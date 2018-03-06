function PlotFrame(FigH, Frame, Tracks, frame_index, LEDVoltage)

figure(FigH)
imshow(Frame);
hold on;

if nargin < 4
    %plot during tracking
    if ~isempty(Tracks)
        ActiveTracks = find([Tracks.Active]);
    else
        ActiveTracks = [];
    end

    for i = 1:length(ActiveTracks)
        figure(FigH)
        plot(Tracks(ActiveTracks(i)).Path(:,1), Tracks(ActiveTracks(i)).Path(:,2), 'r');
        plot(Tracks(ActiveTracks(i)).LastCoordinates(1), Tracks(ActiveTracks(i)).LastCoordinates(2), 'wo');
        text(Tracks(ActiveTracks(i)).LastCoordinates(1)+10, Tracks(ActiveTracks(i)).LastCoordinates(2)+10, num2str(ActiveTracks(i)), 'color', 'g')
    end
else
    %plot after analysis
    if ~isempty(Tracks)
        track_indecies_in_frame = find([Tracks.Frames] == frame_index);
        frameSum = 0;
        currentActiveTrack = 1; %keeps the index of the track_indecies_in_frame
        myColors = winter(length(track_indecies_in_frame));
        for i = 1:length(Tracks)
            if currentActiveTrack > length(track_indecies_in_frame)
                %all active tracks found
                break;
            end
            if track_indecies_in_frame(currentActiveTrack) - frameSum <= Tracks(i).NumFrames 
                %active track found
                in_track_index = track_indecies_in_frame(currentActiveTrack) - frameSum;
                plot(Tracks(i).Path(1:in_track_index,1), Tracks(i).Path(1:in_track_index,2), 'Color', myColors(currentActiveTrack,:));
                currentActiveTrack = currentActiveTrack + 1;
            end
            frameSum = frameSum + Tracks(i).NumFrames;
        end
    end
    if nargin > 4
        %LEDVoltage specified, plot it
        [frame_h, frame_w] = size(Frame);
        plot_x = ceil(frame_w - (frame_w/10));
        plot_y = ceil(frame_h/10);
        plot(plot_x, plot_y, 'o', 'MarkerSize', 30, 'MarkerEdgeColor','none', 'MarkerFaceColor',[max(LEDVoltage/10,0) 0 0])
    end
    
end


hold off;    % So not to see movie replay