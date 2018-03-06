function success = tap_preprocessing(folder_name)
%This function does pre-processing for tap experiments, getting rid of
%motion blurred frames so we don't lose track during taps

    shift = 1; % how many frames does it take to see the tap blur after the HIGH voltage
    
    image_files=dir([folder_name, filesep, '*.jpg']); %get all the jpg files (maybe named tif)
    if isempty(image_files)
        image_files = dir([folder_name, filesep, '*.tif']); 
    end
    
    % Load Voltages
    fid = fopen([folder_name, filesep, 'LEDVoltages.txt']);
    LEDVoltages = transpose(cell2mat(textscan(fid,'%f','HeaderLines',0,'Delimiter','\t'))); % Read data skipping header
    fclose(fid);
    
    if length(image_files)-1 > length(LEDVoltages)
        %there are more frames than there are stimulus
        success = false;
        return
    end

    savePath = [folder_name, filesep, 'back_up_images', filesep];
    if ~exist(savePath, 'dir')
        mkdir(savePath)
    end
    
    tap_indecies = find(LEDVoltages > 0);
    
    for tap_index = length(tap_indecies):-1:1
        %loop through every time the tapper actuates from the last to first
        blurred_image_index = tap_indecies(tap_index)+shift; %apply shift
        if blurred_image_index > 2 && blurred_image_index < length(LEDVoltages)
            %ignore if the experiment begins with a tap or ends with a tap
            filename = [folder_name, filesep, image_files(blurred_image_index).name];
            if ~strcmp(filename(end-4),'s')
                %the filename does not end with s, save back up file, and
                %replace it with the previous frame
                
                %find the appropriate frame as replacement, i.e. the
                %nearest undamaged frame from either side
                index_away = 1;
                while true
                    if tap_index+index_away>length(tap_indecies) || tap_indecies(tap_index+index_away)+shift ~= blurred_image_index+index_away
                        %the stutter image is detected at the right side of
                        %the blurred frame
                        replacement_image_index = blurred_image_index+index_away;
                        break
                    elseif tap_index-index_away<1 || tap_indecies(tap_index-index_away)+shift ~= blurred_image_index-index_away
                        %the stutter image is detected at the left side of
                        %the blurred frame                        
                        replacement_image_index = blurred_image_index-index_away;
                        break
                    end
                    index_away = index_away+1;
                end
                
                movefile(filename,[savePath, image_files(blurred_image_index).name],'f');            
                new_file_name = [folder_name, filesep, image_files(blurred_image_index).name(1:end-4), 's', ...
                image_files(blurred_image_index).name(end-3:end)];
                copyfile([folder_name, filesep, image_files(replacement_image_index).name],...
                new_file_name,'f');
            end
        end
    end
    success = true;
end

