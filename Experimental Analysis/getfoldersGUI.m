function [folders, folder_count] = getfoldersGUI()
%lets ute user select a master parent folder, recrusively map all
%experiments inside by the tags, and allows the user to select a subgroup
%of experimental folders
    [folders, folder_tags, ~] = catalog_tags();

    while true
        %call the gui for resolution while the user is still choosing tags
        h = SelectExperimentByTag(folders, folder_tags);
        movegui(h, 'center');
        uiwait(h);

        selected_tag = h.UserData{3};
        close(h);
        if strcmp(selected_tag, 'All Tags')
            % end loop when the user selects 'All Tags'
            break
        else
            [folders, folder_tags] = filter_folders(folders, folder_tags, selected_tag);
        end
    end
    
    folder_count = length(folders);
end