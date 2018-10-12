function xtr2CSskyplot(xtrFileName, carrierCode, saveFig, options)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to read Gnut-Anubis XTR output file and make MP skyplot graphs.
% Process iterates through all available satellite systems (it will
% detect automatically) and try to plot given MP combination.
%
% Input:
% xtrFileName - name of XTR file
% MPcode - 2-char representation of MP code combination to plot
%        - values corresponding to RINEX v2 code measurements
%
% Optional:
% saveFig - true/false flag to export plots to PNG file (default: true)
% options - structure with the following settings:
%      colorBarLimits = [0 120]; % Range of colorbar
%      colorBarTicks = 0:20:120; % Ticks on colorbar 
%      figResolution = '200';    % Output PNG resolution
%      getMaskFromData = false;   % Derive terrain mask from available data
%      cutOffValue = 0;          % Value of elevation cutoff on skyplots
%
% Requirements:
% polarplot3d.m, findGNSTypes.m, dataCell2matrix.m, getNoSatZone.m
%
% Peter Spanik, 7.10.2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Close all opened figures
close all

% Default options
opt = struct('colorBarLimits',[0, 120],...
                    'colorBarTicks', 0:20:120,...
                    'figResolution','200',...
                    'getMaskFromData', false,...
                    'cutOffValue',0);

% Check input values
if nargin == 2
   saveFig = true;
   options = opt;
   if ~ischar(xtrFileName) || ~ischar(carrierCode)
      error('Inputs "xtrFileName" and "carrierCode" have to be strings!') 
   end
   
elseif nargin == 3
    saveFig = logical(saveFig);
   if ~ischar(xtrFileName) || ~ischar(carrierCode) || numel(saveFig) ~= 1 
      error('Inputs "xtrFileName","carrierCode" have to be strings and "saveFig" has to be single value!') 
   end
   options = opt;

elseif nargin == 4
   if numel(options) ~= 3
      error('Input variable "limAndTicks" have to be cell of the following form {[1x2 array], [1xn array], [1xn char]}!') 
   end
else
   error('Only 2, 3 or 4 input values are allowed!') 
end

% File loading
finp = fopen(xtrFileName,'r');
raw = textscan(finp,'%s','Delimiter','\n','Whitespace','');
data = raw{1,1};

% Find empty lines in XTR file and remove them
data = data(~cellfun(@(c) isempty(c), data));

