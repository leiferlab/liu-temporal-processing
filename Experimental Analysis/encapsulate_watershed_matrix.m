function L = encapsulate_watershed_matrix(L)
%This function superfically changes the label matrix so that the edges of
%it are surrounded by borders
    empty_watershed = max(L(:));
    
    temp = L(1,:);
    temp(temp ~= empty_watershed) = 0;
    L(1,:) = temp;

    temp = L(end,:);
    temp(temp ~= empty_watershed) = 0;
    L(end,:) = temp;
    
    temp = L(:,1);
    temp(temp ~= empty_watershed) = 0;
    L(:,1) = temp;
    
    temp = L(:,end);
    temp(temp ~= empty_watershed) = 0;
    L(:,end) = temp;
end

