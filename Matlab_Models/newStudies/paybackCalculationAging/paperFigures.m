
clc
%close all
% exportgraphics(ax,'payback575.jpg','Resolution',600) 
%-----------------------FIG 6---------------------------------------------- 
weeknum = 35;
visualizingDayNum = 10;
% indexfig1 = weeknum*7*24;
% indexfig2 = indexfig1 + visualizingDayNum*24;
% f= figure; 
% yyaxis left
% set(gca, 'XColor','k', 'YColor','k')
% hold on 
% plot(demand.profile(indexfig1:indexfig2),'--','LineWidth',1);    
% plot(squeeze(demand.energyUtl(1,1,1,indexfig1:indexfig2)),'--','LineWidth',2,'Color',[0.42 0.07 0.94]); %[0.9290 0.6940 0.1250]); %
% plot(squeeze(demand.energyEss(1,1,1,indexfig1:indexfig2)),'-','LineWidth',2,'Color','r'); %':',
% plot(squeeze(demand.energyPv(1,1,1,indexfig1:indexfig2)),'-.','LineWidth',2,'Color',[0.1 0.48 0.04]);
% yyaxis right
% set(gca, 'XColor','k', 'YColor','k')
% plot(squeeze(log.ess.soctotal(1,1,indexfig1:indexfig2)),'LineWidth',1,'Color',[0.94 0.38 0.1]);
% ylim([0 1])
% hold off
% grid on
% legend('Total demand request','Purchased energy','BES provided energy','PV provided energy','SoC level')

figure;

weeknum = 35;
visualizingDayNum = 10;

indexfig1 = weeknum * 7 * 24;
indexfig2 = indexfig1 + visualizingDayNum * 24;
x = indexfig1:indexfig2;

pvsize = 10;
essize = 10;

barData1 = demand.profile(indexfig1:indexfig2);
barData2 = squeeze(demand.energyUtl(8, pvsize, essize, indexfig1:indexfig2));
barData3 = squeeze(demand.energyEss(8, pvsize, essize, indexfig1:indexfig2));
barData4 = squeeze(demand.energyPv(8, pvsize, essize, indexfig1:indexfig2));

barData1 = barData1(:);
barData2 = barData2(:);
barData3 = barData3(:);
barData4 = barData4(:);

stackedData = [barData2, barData3, barData4];

if size(stackedData,1) ~= length(x)
    error('The length of the data vectors does not match the length of x vector.')
end

subplot(3, 1, 1);
bar(x, stackedData, 'stacked');
title('PV setup size= 10 kWp, Energy storage size= 10 kWh');
ylabel('Demand');
hold on;
plot(x, barData1, 'k', 'LineWidth', 1);
legend('Purchased energy', 'BES provided energy', 'PV provided energy','Total demand request');

pvsize = 5;
essize = 5;

barData1 = demand.profile(indexfig1:indexfig2);
barData2 = squeeze(demand.energyUtl(8, pvsize, essize, indexfig1:indexfig2));
barData3 = squeeze(demand.energyEss(8, pvsize, essize, indexfig1:indexfig2));
barData4 = squeeze(demand.energyPv(8, pvsize, essize, indexfig1:indexfig2));

barData1 = barData1(:);
barData2 = barData2(:);
barData3 = barData3(:);
barData4 = barData4(:);

stackedData = [barData2, barData3, barData4];

if size(stackedData,1) ~= length(x)
    error('The length of the data vectors does not match the length of x vector.')
end

subplot(3, 1, 2);
bar(x, stackedData, 'stacked');
title('PV setup size= 5 kWp, Energy storage size= 5 kWh');
ylabel('Demand');
hold on;
plot(x, barData1, 'k', 'LineWidth', 1);
%legend('Purchased energy', 'BES provided energy', 'PV provided energy','Total demand request');

pvsize = 2;
essize = 1;

barData1 = demand.profile(indexfig1:indexfig2);
barData2 = squeeze(demand.energyUtl(8, pvsize, essize, indexfig1:indexfig2));
barData3 = squeeze(demand.energyEss(8, pvsize, essize, indexfig1:indexfig2));
barData4 = squeeze(demand.energyPv(8, pvsize, essize, indexfig1:indexfig2));

barData1 = barData1(:);
barData2 = barData2(:);
barData3 = barData3(:);
barData4 = barData4(:);

stackedData = [barData2, barData3, barData4];

if size(stackedData,1) ~= length(x)
    error('The length of the data vectors does not match the length of x vector.')
end

subplot(3, 1, 3);
bar(x, stackedData, 'stacked');
title('PV setup size= 2 kWp, Energy storage size= 1 kWh');
xlabel('Time');
ylabel('Demand');
hold on;
plot(x, barData1, 'k', 'LineWidth', 1);
%legend('Purchased energy', 'BES provided energy', 'PV provided energy','Total demand request');

%-----------------------FIG 7----------------------------------------------
% figure
index1 = 1:20;
inv.essPv(2:20) = 0;
inv.profit = squeeze(inv.profit);
yyaxis left
hold on
fiancial = [inv.profit -inv.essPv' -inv.replace'  -inv.maintenance']; %-inv.essPv ;
y= bar (index1, fiancial);
y(1).FaceColor = 'blue';
y(2).FaceColor = 'red';
y(3).FaceColor = 'magenta';
y(4).FaceColor = [0.8500 0.3250 0.0980];
yyaxis right
plot(squeeze(inv.regain),'.-','LineWidth',3);
grid on
lgd = legend ("Annual cash flow",  "Capital cost" , "Replacement cost" , "Annual maintenance cost");
set(lgd,'FontName','Times New Roman');
set(lgd,'FontSize',11);
legend show
legend Location southeast
legend('boxoff')
lgd.NumColumns = 2;
hold off
ax = gca;
ax.YAxis(1).Color = 'k';
ax.YAxis(2).Color = 'k';
set(gca, 'XColor','k', 'YColor','k')
%--------------------------------------------------------------------------