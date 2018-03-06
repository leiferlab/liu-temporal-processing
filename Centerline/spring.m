function spring_force = spring(P, l0, nu)
    %calculates the spring force forcing the centerline to be a preferred
    %length
    displacement = P(1:end-1,:) - P(2:end,:);
    distance = sqrt(sum(displacement.^2,2));
    direction = [displacement(:,1)./distance, displacement(:,2)./distance];
    
    %caculate a vectorized left force and a right force coming from a
    %node's springs in the respective direction
    distance_difference = l0/size(P,1) - distance;
    force_magnitude = repmat(nu*distance_difference,1,2);
    left_force = force_magnitude .* direction;
    left_force = [left_force; 0, 0];
    right_force = force_magnitude .* -direction;
    right_force = [0, 0; right_force];
    spring_force = left_force + right_force;
   
end