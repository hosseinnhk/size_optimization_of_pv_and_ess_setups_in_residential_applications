% Simple scheduling
% calculations for various pv and battery sizes and comparison of payback time and inv.profit during 15 years.
% In this version the real price data will added to the system. Prices are
% since 1.1.2022 to 31.12.2022 ( Becuase today is 13.10.2022 the remaining
% days' prices will be mimiced from Aug price calendar). 
% in this version (4) system will run for 15 years with new strategy for
% battery charging. 

clc
clear
close all;
tic;

load ('PL_Ppv');
load ("elecPriceDataBase_ver02.mat");

dummy.range = 0:23;
dummy.count = 1;
dummy.lastEl = size(elecPriceData2022.time(:,1));

%replacing time am pm format by dec numbers. 
while dummy.count < dummy.lastEl(1,1)
    for i= dummy.range 
        elecPriceData2022.time(dummy.count + i) = i;        
    end
    dummy.count = dummy.count + 24 ;
end

% selecting 2022 data
priceDatabase2022 = elecPriceData2022(17545:end,:);
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5833-24:6552,:)];    % oct 31 *1.1025 
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5833:6552,:)];       % Nov 30 *1.1576
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5833:6552,:)];       % Dec 30 *1.215   MWh

% System charactereistics
pv.nominates            = 7000; %[3,5,7,10].*1000; %[2,3,4,5,6,7,8,9,10]*1000; 
pwr.Max                 = 5000;                   % Maximum of load demand during a year. W
pv.index                = 0;
demand.grothRate        = 1.05;                   % demand increasing trend during 10 years.
demand.groth            = ones(length(PL),1);

% Utility trf parameters
utl.trf =  priceDatabase2022(:,3);
%priceVec(5491,1) = {750}; %removing the outilier data 4000Euro
utl.trf = table2array(utl.trf);

% adding 5 percent inlflation rate for next 3 monthes of 2022
utl.trf(6553:7296,1) = utl.trf(6553:7296,1)* 1.05;
utl.trf(7297:8016,1) = utl.trf(7297:8016,1)* 1.10;
utl.trf(8017:8736,1) = utl.trf(8017:8736,1)* 1.15;
utl.trf              = (utl.trf'./1000000 ); % Wh
utl.inflationRate       = 1.03; % utility price inflation rate
utl.inflation           = ones(length(PL),1);
utl.minpayback          = zeros(length(pv.nominates),1);
utl.peakPr              = 1;
utl.offPeakPr           = 2;
utl.normalPr            = 3;

%Energy storage system parameters
ess.cellNomVoltage      = 3.3;                 % Cell nominal voltage.
ess.cellvoltageLuT      = 3.3 * ones(1,100);   % Cell voltage look up table base on soc.
ess.PB_max              = 5000;                % Maximum delivarable power exchange with battery. W
ess.minSoC              = 0.15;                % Minimum State of Charge in Battery.
ess.maxSoC              = 0.9;                 % Maximum State of Charge in Battery.
ess.SoH_nom             = 1;                   % State of health
ess.EoL                 = 0.7;                 % End of life
ess.roundTripEf         = 0.97;                % ess roundtrip efficiency
ess.temp                = 30;                  % ess cell temp centigrad
ess.tempRef             = 22;                  % ambient temp centigrad
ess.Crate               = 1;                   % ess cell c rate Ah
ess.energyRouterEf      = 0.98;                % Energy router efficiency
ess.nominates           = 10000; %linspace(1,15,15).*1000;   %linspace(1,15,15);                     % Different battery capacity with the step of 1 Wh.
ess.srCell_nom          = [35,70,70,70,70,70,70,70,70,105,105,105,105,105,105];
ess.prlCell_nom         = [8,8,12,16,20,24,28,33,38,27,30,33,35,38,41];
ess.optSize             = zeros(length(pv.nominates),1);   % ESS optimum size based on pv size
ess.Ea                  = 78.06;   %k.mol/J
ess.R                   = 8.314;   %j/k.mol
ess.ks1                 = -4.029e-4;   % paper : Practical Capacity Fading Model for Li-Ion Battery Cells in Electric Vehicles
ess.ks2                 = -2.167;
ess.ks3                 = 1.408e-5;
ess.ks4                 = 6.13;
ess.Qnom                = 1.1; %Ah

% Simuulation parameters 
simu.period              = 10;   % year
simu.dur                 = linspace(1,50,50);
simu.essSamples          = length(ess.nominates);
simu.pvSamples           = length(pv.nominates);

% Financial parameters              
inv.ess                 = 135;                 % Investment cost of battery ($/kWh). based on Bloomberg data
inv.pv                  = 1000;                % Investment cost of PV ($/kWp). 
inv.infr                = 450;                 % Infrustructure cost. ($/kW)
inv.essPv               = zeros(length(pv.nominates),length(ess.nominates));   % Vector for investement on infrastructures
inv.oprCost             = zeros(length(pv.nominates),length(ess.nominates));   % Vector for summing  operational cost of system considering battery and PV at each battery capacity
inv.payback             = zeros(length(pv.nominates),length(ess.nominates));
inv.profit              = zeros(length(pv.nominates),length(simu.dur));


for i= 2:simu.period
    utl.inflation     = [utl.inflation ; ones(length(PL),1)*(utl.inflationRate^i)];
    demand.groth      = [demand.groth  ; ones(length(PL),1)*(demand.grothRate^i)];
end

demand.profile      = (pwr.Max/max(PL)).* PL';                 % Normalize and adjust peak of load demand to pwr.Max          
demand.profile      = repmat(demand.profile,1,simu.period);
demand.profile      = demand.profile .* demand.groth';
demand.profile      = demand.profile; %Wh

simu.length          = size(demand.profile);
utl.trf              = repmat(utl.trf,1,simu.period);
utl.trf              = utl.trf .* utl.inflation';

% feed in trf calculation

utl.feedinTrf          = .8 *utl.trf; %Wh
utl.billtotal          = zeros((simu.length));
utl.bill               = sum(demand.profile.*utl.trf);

for index = 2:simu.length(1,2)
    utl.billtotal(index)    = utl.billtotal(index-1) + demand.profile(index)*utl.trf(index);
end

% Bills and cost functions
utl.smartBill          = zeros((simu.length));
utl.feedinBill         = zeros((simu.length));
utl.feedBenefit        = zeros((simu.length)); 
utl.importCost         = zeros((simu.length));
ess.chargeBenefit      = zeros((simu.length));
ess.dischargeCost      = zeros((simu.length));


% Final data collecting

ess.SoHtotal            = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
ess.current             = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
ess.SoCtotal            = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
utl.feedinEnergy        = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
utl.importEnergy        = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));

