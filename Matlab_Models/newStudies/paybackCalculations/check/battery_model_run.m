function [battery_volt soc_last] = battery_model_run(available_energy,hour_second,current_vector,Temp_vector,soc_last)

        current          = available_energy / 3600*pack_volatge;  % calculating curretn for 1 second  
        current_vector   = current_vector * current;              % creating one hour curretn vector
        current_time     = [hour_second current_vector];          % preparing data for model (1hour)
        Temp             = seasonal_temp(season); 
        Temp_vector      = Temp_vector*Temp;
        Temp_time        = [hour_second Temp_vector]; % preparing data for model (1hour)
        Qe_init          = soc_last;
        sim ( "Ecm_2RC_battery.slx");                 % running the model for 1 hour 
        time_out         = soc_voltage.Time;  
        soc              = soc_voltage.Data(:,1);
        soc_last         = soc(87,1);                 % final soc after energy calculations.
        pack_voltage     = soc_voltage.Data(:,2);
        battery_volt     = pack_voltage(87,1);        % final voltage after energy calculations.
end