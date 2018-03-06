function [] = PlotWatershed(embeddingValues)
%Plots the density map along with the watershed
    plot_behavior_colors = true;
    load('reference_embedding.mat')
    if nargin > 0
        maxVal = max(max(abs(embeddingValues)));
        maxVal = round(maxVal * 1.1);

        sigma = 4; %change smoothing factor if necessary

        [xx,density] = findPointDensity(embeddingValues,sigma,501,[-maxVal maxVal]);
        maxDensity = max(density(:));
        density(density < 10e-6) = 0;
    end
    
    maxDensity = max(density(:));
    density(density < 10e-6) = 0;
%     L = watershed(-density,8);
% 
%     L(L==1) = max(L(:))+1;
%     L = L - 1;
    L = encapsulate_watershed_matrix(L);
    number_of_behaviors = max(L(:))-1;
    [ii,jj] = find(L==0);

    watershed_centroids = regionprops(L, 'centroid');
    watershed_centroids = vertcat(watershed_centroids.Centroid);
    watershed_centroids = round(watershed_centroids);

    %special case
    watershed_centroids(2,2) = watershed_centroids(2,2) + 15;
        
    %modify color map
    %my_colormap = parula;
    my_colormap = othercolor('OrRd9');
    my_colormap(1,:) = [1 1 1];

    %figure
    hold on
    imagesc(xx,xx,density)
    plot(xx(jj),xx(ii),'k.')
    axis equal tight off xy
    caxis([0 maxDensity])
    colormap(my_colormap)
    for behavior_index = 1:size(watershed_centroids,1)-1
        text(xx(watershed_centroids(behavior_index,1)), ...
            xx(watershed_centroids(behavior_index,2)), ...
            behavior_names{behavior_index}, 'color', 'k', ...
            'fontsize', 5, 'horizontalalignment', 'center', ...
            'verticalalignment', 'middle');
    end
    
    %plot major watershed divisions
    if plot_behavior_colors
        for behavior_index = 1:number_of_behaviors
            binary_L = L == 0;
            dilated_binary_L = imdilate(binary_L,ones(7));
            inner_border_L = and(ismember(L,behavior_index), dilated_binary_L);
            %inner_border_L = bwmorph(inner_border_L, 'thin', inf);
            [ii,jj] = find(inner_border_L==1);
            plot(xx(jj),xx(ii),'.','color',behavior_colors(behavior_index,:))
        end
    end
    
    colorbar
    
end

