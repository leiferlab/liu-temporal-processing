function OmegaTurns = IdentifyOmegaTurns(Track, Prefs)

% This function receives a structure Track and automatically identifies the time of Omega turns  
% in the track data. The results of this analysis are stored in the struct Track
% (in the field track.OmegaTurns) and returned to the calling function.

EccentricityThresh = Prefs.EccentricityThresh;
%Pirouettes = Track.Pirouettes;
OmegaTurns = [];

% Find Deep Ventral Bends
% ---------------
OmegaI = find(abs(Track.Eccentricity) < EccentricityThresh);
OmegaI = OmegaI(find(OmegaI > Prefs.SampleRate & OmegaI < length(Track.Frames) - Prefs.SampleRate));            % Disregard first and last second of movie
if isempty(OmegaI)
    OmegaTurns = [];
else
    OmegaEndI = find(diff(OmegaI) > Prefs.MaxShortRun*Prefs.SampleRate); %remove deep ventral bends detected for the next MaxShortRun seconds
    
    if isempty(OmegaEndI)
        OmegaTurns = [OmegaI(1), OmegaI(length(OmegaI))];
    else
        OmegaTurns = [OmegaI(1), OmegaI(OmegaEndI(1))];
        for j = 1:length(OmegaEndI)-1
            OmegaTurns = [OmegaTurns; OmegaI(OmegaEndI(j)+1), OmegaI(OmegaEndI(j+1))]; %the beginning of deep ventral bends are spaced by at least 6 seconds. The end is the very next time the worm changes directions from the start
        end
        OmegaTurns = [OmegaTurns; OmegaI(OmegaEndI(length(OmegaEndI))+1), OmegaI(length(OmegaI))]; 
    end
    if Track.NumFrames - OmegaI(length(OmegaI)) < Prefs.MaxShortRun*Prefs.SampleRate
        OmegaTurns(length(OmegaTurns(:,2)), 2) = Track.NumFrames;
    end
end


% for pirouette_run_index = 1:size(Pirouettes, 1)
%     %loop through all the pirouettes
%     pirouette_run_eccentricity = Track.Eccentricity(Pirouettes(pirouette_run_index,1):Pirouettes(pirouette_run_index,2));
%     eccentricity_below_thresh = find(pirouette_run_eccentricity < EccentricityThresh, 1, 'first');
%     if ~isempty(eccentricity_below_thresh)
%         OmegaTurns = [OmegaTurns, eccentricity_below_thresh+Pirouettes(pirouette_run_index,1)-1];
%     end
% end