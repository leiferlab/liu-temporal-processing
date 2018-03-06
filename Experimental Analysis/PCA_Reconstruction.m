function [ reconstructed_worm ] = PCA_Reconstruction(ProjectedEigenvalues, EigenVectors, Modes )
% Reconstructs the worm using the top n modes of the PCs

    reconstructed_worm = EigenVectors(:,1:Modes) * ProjectedEigenvalues(1:Modes,:);

end

