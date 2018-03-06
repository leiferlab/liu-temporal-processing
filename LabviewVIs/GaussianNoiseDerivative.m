% currentVoltage = 2.5;
% frame_count = 100;
% sigma = 0.5;

voltages = zeros(frame_count, 1);
for frame = 1:frame_count
    voltages(frame,1) = currentVoltage;
    currentVoltage = min([max([currentVoltage + normrnd(0,sigma), 0]), 5]);
end