function [folders, folder_count] = getfolders()
%get the experimental folders one by one as the user selects them
    folders = {};
    folder_count = 0;
    start_path = '';
    while true
        folder_name = uigetdir(start_path, 'Select Experiment Folder')
        if folder_name == 0
            break
        else
            if exist([folder_name, '\LEDVoltages.txt'],'file')
                %this is a image folder
                folder_count = folder_count + 1;
                folders{folder_count} = folder_name;
            else
                cd(folder_name) %open the date directory
                allFiles = dir(); %get all the subfolders
                for file_index = 1:length(allFiles)
                    if allFiles(file_index).isdir && ~strcmp(allFiles(file_index).name, '.') && ~strcmp(allFiles(file_index).name, '..')
                        folder_count = folder_count + 1;
                        folders{folder_count} = [folder_name, '\', allFiles(file_index).name];
                    end
                end
            end
            start_path = fileparts([folder_name, '..', 'tracks.mat']); %display the parent folder
        end
    end    
end

