function phi_dt = worm_phase_velocity(ProjectedEigenValues, parameters)
%This function outputs the phase velocity time series given the PCA time series% not used in paper

    phase_determining_PCs = [2, 3]; %which PCs are the sine and cosine of worm locomotion
    phase_determining_eigen_values = ProjectedEigenValues(phase_determining_PCs, :);
    
    x = phase_determining_eigen_values(1,:);
    y = phase_determining_eigen_values(2,:);

    %normalize x and y to be on the same scale (this is done in the paper)
    %the RMS of x and y are both 1
    x = x ./ parameters.PCxScale;
    y = y ./ parameters.PCyScale;
    y(y == 0) = eps;     % Avoid division by zero in phase calculation
    
    %define phase as invtan(x/y)
    phi = atan(x./y);
    NegYIndexes = find(y < 0);
    Index1 = find(phi(NegYIndexes) <= 0);
    Index2 = find(phi(NegYIndexes) > 0);
    phi(NegYIndexes(Index1)) = phi(NegYIndexes(Index1)) + pi;
    phi(NegYIndexes(Index2)) = phi(NegYIndexes(Index2)) - pi;
    
    %take the derivative off phi
    phi_dt = angdiff(phi(2:end),phi(1:end-1));
    
    %correct for discontinuity due to wrapping around and loss of a
    %timepoint
    phi_dt = -[0, unwrap(phi_dt,[],1)]; 

    %gaussian smooth the result 
%     phi_dt = smoothts(phi_dt, 'g', Prefs.StepSize*5, Prefs.StepSize*5);
    phi_dt = smoothts(phi_dt, 'g', parameters.StepSize, parameters.StepSize);
    
    %cap the phi_dt at some min and max
    phi_dt(phi_dt < parameters.MinPhaseVelocity) = parameters.MinPhaseVelocity;
    phi_dt(phi_dt > parameters.MaxPhaseVelocity) = parameters.MaxPhaseVelocity;
    
%     image_size = [70, 70];
%     direction_vector = [[Track.Speed].*-cosd([Track.Direction]); [Track.Speed].*sind([Track.Direction])];
%     head_vector = reshape(Track.Centerlines(1,:,:),2,[]) - (image_size(1)/2);    
%     %normalize into unit vector
%     head_normalization = hypot(head_vector(1,:), head_vector(2,:));
%     head_vector = head_vector ./ repmat(head_normalization, 2, 1);
%     head_direction_dot_product = dot(head_vector, direction_vector);
% 
%     hold all
%     plot(phi_dt/max(phi_dt))
%     plot(head_direction_dot_product/max(head_direction_dot_product))
%     xlabel('Time (frames)')
%     ylabel('Normalized Phase Velocity and direction_vector')
end

