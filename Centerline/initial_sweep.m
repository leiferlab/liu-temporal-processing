function Track = initial_sweep(image_stack, Track, parameters, plot_index)
    % given a sequence of worm images, this function finds the centerlines
    
    %% STEP 1: define parameters %%

    nPoints = 20; % Numbers of points in the contour
    gamma = 15;    %Iteration time step
    ConCrit = .1; %Convergence criteria
    kappa = 50;     % Weight of the image force as a whole
    sigma = 1;   %Smoothing for the derivative calculations in the image, causes centerline to loose track
    alpha = 0; % Bending modulus
    beta = 2; %how local the deformation is
    nu = 30;  %spring force
    mu = 2.5; %repel force
    cd = 3; %cutoff distance for repel force
    xi = 2; %the attraction to the found tips
    l0 = 40; %the expected length of the worm
    sample_size = 10; %how many straight worm images we are measuring for initialization

    image_stack = double(image_stack) ./ 255;
    number_of_images = size(image_stack,3);
    image_size = [size(image_stack,1), size(image_stack,2)];
    if nargin < 3
        plot_index = 0;
    end
    
    %calculate the internal energy for active contour, calculate it once
    %and remember
    persistent B;
    if isempty(B)
        B = internal_energy(alpha, beta, gamma, nPoints);
    end
    
    %% STEP 2: get what a normal worm looks like by looking at the images with the highest eccentricities %%
    thinning_iterations = [];
    dilation_sizes = [];
    lengths = [];
    % Sort the eccentricities in descending order
    [~ ,sortIndex] = sort(Track.Eccentricity,'descend');  
    maxIndecies = sortIndex(1:sample_size);
    if Track.Eccentricity(sortIndex(1)) > 0.97
        best_thresholds = 0;
    else
        best_thresholds = [];
    end
    good_frame_index = maxIndecies(1);
    looking_for_good_frame = true; %make sure the best frame has only 2 tips
    for max_index = 1:length(maxIndecies)
        %this is a pretty straight worm, sample it
        index = maxIndecies(max_index);
        I = reshape(image_stack(:,:,index),image_size);
        
        best_thresholds = [best_thresholds, find_best_threshold(I)];
        best_threshold = min(best_thresholds);
        
        [current_worm_radius, current_dilation_size] = find_worm_radius(I, best_threshold);
        thinning_iterations = [thinning_iterations, current_worm_radius];
        thinning_iteration = round(mean(thinning_iterations));
        
        dilation_sizes = [dilation_sizes, current_dilation_size];
        
        %kappa = 2.5*255/worm_radius; % the image force is scale dependent
        sigma = thinning_iteration/3; %the gaussian blurring is scale dependent
        cd = thinning_iteration; %repel distance is scale dependent
        [initial_contour, thin_image, ~, isGoodFrame, ~] = initialize_contour(I, nPoints, best_threshold);
        if looking_for_good_frame && isGoodFrame
            good_frame_index = index;
            looking_for_good_frame = false;
        end
        
        tips = [initial_contour(1,:); initial_contour(end,:)];
        Fline = external_energy(I, sigma); %External energy from the image
        center_line = relax2tip(initial_contour, tips, kappa, Fline, gamma, B, ConCrit, cd, 0, l0, 0, xi); %calculate the lengths without a length force
        lengths = [lengths, sum(sqrt(sum((center_line(2:end,:)-center_line(1:end-1,:)).^2,2)))];
    end
    l0 = mean(lengths)*0.95; %the length is generally smaller than when the worm is fully extended
    dilation_size = round(mean(dilation_sizes));
    current_thinning_iteration = thinning_iteration;
    
    %% STEP 3: preallocate memory for speed %%
    
    UncertainTips = struct();
    UncertainTips(number_of_images).Tips = [];
    all_center_lines = zeros(nPoints,2,number_of_images);
    thinning_iterations = zeros(1, number_of_images, 'uint8');
    TotalScore = zeros(1, number_of_images);
    ImageScore = zeros(1, number_of_images);
    DisplacementScore = zeros(1, number_of_images);
    PixelsOutOfBody = sparse(1, number_of_images);
    Length = zeros(1, number_of_images);
    centerline_has_ring = false(1,number_of_images); %used later to figure out when omega turns occur
    %used later to resolve problems, problem types: 
    %   1 head/tail flips
    %   2 Image score low
    %   3 centerline out of body
    %   4 displacement score low
    %   see function problem_code_lookup for full list
    potential_problems = zeros(1, number_of_images, 'uint8'); 

    %% STEPS 4-11: main loop for image analysis %%
    %STEP 4: initialize the contour with our absolute best image
    %STEP 5: active contour backward from our best image
    %STEP 6: active contour forward from our best image
    %STEP 7: initialize 'Okazaki' processing for omega turns
    %STEP 8: search forward for omega turns from the first frame until best image
    %STEP 9: active contour forward form step 8
    %STEP 10: search backward for omega turns from the last frame until best image
    %STEP 11: active contour backward form step 10
    step_number = 4;
    while true
        find_centerline = true; %should we perform active contour this loop?
        switch step_number
        case 4
            %STEP 4: initialize the centerline when the worm is kind of straight%
            index = good_frame_index;
            I = reshape(image_stack(:,:,index),image_size); %grab the image
            %STEP 4A-C: find initial contour, thin image, and tips%
            [initial_contour, thin_image, BW, ~, current_thinning_iteration] = initialize_contour(I, nPoints, best_threshold);
            current_head = initial_contour(1,:);
            current_tail = initial_contour(end,:);
            centerline_has_ring(index) = false;
        case {5, 6, 9, 11}
