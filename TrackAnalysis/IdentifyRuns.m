function Runs = IdentifyRuns(Track, Prefs)

% This function receives a structure Track and automatically identifies runs  
% in the track data. 
% The results of this analysis are stored in the struct Track
% (in the field track.Runs) and returned to the calling function.

% Identified run are stored in Track as two columns of indices - the first
% indicating run start indices, the second indicating corresponding
% run end indices. 

MaxShortRun = Prefs.MaxShortRun;

% Find Runs
% ---------------
Running = logical(ones(1, length(Track.Frames)));

% The worm is not running during pauses
for pause_index = 1:size(Track.Pauses,1)
    Running(Track.Pauses(pause_index,1):Track.Pauses(pause_index,2)) = 0;
end

% The worm is not running during reversals
for pirouette_index = 1:size(Track.Pirouettes,1)
    Running(Track.Pirouettes(pirouette_index,1):Track.Pirouettes(pirouette_index,2)) = 0;
end

% if Running(end) == 0
%     %make sure that the worm is "running" at the end so that the dimensions
%     %match
%     Running(end) = 1;
% end

StatusChange = diff(Running);

RunStarts = find(StatusChange == 1);
%RunStarts = RunStarts(1:end-1);
RunStarts = RunStarts + 1;
RunStarts = [1, RunStarts]; %Always assume running at the start

RunEnds = find(StatusChange == -1);
%RunEnds = RunEnds(2:end);

% if isempty(RunEnds)
%     %no changes in status, the run ends when the track ends
%     RunEnds = length(Running);
% end

if Running(end) ~= 0
    %The run ends at the end of the track unless it is reversing or paused
    RunEnds = [RunEnds, length(Running)];
end

PotentialRuns = cat(2, RunStarts', RunEnds');

Runs = [];
%Make sure that runs have a minimum time
for run_index = 1:size(PotentialRuns,1)
    if PotentialRuns(run_index,2) - PotentialRuns(run_index,1) >= MaxShortRun*Prefs.SampleRate
        Runs = [Runs; PotentialRuns(run_index, :)];
    end
end