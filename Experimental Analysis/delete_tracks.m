function success = delete_tracks(folder_name)
%delete the tracks given folders
    disp(folder_name)

    deletePath = [folder_name, filesep, 'analysis'];
    if exist(deletePath, 'dir')
        %delete the previous track variables by deleting the analysis
        %folder
        delete([deletePath, filesep, '*.*']);
    end
    success = true;
end

