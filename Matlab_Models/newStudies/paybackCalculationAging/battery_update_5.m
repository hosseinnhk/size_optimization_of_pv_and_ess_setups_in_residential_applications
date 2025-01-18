function [storageEnergy,ess_degration,unprocessedEnergy,socFinal,soc] = battery_update_5(index,Ess,status,energy,Soc)
    
    if energy < 0
       possible_energy = -min(abs(energy),Ess.PB_max);
       
    else
       possible_energy = min(energy,Ess.PB_max); 
    end



   soc_init             = Ess.soc(index);
   Ess_size             = Ess.cap*Ess.soh(index); 

   soc.charge           = Soc.charge(index);
   soc.discharge        = Soc.discharge(index);
   soc.cycleCharge      = Soc.cycleCharge(index);
   soc.cycleDischarge   = Soc.cycleDischarge(index);

     
    if strcmpi(status,'charge') 

        energy = Ess.energyRouterEf * energy;


        if Ess.soc(index) < Ess.maxsoc 
            dummy_value    = (Ess.maxsoc - Ess.soc(index)) * Ess_size;
        else
            dummy_value  = 0; 
        end
        
        if energy >= dummy_value
            socFinal = Ess.maxsoc;
            unprocessedEnergy = energy - dummy_value;
        else
            socFinal = Ess.soc(index) + energy/Ess_size;
            unprocessedEnergy = 0;
        end

        storageEnergy  = socFinal * Ess_size;

        soc.charge = soc.charge + (socFinal- soc_init);
        if soc.charge >= 1

            soc.cycleCharge = soc.cycleCharge + 1;
            soc.charge = 0;
        end 

    elseif  strcmpi(status,'discharge') 

        %energy = energy/Ess.roundTripEf;

        if Ess.soc(index) > Ess.minsoc
            dummy_value    = (Ess.soc(index) - Ess.minsoc) * Ess_size;
            %dummy_value    = dummy_value;
        else
            dummy_value    = 0;
        end

        if abs(energy) >= dummy_value*Ess.roundTripEf
            socFinal = Ess.minsoc;
            unprocessedEnergy = energy + dummy_value*Ess.roundTripEf;
        else
            socFinal = Ess.soc(index) + energy/(Ess_size*Ess.roundTripEf);
            unprocessedEnergy = 0;
        end

        storageEnergy    = socFinal * Ess_size; 

        soc.discharge = soc.discharge + (soc_init - socFinal);

        if soc.discharge >= 1
            soc.cycleDischarge = soc.cycleDischarge + 1;
            soc.discharge = 0;
        end

    end

%state of the health calculations:


   finalAh   = socFinal *Ess_size  / ((3+0.3*socFinal)*Ess.seriesCellnum*Ess.parallelCellNum);  %Ess.cellvoltageLuT(floor(socFinal*100)
   initialAh = soc_init  *Ess_size /  ((3+0.3*soc_init)*Ess.seriesCellnum*Ess.parallelCellNum);
   %Ess.current = 

   %finalAh   = Ess.Qnom*socFinal;%*Ess.SoH(index);  %-Ess.maxSoC-
   %initialAh = Ess.Qnom*soc_init; %*Ess.SoH(index);   %-Ess.maxSoC-

   if finalAh ~= initialAh

        t_soc = @(ah)  1-ah/Ess.Qnom;    
        deltaAh    = finalAh - initialAh ; 
    
        SoC_avg = (1/deltaAh)*integral(t_soc,initialAh,finalAh);
        dev_soc = @(ah) (1-ah/Ess.Qnom - SoC_avg).^2;
        SoC_dev = (3/deltaAh)*integral(dev_soc,initialAh,finalAh);
        SoC_dev = sqrt(SoC_dev);
        if SoC_dev<0 || SoC_avg< 0
            print("minus");
        end
        zita   = ((Ess.ks1*SoC_dev*exp(Ess.ks2*SoC_avg) + Ess.ks3*exp(Ess.ks4*SoC_dev))*exp((-Ess.Ea/Ess.R)*(1/(Ess.temp+273.15) - 1/(Ess.tempRef+273.15)))) * abs(deltaAh); 
        ess_degration =  zita; %/(0.2* Ess.Qnom); %Ess.SoH(index).
   else
        ess_degration = 0;  
   end
end