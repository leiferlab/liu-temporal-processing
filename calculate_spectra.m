function success = calculate_spectra(folder_name)
% Take the PCA projections and get the spectrogram and directionality

    addpath(genpath(pwd))
    %set up parameters
    parameters = load_parameters(folder_name);
    
    if parameters.TrackOnly
        success = true;
        return
    end
    
    relevant_track_fields = {'ProjectedEigenValues','Frames','Velocity'};

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

    %% get the spectra
    [Spectra, ~, ~, Amps, ~] = generate_spectra({Tracks.ProjectedEigenValues}, {Tracks.Velocity}, parameters);

    Tracks(1).Spectra = [];  %preallocate memory
    Tracks(1).Amps = [];
    for track_index = 1:length(Spectra)
        Tracks(track_index).Spectra = Spectra{track_index};
        Tracks(track_index).Amps = Amps{track_index};
    end
    
    %save
    savetracks(Tracks, folder_name);
    success = true;    
 end