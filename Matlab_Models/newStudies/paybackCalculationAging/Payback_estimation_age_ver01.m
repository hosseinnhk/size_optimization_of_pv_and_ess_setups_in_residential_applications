% Simple scheduling
% calculations for various pv and battery sizes and comparison of payback time and profit during 100 years.
% In this version the real price data will added to the system. Prices are
% since 1.1.2022 to 31.12.2022 ( Becuase today is 19.08.2022 the remaining
% days' prices will be mimiced from Aug price calendar). 
% in this version (12) system will run for a year with new strategy for
% battery charging. 

clc
clear
close all;

tic;

load ('PL_Ppv');
load ("elecPriceDataBase_ver02.mat");

range = 0:23;
count = 1;
lastEl = size(elecPriceData2022.time(:,1));

%replacing time am pm format by dec numbers. 
while count < lastEl(1,1)
    for i= range 
        elecPriceData2022.time(count + i) = i;        
    end
    count = count + 24 ;
end

% selecting 2022 prices from data base
priceDatabase2022 = elecPriceData2022(17545:end,:);
%priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5089-24:end,:)];    % Aug price is completed 
%priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5089:5808,:)];      % Sep 30 *1.05
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5833-24:6552,:)];    % oct 31 *1.1025 
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5833:6552,:)];       % Nov 30 *1.1576
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5833:6552,:)];       % Dec 30 *1.215

utilityTariff =  priceDatabase2022(:,3);
%priceVec(5491,1) = {750}; %removing the outilier data 4000Euro
utilityTariff = table2array(utilityTariff);

% adding 5 percent inlflation rate for next 3 monthes of 2022
utilityTariff(6553:7296,1) = utilityTariff(6553:7296,1)* 1.05;
utilityTariff(7297:8016,1) = utilityTariff(7297:8016,1)* 1.10;
utilityTariff(8017:8736,1) = utilityTariff(8017:8736,1)* 1.15;




