function min_displacement = min_circshifted_displacement(K, Old_K)
    %finds the minimum circshifted displacement to look for flips in the
    %centerline
    displacements = zeros(1,size(K,1));
    for shift = 1:size(K,1)
        displacements(shift) = find_displacement_between_two_centerlines(K, circshift(Old_K,shift-1,1));
    end
    min_displacement = min(displacements);
end