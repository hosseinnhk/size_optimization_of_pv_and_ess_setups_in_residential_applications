%Simple scheduling
clc;
clear all;
close all;
tic;
load('PL_Ppv');

PL_max  = max(PL1);                    % Maximum of load demand during a year
Ppv_max = 10;                    % Maximum of PV generation during a year
PB_max  = 5;                    % Maximum power of the battery during a year. It is limited by power electronics

Day_Price   = 0.039251;         % Daily electricity price ($/kWh)
Night_Price = 0.025989;         % Nightly electricity price ($/kWh)
Inv_PriceB  = 100;              % Investment cost of battery ($/kWh)
T1=8;                           % Start hour of daily price
T2=23;                          % Last hour of daily price
Price=[ones(1,T1-1)*Night_Price ...
       ones(1,T2-T1+1)*Day_Price...
       ones(1,24-T2)*Night_Price];

Counter=0;                      % this is a pointer of the battery size
for CapB=0:0.1:15               % Runin the system for different battery capacity with the step of 0.1
    Counter=Counter+1;          % This is the index of matrices for each battery capacity. If CapB=0:0.1:15, the counter is varied from 1 to 151 to change rows of matrices.
    SOC_min=0;                  % Minimum of State of Charge in Battery
    SOC_max=CapB;               % Maximum of State of Charge in Battery
    CH_C_rate=1;                % The rate at which a battery is being charged or discharged (1/h)
    DCH_C_rate=1;               % Charging and Discharging is same. They can be different.
    Cost1=0;                    % Vector for summing daily operational cost of system considering PV at each battery capacity
    Cost2=0;                    % Matrix for summing daily operational cost of system considering battery and PV at each battery capacity
    Cost3=0;                    % Matrix for summing daily operational cost of system without battery and PV at each battery capacity
    Memory=SOC_min;             % It is assumed that the battery has the minimum state of charge at the begining of the project. It cannot affect abviously on the results.
    for k = 0:363      %% 0 or 1 ?           % Starting calculating different defined costs of system for each day
        
        load('PL_Ppv')          % Load PV and load demand data
        PL  = PL_max/max(PL1)*PL1(1+24*k:24+24*k);% Normalize and adjust peak of load demand to PL_max at the understudy day
        Ppv = Ppv_max/max(Ppv)*Ppv(1+24*k:24+24*k);% Normalize and adjust peak of generated PV to Ppv_max at the understudy day
       
        My_GRID_without_B=PL-Ppv;           % Returns 1x24 vector which positive value means that load demand is higher than generated PV and negative value is vice versa.
                                % In other words, negative means that extra generation of PV should be stored and positive means that should be met by battery or grid.
      
% Scheduling the system for the first hour taking into account initial SOC
% which defines by previous day and is saved in veriable Memory
      if My_GRID_without_B(1)>0    %Discharge
                if Memory>SOC_min  %cheking if battery is not discharged   ??? PB_max or Memory
                PB(Counter,k+1,1)=min(PB_max,My_GRID_without_B(1)); %we set the power from bettery in order to companste lack of power from PV but taking into account maximum power from battery
                My_GRID_with_B(1)=My_GRID_without_B(1)-PB(Counter,k+1,1);% and now we calculate final power value that will be consumed from the grid 
                SOC(Counter,k+1,1)=max(SOC_min, Memory-PB(Counter,k+1,1));%estimation of the next SOC and simple chek that battery is not discharged
                My_GRID_with_B(1)=max(0,My_GRID_with_B(1));
                else %it means that battery is discharged 
                PB(Counter,k+1,1)=0; %and power from battery is zero if battery is discharge 
                SOC(Counter,k+1,1)=SOC_min;
                My_GRID_with_B(1)=My_GRID_without_B(1);%and power that we consume from the grid is the same as we consume without battery 
                My_GRID_with_B(1)=max(0,My_GRID_with_B(1));
                end
      else              %Charge
                if Memory<SOC_max %cheking if battery is not overcharged
                PB(Counter,k+1,1)=max(-PB_max,My_GRID_without_B(1)); %we set the power from bettery in order to save surplus power from PV but taking into account maximum power battery
                My_GRID_with_B(1)=My_GRID_without_B(1)-PB(Counter,k+1,1); % and now we calculate final power value that will be consumed from the grid 
                My_GRID_with_B(1)=max(0,My_GRID_with_B(1)); % this is always zero??? % abut we need to take into account that it can be only positive, which means that we can not sell energy to the grid
                SOC(Counter,k+1,1)=min(SOC_max, Memory-PB(Counter,k+1,1));% estimation of the next SOC and simple chek that battery is not overcharged
                else
                PB(Counter,k+1,1)=0; 
                SOC(Counter,k+1,1)=SOC_max;
                My_GRID_with_B(1)=0;
                end                
      end
      My_GRID_without_B(1)=max(0,My_GRID_without_B(1)); % we need to take into account that power from grid can be only positive, which means that we can not sell energy to the grid, even if battery is absent
      
      Cost1=Cost1+Night_Price*PL(1); % this is energy cost from the grid that we would need to pay in order to cover our load demends without PV and battery 
      Cost2=Cost2+Night_Price*My_GRID_without_B(1); % this is energy cost from the grid that we would need to pay in order to cover our load demends with PV but without battery
      Cost3=Cost3+Night_Price*My_GRID_with_B(1); % this is energy cost from the grid that we would need to pay in order to cover our load demends with PV and with battery (the lowest)
                               
