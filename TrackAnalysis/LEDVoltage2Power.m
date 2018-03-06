function Tracks = LEDVoltage2Power( Tracks, power500 )
% This function converts the LEDVoltages to LEDPower based on where the
% worms are in the field of view
    linearpower500 = power500(:);
    for track_index = 1:length(Tracks)
       path = round(Tracks(track_index).Path);
       power_index = sub2ind(size(power500),path(:,2)',path(:,1)');
       Tracks(track_index).LEDVoltage2Power = linearpower500(power_index)' ./ 5;
       Tracks(track_index).LEDPower = Tracks(track_index).LEDVoltage2Power .* Tracks(track_index).LEDVoltages;
    end

end

