function [] = plot_triangle(centers_x, centers_y, areas, colors, point_down)
%plots any number of triangles
    number_of_triangles = length(centers_x);
    if nargin < 5
        point_down = false(number_of_triangles,1);
    end
    hold on
    for triangle_index = 1:number_of_triangles
        base_length = sqrt(4*areas(triangle_index)/sqrt(3));
        half_base_length = base_length/2;
        height = base_length*sqrt(3)/2;
        if point_down(triangle_index)
            pt1=[0, height];
            pt2=[half_base_length, 0];
            pt3=[base_length, height];
        else
            pt1=[0, 0];
            pt2=[half_base_length, height];
            pt3=[base_length, 0];
        end
        x = [pt1(1), pt2(1), pt3(1)] - half_base_length + centers_x(triangle_index);
        y = [pt1(2), pt2(2), pt3(2)] - (height/2) + centers_y(triangle_index);
        patch(x,y,colors(triangle_index,:));
    end
    

end