ess.cellNomVoltage      = 3.3;                 % Cell nominal voltage.
PL_max                  = 5;                   % Maximum of load demand during a year. kW
ess.PB_max              = 5;                   % Maximum delivarable power exchange with battery. kW
Inv_PriceB              = 135;                 % Investment cost of battery ($/kWh). based on Bloomberg data
Inv_PricePV             = 1000;                % Investment cost of PV ($/kWp). 
ess.SOC_min             = 0.15;                % Minimum State of Charge in Battery.
ess.SOC_max             = 0.90;                % Maximum State of Charge in Battery.
ess.SoH_nom             = 100;                 % State of health
ess.EoL                 = 70;                  % End of life
ess.RoundTripEf         = 0.97;                % ess roundtrip efficiency
ess.Temp                = 30;                  % ess cell temp
ess.EnergyRouterEf      = 0.98;                % Energy router efficiency
utilityTariff           = (utilityTariff'./1000 );  %repmat(day_price,1,364);  % whole year electricity price based on our data samples of load and pv (8736) 

battery_cap_nominates   = linspace(1,15,15);                     % Different battery capacity with the step of 1 kWh.
ess.seriesCell_nominates    = [35,70,70,70,70,70,70,70,70,105,105,105,105,105,105];
ess.parallelCell_nominates  = [8,8,12,16,20,24,28,33,38,27,30,33,35,38,41];


pv_cap_nominates        = [2,3,4,5,6,7,8,9,10];                % linspace(1,10,10);
investment_battery_pv   = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for investement on infrastructures
cost_pv_battery         = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for summing  operational cost of system considering battery and PV at each battery capacity



% synthesizing data for simulation period 

simulationPeriod        = 10;   % year
utility_inflationRate   = 1.03; % utility price inflation rate
demand_inflationrate    = 1.05; % demand increasing trend during 10 years.

utilityInflationArray         = ones(length(PL),1);
demandInflationArray          = ones(length(PL),1);

for i= 2:simulationPeriod
    utilityInflationArray     = [utilityInflationArray ; ones(length(PL),1)*(utility_inflationRate^i)];
    demandInflationArray      = [demandInflationArray  ; ones(length(PL),1)*(demand_inflationrate^i)];
end

demand_database      = (PL_max/max(PL)).* PL';                 % Normalize and adjust peak of load demand to PL_max          
demand_database      = repmat(demand_database,1,simulationPeriod);
demand_database      = demand_database .* demandInflationArray';

utilityTariff                = repmat(utilityTariff,1,simulationPeriod);
utilityTariff                = utilityTariff .* utilityInflationArray';

% feed in tariff calculation
feedinTarriff         = .8 *utilityTariff;
%feedintarriff         =  feedintarriff/1000;


vector_size             = size(demand_database);

totalBill               = sum(demand_database .* utilityTariff);

payback_time            = zeros(length(pv_cap_nominates),length(battery_cap_nominates));
best_ess_size           = zeros(length(pv_cap_nominates),1);
mininum_paybacktime     = zeros(length(pv_cap_nominates),1);
duration                = linspace(1,50,50);
profit                  = zeros(length(pv_cap_nominates),length(duration));
count                   = 0 ;


% figure;
% plot (priceVec(6553:7296));
% hold on
% plot (feedintarriff(6553:7296));

for pv_size = pv_cap_nominates

    pv_database    = (pv_size/max(Ppv)).* Ppv'; % Normalize and adjust peak of generated PV to Ppv_max
    pv_database    = repmat(pv_database,1,simulationPeriod);
    ess.index      = 0;
    energy_fellow  = (pv_database - demand_database)*1000; % positive surplus negative shortage

    for ess_size = battery_cap_nominates

        ess.index                  = ess.index +1;
        ess.energy                 = zeros((vector_size));
        ess.energy(1)              = ess.SOC_min* ess_size;
        ess.SoH                    = zeros((vector_size));
        ess.SoH(1)                 = ess.SoH_nom;
        energy_usage_grid          = zeros((vector_size)); 
        %ess.SOC_min                = ess.SOC_min * battery_size;     
        ess.parallelCellNum        = ess.parallelCell_nominates(ess.index);
        ess.seriesCellnum          = ess.seriesCell_nominates(ess.index);
        ess.Voltage                = ess.cellNomVoltage * ess.seriesCellnum;
        ess.Qnorm                  = ess_size*1000/ess.Voltage; 
        
        
        for index = 1:length(demand_database)


            ClockTime = rem(index-1,24); % priceDatabase2022.time(index,1)
            timeTillMidnight =   23 - ClockTime;
            energy_production_forecast  = 0;
            energy_consumption_forecast = 0;
        
            if  ClockTime==0   
              
                [tariffMin,tariffminIndex] = min(utilityTariff(index:index+23)); % the chepeaset hour in th next 24hours
                tariffminIndex = tariffminIndex + index - 1;
                %if sum(pv_database(index:index+24)) < sum(demand_database(index:index+24)) 
                %chargePermision = true;
                %end
                [tariffMax,tariffMaxIndex] = max(utilityTariff(index:index+23));
                tariffMaxIndex = tariffMaxIndex + index - 1;
            end
            
            for stepForward = 1:timeTillMidnight
                energy_production_forecast  = energy_production_forecast + pv_database(index); 
                energy_consumption_forecast = energy_consumption_forecast + demand_database(index);                
            end

            
            if energy_fellow > 0 % positive means energy surplus

               if ess.chargeCost > utl.feedBenefit
                 utl.energysell = true;  
                 ess.charge     = false; 
               else
                 utl.energysell = false;  
                 ess.charge     = true;  
               end
               
            elseif energy_fellow < 0 % negative means energy shortage

               if ess.usageCost < utilityUsageCost 
                   ess.discharge = true;
                   utl.energybuy = false;
               else
                   ess.discharge = false;
                   utl.energybuy = true;
               end 
            else
                utl.energybuy  = false;
                utl.energysell = false; 
                ess.discharge  = false;
                ess.charge     = false;
            end

            switch mashineState 
                case ess
            end
            
            
            % load demand satisfaction 
            if energy_production >= energy_consumption               
               surplus_energy     = energy_production - energy_consumption; % wh             
            %else
               shortage_energy    = energy_consumption - energy_production; 
            %end




                % system decides if surplus energy should be delivered to grid or
                % stored in ess.

                utilityTariff(index) 
                feedinTarriff(index)


                ess.totalCurrent     = surplus_energy/ energyStorageVoltage; %Ah
                ess.CellCurrent      = totalCurrent / parallelCellNum;  %Ah
                
                [ess.energy(index),ess.SoH(index)]=...
                    battery_update(index,ess,...
                    surplus_energy,ess_size,'charge'); 

                surplus_energy = 0 ;
                
            % pv cann't handle the load demand and we will either battery or grid.
            else  
                energy_consumption             = energy_consumption - energy_production;
                dummy_load_value               = energy_consumption;
                %if index > 1 && (year_price(index) >= 1.2 * priceMinNextDay)
                energy_consumption            = ...
                    max ( 0 , energy_consumption - min(PB_max,storage_energy(index)-SOC_min));
                energy_usage_grid(index)       = energy_consumption;
                [ess.energy(index),ess.SoH(index)] = ...
                    battery_update(storage_energy(index),...
                    dummy_load_value,ess_size,'discharge',PB_max,SOC_min,SOC_max,Qnorm,EnergyRouterEf);
                %else
                    %energy_usage_grid(index) = energy_consumption;
                %end
        
            end
            
            % charge battery from grid if the next day pv generation is not
            % enough for load demand. (next day startrs from 0 to 24)
            % best solution for charging the battery durying cheap hours.


            if index == tariffminIndex && chargePermision 
                try
                    if sum(pv_database(index:index+18)) < sum(demand_database(index:index+18)) 
                        energy_usage_grid (index) = energy_usage_grid (index) + ...
                            min ( PB_max ,ess_size - storage_energy(index));
                        [storage_energy(index),SoH(index)] = battery_update(storage_energy(index),...
                            ess_size,ess_size,'charge',PB_max,SOC_min,SOC_max,Qnorm,EnergyRouterEf);
                        chargePermision =  false;
                        tariffminIndex = nan;
                    end
                catch
                    if sum(pv_database(index:end)) < sum(demand_database(index:end)) 
                        energy_usage_grid (index) = energy_usage_grid (index) + ...
                            min ( PB_max ,ess_size - storage_energy(index));
                       [storage_energy(index),SoH(index)] = battery_update(storage_energy(index),...
                            ess_size,ess_size,'charge',PB_max,SOC_min,SOC_max,Qnorm,EnergyRouterEf);
                        chargePermision =  false;
                        tariffminIndex = nan;
                    end
                end


            end
            
            if index == tariffMaxIndex
                 
                energy_usage_grid (index) = energy_usage_grid (index) - storage_energy(index);
                    %min ( PB_max ,battery_size - battery_charge_capacity(index));
                storage_energy(index) = 0; %battery_update(battery_charge_capacity(index),...
                    %battery_size,battery_size,'discharge',PB_max,SOC_min);                
            end

            % update last battery status for next step.
            storage_energy(index+1) = storage_energy(index); 
    
        end


    
        index_battery                                 = find(battery_cap_nominates == ess_size);
        index_pv                                      = find(pv_cap_nominates == pv_size);
        cost_pv_battery(index_pv,index_battery)       = sum(energy_usage_grid .* utilityTariff);    
        investment_battery_pv(index_pv,index_battery) = ess_size * (Inv_PriceB) + Inv_PricePV * pv_size; %+PB_max*10  1700
        payback_time(index_pv,index_battery)          = ...
            investment_battery_pv(index_pv,index_battery) ./ (totalBill - cost_pv_battery(index_pv,index_battery)); 

    end
     
   
end

% % Profit calculations
% for i = 1:length(pv_cap_nominates)  
% 
%     [mininum_paybacktime(i),best_battery_size(i)] = min(payback_time(i,:));
% 
%     for j= 1:length(duration)
%         profit(i,j) =  - investment_battery_pv(i,best_battery_size(i)) + duration(j) * (cost_grid - cost_pv_battery(i,best_battery_size(i)));
%     end
% end
% 
% % minimum pay back time best battery size calculation
% for i = pv_cap_nominates
%     j = find(pv_cap_nominates==i);
%     [mininum_paybacktimeS,best_battery_size] = min(payback_time(j,:));
%     txt = ['PV size= ',num2str(i),' kW'];
%     plot (0:0.1:30 , payback_time(j,:),'DisplayName',txt) 
%     %plot (payback_time(j,:),'DisplayName',txt)
%     hold on;
%     plot(best_battery_size/10,mininum_paybacktimeS,'*r','HandleVisibility','off');
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
% for i = pv_cap_nominates 
%     j = find(pv_cap_nominates==i);
%     txt = ['PV size= ',num2str(i),' kW','       Payback time= ', num2str(mininum_paybacktime(j),3),' Years'];  % > 0, 1, 'first')) num2str(profit(j,:))
%     plot(profit(j,:),'DisplayName',txt);
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
% plot(demand_database,'Color',"red");
% title("Energy demand profile");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([0 5.5]);
% hold on;
% 
% subplot(4,1,2);
% plot(pv_database,'Color',"cyan");
% title("Energy generation profile");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([0 5.5]);
% 
% subplot(4,1,3);
% plot(energy_usage_grid,'DisplayName', "Energy exchange with grid");
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
toc;



