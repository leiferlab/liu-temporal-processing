function [] = delete_extra_individual_worm_images(folder_name, endIndex)
% delete individual worm image files that are no longer relevant
    individual_worms = dir([folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', '*.mat']); 
    for image_stack_index = 1:length(individual_worms)
        current_file_name = individual_worms(image_stack_index).name;
        find_underscore = strfind(current_file_name, '_');
        find_dot = strfind(current_file_name, '.');
        current_index = str2num(current_file_name(find_underscore(1)+1:find_dot(1)-1));
        if current_index > endIndex
            delete([folder_name, filesep, 'individual_worm_imgs', filesep, current_file_name])
        end
    end
    
    individual_worms = dir([folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', '*.mp4']); 
    for image_stack_index = 1:length(individual_worms)
        current_file_name = individual_worms(image_stack_index).name;
        find_underscore = strfind(current_file_name, '_');
        find_dot = strfind(current_file_name, '.');
        current_index = str2num(current_file_name(find_underscore(1)+1:find_dot(1)-1));
        if current_index > endIndex
            delete([folder_name, filesep, 'individual_worm_imgs', filesep, current_file_name])
        end
    end
end