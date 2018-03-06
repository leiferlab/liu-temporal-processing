function Tracks = get_directional_behavior_triggers(Tracks,randomize)
%this function calculates the Behaviors field, consisting of a binary
%vector that is true for when a particular behavioral transition occurs

    if nargin<2
        randomize = false;
    end

    load('reference_embedding.mat')
    %calculate the triggers for LNP fitting
    number_of_behaviors = max(L(:)-1);
    
    %get a list of behavioral triggers
    no_weight_edges = get_edge_pairs(number_of_behaviors);
    Tracks(1).Behaviors = [];
    number_of_edges = size(no_weight_edges,1);
    
    for track_index = 1:length(Tracks)
        triggers = false(number_of_edges, length(Tracks(track_index).Frames)); %a binary array of when behaviors occur
        for edge_index = 1:number_of_edges
            current_behavioral_transition = Tracks(track_index).BehavioralTransition(:,1)';
            transition_indecies = strfind(current_behavioral_transition,no_weight_edges(edge_index,:))+1;
            %transition into
            transition_start_frames = Tracks(track_index).BehavioralTransition(transition_indecies,2);
            triggers(edge_index,transition_start_frames) = true;
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

