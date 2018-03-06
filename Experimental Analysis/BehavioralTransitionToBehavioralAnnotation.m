function Tracks = BehavioralTransitionToBehavioralAnnotation(Tracks)
%Add Tracks with BehavioralTransition field with BehavioralAnnotation Field
    for track_index = 1:length(Tracks)
       behavioral_annotaiton = zeros(1, length(Tracks(track_index).Frames));
       for transtion_index = 1:size(Tracks(track_index).BehavioralTransition,1)
           behavioral_annotaiton(Tracks(track_index).BehavioralTransition(transtion_index,2): ...
               Tracks(track_index).BehavioralTransition(transtion_index,3)) = ...
               Tracks(track_index).BehavioralTransition(transtion_index,1);
       end
       Tracks(track_index).BehavioralAnnotation = behavioral_annotaiton(1:length(Tracks(track_index).Frames));
    end
end

