function [ behavior_timeseries ] = behavioral_space_to_behavior(behavioral_space_timeseries, watershed_labels, xx)
%This function annotates a time series in 2D behavioral space using the
%watershed map
    watershed_xy_indecies = SpaceMapping(behavioral_space_timeseries,xx);
    % use linear indexing
    watershed_linear_indecies = sub2ind(size(watershed_labels), watershed_xy_indecies(:,2), watershed_xy_indecies(:,1));
    watershed_labels_linear = watershed_labels(:); 
    behavior_timeseries = watershed_labels_linear(watershed_linear_indecies)';
%     behavior_timeseries = diag(watershed_labels(watershed_xy_indecies(:,2),watershed_xy_indecies(:,1)));
end