%calculation of demand response by pv ess utl 
demand.energyPv         = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
demand.energyEss        = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
demand.energyUtl        = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));

%soc states 
soc.socCharge           = zeros((simu.length));
soc.socDischarge        = zeros((simu.length));
soc.cycleCharge         = zeros((simu.length));
soc.cycleDischarge      = zeros((simu.length));
dummy.soc.socCharge     = 0;
dummy.soc.socDischarge  = 0;
dummy.soc.cycleCharge   = 0;
dummy.soc.cycleDischarge= 0;
%dummy.count            = 0 ;  

for pv_size = pv.nominates

    pv.index       = pv.index +1;
    pv.database    = (pv_size/max(Ppv)).* Ppv'; % Normalize and adjust peak of generated PV to Ppv_max
    pv.database    = repmat(pv.database,1,simu.period);
    ess.index      = 0;
    
    for ess_size = ess.nominates
        ess.cap = ess_size;
        ess.index                  = ess.index +1;
        energy.flow                = pv.database - demand.profile; % positive surplus negative shortage. Wh

        utl.energy                 = zeros((simu.length)); 
        utl.smartBillt             = zeros((simu.length)); 
        utl.feedinBillt            = zeros((simu.length)); 
        
        ess.energy                 = zeros((simu.length));
        ess.energy(1)              = ess.maxSoC* ess_size;
        ess.SoC                    = zeros((simu.length));
        ess.SoC(1)                 = ess.maxSoC;        
        ess.SoH                    = zeros((simu.length));
        ess.SoH(1)                 = ess.SoH_nom;    
        ess.cellFade               = zeros((simu.length));
        ess.parallelCellNum        = ess.prlCell_nom (ess.index);
        ess.seriesCellnum          = ess.srCell_nom(ess.index);
        ess.packVoltage            = ess.cellNomVoltage * ess.seriesCellnum; % corrrect it at final version
        %ess.Qnom                  = ess_size/ess.Voltage; 
             
        for index = 1:length(demand.profile)
            
            demand.energyPv(pv.index, ess.index,index) = min(demand.profile(index),pv.database(index));
            
            dummy.clockTime    = rem(index-1,24); 
            dummy.tillMidnight = 23 - dummy.clockTime;
            energy.genPred     = 0;
            energy.demPred     = 0;
        
            if  dummy.clockTime==0   
              
                [utl.trfMin,utl.trfMinInd] = min(utl.trf(index:index+23)); % the lowest utility tariff in the day
                utl.trfMinInd = utl.trfMinInd + index - 1;
                [utl.trfMax,utl.trfMaxInd] = max(utl.trf(index:index+23)); % the highest utility tariff in the day
                utl.trfMaxInd = utl.trfMaxInd + index - 1;
            end

            % Predictions
            for stepForward = 1:dummy.tillMidnight

                energy.genPred  = energy.genPred + pv.database(index+stepForward); 
                energy.demPred  = energy.demPred + demand.profile(index+stepForward);                
            end

            if utl.trf(index) >= 0.75 * utl.trfMax  
                utl.state = utl.peakPr;
            elseif utl.trf(index) <= 1.25 * utl.trfMin 
                utl.state = utl.offPeakPr;
            else 
                utl.state = utl.normalPr;
            end

            switch utl.state
                case utl.normalPr

                      if energy.flow(index) > 0    % energy surplus

                       if  energy.genPred <= energy.demPred % we should charge battery for the near future
                            
                            [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.SoC(index),dummysoc]= ...
                            battery_update_4(index,ess,'charge',energy.flow(index),soc);

                            %demand.energyEss 
                            if energy.flow(index) > 0
                                utl.feedinEnergy(pv.index, ess.index,index) = energy.flow(index);
                                utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);
                                energy.flow(index)    = 0;
                            end                        
                        else
                                utl.feedinEnergy(pv.index, ess.index,index) = energy.flow(index);
                                utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);  %usd
                                energy.flow(index) = 0; 
                        end

                     elseif energy.flow(index) < 0

                        if  energy.genPred >= energy.demPred   
                            [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.SoC(index),dummy.soc]= ...
                            battery_update_4(index,ess,'discharge',energy.flow(index),soc);
                            if energy.flow(index) < 0
                                demand.energyUtl(pv.index, ess.index,index) = -energy.flow(index);
                                utl.importEnergy(pv.index, ess.index,index) = -energy.flow(index);
                                utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                                energy.flow(index)   = 0;
                            end  
                       else 
                            demand.energyUtl(pv.index, ess.index,index) = -energy.flow(index);
                            utl.importEnergy(pv.index, ess.index,index) = -energy.flow(index);
                            utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                            energy.flow(index)   = 0;                            
                       end

                     else
                        print("energy flow zero")
                     end

                case utl.offPeakPr

                     if energy.flow(index) > 0    % energy surplus
                           
                        [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.SoC(index),dummy.soc]= ...
                        battery_update_4(index,ess,'charge',energy.flow(index),soc);

                        %demand.energyEss 
                        if energy.flow(index) > 0
                            utl.feedinEnergy(pv.index, ess.index,index) = energy.flow(index);
                            utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);
                            energy.flow(index)    = 0;
                        end                        

                     elseif energy.flow(index) < 0 

                        demand.energyUtl(pv.index, ess.index,index) = -energy.flow(index);
                        utl.importEnergy(pv.index, ess.index,index) = -energy.flow(index);
                        utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                        energy.flow(index)   = 0;  
                        
                     else
                        print("energy flow zero")
                     end

                     if ess.SoC(index) < 0.4 && utl.trf(index) == utl.trfMin   % ess charge from grid

                        dummy.essEnergy = ess.energy(index);
                        dummy.cellFade  = ess.cellFade(index); 
                        ess.fullCharge  = (ess.maxSoC - ess.SoC(index))*ess_size;
                        ess.fullCharge  = min(ess.PB_max, ess.fullCharge);  
                 
                        [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.SoC(index),dummy.soc]= ...
                        battery_update_4(index,ess,'charge',ess.fullCharge,soc);

                        utl.importEnergy(pv.index, ess.index,index) = utl.importEnergy(pv.index, ess.index,index) + ...
                                                                      (ess.energy(index) - dummy.essEnergy); 

                        utl.smartBill(index) = utl.smartBill(index) + utl.trf(index)*(ess.energy(index) - dummy.essEnergy);
                        dummy.essEnergy = 0; 
                        ess.cellFade(index)  = dummy.cellFade  + ess.cellFade(index);

                     end                     

                case utl.peakPr
                     if energy.flow(index) > 0    % energy surplus

                        utl.feedinEnergy(pv.index, ess.index,index) = energy.flow(index);
                        utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);
                        energy.flow(index) = 0; 

                     elseif energy.flow(index) < 0

                        [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.SoC(index),dummy.soc]= ...
                        battery_update_4(index,ess,'discharge',energy.flow(index),soc);
                        if energy.flow(index) < 0
                            demand.energyUtl(pv.index, ess.index,index) = -energy.flow(index);
                            utl.importEnergy(pv.index, ess.index,index) = -energy.flow(index);
                            utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                            energy.flow(index)   = 0;
                        end  
                     else
                        print("energy flow zero")
                     end

                     if ess.SoC(index) > 0.6 && utl.trf(index) == utl.trfMax   % energy export to grid at max point 
                        dummy.essEnergy = ess.energy(index);
                        dummy.cellFade  = ess.cellFade(index);
                        [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.SoC(index),dummy.soc]= ...
                        battery_update_4(index,ess,'discharge',ess.energy(index),soc);
                        utl.feedinEnergy(pv.index, ess.index,index) = utl.feedinEnergy(pv.index, ess.index,index) + ...
                                                                      (dummy.essEnergy - ess.energy(index)); 
                        utl.feedinBill(index) = utl.feedinBill(index) + utl.feedinTrf(index)*(dummy.essEnergy - ess.energy(index));
                        dummy.essEnergy = 0; 
                        ess.cellFade(index)  = dummy.cellFade  + ess.cellFade(index);
                     end

                otherwise
                    print("otherwise");
            end

           ess.SoH(index) = 1 - sum(ess.cellFade)/(0.2* ess.Qnom);
           ess.SoH(index) = ess.SoH(index) * ((0.98)^(index/8736)); % calendar age factor

           if index ~= length(demand.profile)
              
               ess.SoH(index+1)            = ess.SoH(index); 
               ess.SoC(index+1)            = ess.SoC(index);
               ess.energy(index+1)         = ess.energy(index);
               utl.smartBillt(index+1)     = utl.smartBillt(index)  + utl.smartBill(index);
               utl.feedinBillt(index+1)    = utl.feedinBillt(index) + utl.feedinBill(index);  
               soc.socCharge(index+1)      = dummy.soc.socCharge;
               soc.socDischarge(index+1)   = dummy.soc.socDischarge;
               soc.cycleCharge(index+1)    = dummy.soc.cycleCharge;
               soc.cycleDischarge(index+1) = dummy.soc.cycleDischarge;
           end
        end

        % End of x years simulation
        % system result log
         ess.SoHt(pv.index,ess.index,:)  = ess.SoH';
        % inv.oprCost(pv.index,ess.index) = sum ( abs(utl.smartBill) - utl.feedinBill);  %sum(utl.energy.* utl.trf) ;

        % inv.essPv(pv.index,ess.index)   = ess_size * (inv.ess)/1000 + inv.pv * pv_size; % +PB_max*10;  %1700
        % inv.payback(pv.index,ess.index) = ... 
        % inv.essPv(pv.index,ess.index) ./ (utl.billtotal - inv.oprCost(pv.index,ess.index)); 
    end      
end

% Profit calculations
% for i = 1:length(pv.nominates)  
% 
%     [utl.minpayback(i),best_battery_size(i)] = min(inv.payback(i,:));
% 
%     for j= 1:length(simu.dur)
%         inv.profit(i,j) =  - inv.essPv(i,best_battery_size(i)) + simu.dur(j) * (utl.bill - inv.oprCost(i,best_battery_size(i)));
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

figure
subplot(3,1,1)
plot (ess.SoH)
%hold on
subplot(3,1,2)
plot (ess.energy)

subplot(3,1,3)
plot((soc.cycleCharge+soc.cycleDischarge)/2)


% figure;
% plot (utl.trf(6553:7296)*10e6);
% hold on
% plot (utl.feedinTrf(6553:7296)*10e6);

%sohi=ess.SoH';

% figure 
% plot(pv.database*1000)
% hold on
% plot(demand.profile*1000)
% plot(squeeze(demand.energyPv(1,1,:)))

toc;


