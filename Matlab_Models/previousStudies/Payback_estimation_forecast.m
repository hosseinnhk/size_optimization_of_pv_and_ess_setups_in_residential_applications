
clc
clear all

PL_max=5;                         % Maximum of load demand during a year
Ppv_max=3;                        % Maximum of PV generation during a year
PB_max=0.5;                       % Maximum power of the battery during a year. It is limited by power electronics

% Day_Price=0.039251;             % Daily electricity price ($/kWh)
% Night_Price=0.025989;           % Nightly electricity price ($/kWh)
Day_Price               = 0.3239;              % Day   electricity price (Euro/kWh).
Night_Price             = 0.2528;              % Night electricity price (Euro/kWh)
T1=8;                           % Start hour of daily price
T2=23;                          % Last hour of daily price
Price=[ones(1,T1-1)*Night_Price ones(1,T2-T1+1)*Day_Price ones(1,24-T2)*Night_Price];
%COST1=[];                       % Matrix for saving yearly operational cost of system considering PV for each battery capacity
%COST2=[];                       % Matrix for saving yearly operational cost of system considering battery and PV for each battery capacity
%COST3=[];                       % Matrix for saving yearly operational cost of system without battery and PV for each battery capacity
% INV_Cost=[];                % Matrix for saving investment cost of system for each battery capacity
% INV_Cost2=[];
Counter=0;
for CapB=0:0.1:15               % Runin the system for different battery capacity with the step of 0.1
    Counter=Counter+1;          % This is the index of matrices for each battery capacity. If CapB=0:0.1:15, the counter is varied from 1 to 151 to change rows of matrices.
    SOC_min=0;                  % Minimum of State of Charge in Battery
    SOC_max=CapB;               % Maximum of State of Charge in Battery
    %Cycle_Life=500;             % Cycle life of the battery
    CH_C_rate=1;                % The rate at which a battery is being charged or discharged (1/h)
    DCH_C_rate=1;               % Charging and Discharging is same. They can be different.
    Inv_PriceB=100;             % Investment cost of battery ($/kWh)
    Cost1=0;                    % Matrix for summing daily operational cost of system considering PV at each battery capacity
    Cost2=0;                    % Matrix for summing daily operational cost of system considering battery and PV at each battery capacity
    Cost3=0;                    % Matrix for summing daily operational cost of system without battery and PV at each battery capacity
    Memory=SOC_min;             % It is assumed that the battery has the minimum state of charge at the begining of the project. It cannot affect abviously on the results.
    for k=0:363                 % Starting calculating different defined costs of system for each day
        
        load('PL_Ppv')          % Load PV and load demand data
        PL=PL_max/max(PL)*PL(1+24*k:24+24*k);% Normalize and adjust peak of load demand to PL_max at the understudy day
        Ppv=Ppv_max/max(Ppv)*Ppv(1+24*k:24+24*k);% Normalize and adjust peak of generated PV to Ppv_max at the understudy day
        
        SOC(Counter,k+1,1) = Memory; % Battery state of charge at each day is the battery state of charge at the end of previous day.
        My_PL = PL-Ppv;              % Returns 1x24 vector which positive value means that load demand is higher than generated PV and negative value is vice versa.
        % In other words, negative means that extra generation of PV should be stored and positive means that should be met by battery or grid.
        SEDPS=0;                % Sum of Energy Demand at Daily Price for each Section. The first section is at teh start of daily price hour and new sectoin is created if the sign of My_PL is changed.
        I=T1-1;
        Flag=[];
        PVS=0;                  % PV generation at each section.
        while I<T2              % Calculating SEDPS and PVS variables.
            for II=I+1:T2       % Combination of "while" and "for" with "break" can help to create pre-unknown number of sections
                I=II;
                if  sign(My_PL(II)) >= 0
                    SEDPS(end)=SEDPS(end)+My_PL(II);                   
                else
                    Flag = [Flag;I];% To know the hours of PV generation for each section.
                    PVS(end) = PVS(end) - My_PL(II);
                    if Flag(end) ~= T1 && SEDPS(end) == 0 %Eliminate the hour number if there are two consequtive PV generation hours
                        SEDPS(end)=[];
                        Flag(end)=[];
                    elseif SEDPS(end) ~= 0 && size(Flag,1)>1
                        PVS(end)   = PVS(end)+My_PL(II);
                        PVS(end+1) = -My_PL(II);
                    end
                    SEDPS(end+1)=0; 
                    break
                end
            end
        end
        Flag(end+1)=T2;         % The end of flag should be the last hour of daily price
        
        PV2=sum(Ppv(1:T1-1));                  % Calculating extra PV generation at nightly price
        
        
        %Limitation of First-hours Charging for Absorbing PVs
        LimCh=PV2+SOC(Counter,k+1,1);
        if isempty(PVS)~=1
            %     LimCh=[LimCh;LimCh+PV(1)];
            for I=1:length(PVS)
                if PVS(I)>SEDPS(I)
                    LimCh=[LimCh;LimCh+(PVS(I)-SEDPS(I))];
                else
                    LimCh=[LimCh;LimCh];
                end
            end
        end
        
        if SOC_max-LimCh(end)>SOC(Counter,k+1,1)
            % Scheduling the system for the first hour
            PB (Counter,k+1,1) = max(0,min(SOC_max-SOC(Counter,k+1,1)-LimCh(end),CapB*CH_C_rate));
            SOC(Counter,k+1,1) = SOC(Counter,k+1,1)+PB(Counter,k+1,1);
            My_LD(1) = PL(1) + PB(Counter,k+1,1);
            % scheduling the system for nightly price
            for I = 2:T1-1
                PB(Counter,k+1,I) = max(0,min(SOC_max-SOC(Counter,k+1,I-1)-LimCh(end),CapB*CH_C_rate));
                SOC(Counter,k+1,I)= SOC(Counter,k+1,I-1) + PB(Counter,k+1,I);
                My_LD(I)=PL(I)+PB(Counter,k+1,I);
            end
        else

            if SOC(Counter,k+1,1)-(SOC_max-LimCh(end))>PL(1)
                PB(Counter,k+1,1)=-min(min(PL(1),SOC(Counter,k+1,1)),CapB*DCH_C_rate);
                SOC(Counter,k+1,1)=SOC(Counter,k+1,1)+PB(Counter,k+1,1);
                My_LD(1)=PL(1)+PB(Counter,k+1,1);
            else
                PB(Counter,k+1,1)=-min(min(SOC(Counter,k+1,1)-(SOC_max-LimCh(end)),SOC(Counter,k+1,1)),CapB*DCH_C_rate);
                SOC(Counter,k+1,1)=SOC(Counter,k+1,1)+PB(Counter,k+1,1);
                My_LD(1)=PL(1)+PB(Counter,k+1,1);
            end
            I=2;
            while I<8
                if SOC(Counter,k+1,I-1)-(SOC_max-LimCh(end))>PL(I)
                    PB(Counter,k+1,I)=-min(min(PL(I),SOC(Counter,k+1,I-1)),CapB*DCH_C_rate);
                    SOC(Counter,k+1,I)=SOC(Counter,k+1,I-1)+PB(Counter,k+1,I);
                    My_LD(I)=PL(I)+PB(Counter,k+1,I);
                else
                    PB(Counter,k+1,I)=-min(min(SOC(Counter,k+1,I-1)-(SOC_max-LimCh(end)),SOC(Counter,k+1,I-1)),CapB*DCH_C_rate);
                    SOC(Counter,k+1,I)=SOC(Counter,k+1,I-1)+PB(Counter,k+1,I);
                    My_LD(I)=PL(I)+PB(Counter,k+1,I);
                end
                I=I+1;
            end
        end
        
        
        
        
        
        % scheduling the system for daily price
        for I=T1:T2
            if My_PL(I)>0
                PB(Counter,k+1,I)=-min(min(CapB*DCH_C_rate,SOC(Counter,k+1,I-1)),My_PL(I));
                SOC(Counter,k+1,I)=SOC(Counter,k+1,I-1)+PB(Counter,k+1,I);
                My_LD(I)=My_PL(I)+PB(Counter,k+1,I);
            else
                PB(Counter,k+1,I)=min(-My_PL(I),min(CapB*CH_C_rate,SOC_max-SOC(Counter,k+1,I-1)));
                SOC(Counter,k+1,I)=SOC(Counter,k+1,I-1)+PB(Counter,k+1,I);
                My_LD(I)=0;
            end
        end
        
        % scheduling the system for last hours with nightly price
        My_LD(T2+1:24)=PL(T2+1:24);
        SOC(Counter,k+1,T2+1:24)=SOC(Counter,k+1,T2);
        PB(Counter,k+1,T2+1:24)=0;
        
        Memory=SOC(Counter,k+1,24); % Store SOC of last hour to use at the begining hour of next day
        
        My_PL(My_PL<0)=0;
        Cost1=Cost1+sum(Price'.*[PL(1:T1-1);My_PL(T1:T2);PL(T2+1:24)]); %Energy from grid and PV
        Cost2=Cost2+sum(Price.*My_LD); %Energy from grid and PV and Battery
        Cost3=Cost3+sum(Price'.*PL);  %All energy from the grid
        
    end
    
    if Cost1==Cost2
    PaybackB(Counter)=10;%payback if only battery cost is taken into account
    PaybackB2(Counter)=10;
    else 
    PaybackB(Counter)=((Inv_PriceB+PB_max*10)*CapB)./(Cost1-(Cost2-Memory*Price(end)));
    PaybackB2(Counter)=((Inv_PriceB+PB_max*10)*CapB)./(Cost1-(Cost2)); %-Memory*Price(end)
    end
    PaybackAll(Counter)=((Inv_PriceB+PB_max*10)*CapB+1000*Ppv_max)./(Cost3-(Cost2-Memory*Price(end))); %payback if battery and PV cost is taken into account
    
end

figure;plot(0:0.1:15,PaybackB(:))%this is battery only
hold on ;
plot(0:0.1:15,PaybackB2(:))%this is battery only
figure;plot(0:0.1:15,PaybackAll(:)) %full system 

%[a b]=min(INV_Cost./(COST3-COST2));
%PBplot=squeeze(PB(b,:,:))';
%figure;plot(PBplot(:))
%hold on
%SOCplot=squeeze(SOC(b,:,:))';
%plot(SOCplot(:))
%load('PL_Ppv')          % Load PV and load demand data
%PL=PL_max/max(PL)*PL;% Normalize and adjust peak of load demand to PL_max at the understudy day
%Ppv=Ppv_max/max(Ppv)*Ppv;
%hold on;
%plot(Ppv)
%plot(PL)