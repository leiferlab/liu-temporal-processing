function [behavioral_transition_rates,behavioral_transition_rates_std,behavior_occupation_ratio] = find_behavioral_rates(Tracks)
%This function takes in tracks and finds the various rates of behaviors,
%both transitions in transition/min and fraction of time spent in that
%behavior
    fps = 14;

    load('reference_embedding.mat')
    %get the number of behaviors
    number_of_behaviors = max(L(:))-1;
    
    %get transition graph
    [~,~, adj_matrix, adj_matrix_duration_occupied] =  BehavioralTransitionGraph(Tracks, number_of_behaviors, true, 1);
    transition_counts = sum(adj_matrix,1);
    behavior_frame_counts = sum(adj_matrix_duration_occupied,1);

    total_frames = length([Tracks.Frames]);
    
    behavioral_transition_rates = transition_counts./total_frames.*fps.*60; % in transitions/min
    
    %get the error bar on the transition rate
    behavioral_transition_rates_std = sqrt(transition_counts)./total_frames.*fps.*60;

    behavior_occupation_ratio = behavior_frame_counts ./ total_frames;
    behavior_occupation_ratio = [behavior_occupation_ratio, 1-sum(behavior_occupation_ratio)];
%    errorbar(1:number_of_behaviors,behavioral_transition_rates,behavioral_transition_rates_std,'r.','linewidth',2,'markersize',40)
end

