function [Tracks, number_of_behaviors] = find_stereotyped_behaviors_from_velocity(Tracks)
    % not used in paper
    number_of_behaviors = 5;
    fps = 14;

    duration_cutoff = 0.5 * fps;

    if isempty(Tracks)
        return
    else
        Tracks(1).BehavioralTransition = []; %preallocate memory
    end
    
    Speeds = [Tracks.Speed];
    
    speed_ranges = min(Speeds);
    for behavior_index = 1:number_of_behaviors-1
        speed_ranges = [speed_ranges, prctile(Speeds, behavior_index/number_of_behaviors*100)];
    end
    speed_ranges = [speed_ranges, max(Speeds)];
    

    for track_index = 1:length(Tracks)
        % get a sequence of binned velocity behavior values
        behavioral_annotation = zeros(1,length(Tracks(track_index).Frames));
        for range_index = 1:number_of_behaviors
            range_min = speed_ranges(range_index);
            range_max = speed_ranges(range_index+1);
            behavioral_annotation(and(Tracks(track_index).Speed >= range_min, Tracks(track_index).Speed < range_max)) = range_index;
        end
        
        % get a logical sequence that is 1s for when the animal is staying in a
        % watershed region and 0s during transitions to another watershed
        behavioral_transitions = [0, diff(double(behavioral_annotation))];
        behavioral_transitions_logical_indexing = behavioral_transitions == 0;

        % a stereotyped behavior has to stay in one watershed and below the
        %velocity threshold, this is the logical indexing of it. The worm
        %never begins or ends the track in a stereotyped behavior 
        stereotyped_behavior_logical_indexing = behavioral_transitions_logical_indexing;
        stereotyped_behavior_logical_indexing(end) = false;

        %the beginnings of stereotyped behaviors matches pattern [0 1]
        stereotyped_behavior_beginnings =[1, strfind(stereotyped_behavior_logical_indexing, [false true]) + 1];
        %the ends of stereotyped behaviors matches pattern [1 0]
        stereotyped_behavior_ends = strfind(stereotyped_behavior_logical_indexing, [true false]);

        stereotyped_behavior_annotation = double(behavioral_annotation(stereotyped_behavior_beginnings));
        stereotyped_behavior_duration = stereotyped_behavior_ends-stereotyped_behavior_beginnings;

%         Stereotyped_Behaviors{track_index} = [stereotyped_behavior_annotation; stereotyped_behavior_beginnings; ...
%             stereotyped_behavior_ends; stereotyped_behavior_duration]';

        %filter for duration cutoff
        duration_filter_logical = stereotyped_behavior_duration >= duration_cutoff;
        stereotyped_behavior_annotation = stereotyped_behavior_annotation(duration_filter_logical);
        stereotyped_behavior_beginnings = stereotyped_behavior_beginnings(duration_filter_logical);
        stereotyped_behavior_ends = stereotyped_behavior_ends(duration_filter_logical);

        %combine adjacent stereotyped behaviors if they are the same
        stereotyped_behavior_transition_beginnings_logical = [true, logical(abs(diff(stereotyped_behavior_annotation)))];
        stereotyped_behavior_transition_ends_logical = true(size(stereotyped_behavior_transition_beginnings_logical));

        %find repeated stereotyped behaviors
        stereotyped_behavior_transition_ends_logical(strfind(stereotyped_behavior_transition_beginnings_logical, [true false])) = false;
        stereotyped_behavior_transition_ends_logical(strfind(stereotyped_behavior_transition_beginnings_logical, [false false])) = false;

        if length(stereotyped_behavior_transition_beginnings_logical) == length(stereotyped_behavior_annotation)
            stereotyped_behavioral_transition_annotation = stereotyped_behavior_annotation(stereotyped_behavior_transition_beginnings_logical);
            stereotyped_behavior_transition_beginnings = stereotyped_behavior_beginnings(stereotyped_behavior_transition_beginnings_logical);
            stereotyped_behavior_transition_ends = stereotyped_behavior_ends(stereotyped_behavior_transition_ends_logical);
            stereotyped_behavior_transition_duration = stereotyped_behavior_transition_ends - stereotyped_behavior_transition_beginnings;
        else
            a = 1;
        end

        %define transitions as changes stereotyped behaviors
        Tracks(track_index).BehavioralTransition = [stereotyped_behavioral_transition_annotation', ...
            stereotyped_behavior_transition_beginnings', stereotyped_behavior_transition_ends', stereotyped_behavior_transition_duration'];
    end

end
