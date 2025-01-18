% Simple scheduling
% calculations for various pv and battery sizes and comparison of payback time and profit during 100 years.
% In this version the real price data will added to the system. Prices are
% since 1.1.2022 to 31.12.2022 ( Becuase today is 19.08.2022 the remaining
% days' prices will be mimiced from aug price calendar). 
% in this version (9) system will run for a year with new strategy for
% battery charging. 

clc
clear
close all;

tic;

load ('PL_Ppv');
%load ('cell_data');
load ("elecPriceDataBase.mat");

range = 0:23;
count = 1;
lastEl = size(priceDataBase1.time(:,1));

%replacing time am pm format by dec numbers. 
while count < lastEl(1,1)
    for i= range 
        priceDataBase1.time(count + i) = i;        
    end
    count = count + 24 ;
end

% selecting 2022 prices from data base
priceDatabase2022 = priceDataBase1(17545:end,:);
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5089-24:end,:)];  % Aug price is completed 
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5089:5808,:)];    % Sep 30
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5089-24:5808,:)]; % oct 31
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5089:5808,:)];    % Nov 30
priceDatabase2022 = [priceDatabase2022 ; priceDatabase2022(5089:5808,:)];    % Dec 30

priceVec =  priceDatabase2022(:,3);

%lastmonthtimetable = priceDatabase2022.time(8017:end,1);
%lastmonthprice = priceVec(8017:end,1);


PL_max                  = 5;                   % Maximum of load demand during a year.
PB_max                  = 7;                   % Maximum delivarable power exchange with battery.
Inv_PriceB              = 100; %950;                 % Investment cost of battery ($/kWh).
SOC_min                 = 0;                   % Minimum of State of Charge in Battery.


