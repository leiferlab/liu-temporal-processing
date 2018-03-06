function [sorted_eigen_values, eigen_vectors] = myPCA( matrix )
    %get the eigen values and vectors to do PCA
    %mean center
    mean_centered = matrix - (diag(mean(matrix, 2))*ones(size(matrix)));
    %get the covariance
    covariance_matrix = cov(transpose(mean_centered));
    %get the eigen values and eigen vectors of the covariance
    [eigen_vectors, eigen_values] = eig(covariance_matrix);
    %get the eigen values in one column
    eigen_values = sum(eigen_values,2);
    %sort the eigen values from biggest to smallest
    [sorted_eigen_values, sort_index] = sort(eigen_values, 'descend');
    %make the eigen values a diagonal matrix
    sorted_eigen_values = diag(sorted_eigen_values);
    %order the eigen vectors according to how the eigen values are sorted
	eigen_vectors = eigen_vectors(:, sort_index);
end