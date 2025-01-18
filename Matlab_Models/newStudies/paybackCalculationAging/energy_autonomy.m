clc
%close all


loadDemand = sum(demand.profile);

% for index = 1:20
%         Pv.database         = (index*1000/max(Ppv)).* Ppv';         % Normalize and adjust peak of generated PV to Ppv_max
%         Pv.database         = repmat(Pv.database,1,simu.period);
%         Pv.datalog(index,:) = Pv.database;
%         pvgeneration(index) = sum(Pv.datalog(index,:));
% end

for index1 = 1:8 
    for index2= 1:20
        for index3 = 1:15
            
            utldemandbuy(index1,index2,index3)= sum (log.utl.importEnergy (index1,index2,index3,:)) ; %demand.energyUtl demand.energyPv  %  -log.utl.feedinEnergy(index1,index2,index3,:)  %-demand.energyEss(index1,index2,index3,:)
%             feedinEnergy(index1,index2,index3)= sum(log.utl.feedinEnergy(index1,index2,index3,:)); 
%             %utldemandbuy(index1,index2,index3)= sum (demand.energyUtl(index1,index2,index3,:)) ; %demand.energyPv
%             pvload(index1,index2,index3) = sum (demand.energyPv(index1,index2,index3,:)+ supply.energyPVEss(index1,index2,index3,:)); %; + demand.energyEssPV(index1,index2,index3,:)
%             bessload(index1,index2,index3) = sum (demand.energyEss(index1,index2,index3,:));
            
            energy.autonomy(index1,index2,index3) = 1 - ((utldemandbuy(index1,index2,index3))) /loadDemand;
            %energy.greenUsage(index1,index2,index3) = (pvgeneration(index2) - pvload(index1,index2,index3))/pvgeneration(index2)  ;
            %energy.greenUsage(index1,index2,index3) = (loadDemand - pvload(index1,index2,index3))/loadDemand  ; %
         %   energy.greenUsage22(index1,index2,index3) = (pvload(index1,index2,index3))/pvgeneration(index2)  ; %
     %       energy.Ess(index1,index2,index3)= (loadDemand - bessload(index1,index2,index3))/loadDemand;

        end
    end
end


% for index1 = 1:4
% for index2 = 1:20
%     for index3 = 1:15
%         energy.autonomy(index1,index2,index3) = sum (demand.energyUtl(index1,index2,index3,:))/sum(demand.profile);
%         energy.greenUsage(index1,index2,index3)= sum (demand.energyPv(index1,index2,index3,:))/sum(demand.profile);
%         energy.Ess(index1,index2,index3)= sum (demand.energyEss(index1,index2,index3,:))/sum(demand.profile);
%     end
% end
% end
% 
for index1 = 1:20
    for index2 = 1:15
        %energyAutNoFeed(index1) = (pvgeneration(index1))/loadDemand;
        energyAutonomy(index1,index2) =mean (energy.autonomy(:,index1,index2));
%         if energyAutonomy(index1,index2)>=0
%             PenergyAutonomy(index1,index2) = energyAutonomy(index1,index2);
%         else
%             NenergyAutonomy(index1,index2) = energyAutonomy(index1,index2);
%         end
% %         PVselfconsumption (index1,index2)  = max(pvload(:,index1,index2));
%         PVselfconsumption (index1,index2) = PVselfconsumption (index1,index2)/pvgeneration(index1);
%         feedinenergy(index1,index2)       = feedinEnergy(4,index1,index2);
%         %energyGreen  (index1,index2)  = max (energy.greenUsage(:,index1,index2));
%      %   energyGreen22  (index1,index2)  = max (energy.greenUsage22(:,index1,index2));
%         energyEss    (index1,index2)    = max (energy.Ess(:,index1,index2));
    end
end


figure 
mesh(energyAutonomy)
% for index1 = 1:20
%     greenaut(index1) = 1- pvgeneration(index1)/loadDemand;
% 
% end

% figure 
% plot (greenaut)

% figure 
% plot(energyAutNoFeed)
% figure
% for index1 = 20:-1:1
%     for index2 = 15:-1:1
%     if energyAutonomy(index1,index2) >=0 
%         scatter3(index1,index2,energyAutonomy(index1,index2),'blue','filled','o')
%     else
%         scatter3(index1,index2,energyAutonomy(index1,index2),'red','filled','o')
%     end
%     hold on
%     end
% end
% figure
% PenergyAutonomy(PenergyAutonomy==0)=NaN;
% NenergyAutonomy(NenergyAutonomy==0)=NaN;
% mesh (PenergyAutonomy*100,'EdgeColor',[0.00,0.45,0.74])
% hold on
% mesh (NenergyAutonomy*100,'EdgeColor',[0.64,0.08,0.18])

