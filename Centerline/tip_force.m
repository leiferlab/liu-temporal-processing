function tip_force = tip_force(P, tips, xi)
    %calculates the force pinning the tip
    head_force = xi * (tips(1,:) - P(1,:));
    tail_force = xi * (tips(2,:) - P(end,:));
    tip_force = zeros(size(P));
    tip_force(1,:) = head_force;
    tip_force(end,:) = tail_force;
end