function success = track_image_directory(folder_name, analysis_mode)
% tracks and saves individual worms for all the images in a directory

    addpath(genpath(pwd))
    parameters = load_parameters(folder_name); %load experiment parameters
    
    %% STEP 1: initialize %%
    if nargin < 2
        analysis_mode = 'all';
    end
    
    number_of_images_for_median_projection = 20;
    mask = parameters.Mask;
    image_size = [parameters.ImageSize, parameters.ImageSize];
    relevant_track_fields = {'Active','Path','LastCoordinates','Frames','Size', ...
        'LastSize','FilledArea','Eccentricity','WormIndex','Time','NumFrames', ...
        'SmoothX','SmoothY','Direction','Speed','SmoothSpeed','AngSpeed', ...
        'BackwardAcc','Pirouettes','LEDVoltages','Pauses','OmegaTurns','Runs','MergedBlobIndex'};
    

    %% STEP 2: See if a track file exists, if it does, there are some options that use them %%
    Tracks = load_single_folder(folder_name, relevant_track_fields);
    if ~isempty(Tracks)
        if strcmp(analysis_mode, 'continue')
            %track already exists, check if there are individual worm
            %images
            if exist([folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', num2str(length(Tracks)), '.mat'], 'file') == 2
                %there are individual worm images
                success = true;
                return
            else
                %repeat the analysis and save individual worm images
                analysis_mode = 'analysis';
            end
        end
    end
    
    %% STEP 3: Load images and other properties from the directory %%
    % Get all the tif file names (probably jpgs)
    %tap correct
    if parameters.TapCorrection 
        %debugging tapping mode
        tap_preprocessing(folder_name);
    end
    
    image_files=dir([folder_name, filesep, '*.jpg']); %get all the jpg files (maybe named tif)
    if isempty(image_files)
        image_files = dir([folder_name, filesep, '*.tif']); 
    end
    
    % Load Voltages
    fid = fopen([folder_name, filesep, 'LEDVoltages.txt']);
    LEDVoltages = transpose(cell2mat(textscan(fid,'%f','HeaderLines',0,'Delimiter','\t'))); % Read data skipping header
    fclose(fid);
    
    if length(image_files)-1 > length(LEDVoltages)
        %there are more frames than there are stimulus
        success = false;
        return
    end
    
    %% STEP 4: Get the median z projection %%
    medianProj = imread([folder_name, filesep, image_files(1).name]);
    [x_resolution, y_resolution] = size(medianProj);
    medianProjCount = min(number_of_images_for_median_projection, length(image_files) - 1); 
    medianProj = zeros(size(medianProj,1), size(medianProj,2), medianProjCount);
    for frame_index = 1:medianProjCount
        curImage = imread([folder_name, filesep, image_files(floor((length(image_files)-1)*frame_index/medianProjCount)).name]);
        medianProj(:,:,frame_index) = curImage;
    end
    medianProj = median(medianProj, 3);
    medianProj = uint8(medianProj);
    
    %% STEP 5: TRACKING %%
    if isempty(Tracks) || ~strcmp(analysis_mode, 'analysis')
        % Start Tracker
        Tracks = [];
        
        % Analyze Movie
        for frame_index = 1:length(image_files) - 1
            % Get Frame
            curImage = imread([folder_name, filesep, image_files(frame_index).name]);
            subtractedImage = curImage - medianProj - mask;

            % Convert frame to a binary image 
            if parameters.AutoThreshold       % use auto thresholding
                Level = graythresh(subtractedImage) + parameters.CorrectFactor;
                Level = max(min(Level,1) ,0);
            else
                Level = parameters.ManualSetLevel;
            end
            
            NUM = parameters.MaxObjects + 1;
            while (NUM > parameters.MaxObjects)
                if parameters.DarkObjects
                    BW = ~im2bw(subtractedImage, Level);  % For tracking dark objects on a bright background
                else
                    BW = im2bw(subtractedImage, Level);  % For tracking bright objects on a dark background
                end
                
                % Identify all objects
                [L,NUM] = bwlabel(BW);
                Level = Level + (1/255); %raise the threshold until we get below the maximum number of objects allowed
            end
            STATS = regionprops(L, {'Area', 'Centroid', 'FilledArea', 'Eccentricity', 'Extrema'});

            % Identify all worms by size
            WormIndices = find([STATS.Area] > parameters.MinWormArea & ...
                [STATS.Area] < parameters.MaxWormArea);
            
            % Find and ignore the blobs touching the edge
            all_extrema = reshape([STATS.Extrema], 8, 2, []);
            x_extrema = squeeze(all_extrema(:,2,:));
            y_extrema = squeeze(all_extrema(:,1,:));
            x_extrema_left_border = arrayfun(@(x) le(x,1), x_extrema);
            x_extrema_right_border = arrayfun(@(x) ge(x,x_resolution), x_extrema);
            y_extrema_top_border = arrayfun(@(y) le(y,1), y_extrema);          
            y_extrema_bottom_border = arrayfun(@(y) ge(y,y_resolution), y_extrema);
            
            x_extrema_left_border = sum(x_extrema_left_border, 1);
            x_extrema_right_border = sum(x_extrema_right_border, 1);
            y_extrema_top_border = sum(y_extrema_top_border, 1) >= 1;
            y_extrema_bottom_border = sum(y_extrema_bottom_border, 1);
            frames_on_border = bsxfun(@or, x_extrema_left_border, x_extrema_right_border);
            frames_on_border = bsxfun(@or, frames_on_border, y_extrema_top_border);
            frames_on_border = bsxfun(@or, frames_on_border, y_extrema_bottom_border);
            
            WormIndices = intersect(WormIndices, find(~frames_on_border));
            
            % get their centroid coordinates
            NumWorms = length(WormIndices);
            WormCentroids = [STATS(WormIndices).Centroid];
            WormCoordinates = [WormCentroids(1:2:2*NumWorms)', WormCentroids(2:2:2*NumWorms)'];
            WormSizes = [STATS(WormIndices).Area];
            WormFilledAreas = [STATS(WormIndices).FilledArea];
            WormEccentricities = [STATS(WormIndices).Eccentricity];

            % Track worms 
            if isempty(Tracks)
                ActiveTracks = [];
            else
                ActiveTracks = find([Tracks.Active] == 1);
            end

            % Update active tracks with new coordinates
            for i = 1:length(ActiveTracks)
                %find the closest worm still being tracked, and update it
                DistanceX = WormCoordinates(:,1) - Tracks(ActiveTracks(i)).LastCoordinates(1);
                DistanceY = WormCoordinates(:,2) - Tracks(ActiveTracks(i)).LastCoordinates(2);
                Distance = sqrt(DistanceX.^2 + DistanceY.^2);
                [MinVal, MinIndex] = min(Distance);
                if ~isempty(MinVal) && (MinVal <= parameters.MaxDistance) 
                    if WormSizes(MinIndex) - Tracks(ActiveTracks(i)).LastSize > parameters.SizeChangeThreshold
                        % the current blob has gained too much area
                        Tracks(ActiveTracks(i)).Active = -1;
                        Tracks(ActiveTracks(i)).MergedBlobIndex = WormIndices(MinIndex);
                    elseif Tracks(ActiveTracks(i)).LastSize - WormSizes(MinIndex) > parameters.SizeChangeThreshold
                        % the current blob has lost too much area
                        Tracks(ActiveTracks(i)).Active = -2;
                    else
                        Tracks(ActiveTracks(i)).Path = [Tracks(ActiveTracks(i)).Path; WormCoordinates(MinIndex, :)];
                        Tracks(ActiveTracks(i)).LastCoordinates = WormCoordinates(MinIndex, :);
                        Tracks(ActiveTracks(i)).Frames = [Tracks(ActiveTracks(i)).Frames, frame_index];
                        Tracks(ActiveTracks(i)).Size = [Tracks(ActiveTracks(i)).Size, WormSizes(MinIndex)];
                        Tracks(ActiveTracks(i)).LastSize = WormSizes(MinIndex);
                        Tracks(ActiveTracks(i)).FilledArea = [Tracks(ActiveTracks(i)).FilledArea, WormFilledAreas(MinIndex)];
                        Tracks(ActiveTracks(i)).Eccentricity = [Tracks(ActiveTracks(i)).Eccentricity, WormEccentricities(MinIndex)];
                        Tracks(ActiveTracks(i)).WormIndex = [Tracks(ActiveTracks(i)).WormIndex, WormIndices(MinIndex)];
                        WormIndices(MinIndex) = [];
                        WormCoordinates(MinIndex,:) = [];
                        WormSizes(MinIndex) = [];
                        WormFilledAreas(MinIndex) = [];
                        WormEccentricities(MinIndex) = [];
                    end
                else
                    Tracks(ActiveTracks(i)).Active = 0;
                end

            end

            % Start new tracks for coordinates not assigned to existing tracks
            NumTracks = length(Tracks);
            for i = 1:length(WormCoordinates(:,1))
                Index = NumTracks + i;
                Tracks(Index).Active = 1;
                Tracks(Index).Path = WormCoordinates(i,:);
                Tracks(Index).LastCoordinates = WormCoordinates(i,:);
                Tracks(Index).Frames = frame_index;
                Tracks(Index).Size = WormSizes(i);
                Tracks(Index).LastSize = WormSizes(i);
                Tracks(Index).FilledArea = WormFilledAreas(i);
                Tracks(Index).Eccentricity = WormEccentricities(i);
                Tracks(Index).WormIndex = WormIndices(i);
                Tracks(Index).MergedBlobIndex = [];
            end
            %frame_index
        end
    end
    
    %% STEP 6: Post-Track Filtering to get rid of invalid tracks %%
    DeleteTracks = [];
    first_frames = zeros(1,length(Tracks));
    last_frames = zeros(1,length(Tracks));
    for i = 1:length(Tracks)
        first_frames(i) = Tracks(i).Frames(1);
        last_frames(i) = Tracks(i).Frames(end);
    end
    for i = 1:length(Tracks)
        if length(Tracks(i).Frames) < parameters.MinTrackLength
            %get rid of tracks that are too short
            DeleteTracks = [DeleteTracks, i];
        elseif mean(Tracks(i).Size) < parameters.MinAverageWormArea
            %get rid of worms that are too small
            DeleteTracks = [DeleteTracks, i];
        else
            %find the maximum displacement from the first time point.
            %correct for dirts that don't move
            position_relative_to_start = transpose(Tracks(i).Path - repmat(Tracks(i).Path(1,:),size(Tracks(i).Path,1),1));
            euclideian_distances_relative_to_start = sqrt(sum(position_relative_to_start.^2,1)); %# The two-norm of each column
            if max(euclideian_distances_relative_to_start) < parameters.MinDisplacement
                DeleteTracks = [DeleteTracks, i];
            end
        end
        if Tracks(i).Active == -1
            %the track ended because of a + change in area
            if ~isempty(Tracks(i).MergedBlobIndex)
                %find the tracks that starts right after the last frame
                tracks_that_started_immediately_after = find(first_frames == last_frames(i)+1);
                if ~isempty(tracks_that_started_immediately_after)
                    for tracks_that_started_immediately_after_index = 1:length(tracks_that_started_immediately_after)
                        current_track_index = tracks_that_started_immediately_after(tracks_that_started_immediately_after_index);
                        if Tracks(current_track_index).WormIndex(1) == Tracks(i).MergedBlobIndex
                            %this track is a result of increased blob size
                            DeleteTracks = [DeleteTracks, current_track_index];
                            break
                        end
                    end
                end
            end
        elseif Tracks(i).Active == -2
            %the track ended because of a - change in area
            tracks_that_started_immediately_after = find(first_frames == last_frames(i)+1);
            if length(tracks_that_started_immediately_after) >= 2
                %there are 2 or more tracks that started in this frame, get
                %their centroids
                ending_position = Tracks(i).Path(end,:);
                starting_positions = [];
                resulting_worm_count = 0;
                for tracks_that_started_immediately_after_index = 1:length(tracks_that_started_immediately_after)
                    current_track_index = tracks_that_started_immediately_after(tracks_that_started_immediately_after_index);
                    starting_positions = [starting_positions; Tracks(current_track_index).Path(1,:)];
                end
                %get the top 2 tracks that are the closest to the ending
                %centroid, average them and see the displacement
                distances = pdist2(ending_position, starting_positions);
                [~, sorted_distance_indecies] = sort(distances, 'descend');
                closest_track_index_1 = sorted_distance_indecies(1);
                closest_track_index_2 = sorted_distance_indecies(2);
                averaged_centroid = (starting_positions(closest_track_index_1,:) + starting_positions(closest_track_index_2,:)) ./ 2;
                if pdist2(ending_position, averaged_centroid) < parameters.MaxDistance
                    DeleteTracks = [DeleteTracks, i];
                end
            end
        end
    end
    Tracks(unique(DeleteTracks)) = [];
    
    %% STEP 7: Go through all the tracks and analyze them %% 
    
    NumTracks = length(Tracks);
    for track_index = 1:NumTracks
        Tracks(track_index).Time = Tracks(track_index).Frames/parameters.SampleRate;		% Calculate time of each frame
        Tracks(track_index).NumFrames = length(Tracks(track_index).Frames);		    % Number of frames

        % Smooth track data by rectangular sliding window of size WinSize;
        Tracks(track_index).SmoothX = RecSlidingWindow(Tracks(track_index).Path(:,1)', parameters.SmoothWinSize);
        Tracks(track_index).SmoothY = RecSlidingWindow(Tracks(track_index).Path(:,2)', parameters.SmoothWinSize);

        % Calculate Direction & Speed
        Xdif = CalcDif(Tracks(track_index).SmoothX, parameters.StepSize) * parameters.SampleRate;
        Ydif = -CalcDif(Tracks(track_index).SmoothY, parameters.StepSize) * parameters.SampleRate;    % Negative sign allows "correct" direction
                                                                                   % cacluation (i.e. 0 = Up/North)
        Ydif(Ydif == 0) = eps;     % Avoid division by zero in direction calculation

        Tracks(track_index).Direction = atan(Xdif./Ydif) * 360/(2*pi);	    % In degrees, 0 = Up ("North")

        NegYdifIndexes = find(Ydif < 0);
        Index1 = find(Tracks(track_index).Direction(NegYdifIndexes) <= 0);
        Index2 = find(Tracks(track_index).Direction(NegYdifIndexes) > 0);
        Tracks(track_index).Direction(NegYdifIndexes(Index1)) = Tracks(track_index).Direction(NegYdifIndexes(Index1)) + 180;
        Tracks(track_index).Direction(NegYdifIndexes(Index2)) = Tracks(track_index).Direction(NegYdifIndexes(Index2)) - 180;

        Tracks(track_index).Speed = sqrt(Xdif.^2 + Ydif.^2) / parameters.PixelSize;		% In mm/sec
        
        Tracks(track_index).SmoothSpeed = smoothts(Tracks(track_index).Speed, 'g', parameters.StepSize, parameters.StepSize);		% In mm/sec

        AngleChanges = CalcAngleDif(Tracks(track_index).Direction, parameters.StepSize);
        
        % Calculate angular speed
        Tracks(track_index).AngSpeed = AngleChanges * parameters.SampleRate;		% in deg/sec

        Tracks(track_index).BackwardAcc = CalcBackwardAcc(Tracks(track_index).Speed, AngleChanges, parameters.StepSize);		% in mm/sec^2
        %Find Pauses
        Tracks(track_index).Pauses = IdentifyPauses(Tracks(track_index), parameters);
        % Identify Pirouettes (Store as indices in Tracks(TN).Pirouettes)
        Tracks(track_index).Pirouettes = IdentifyPirouettes(Tracks(track_index), parameters);
        % Identify Omegas (Store as indices in Tracks(TN).OmegaTurns)
        Tracks(track_index).OmegaTurns = IdentifyOmegaTurns(Tracks(track_index), parameters);
        % Identify Runs (Store as indices in Tracks(TN).Runs)
        Tracks(track_index).Runs = IdentifyRuns(Tracks(track_index), parameters);
        %Save the LED Voltages for this track
        Tracks(track_index).LEDVoltages = LEDVoltages(:, min(Tracks(track_index).Frames):max(Tracks(track_index).Frames));
    end
    
%% STEP 8: Calculate LED Power %%
    Tracks = LEDVoltage2Power(Tracks, parameters.power500);
    
%% STEP 9: Save the tracks %%
    savetracks(Tracks,folder_name);
    
%% STEP 10: save each worms images %%
    if isempty(Tracks) || ~parameters.SaveIndividualImages || parameters.TrackOnly
        success = true;
        return
    end

    savePath = [folder_name, filesep, 'individual_worm_imgs', filesep];
    if ~exist(savePath, 'dir')
        mkdir(savePath)
    end
    
    delete_extra_individual_worm_images(folder_name, 0); %delete previous .mat files
    
    frame_count = length(image_files)-1;
    %get where each track begins and ends in terms of frames and put them
    %in a sparse binary matrix
    tracks_start_in_frame = logical(sparse(length(Tracks), frame_count));
    tracks_end_in_frame = logical(sparse(length(Tracks), frame_count));
    for track_index = 1:length(Tracks)
        tracks_start_in_frame(track_index, Tracks(track_index).Frames(1)) = true;
        tracks_end_in_frame(track_index, Tracks(track_index).Frames(end)) = true;
    end

    current_image_stacks = [];

    for frame_index = 1:frame_count
        tracks_that_start_in_this_frame = find(tracks_start_in_frame(:,frame_index));
        if ~isempty(tracks_that_start_in_this_frame)
            %%%there are tracks that start in this frame%%%
            previous_length = length(current_image_stacks);
            current_image_stacks(previous_length+length(tracks_that_start_in_this_frame)).TrackIndex = []; %preallocate memory
            for new_track_index = 1:length(tracks_that_start_in_this_frame)
                track_index = tracks_that_start_in_this_frame(new_track_index);
                current_image_stacks(previous_length+new_track_index).TrackIndex = track_index;
                current_image_stacks(previous_length+new_track_index).TrackStartFrame = frame_index;
                current_image_stacks(previous_length+new_track_index).Images = zeros([image_size, length(Tracks(track_index).Frames)], 'uint8');
            end
        end

        %%%image processing%%%
        curImage = imread([folder_name, filesep, image_files(frame_index).name]);
        subtractedImage = curImage - medianProj - mask; %subtract median projection  - imageBackground
        if parameters.AutoThreshold       % use auto thresholding
            Level = graythresh(subtractedImage) + parameters.CorrectFactor;
            Level = max(min(Level,1) ,0);
        else
            Level = parameters.ManualSetLevel;
        end
        % Convert frame to a binary image 
        NUM = parameters.MaxObjects + 1;
        while (NUM > parameters.MaxObjects)
            if parameters.DarkObjects
                BW = ~im2bw(subtractedImage, Level);  % For tracking dark objects on a bright background
            else
                BW = im2bw(subtractedImage, Level);  % For tracking bright objects on a dark background
            end
            % Identify all objects
            [L,NUM] = bwlabel(BW);
            Level = Level + (1/255); %raise the threshold until we get below the maximum number of objects allowed
        end

        for image_stack_index = 1:length(current_image_stacks)
            %for each track in this frame, get the image
            track_index = current_image_stacks(image_stack_index).TrackIndex;
            in_track_index = frame_index - current_image_stacks(image_stack_index).TrackStartFrame + 1;
            region_index = Tracks(track_index).WormIndex(in_track_index);
            centroid_x = round(Tracks(track_index).Path(in_track_index,1));
            centroid_y = round(Tracks(track_index).Path(in_track_index,2));
            image_top_left_corner_x = centroid_x-image_size(1)/2;
            image_top_left_corner_y = centroid_y-image_size(2)/2;
            image_bottom_right_corner_x = image_top_left_corner_x+image_size(1);
            image_bottom_right_corner_y = image_top_left_corner_y+image_size(2);

            cropped_labeled_image = imcrop(L, [image_top_left_corner_x, image_top_left_corner_y, (image_size-1)]);
            single_worm = cropped_labeled_image == region_index; %get an binary mask of only where the worm is
            single_worm = bwmorph(single_worm, 'fill');
            worm_frame = imcrop(subtractedImage, [image_top_left_corner_x, image_top_left_corner_y, (image_size-1)]);
            worm_frame(~single_worm) = 0; %mask

            %pad the image if necessary
            if image_top_left_corner_x < 1 || image_top_left_corner_y < 1
                %pad the front
                worm_frame = padarray(worm_frame, [max(1-image_top_left_corner_y,0), max(1-image_top_left_corner_x,0)], 0, 'pre');
            end
            if image_bottom_right_corner_x > size(L,2) || image_bottom_right_corner_y > size(L,1)
                %pad the end
                worm_frame = padarray(worm_frame, [max(image_bottom_right_corner_y-size(L,1)-1,0), max(image_bottom_right_corner_x-size(L,2)-1,0)], 0, 'post');
            end

            current_image_stacks(image_stack_index).Images(:,:,in_track_index) = worm_frame;
        end

        tracks_that_end_in_this_frame = find(tracks_end_in_frame(:,frame_index));
        if ~isempty(tracks_that_end_in_this_frame)
            %%%there are tracks that end in this frame, do the computation%%%
            image_stack_indecies = [];
            for ending_track_index = 1:length(tracks_that_end_in_this_frame)
                track_index = tracks_that_end_in_this_frame(ending_track_index);
                image_stack_index = find([current_image_stacks.TrackIndex] == track_index);
                image_stack_indecies = [image_stack_indecies, image_stack_index];
                worm_images = current_image_stacks(image_stack_index).Images;
                save([folder_name, filesep, 'individual_worm_imgs', filesep, 'worm_', num2str(track_index), '.mat'], 'worm_images', '-v7.3');
            end
            current_image_stacks(image_stack_indecies) = []; %clear the memory of these images
        end
    end
    
%% STEP FINAL: return 
    success = true;
end
