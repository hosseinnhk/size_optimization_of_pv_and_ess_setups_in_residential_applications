close all;

% figure
% for index1 = 1:20
%     plot(squeeze(log.ess.sohtotal(6 ...
%         ,index1,:,end)),LineWidth=1)      
%     hold on
%     grid on
% end
% 
% lgd = legend ("PV size = 1 kW",  "PV size = 2 kW" , "PV size = 3 kW" , "PV size = 4 kW",...
%     "PV size = 5 kW",  "PV size = 6 kW" , "PV size = 7 kW" , "PV size = 8 kW",...
%     "PV size = 9 kW",  "PV size = 10 kW" , "PV size = 11 kW" , "PV size = 12 kW",...
%     "PV size = 13 kW",  "PV size = 14 kW" , "PV size = 15 kW" , "PV size = 16 kW",...
%     "PV size = 17 kW",  "PV size = 18 kW" , "PV size = 19 kW" ,"PV size = 20 kW"...
%     );
% set(lgd,'FontName','Times New Roman');
% set(lgd,'FontSize',9);
% legend show
% legend Location southeast
% legend('boxoff')
% lgd.NumColumns = 2;


% figure
% for index1 = 1:15
%     plot(squeeze(log.ess.sohtotal(6,:,index1,end)),LineWidth=1)
% %    xlim([1,15]);
% %    xticks(1:15);        
%     hold on
%     grid on
% end
% 
% lgd = legend ("BES size = 1 kWh",  "BES size = 2 kWh" , "BES size = 3 kWh" , "BES size = 4 kWh",...
%     "BES size = 5 kWh",  "BES size = 6 kWh" , "BES size = 7 kWh" , "BES size = 8 kWh",...
%     "BES size = 9 kWh",  "BES size = 10 kWh" , "BES size = 11 kWh" , "BES size = 12 kWh",...
%     "BES size = 13 kWh",  "BES size = 14 kWh" , "BES size = 15 kWh"  ...
%     );

bs = 1:15;
pvs= 1:20;
[BS, PVS] = meshgrid(bs, pvs);

% Plot the data using contour3
figure;
[M,c]=contour3(PVS, BS, squeeze(log.ess.sohtotal(6,:,:,end)),100,'Fill','on');
c.LineWidth = 2;
xlabel('PV size');
ylabel('Bess size');
zlabel('Soh Values');

sohValues = squeeze(log.ess.sohtotal(:,:,:,end));

bs = 1:15;
pvs= 1:20;
ers = 1:8;
[BS, PVS,ERS] = meshgrid(bs, pvs,ers);

% Create the bubble chart
figure;
b = bubblechart3(ERS(:), PVS(:), BS(:), sohValues(:), sohValues(:));
bubblesize([5 30])
bubblelegend('SoH values','Location','eastoutside')
% b.SizeData = 50 * b.SizeData / max(b.SizeData); 
xlabel('ER size');
ylabel('PV size');
zlabel('BESS Values');
title('3D Bubble Chart');

