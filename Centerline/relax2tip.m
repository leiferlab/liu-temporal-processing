function K = relax2tip(P, tips, kappa, Fline, gamma, B, ConCrit, cd, mu, l0, nu, xi)
    %iteratively relaxes the contour given the 2 worm tips
    %parameters:
    %P: initial centerline
    %tips: 2x2 matrix with the 1st row being the xy of the head and the 2nd row is the tail
    %kappa: image force constant
    %Fline: image gradient in x and y
    %gamma: timestep of the iteration
    %B: relaxation matrix
    %ConCrit: the convergence criteria
    %cd: repel characteristic distance
    %mu: repel force constant
    %l0: the characteristic length of the contour
    %nu: spring force constant
    %xi: tip force constant
    POriginal = P;
    nPoints = size(P,1);
    max_iteration = 100;
    Pdiff = ConCrit + 1;
    iteration = 1;
    try
%         outputVideo = VideoWriter(fullfile(['snakes_', num2str(1)]),'MPEG-4');
%         outputVideo.FrameRate = 1;
%         open(outputVideo)

        while Pdiff > ConCrit && iteration < max_iteration
            Pold = P;

            %get forces acting on the centerlines
            Frepel = repel(P, cd, mu);
            %Fstrech = strech(P, l0, nu);
            Fspring = spring(P, l0, nu);
            Ftips = tip_force(P, tips, xi);

            %get image forces (line only) on the contour
            Fext = zeros(nPoints,2);
            Fext(2:nPoints-1,1) = -kappa*(interp2(Fline(:,:,1),P(2:nPoints-1,2),P(2:nPoints-1,1)));                
            Fext(2:nPoints-1,2) = -kappa*(interp2(Fline(:,:,2),P(2:nPoints-1,2),P(2:nPoints-1,1)));

            %get the total forces
            Ftot = Fspring + Ftips + Fext + Frepel;

            %Update contour with forces
            ssx = gamma*P(:,1) + Ftot(:,1);
            ssy = gamma*P(:,2) + Ftot(:,2);

            %Semi-implicit relaxtion
            P(:,1) = B*ssx;
            P(:,2) = B*ssy;            

            % Resample to make uniform points
            dis=[0;cumsum(sqrt(sum((P(2:end,:)-P(1:end-1,:)).^2,2)))];
            J(:,1) = interp1(dis,P(:,1),linspace(0,dis(end),nPoints));
            J(:,2) = interp1(dis,P(:,2),linspace(0,dis(end),nPoints));

            P = J;
            Pdis = (Pold - J).^2;
            Pdiff = (sum(sqrt(Pdis(2:nPoints-1,1)+Pdis(2:nPoints-1,2))))/nPoints;


            %writeVideo(outputVideo, getframe(gcf));
            %pause();

            iteration = iteration + 1;
        end

%         if iteration >= max_iteration
% %             'WARNING: max iteration reached'
%               %debug
%             imshow(Fline(:,:,1)+Fline(:,:,2), [], 'InitialMagnification', 300, 'Border','tight')
%             hold on
%             plot(Pold(:,2), Pold(:,1), 'g-');
%             quiver(Pold(:,2),Pold(:,1),Ftot(:,2),Ftot(:,1),'AutoScale','off')
%             hold off
%             pause
%         end
        
        dis=[0;cumsum(sqrt(sum((P(2:end,:)-P(1:end-1,:)).^2,2)))];
        % Resample to make uniform points
        K(:,1) = interp1(dis,P(:,1),linspace(0,dis(end),nPoints));
        K(:,2) = interp1(dis,P(:,2),linspace(0,dis(end),nPoints));
    catch
        K = POriginal;
    end
%     close(outputVideo) 
end