%             if index == 1140
%                 asdf = 1;
%             end
            %STEP 5/6/9/11A: find initial contour by looking at the previous, unless we are starting at the first or last frame%
            if index >= 1 && index <= number_of_images
                initial_contour = reshape(all_center_lines(:,:,index),nPoints,2);
                current_thinning_iteration = thinning_iterations(index);
                reinitialize = false;
            else
                reinitialize = true;
            end
            if step_number == 5 || step_number == 11
                %STEP 5/9B: go backwards%
                index = index - 1;
            elseif step_number == 6 || step_number == 9
                %STEP 6/11B: go forwards%
                index = index + 1;
            end
            I = reshape(image_stack(:,:,index),image_size); %grab the image

            %STEP 5/6/9/11C: find tips and thin image%
            if reinitialize
                % we need to reinitialize for STEPS 9 / 11 if beginning at
                % the first and last frames and there are no omega turns
                [initial_contour, thin_image, BW, ~, current_thinning_iteration] = initialize_contour(I, nPoints, best_threshold);
                current_head = initial_contour(1,:);
                current_tail = initial_contour(end,:);
            else
                prev_head= initial_contour(1,:);
                prev_tail = initial_contour(end,:);
                [current_head, current_tail, UncertainTips(index).Tips, ...
                    centerline_has_ring(index), thin_image, BW, current_thinning_iteration] = ...
                    find_tips_centerline_image(I, prev_head, prev_tail, current_thinning_iteration, dilation_size, best_threshold);
            end
        case 7
            %STEP 7: prepare for going into Okazaki mode%%
            find_centerline = false; %skip active contour
            omega_turn_annotation = binary_smoothing(centerline_has_ring, 7);
            omega_turn_annotation = fill_binary_holes(omega_turn_annotation, 2); %fill up to 2 holes
            all_centerline_tips = all_center_lines([1,end],:,:);
            possible_head_switch_frames = sparse(false(1,number_of_images));
            step_number = 8;
        case 8
            %STEP 8: going forwards from frame 1 for head/tail flip correction, finding the next omega turn%
            find_centerline = false; %skip active contour
            [next_omega_turn_start, ~, stop_index] = find_next_section(omega_turn_annotation, index, 'f', all_centerline_tips);
            possible_head_switch_frames(stop_index) = true;
            if isempty(next_omega_turn_start)
                %no omega turns left, skip steps 10/11
                step_number = 12;
                break
            elseif next_omega_turn_start >= good_frame_index
                %there are omega turns going in the opposite direction,
                %go to step 10;
                index = number_of_images;
                step_number = 10;
            elseif index == 1 && ~omega_turn_annotation(1)
                %start going towards the omega turn from the first image if
                %it is not an omega turn
                index = 0;
                step_number = 9;
            else
                %start going towards the omega turn from the best image in
                %between omega turns
                [~, best_eccentricity_index] = max(Track.Eccentricity(index:next_omega_turn_start));
                index = index + best_eccentricity_index - 1;
                step_number = 9;
            end
        case 10
            %STEP 10: going backwards from the last frame for head/tail flip correction, finding the next omega turn%
            find_centerline = false; %skip active contour
            [next_omega_turn_start, ~, stop_index] = find_next_section(omega_turn_annotation, index, 'b', all_centerline_tips);
            possible_head_switch_frames(stop_index) = true;
            if isempty(next_omega_turn_start) || next_omega_turn_start <= good_frame_index
                %no omega turns left, end this!
                step_number = 12;
                break
            elseif index == number_of_images && ~omega_turn_annotation(number_of_images)
                %start going towards the omega turn from the last image if
                %it is not an omega turn
                index = number_of_images+1;
                step_number = 11;
            else
                %start going towards the omega turn from the best image in
                %between omega turns
                [~, best_eccentricity_index] = max(Track.Eccentricity(next_omega_turn_start:index));
                index = next_omega_turn_start + best_eccentricity_index - 1;
                step_number = 11;
            end
        end
        
        if find_centerline
            previously_found_centerline = squeeze(all_center_lines(:,:,index)); %important for step 9/11, so we can compare it
            %STEP 4/5/6/9/11D: find the image gradient%
            composite_image = I + imgaussfilt(double(thin_image)); %we want to reward the centerline being on the thinned image
            Fline = external_energy(composite_image, sigma); %External energy from the image
            
            %STEP 4/5/6/9/11E: find centerline given the tips found%
            if ~isempty(current_head) && ~isempty(current_tail)
                %STEP 4/5/6/9/11E: find centerline if both head and tail are certain%
                tips = [current_head; current_tail];
                all_center_lines(:,:,index) = relax2tip(initial_contour, tips, kappa, Fline, gamma, B, ConCrit, cd, mu, l0, nu, xi);
                if step_number == 4
                    %STEP 4: the displacement score is 1
                    [TotalScore(index), ImageScore(index), DisplacementScore(index), PixelsOutOfBody(index)] ...
                        = score_centerline_whole_image(all_center_lines(:,:,index), [], BW, dilation_size, l0);
                else
                    %STEP 5/6/9/11: the displacement score is based on what the previous contour is                   
                    [TotalScore(index), ImageScore(index), DisplacementScore(index), PixelsOutOfBody(index)] ...
                        = score_centerline_whole_image(all_center_lines(:,:,index), initial_contour, BW, dilation_size, l0);
                end
            else
                %STEP 5/6/9/11E: go through the uncertain tips for the ones that matches the image%
                %we are here because at least one tip is uncertain
                if ~isempty(current_head)
                    heads_to_try = current_head;
                    tails_to_try = UncertainTips(index).Tips;
                elseif ~isempty(current_tail)
                    heads_to_try = UncertainTips(index).Tips;
                    tails_to_try = current_tail;
                else
                    heads_to_try = UncertainTips(index).Tips;
                    tails_to_try = UncertainTips(index).Tips;                    
                end

                %The two tips are the ones that give the best centerline
                %according to our score (higher score means better match)
                tip_total_scores = zeros(size(heads_to_try,1), size(tails_to_try,1));
                tip_image_scores = zeros(size(heads_to_try,1), size(tails_to_try,1));
                tip_displacement_scores = zeros(size(heads_to_try,1), size(tails_to_try,1));
                tip_pixels_out_of_body = zeros(size(heads_to_try,1), size(tails_to_try,1));
                tip_centerlines = zeros(size(heads_to_try,1), size(tails_to_try,1), nPoints, 2); %save the centerlines so we don't have to compute it again
                for head_index = 1:size(tip_total_scores,1)
                    for tail_index = 1:size(tip_total_scores,2)
                        if ismember(heads_to_try(head_index,:), tails_to_try(tail_index,:), 'rows')
                            %the head and the tail are the same
                            tip_total_scores(head_index,tail_index) = -1;
                        else
                            %the score has not been computed, compute it
                            temp_tips = [heads_to_try(head_index,:); tails_to_try(tail_index,:)];
                            K = relax2tip(initial_contour, temp_tips, kappa, Fline, gamma, B, ConCrit, cd, mu, l0, nu, xi);
                            [tip_total_scores(head_index,tail_index), ...
                                tip_image_scores(head_index,tail_index), ...
                                tip_displacement_scores(head_index,tail_index), ...
                                tip_pixels_out_of_body(head_index,tail_index)]...
                                = score_centerline_whole_image(K, initial_contour, BW, dilation_size, l0); 
                            
                            tip_centerlines(head_index,tail_index, :, :) = K;
                        end
                    end
                end

                [max_score,tips_index] = max(tip_total_scores(:)); %get the max score
                [head_index,tail_index] = ind2sub(size(tip_total_scores),tips_index); %find which head and tail produced it
                all_center_lines(:,:,index) = reshape(tip_centerlines(head_index,tail_index,:,:), nPoints, 2);
                TotalScore(index) = max_score;
                ImageScore(index) = tip_image_scores(head_index,tail_index);
                DisplacementScore(index) = tip_displacement_scores(head_index,tail_index);
                PixelsOutOfBody(index) = tip_pixels_out_of_body(head_index,tail_index);
            end

            %STEP 4/5/6/9/11F: Get the centerline length%
            Length(index) = sum(sqrt(sum(squeeze((all_center_lines(2:end,:,index)-all_center_lines(1:end-1,:,index))).^2,2)));
            if pdist2(all_center_lines(1,:,index),all_center_lines(end,:,index)) > 0.7 * Length(index)
                %the worm is pretty straight, it should not have rings
                centerline_has_ring(index) = false;
            end
            thinning_iterations(index) = current_thinning_iteration;
            
