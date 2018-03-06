function [center_line_interp, thin_image_returned, BW, isGoodFrame, thinning_iteration] = initialize_contour(I, nPoints, best_threshold)
    %Initializes the contour given a threshold value

    %% STEP 1: use mexican hat filter to find tips %%
    [~, labeled_filtered_image, BW] = tip_filter(I, best_threshold);
    labeled_filtered_image = imdilate(labeled_filtered_image, ones(3)); %dilate the tips
    isGoodFrame = false; 
    
    %% STEP 2: thin for end points%%%
    [thin_image, thinning_iteration] = find_possible_centerline_image(BW, Inf); %update 3 to variable
    thin_image_returned = thin_image;
    endpoint_image = bwmorph(thin_image,'endpoint');
    [endpoints_x, endpoints_y] = ind2sub(size(endpoint_image),find(endpoint_image));
    endpoints = [endpoints_x, endpoints_y];
    
    %if there are no endpoints found, just branchpoints, then we fill in
    %the thinned image and re-thin it
    if isempty(endpoints)
        %find branch poiunts
        branchpoint_image = bwmorph(thin_image,'branchpoints');
        if sum(branchpoint_image(:)) > 0
            %there are branch points!
            thin_image = imfill(thin_image,'holes');
            thin_image = bwmorph(thin_image,'thin',Inf);
            thin_image_returned = thin_image;
            endpoint_image = bwmorph(thin_image,'endpoint');
            [endpoints_x, endpoints_y] = ind2sub(size(endpoint_image),find(endpoint_image));
            endpoints = [endpoints_x, endpoints_y];
        end
    else
        %extreme case
    end
    

    %% STEP 3: get head and tail if possible%%%   
    potentially_certain_tips = []; 
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
    
    if size(potentially_certain_tips) == 2
        %there are exactly 2 tips, it is a good frame
        endpoints = potentially_certain_tips;
        isGoodFrame = true;
    elseif size(potentially_certain_tips) >= 2
        endpoints = potentially_certain_tips;
    else
        %less than 2 endpoints
        endpoints(endpoints_accounted_for, :) = []; %remove all the endpoints that were pulled
        endpoints = [potentially_certain_tips; endpoints]; %put them back if we need it
    end
    
    %% STEP 4: get a centerline without spurs
    iteration_count = 1; %make sure we don't loop forever
    while iteration_count < 50
        endpoint_image = bwmorph(thin_image,'endpoint');
        if sum(endpoint_image(:)) <= 2
            break
        else
            %there are more than 2 endpoints remove spurs
            thin_image = bwmorph(thin_image, 'spur', 1);
        end
        iteration_count = iteration_count + 1;
    end
    
    %% STEP 5: put the 2 best potentially_certain_tips back 
    if isempty(endpoints)
        %extreme case, no endpoints found, use the diagonal and
        %interp
        center_line = [1, 1; size(BW,1), size(BW,2)];
        dis=[0;cumsum(sqrt(sum((center_line(2:end,:)-center_line(1:end-1,:)).^2,2)))];
        isGoodFrame = false;
        % Resample to make uniform points
        center_line_interp(:,1) = interp1(dis,center_line(:,1),linspace(0,dis(end),nPoints));
        center_line_interp(:,2) = interp1(dis,center_line(:,2),linspace(0,dis(end),nPoints));isGoodFrame = false;
        isGoodFrame = false;
        return
    end
    D = pdist2(endpoints, endpoints);
    [~, linear_index] = max(D(:));
    [tip1_index, tip2_index] = ind2sub([size(endpoints,1),size(endpoints,1)], linear_index(1));
    thin_image(endpoints(tip1_index,1), endpoints(tip1_index,2)) = true;
    thin_image(endpoints(tip2_index,1), endpoints(tip2_index,2)) = true;

    
    %% STEP 6: start the algorithm
    %grab any endpoint to start the algorithm
    endpoint = endpoints(1,:);
    thin_image(endpoint(1), endpoint(2)) = false;
    
    center_line = endpoint;
    while sum(thin_image(:)) > 0
        %the next point along the centerline is the closest pixel to the
        %current end of the centerline
        [pixels_left_x, pixels_left_y] = ind2sub(size(I),find(thin_image));
        pixels_left = [pixels_left_x, pixels_left_y];
        [~, next_index] = pdist2(pixels_left, center_line(end,:),'euclidean', 'Smallest', 1);
        center_line = [center_line; pixels_left(next_index,:)];
        if size(endpoints,1) >= 2 && endpoints(2,1) == pixels_left(next_index,1) && endpoints(2,2) == pixels_left(next_index,2)
            %the second endpoint reached, stop
            break
        else
            thin_image(pixels_left(next_index,1), pixels_left(next_index,2)) = false;
        end
    end

    dis=[0;cumsum(sqrt(sum((center_line(2:end,:)-center_line(1:end-1,:)).^2,2)))];
    
    if dis(end) == 0
        %extreme case where there is no centerline, use the diagonal and
        %interp
        center_line = [1, 1; size(BW,1), size(BW,2)];
        dis=[0;cumsum(sqrt(sum((center_line(2:end,:)-center_line(1:end-1,:)).^2,2)))];
        isGoodFrame = false;
    end
    
    % Resample to make uniform points
    center_line_interp(:,1) = interp1(dis,center_line(:,1),linspace(0,dis(end),nPoints));
    center_line_interp(:,2) = interp1(dis,center_line(:,2),linspace(0,dis(end),nPoints));

end