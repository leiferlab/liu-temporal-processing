function parameters = load_parameters(folder_name)
%loads the parameter structure based on the tags in the experimental folder
%and parameters.csv settings file

    SaveIndividualImages = 1;
    
    if nargin < 1
        tags = {};
    else
        %load the tags
        if exist([folder_name, filesep, 'tags.txt'],'file')
            %this is an image folder with tags
            tags = textread([folder_name, filesep, 'tags.txt'], '%s', 'delimiter', ' ');
        else
            tags = {};
        end
    end

    parameters = load('EigenVectors.mat'); %load eigenvectors for eigenworms
    parameters.SaveIndividualImages = SaveIndividualImages;
    
    param_table = readtable('parameters.csv','ReadVariableNames',false);

    %load the default parameters first
    for tag_index = 3:size(param_table,2)
        current_tags = param_table{1,tag_index}{1,1};
        current_tags = strsplit(current_tags,';');
        if tag_index == 3 || all(ismember(current_tags, tags)) 
            %load the default and the correct tags
            for parameter_index = 2:size(param_table,1)
                value = param_table{parameter_index,tag_index}{1,1};
                number_value = str2double(value);
                param_name = param_table{parameter_index,1}{1,1};
                if isnan(number_value)
                    %string or empty value
                    if ~isempty(value)
                        parameters.(param_name) = value;
                    end
                else
                    %numeric value
                    parameters.(param_name) = number_value;
                end
            end
        end
    end

    if ischar(parameters.Mask) && exist(parameters.Mask, 'file')
       %get the mask
       parameters.Mask = imread(parameters.Mask); 
    end

    if ischar(parameters.power500) && exist(parameters.power500, 'file')
       %get the power distribution
       load(parameters.power500);
       parameters.power500 = power500; 
    end
    
    parameters.ProgressDir = pwd;
    
end

