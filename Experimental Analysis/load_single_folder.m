function [ Tracks ] = load_single_folder(folder_name, field_names)
%get the tracks given a single folder

    if nargin < 2
        field_names = {};
    end
    Tracks = [];
    analysis_folder_name = [folder_name, filesep, 'analysis'];
    if exist(analysis_folder_name, 'dir')
        %use new data structure system if available
        if isempty(field_names)
            %load everything
            matlab_files = dir([analysis_folder_name, filesep, '*.mat']); 
            file_names = {matlab_files.name};
            for file_index = 1:length(file_names)
                field_names{file_index} = file_names{file_index}(1:end-4);
            end
        end
        %load the fields individually and put them in cells
        cell_tracks = [];
        for field_index = 1:length(field_names)
            file_name = [analysis_folder_name,filesep,field_names{field_index},'.mat'];
            if exist(file_name, 'file') == 2
                values = load(file_name);
                cell_tracks = [cell_tracks; values.values];
            else
                %there is a missing field requested, return nothing
                Tracks = [];
                return
            end
        end
        %convert into struct
        Tracks = cell2struct(cell_tracks,field_names,1)';
    elseif exist([folder_name, filesep, 'Tracks.mat'], 'file') == 2
        load([folder_name, filesep, 'Tracks.mat'])
        if ~isempty(field_names)
            track_fields = fieldnames(Tracks);
            if ~all(ismember(field_names, track_fields))
                %some fields requested do not exist, return nothing
                Tracks = [];
                return
            else
                %filter out the relevant fields
                fields_to_remove = ~ismember(track_fields, field_names);
                Tracks = rmfield(Tracks, track_fields(fields_to_remove));
            end
        end
    end

end

