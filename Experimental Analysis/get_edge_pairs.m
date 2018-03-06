function no_weight_edges = get_edge_pairs(number_of_behaviors, with_self)
%this generates all possible transition pairs (with and without out self
%edges)
    if nargin < 2
        with_self = false;
    end
    no_weight_edges = fliplr(combvec(1:number_of_behaviors, 1:number_of_behaviors)');
    if ~with_self
        indecies_to_remove = 1:(number_of_behaviors+1):size(no_weight_edges,1);
        no_weight_edges(indecies_to_remove,:) = [];
    end
end

