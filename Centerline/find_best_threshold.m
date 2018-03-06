function threshold = find_best_threshold(Image)
    % get best binary threshold for the worm

    threshold = 0;
    %imshow(Image, []);
    while threshold < 0.3
        BW = im2bw(Image, threshold);
        BW = bwmorph(BW, 'fill');
        STATS = regionprops(BW,'Eccentricity');
%         imshow(BW, []);
%         STATS
%         threshold
%         pause
        if isempty(STATS)
            threshold = 0;
            return
        elseif STATS(1).Eccentricity > 0.97
            return
        else
            threshold = threshold + 1/255;
        end
    end
    threshold = 0;
end