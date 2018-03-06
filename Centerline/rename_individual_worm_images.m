function [] = rename_individual_worm_images(folder_name, beginIndex, endIndex, shift)
% renames the individually saved matrices by shift
    if beginIndex > endIndex
        return
    elseif shift > 0
        %shift up
        shift_indecies = endIndex:-1:beginIndex;
    elseif shift < 0
        %shift down
        shift_indecies = beginIndex:endIndex;
    else
        %shift == 0
        return
    end

    for track_index = shift_indecies
        current_file_name = [folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', num2str(track_index), '.mat'];
        if ~exist(current_file_name, 'file')
            break;
        end
        new_file_name = [folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', num2str(track_index+shift), '.mat'];
        try
            movefile(current_file_name, new_file_name, 'f');
        catch
            %sometimes it takes a bit of time for windows to react
            pause(5)
            movefile(current_file_name, new_file_name, 'f');
        end
    end
end