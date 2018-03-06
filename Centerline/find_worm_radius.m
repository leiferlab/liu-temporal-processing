function [thinning_iteration, dilation_size] = find_worm_radius(Image, best_threshold)
    % get the worm radius by looking at how many iterations it takes for
    % thinning to converge
    BW = im2bw(Image, best_threshold);
    BW = bwmorph(BW, 'fill');
    
%     last_thinned_image = false(size(Image));
%     thinning_iteration = 1;
%     while 1
%         thinned_image = bwmorph(BW, 'thin', thinning_iteration);
%         if isequal(last_thinned_image,thinned_image)
%             break
%         else
%             last_thinned_image = thinned_image;
%             thinning_iteration = thinning_iteration + 1;
%         end
%     end

    [thinned_image, ~, thinning_iteration] = algbwmorph_iter_output(BW,'thin', Inf);


    % get how much to dilate the image for the best match
    linearized_image = BW(:);
    image_scores = zeros(1, thinning_iteration);
    dilation_size = 1;
    while dilation_size <= thinning_iteration
        generated_image = imdilate(thinned_image, true(dilation_size));
        linearized_generated_binary_image = generated_image(:);
        union_total = sum(or(linearized_image, linearized_generated_binary_image));
        intersection_total = sum(and(linearized_image, linearized_generated_binary_image));
        image_scores(dilation_size) = intersection_total / union_total;
        dilation_size = dilation_size + 1;
%         imshow(generated_image, []);
%         pause();
    end
    
    thinning_iteration = thinning_iteration - 2; %thinning correction
    
    [~,dilation_size] = max(image_scores);
%     imshow(thinned_image, [])
%     pause();
%     %debug
%     subplot(1,2,1), imshow(Image,[])
%     hold on
%     plot(K(:,2), K(:,1), 'g-');
%     hold off
%     
%     subplot(1,2,2), imshow(generated_image_binary,[])
%     hold on
%     plot(K(:,2), K(:,1), 'g-');
%     hold off
%     
%     score
%     pause(0.1);
end