% figure 
% mesh (PVselfconsumption)
% figure 
% mesh (feedinenergy/max(max(feedinenergy)))
%figure
% plot(energyGreen(:,10)*100)
% hold on 
% plot(energyGreen22(:,10)*100)
% hold on 
% plot (energyGreen2(:,10)*100)
% legend ('PV self consumption assuming no feed in energy', 'PV self consumption assuming feed in energy')
% legend show
%mesh (energyGreen)
% figure
% mesh(energyEss)

%  figure 
% for index2 = 1:20
%     for index3 = 1:15
%        scatter3(index2,index3, energy.autonomy(4,index2,index3),'filled');
%        hold on
%     end
% end


% figure 
% for index1 = 1:20
%     plot(energyAutonomy(index1,:))
%     hold on
% end
%surf (energyGreen)
% surf (energyEss)
% % 
% figure 
% surf (energy.greenUsage)
% % 
% figure 
% surf (energy.Ess)
% Profit calculations
% for i = 1:length(pv.nominates)  
% 
%     [utl.minpayback(i),best_battery_size(i)] = min(inv.payback(i,:));
% 
%     for j= 1:length(simu.dur)
%         inv.profit(i,j) =  - inv.essPv(i,best_battery_size(i)) + simu.dur(j) * (utl.bill - utl.netSmartBill(i,best_battery_size(i)));
%     end
% end

% minimum pay back time best battery size calculation
% for i = pv.nominates
%     j = find(pv.nominates==i);
%     [utl.minpaybackS,best_battery_size] = min(inv.payback(j,:));
%     txt = ['PV size= ',num2str(i),' kW'];
%     plot (1:1:8 , inv.payback(j,:),'DisplayName',txt) 
%     %plot (inv.payback(j,:),'DisplayName',txt)
%     hold on;
%     plot(best_battery_size,utl.minpaybackS,'*r','HandleVisibility','off');
% end
% 
% title("Payback time calculation cosidering PV and Bess variable sizes");
% xlabel('Battery size (kWh)');
% ylabel('Payback time (Year)');
% legend show;
% ax = gca;
% exportgraphics(ax,'graph.jpg','Resolution',600)
% hold off;


% Visualizing the results
% figure; 
% for i = pv.nominates 
%     j = find(pv.nominates==i);
%     txt = ['PV size= ',num2str(i),' kW','       Payback time= ', num2str(utl.minpayback(j),3),' Years'];  % > 0, 1, 'first')) num2str(inv.profit(j,:))
%     plot(inv.profit(j,:),'DisplayName',txt);
%     hold on;
% end
% legend Location northwest;
% legend('FontSize', 7);
% legend show;
% title("Profits cosidering PV and Bess optimum sizes");
% ylabel('Profit (Euro)');
% xlabel('Year');
% %ylim([0 20000]);
% %xlim([0 70]);
% ax2 = gca;
% exportgraphics(ax2,'graph2.jpg','Resolution',600)
% hold off;

% f = figure;
% 
% subplot(4,1,1);
% plot(demand.profile,'Color',"red");
% title("Energy demand profile");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([0 5.5]);
% hold on;
% 
% subplot(4,1,2);
% plot(pv.database,'Color',"cyan");
% title("Energy generation profile");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([0 5.5]);
% 
% subplot(4,1,3);
% plot(energy.utility,'DisplayName', "Energy exchange with grid");
% %plot(battery_charge_capacity,'DisplayName', "Bess available energy amount");
% title("Energy flow of main grid");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([-1 5]);
% 
% subplot(4,1,4);
% plot(battery_charge_capacity,'DisplayName', "Bess available energy amount","Color",'magenta');
% title("Energy flow of Bess");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([-2 11]);
% 
% legend show;
% %ax = gca;
% exportgraphics(f,'graph_3.jpg','Resolution',600);

% figure
% subplot(3,1,1)
% plot (ess.soc(1:3000))
% hold on
% 
% subplot(3,1,2)
% plot (ess.soh)
% subplot(3,1,3)
% plot(soc.cycleDischarge+soc.cycleCharge)
% min(ess.soh)
%bar (ess.soc(200:300))


