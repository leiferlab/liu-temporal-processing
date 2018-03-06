function [start_index, end_index, min_dist_index]  = find_next_section(binary_annotation, current_index, backwards_or_forwards, all_center_line_tips)
    %finds the next section bounded by 1s going either forwards or backwards in time
    if strcmp(backwards_or_forwards, 'b')
        %going backwards
        %find where the next section starts
        if current_index > length(binary_annotation) && binary_annotation(end)
            %the array ends with a true and we are searching from after
            %it
            start_index = length(binary_annotation);
        else
            %the array does not start with a true or we we not searching
            %from before it starts
            if current_index > length(binary_annotation)
                current_index = length(binary_annotation);
            end
            temp_annotation = binary_annotation(1:current_index);
            start_index = strfind(temp_annotation, [true, false]);
        end
        
        if ~isempty(start_index)
            start_index = start_index(end);
        else
            end_index = [];
            min_dist_index = [];
            return
        end
        %find where the next section ends
        temp_annotation = binary_annotation(1:start_index);
        end_index = strfind(temp_annotation, [false, true]);
        if ~isempty(end_index)
            end_index = end_index(end) + 1;
        else
            end_index = 1;
        end
        if nargin > 3 && ~isempty(all_center_line_tips) && end_index > 0 && start_index < size(all_center_line_tips,3)
            %find where are the two tips closest together, and thus have the most
            %likely chance of flipping
            all_tips = all_center_line_tips(:, :, end_index:start_index);
            all_tip_distances = squeeze(sqrt((all_tips(end,1,:)-all_tips(1,1,:)).^2 + (all_tips(end,2,:)-all_tips(1,2,:)).^2));
            [~, min_index] = min(all_tip_distances);
            min_dist_index = end_index + min_index - 1;
        else
            min_dist_index = round(mean([start_index, end_index]));
        end
    else
        %going forwards
        %find where the next section starts
        if current_index < 1 && binary_annotation(1)
            %the array starts with a true and we are searching from before
            %it
            current_index = 1;
            start_index = 0;
        else
            %the array does not start with a true or we we not searching
            %from before it starts
            if current_index < 1
                current_index = 1;
            end
            temp_annotation = binary_annotation(current_index:end);
            start_index = strfind(temp_annotation, [false, true]);
        end
        
        if ~isempty(start_index)
            start_index = start_index(1) + current_index;
        else
            end_index = [];
            min_dist_index = [];
            return
        end
        %find where the next section ends
        temp_annotation = binary_annotation(start_index:end);
        end_index = strfind(temp_annotation, [true, false]);
        if ~isempty(end_index)
            end_index = end_index(1) + start_index - 1;
        else
            end_index = length(binary_annotation);
        end
        if nargin > 3 && ~isempty(all_center_line_tips) && start_index > 0 && end_index < size(all_center_line_tips,3)
            %find where are the two tips closest together, and thus have the most
            %likely chance of flipping
            all_tips = all_center_line_tips(:, :, start_index:end_index);
            all_tip_distances = squeeze(sqrt((all_tips(end,1,:)-all_tips(1,1,:)).^2 + (all_tips(end,2,:)-all_tips(1,2,:)).^2));
            [~, min_index] = min(all_tip_distances);
            min_dist_index = start_index + min_index - 1;
        else
            min_dist_index = round(mean([start_index, end_index]));
        end
    end  
end