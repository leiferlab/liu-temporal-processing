function w = padded_conv(u, v)
%This function takes variables u and v, convolves them like
%conv(u,v,'same') but without the edge effect of the sharp jump
    padded_u = [repmat(u(1),1,length(v)), u, repmat(u(end),1,length(v))];
    w = conv(padded_u, v, 'same');
    w = w(length(v)+1:length(v)+length(u));
end

