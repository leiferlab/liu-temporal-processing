function [LNPStats, meanLEDPower, stdLEDPower] = FitLNP(Tracks,folder_indecies,folders,cross_valdiation)
%FitLNP takes in tracks and outputs the parameters of the LNP
    numbins = 10;
    
    if nargin<4
        cross_valdiation = false;
    end
    
    fps = 14;
    BTA_seconds_before_and_after = 10;
    seconds_before = BTA_seconds_before_and_after;
    seconds_after = BTA_seconds_before_and_after;
    BTA_length = (fps*seconds_before)+(fps*seconds_after)+1;
    
    if ~isfield(Tracks, 'Behaviors')
        Tracks = get_behavior_triggers(Tracks);
    end
    
    %filter out tracks that are too short
    indecies_to_remove = [];
    for track_index = 1:length(Tracks)
        if length(Tracks(track_index).Frames) < BTA_length
            indecies_to_remove = [indecies_to_remove, track_index];
        end
    end
    Tracks(indecies_to_remove) = [];
    folder_indecies(indecies_to_remove) = [];
    
    number_of_behaviors = size(Tracks(1).Behaviors,1);

    %get all the LEDVoltages from all experiments
    all_LEDVoltages = cell(1,length(folders));
    meanLEDVoltages = cell(1,length(folders));
    for folder_index = 1:length(folders)
        folder_name = folders{folder_index};
        % Load Voltages
        fid = fopen([folder_name, filesep, 'LEDVoltages.txt']);
        all_LEDVoltages{folder_index} = transpose(cell2mat(textscan(fid,'%f','HeaderLines',0,'Delimiter','\t'))); % Read data skipping header
        meanLEDVoltages{folder_index} = mean(all_LEDVoltages{folder_index});
        fclose(fid);
    end
    
    allLEDPower = [Tracks.LEDPower];
%     allLEDPower = [Tracks.LEDVoltages];
    meanLEDPower = mean(allLEDPower);
    stdLEDPower = std(allLEDPower);

%     allLEDVoltages = [Tracks.LEDVoltages];
%     meanLEDVoltages = mean(allLEDVoltages);

    
    %calculate the BTA and linear kernel
    Behaviors = {Tracks(:).Behaviors};
    LEDPowers = {Tracks(:).LEDPower};
    [BTA, trigger_count, BTA_std, BTA_stats] = BehaviorTriggeredAverage(Behaviors, LEDPowers, ~cross_valdiation);
    clear Behaviors LEDPowers

    linear_kernel = BTA_to_kernel(BTA, BTA_stats, meanLEDPower, ~cross_valdiation);

    %smooth the linear_kernel? Approximate by gaussian and exponential?
    
    LNPStats(number_of_behaviors).BTA = [];
    LNPStats(number_of_behaviors).BTA_std = [];
    LNPStats(number_of_behaviors).linear_kernel = [];
    LNPStats(number_of_behaviors).trigger_count = [];
    LNPStats(number_of_behaviors).BTA_norm = [];
    LNPStats(number_of_behaviors).shuffle_norms = [];
    LNPStats(number_of_behaviors).BTA_percentile = [];
    
    LNPStats(number_of_behaviors).non_linearity_fit = [];
    LNPStats(number_of_behaviors).bin_edges = [];
    LNPStats(number_of_behaviors).filtered_signal_histogram = [];
    LNPStats(number_of_behaviors).filtered_signal_given_reversal_histogram = [];
  
    all_behaviors = horzcat(Tracks.Behaviors);
    
    for behavior_index = 1:number_of_behaviors
        LNPStats(behavior_index).BTA = BTA(behavior_index,:);    
        LNPStats(behavior_index).BTA_std = BTA_std(behavior_index,:);    
        LNPStats(behavior_index).linear_kernel = linear_kernel(behavior_index,:);
        LNPStats(behavior_index).trigger_count = trigger_count(behavior_index,:);
        
        if isempty(BTA_stats)
            LNPStats(behavior_index).BTA_norm = [];
            LNPStats(behavior_index).shuffle_norms = [];
            LNPStats(behavior_index).BTA_percentile = [];

        else
            LNPStats(behavior_index).BTA_norm = BTA_stats.BTA_norm(behavior_index);
            LNPStats(behavior_index).shuffle_norms = BTA_stats.shuffle_norms(behavior_index,:);
            LNPStats(behavior_index).BTA_percentile = BTA_stats.BTA_percentile(behavior_index);
        end
        
        if isempty(nonzeros(linear_kernel(behavior_index,:)))
            %special case: flat kernel, the nonlinearity predicts the mean
            %rate. find the mean rate
            bin_centers = 0:numbins-1;
            mean_transition_rate = sum(all_behaviors(behavior_index,:))/size(all_behaviors,2)*fps*60;
            non_linearity = repmat(mean_transition_rate,1,numbins);
            LNPStats(behavior_index).bin_edges = bin_centers;
            LNPStats(behavior_index).filtered_signal_histogram = [];
            LNPStats(behavior_index).filtered_signal_given_reversal_histogram = [];
            LNPStats(behavior_index).non_linearity_fit = fit(bin_centers',non_linearity','exp1');
            LNPStats(behavior_index).non_linearity = non_linearity;
            LNPStats(behavior_index).bin_centers = bin_centers;
            LNPStats(behavior_index).errors = zeros(1,numbins);
        else            
           
            %calculate the filtered LEDVoltages for all experiments
            all_filtered_LEDVoltages = cell(1,length(folders));
            for folder_index = 1:length(folders)
                %convolve the linear kernels with the input signal of LED voltages
