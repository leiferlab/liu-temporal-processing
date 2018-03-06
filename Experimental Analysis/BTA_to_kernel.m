function [linear_kernel] = BTA_to_kernel(BTA, BTA_stats,meanLEDPower,skip_threshold)
%This function gets the kernel section of the BTA
%   The kernel is defined as bounded by zeros that contain all the significant
%   regions

    if nargin<3
        meanLEDPower = 0;
    end
    if nargin<4
        skip_threshold = true;
    end
    
    linear_kernel = zeros(size(BTA));
    percentile_threshold = 0.99;
    
    for behavior_index = 1:size(BTA,1)
        if isfield(BTA_stats, 'BTA_percentile') && BTA_stats.BTA_percentile(behavior_index) > percentile_threshold
            %BTA above percentile level, significant
            real_kernel = true;
        else
            real_kernel = false;
        end

        if real_kernel || skip_threshold
            %mean offset if necessary
            if isfield(BTA_stats, 'mean_subtracted') && BTA_stats.mean_subtracted
                linear_kernel(behavior_index, :) = BTA(behavior_index, :);
            else
                linear_kernel(behavior_index, :) = BTA(behavior_index, :)-meanLEDPower;
            end
            %the linear kernel is time reversed BTA
            linear_kernel(behavior_index,:) = fliplr(linear_kernel(behavior_index,:));
        end
    end
end

