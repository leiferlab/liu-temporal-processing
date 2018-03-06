function [matched_tips, unknown_tips, known_tips]  = assign_tips(known_tips, unknown_tips, threshold_distance)
    %loop until all known or unknown are assigned, or until
    %threshold_distance is reached
    matched_tips = zeros(size(known_tips));
    
    known_indecies = 1:size(known_tips,1);
    while ~isempty(known_tips) && ~isempty(unknown_tips)
        distance_matrix = pdist2(known_tips, unknown_tips);
        [dist, min_index] = min(distance_matrix(:));
        if dist > threshold_distance
            break;
        end
        
        [known_index, unknown_index] = ind2sub(size(distance_matrix), min_index);
        matched_tips(known_indecies(known_index),:) = unknown_tips(unknown_index,:);
        
        %remove the matched tips from next selection
        known_tips(known_index,:) = [];
        known_indecies(known_index) = [];
        unknown_tips(unknown_index,:) = [];
    end
end