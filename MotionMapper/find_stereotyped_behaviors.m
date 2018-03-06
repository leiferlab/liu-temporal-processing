function Tracks = find_stereotyped_behaviors(Tracks, L, xx)
    %enforces the constraint that stereotyped behaviors have stay in a
    %watershed region for more than 0.5 seconds in order for it to count
    
    fps = 14;
    % velocity_cutoff = 27; %% need to load in value
    velocity_cutoff = 10^6; % no velocity cutoff used
    duration_cutoff = 0.5 * fps;

%     Stereotyped_Behaviors = cell(size(Embeddings));
    if isempty(Tracks)
        return
    else
        Tracks(1).BehavioralTransition = []; %preallocate memory
    end

    for track_index = 1:length(Tracks)
        % get a sequence of watershed values
        behavioral_annotation = behavioral_space_to_behavior(Tracks(track_index).Embeddings, L, xx);
        % get a logical sequence that is 1s for when the animal is staying in a
        % watershed region and 0s during transitions to another watershed
        behavioral_transitions = [0, diff(double(behavioral_annotation))];
        behavioral_transitions_logical_indexing = behavioral_transitions == 0;

        % find the velocity in behavioral space
        bs_velocity = sqrt(diff(Tracks(track_index).Embeddings(:,1)).^2 + diff(Tracks(track_index).Embeddings(:,2)).^2);
        bs_velocity_thresholded_logical_indexing = [0, bs_velocity' < velocity_cutoff];

        % a stereotyped behavior has to stay in one watershed and below the
        %velocity threshold, this is the logical indexing of it. The worm
        %never begins or ends the track in a stereotyped behavior 
        stereotyped_behavior_logical_indexing = and(behavioral_transitions_logical_indexing, bs_velocity_thresholded_logical_indexing);
        stereotyped_behavior_logical_indexing(end) = false;

        %the beginnings of stereotyped behaviors matches pattern [0 1]
        stereotyped_behavior_beginnings = strfind(stereotyped_behavior_logical_indexing, [false true]) + 1;
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
            disp(['error: ' num2str(length(stereotyped_behavior_transition_beginnings_logical)) ' ' num2str(length(stereotyped_behavior_annotation))])
        end

        %define transitions as changes stereotyped behaviors
        Tracks(track_index).BehavioralTransition = [stereotyped_behavioral_transition_annotation', ...
            stereotyped_behavior_transition_beginnings', stereotyped_behavior_transition_ends', stereotyped_behavior_transition_duration'];
    end

end
