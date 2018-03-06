function [Spectra, SpectraFrames, SpectraTracks, Amps, f] = generate_spectra(Projections, Velocities, parameters)
%This function gets the wavelet transform given tracks

    L = length(Projections);
    Spectra = cell(1,L); %full wavelet transform
    SpectraFrames = cell(1,L); %keep track of each datapoint's frame indecies
    SpectraTracks = cell(1,L); %keep track of each datapoint's track index
    %datapoint_count = 1;
    for track_index = 1:L
        [feature_vector,f] = findWavelets(Projections{track_index}',parameters.pcaModes,parameters);  

        %find phase velocity and add it to the spectra
        phi_dt = Velocities{track_index};

        %binary option
        forward_vector = zeros(length(phi_dt),1);
        forward_vector(phi_dt > 0) = 1;
        forward_vector = forward_vector + 1;
        Spectra{track_index} = [feature_vector, forward_vector];

%         %no phase velocity option
%         Spectra{track_index} = feature_vector;
        
        SpectraFrames{track_index} = 1:size(Spectra{track_index},1);
        SpectraTracks{track_index} = repmat(track_index,1,size(Spectra{track_index},1));

        if ~mod(track_index, 100)
            disp(['spectra generated for ' num2str(track_index) ' of ' num2str(L) ' ' num2str(track_index/L*100) ' percent']);
        end
    end
      
    %normalize
    data = vertcat(Spectra{:});

    phi_dt = data(:,end); %get phase velocity
    phi_dt = phi_dt ./ parameters.pcaModes; % weigh the phase velocity as a PCA mode (1/5)

    % normalize the phase velocity
    data = data(:,1:end-1);
    temp_amps = sum(data,2);
    data(:) = bsxfun(@rdivide,data,temp_amps);
    data = [data, phi_dt];

    temp_amps = sum(data,2);
    data(:) = bsxfun(@rdivide,data,temp_amps);

    Amps = cell(1,L);
    
    
    %remake Spectra
    start_index = 1;
    for track_index = 1:length(Spectra)
        end_index = start_index + size(Spectra{track_index},1) - 1;
        Spectra{track_index} = data(start_index:end_index, :);
        Amps{track_index} = temp_amps(start_index:end_index, :);
        start_index = end_index + 1;
    end
    
    f = fliplr(f);
end

