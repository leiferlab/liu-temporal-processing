function [non_linearity_fit, non_linearities, bin_centers, errors] = fit_nonlinearity(filtered_signal_given_behavior_histogram, filtered_signal_histogram, bin_edges)
% This function fits the non-linearity of the LNP model weighing the points
% by the expected counting error
    fps = 14;
    
    bin_count = length(filtered_signal_given_behavior_histogram);
    non_linearities = [];
    bin_centers = [];
    errors = [];
    
    for bin_index = 1:bin_count
        behavior_count = filtered_signal_given_behavior_histogram(bin_index);
        filtered_signal_count = filtered_signal_histogram(bin_index);
        
        if behavior_count < 2 || filtered_signal_count < 2
            %there is no data in a condition, ignore the point
        else

            non_linearity = behavior_count./filtered_signal_count*60*fps;
            bin_center = bin_edges(bin_index)+(diff(bin_edges(1:2)/2));
            
            %calculate error
            error = sqrt((sqrt(behavior_count-1)./filtered_signal_count)^2+(behavior_count*sqrt(filtered_signal_count-1)./(filtered_signal_count^2))^2)*60*fps;
            
            non_linearities = [non_linearities, non_linearity];
            bin_centers = [bin_centers, bin_center];
            errors = [errors, error];
            
        end
        
    end

    
    weights = 1./errors;
    try 
        non_linearity_fit = fit(bin_centers',non_linearities','exp1','weights',weights);
    catch
        non_linearity_fit = [];
    end

end

