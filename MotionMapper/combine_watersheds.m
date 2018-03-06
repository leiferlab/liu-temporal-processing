function [ new_labels ] = combine_watersheds( L, indecies_to_combine )
%This function combines the indecies in indecies_to_combine
    if length(indecies_to_combine) < 2
        new_labels = L;
        return
    end
    BW = im2bw(L, 0);
    BW_combined_indecies = ismember(L, indecies_to_combine);
    BW_combined_indecies = bwmorph(BW_combined_indecies,'close');
    new_BW = or(BW,BW_combined_indecies);
    new_labels = bwlabel(new_BW);

    max_label_index = max(new_labels(:));
    new_labels(new_labels==1) = max_label_index+1;
    new_labels = uint8(new_labels - 1);

end

