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
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5833:6552,:)];       % Dec 30 *1.215

% System charactereistics
pv.nominates            = 7; %[3,5,7,10]; %[2,3,4,5,6,7,8,9,10]; 
pwr.Max                 = 5;                   % Maximum of load demand during a year. kW
pv.index                = 0;
demand.grothRate        = 1.05;                % demand increasing trend during 10 years.
demand.groth            = ones(length(PL),1);

% Utility trf parameters
utl.trf =  priceDatabase2022(:,3);
%priceVec(5491,1) = {750}; %removing the outilier data 4000Euro
utl.trf = table2array(utl.trf);
% adding 5 percent inlflation rate for next 3 monthes of 2022
utl.trf(6553:7296,1) = utl.trf(6553:7296,1)* 1.05;
utl.trf(7297:8016,1) = utl.trf(7297:8016,1)* 1.10;
utl.trf(8017:8736,1) = utl.trf(8017:8736,1)* 1.15;
utl.trf              = (utl.trf'./1000000 ); %Wh
utl.inflationRate       = 1.03; % utility price inflation rate
utl.inflation           = ones(length(PL),1);
utl.minpayback          = zeros(length(pv.nominates),1);

%Energy storage system parameters
ess.cellNomVoltage      = 3.3;                 % Cell nominal voltage.
ess.cellvoltageLuT      = 3.3 * ones(1,100);   % Cell voltage look up table base on soc.
ess.PB_max              = 5;                   % Maximum delivarable power exchange with battery. kW
ess.minSoC              = 0.15;                % Minimum State of Charge in Battery.
ess.maxSoC              = 0.90;                % Maximum State of Charge in Battery.
ess.SoH_nom             = 1;                   % State of health
ess.EoL                 = 0.7;                 % End of life
ess.roundTripEf         = 0.97;                % ess roundtrip efficiency
ess.temp                = 30;                  % ess cell temp centigrad
ess.tempRef             = 22;                  % ambient temp centigrad
ess.Crate               = 1;                   % ess cell c rate Ah
ess.EnergyRouterEf      = 0.98;                % Energy router efficiency
ess.nominates           = 10; %linspace(1,8,8);   %linspace(1,15,15);                     % Different battery capacity with the step of 1 kWh.
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
simu.period              = 15;   % year
simu.dur                 = linspace(1,50,50);
simu.essSamples          = length(ess.nominates);
simu.pvSamples           = length(pv.nominates);

% Financial parameters              
inv.ess                 = 135;                 % Investment cost of battery ($/kWh). based on Bloomberg data
inv.pv                  = 1000;                % Investment cost of PV ($/kWp). 
inv.infr                = 450;                 % Infrustructure cost. 
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

simu.length          = size(demand.profile);
utl.trf              = repmat(utl.trf,1,simu.period);
utl.trf              = utl.trf .* utl.inflation';

% feed in trf calculation

utl.feedinTrf          = .8 *utl.trf; %Wh
utl.billtotal          = zeros((simu.length));

for index = 2:simu.length(1,2)
    utl.billtotal(index)    = utl.billtotal(index-1) + demand.profile(index)*utl.trf(index)*1000;
end

% Bills and cost functions
utl.smartBill          = zeros((simu.length));
utl.feedinBill         = zeros((simu.length));
utl.feedBenefit        = zeros((simu.length)); 
utl.importCost         = zeros((simu.length));
ess.chargeBenefit      = zeros((simu.length));
ess.dischargeCost      = zeros((simu.length));

%dummy.count                   = 0 ;
% figure;
% plot (priceVec(6553:7296));
% hold on
% plot (feedintarriff(6553:7296));

% Final data collecting

ess.SoHtotal            = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
ess.current             = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
ess.SoCtotal            = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
utl.feeninEnergy        = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
utl.imortEnergy         = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
%calculation of demand response by pv ess utl 
demand.energyPv         = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
demand.energyEss        = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));
demand.energyUtl        = zeros(simu.pvSamples, simu.essSamples, simu.length(1,2));

