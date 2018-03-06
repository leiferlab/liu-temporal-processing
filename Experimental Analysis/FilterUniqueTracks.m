function [ filteredTracks ] = FilterUniqueTracks(Tracks)
%Takes a list of tracks and only keeps tracks that are unique
%   Detailed explanation goes here
    %fps = 14;
    filteredTracks = [];
    
    %find the frame after the first loss of track
    first_frame_lost = max([Tracks.Frames]);
    for track_index = 1:length(Tracks)
        currentTrack = Tracks(track_index);
        if first_frame_lost > max(currentTrack.Frames)
            first_frame_lost = max(currentTrack.Frames);
        end
    end
    first_frame_lost = first_frame_lost + 1;
    
    %any new tracks after might not be unique
    for track_index = 1:length(Tracks)
        currentTrack = Tracks(track_index);
        if min(currentTrack.Frames) < first_frame_lost
            filteredTracks = [filteredTracks, currentTrack];
        end
    end
end