%             %%%%%%STEP DEBUG: plot as we go along%%%%%%
%             plot_worm_frame(I, squeeze(all_center_lines(:,:,index)), ...
%                 Track.UncertainTips(index), Track.Eccentricity(index), ...
%                 Track.Direction(index), Track.Speed(index), Track.TotalScore(index), 1);
%             index
%             pause(0.1)

            %STEP 4/5/6/9/11G: look for transitions%
            switch step_number
            case 4
                if index == 1
                    step_number = 6;
                else
                    step_number = 5;
                end
            case 5
                if index == 1
                    index = good_frame_index;
                    if good_frame_index == number_of_images
                        %skip step 6 (i.e. going forwads)
                        index = 1;
                        step_number = 7;
                    else
                        step_number = 6;
                    end
                end
            case 6
                if index == number_of_images
                    index = 1;
                    step_number = 7;
                end
            case 9
                if index >= stop_index
                    %STEP 9H: determine if the centerline has been flipped%
                    current_centerline = squeeze(all_center_lines(:,:,index));
                    displacement = min_circshifted_displacement(previously_found_centerline, current_centerline);
                    flipped_displacement = min_circshifted_displacement(previously_found_centerline, flip(current_centerline,1));
                    if flipped_displacement < displacement
                        %tip flip detected. gotta flip everything past it
                        all_center_lines(:,:,1:index) = flip(all_center_lines(:,:,1:index),1);
                    end
                    step_number = 8;
                end
            case 11
                if index <= stop_index
                    %STEP 11H: determine if the centerline has been flipped%
                    current_centerline = squeeze(all_center_lines(:,:,index));
                    displacement = min_circshifted_displacement(previously_found_centerline, current_centerline);
                    flipped_displacement = min_circshifted_displacement(previously_found_centerline, flip(current_centerline,1));
                    if flipped_displacement < displacement
                        %tip flip detected. gotta flip everything past it
                        all_center_lines(:,:,index:end) = flip(all_center_lines(:,:,index:end),1);
                    end
                    step_number = 10;
                end
            end
        end