%                 all_filtered_LEDVoltages{folder_index} = conv(all_LEDVoltages{folder_index}-meanLEDVoltages{folder_index}, linear_kernel(behavior_index,:), 'same');
                all_filtered_LEDVoltages{folder_index} = padded_conv(all_LEDVoltages{folder_index}-meanLEDVoltages{folder_index}, linear_kernel(behavior_index,:));
            end
            
            %get all the filtered signals concatenated together
            all_filtered_signal = zeros(1, length(allLEDPower));
            current_frame_index = 1;
            for track_index = 1:length(Tracks)
                current_LEDVoltages2Power = Tracks(track_index).LEDVoltage2Power;
                filtered_signal = current_LEDVoltages2Power .* all_filtered_LEDVoltages{folder_indecies(track_index)}(Tracks(track_index).Frames);
                all_filtered_signal(current_frame_index:current_frame_index+length(Tracks(track_index).Frames)-1) = filtered_signal;
                current_frame_index = current_frame_index+length(Tracks(track_index).Frames);
            end

            %make histogram of filtered signal
            current_bin_edges = linspace(min(all_filtered_signal), max(all_filtered_signal), numbins+1);
            current_bin_edges(end) = current_bin_edges(end) + 1;
            LNPStats(behavior_index).bin_edges = current_bin_edges;

            [current_filtered_signal_histogram, ~] = histc(all_filtered_signal, current_bin_edges);
            current_filtered_signal_histogram = current_filtered_signal_histogram(1:end-1);
            LNPStats(behavior_index).filtered_signal_histogram = current_filtered_signal_histogram;

            %get histogram of filtered_signal given a reversal
            current_filtered_signal_given_behavior = all_filtered_signal(all_behaviors(behavior_index,:));
            current_filtered_signal_given_behavior_histogram = histc(current_filtered_signal_given_behavior, current_bin_edges);
            current_filtered_signal_given_behavior_histogram = current_filtered_signal_given_behavior_histogram(1:end-1);
            LNPStats(behavior_index).filtered_signal_given_reversal_histogram = current_filtered_signal_given_behavior_histogram;
        %     figure
        %     bar(bin_edges(1:end-1), filtered_signal_given_reversal_histogram');
        %     set(gca,'XTick',round(bin_edges*100)/100)
            [LNPStats(behavior_index).non_linearity_fit, LNPStats(behavior_index).non_linearity, ...
                LNPStats(behavior_index).bin_centers, LNPStats(behavior_index).errors] = ...
                fit_nonlinearity(current_filtered_signal_given_behavior_histogram, current_filtered_signal_histogram, current_bin_edges);
            disp(num2str(behavior_index));
        end
    end
end

