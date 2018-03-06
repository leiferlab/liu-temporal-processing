function [filtered_folders, filtered_tags] = filter_folders(folders, folder_tags, selected_tag)
    % this function filters the experimental folders by tag
    filtered_folders = [];
    filtered_tags = [];
    for folder_index = 1:length(folders)
        current_folder_tags = folder_tags{folder_index};
        binary_indexing = ismember(current_folder_tags, selected_tag);
        if sum(binary_indexing) > 0
            %the folder has the selected_tag
            filtered_folders = [filtered_folders, folders(folder_index)];
            filtered_tags = [filtered_tags, {current_folder_tags(~binary_indexing)}];
        end
    end
end