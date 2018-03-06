function [cum_distances, sequences] = find_cumulative_distance_minus_backtrack(points,BW_size)
% given a set of points in order, return the cumlative distance from the
% first point until all subsequent points, accounting for backtracking
    if size(points,1) <= 1
        cum_distances = 0;
    else
        distances = sum(abs(diff(points)),2); %get manhattan distance
        distances(distances == 2) = sqrt(2); %get euclidean distance
        distances = [0; distances]; %pad the first value
        point_sequence = sub2ind(BW_size, points(:,1), points(:,2));
        cum_distances = zeros(size(points,1),1);
        cum_distances(2) = distances(2);
        back_tracking_index = 0;
        sequences(length(point_sequence)).PointsThusFar = [];
        sequences(1).PointsThusFar = points(1,:);
        sequences(2).PointsThusFar = [sequences(1).PointsThusFar; points(2,:)];
        for i = 3:length(point_sequence)
            if back_tracking_index > 0
                %we are currently backtracking
                distance_backtracked = i-back_tracking_index;
                if back_tracking_index-distance_backtracked <= 0 || point_sequence(i) ~= point_sequence(back_tracking_index-distance_backtracked)
                    %we are no longer backtracking
                    back_tracking_index = 0;
                    cum_distances(i) = cum_distances(i-1) + distances(i);
                    sequences(i).PointsThusFar = [sequences(i-1).PointsThusFar; points(i,:)];
                else
                    %we are still backtracking
                    cum_distances(i) = cum_distances(i-1) - distances(i);
                    sequences(i).PointsThusFar = sequences(i-1).PointsThusFar(1:end-1,:);
                end
            elseif point_sequence(i) == point_sequence(i-2);
                %backtracking detected
                back_tracking_index = i-1;
                cum_distances(i) = cum_distances(i-1) - distances(i);
                sequences(i).PointsThusFar = sequences(i-1).PointsThusFar(1:end-1,:);
            else
                cum_distances(i) = cum_distances(i-1) + distances(i);
                sequences(i).PointsThusFar = [sequences(i-1).PointsThusFar; points(i,:)];
            end
        end
    end

end