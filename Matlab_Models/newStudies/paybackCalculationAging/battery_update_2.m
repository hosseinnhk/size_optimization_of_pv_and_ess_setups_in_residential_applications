function [storageEnergy,StateOfHealth,unprocessedEnergy,SoC] = battery_update2(index,Ess,Ess_size,status,energy)

%[ess.energy(index),ess.SoH(index),energy.fellow(index),ess.SoC]= battery_update(index,ess,ess_size,'discharge',energy.flow(index))

    
    %energy = min(Ess.PB_max*1000,energy);
   SoC_init        = Ess.SoC(index);
   Ess_size        = Ess_size*Ess.SoH(index);   

    if strcmpi(status,'charge')

        energy         = Ess.EnergyRouterEf * energy;
        dummy_value    = (Ess.maxSoC - Ess.SoC(index)) * Ess_size;

        if energy >= dummy_value
            SoC = Ess.maxSoC;
            unprocessedEnergy = energy - dummy_value;
        else
            SoC = Ess.SoC(index) + energy/Ess_size;
            unprocessedEnergy = 0;
        end

        storageEnergy  = SoC * Ess_size;
%        StateOfHealth  = Ess.SoH(index) - 1.1e-5;

    elseif  strcmpi(status,'discharge') 

        energy         = energy/Ess.roundTripEf;
        dummy_value    = (Ess.SoC(index) - Ess.minSoC) * Ess_size;

        if abs(energy) >= dummy_value
            SoC = Ess.minSoC;
            unprocessedEnergy = energy + dummy_value;
        else
            SoC = Ess.SoC(index) + energy/Ess_size;
            unprocessedEnergy = 0;
        end

        storageEnergy  = SoC * Ess_size; 
  %      StateOfHealth  = Ess.SoH(index) - 1.1e-5;
    end
%state of the health calculations:

    SoC_final  = SoC;
    deltaAh    = abs(Ess.cellCurrent);

   if strcmpi(status,'discharge')
        currentAh2 = Ess.Qnom*(1-SoC_final); 
        currentAh1 = Ess.Qnom*(1-SoC_init);
    elseif strcmpi(status,'charge')
        currentAh1 = Ess.Qnom*(1-SoC_final); 
        currentAh2 = Ess.Qnom*(1-SoC_init);
    end

    SoC_avg = (1/deltaAh) *( (-(currentAh2^2)/(2*Ess.Qnom) + currentAh2) - ...
                             (-(currentAh1^2)/(2*Ess.Qnom) + currentAh1) );
    SoC_dev = (3/deltaAh) * ( ( (currentAh2^3/(3 * Ess.Qnom^2)) + currentAh2 + currentAh2*SoC_avg^2 - currentAh2^2/Ess.Qnom - 2*SoC_avg*currentAh2 + (currentAh2^2/Ess.Qnom)* SoC_avg )   - ...
                              ( (currentAh1^3/(3 * Ess.Qnom^2)) + currentAh1 + currentAh1*SoC_avg^2 - currentAh1^2/Ess.Qnom - 2*SoC_avg*currentAh1 + (currentAh1^2/Ess.Qnom)* SoC_avg ) );
    SoC_dev = sqrt(abs(SoC_dev));
    %SoC_avg = abs(SoC_avg);
    zita   = ((Ess.ks1*SoC_dev*exp(Ess.ks2*SoC_avg) + Ess.ks3*exp(Ess.ks4*SoC_dev))*exp((-Ess.Ea/Ess.R)*(1/(Ess.temp) - 1/(Ess.tempRef)))) * (currentAh2-currentAh1); %+273.15
    %StateOfHealth = (1 - zita/(0.2 * Ess.Qnom)); %Ess.SoH(index)
    if index < 65000
    StateOfHealth = -zita/(0.2* Ess.Qnom); %Ess.SoH(index).
    else
    StateOfHealth = -zita/(0.2* Ess.Qnom) * (1+ index/150000)^2;
    end

    %StateOfHealth = -zita/(Ess.Qnom); %Ess.SoH(index)
%* (1.544e7* exp(-40498/(8.3143*(Ess.temp+273.15)))* (index/8760))/100
end