% Find indices of Main Chapters (#)
GNScell = findGNSTypes(data);

% Set custom colormap -> empty bin = white
myColorMap = colormap(jet); close; % Command colormap open figure!
myColorMap = [[1,1,1]; myColorMap];

% Satellite's data loading
for i = 1:length(GNScell)
    % Find position estimate
    selpos = cellfun(@(c) strcmp(['=XYZ', GNScell{i}],c(1:7)), data);
    postext = char(data(selpos));
    pos = str2num(postext(30:76));
    
    % Elevation loading
    selELE_GNS = cellfun(@(c) strcmp([GNScell{i}, 'ELE'],c(2:7)), data);
    dataCell = data(selELE_GNS);
    [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell);
    ELE.(GNScell{i}).time = timeStamp;
    ELE.(GNScell{i}).meanVals = meanVal;
    ELE.(GNScell{i}).vals = dataMatrix;
    sel1 = ~isnan(dataMatrix);
    
    % Azimuth loading
    selAZI_GNS = cellfun(@(c) strcmp([GNScell{i}, 'AZI'],c(2:7)), data);
    dataCell = data(selAZI_GNS);
    [timeStamp, meanVal, dataMatrix] = dataCell2matrix(dataCell);
    AZI.(GNScell{i}).time = timeStamp;
    AZI.(GNScell{i}).meanVals = meanVal;
    AZI.(GNScell{i}).vals = dataMatrix;
    sel2 = ~isnan(dataMatrix);
    
    % Check ELE and AZI size
    if size(sel1) == size(sel2)
       % Get timestamps
       if all(ELE.(GNScell{i}).time == AZI.(GNScell{i}).time)
          timeStampsUni = timeStamp;
       end
    else
       error('Reading ELE and AZI failed, not equal number of ELE and AZI epochs!')
    end
    
    % Multipath loading
    selCS_GNS = cellfun(@(c) strcmp([' ', GNScell{i}, 'SLP'], c(1:7)), data);
    if nnz(selCS_GNS) == 0
        warning('For %s system cycle-slip information is missing - no cycle slip occurs!',GNScell{i})
        continue
    end
    dataCell = data(selCS_GNS);
    [~, ~, CS.(GNScell{i})] = dataCell2CSmatrix(dataCell);
end

% Interpolate position of CS event
allSlips = [];
for i = 1:numel(GNScell)
    CycleSlip.(GNScell{i}) = [];
    for prn = 1:32
        if ~isempty(CS.(GNScell{i}){prn})
            % Get the data from cells
            wantedTime = CS.(GNScell{i}){prn}(:);
            givenTime  = AZI.(GNScell{i}).time;
            givenAzi   = AZI.(GNScell{i}).vals(:,prn);
            givenEle   = ELE.(GNScell{i}).vals(:,prn);
            
            % Interpolation
            wantedAzi = interp1(givenTime,givenAzi,wantedTime,'Linear');
            wantedEle = interp1(givenTime,givenEle,wantedTime,'Linear');
            
            % Not select nan values
            selNotNan = ~isnan(wantedAzi) & ~isnan(wantedEle);
            wantedAzi = wantedAzi(selNotNan);
            wantedEle = wantedEle(selNotNan);
            
            % Paste to output
            CycleSlip.(GNScell{i}) = [CycleSlip.(GNScell{i}); [wantedAzi, wantedEle]];
            
        end
    end
    allSlips = [allSlips; CycleSlip.(GNScell{i})];
end

% % Figure of cycle-slip positions
% figure('Position',[200 200 800 320])
% cols = [1 0 0; 1 0 1; 0 0 1];
% for i = 1:numel(GNScell)
%     plot(CycleSlip.(GNScell{i})(:,1),CycleSlip.(GNScell{i})(:,2),'o','Color',cols(i,:))
%     hold on; grid on; box on
% end
% xlabel('Azimuth (deg)')
% ylabel('Elevation (deg)')
% title('Cycle-slip positions')
% legend(GNScell)
% axis([0 360 0 90])
% set(gca,'XTick',0:45:360,'YTick',0:30:90)

% Compute kernel density
aziBins = 0:3:360;
eleBins = 0:3:90;
[x1,x2] = meshgrid(aziBins, eleBins);
x1 = x1(:);
x2 = x2(:);
xi = [x1 x2];
density = ksdensity(allSlips,xi,'Bandwidth',[4.5, 4.5]);
densityReshaped = reshape(density,[numel(eleBins), numel(aziBins)]);


% figure('Position',[200 200 800 320])
% imagesc('XData',aziBins,'YData',eleBins,'CData',densityReshaped,'AlphaData', 1)
% axis([0 360 0 90])
% set(gca,'XTick',0:45:360,'YTick',0:30:90)
% hold on; grid on; box on
% %plot(allSlips(:,1),allSlips(:,2),'k.')
% colormap(flipud(hot))

% % Check for useDataMasking settings
% if options.getMaskFromData
%     visibleBins = getVisibilityMask(AZI.(GNScell{i}).vector,ELE.(GNScell{i}).vector,[3, 3],options.cutOffValue);
%     densityReshaped(~visibleBins) = 0;
% end

% Determine noSatZone bins
[x_edge,y_edge] = getNoSatZone('GPS',pos);
xq = (90 - x2).*sind(x1);
yq = (90 - x2).*cosd(x1);
in = inpolygon(xq,yq,x_edge,y_edge);
densityReshaped(in) = 0;

% Create figure
figure('Position',[300 100 700 480],'NumberTitle', 'off','Resize','off')
polarplot3d(flipud(densityReshaped),'PlotType','surfn','RadialRange',[0 90],'PolarGrid',{6,12},'GridStyle',':','AxisLocation','surf');
view(90,-90)
colormap(flipud(hot))
axis equal
axis tight
axis off

disp('End')

%     
%     colormap(myColorMap)
%     c = colorbar;
%     colLimits = options.colorBarLimits;
%     colLimits(1) = colLimits(1) + 5;
%     c.Limits = colLimits;
%     c.Ticks = options.colorBarTicks;
%     c.Position = [c.Position(1)*1.02, c.Position(2)*1.4, 0.8*c.Position(3), c.Position(4)*0.9];
%     c.TickDirection = 'in';
%     c.LineWidth = 1.1;
%     c.FontSize = 10;
%     
%     caxis(options.colorBarLimits)
%     ylabel(c,sprintf('%s RMS MP%s value (cm)',GNScell{i},MPcode),'fontsize',10,'fontname','arial')
%     axis equal
%     axis tight
%     axis off
%     hold on
%     text(60,0,-100,'30','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')
%     text(30,0,-100,'60','FontSize',10,'HorizontalAlignment','center','background','w','fontname','arial','FontWeight','bold')


% Exporting figure
if saveFig == true
    splittedInputName = strsplit(xtrFileName,'.');
    figName = [splittedInputName{1}, '_GNSS_cycle-slips'];
    print(figName,'-dpng',sprintf('-r%s',options.figResolution))
end