% Machine states
  state.reset        = 0;
  state.initial      = 1;
  state.essCharge    = 2;
  state.essDischarge = 3;
  state.utlImport    = 4;
  state.utlExport    = 5;
%   state.essUtlCharge = 6;
%   state.essUtlDischarge = 7;

  machine.state = state.initial;  

for pv_size = pv.nominates

    pv.index       = pv.index +1;
    pv.database    = (pv_size/max(Ppv)).* Ppv'; % Normalize and adjust peak of generated PV to Ppv_max
    pv.database    = repmat(pv.database,1,simu.period);
    ess.index      = 0;
    
    for ess_size = ess.nominates*1000

        ess.index                  = ess.index +1;
        energy.fellow              = (pv.database - demand.profile)*1000; % positive surplus negative shortage.

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
        ess.packVoltage            = ess.cellNomVoltage * ess.seriesCellnum;
        %ess.Qnom                  = ess_size/ess.Voltage; 
             
        for index = 1:length(demand.profile)
            
            demand.energyPv (pv.index, ess.index,index) = min(demand.profile(index),pv.database(index))*1000;
            
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

            if energy.genPred < energy.demPred 

               ess.pvcharge = true;
            else
               ess.pvcharge = false; 
            end

            % Calculation of system state and costs
               %ess.dischargeCost(index) = utl.feedinTrf(index) * ess.roundTripEf * (ess.energy(index) - energy.fellow(index));

            % Machine state selection 
            if energy.fellow(index) > 0    % energy surplus

               if  ess.pvcharge && utl.trf(index) < utl.trfMax/2        %ess.chargeBenefit < utl.feedBenefit
                   machine.state = state.essCharge;
               else
                   machine.state = state.utlExport;                  
               end
               
           elseif energy.fellow(index) < 0 % energy shortage

               if utl.trf(index) > utl.trfMin  %ess.dischargeCost < utl.importCost 
                  machine.state = state.essDischarge;
               else
                  machine.state = state.utlImport;
               end 
           else
                  machine.state = state.initial;
           end
      
            
           % load satisfaction stage:
           switch machine.state

               case state.initial
                
                
               case state.essCharge

                       ess.cellVoltage      = ess.cellvoltageLuT(floor(ess.SoC(index)*100)); 
                       ess.totalCurrent     = energy.fellow(index)/ ess.packVoltage ; %Ah
                       ess.cellCurrent      = ess.totalCurrent / ess.parallelCellNum;  %Ah
        
                    [ess.energy(index),ess.cellFade(index),energy.fellow(index),ess.SoC(index)]= ...
                        battery_update2(index,ess,ess_size,'charge',energy.fellow(index)); 

                    if energy.fellow(index) > 0
                        utl.feedinBill(index) = utl.feedinTrf(index)*energy.fellow(index);
                        energy.fellow(index)  = 0;
                    end

                case state.essDischarge

                    ess.totalCurrent     = energy.fellow(index)/ ess.packVoltage; %Ah
                    ess.cellCurrent      = ess.totalCurrent / ess.parallelCellNum;  %Ah

                    [ess.energy(index),ess.cellFade(index),energy.fellow(index),ess.SoC(index)]= ...
                        battery_update2(index,ess,ess_size,'discharge',energy.fellow(index)); 

                    if energy.fellow(index) < 0
                        utl.smartBill(index) = utl.trf(index)*energy.fellow(index);
                        energy.fellow(index)  = 0;
                    end

                case state.utlImport

                    utl.smartBill(index) = utl.trf(index)*energy.fellow(index);
                    energy.fellow(index)  = 0;    

                case state.utlExport

                    utl.feedinBill(index) = utl.feedinTrf(index)*energy.fellow(index);
                    energy.fellow(index)  = 0;   

                case state.reset
                    print("system reset");
                otherwise
                    print("otherwise");
           end

%             if utl.trf(index) == utl.trfMin
%                 %fully charge battery
%                 dummy.fade = ess.cellFade(index);
%                 [ess.energy(index),ess.cellFade(index),energy.fellow(index),ess.SoC(index)]= ...
%                         battery_update2(index,ess,ess_size,'charge',ess_size*ess.SoC(index));
%                 ess.cellFade(index) = dummy.fade + ess.cellFade(index);
%             end

