function [transition_graph,normalized_adj_matrix, adj_matrix, adj_matrix_duration_occupied, behavioral_ratios] = BehavioralTransitionGraph(Tracks, number_of_behaviors, plotting, ratio_included)
    % Generates a normalized adjacency matrix from tracks
    % the generated adjacency matrix has "from" columns and "to" rows

    fps = 14;
    if nargin < 2
        number_of_behaviors = 12;
    end
    if nargin < 3
        plotting = false;
    end
    if nargin < 4
        ratio_included = 1;
    end
    
    %construct the adjacency matrix
    total_frames = 0;
    adj_matrix = zeros(number_of_behaviors);
    adj_matrix_duration_occupied = zeros(number_of_behaviors);
    non_directional_duration_occupied = zeros(1,number_of_behaviors);
    for track_index = 1:length(Tracks)
        if size(Tracks(track_index).BehavioralTransition,1) > 1
         from_indecies = Tracks(track_index).BehavioralTransition(1:end-1,1);
         to_indecies = Tracks(track_index).BehavioralTransition(2:end,1);
         duration_occupied = Tracks(track_index).BehavioralTransition(2:end,4);
            for transition_index = 1:length(from_indecies)
                %skip the behavior 0 and above specified behavior
                if from_indecies(transition_index) > 0 && to_indecies(transition_index) > 0 && ...
                    from_indecies(transition_index) <= number_of_behaviors && to_indecies(transition_index) <= number_of_behaviors
                     adj_matrix(from_indecies(transition_index),to_indecies(transition_index)) = ...
                         adj_matrix(from_indecies(transition_index),to_indecies(transition_index)) + 1;
                     adj_matrix_duration_occupied(from_indecies(transition_index),to_indecies(transition_index)) = ...
                         adj_matrix_duration_occupied(from_indecies(transition_index),to_indecies(transition_index)) + duration_occupied(transition_index);
                     non_directional_duration_occupied(to_indecies(transition_index)) = non_directional_duration_occupied(to_indecies(transition_index))+ duration_occupied(transition_index);
                end
            end
        end
        total_frames = total_frames + length(Tracks(track_index).Frames);
    end

    %% find the normalized adjacency matrix and turn it into a graph
    
%     %normalize by the total number of events going into a behavior
%     normalized_adj_matrix = adj_matrix ./ repmat(sum(adj_matrix,1),number_of_behaviors,1);
%     for behavior_index = 1:number_of_behaviors
%         %go through each into behavior and remove insignificant ones
%         behaviors_going_into = normalized_adj_matrix(:,behavior_index);
%         behaviors_going_into_sorted = sort(behaviors_going_into, 'descend');
%         behaviors_going_into_cumsum = cumsum(behaviors_going_into_sorted);
%         cut_off_ratio = behaviors_going_into_sorted(find(behaviors_going_into_cumsum>ratio_included,1,'first'));
%         if isempty(cut_off_ratio)
%             %all the behaviors are included
%             cut_off_ratio = 0;
%         end
%         behaviors_going_into(behaviors_going_into<cut_off_ratio) = 0;
%         normalized_adj_matrix(:,behavior_index) = behaviors_going_into;
%     end

    %normalize by all transitions
    normalized_adj_matrix = adj_matrix ./ sum(adj_matrix(:));
    behaviors_sorted = sort(normalized_adj_matrix(:), 'descend');
    behaviors_sorted_cumsum = cumsum(behaviors_sorted);
    cut_off_ratio = behaviors_sorted(find(behaviors_sorted_cumsum>ratio_included,1,'first'));
    if isempty(cut_off_ratio)
        %all the behaviors are included
        cut_off_ratio = 0;
    end    
    normalized_adj_matrix(normalized_adj_matrix<cut_off_ratio) = 0;

    %%
    transition_graph = digraph(normalized_adj_matrix);
    behavioral_ratios = non_directional_duration_occupied ./ sum(non_directional_duration_occupied);
    
    %% plot the density diagram
    if plotting
        LWidths = 10*transition_graph.Edges.Weight/max(transition_graph.Edges.Weight);

        load('reference_embedding.mat')

        maxDensity = max(density(:));
        [ii,jj] = find(L==0);

        watershed_centroids = regionprops(L, 'centroid');
        watershed_centroids = vertcat(watershed_centroids.Centroid);
        watershed_centroids = round(watershed_centroids);
        watershed_centroids = watershed_centroids(1:end-1,:);

        %special case
        watershed_centroids(2,2) = watershed_centroids(2,2) + 15;
        
        %modify jet map
        my_colormap = othercolor('OrRd9');
        my_colormap(1,:) = [1 1 1];

        figure
        hold on

        scatter(xx(watershed_centroids(:,1)),xx(watershed_centroids(:,2)), ...
            round(behavioral_ratios*50000), behavior_colors,'filled')%,'MarkerEdgeColor','y','LineWidth',5);
        
        for region_index = 1:size(watershed_centroids,1)
            text(xx(watershed_centroids(region_index,1)), ...
                xx(watershed_centroids(region_index,2)), ...
                [behavior_names{region_index}, char(13), num2str(round(behavioral_ratios(region_index).*100)),'%'], 'color', 'k', ...
                'fontsize', 16, 'horizontalalignment', 'center', ...
                'verticalalignment', 'middle');
        end
        
        %imagesc(xx,xx,density)
        plot(xx(jj),xx(ii),'k.')
        axis equal tight off xy
        %caxis([0 maxDensity])
        %colormap(my_colormap)
        edge_weights = transition_graph.Edges.Weight;
        graph_edge_label = cell(1,length(edge_weights));
        for edge_index = 1:length(edge_weights)
            graph_edge_label{edge_index} = [num2str(round(edge_weights(edge_index).*100)), '%'];
        end
        
        plot(transition_graph,'EdgeLabel',graph_edge_label,'LineWidth',LWidths, ...
            'ArrowSize', 25, 'EdgeColor', 'b', 'EdgeAlpha', 0.5, 'NodeColor', 'none', ...
            'NodeLabel', {}, ...
            'XData',xx(watershed_centroids(:,1))','YData',xx(watershed_centroids(:,2))');
        
        set(gca,'fontsize',50)

        title([num2str(round(total_frames/fps/3600)), ' worm-hours']);
        hold off
    end
end