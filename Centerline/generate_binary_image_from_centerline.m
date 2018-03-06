function [generated_image, linear_bresenham_image] = generate_binary_image_from_centerline(K, image_size, dilation_size)
    % given the centerline and the image size, this function creates a
    % image that looks like the original worm
    
    linear_bresenham_image = false(image_size(1)*image_size(2),1);
    
    for i = 1:size(K,1)-1
        pixel_positions = bresenham(K(i,1), K(i,2), K(i+1,1), K(i+1,2));
        %all_pixel_positions = [all_pixel_positions; pixel_positions(2:end,:)];
        try
            linearSub = sub2ind(image_size, pixel_positions(:,1), pixel_positions(:,2));
            linear_bresenham_image(linearSub) = true;
        catch
            %when the centerline is out of frame, an error occurs
        end
    end
    
    
    generated_image = reshape(linear_bresenham_image,image_size(1),image_size(2));
%     %remove the end by worm radius because we will dilate anyways
%     generated_image = bwmorph(generated_image, 'spur', round(dilation_size/2));
%     linear_bresenham_image = generated_image(:);
    generated_image = imdilate(generated_image, true(dilation_size));

%     imshow(generated_image, []);
%     pause
%     score = sum(Image(linearSub));
end