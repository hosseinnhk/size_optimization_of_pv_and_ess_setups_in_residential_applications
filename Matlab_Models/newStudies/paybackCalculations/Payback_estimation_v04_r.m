% Simple scheduling
% calculations for various pv and battery sizes and comparison of payback time and profit during 100 years.

clc
clear
close all;

tic;

load ('PL_Ppv')
load ('cell_data')
PL_max                  = max(PL1);                   % Maximum of load demand during a year.
PB_max                  = 5;                   % Maximum delivarable power exchange with battery.
Inv_PriceB              = 600;                 % Investment cost of battery ($/kWh).
SOC_min                 = 0;                   % Minimum of State of Charge in Battery.
T1                      = 8;                   % Start hour of daily price.
T2                      = 23;                  % Last  hour of daily price.
Day_Price               = 0.150;              % Day   electricity price (Euro/kWh).
Night_Price             = 0.050;              % Night electricity price (Euro/kWh).
day_price               = [ones(1,T1-1)*Night_Price ...
                            ones(1,T2-T1+1)*Day_Price...
                            ones(1,24-T2)*Night_Price];
last_hour_cheap_energy  = (7:24:8719);
year_price              = repmat(day_price,1,364);                % whole year electricity price based on our data samples of load and pv (8736) 
battery_cap_nominates   = linspace(0,10,101);                     % Different battery capacity with the step of 0.1
pv_cap_nominates        = linspace(1,10,10);               
investment_battery_pv   = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for investement on infrastructures
cost_pv_battery         = zeros(length(pv_cap_nominates),length(battery_cap_nominates));   % Vector for summing  operational cost of system considering battery and PV at each battery capacity
load_energy_demand      = (PL_max/max(PL1)).* PL1(1:8736)';                 % Normalize and adjust peak of load demand to PL_max          
vector_size             = size(load_energy_demand);
cost_grid               = sum(load_energy_demand .* year_price);
payback_time            = zeros(length(pv_cap_nominates),length(battery_cap_nominates));
best_battery_size       = zeros(length(pv_cap_nominates));
mininum_paybacktime     = zeros(length(pv_cap_nominates));
profit                  = zeros(length(pv_cap_nominates),length(duration));
duration                = linspace(1,100,100);


for pv_size = pv_cap_nominates

    pv_generated_energy = (pv_size/max(Ppv)).* Ppv'; % Normalize and adjust peak of generated PV to Ppv_max

    for battery_size = battery_cap_nominates
    
        battery_charge_capacity    = zeros((vector_size));
        energy_usage_grid          = zeros((vector_size)); 
        SOC_min                    = 0 * battery_size;
        battery_charge_capacity(1) = SOC_min;
    
        for index = 1:length(load_energy_demand)

            pv_realtime_value   = pv_generated_energy(index);
            load_realtime_value = load_energy_demand(index);
    
            % pv can handle the load demand 
            if pv_realtime_value >= load_realtime_value

                available_energy = pv_realtime_value - load_realtime_value; % kwh

                battery_charge_capacity(index)= ...
                     battery_update(battery_charge_capacity(index),...
                     pv_realtime_value - load_realtime_value,battery_size,'charge',PB_max,SOC_min); 
                
            % pv cann't handle the load demand and we will either battery or grid.
            else  
                load_realtime_value            = load_realtime_value - pv_realtime_value;
                dummy_load_value               = load_realtime_value;                
                load_realtime_value            = ...
                    max ( 0 , load_realtime_value - min(PB_max,battery_charge_capacity(index) - SOC_min));

                energy_usage_grid(index)       = load_realtime_value;
    
                battery_charge_capacity(index) = ...
                     battery_update(battery_charge_capacity(index),...
                     dummy_load_value,battery_size,'discharge',PB_max,SOC_min);
        
            end
            
            % charge battery from grid if the next day pv generation is not
            % enough for load demand. (next day startrs from 8 to 24)
    
            if  ismember(index,last_hour_cheap_energy) 
    
                if sum(pv_generated_energy(index+1:index+16)) < sum(load_energy_demand(index+1:index+16)) 
                    
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
        investment_battery_pv(index_pv,index_battery) = ...
            battery_size * (Inv_PriceB) + 1000 * pv_size; %+PB_max*10 
        payback_time(index_pv,index_battery)          = ...
            investment_battery_pv(index_pv,index_battery) ./ (cost_grid - cost_pv_battery(index_pv,index_battery)); 

    end
     
   
end



for i = 1:length(pv_cap_nominates)

    [mininum_paybacktime(i),best_battery_size(i)] = min(payback_time(i,:));

    for j= 1:length(duration)
        profit(i,j) =  - investment_battery_pv(i,best_battery_size(i)) ...
            + duration(j) * (cost_grid - cost_pv_battery(i,best_battery_size(i)));
    end
end

for i = pv_cap_nominates
    %[mininum_paybacktime,best_battery_size] = min(payback_time(i,:));
    txt = ['pv size=',num2str(i),'kwh'];
    plot (0:0.1:10 , payback_time(i,:),'DisplayName',txt)
    hold on;
    %plot(battery_cap_nominates(location),mininum_paybacktime,'*r')
end

title("payback time calculation cosidering pv and battery variable sizes");
xlabel('battery size (kwh)');
ylabel('pay back time (year)');
legend show;
hold off;
figure; 

for i = pv_cap_nominates 
    txt = ['pv size= ',num2str(i),' kw','       paybacktime= ',num2str(find(profit(i,:) > 0, 1, 'first')),' years'];
    plot(profit(i,:),'DisplayName',txt)
    hold on;
end

legend show;
hold off;
toc;



