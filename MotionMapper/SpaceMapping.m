function [output_matrix] = SpaceMapping(input_matrix, xx)
%SpaceMapping takes in a linspace xx and an arbitury input_matrix and looks
%up the indecies in xx closest to each element of the input_matrix to
%generate the output_matrix

    %figure out the equation that maps xx
    slope = (xx(end) - xx(1))/length(xx);
    intercept = xx(1);

    %
    output_matrix = input_matrix - intercept;
    output_matrix = output_matrix ./ slope;
    output_matrix = round(output_matrix);
end

