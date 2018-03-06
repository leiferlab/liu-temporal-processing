%This script allows the user to pick a watershed region in a t-SNE map and
%finds when the animal stays in that region and plots their behaivor

%% STEP 1: establish plotting constants 
N_rows = 4;
N_columns = 4;
N = N_rows*N_columns;
fps = 14;
frames_before = 1*fps-1;
frames_after = 1*fps;
duration = frames_before+frames_after+1;


%% STEP 3: allow user to select the point
% maxVal = max(max(abs(combineCells(Embeddings))));
% maxVal = round(maxVal * 1.1);
% sigma = maxVal / 40;
% numPoints = 501;
% rangeVals = [-maxVal maxVal];
% [xx,density] = findPointDensity(combineCells(Embeddings),sigma,numPoints,rangeVals);
% maxDensity = max(density(:));

figure
hold on
imagesc(xx,xx,density)
plot(xx(jj),xx(ii),'k.')
axis equal tight off xy
caxis([0 maxDensity * .8])
colormap(jet)
hold off

[x,y] = getpts;
close
selected_point = [x(1), y(1)];

% %% STEP 4a: get example points based on closeness to the selected point
% [~,possible_training_indecies] = pdist2(trainingEmbedding,selected_point,'euclidean','Smallest',size(trainingEmbedding,1));
% possible_tracks = trainingSetTracks(possible_training_indecies);
% possible_frames = trainingSetFrames(possible_training_indecies);

% %% STEP 4b: get example points based on watershed region
% watershed_x = SpaceMapping(selected_point(1),xx);
% watershed_y = SpaceMapping(selected_point(2),xx);
% watershed_region = L(watershed_y, watershed_x); %get the watershed region index
% 
% %find all training points in the region
% [watershed_ii,watershed_jj] = find(L==watershed_region);
% watershed_space_embedding = SpaceMapping(trainingEmbedding,xx);
% possible_training_indecies = find(ismember(watershed_space_embedding,[watershed_jj,watershed_ii],'rows'));
% possible_training_indecies = possible_training_indecies(randperm(length(possible_training_indecies))); %randomize order
% possible_tracks = trainingSetTracks(possible_training_indecies);
% possible_frames = trainingSetFrames(possible_training_indecies);

%% STEP 4c: get example points based on watershed region
watershed_x = SpaceMapping(selected_point(1),xx);
watershed_y = SpaceMapping(selected_point(2),xx);
watershed_region = L(watershed_y, watershed_x); %get the watershed region index

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


if ~exist('data', 'var')
    data = vertcat(Spectra{:});
end

spectra_in_region = data(possible_indecies,:);
std_spectra_in_region = std(spectra_in_region,0,1);
mean_spectra_in_region = mean(spectra_in_region,1);
coef_of_variation = std_spectra_in_region ./ mean_spectra_in_region;

std_spectra = std(data,0,1);
mean_spectra = mean(data,1);

figure
for pca_modes = 1:5
    subplot(5,1,pca_modes)
    indecies = 1:25;
    indecies = (pca_modes-1)*25 + indecies;
    hold on
    errorbar(mean_spectra_in_region(indecies),std_spectra_in_region(indecies))
    errorbar(mean_spectra(indecies),std_spectra(indecies))
    hold off
    ax = gca;
    ax.XTick = 1:5:25;
    ax.XTickLabel = num2cell(round(f(mod(1:length(f),5) == 1), 1));
    if pca_modes == 1
        ylabel('Normalized Spectra Contribution')
    end
    xlabel('Freqency (Hz)')
    xlim([1 25])
    legend('In Region','All Spectra')
end

