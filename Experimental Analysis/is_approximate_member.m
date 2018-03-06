function [ index_found ] = is_approximate_member(search_for,search_in,min_difference)
%finds if there exists an approximate row in "search_in" for the row "search_for"
%used to see if a stimulus shape appears similar to another stimulus shape
    if nargin < 3
        min_difference = 0.05;
    end

    index_found = 0;
    for row_index = 1:size(search_in,1)
        %compute the average normalized L1 distance
        L1_dist = max(sum(abs(search_for-search_in(row_index,:)))/sum(search_in(row_index,:)), ...
            sum(abs(search_for-search_in(row_index,:)))/sum(search_for));
        if L1_dist < min_difference
            index_found = row_index;
            return
        end
    end
end