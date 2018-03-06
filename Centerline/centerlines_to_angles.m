function [angle_changes, mean_angles] = centerlines_to_angles(centerlines)
    %this function gets the angles with respect to the mean angle for each
    %segment in the worm, vectorized so that multiple centerlines can be
    %inputted at once. The output is in radians
    
    [nPoints, ~, num_centerlines] = size(centerlines);
    
    %get differences between points
    centerline_diff = centerlines(2:end,:,:) - centerlines(1:end-1,:,:);
    centerline_x_diff = squeeze(centerline_diff(:,1,:));
    centerline_y_diff = squeeze(centerline_diff(:,2,:));
    centerline_y_diff(centerline_y_diff==0) = eps; %avoid division by 0
    
    %get angles according to 0 is North (Up)
    centerline_x_over_y = centerline_x_diff ./ centerline_y_diff;
    angles = atand(centerline_x_over_y); 
    
    %make sure the angles are 360
    NegYdifIndexes = find(centerline_y_diff < 0);
    Index1 = find(angles(NegYdifIndexes) <= 0);
    Index2 = find(angles(NegYdifIndexes) > 0);
    angles(NegYdifIndexes(Index1)) = angles(NegYdifIndexes(Index1)) + 180;
    angles(NegYdifIndexes(Index2)) = angles(NegYdifIndexes(Index2)) - 180;
    
    %subtract the mean_angle from each angle
    mean_angles = meanangle(angles,1);
    mean_angles_rep = repmat(mean_angles,nPoints-1,1);
    angle_changes = angdiff(angles*pi/180,mean_angles_rep*pi/180);
    
    %correct for discontinuity due to wrapping around
    angle_changes = unwrap(angle_changes,[],1); 
    
    %correct for the mean angle_change not being near 0
    mean_angle_changes = mean(angle_changes,1);
    correction = zeros(1,length(mean_angle_changes));
    correction(mean_angle_changes < -pi) = 2*pi;
    correction(mean_angle_changes > pi) = -2*pi;
    correction = repmat(correction,nPoints-1,1);
    angle_changes = angle_changes + correction;
    
%     %debug
%     figure
%     hold all
%     sample_count = min(100, num_centerlines);
%     sampled_indecies = randsample(num_centerlines, sample_count);
%     for index = 1:sample_count
%         plot(angle_changes(:,sampled_indecies(index)));
%     end
%     xlabel('Position Along the Worm')
%     ylabel('Angle Difference to Mean Angle (radians)')
%     hold off
end