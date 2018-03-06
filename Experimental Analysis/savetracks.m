function [] = savetracks(Tracks, folder_name, overwrite, fields_to_save)
%save the tracks as individual variables given folders
    savePath = [folder_name, filesep, 'analysis'];
    
    if nargin < 3
        %default is to not overwrite values already calculated that are not in the track
        overwrite = false; 
    end
    if nargin < 4
        fields_to_save = {};
    end
    
    
    if ~exist(savePath, 'dir')
        mkdir(savePath)
    elseif overwrite
        %overwrite the previous track variables by deleting the analysis
        %folder
        delete([savePath, filesep, '*.*']);
    end
    
    field_names = fieldnames(Tracks);
    for field_index = 1:length(field_names)
        %save each field of the track individually
        field_name = field_names{field_index};
        if isempty(fields_to_save) || ismember(field_name,fields_to_save)
            values = {Tracks.(field_name)}; %turn the data into cell format and save it
            saveFileName = [savePath, filesep, field_name, '.mat'];
            save(saveFileName, 'values', '-v7.3');
        end
    end
end

