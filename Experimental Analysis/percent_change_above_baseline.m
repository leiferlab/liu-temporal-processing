function [largest_percent_change, baseline_mean, exp_max, exp_min, baseline_std, exp_mean, exp_std, p] = percent_change_above_baseline(data,baseline_start,baseline_end,exp_start,exp_end)
%finds a baseline value by averaging the first part of the data, finds
%the max deviation from baseline, and calculate how much deviation occurs
    if nargin < 2
        baseline_ratio = 0.2;
        search_until = 0.8;
        
        baseline_start = 1;
        baseline_end = round(size(data,2) .* baseline_ratio);
        exp_start = round(size(data,2) .* baseline_ratio)+1;
        exp_end = round(size(data,2) .* search_until);
    end
    
    baseline_data = data(:,baseline_start:baseline_end);
    exp_data = data(:,exp_start:exp_end);
    baseline_mean = mean(baseline_data,2);
    baseline_std = std(baseline_data,0,2);
    exp_mean = mean(exp_data,2);
    exp_std = std(exp_data,0,2);

    
    exp_max = max(exp_data,[],2);
    exp_min = min(exp_data,[],2);
    
    max_change = (exp_max - baseline_mean) ./ baseline_mean .* 100;
    min_change = (baseline_mean - exp_min) ./ baseline_mean .* 100;
    
    largest_percent_change = zeros(size(baseline_mean));
    for behavior_index = 1:size(data,1)
        if max_change(behavior_index) > min_change(behavior_index)
            largest_percent_change(behavior_index) = max_change(behavior_index);
        else
            largest_percent_change(behavior_index) = -min_change(behavior_index);
        end
    end
    [~,p,~,~] = ttest2(baseline_data, exp_data);


end