%T1                      = 8;                   % Start hour of daily price.
%T2                      = 23;                  % Last hour of daily price.
% Day_Price               = 0.3239;              % Day   electricity price (Euro/kWh).
% Night_Price             = 0.2528;              % Night electricity price (Euro/kWh).
% day_price               = [ones(1,T1-1)*Night_Price ...
%                             ones(1,T2-T1+1)*Day_Price...
%                             ones(1,24-T2)*Night_Price];
%last_hour_cheap_energy  = (7:24:8719);
year_price              = (table2array(priceVec)'./1000 ); %repmat(day_price,1,364);  % whole year electricity price based on our data samples of load and pv (8736) 
lastmonthprice          = year_price (1,8017:end);
battery_cap_nominates   = linspace(0,30,301);                     % Different battery capacity with the step of 0.1
pv_cap_nominates        = linspace(1,20,20); %[2,3,4,5,6,7,8,9,10];  %
investment_battery_pv   = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for investement on infrastructures
cost_pv_battery         = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for summing  operational cost of system considering battery and PV at each battery capacity
load_energy_demand      = (PL_max/max(PL)).* PL';                 % Normalize and adjust peak of load demand to PL_max          
%lastMonthDemand         = load_energy_demand(1,8017:end);
vector_size             = size(load_energy_demand);
cost_grid               = sum(load_energy_demand .* year_price);
payback_time            = zeros(length(pv_cap_nominates),length(battery_cap_nominates));
best_battery_size       = zeros(length(pv_cap_nominates),1);
mininum_paybacktime     = zeros(length(pv_cap_nominates),1);
duration                = linspace(1,20,20);
profit                  = zeros(length(pv_cap_nominates),length(duration));
count   = 0 ;

%lastMonthDemand = load_energy_demand(8017:end:end,1);
%vector_size     = size(lastMonthDemand,1);


for pv_size = pv_cap_nominates

    pv_generated_energy = (pv_size/max(Ppv)).* Ppv'; % Normalize and adjust peak of generated PV to Ppv_max
    %lastMonthGeneration = pv_generated_energy; %(1,8017:end);


    for battery_size = battery_cap_nominates
    
        
        battery_charge_capacity    = zeros((vector_size));
        energy_usage_grid          = zeros((vector_size)); 
        SOC_min                    = 0 * battery_size;
        battery_charge_capacity(1) = SOC_min;
    
        for index = 1:length(load_energy_demand)

            pv_realtime_value   = pv_generated_energy(index); %lastMonthGeneration(index); % 
            load_realtime_value = load_energy_demand(index); %lastMonthDemand(index);     
            
            % pv can handle the load demand 
            if pv_realtime_value >= load_realtime_value
                
                % we should provide current data and feed it to simulation
                % to update soc and voltage.
                available_energy = pv_realtime_value - load_realtime_value; % kwh
                battery_charge_capacity(index)=...
                    battery_update(battery_charge_capacity(index),...
                    available_energy,battery_size,'charge',PB_max,SOC_min); 
                available_energy = 0 ;
                
            % pv cann't handle the load demand and we will either battery or grid.
            else  
                load_realtime_value            = load_realtime_value - pv_realtime_value;
                dummy_load_value               = load_realtime_value;
                %if index > 1 && (year_price(index) >= 1.2 * priceMinNextDay)
                load_realtime_value            = ...
                    max ( 0 , load_realtime_value - min(PB_max,battery_charge_capacity(index)-SOC_min));
                energy_usage_grid(index)       = load_realtime_value;
                battery_charge_capacity(index) = ...
                    battery_update(battery_charge_capacity(index),...
                    dummy_load_value,battery_size,'discharge',PB_max,SOC_min);
                %else
                    %energy_usage_grid(index) = load_realtime_value;
                %end
        
            end
            
            % charge battery from grid if the next day pv generation is not
            % enough for load demand. (next day startrs from 8 to 24)
            % best solution for charging the battery durying cheap hours.

            
%             if  priceDatabase2022.time(index,1)==0   
%               
%                 [priceMinNextDay,PriceminIndex] = min(year_price(index:index+23)); % the chepeaset hour in th next 24hours
%                 PriceminIndex = PriceminIndex + index - 1;
%                 %if sum(pv_generated_energy(index:index+24)) < sum(load_energy_demand(index:index+24)) 
%                 chargePermision = true;
%                 %end
%                 [priceMaxNextDay,PriceMaxIndex] = max(year_price(index:index+23));
%                 PriceMaxIndex = PriceMaxIndex + index - 1;
%             end

%             if index == PriceminIndex && chargePermision 
%                 try
%                     if sum(pv_generated_energy(index:index+18)) < sum(load_energy_demand(index:index+18)) 
%                         energy_usage_grid (index) = energy_usage_grid (index) + ...
%                             min ( PB_max ,battery_size - battery_charge_capacity(index));
%                         battery_charge_capacity(index) = battery_update(battery_charge_capacity(index),...
%                             battery_size,battery_size,'charge',PB_max,SOC_min);
%                         chargePermision =  false;
%                         PriceminIndex = nan;
%                     end
%                 catch
%                     if sum(pv_generated_energy(index:end)) < sum(load_energy_demand(index:end)) 
%                         energy_usage_grid (index) = energy_usage_grid (index) + ...
%                             min ( PB_max ,battery_size - battery_charge_capacity(index));
%                         battery_charge_capacity(index) = battery_update(battery_charge_capacity(index),...
%                             battery_size,battery_size,'charge',PB_max,SOC_min);
%                         chargePermision =  false;
%                         PriceminIndex = nan;
%                     end
%                 end
% 
% 
%             end
            
%             if index == PriceMaxIndex
%                  
%                 energy_usage_grid (index) = energy_usage_grid (index) - battery_charge_capacity(index);
%                     %min ( PB_max ,battery_size - battery_charge_capacity(index));
%                 battery_charge_capacity(index) = 0; %battery_update(battery_charge_capacity(index),...
%                     %battery_size,battery_size,'discharge',PB_max,SOC_min);                
%             end

            % update last battery status for next step.
            battery_charge_capacity(index+1) = battery_charge_capacity(index); 
    
        end
    
        index_battery                                 = find(battery_cap_nominates == battery_size);
        index_pv                                      = find(pv_cap_nominates == pv_size);
        cost_pv_battery(index_pv,index_battery)       = sum(energy_usage_grid .* year_price);    
        investment_battery_pv(index_pv,index_battery) = battery_size * (Inv_PriceB) + 1000 * pv_size; %+PB_max*10  1700
        payback_time(index_pv,index_battery)          = ...
            investment_battery_pv(index_pv,index_battery) ./ (cost_grid - cost_pv_battery(index_pv,index_battery)); 

    end
     
   
end



for i = 1:length(pv_cap_nominates)

    [mininum_paybacktime(i),best_battery_size(i)] = min(payback_time(i,:));

    for j= 1:length(duration)
        profit(i,j) =  - investment_battery_pv(i,best_battery_size(i)) + duration(j) * (cost_grid - cost_pv_battery(i,best_battery_size(i)));
    end
end

for i = pv_cap_nominates
    j = find(pv_cap_nominates==i);
    [mininum_paybacktimeS,best_battery_size] = min(payback_time(j,:));
    txt = ['PV size= ',num2str(i),' kW'];
    plot (0:0.1:30 , payback_time(j,:),'DisplayName',txt) 
    %plot (payback_time(j,:),'DisplayName',txt)
    hold on;
    plot(best_battery_size/10,mininum_paybacktimeS,'*r','HandleVisibility','off');
end


title("Payback time calculation cosidering PV and BESS variable sizes");
xlabel('Battery size (kWh)');
ylabel('Payback time (Year)');
legend show;
ax = gca;
exportgraphics(ax,'graph.jpg','Resolution',400)
hold off;


figure; 
for i = pv_cap_nominates 
    j = find(pv_cap_nominates==i);
    txt = ['PV size= ',num2str(i),' kW','       Payback time= ', num2str(mininum_paybacktime(j),3),' Years'];  % > 0, 1, 'first')) num2str(profit(j,:))
    plot(profit(j,:),'DisplayName',txt);
    hold on;
end
legend Location northwest;
legend('FontSize', 7);
legend show;
title("Profits cosidering PV and BESS optimum sizes");
ylabel('Profit (Euro)');
xlabel('Year');
%ylim([0 20000]);
%xlim([0 70]);
ax2 = gca;
exportgraphics(ax2,'graph2.jpg','Resolution',400)
hold off;

% f = figure;
% subplot(4,1,1);
% plot(load_energy_demand,'Color',"red");
% title("Energy demand profile");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([0 5.5]);
% hold on;
% subplot(4,1,2);
% plot(pv_generated_energy,'Color',"cyan");
% title("Energy generation profile");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([0 5.5]);
% 
% subplot(4,1,3);
% plot(energy_usage_grid,'DisplayName', "Energy exchange with grid");
% %plot(battery_charge_capacity,'DisplayName', "BESS available energy amount");
% title("Energy flow of main grid");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([-1 5]);
% 
% subplot(4,1,4);
% plot(battery_charge_capacity,'DisplayName', "BESS available energy amount","Color",'magenta');
% title("Energy flow of BESS");
% ylabel('Energy (kW)',FontSize=6);
% xlabel('Hour',FontSize=6);
% ylim([-2 11]);
% 
% legend show;
% %ax = gca;
% exportgraphics(f,'graph_3.jpg','Resolution',600);
toc;



