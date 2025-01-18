%Simple scheduling
clc
clear
close all;

Inv_PriceB=100;             % Investment cost of battery ($/kWh)
PL_max  = 5;                      % Maximum of load demand during a year
Ppv_max = 5;                      % Maximum of PV generation during a year
PB_max  = 3;                    %%%%????? what is pb max?
% Day_Price=0.039251;             % Daily electricity price ($/kWh)
% Night_Price=0.025989;           % Nightly electricity price ($/kWh)
Day_Price               = 0.3239;              % Day   electricity price (Euro/kWh).
Night_Price             = 0.2528;              % Night electricity price (Euro/kWh).
T1=8;                           % Start hour of daily price
T2=23;                          % Last hour of daily price
Price=[ones(1,T1-1)*Night_Price ones(1,T2-T1+1)*Day_Price ones(1,24-T2)*Night_Price];
COST1=[];                       % Matrix for saving yearly operational cost of system considering PV for each battery capacity
COST2=[];                       % Matrix for saving yearly operational cost of system considering battery and PV for each battery capacity
COST3=[];                       % Matrix for saving yearly operational cost of system without battery and PV for each battery capacity
INV_Cost=[];                    % Matrix for saving investment cost of system for each battery capacity
Counter=0;                      
for CapB=3    %% this is not a for loop            % Runin the system for different battery capacity with the step of 0.1
    Counter=Counter+1;          % This is the index of matrices for each battery capacity. If CapB=0:0.1:15, the counter is varied from 1 to 151 to change rows of matrices.
    SOC_min=0;                  % Minimum of State of Charge in Battery
    SOC_max=CapB;               % Maximum of State of Charge in Battery
    CH_C_rate=0;                % The rate at which a battery is being charged or discharged (1/h)
    DCH_C_rate=0;               % Charging and Discharging is same. They can be different.
    Cost1=0;                    % Matrix for summing daily operational cost of system considering PV at each battery capacity
    Cost2=0;                    % Matrix for summing daily operational cost of system considering battery and PV at each battery capacity
    Cost3=0;                    % Matrix for summing daily operational cost of system without battery and PV at each battery capacity
    Memory=SOC_min;             % It is assumed that the battery has the minimum state of charge at the begining of the project. It cannot affect abviously on the results.
    for k=0:363                 % Starting calculating different defined costs of system for each day
        
        load('PL_Ppv')          % Load PV and load demand data
        PL=PL_max/max(PL)*PL(1+24*k:24+24*k);% Normalize and adjust peak of load demand to PL_max at the understudy day
        Ppv=Ppv_max/max(Ppv)*Ppv(1+24*k:24+24*k);% Normalize and adjust peak of generated PV to Ppv_max at the understudy day
       
        My_GRID_without_B=PL-Ppv;           % Returns 1x24 vector which positive value means that load demand is higher than generated PV and negative value is vice versa.
                                % In other words, negative means that extra generation of PV should be stored and positive means that should be met by battery or grid.
      
% Scheduling the system for the first hour
      if My_GRID_without_B(1)>0    
                if Memory>SOC_min   %Discharge  
                PB (Counter,k+1,1) = min(PB_max,My_GRID_without_B(1));
                SOC(Counter,k+1,1) = max(SOC_min, Memory -PB(Counter,k+1,1));
                My_GRID_with_B(1)  = My_GRID_without_B(1)-PB(Counter,k+1,1);
                else
                PB(Counter,k+1,1) = 0;
                SOC(Counter,k+1,1)= SOC_min;
                My_GRID_with_B(1) = My_GRID_without_B(1);
                end
      else              %Charge
                if Memory < SOC_max
                PB(Counter,k+1,1) = max(-PB_max,My_GRID_without_B(1));
                SOC(Counter,k+1,1)= min(SOC_max, Memory-PB(Counter,k+1,1));
                My_GRID_with_B(1) = My_GRID_without_B(1)-PB(Counter,k+1,1);
                My_GRID_with_B(1) = max(0,My_GRID_with_B(1));
                else
                PB(Counter,k+1,1)=0;
                SOC(Counter,k+1,1)=SOC_max;
                My_GRID_with_B(1)=0;
                end
      end
      My_GRID_without_B(1)=max(0,My_GRID_without_B(1));     
      Cost1=Night_Price*PL(1)+Cost1;
      Cost2=Cost2+Night_Price*My_GRID_without_B(1);
      Cost3=Cost3+Night_Price*My_GRID_with_B(1);
                              
% Scheduling the system for catching all the sun!                                              
     for I=2:T2+1
            if My_GRID_without_B(I)>0    %Discharge
                if SOC(Counter,k+1,I-1)>SOC_min
                PB(Counter,k+1,I)=min(PB_max,My_GRID_without_B(I));
                SOC(Counter,k+1,I)=max(SOC_min, SOC(Counter,k+1,I-1)-PB(Counter,k+1,I));
                My_GRID_with_B(I)=My_GRID_without_B(I)-PB(Counter,k+1,I);
                else
                PB(Counter,k+1,I)=0;
                SOC(Counter,k+1,I)=SOC_min;
                My_GRID_with_B(I)=My_GRID_without_B(I);
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
      Cost1=Day_Price*PL(1)+Cost1;
      Cost2=Cost2+Day_Price*My_GRID_without_B(1);
      Cost3=Cost3+Day_Price*My_GRID_with_B(1);
      else 
      Cost1=Night_Price*PL(I)+Cost1;
      Cost2=Cost2+Night_Price*My_GRID_without_B(I);
      Cost3=Cost3+Night_Price*My_GRID_with_B(I);
      end 
     end
 
% Store SOC of last hour to use at the begining hour of next day
       Memory=SOC(Counter,k+1,24);
       


    end
    COST1=[COST1;Cost1];   %%??  how we store every day cost outside of the for loop ???
    COST2=[COST2;Cost2];
    COST3=[COST3;Cost3];
    INV_Cost=[INV_Cost;((Inv_PriceB*CapB)+1000*Ppv_max)];
end
%figure;plot(0:0.1:15,INV_Cost./(COST1-COST3))
%figure;plot(0:0.1:15,INV_Cost./(COST3-COST2))
[a b]=min(INV_Cost./(COST1-COST3));  
PBplot=squeeze(PB(b,:,:))';
%figure;plot(PBplot(:)) %hossein
SOCplot=squeeze(SOC(b,:,:))';
figure;plot(SOCplot(:))
load('PL_Ppv')          % Load PV and load demand data
PL=PL_max/max(PL)*PL;% Normalize and adjust peak of load demand to PL_max at the understudy day
Ppv=Ppv_max/max(Ppv)*Ppv;
hold on;
%figure;
plot(Ppv)
%figure;
plot(PL)
PBplot=squeeze(PB(b,:,:))';
%figure;
plot(PBplot(:))