function Pirouettes = IdentifyPirouettes(Track, Prefs)

% This function receives a structure Track and automatically identifies pirouettes  
% in the track data. The results of this analysis are stored in the struct Track
% (in the field track.Pirouettes) and returned to the calling function.

% Identified pirouettes are stored in Track as two columns of indices - the first
% indicating pirouette start indices, the second indicating corresponding
% pirouette end indices. 

% Calculate Angular velocity pirouette threshold
% ----------------------------------------------
% Esqr = mean((Track.AngSpeed).^2);
% E = mean(abs(Track.AngSpeed));
% AverageAngSpeed = sqrt(Esqr);
% PirThreshMult = 1.5;
% AngSpeedSTD = sqrt(Esqr - E^2);
% PirThresh = max(AverageAngSpeed * PirThreshMult, Prefs.PirThresh);
PirThresh = Prefs.PirThresh;
PirSpeedThresh = Prefs.PirSpeedThresh;

% Find Pirouettes
% ---------------
PirI = find(abs(Track.AngSpeed) > PirThresh & Track.SmoothSpeed > PirSpeedThresh);
PirI = PirI(find(PirI > Prefs.SampleRate & PirI < length(Track.Frames) - Prefs.SampleRate));            % Disregard first and last second of movie
if isempty(PirI)
    PotentialPirouettes = [];
else
    PirEndI = find(diff(PirI) > Prefs.MaxShortRun*Prefs.SampleRate); %remove reversals detected for the next MaxShortRun seconds
    if isempty(PirEndI)
        PotentialPirouettes = [PirI(1), PirI(length(PirI))];
    else
        PotentialPirouettes = [PirI(1), PirI(PirEndI(1))];
        for j = 1:length(PirEndI)-1
            PotentialPirouettes = [PotentialPirouettes; PirI(PirEndI(j)+1), PirI(PirEndI(j+1))]; %the beginning of reversals are spaced by at least 6 seconds. The end is the very next time the worm changes directions from the start
        end
        PotentialPirouettes = [PotentialPirouettes; PirI(PirEndI(length(PirEndI))+1), PirI(length(PirI))]; 
    end
    if Track.NumFrames - PirI(length(PirI)) < Prefs.MaxShortRun*Prefs.SampleRate
        PotentialPirouettes(length(PotentialPirouettes(:,2)), 2) = Track.NumFrames;
    end
end

Pauses = Track.Pauses;
Pirouettes = [];
% A reversal cannot start during a pause
for pirouette_index = 1:size(PotentialPirouettes,1)
    Pirouette_start_during_pause = 0;
    for pause_index = 1:size(Pauses,1)
        if PotentialPirouettes(pirouette_index, 1) >= Pauses(pause_index,1) && PotentialPirouettes(pirouette_index, 1) <= Pauses(pause_index,2)
            %the reversal starts during a pause, remove it
            Pirouette_start_during_pause = 1;
        end
    end
    if ~Pirouette_start_during_pause
        Pirouettes = [Pirouettes; PotentialPirouettes(pirouette_index,:)];
    end
end


% x = Track.Frames(Pirouettes)
    