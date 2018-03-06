function repforce = repel(P, cd, mu)
    %find the self repel forces between each point to each other
    nPoints = size(P,1);
    force = zeros(size(P));
    
    for i = 1:nPoints
        for j = 1:nPoints
            if j >= i
                break;
            elseif i-j == 1
                %there is no repel force between adjacent points
                continue;
            else
                displacement = P(i,:) - P(j,:);
                distance = norm(displacement);
                if distance < cd
                    force(i,:) = force(i,:) + (displacement/distance);
                    force(j,:) = force(j,:) - (displacement/distance);
                end
            end
        end
    end
    
    repforce = mu*force;
end