%         index
    end
    
    %% STEP 12: get correct head/tail assuming the worm travels mainly pointing towards the head%%
%     direction_vector = [[Track.Speed].*-cosd([Track.Direction]); [Track.Speed].*sind([Track.Direction])];
    direction_vector = [-cosd([Track.Direction]); sind([Track.Direction])];
    
    head_vector = reshape(all_center_lines(1,:,:),2,[]) - (image_size(1)/2);    
    tail_vector = reshape(all_center_lines(end,:,:),2,[]) - (image_size(1)/2);
    
    %normalize into unit vector
    head_normalization = hypot(head_vector(1,:), head_vector(2,:));
    tail_normalization = hypot(tail_vector(1,:), tail_vector(2,:));
    head_vector = head_vector ./ repmat(head_normalization, 2, 1);
    tail_vector = tail_vector ./ repmat(tail_normalization, 2, 1);
    
    head_direction_dot_product = dot(head_vector, direction_vector);
    tail_direction_dot_product = dot(tail_vector, direction_vector);
    mean_head_direction_dot_product = mean(head_direction_dot_product);
    mean_tail_direction_dot_product = mean(tail_direction_dot_product);
    if mean_tail_direction_dot_product > mean_head_direction_dot_product
        all_center_lines = flip(all_center_lines,1);
        temp_head_direction_dot_product = head_direction_dot_product;
        head_direction_dot_product = tail_direction_dot_product;
        tail_direction_dot_product = temp_head_direction_dot_product;
    end
    
    %% STEP 13: get correct head/tail in the subsection with the best frame%%
    index = good_frame_index;
    search_backwards = true;
    search_forwards = true;
    test_flip = true;
    sections_with_no_head_switchs = ~full(possible_head_switch_frames);
    if ~possible_head_switch_frames(good_frame_index)
        [subsection_start, ~, ~] = find_next_section(sections_with_no_head_switchs, index, 'b');
        [subsection_end, ~, ~] = find_next_section(sections_with_no_head_switchs, index, 'f');
        if isempty(subsection_start) && isempty(subsection_end)
            %one giant block, no possible head/tail swaps
            search_backwards = false;
            search_forwards = false;
            test_flip = false;
        elseif isempty(subsection_start)
            subsection_start = 1;
            search_backwards = false;
        elseif isempty(subsection_end)
            subsection_end = number_of_images;
            search_forwards = false;
        end
        if test_flip
            [flip_needed, flip_possible] = determine_if_head_tail_flip(head_direction_dot_product(subsection_start:subsection_end), ...
                    tail_direction_dot_product(subsection_start:subsection_end), parameters);
            if flip_possible
                potential_problems(index) = 1;
            end
            if flip_needed
                %a flip is needed
                all_center_lines = flip(all_center_lines,1);
                %flip the dot products
                temp_head_direction_dot_product = head_direction_dot_product;
                head_direction_dot_product = tail_direction_dot_product;
                tail_direction_dot_product = temp_head_direction_dot_product;
            end
        end
    end
    
    %% STEP 14: get correct head/tail in the subsections before the best frame%%
    while search_backwards
        %going backwards until the first frame
        [subsection_end, subsection_start, ~] = find_next_section(sections_with_no_head_switchs, index, 'b');
        if isempty(subsection_start)
            break
        else
            [flip_needed, flip_possible] = determine_if_head_tail_flip(head_direction_dot_product(subsection_start:subsection_end), ...
                    tail_direction_dot_product(subsection_start:subsection_end), parameters);
            if flip_possible
                potential_problems(subsection_end) = 1;
            end
            if flip_needed
                %a flip is needed
                all_center_lines(:,:,1:subsection_end) = flip(all_center_lines(:,:,1:subsection_end),1);
                %flip the dot products
                temp_head_direction_dot_product = head_direction_dot_product;
                head_direction_dot_product(1:subsection_end) = tail_direction_dot_product(1:subsection_end);
                tail_direction_dot_product(1:subsection_end) = temp_head_direction_dot_product(1:subsection_end);
            end
            index = subsection_start - 1;
            if subsection_start < 1
                break
            end
        end
    end
    
    %% STEP 15: get correct head/tail in the subsections after the best frame%%
    index = good_frame_index;
    while search_forwards
        %going forwards until the last frame
        [subsection_start, subsection_end, ~] = find_next_section(sections_with_no_head_switchs, index, 'f');
        if isempty(subsection_start)
            break
        else
            [flip_needed, flip_possible] = determine_if_head_tail_flip(head_direction_dot_product(subsection_start:subsection_end), ...
                    tail_direction_dot_product(subsection_start:subsection_end), parameters);
            if flip_possible
                potential_problems(subsection_start) = 1;
            end
            if flip_needed
                %a flip is needed
                all_center_lines(:,:,subsection_start:end) = flip(all_center_lines(:,:,subsection_start:end),1);
                %flip the dot products
                temp_head_direction_dot_product = head_direction_dot_product;
                head_direction_dot_product(subsection_start:end) = tail_direction_dot_product(subsection_start:end);
                tail_direction_dot_product(subsection_start:end) = temp_head_direction_dot_product(subsection_start:end);
            end
            index = subsection_end + 1;
            if subsection_end > number_of_images
                break
            end
        end
    end
    
    %% STEP 16: determine if there are additional problems
    aspect_ratio = Length / dilation_size;
    potential_problems(ImageScore < 0.5) = 2;
    potential_problems(PixelsOutOfBody > 10) = 3;
    potential_problems(DisplacementScore < 0.85) = 4;
    potential_problems(Length < 25) = 5; 
    potential_problems(Length > 65) = 6;
    potential_problems(aspect_ratio < 4) = 7; 
    potential_problems(aspect_ratio > 12) = 8;
    
    %% STEP 17: store results
    Track.Centerlines = all_center_lines;
    Track.UncertainTips = UncertainTips;
    Track.OmegaTurnAnnotation = omega_turn_annotation;
    Track.PossibleHeadSwitch = possible_head_switch_frames;
    Track.Length = Length;
    Track.TotalScore = TotalScore;
    Track.ImageScore = ImageScore;
    Track.DisplacementScore = DisplacementScore;
    Track.PixelsOutOfBody = PixelsOutOfBody;
    Track.PotentialProblems = potential_problems;
    Track.DilationSize = dilation_size;
    Track.AspectRatio = aspect_ratio;
    Track.MeanAspectRatio = mean(Track.AspectRatio);
    Track.ThinningIteration = thinning_iterations;
    
%     %% DEBUG: plot from beginning to finish%%%%%%
% %    outputVideo = VideoWriter(fullfile(['worm_', num2str(plot_index)]),'MPEG-4');
%     outputVideo = VideoWriter(fullfile('debug.mp4'),'MPEG-4');
%     outputVideo.FrameRate = 14;
%     open(outputVideo)
%     for index = 1:number_of_images
%         I = reshape(image_stack(:,:,index),image_size);
%         plot_worm_frame(I, squeeze(all_center_lines(:,:,index)), ...
%             Track.UncertainTips(index), Track.Eccentricity(index), ...
%             Track.Direction(index), Track.Speed(index), Track.TotalScore(index), 1);
% %         drawnow
% %         pause(0.01);
%         writeVideo(outputVideo, getframe(gcf));
%     end
%     close(outputVideo) 
end