function [folders, folder_tags, folder_count] = catalog_tags(folder_name)
% Look through experimental folders recursively and sort out what the 
% experimental tags are

    folders = {};
    folder_count = 0;
    folder_tags = cell(0,0);
    
    start_path = '';
    
    if nargin < 1
        folder_name = uigetdir(start_path, 'Select Experiment Folder')
    else
        %there is a folder_name input
    end

    if exist([folder_name, filesep, 'parameters.txt'],'file')
        %this is an image folder
        if exist([folder_name, filesep, 'tags.txt'],'file')
            %this is an image folder with tags
            folder_count = folder_count + 1;
            folders{folder_count} = folder_name;
            %make the date of the experiment into a tag
            path = strsplit(folder_name,filesep);
            date_folder = path{length(path)-1};
            my_tags = textread([folder_name, filesep, 'tags.txt'], '%s', 'delimiter', ' ');
            folder_tags(1,1) = {[my_tags; date_folder]};
        end
    else
        %this is a parent folder
        allFiles = dir(folder_name); %get all the subfolders
        for file_index = 1:length(allFiles)
            if allFiles(file_index).isdir && ~strcmp(allFiles(file_index).name, '.') && ~strcmp(allFiles(file_index).name, '..')
                %recursively add experimental folders
                [sub_folders, sub_folder_tags, sub_folder_count] = catalog_tags([folder_name, filesep, allFiles(file_index).name]);
                folders = [folders, sub_folders];
                folder_tags = [folder_tags, sub_folder_tags];
                folder_count = folder_count + sub_folder_count;
            end
        end
    end
    

end
