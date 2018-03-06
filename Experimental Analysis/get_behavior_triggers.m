function Tracks = get_behavior_triggers(Tracks,randomize)
%this function calculates the Behaviors field, consisting of a binary
%vector that is true for when a particular behavioral transition occurs

    if nargin<2
        randomize = false;
    end

    load('reference_embedding.mat')
    %calculate the triggers for LNP fitting
    number_of_behaviors = max(L(:)-1);
    Tracks(1).Behaviors = [];
    for track_index = 1:length(Tracks)
        triggers = false(number_of_behaviors, length(Tracks(track_index).Frames)); %a binary array of when behaviors occur
        for behavior_index = 1:number_of_behaviors
            transition_indecies = Tracks(track_index).BehavioralTransition(:,1) == behavior_index;
            %transition into of
            transition_start_frames = Tracks(track_index).BehavioralTransition(transition_indecies,2);
            triggers(behavior_index,transition_start_frames) = true;
    %                 %transition out of
    %                 transition_end_frames = Tracks(track_index).BehavioralTransition(transition_indecies,3);
    %                 triggers(behavior_index,transition_end_frames) = true;
        end
        triggers = triggers(:,1:length(Tracks(track_index).Frames));
        if randomize
            %randomly shift the spike train if asked
            shift = unidrnd(size(triggers,2));
            triggers = circshift(triggers,shift,2);
        end
        Tracks(track_index).Behaviors = triggers;
    end

end

