function [ Behaviors ] = circshift_triggers(Behaviors, BTA_seconds_before_and_after, randomize, remove_edge)
% Shifts the triggers for each track randomly and removes any behavior
% transistions that are too close to the edge if the options call for its
    if nargin<3
        randomize = false;
    end
    if nargin<4
        remove_edge = false;
    end
    fps = 14;
    distance_to_edge = fps*BTA_seconds_before_and_after;
    if randomize
       %parfor track_index = 1:length(Behaviors)
       for track_index = 1:length(Behaviors)
            shift = unidrnd(size(Behaviors{track_index},2));
            Behaviors{track_index} = circshift(Behaviors{track_index},shift,2);
            if remove_edge
                Behaviors{track_index} = Behaviors{track_index}(:,distance_to_edge+1:end-distance_to_edge);
            else
                Behaviors{track_index}(:,1:distance_to_edge) = false;
                Behaviors{track_index}(:,end-distance_to_edge:end) = false;
            end
        end
    else
        %parfor track_index = 1:length(Behaviors)
        for track_index = 1:length(Behaviors)
            if remove_edge
                Behaviors{track_index} = Behaviors{track_index}(:,distance_to_edge+1:end-distance_to_edge);
            else
                Behaviors{track_index}(:,1:distance_to_edge) = false;
                Behaviors{track_index}(:,end-distance_to_edge:end) = false;
            end
        end
    end
end