function [] = PlotDirectionalBehavioralMappingExperimentGroup (LNPStats, meanLEDPower, stdLEDPower, L, density, xx)
%Takes in structure LNPStats and plots them depending on the settings
    fps = 14;
    BTA_seconds_before_and_after = 10;
    BTA_seconds_before = BTA_seconds_before_and_after;
    BTA_seconds_after = BTA_seconds_before_and_after;
    kernel_seconds_before = BTA_seconds_before;
    rows_per_page = 3;
    NumTicks = 3;

    figure
    plot_watershed = 1;
    plot_BTA = 1;
    plot_linear_filter = 1;
    plot_filtered_signal_histogram = 0;
    plot_filtered_signal_given_reversal_histogram = 0;
    plot_non_linearity = 1;
    
    number_of_behaviors = max(L(:))-1;
   
    if nargin > 4
        [ii,jj] = find(L==0);
    %     all_density = density(:);
    %     [white_space_ii white_space_jj] = find(density > 1);
        density(density > 1) = 0;
        maxDensity = max(density(:));

        watershed_centroids = regionprops(L, 'centroid');
        watershed_centroids = vertcat(watershed_centroids.Centroid);
        watershed_centroids = round(watershed_centroids);
        watershed_centroids = watershed_centroids(1:number_of_behaviors,:);
        
        %modify jet map
        my_colormap = othercolor('OrRd9');
        my_colormap(1,:) = [1 1 1];
    else
        plot_watershed = 0;
    end
    
    BTA_plot_number = plot_BTA;
    linear_filter_plot_number = BTA_plot_number+plot_linear_filter;
    filtered_signal_histogram_plot_number = linear_filter_plot_number+plot_filtered_signal_histogram;
    filtered_signal_given_reversal_histogram_plot_number = filtered_signal_histogram_plot_number+plot_filtered_signal_given_reversal_histogram;
    non_linearity_plot_number = filtered_signal_given_reversal_histogram_plot_number+plot_non_linearity;
    watershed_plot_number = non_linearity_plot_number+plot_watershed;
    plots_per_experiment = watershed_plot_number;
    
    for behavior_index = 1:length(LNPStats)
        %plot watershed
        if plot_watershed
            %create an adjacency matrix
            edges = LNPStats(behavior_index).Edges;
            adj_matrix = zeros(number_of_behaviors);
            adj_matrix(edges(1),edges(2)) = edges(3);
            transition_graph = digraph(adj_matrix);
            LWidths = 2*transition_graph.Edges.Weight/max(transition_graph.Edges.Weight);
            
            scrollsubplot(rows_per_page, plots_per_experiment, plots_per_experiment*(behavior_index-1) + watershed_plot_number);
            hold on
            imagesc(xx,xx,density)
            plot(xx(jj),xx(ii),'k.')
            axis equal tight off xy
            caxis([0 maxDensity * .8])
            colormap(my_colormap)

            plot(transition_graph,'EdgeLabel',transition_graph.Edges.Weight,'LineWidth',5, ...
                'ArrowSize', 25, 'EdgeColor', 'm', ...
                'XData',xx(watershed_centroids(:,1))','YData',xx(watershed_centroids(:,2))');

            hold off
        end
        
        if LNPStats(behavior_index).trigger_count == 0
            %no transition event
            continue
        end
        
        %plot BTA
        if plot_BTA
            scrollsubplot(rows_per_page, plots_per_experiment, plots_per_experiment*(behavior_index-1) + BTA_plot_number);
            hold on
            %shaded error bar represents the mean of the angular error
            shadedErrorBar(-BTA_seconds_before:1/fps:BTA_seconds_after, LNPStats(behavior_index).BTA, 2*stdLEDPower*sqrt(2/LNPStats(behavior_index).trigger_count)*ones(1,length(LNPStats(behavior_index).BTA)), {'-k', 'Linewidth', 3});
%             shadedErrorBar(-BTA_seconds_before:1/fps:BTA_seconds_after, LNPStats(behavior_index).BTA, LNPStats(behavior_index).BTA_std ./ 10, {'-k', 'Linewidth', 3});
            meanLEDVoltageY = zeros(1,length(LNPStats(behavior_index).BTA));
            meanLEDVoltageY(:) = meanLEDPower;
            plot(-BTA_seconds_before:1/fps:BTA_seconds_after, meanLEDVoltageY, 'r', 'Linewidth', 3)
            hold off
%             xlabel(strcat('Time (s) (', num2str(LNPStats(behavior_index).trigger_count), ' behaviors analyzed)')) % x-axis label
            xlabel(['n=',num2str(LNPStats(behavior_index).trigger_count)]) % x-axis label
%             ylabel('Stimulus Intensity (uW/mm^2)') % y-axis label
            axis([-10 10 23 27])
            %axis([-10 2 0 5])
            ax = gca;
            %ax.XTick = ;
