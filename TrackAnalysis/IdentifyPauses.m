function Pauses = IdentifyPauses(Track, Prefs)

% This function receives a structure Track and  identifies the time the worm
% paused. The results of this analysis are stored in the struct Track
% (in the field Track.Pauses) and returned to the calling function.

PauseSpeedThresh = Prefs.PauseSpeedThresh;
MinPauseDuration = Prefs.MinPauseDuration;
PotentialPauses = [];

% Find Pauses
% ---------------
Pauses = zeros(1, length(Track.SmoothSpeed));
Pauses(find(abs(Track.SmoothSpeed) < PauseSpeedThresh)) = 1;
% PauseI = PauseI(find(PauseI > Prefs.SampleRate & PauseI < length(Track.Frames) - Prefs.SampleRate));            % Disregard first and last second of movie
Pauses(1) = 0;
Pauses(end) = 0;
if isempty(Pauses)
    PotentialPauses = [];
else
    ChangeInPauseState = diff(Pauses);
    PauseStarts = find(ChangeInPauseState == 1) + 1;
    PauseEnds = find(ChangeInPauseState == -1);
    PotentialPauses = cat(2, PauseStarts', PauseEnds');
%     PauseEndI = find(diff(PauseI) > Prefs.MaxShortRun*Prefs.SampleRate); %remove pauses detected for the next MaxShortRun seconds
%     
%     if isempty(PauseEndI)
%         PotentialPauses = [PauseI(1), PauseI(length(PauseI))];
%     else
%         PotentialPauses = [PauseI(1), PauseI(PauseEndI(1))];
%         for j = 1:length(PauseEndI)-1
%             PotentialPauses = [PotentialPauses; PauseI(PauseEndI(j)+1), PauseI(PauseEndI(j+1))]; %the beginning of deep ventral bends are spaced by at least 6 seconds. The end is the very next time the worm changes directions from the start
%         end
%         PotentialPauses = [PotentialPauses; PauseI(PauseEndI(length(PauseEndI))+1), PauseI(length(PauseI))]; 
%     end
%     if Track.NumFrames - PauseI(length(PauseI)) < Prefs.MaxShortRun*Prefs.SampleRate
%         PotentialPauses(length(PotentialPauses(:,2)), 2) = Track.NumFrames;
%     end
    
end

Pauses = [];

% Remove pauses less than a threshold amount of time
for pause_index = 1:size(PotentialPauses,1)
    if PotentialPauses(pause_index,2) - PotentialPauses(pause_index,1) >= MinPauseDuration*Prefs.SampleRate
        Pauses = [Pauses; PotentialPauses(pause_index, :)];
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