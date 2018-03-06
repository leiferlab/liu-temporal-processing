function [tip_centroids, L, BW]  = tip_filter(I, thresh)
    %Use a Mexican hat-esque filter to find tips. parameters are hardcoded

    %Create Mexican hat-esque filter, if it hasn't been already
    persistent circle_filter;
    if isempty(circle_filter)
        [X,Y] = meshgrid(-5:5, -5:5);
        circle_filter = double((X.^2 + Y.^2)<4) - .15; %Create circular filter
    end

    BW = im2bw(I,thresh);
    BW = bwmorph(BW, 'fill'); %fill in the blob
    
    %take the largest blob
    CC = bwconncomp(BW);
    if CC.NumObjects == 0
        %no objects found
        L = bwlabel(BW);
        tip_centroids = [];
        return
    end
    
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [~,idx] = max(numPixels);
    BW(~CC.PixelIdxList{idx}) = 0;
    
    % apply Mexican hat-esque filter to image to get tips
    Icirc = imfilter(BW,circle_filter);
    L = bwlabel(Icirc);
    all_stats = regionprops(L, 'Centroid');
    tip_centroids = reshape([all_stats.Centroid], 2, [])';
    tip_centroids = fliplr(tip_centroids);
%     imshow(Icirc, []);
%     hold on
%     plot(round(tip_centroids(:,1)), round(tip_centroids(:,2)), 'go')
%     hold off
end