function [thinned_image_outline, thin_iteration] = find_possible_centerline_image(BW, best_thinning_iteration)
    %find the centerline image by removing best_thinning_iteration pixels 
    %from the outside of the BW image and finding the outline

    [first_thinned_image, ~, thin_iteration] = algbwmorph_iter_output(BW, 'thin',max(0,best_thinning_iteration-2));
    first_thinned_image_outline = bwmorph(first_thinned_image, 'remove');
    bridged_thinned_image = bwmorph(first_thinned_image_outline, 'close');
    thinned_image_outline = bwmorph(bridged_thinned_image, 'thin', Inf);
    
    %thin_iteration = thin_iteration - 2; %correction
    %debug
    %imshow(Image + thinned_image_outline,[])

%     pause(0.1);
end