%             ax.YTick = linspace(0.64,0.84,5);
            ax.FontSize = 18;
            xlabh = get(gca,'XLabel');
            set(xlabh,'Position',get(xlabh,'Position') + [0 2.8 0])
            limits = get(gca,'XLim');
            set(gca,'XTick',linspace(limits(1),limits(2),NumTicks))
            limits = get(gca,'YLim');
            set(gca,'YTick',linspace(limits(1),limits(2),NumTicks))
        end
        
        %plot linear kernel
        if plot_linear_filter
            scrollsubplot(rows_per_page, plots_per_experiment, plots_per_experiment*(behavior_index-1) + linear_filter_plot_number);
            hold on
            shadedErrorBar(-BTA_seconds_before:1/fps:BTA_seconds_after, LNPStats(behavior_index).linear_kernel, 2*stdLEDPower*sqrt(2/LNPStats(behavior_index).trigger_count)*ones(1,length(LNPStats(behavior_index).linear_kernel)), {'-k', 'Linewidth', 3});
            plot(-BTA_seconds_before:1/fps:BTA_seconds_after, 0, 'r')
            hold off
            xlabel(strcat('Time (s) (', num2str(LNPStats(behavior_index).trigger_count), ' behaviors analyzed)')) % x-axis label
%             xlabel(strcat(num2str(LNPStats(behavior_index).trigger_count), ' behaviors analyzed')) % x-axis label
            ylabel('Stimulus Intensity (uW/mm^2)') % y-axis label
            ax = gca;
            ax.FontSize = 10;
        end

        %plot the filtered signal histogram
        if plot_filtered_signal_histogram
            scrollsubplot(rows_per_page, plots_per_experiment, plots_per_experiment*(behavior_index-1) + filtered_signal_histogram_plot_number);
            bar(LNPStats(behavior_index).bin_edges(1:end-1), LNPStats(behavior_index).filtered_signal_histogram);
            set(gca,'XTick',round(LNPStats(behavior_index).bin_edges*100)/100)
        end
        
        %plot the filtered signal given reversal histogram
        if plot_filtered_signal_given_reversal_histogram
            scrollsubplot(rows_per_page, plots_per_experiment, plots_per_experiment*(behavior_index-1) + filtered_signal_given_reversal_histogram_plot_number);
            bar(LNPStats(behavior_index).bin_edges(1:end-1), LNPStats(behavior_index).filtered_signal_given_reversal_histogram');
            set(gca,'XTick',round(LNPStats(behavior_index).bin_edges*100)/100)
        end
        
       
        %plot non linearity
        if plot_non_linearity
            bin_centers = LNPStats(behavior_index).bin_centers;
    %        non_linearity_fit = fit(bin_centers',non_linearity','exp1');   %refit of necessary
            non_linearity_fit = LNPStats(behavior_index).non_linearity_fit;
            LNPStats(behavior_index).exp_fit_a = non_linearity_fit.a;
            LNPStats(behavior_index).exp_fit_b = non_linearity_fit.b;

            scrollsubplot(rows_per_page, plots_per_experiment, plots_per_experiment*(behavior_index-1) + non_linearity_plot_number);
            non_linearity = LNPStats(behavior_index).non_linearity;
            fig = gcf;
            prev_line_marker_size = get(fig,'DefaultLineMarkerSize');
            prev_line_width = get(fig,'DefaultLineLineWidth');
            set(fig,'DefaultLineMarkerSize',30);
            set(fig,'DefaultLineLineWidth',5)
            hold on
            plot(non_linearity_fit,bin_centers,non_linearity)
            errorbar(bin_centers,non_linearity,LNPStats(behavior_index).errors, 'b.')
            
            %axis([-3 4 0 3])
            ax = gca;
            %ax.XTick = ;
            %ax.YTick = linspace(0.64,0.84,5);
            ax.FontSize = 18;
            old_ylim = ylim;
            ylim([0 old_ylim(2)]);
%             ylim([0 4]);
            
            limits = get(gca,'XLim');
            set(gca,'XTick',linspace(limits(1),limits(2),NumTicks))
            limits = get(gca,'YLim');
            set(gca,'YTick',linspace(limits(1),limits(2),NumTicks))
            xlabel('') % x-axis label
            ylabel('') % y-axis label
%             xlabel('Filtered Signal (a.u.)') % x-axis label
%             ylabel('Behavioral Rate (Behaviors/Min)') % y-axis label
            legend('off')
            set(fig,'DefaultLineMarkerSize',prev_line_marker_size);
            set(fig,'DefaultLineLineWidth',prev_line_width)
        end
    end
    
    if isfield(LNPStats, 'shuffle_norms') && ~isempty(LNPStats(1).shuffle_norms)
        figure
        shuffle_norms = vertcat(LNPStats.shuffle_norms);
        BTA_norms = [LNPStats.BTA_norm];
        shuffle_mean = mean(shuffle_norms, 2)';
        shuffle_std = 2.6 .* std(shuffle_norms,0,2)';
        xticklabelcells = cell(1,length(LNPStats));

        hold on
        errorbar(1:length(LNPStats), shuffle_mean, shuffle_std, 'bo')
        for LNP_index = 1:length(LNPStats)
            if LNPStats(LNP_index).BTA_percentile > 0.99
                plot(LNP_index, BTA_norms(LNP_index), 'r*')
            else
                plot(LNP_index, BTA_norms(LNP_index), 'b*')
            end
            xticklabelcells{LNP_index} = [num2str(LNPStats(LNP_index).Edges(1)) ' To ' num2str(LNPStats(LNP_index).Edges(2))];
        end
        hold off
        set(gca,'XTick',1:length(LNPStats))
        set(gca,'XTickLabel',xticklabelcells)
        set(gca,'XTickLabelRotation',90)

        xlabel('Behavior Index') % x-axis label
        ylabel('Filter Magnitude') % y-axis label
        legend('Shuffled Magnitutde (99% confidence)', 'BTA Magnitutde')
    end
end

