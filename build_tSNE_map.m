function success = build_tSNE_map(folders)
% build the tSNE map given spectrograms
    addpath(genpath(pwd))

    %% STEP 1: set up parameters
    relevant_track_fields = {'Amps','Spectra'};

    %% STEP 2: Load the analysis preferences %%
    parameters = load_parameters();
    edgeEffectTime = round(sqrt(1/parameters.minF)*parameters.samplingFreq);

    %% STEP 3: load the tracks into memory
    [allTracks, ~, ~] = loadtracks(folders, relevant_track_fields);

    %% STEP 4: convert tracks to cell format
    track_count = length(allTracks);
    Spectra = cell(1,track_count);
    amps = cell(1,track_count);
    SpectraFrames = cell(1,track_count);
    SpectraTracks = cell(1,track_count);
    for track_index = 1:length(allTracks)
        Spectra{track_index} = allTracks(track_index).Spectra;
        amps{track_index} = allTracks(track_index).Amps;
        SpectraFrames{track_index} = 1:size(Spectra{track_index},1);
        SpectraTracks{track_index} = repmat(track_index,1,size(Spectra{track_index},1));
    end

    clear allTracks


    %% STEP 5: Get a set of "training spectra" without edge effects
    TrainingSpectra = cell(1,track_count);
    TrainingSpectraFrames = cell(1,track_count);
    TrainingSpectraTracks = cell(1,track_count);
    TrainingAmps = cell(1,track_count);

    for track_index = 1:track_count
        TrainingSpectra{track_index} = Spectra{track_index}(edgeEffectTime:end-edgeEffectTime,:);
        TrainingSpectraFrames{track_index} = SpectraFrames{track_index}(edgeEffectTime:end-edgeEffectTime);
        TrainingSpectraTracks{track_index} = SpectraTracks{track_index}(edgeEffectTime:end-edgeEffectTime);  
        TrainingAmps{track_index} = amps{track_index}(edgeEffectTime:end-edgeEffectTime); 
        Spectra{track_index} = []; %optional clearing of memory
    end

    clear Spectra amps

    %% STEP 6A: initialize training input
    training_input_data = vertcat(TrainingSpectra{:}); %these timpoints will be randomly sampled from
    clear TrainingSpectra
    training_input_frames = [TrainingSpectraFrames{:}];
    clear TrainingSpectraFrames
    training_input_tracks = [TrainingSpectraTracks{:}];
    clear TrainingSpectraTracks
    training_amps = vertcat(TrainingAmps{:}); 
    clear TrainingAmps

    %% STEP 6B: Find training set by sampling uniformly
    skipLength = round(length(training_input_data(:,1))/parameters.trainingSetSize);
    trainingSetData = training_input_data(skipLength:skipLength:end,:);
    trainingSetAmps = training_amps(skipLength:skipLength:end);
    trainingSetFrames = training_input_frames(skipLength:skipLength:end);
    trainingSetTracks = training_input_tracks(skipLength:skipLength:end);
    clear training_input_data

    %clean memory
    clear iteration_data iteration_amps sampled_indecies iterationEmbedding amps
    clear TrainingSpectra TrainingSpectraFrames TrainingSpectraTracks
    clear training_input_data training_input_frames training_input_tracks training_input_amps

    %% STEP 7: Embed the training set 
    %clear memory
    parameters.signalLabels = log10(trainingSetAmps);

    fprintf(1,'Finding t-SNE Embedding for Training Set\n');
    [trainingEmbedding,betas,P,errors] = run_tSne(trainingSetData,parameters);

    %% STEP 8: update our reference map to the newly constructed one
    save('reference_embedding.mat', 'trainingEmbedding', 'trainingSetData');
    success = true;
end