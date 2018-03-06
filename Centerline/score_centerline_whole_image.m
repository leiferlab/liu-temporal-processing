function [total_score, image_score, displacement_score, centerline_pixels_out_of_body] = score_centerline_whole_image(K, Old_K, BW, dilation_size, l0)
    % the score is the dot product of the image and a generated image from
    % the centerline minus the displacement score

    %%%find the image score, which the fraction of intensities covered by
    %%%the centerline
    [generated_binary_image, linear_bresenham_image] = generate_binary_image_from_centerline(K, size(BW), dilation_size);
%     Image = Image .* double(im2bw(Image,best_threshold/255));
    linearized_image = BW(:);
    linearized_generated_binary_image = generated_binary_image(:);
%     intensity_sum = sum(linearized_image);
%     image_score = dot(linearized_generated_binary_image, linearized_image)/intensity_sum;
    union = or(linearized_image, linearized_generated_binary_image);
    union_total = sum(union);
    intersection = and(linearized_image, linearized_generated_binary_image);
    intersection_total = sum(intersection);
    image_score = intersection_total / union_total;
    
    %%% Find how many pixels does the centerline appear out of the body
    centerline_pixels_out_of_body = sum(linear_bresenham_image) - sum(linearized_image(linear_bresenham_image));
    
    if ~isempty(Old_K)
        %%%find the displacement score which is the average displacement
        %%%per point over the body length of the worm capped at 1
        displacement_score = 1 - (find_displacement_between_two_centerlines(K, Old_K)/size(K,1)/l0);
        displacement_score = min(displacement_score, 1);
    else
        displacement_score = 1;
    end
    total_score = image_score + displacement_score;
%     if image_score < 0.5
%         %debug
%          subplot(1,2,1), imshow(BW,[])
% %        subplot(1,2,1), imshow(reshape(union,70,70),[])
%         hold on
%         plot(K(:,2), K(:,1), 'g-');
%         hold off
% 
%          subplot(1,2,2), imshow(generated_binary_image,[])
% %         subplot(1,2,2), imshow(reshape(intersection,70,70),[])
%         hold on
%         plot(K(:,2), K(:,1), 'g-');
%         hold off
% 
%         [total_score, image_score, displacement_score, centerline_pixels_out_of_body]
%     end

end