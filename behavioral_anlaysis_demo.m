% This script performs behavioral analysis without a cluster

% analysis options
tracking = true; 
finding_centerline = true;
resolving_problems = true;
calculate_spectra = true;
build_new_behavioral_space = false; 
calculate_embedding = true;
calculate_behavior = true;
plotting = true;

parameters = load_parameters(); %load default parameters


%% STEP 1: Select the folders to analyze
[folders, folder_count] = getfoldersGUI();

%% STEP 3: Track and save the individual worm images %%
if tracking
    'Tracking...'
    for folder_index = 1:folder_count
        folder_name = folders{folder_index};
        track_image_directory(folder_name, 'all');
    end
end

%% STEP 4: Find centerlines %%
if finding_centerline
    'Getting Centerlines...'
    for folder_index = 1:folder_count
        folder_name = folders{folder_index}
        find_centerlines(folder_name);
    end 
end

%% STEP 6: Resolve problems
if resolving_problems
    'Resolve Issues'
    for folder_index = 1:folder_count
        folder_name = folders{folder_index}
        auto_resolve_problems(folder_name);
    end 
end


%% STEP 7: do behavioral mapping
if calculate_spectra
   'Getting spectrograms'
    for folder_index = 1:folder_count
        folder_name = folders{folder_index}
        calculate_spectra(folder_name);
    end
end

%% STEP 8 (optional): construct a behavioral map, warning: requires lots of RAM
if build_new_behavioral_space
   'Building behavioral map part 1: t-SNE embedding'
   build_tSNE_map(folders);
end

%% STEP 9: embed the spectra of all the tracks into behavioral map
if calculate_embedding
    'Embedding into behavioral space'
    for folder_index = 1:folder_count
        folder_name = folders{folder_index}
        calculate_embeddings(folder_name);
    end
end

%% STEP X (optional): make watershed, warning: may require lots of RAM
if build_new_behavioral_space
   'Building behavioral map part 2: behavioral segmentation'
    build_behavioral_map(folders);
end

%% STEP X: calculate behaviors
if calculate_behaviors
   'Calculating behaviors'
    for folder_index = 1:folder_count
        folder_name = folders{folder_index}
        calculate_behaviors(folder_name);
    end
end
        
%% STEP 8: Plotting debugging movies
if plotting
    'Plotting..'
    for folder_index = 1:folder_count
        folder_name = folders{folder_index}
        plot_image_directory(folder_name);
    end 
end
