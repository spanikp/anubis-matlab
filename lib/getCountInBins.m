%function count = getCountInBins(aziBins,eleBins,allSlips)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function assign occurences in "allSlips" variable to azimuthal/elevation
% matrix.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
clear 
clc

load allSlips
binSize = [3,3];
aziBins = 0:binSize(1):360;
eleBins = 0:binSize(2):90;


allSlips = unique(allSlips,'rows');
fprintf('Total CS number = %d\n',size(allSlips,1));

[N,Xedges,Yedges] = histcounts2(allSlips(:,1),allSlips(:,2),aziBins,eleBins);
N = N';
realMaxCS = max(max(N));
fprintf('Real maximum CS in Bin = %d\n',realMaxCS)

% Kernel smoothing
gaussKernel = fspecial('gaussian', [4,4],1.5);
N = conv2(N,gaussKernel,'same');
N = 0.685^2*conv2(N,ones(4,4),'same');
fprintf('Maximum CS in Bin after blur = %d\n',round(max(max(N))))
fprintf('Total CS after blur = %d\n',round(sum(sum(N))));

figure('Position',[0 200, 1200 400])
subplot(1,2,1)
plot(allSlips(:,1),allSlips(:,2),'.')
axis([0 360 0 90])
grid on;
set(gca,'xtick',aziBins,'ytick',eleBins)

subplot(1,2,2)
imagesc(flipud(N));
colormap(flipud(hot))
c = colorbar;
c.Limits = [0 14];
caxis(c.Limits)
grid on; box on;
set(gca,'xtick',0.5:1:size(N,2)+0.5,'XTickLabel',strsplit(num2str(aziBins),' '))
set(gca,'ytick',0.5:1:size(N,1)+0.5,'YTickLabel',strsplit(num2str(fliplr(eleBins)),' '))

if options.colorBarOn
    c = colorbar;
    c.Limits = [0, options.colorBarLimits];
    c.Ticks = options.colorBarTicks;
    c.Position = [c.Position(1)*1.02, c.Position(2)*1.4, 0.8*c.Position(3), c.Position(4)*0.9];
    c.TickDirection = 'in';
    c.LineWidth = 1.1;
    c.FontSize = 10;
    caxis(options.colorBarLimits)
    ylabel(c,'Number of cycle-slips per bin','fontsize',10,'fontname','arial')
else
    caxis(c.Limits)
end

axis equal
axis tight
axis off
hold on
text(60,0,-100,'30','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')
text(30,0,-100,'60','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')
   
% Exporting figure
if saveFig == true
    splittedInputName = strsplit(xtrFileName,{'.','/'});
    figName = [fullfile(options.figSavePath, splittedInputName{end-1}), '_allGNSS_cycle-slips'];
    print(figName,'-dpng',sprintf('-r%s',options.figResolution))
end
