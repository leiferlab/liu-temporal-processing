 function [certain_head, certain_tail, uncertain_tips, has_ring, thin_image, BW, new_worm_radius]  = find_tips_centerline_image(I, prev_head, prev_tail, worm_radius, dilation_size, best_threshold)
    %loop through threholds to see if there is a hole in the image, if so,
    %get the branching tips when the hole is the biggest
    
    %enforce prev_head and prev_tail to be inside the image
    prev_head = [max(prev_head(1),1), max(prev_head(2),1)];
    prev_head = [min(prev_head(1),size(I,1)), min(prev_head(2),size(I,1))];
    prev_tail = [max(prev_tail(1),1), max(prev_tail(2),1)];
    prev_tail = [min(prev_tail(1),size(I,1)), min(prev_tail(2),size(I,1))];
    
    max_tip_displacement_per_frame = 7; %pixels the tips are allowed to move
    prev_tips = [prev_head; prev_tail];

    %% STEP 1: use mexican hat filter to find tips %%
    [mex_tips, labeled_filtered_image, BW] = tip_filter(I, best_threshold);
    labeled_filtered_image = imdilate(labeled_filtered_image, true(worm_radius)); %dilate the tips
    
    %% STEP 2: thin for end points %%
    [thin_image, thin_iteration] = find_possible_centerline_image(BW, worm_radius); %update 3 to variable
    endpoint_image = bwmorph(thin_image,'endpoint');
    [endpoints_x, endpoints_y] = ind2sub(size(endpoint_image),find(endpoint_image));
    endpoints = [endpoints_x, endpoints_y];

    %% STEP 3: get head and tail if possible %%  
    potentially_certain_tips = []; %we will check for tip displacement later
    endpoints_accounted_for = [];
    mex_tips_accounted_for = [];
    for endpoint_index = 1:size(endpoints,1)
        mex_tip_index = labeled_filtered_image(endpoints(endpoint_index, 1), endpoints(endpoint_index, 2));
        if mex_tip_index > 0
            %the tip is picked up by both algorithms
            potentially_certain_tips = [potentially_certain_tips; endpoints(endpoint_index, :)];
            mex_tips_accounted_for = [mex_tips_accounted_for, mex_tip_index];
            endpoints_accounted_for = [endpoints_accounted_for, endpoint_index];
        end
    end
    % only add the unaccounted for mexican hat filter tips to the list
    % of uncertain tips
    mex_tips(mex_tips_accounted_for,:) = [];
    %ensures that the two tips are never assigned to the same previous
    %tip
    [matched_tips, leftover_endpoints] = assign_tips(prev_tips, potentially_certain_tips, max_tip_displacement_per_frame);
    certain_head = [];
    certain_tail = [];
    if matched_tips(1,1) > 0;
        %head is found
        certain_head = matched_tips(1,:);
    end
    if matched_tips(2,1) > 0;
        %tail is found
        certain_tail = matched_tips(2,:);
    end
    endpoints(endpoints_accounted_for, :) = []; %remove all the endpoints that were pulled
    endpoints = [endpoints; leftover_endpoints]; %put them back sans the certain tip

    %% STEP 4: find branch points if there is a ring %%
    possible_ring_image = bwmorph(bwmorph(thin_image,'shrink',Inf), 'clean');
    new_worm_radius = [];
    new_endpoints = [];
    has_ring = false;
    if sum(possible_ring_image(:)) > 0
        %there is a hole detected, get the branchpoints
        thin_branchpoint_image = bwmorph(thin_image,'branchpoints');
        dilated_ring_image = imdilate(possible_ring_image, true(dilation_size));
        possible_branchpoint_image = thin_branchpoint_image .* dilated_ring_image;
        [possible_branchpoint_x, possible_branchpoint_y] = ind2sub(size(possible_branchpoint_image),find(possible_branchpoint_image));
        branching_points = [possible_branchpoint_x, possible_branchpoint_y];
        
        if isempty(certain_head) || isempty(certain_tail)
            %only mark as possible omega turn when we don't have certain
            %tips
            has_ring = true;
            %try to break the ring by thresholding so we can find maybe a better tip
            mean_intensity = mean(I(I>0));
            new_BW = im2bw(I, mean_intensity);
            new_thin_image = find_possible_centerline_image(new_BW, worm_radius);
            new_endpoint_image = bwmorph(new_thin_image,'endpoint') .* dilated_ring_image;
            [new_endpoints_x, new_endpoints_y] = ind2sub(size(new_endpoint_image),find(new_endpoint_image));
            new_endpoints = [new_endpoints_x, new_endpoints_y];
        elseif size(branching_points,1) == 2 
            %there are 2 branchpoints
            %we have certain head and certain tail.. but there is still a
            %ring in the image?! that means that our thinning is off or
            %there is a bend in the worm
            
            %trace the paths from one branchpoint to another 
            [possible_ring_image_pixels_x, possible_ring_image_pixels_y] = ind2sub(size(I),find(possible_ring_image));
            possible_ring_image_pixels = [possible_ring_image_pixels_x, possible_ring_image_pixels_y];
            
            [~,closest_boundary_point1_index] = pdist2(possible_ring_image_pixels,branching_points(1,:),'euclidean','Smallest',1);
            closest_boundary_point1 = possible_ring_image_pixels(closest_boundary_point1_index,:);
            
            [~,closest_boundary_point2_index] = pdist2(possible_ring_image_pixels,branching_points(2,:),'euclidean','Smallest',1);
            closest_boundary_point2 = possible_ring_image_pixels(closest_boundary_point2_index,:);
            
            boundary_points = bwtraceboundary(possible_ring_image, closest_boundary_point1, 'N');
            cum_distances = find_cumulative_distance(boundary_points);
            perimeter = cum_distances(end);
            
            if isempty(boundary_points)
                %extreme case: no boundary found
                cw_distance = 0;
            else
                [~, second_branchpoint_index] = ismember(closest_boundary_point2, boundary_points, 'rows');
                if second_branchpoint_index == 0
                    %extreme case: no index found!
                    cw_distance = 0;
                else
                   cw_distance = cum_distances(second_branchpoint_index);
                end
            end
            ccw_distance = perimeter - cw_distance;
            
            if min(cw_distance, ccw_distance) < 0.8*max(cw_distance, ccw_distance)
                %real! thin image should have the shorter path removed
                if cw_distance < ccw_distance
                    points_to_remove = boundary_points(2:second_branchpoint_index-1,:);
                else
                    points_to_remove = boundary_points(second_branchpoint_index+1:end-1,:);
                end
                for removal_index = 1:size(points_to_remove,1);
                    thin_image(points_to_remove(removal_index,1), points_to_remove(removal_index,2)) = false;
                end
            else
                %fake! it's time to change the thinning parameter
                [new_thin_image, thin_iteration] = find_possible_centerline_image(BW, Inf);
                if thin_iteration > worm_radius && thin_iteration <= worm_radius + 2
                    %the thin_iteration has increased by 1 or 2. change the
                    %worm_raidus
                    new_worm_radius = thin_iteration;
                    thin_image = new_thin_image;
                end
            end
        end
    else
        branching_points = [];
    end
    
    %% STEP 5: add in prev_head and prev_tail if there are no suitable candidates close to them %%
    uncertain_tips = [endpoints; branching_points; new_endpoints; mex_tips];
    all_tips = [certain_head; certain_tail; uncertain_tips];
    if isempty(certain_head) && BW(round(prev_head(1)), round(prev_head(2)))
        min_distance = pdist2(prev_head, all_tips, 'euclidean', 'Smallest', 1);
        if min_distance > max_tip_displacement_per_frame
            uncertain_tips = [uncertain_tips; prev_head];
        end
    end
    if isempty(certain_tail) && BW(round(prev_tail(1)), round(prev_tail(2)))
        min_distance = pdist2(prev_tail, all_tips, 'euclidean', 'Smallest', 1);
        if min_distance > max_tip_displacement_per_frame
            uncertain_tips = [uncertain_tips; prev_tail];
        end
    end
    
    %% STEP 6: return the uncertain tips %%
    if size(certain_head,1) + size(certain_tail,1) + size(uncertain_tips,1) < 2
        %if we haven't found enough tips, add in the previous ones
        uncertain_tips = [uncertain_tips; prev_head; prev_tail];
    end
    uncertain_tips = unique(uncertain_tips, 'rows');
    if isempty(new_worm_radius) 
        if thin_iteration < worm_radius
            %update the thinning if it decreased
            new_worm_radius = thin_iteration;
        else
            new_worm_radius = worm_radius;
        end
    end
%    new_worm_radius = worm_radius;
end