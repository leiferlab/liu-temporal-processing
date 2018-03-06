function smoothed_x = binary_smoothing(x, window)
    %smoothes a binary vector over a window (window should be odd)
    half_window = floor(window/2);
    votes = zeros(size(x));
    for current_window = 1:half_window
        shift_right = circshift(x, [0, current_window]);
        shift_right(1:half_window) = x(1);
        shift_left = circshift(x, [0, -current_window]);
        shift_left(end-half_window:end) = x(end);
        votes = votes + shift_right + shift_left;
    end
    votes = votes + x;
    smoothed_x = votes >= (floor(window)+1)/2;
end