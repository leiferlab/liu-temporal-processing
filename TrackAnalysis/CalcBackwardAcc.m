function Dif = CalcBackwardAcc(Speed, AngChange, StepSize)			% StepSize MUST be > 0

% This function calculates the (approx.) derivative of the vector *Speed* 
% in the component going "backward" (180 degrees from current direction) 
% 
% 
Len = length(Speed);
HalfStepHi = ceil(StepSize/2);
HalfStepLo = floor(StepSize/2);

Dif(1) = Speed(2) - Speed(1).*cosd(AngChange(1));
for i = 2:HalfStepHi
	Dif(i) = (Speed(2*i-1) - Speed(1).*cosd(AngChange(i))) / (2*i-2);
end
Dif(HalfStepHi+1:Len-HalfStepLo) = (Speed(StepSize+1:Len) - Speed(1:Len-StepSize).*cosd(AngChange(HalfStepHi+1:Len-HalfStepLo)))/StepSize;
for i = 1:HalfStepLo-1
	Dif(Len-HalfStepLo+i) = (Speed(Len) - Speed(Len-2*HalfStepLo+2*i).*cosd(AngChange(Len-HalfStepLo+i)))/(2*HalfStepLo-2*i);
end
Dif(Len) = Speed(Len) - Speed(Len-1).*cosd(AngChange(Len-1));
