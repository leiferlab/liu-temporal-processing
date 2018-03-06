%This script allows the user to pick a watershed region in a t-SNE map and
%finds when the animal stays in that region and plots their behaivor, not used in paper


%% STEP 1: establish plotting constants 
N_rows = 4;
N_columns = 4;
N = N_rows*N_columns;
fps = 14;
frames_before = 1.5*fps-1;
frames_after = 1.5*fps;
duration = frames_before+frames_after+1;
parameters = load_parameters();
load('reference_embedding.mat')
relevant_track_fields = {'BehavioralTransition','Embeddings','Centerlines'};%'Direction','Velocity';


% folders = getfoldersGUI();
% % allow user to select the folder to save as
% pathname = uigetdir('', 'Select Save Folder')
% if isequal(pathname,0)
%     %cancel
%    return
% end
%% STEP 2: allow user to select the folder to save as
[allTracks, folder_indecies, track_indecies] = loadtracks(folders,relevant_track_fields );
if ~exist('Embeddings', 'var')
    Embeddings = {allTracks.Embeddings};
end
embeddingValues = vertcat(Embeddings{:});


for watershed_region = 1:max(L(:)-1)
    saveFileName = fullfile(pathname,[num2str(watershed_region), '.mp4']);

    %find all training points in the region
    possible_tracks = [];
    possible_frames = [];
    possible_indecies = [];

    current_index = 0;
    % loop through the embeddings to find all the instances of a behavior
    % occuring more than the duration
    for track_index = 1:length(Embeddings)
        behavioral_annotation = behavioral_space_to_behavior(Embeddings{track_index}, L, xx);
        behavioral_transitions = [0, diff(double(behavioral_annotation))];
        indecies_of_transitions = [1, find(abs(behavioral_transitions))];
        behavioral_sequence = behavioral_annotation(indecies_of_transitions);
        behavioral_duration = [diff(indecies_of_transitions), length(behavioral_annotation)-indecies_of_transitions(end)];

        possible_frames_in_this_track = indecies_of_transitions(behavioral_sequence == watershed_region ...
            & behavioral_duration >= duration);
        possible_frames_in_this_track = possible_frames_in_this_track + frames_before; %offset time from the beginning

        possible_frames = [possible_frames, possible_frames_in_this_track];
        possible_tracks = [possible_tracks, repmat(track_index, 1, length(possible_frames_in_this_track))];
        possible_indecies = [possible_indecies, current_index + possible_frames_in_this_track];

        current_index = current_index + length(behavioral_annotation);
    end

    %randomly reorder
    random_order = randperm(length(possible_frames));
    possible_frames = possible_frames(random_order);
    possible_tracks = possible_tracks(random_order);
    possible_indecies = possible_indecies(random_order);

    if length(possible_indecies) < N
        error(['Cannot output video. There are only ' num2str(length(possible_indecies)) ' observed behaviors, fewer than the required ' num2str(N)])
    end


    %% STEP 5: get N points that fits the criteria
    selected_indecies = [];
    selected_tracks = [];
    selected_frames = [];
    current_index = 1;
    while length(selected_indecies) < N
        current_track_number = possible_tracks(current_index);
        current_track_length = size(allTracks(current_track_number).Embeddings,1);
        current_frame_number = possible_frames(current_index);
        if current_frame_number - frames_before < 1 || current_frame_number + frames_after > current_track_length
            %this point will be cut out at some point, throw it out
        else
            data_point_accepted = false;
            if ismember(current_track_number, selected_tracks)
                previously_found_indecies = find(selected_tracks==current_track_number);
                previously_found_frames = selected_frames(previously_found_indecies);
                covered_frames = current_frame_number-frames_before:current_frame_number+frames_after;
                if ~sum(ismember(previously_found_frames,covered_frames))               
                    %this track has been represented, but this behavior is out
                    %of range
                    data_point_accepted = true;
                end
            else
                %this track has not been represented
                data_point_accepted = true;
            end
            if data_point_accepted
                selected_indecies = [selected_indecies, possible_indecies(current_index)];
                selected_tracks = [selected_tracks, current_track_number];
                selected_frames = [selected_frames, current_frame_number];  
            end
        end
        current_index = current_index + 1;
    end

    selected_embedded_points = embeddingValues(selected_indecies, :);
