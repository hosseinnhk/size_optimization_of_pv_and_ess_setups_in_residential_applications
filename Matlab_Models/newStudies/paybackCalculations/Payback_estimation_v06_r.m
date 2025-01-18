% Simple scheduling
% calculations for various pv and battery sizes and comparison of payback time and profit during 100 years.
% In this version the real price data will added to the system. Prices are
% since 1.1.2022 to 31.12.2022 ( Becuase today is 19.08.2022 the remaining
% days' prices will be mimiced from aug price calendar). 



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


PL_max                  = 5;                   % Maximum of load demand during a year.
PB_max                  = 5;                   % Maximum delivarable power exchange with battery.
Inv_PriceB              = 100;                 % Investment cost of battery ($/kWh).
SOC_min                 = 0;                   % Minimum of State of Charge in Battery.


T1                      = 8;                   % Start hour of daily price.
T2                      = 23;                  % Last hour of daily price.
% Day_Price               = 0.3239;              % Day   electricity price (Euro/kWh).
% Night_Price             = 0.2528;              % Night electricity price (Euro/kWh).
% day_price               = [ones(1,T1-1)*Night_Price ...
%                             ones(1,T2-T1+1)*Day_Price...
%                             ones(1,24-T2)*Night_Price];
last_hour_cheap_energy  = (7:24:8719);
year_price              = (table2array(priceVec)'./1000 ); %repmat(day_price,1,364);  % whole year electricity price based on our data samples of load and pv (8736) 

battery_cap_nominates   = linspace(0,30,301);                     % Different battery capacity with the step of 0.1
pv_cap_nominates        = [1,2,3,4,5,6,7,8,9,10];  %linspace(1,10,10);
investment_battery_pv   = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for investement on infrastructures
cost_pv_battery         = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for summing  operational cost of system considering battery and PV at each battery capacity
load_energy_demand      = (PL_max/max(PL)).* PL';                 % Normalize and adjust peak of load demand to PL_max          
vector_size             = size(load_energy_demand);
cost_grid               = sum(load_energy_demand .* year_price);
payback_time            = zeros(length(pv_cap_nominates),length(battery_cap_nominates));
best_battery_size       = zeros(length(pv_cap_nominates),1);
mininum_paybacktime     = zeros(length(pv_cap_nominates),1);
profit                  = zeros(length(pv_cap_nominates),length(duration));
duration                = linspace(1,50,50);
%txt                     = cell(length(pv_cap_nominates),1);
% seasonal_temp           = [20,25,30,35,30,25]';   % ambinet temprature throught a year.
% season                  = 1;
% hour_second             = round( linspace(1,3600,36)');
% current_vector          = ones(36,1);
% Temp_vector             = ones(36,1);
% sim_time                = 3600;
% pack_volatge            = 305;

for pv_size = pv_cap_nominates

    pv_generated_energy = (pv_size/max(Ppv)).* Ppv'; % Normalize and adjust peak of generated PV to Ppv_max

    for battery_size = battery_cap_nominates
    
        battery_charge_capacity    = zeros((vector_size));
        energy_usage_grid          = zeros((vector_size)); 
        SOC_min                    = 0 * battery_size;
        battery_charge_capacity(1) = SOC_min;
    
        for index = 1:length(load_energy_demand)

%             if rem(index,1456) == 0 % deviding a year to 6 sections.
%                 seasone = season + 1;
%             end

            pv_realtime_value   = pv_generated_energy(index);
            load_realtime_value = load_energy_demand(index);
    
            % pv can handle the load demand 
            if pv_realtime_value >= load_realtime_value

                % we should provide current data and feed it to simulation
                % to update soc and voltage.
                available_energy = pv_realtime_value - load_realtime_value; % kwh
                battery_charge_capacity(index)=...
                    battery_update(battery_charge_capacity(index),...
                    pv_realtime_value - load_realtime_value,battery_size,'charge',PB_max,SOC_min); 
                
            % pv cann't handle the load demand and we will either battery or grid.
            else  
    
                load_realtime_value            = load_realtime_value - pv_realtime_value;
                dummy_load_value               = load_realtime_value;
                load_realtime_value            = ...
                    max ( 0 , load_realtime_value - min(PB_max,battery_charge_capacity(index)-SOC_min));
                energy_usage_grid(index)       = load_realtime_value;
                battery_charge_capacity(index) = ...
                    battery_update(battery_charge_capacity(index),...
                    dummy_load_value,battery_size,'discharge',PB_max,SOC_min);
        
            end
            
            % charge battery from grid if the next day pv generation is not
            % enough for load demand. (next day startrs from 8 to 24)
    
            if  year_price(index)*1000 < 250   %ismember(index,last_hour_cheap_energy) 
    
                if index > 8736-24 
                    index = 8736-24;
                end

                if sum(pv_generated_energy(index+1:index+24)) < sum(load_energy_demand(index+1:index+24)) 
                    
                    energy_usage_grid (index) = energy_usage_grid (index) + ...
                        min ( PB_max ,battery_size - battery_charge_capacity(index));
                    battery_charge_capacity(index) = battery_update(battery_charge_capacity(index),...
                        battery_size,battery_size,'charge',PB_max,SOC_min);
    
                end
            end
    
            % update last battery status for next step.
            battery_charge_capacity(index+1) = battery_charge_capacity(index); 
    
        end
    
        index_battery                                 = find(battery_cap_nominates == battery_size);
        index_pv                                      = find(pv_cap_nominates == pv_size);
        cost_pv_battery(index_pv,index_battery)       = sum(energy_usage_grid .* year_price);    
        investment_battery_pv(index_pv,index_battery) = battery_size * (Inv_PriceB) + 1000 * pv_size; %+PB_max*10 
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
    [mininum_paybacktime,best_battery_size] = min(payback_time(j,:));
    txt = ['PV size = ',num2str(i),' kwh'];
    plot (0:0.1:30 , payback_time(j,:),'DisplayName',txt); 
    plot(best_battery_size/10,mininum_paybacktime,'*r','HandleVisibility','off');
    hold on;
end

title("Payback time calculation cosidering PV and battery variable sizes");
xlabel('Battery size (kwh)');
ylabel('Pay back time (year)');
legend show;
hold off;

figure; 
for i = pv_cap_nominates 
    j = find(pv_cap_nominates==i);
    txt1 = ['PV size= ',num2str(i),' kwh','       Paybacktime= ', num2str(find(profit(j,:) > 0, 1 , 'first')),' years'];  % > 0, 1, 'first')) num2str(profit(j,:))
    plot(profit(j,:),'DisplayName',txt1)
    hold on;
end

legend show;
hold off;
toc;



