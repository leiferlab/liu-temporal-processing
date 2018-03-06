function x  = fill_binary_holes(x, hole_size)
    %this function removes all holes (ex [1 0 1] and [0 1 0]) up to hole_size
    for current_hole_size = 1:hole_size
        pattern = [1, zeros(1,current_hole_size), 1];
        idx = strfind(x,pattern);
        if ~isempty(idx)
          x(bsxfun(@plus,idx,(0:current_hole_size+2)')) = 1;
        end
        pattern = [0, ones(1,current_hole_size), 0];
        idx = strfind(x,pattern);
        if ~isempty(idx)
          x(bsxfun(@plus,idx,(0:current_hole_size+2)')) = 0;
        end
    end
end