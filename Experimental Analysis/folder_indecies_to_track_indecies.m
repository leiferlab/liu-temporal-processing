function [ track_indecies ] = folder_indecies_to_track_indecies( folder_indecies )
%Converts folder indecies to track indecies
    current_folder_index = 1;
    track_indecies = zeros(size(folder_indecies));
    track_indecies(1) = 1;
    for index = 2:length(folder_indecies)
       if folder_indecies(index) ~= current_folder_index
           %new index reached
           current_folder_index = folder_indecies(index);
           track_indecies(index) = 1;
       else
           track_indecies(index) = track_indecies(index-1)+1;
       end
    end
end
