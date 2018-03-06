function strech_force = strech(P, l0, nu)
    %calculates the force streching the two ends
    head_direction = P(1,:) - P(2,:);
    head_direction = head_direction/norm(head_direction);

    tail_direction = P(end,:) - P(end-1,:);
    tail_direction = tail_direction/norm(tail_direction);

    l = sum(sqrt(sum((P(2:end,:)-P(1:end-1,:)).^2,2)));
    force_magnitude = nu*(l0-l);
    
    strech_force = zeros(size(P));
    strech_force(1,:) = force_magnitude*head_direction;
    strech_force(end,:) = force_magnitude*tail_direction;
    strech_force(2,:) = -strech_force(1,:);
    strech_force(end-1,:) = -strech_force(end,:);
end