function [cum_distances] = find_cumulative_distance(points)
% given a set of points in order, return the cumlative distance from the
% first point until all subsequent points
    if size(points,1) <= 1
        cum_distances = 0;
    else
        distances = sum(abs(diff(points)),2); %get the manhattan distance
        distances(distances == 2) = sqrt(2); %change to euclidean
        cum_distances = [0; cumsum(distances)];
    end
end