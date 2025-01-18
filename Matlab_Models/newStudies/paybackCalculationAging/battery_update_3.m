function [storageEnergy,StateOfHealth,unprocessedEnergy,SoC_final,soC] = battery_update_3(index,Ess,Ess_size,status,energy,Soc)
    
    %energy = min(Ess.PB_max*1000,energy);
   SoC_init             = Ess.SoC(index);
   Ess_size             = Ess_size*Ess.SoH(index); 

   soC.socCharge        = Soc.socCharge(index);
   soC.socDischarge     = Soc.socDischarge(index);
   soC.cycleCharge      = Soc.cycleCharge(index);
   soC.cycleDischarge   = Soc.cycleDischarge(index);

     
    if strcmpi(status,'charge') 

        energy         = Ess.EnergyRouterEf * energy;

        if (Ess.SoC(index) < Ess.maxSoC )
            dummy_value    = (Ess.maxSoC - Ess.SoC(index)) * Ess_size;
        else
            dummy_value  = 0; 
        end
        
        if energy >= dummy_value
            SoC_final = Ess.maxSoC;
            unprocessedEnergy = energy - dummy_value;
        else
            SoC_final = Ess.SoC(index) + energy/Ess_size;
            unprocessedEnergy = 0;
        end

        storageEnergy  = SoC_final * Ess_size;

        soC.socCharge = soC.socCharge + (SoC_final- SoC_init);
        if soC.socCharge >= 1

            soC.cycleCharge = soC.cycleCharge + 1;
            soC.socCharge = 0;
        end 

    elseif  strcmpi(status,'discharge') 

        energy         = energy/Ess.roundTripEf;

        if Ess.SoC(index) > Ess.minSoC
            dummy_value    = (Ess.SoC(index) - Ess.minSoC) * Ess_size;
        else
            dummy_value    = 0;
        end

        if abs(energy) >= dummy_value
            SoC_final = Ess.minSoC;
            unprocessedEnergy = energy + dummy_value;
        else
            SoC_final = Ess.SoC(index) + energy/Ess_size;
            unprocessedEnergy = 0;
        end

        storageEnergy    = SoC_final * Ess_size; 

        soC.socDischarge = soC.socDischarge + (SoC_init - SoC_final);

        if soC.socDischarge >= 1

            soC.cycleDischarge = soC.cycleDischarge + 1;
            soC.socDischarge = 0;
        end

    end

%state of the health calculations:

   
   %if strcmpi(status,'discharge')
       
        finalAh   = Ess.Qnom*(Ess.maxSoC-SoC_final); 
        initialAh = Ess.Qnom*(Ess.maxSoC-SoC_init);

%     elseif strcmpi(status,'charge')
% 
%         initialAh = Ess.Qnom*(Ess.maxSoC-SoC_final); 
%         finalAh   = Ess.Qnom*(Ess.maxSoC-SoC_init);
%    end
    
   if finalAh ~= initialAh

        t_soc = @(ah)  1-ah/Ess.Qnom;    
        deltaAh    = finalAh - initialAh ;  %abs(Ess.cellCurrent);
    
        SoC_avg = (1/deltaAh)*integral(t_soc,initialAh,finalAh);
        dev_soc = @(ah) (1-ah/Ess.Qnom - SoC_avg).^2;
        SoC_dev = (3/deltaAh)*integral(dev_soc,initialAh,finalAh);
        SoC_dev = sqrt(SoC_dev);
    
        %SoC_avg = (1/deltaAh) *( (-(finalAh^2)/(2*Ess.Qnom) + finalAh) - ...
        %                         (-(initialAh^2)/(2*Ess.Qnom) + initialAh) );
        %SoC_dev = (3/deltaAh) * ( ( (finalAh^3/(3 * Ess.Qnom^2)) + finalAh + finalAh*SoC_avg^2 - finalAh^2/Ess.Qnom - 2*SoC_avg*finalAh + (finalAh^2/Ess.Qnom)* SoC_avg )   - ...
        %                          ( (initialAh^3/(3 * Ess.Qnom^2)) + initialAh + initialAh*SoC_avg^2 - initialAh^2/Ess.Qnom - 2*SoC_avg*initialAh + (initialAh^2/Ess.Qnom)* SoC_avg ) );
        %SoC_dev = sqrt(abs(SoC_dev));
        %SoC_avg = abs(SoC_avg);
        zita   = ((Ess.ks1*SoC_dev*exp(Ess.ks2*SoC_avg) + Ess.ks3*exp(Ess.ks4*SoC_dev))*exp((-Ess.Ea/Ess.R)*(1/(Ess.temp+273.15) - 1/(Ess.tempRef+273.15)))) * (finalAh-initialAh); 
        %StateOfHealth = (1 - zita/(0.2 * Ess.Qnom)); %Ess.SoH(index)
        %if index < 65000
            StateOfHealth =  zita; %/(0.2* Ess.Qnom); %Ess.SoH(index).
        %else
            %StateOfHealth = -zita/(0.2* Ess.Qnom) * (1+ index/150000)^2;
        %end
   else
      StateOfHealth = 0;  
   end
   % StateOfHealth = 1;
    %StateOfHealth = -zita/(Ess.Qnom); %Ess.SoH(index)
%* (1.544e7* exp(-40498/(8.3143*(Ess.temp+273.15)))* (index/8760))/100
end