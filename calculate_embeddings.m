function success = calculate_embeddings(folder_name)
% Given the spectrogram, calculate the embedding for every time point
    addpath(genpath(pwd))
    %set up parameters
    parameters = load_parameters(folder_name);
    
    if parameters.TrackOnly
        success = true;
        return
    end    
    
    load('reference_embedding.mat')
    relevant_track_fields = {'Spectra'};

    %% Load tracks
    Tracks = load_single_folder(folder_name, relevant_track_fields);
    if isempty(Tracks)
        error('Empty Tracks');
    end

    try
        parpool(feature('numcores'))
    catch
        %sometimes matlab attempts to write to the same temp file. wait and
        %restart
        pause(randi(60));
        parpool(feature('numcores'))
    end


    data = vertcat(Tracks.Spectra);
    [embeddingValues,~] = findEmbeddings(data,trainingSetData,trainingEmbedding,parameters);
    clear data

    % cut the embeddings
    Tracks(1).Embeddings = []; %preallocate memory
    start_index = 1;
    for track_index = 1:length(Tracks)
        end_index = start_index + size(Tracks(track_index).Spectra,1) - 1;
        Tracks(track_index).Embeddings = embeddingValues(start_index:end_index, :);
        start_index = end_index + 1;
    end

    %save
    savetracks(Tracks, folder_name);
    success = true;    
 end