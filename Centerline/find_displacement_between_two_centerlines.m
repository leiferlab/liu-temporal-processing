function displacement = find_displacement_between_two_centerlines(K, Old_K)
    %finds the difference in euclidean distance between two centerlines
    Kdis = (Old_K - K).^2;
    displacement = sum(sqrt(Kdis(:,1)+Kdis(:,2)));
end