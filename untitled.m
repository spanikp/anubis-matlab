close all
clear
clc


% Kernel density explanation
SixMPG = [13;15;23;29;32;34];
pdSix = fitdist(SixMPG,'Kernel','BandWidth',4);

% figure
% x = 0:.1:45;
% ySix = pdf(pdSix,x);
% plot(x,ySix,'k-','LineWidth',2)
% 
% % Plot each individual pdf and scale its appearance on the plot
% hold on; grid on
% yy = 0;
% for i=1:6
%     pd = makedist('Normal','mu',SixMPG(i),'sigma',4);
%     y = pdf(pd,x);
%     y = y/6;
%     yy = yy + y;
%     plot(x,y,'b:')
% end
% 
% k = ksdensity(SixMPG,x,'Bandwidth',4);
% plot(x,0.9*k)

binSize = [3,3];
azi = 0:binSize(1):360;
ele = 0:binSize(2):90;
[skyAzi,skyEle] = meshgrid(azi,ele);
gridPoints = [skyAzi(:), skyEle(:)];

samples = [60,15;
           85,12;
           85,12;
           190,70;
           190,70;
           190,70];

%samples = ([360*rand(200,1), 90*rand(200,1)]);
       
figure('Position',[100,100,1200,400])
for p = 190:1:190
    pause(0.01)
    samples(4,:) = [p,70];
    samples(5,:) = [190,70+(p-190)];
    
    subplot(1,2,1)
    plot(samples(:,1),samples(:,2),'*')
    grid on;
    axis([0 360 0 90])
    set(gca,'xtick',0:90:360,'ytick',0:30:90)
    
    subplot(1,2,2)
    dens = size(samples,1)*prod(binSize)*ksdensity(samples,gridPoints,'BandWidth',binSize,'BoundaryCorrection','reflection');
    dens = reshape(dens,size(skyAzi));
    %fprintf('sum(dens) = %.3f\n',sum(sum(dens)))
    
    count = conv2(dens,1.35*ones(3,3),'same');
    %fprintf('max(count) = %.3f\n',max(max(count)))
    imagesc('Xdata',azi,'Ydata',ele,'Cdata',count)
    axis([0 360 0 90])
    box on; grid on;
    colormap(flipud(hot))
    c = colorbar;
    c.Limits = [0, 3];
    caxis(c.Limits)
    %hold on
    %view(0,90)
end

figure('Position',[300 100 700 480],'NumberTitle', 'off','Resize','off')
polarplot3d(flipud(count),'PlotType','surfn','RadialRange',[0 90],'PolarGrid',{6,12},'GridStyle',':','AxisLocation','surf');
view(90,-90)
colormap(flipud(hot))
c = colorbar;
c.Limits = [0, 5];
caxis(c.Limits)
axis equal
axis tight
axis off
hold on
text(60,0,-100,'30','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')
text(30,0,-100,'60','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')