% Scheduling the system for catching all the sun!  
% The algorihm is the same as above with only difference that we consider night or day for cost calculation!
     for I=2:T2+1
            if My_GRID_without_B(I)>0    %Discharge
                if SOC(Counter,k+1,I-1)>SOC_min
                PB(Counter,k+1,I)=min(PB_max,My_GRID_without_B(I)); %??? SOC ???
                SOC(Counter,k+1,I)=max(SOC_min, SOC(Counter,k+1,I-1)-PB(Counter,k+1,I));
                My_GRID_with_B(I)=My_GRID_without_B(I)-PB(Counter,k+1,I);
                My_GRID_with_B(I)=max(0,My_GRID_with_B(I));
                else
                PB(Counter,k+1,I)=0;
                SOC(Counter,k+1,I)=SOC_min;
                My_GRID_with_B(I)=My_GRID_without_B(I);
                My_GRID_with_B(I)=max(0,My_GRID_with_B(I));
                end
            else              %Charge
                if SOC(Counter,k+1,I-1)<SOC_max
                PB(Counter,k+1,I)=max(-PB_max,My_GRID_without_B(I));
                SOC(Counter,k+1,I)=min(SOC_max, SOC(Counter,k+1,I-1)-PB(Counter,k+1,I));
                My_GRID_with_B(I)=My_GRID_without_B(I)-PB(Counter,k+1,I);
                My_GRID_with_B(I)=max(0,My_GRID_with_B(I));
                else
                PB(Counter,k+1,I)=0;
                SOC(Counter,k+1,I)=SOC_max;
                My_GRID_with_B(I)=0;
                end
             end
     
      My_GRID_without_B(I)=max(0,My_GRID_without_B(I));     
      if (I>T1-1)
      Cost1=Cost1+Day_Price*PL(I);
      Cost2=Cost2+Day_Price*My_GRID_without_B(I);
      Cost3=Cost3+Day_Price*My_GRID_with_B(I);
      else 
      Cost1=Night_Price*PL(I)+Cost1;
      Cost2=Cost2+Night_Price*My_GRID_without_B(I);
      Cost3=Cost3+Night_Price*My_GRID_with_B(I);
      end
     end
     costiii(Counter) = Cost3;
     Memory=SOC(Counter,k+1,24); %this is SOC at the end of the day, which will be used as starting point during next day
      
     
    end
    
    %INV_Cost(Counter)=((Inv_PriceB+PB_max*10)*CapB)+1000*Ppv_max;  %this is investment for the full system
    %INV_Cost2(Counter)=((Inv_PriceB+PB_max*10)*CapB); %this is investment for the battery only
    
    if Cost2==Cost3
    PaybackB(Counter)=10; %payback if only battery cost is taken into account
    else 
    PaybackB(Counter)=(Inv_PriceB*CapB)./(Cost2-Cost3);
    end
    
     PaybackAll(Counter)=(Inv_PriceB*CapB+1000*Ppv_max)./(Cost1-Cost3); %payback if battery and PV cost is taken into account
     
end
figure;plot(0:0.1:15,PaybackB(:))%this is battery only
figure;plot(0:0.1:15,PaybackAll(:)) %full system 
min(PaybackAll)
toc;
%[a b]=min(INV_Cost./(COST3-COST2));
%PBplot=squeeze(PB(b,:,:))';
%figure;plot(PBplot(:))
%SOCplot=squeeze(SOC(b,:,:))';
%figure;plot(SOCplot(:))
%load('PL_Ppv')          % Load PV and load demand data
%PL=PL_max/max(PL)*PL;% Normalize and adjust peak of load demand to PL_max at the understudy day
%Ppv=Ppv_max/max(Ppv)*Ppv;
%hold on;
%plot(Ppv)
%plot(PL)
%PBplot=squeeze(PB(b,:,:))';
%plot(PBplot(:))(:))