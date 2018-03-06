function success = build_behavioral_map(folders)
    % segments a behavioral map into watersheds of stereotyped behaviors
    
    %% STEP 1: load relevant variables
    addpath(genpath(pwd))
    relevant_track_fields = {'Embeddings'};
    load('reference_embedding.mat')

    [allTracks, ~, ~] = loadtracks(folders, relevant_track_fields);
    embeddingValues = vertcat(allTracks.Embeddings);
    
    %% STEP 10: Find watershed regions and make density plot
    maxVal = max(max(abs(embeddingValues)));
    maxVal = round(maxVal * 1.1);

    % sigma = maxVal / 40; %change smoothing factor if necessary
    sigma = 4.3; %change smoothing factor if necessary
    numPoints = 501;
    rangeVals = [-maxVal maxVal];

    [xx,density] = findPointDensity(embeddingValues,sigma,501,[-maxVal maxVal]);
    maxDensity = max(density(:));
    density(density < 10e-6) = 5; % set below threshold density to 0
    L = watershed(-density,8);
    [ii,jj] = find(L==0);

    L(L==1) = max(L(:))+1;
    L = L - 1;

    watershed_centroids = regionprops(L, 'centroid');
    watershed_centroids = vertcat(watershed_centroids.Centroid);
    watershed_centroids = round(watershed_centroids);
    number_of_behaviors = size(watershed_centroids,1)-1;
    
    density(density == 5) = 0;
    %modify color mapping
    my_colormap = othercolor('OrRd9');
    my_colormap(1,:) = [1 1 1];
    
    figure
    hold on
    imagesc(xx,xx,density)
    caxis([0 maxDensity])
    colormap(my_colormap)
    plot(xx(jj),xx(ii),'k.')
    for region_index = 1:number_of_behaviors
        text(xx(watershed_centroids(region_index,1)), ...
            xx(watershed_centroids(region_index,2)), ...
            num2str(region_index), 'color', 'k', ...
            'fontsize', 12, 'horizontalalignment', 'center', ...
            'verticalalignment', 'middle');
    end
    axis equal tight xy
    hold off
    colorbar
    xlimits=round(get(gca,'xlim'));
    set(gca,'xtick',xlimits);
    ylimits=round(get(gca,'ylim'));
    set(gca,'ytick',ylimits);

    behavior_names = cell(1,number_of_behaviors);
    for behavior_index = 1:number_of_behaviors
        behavior_names{behavior_index} = ['Behavior ', num2str(behavior_index)];
    end
    behavior_colors = jet(number_of_behaviors);
    save('reference_embedding.mat', 'trainingEmbedding', 'trainingSetData','density','xx','L','behavior_names','behavior_colors');
    
    success = true;
end