%             if utl.trf(index) == utl.trfMax
%                 %fully charge battery
%                 dummy.fade = ess.cellFade(index);
%                 [ess.energy(index),ess.cellFade(index),energy.fellow(index),ess.SoC(index)]= ...
%                         battery_update2(index,ess,ess_size,'discharge',ess_size*ess.SoC(index));
%                 ess.cellFade(index) = dummy.fade + ess.cellFade(index);
%             end
% 
%            if  ess.cellFade(index)==1 
%                ess.cellFade(index) = .9;
%            end
           %ess.SoH(index) = ess.SoH(index) - abs(1- ess.cellFade(index));
           ess.SoH(index) = ess.SoH(index) - abs (ess.cellFade(index));

           if index ~= length(demand.profile)

               ess.SoH(index+1)         = ess.SoH(index); 
               ess.SoC(index+1)         = ess.SoC(index);
               utl.smartBillt(index+1)  = utl.smartBillt(index)  + utl.smartBill(index);
               utl.feedinBillt(index+1) = utl.feedinBillt(index) + utl.feedinBill(index);               
           end
           


            % charge battery from grid if the next day pv generation is not
            % enough for load demand. (next day startrs from 0 to 24)
            % best solution for charging the battery durying cheap hours.
% 
%             if index == utl.trfMinInd && chargePermision 
%                 try
%                     if sum(pv.database(index:index+18)) < sum(demand.profile(index:index+18)) 
%                         utl.energy(index) = utl.energy(index) + ...
%                             min ( PB_max ,ess_size - storage_energy(index));
%                         [storage_energy(index),SoH(index)] = battery_update2(storage_energy(index),...
%                             ess_size,ess_size,'charge',PB_max,SOC_min,ess.maxSoC,Qnom,EnergyRouterEf);
%                         chargePermision =  false;
%                         utl.trfMinInd = nan;
%                     end
%                 catch
%                     if sum(pv.database(index:end)) < sum(demand.profile(index:end)) 
%                         utl.energy(index) = utl.energy(index) + ...
%                             min ( PB_max ,ess_size - storage_energy(index));
%                        [storage_energy(index),SoH(index)] = battery_update2(storage_energy(index),...
%                             ess_size,ess_size,'charge',PB_max,SOC_min,ess.maxSoC,Qnom,EnergyRouterEf);
%                         chargePermision =  false;
%                         utl.trfMinInd = nan;
%                     end
%                 end
% 
%             end           
%             if index == utl.trfMaxInd
%                  
%                 utl.energy(index) = utl.energy(index) - storage_energy(index);
%                     %min ( PB_max ,battery_size - battery_charge_capacity(index));
%                 storage_energy(index) = 0; %battery_update2(battery_charge_capacity(index),...
%                     %battery_size,battery_size,'discharge',PB_max,SOC_min);                
%             end
% 
%             % update last battery status for next step.
%             storage_energy(index+1) = storage_energy(index); 
%     
%         end

        end
        % End of 10 years simulation
        ess.SoHt(pv.index,ess.index,:)  = ess.SoH';
        inv.oprCost(pv.index,ess.index) = sum ( abs(utl.smartBill) - utl.feedinBill);  %sum(utl.energy.* utl.trf) ;

       % inv.essPv(pv.index,ess.index)   = ess_size * (inv.ess)/1000 + inv.pv * pv_size; % +PB_max*10;  %1700
       % inv.payback(pv.index,ess.index) = ... 
       %      inv.essPv(pv.index,ess.index) ./ (utl.billtotal - inv.oprCost(pv.index,ess.index)); 
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
plot (ess.SoH)
%sum ( 1- ess.SoH )
sohi=ess.SoH';

% figure 
% plot(pv.database*1000)
% hold on
% plot(demand.profile*1000)
% plot(squeeze(demand.energyPv(1,1,:)))


toc;


