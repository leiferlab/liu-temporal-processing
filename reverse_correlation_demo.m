% This script demos how to do reverse correlation to fit LN models after behavioral analysis

relevant_track_fields = {'BehavioralTransition','Frames','LEDPower','LEDVoltage2Power'};    
load('reference_embedding.mat')
number_of_behaviors = max(L(:))-1;

%select folders
folders = getfoldersGUI();

%load tracks
[allTracks, folder_indecies, track_indecies] = loadtracks(folders,relevant_track_fields);

%% fit LN models for each behavior
[LNPStats_nondirectional, meanLEDPower_nondirectional, stdLEDPower_nondirectional] = FitLNP(allTracks,folder_indecies,folders);

% display fitted models
PlotBehavioralMappingExperimentGroup(LNPStats_nondirectional, meanLEDPower_nondirectional, stdLEDPower_nondirectional, L, density, xx)


%% fit context dependent LN models
[LNPStats_directional, meanLEDPower_directional, stdLEDPower_directional] = directional_FitLNP(allTracks,folder_indecies,folders);

% display fitted models
PlotDirectionalBehavioralMappingExperimentGroup(LNPStats_directional, meanLEDPower_directional, stdLEDPower_directional, L, density, xx)