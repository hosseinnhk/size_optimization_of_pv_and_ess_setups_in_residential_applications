function [storageEnergy,ess_degration,unprocessedEnergy,SoC_final,soC] = battery_update_4(index,Ess,status,energy,Soc)
    
%     intial_energy = energy;
%     if abs(energy) > Ess.PB_max
%        energy  = abs(energy)*Ess.PB_max/energy;
%     end

   soc_init             = Ess.soc(index);
   Ess_size             = Ess.cap*Ess.soh(index); 

   soC.socCharge        = Soc.socCharge(index);
   soC.socDischarge     = Soc.socDischarge(index);
   soC.cycleCharge      = Soc.cycleCharge(index);
   soC.cycleDischarge   = Soc.cycleDischarge(index);

     
    if strcmpi(status,'charge') 

        energy = Ess.energyRouterEf * energy;


        if Ess.soc(index) < Ess.maxsoc 
            dummy_value    = (Ess.maxsoc - Ess.soc(index)) * Ess_size;
        else
            dummy_value  = 0; 
        end
        
        if energy >= dummy_value
            SoC_final = Ess.maxsoc;
            unprocessedEnergy = energy - dummy_value;
        else
            SoC_final = Ess.soc(index) + energy/Ess_size;
            unprocessedEnergy = 0;
        end

        storageEnergy  = SoC_final * Ess_size;

        soC.socCharge = soC.socCharge + (SoC_final- soc_init);
        if soC.socCharge >= 1

            soC.cycleCharge = soC.cycleCharge + 1;
            soC.socCharge = 0;
        end 

    elseif  strcmpi(status,'discharge') 

        energy = energy/Ess.roundTripEf;

        if Ess.soc(index) > Ess.minsoc
            dummy_value    = (Ess.soc(index) - Ess.minsoc) * Ess_size;
        else
            dummy_value    = 0;
        end

        if abs(energy) >= dummy_value
            SoC_final = Ess.minsoc;
            unprocessedEnergy = energy + dummy_value;
        else
            SoC_final = Ess.soc(index) + energy/Ess_size;
            unprocessedEnergy = 0;
        end

        storageEnergy    = SoC_final * Ess_size; 

        soC.socDischarge = soC.socDischarge + (soc_init - SoC_final);

        if soC.socDischarge >= 1
            soC.cycleDischarge = soC.cycleDischarge + 1;
            soC.socDischarge = 0;
        end

    end

%state of the health calculations:


   finalAh   = SoC_final *Ess_size  / ((3+0.3*SoC_final)*Ess.seriesCellnum*Ess.parallelCellNum);  %Ess.cellvoltageLuT(floor(SoC_final*100)
   initialAh = soc_init  *Ess_size /  ((3+0.3*soc_init)*Ess.seriesCellnum*Ess.parallelCellNum);
   %Ess.current = 

   %finalAh   = Ess.Qnom*SoC_final;%*Ess.SoH(index);  %-Ess.maxSoC-
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