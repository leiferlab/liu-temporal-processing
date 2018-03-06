function [] = individual_worm_videos(Tracks, folder_name, fps, plotting_fps)
% Plots a single worm over time along with its centerline
    frames_per_plot_time = round(fps/plotting_fps);
    for track_index = 1:length(Tracks)
        plotting_index = 1;
        loaded_file = load([folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', num2str(track_index), '.mat']);
        worm_images = loaded_file.worm_images;
        outputVideo = VideoWriter(fullfile([folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', num2str(track_index)]),'Motion JPEG AVI');
        outputVideo.FrameRate = plotting_fps;
        open(outputVideo)

        for worm_frame_index = 1:frames_per_plot_time:size(worm_images,3)
            I = squeeze(worm_images(:,:,worm_frame_index));
            plot_worm_frame(I, squeeze(Tracks(track_index).Centerlines(:,:,worm_frame_index)), ...
                Tracks(track_index).UncertainTips(worm_frame_index), ...
                Tracks(track_index).Eccentricity(worm_frame_index), Tracks(track_index).Direction(worm_frame_index), ...
                Tracks(track_index).Speed(worm_frame_index),  Tracks(track_index).TotalScore(worm_frame_index), plotting_index);
            
%             IWFig = findobj('Tag', ['IWFig', num2str(plotting_index)]);
%             writeVideo(outputVideo, getframe(IWFig));
             writeVideo(outputVideo, getframe(gcf));
        end
        close(outputVideo) 
    end
end