function output=battery_update(battery_charge,energy_amount,batterysize,status,power_limitation,minimum_battery_charge)
  
    %2RC battery model
    energy_amount = min(power_limitation,energy_amount);
    
    if strcmpi(status,'charge')

        dummy_value   = battery_charge + energy_amount;
        output        = min(batterysize,dummy_value);

    elseif  strcmpi(status,'discharge') 

        dummy_value   = battery_charge - energy_amount; 
        output        = max(minimum_battery_charge,dummy_value); 
    end
end