%     if ~exist('data', 'var')
%         data = vertcat(Spectra{:});
%     end
%     selected_feature_vectors = data(selected_indecies,:);

    %% STEP 6: plot the training points selected
    sample_figure = figure('Position', [0, 0, size(xx,2), size(xx,2)])
    [ii,jj] = find(L==0);
    maxDensity = max(density(:));
    hold on
    imagesc(xx,xx,density)
    for i = 1:N
        text(selected_embedded_points(i,1), selected_embedded_points(i,2),num2str(i),'VerticalAlignment','middle','HorizontalAlignment','center','Color','m')
        %plot(selected_embedded_points(:,1), selected_embedded_points(:,2), '*m', 'MarkerSize', 10)
    end
    %plot(selected_embedded_points(:,1), selected_embedded_points(:,2), '*m', 'MarkerSize', 10)
    %plot(selected_point(:,1), selected_point(:,2), 'om', 'MarkerSize', 30, 'LineWidth', 3)
    plot(xx(jj),xx(ii),'k.')
    axis equal tight off xy
    caxis([0 maxDensity * .8])
    colormap(jet)
    hold off
    set(gca,'position',[0 0 1 1],'units','normalized')

    saveas(sample_figure,fullfile(pathname,['data_samples_', num2str(watershed_region), '.png']),'png');
    close(sample_figure)
    %% STEP 7: plot the behaviors

    %load the worm images
    clear required_worm_images
    required_worm_images(N).worm_images = [];
    for worm_images_index = 1:N
        track_index = selected_tracks(worm_images_index);
        image_file = fullfile([folders{folder_indecies(track_index)},filesep,'individual_worm_imgs',filesep,'worm_', num2str(track_indecies(track_index)), '.mat']);
        required_worm_images(worm_images_index) = load(image_file);
    end

%     %calculate phi_dt
%     required_worm_images(N).phi_dt = [];
%     for worm_images_index = 1:N
%         track_index = selected_tracks(worm_images_index);
%         required_worm_images(worm_images_index).phi_dt = worm_phase_velocity(allTracks(track_index).ProjectedEigenValues, parameters)';
%     end
    
    behavior_figure = figure('Position', [0, 0, 400, 400]);
    outputVideo = VideoWriter(saveFileName,'MPEG-4');
    outputVideo.FrameRate = 14;
    open(outputVideo)

    for relative_frame_index = -frames_before:frames_after
        for subplot_index = 1:N
            worm_frame_index = selected_frames(subplot_index) + relative_frame_index;
            track_index = selected_tracks(subplot_index);
            if worm_frame_index < 1 || worm_frame_index > size(required_worm_images(subplot_index).worm_images,3)
                %the video does not exist, skip
                continue
            else
                subplot_tight(N_rows,N_columns,subplot_index,0);
                plot_worm_frame(required_worm_images(subplot_index).worm_images(:,:,worm_frame_index), squeeze(allTracks(track_index).Centerlines(:,:,worm_frame_index)), ...
                [], [], [], [], [], 0);
            end
        end

    %     ga = axes('Position',[0,0,1,1],'Xlim',[0,400],'Ylim',[0,400],'tag','ga');
    %     % set print margins
    %     topm = 400; botm = 0;
    %     rgtm = 400; lftm = 0;
    %     ctrm = (rgtm-lftm)/2;
    % 
    %     time_text = datestr(abs(relative_frame_index)/24/3600/fps,'SS.FFF');
    %     if relative_frame_index < 0
    %         time_text = ['-', time_text];
    %     end
    %     text(ctrm,botm+35,time_text,'color','red','fontsize',20,'VerticalAlignment','top','HorizontalAlignment','center')
    % 
    %     % make sure the plot is visible
    %     set(ga,'vis','off');

        %pause
        writeVideo(outputVideo, getframe(gcf));
        clf
    end
    close(outputVideo)
    close(behavior_figure)

%     %% STEP 8: plot feature vectors
%     feature_vector_figure = figure('Position', [0, 0, 800, 800]);
%     imagesc(selected_feature_vectors);
%     colorbar
%     saveas(feature_vector_figure,fullfile(pathname,['featurevector_', num2str(watershed_region), '.png']),'png');
%     close(feature_vector_figure)
end