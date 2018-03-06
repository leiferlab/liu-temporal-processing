function [BTA, behaviorCounts, BTA_std] = fastparallel_BehaviorTriggeredAverage(Concatenated_Behaviors,Concatenated_LEDPowers,BTA_seconds_before_and_after)
%This function performs the core BTA caculation
    downsample_number = 0;
    fps = 14;
    
    seconds_before = BTA_seconds_before_and_after;
    seconds_after = BTA_seconds_before_and_after;
    BTA_length = (fps*seconds_before)+(fps*seconds_after)+1;
    number_of_behaviors = size(Concatenated_Behaviors,1);
    
    BTA = zeros(number_of_behaviors,BTA_length);
    BTA_std = zeros(number_of_behaviors,BTA_length);
    behaviorCounts = sum(Concatenated_Behaviors,2);
    
    for behavior_index = 1:number_of_behaviors
        if behaviorCounts(behavior_index) > 0
            behavior_triggers = Concatenated_Behaviors(behavior_index,:);
            
            if downsample_number > 0 && behaviorCounts(behavior_index) > downsample_number
                %downsample to a certain number if hard coded in
                %randomly select from the available triggers
                trigger_indecies = find(behavior_triggers);
                downsampled_trigger_indecies = randsample(trigger_indecies,downsample_number);
                behavior_triggers = false(1,length(behavior_triggers));
                behavior_triggers(downsampled_trigger_indecies) = true;
                behaviorCounts(behavior_index) = downsample_number;
            end

            tracksCentered = zeros(BTA_length, behaviorCounts(behavior_index));
            parfor time_index = 1:BTA_length
                shift = time_index - (fps*BTA_seconds_before_and_after) - 1;
                timeshifted_triggers = circshift(behavior_triggers,shift,2);
                tracksCentered(time_index,:) = Concatenated_LEDPowers(timeshifted_triggers);
            end
            BTA(behavior_index,:) = mean(tracksCentered,2)';
            BTA_std(behavior_index,:) = std(tracksCentered,0,2)';
        end
    end

end

