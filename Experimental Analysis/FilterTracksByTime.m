function [filteredTracks, track_indecies_preserved] = FilterTracksByTime(Tracks, startFrame, endFrame, entire_duration_required)
%Takes a list of tracks and filters them based on start and end frames.
%   Detailed explanation goes here
    %fps = 14;
    if nargin < 4
        entire_duration_required = false;
    end
    filteredTracks = [];
    track_indecies_preserved = false(1,length(Tracks));
    for track_index = 1:length(Tracks)
        current_filtered_track = CutTrackByFrame(Tracks(track_index), startFrame, endFrame);
        if ~isempty(current_filtered_track)
            if ~entire_duration_required || length(current_filtered_track.Frames) == endFrame-startFrame+1
                filteredTracks = [filteredTracks, current_filtered_track];
                track_indecies_preserved(track_index) = true;
            end
        end
    end
    track_indecies_preserved = find(track_indecies_preserved);
end
