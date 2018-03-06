frame_count = 10^6;
correlationTime = 5;
sigma = 0.2; %the standard deviation
minVoltage = 0;
maxVoltage = 5;
currentVoltage = 0.3; %in this case, the average voltage
fps = 14;

voltages = zeros(1,frame_count);
A = exp(-(1/fps)/correlationTime);
voltages(1,1) = 0; %the initial voltage is 0, we will offset later

for frame = 2:frame_count
    %voltages(1,frame) = A*voltages(1,frame-1) + (randn(1)*sqrt(sigma^2*(1-(A^2))));
    voltages(1,frame) = (randn(1)*sqrt(sigma^2*(1-(A^2))));
end

%offset
voltages = voltages + currentVoltage;

%make sure the signal does not go out of bounds
voltages(voltages<minVoltage) = minVoltage;
voltages(voltages>maxVoltage) = maxVoltage;

plot(0:1/fps:(frame_count-1)/fps, voltages, 'bo-')
xlabel('time (s)') % x-axis label
ylabel('voltage') % y-axis label


% N = length(voltages);
% xdft = fft(voltages);
% xdft = xdft(1:N/2+1);
% psdx = (1/(frame_count*N)) * abs(xdft).^2;
% psdx(2:end-1) = 2*psdx(2:end-1);
% freq = 0:frame_count/length(voltages):frame_count/2;
% 
figure;
% plot(freq(1:100),10*log10(psdx(1:100)))
% grid on
% title('Periodogram Using FFT')
% xlabel('Frequency (Hz)')
% ylabel('Power/Frequency (dB/Hz)')

periodogram(voltages,rectwin(length(voltages)),length(voltages),fps, 'power')