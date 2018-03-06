function [tap_transition_rate_of_interest,control_transition_rate_of_interest,tap_transition_rate_of_interest_std,control_transition_rate_of_interest_std,h,p,tap_transition_total_count,control_transition_total_count,tap_observation_total_count,control_observation_total_count] = average_transition_rate_after_tap(folders_platetap, behavior_from, behavior_to)
% this function looks at the transition rates after a platetap and compares
% it to the control of the time point in between platetaps. If the
% behavior_from is 0, it is ignored
    load('reference_embedding.mat')
    %load tracks
    relevant_track_fields = {'BehavioralTransition','Frames'};

    %load stimuli.txt from the first experiment
    normalized_stimuli = 1; %delta function
    time_window_before = 0;
%     time_window_after = 14; %transition rate average for 1 seconds after tap
    time_window_after = 28; %transition rate average for 2 seconds after tap
    fps = 14;

    number_of_behaviors = max(L(:)-1);
   
    tap_behaviors_for_frame = cell(1,time_window_before+time_window_after+1);
    control_behaviors_for_frame = cell(1,time_window_before+time_window_after+1);
    tap_observation_total_count = 0;
    control_observation_total_count = 0;  

    %% behavioral rate compare
    for folder_index = 1:length(folders_platetap)
        %for each experiment, search for the occurance of each stimulus after
        %normalizing to 1
        LEDVoltages = load([folders_platetap{folder_index}, filesep, 'LEDVoltages.txt']);
        % LEDVoltages = LEDVoltages(randperm(length(LEDVoltages))); %optional, randomly permuate the taps
        %LEDVoltages(LEDVoltages>0) = 1; %optional, make the stimulus on/off binary

        %find when each stimuli is played back by convolving the time
        %reversed stimulus (cross-correlation)
        xcorr_ledvoltages_stimulus = padded_conv(LEDVoltages, normalized_stimuli);
        peak_thresh = 0.99.*max(xcorr_ledvoltages_stimulus); %the peak threshold is 99% of the max (because edge effects)
        [~, tap_frames] = findpeaks(xcorr_ledvoltages_stimulus, 'MinPeakHeight', peak_thresh,'MinPeakDistance',14);
        
        %generate a series of control taps
        control_frame_shift = round((tap_frames(2)-tap_frames(1))/2); %the control taps are exactly in between taps
        control_LEDVoltages = circshift(LEDVoltages,[0,control_frame_shift]);
        xcorr_ledvoltages_stimulus = padded_conv(control_LEDVoltages, normalized_stimuli);
        [~, control_frames] = findpeaks(xcorr_ledvoltages_stimulus, 'MinPeakHeight', peak_thresh,'MinPeakDistance',14);
        
        %load the tracks for this folder
        [current_tracks, ~, ~] = loadtracks(folders_platetap(folder_index),relevant_track_fields);
        current_tracks = BehavioralTransitionToBehavioralAnnotation(current_tracks);

        %generate the Behavior matricies
        current_tracks = get_behavior_triggers(current_tracks);
        current_tracks(1).LocalFrameIndex = [];
        for track_index = 1:length(current_tracks)
            current_tracks(track_index).LocalFrameIndex = 1:length(current_tracks(track_index).Frames);
        end

        %get the transitions rates for tap condition
        for critical_frame_index = 1:length(tap_frames)
            %for every time a stimulus is delivered, look at a certain range of
            %frames only if the track fits certain criteria
            current_critical_frame = tap_frames(critical_frame_index);
            if current_critical_frame + time_window_after <= length(LEDVoltages) && current_critical_frame - time_window_before >= 1
                %get tracks that last through the entire duration of the window
                tracks_within_critical_window = FilterTracksByTime(current_tracks,current_critical_frame - time_window_before, current_critical_frame + time_window_after, true);
                if ~isempty(tracks_within_critical_window)
                    tracks_on_current_critical_frame = FilterTracksByTime(tracks_within_critical_window,current_critical_frame, current_critical_frame);
                    tap_observation_total_count = tap_observation_total_count + size([tracks_within_critical_window.Frames],2); % keep track of how many observations we take

                    %select the tracks that have the next behavior being behavior to
                    selected_indecies = false(1,length(tracks_within_critical_window));
                    for tracks_within_critical_window_index = 1:length(tracks_within_critical_window)
                        current_behavioral_transitions = tracks_on_current_critical_frame(tracks_within_critical_window_index).BehavioralTransition;
                        current_local_frame_index = [tracks_on_current_critical_frame(tracks_within_critical_window_index).LocalFrameIndex];
                        next_behavior = current_behavioral_transitions(find(current_behavioral_transitions(:,2)>current_local_frame_index,1,'first'),1);
                        if ~isempty(next_behavior) && next_behavior == behavior_to
                            selected_indecies(tracks_within_critical_window_index) = true;
                        end
                    end
                    BehavioralAnnotations = [tracks_on_current_critical_frame.BehavioralAnnotation];
                    if behavior_from > 0
                        selected_tracks = tracks_within_critical_window(and(selected_indecies,BehavioralAnnotations == behavior_from));
                    else
                        selected_tracks = tracks_within_critical_window(selected_indecies);
                    end
                    if ~isempty(selected_tracks)
                        for frame_shift = -time_window_before:time_window_after
                            current_frame = current_critical_frame + frame_shift;
                            tracks_on_critical_frame = FilterTracksByTime(selected_tracks,current_frame, current_frame);
                            tap_behaviors_for_frame{frame_shift+time_window_before+1} = [tap_behaviors_for_frame{frame_shift+time_window_before+1}, tracks_on_critical_frame.Behaviors];
                        end
                    end
                end
            end
        end
        
        %get the transitions rates for control condition
        for critical_frame_index = 1:length(control_frames)
            %for every time a stimulus is delivered, look at a certain range of
            %frames only if the track fits certain criteria
            current_critical_frame = control_frames(critical_frame_index);
            if current_critical_frame + time_window_after <= length(LEDVoltages) && current_critical_frame - time_window_before >= 1
                %get tracks that last through the entire duration of the window
                tracks_within_critical_window = FilterTracksByTime(current_tracks,current_critical_frame - time_window_before, current_critical_frame + time_window_after, true);
                if ~isempty(tracks_within_critical_window)
                    tracks_on_current_critical_frame = FilterTracksByTime(tracks_within_critical_window,current_critical_frame, current_critical_frame);
                    control_observation_total_count = control_observation_total_count + size([tracks_within_critical_window(:).Frames],2); % keep track of how many observations we take

                    %select the tracks that have the next behavior being behavior to
                    selected_indecies = false(1,length(tracks_within_critical_window));
                    for tracks_within_critical_window_index = 1:length(tracks_within_critical_window)
                        current_behavioral_transitions = tracks_on_current_critical_frame(tracks_within_critical_window_index).BehavioralTransition;
                        current_local_frame_index = [tracks_on_current_critical_frame(tracks_within_critical_window_index).LocalFrameIndex];
                        next_behavior = current_behavioral_transitions(find(current_behavioral_transitions(:,2)>current_local_frame_index,1,'first'),1);
                        if ~isempty(next_behavior) && next_behavior == behavior_to
                            selected_indecies(tracks_within_critical_window_index) = true;
                        end
                    end
                    BehavioralAnnotations = [tracks_on_current_critical_frame.BehavioralAnnotation];
                    if behavior_from > 0
                        selected_tracks = tracks_within_critical_window(and(selected_indecies,BehavioralAnnotations == behavior_from));
                    else
                        selected_tracks = tracks_within_critical_window(selected_indecies);
                    end
                    if ~isempty(selected_tracks)
                        for frame_shift = -time_window_before:time_window_after
                            current_frame = current_critical_frame + frame_shift;
                            tracks_on_critical_frame = FilterTracksByTime(selected_tracks,current_frame, current_frame);
                            control_behaviors_for_frame{frame_shift+time_window_before+1} = [control_behaviors_for_frame{frame_shift+time_window_before+1}, tracks_on_critical_frame.Behaviors];
                        end
                    end
                end
            end
        end
    end
    
    %get the transition rate for the tap condition
    tap_transition_counts = [];  
    for frame_index = 1:length(tap_behaviors_for_frame)
        %loop through all the frames and grab the behavioral counts and
        %total observations
        transitions_for_frame = tap_behaviors_for_frame{frame_index};
        tap_transition_counts = [tap_transition_counts, sum(transitions_for_frame,2)];
    end
    if isempty(tap_transition_counts)
        tap_transition_total_count = 0;
    else
        tap_transition_total_count = sum(tap_transition_counts(behavior_to,:),2);
    end
    tap_transition_rate_of_interest = tap_transition_total_count./tap_observation_total_count.*fps.*60; %convert to /min
    tap_transition_rate_of_interest_std = sqrt(tap_transition_total_count)./tap_observation_total_count.*fps.*60;
    
    %get the transition rate for the control condition
    control_transition_counts = [];
    for frame_index = 1:length(control_behaviors_for_frame)
        %loop through all the frames and grab the behavioral counts and
        %total observations
        transitions_for_frame = control_behaviors_for_frame{frame_index};
        control_transition_counts = [control_transition_counts, sum(transitions_for_frame,2)];
    end  
    if isempty(control_transition_counts)
        control_transition_total_count = 0;
    else
        control_transition_total_count = sum(control_transition_counts(behavior_to,:),2);
    end
    control_transition_rate_of_interest = control_transition_total_count./control_observation_total_count.*fps.*60; %convert to /min
    control_transition_rate_of_interest_std = sqrt(tap_transition_total_count)./tap_observation_total_count.*fps.*60;
    
    p = testPoissonSignificance(tap_transition_total_count,control_transition_total_count,tap_observation_total_count,control_observation_total_count,0,2);
    if p > 0.05
        h = false;
    else
        h = true;
    end
   
%     %% plot the differences
%     %calculate the mean and std of the measured transition rates
%     figure('Position', [0, 0, 200, 200]);
%     hold on
%     barwitherr([control_transition_rate_of_interest_std; tap_transition_rate_of_interest_std], [control_transition_rate_of_interest; tap_transition_rate_of_interest])
%     if h
%         sigstar({[1,2]},p);
%     end
%     
%     axis([0 3 0 60])
%     set(gca,'XTickLabel',{'','Control','Tap',''})
%     ylabel('Transition Rate (transitions/worm/min)')
% %     title(['n = ',num2str(length(tap_transition_rates)), ' Experiments'])
end

