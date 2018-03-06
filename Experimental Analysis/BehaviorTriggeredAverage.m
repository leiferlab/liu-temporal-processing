function [BTA, behaviorCounts, BTA_std, BTA_stats] = BehaviorTriggeredAverage(Behaviors, LEDPowers, bootstrap)
    %finds the behavior triggered average, optionally determine the
    %significance of the BTA by shuffling transitions randomly and finding
    %the BTA
    BTA_seconds_before_and_after = 10;
    number_of_random_shuffles = 100;
    number_of_behaviors = size(Behaviors{1},1);

    if nargin < 3
        %default for bootstrap is true
        bootstrap = true;
    end
    Concatenated_LEDPowers = horzcat(LEDPowers{:});
    mean_LEDPowers = mean(Concatenated_LEDPowers);
    
    %get triggers accounting for edges
    no_edge_Behaviors = circshift_triggers(Behaviors,BTA_seconds_before_and_after,false);
    Concatenated_Behaviors = horzcat(no_edge_Behaviors{:});
    
    [BTA, behaviorCounts, BTA_std] = fastparallel_BehaviorTriggeredAverage(Concatenated_Behaviors,Concatenated_LEDPowers,BTA_seconds_before_and_after);
    
    if bootstrap
        BTA_norm = sqrt(sum((BTA-mean_LEDPowers).^2, 2));

        %perform bootstrapping
        shuffle_norms = zeros(number_of_behaviors,number_of_random_shuffles);
        for shuffle_index = 1:number_of_random_shuffles
            %get triggers accounting for edges
            no_edge_Behaviors = circshift_triggers(Behaviors,BTA_seconds_before_and_after,true);
            Concatenated_Behaviors = horzcat(no_edge_Behaviors{:});
            [shuffle_BTA, ~, ~] = fastparallel_BehaviorTriggeredAverage(Concatenated_Behaviors,Concatenated_LEDPowers,BTA_seconds_before_and_after);

            %get the L2 norm of the shuffled_BTAs
            shuffle_norm = sqrt(sum((shuffle_BTA-mean_LEDPowers).^2, 2));
            shuffle_norms(:,shuffle_index) = shuffle_norm;

            disp(num2str(shuffle_index));
        end

        allnorms = [BTA_norm, shuffle_norms];
        BTA_percentile = zeros(number_of_behaviors,1);
        for behavior_index = 1:number_of_behaviors
            norm_ranks = tiedrank(allnorms(behavior_index,:)) / (number_of_random_shuffles+1);
            BTA_percentile(behavior_index) = norm_ranks(1);
        end
        BTA_stats.BTA_norm = BTA_norm;
        BTA_stats.shuffle_norms = shuffle_norms;
        BTA_stats.BTA_percentile = BTA_percentile;
        BTA_stats.mean_subtracted = false;
    else
        BTA_stats = [];

    end
end
