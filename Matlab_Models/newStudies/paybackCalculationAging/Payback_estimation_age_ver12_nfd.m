% Simple scheduling
% calculations for various pv and battery sizes and comparison of payback time and inv.profit during 15 years.
% In this version the real price data will added to the system. Prices are
% since 1.1.2022 to 31.12.2022 ( Becuase today is 13.10.2022 the remaining
% days' prices will be mimiced from Aug price calendar). 
% in this version (11) system will run for 20 years with new strategy for
% battery charging and also pb max 5k 10k 15 20 is applied in this version
% prices also will be updated at last step until end of the Oct.

clc
clear
close all;
tic;

load ('PL_Ppv');
load ("elecPriceData1031.mat");

% -------------------------------------------------------------------------End------------------------------------------------------
% Utility trf parameters
% -------------------------------------------------------------------------Utility--------------------------------------------------
utl.database2022     = elecPriceData1031(2:end,:);
utl.database2022     = [utl.database2022 ; utl.database2022(6552:7272,:)];       % Nov 30 *1.1576
utl.database2022     = [utl.database2022 ; utl.database2022(6552:7271,:)];       % Dec 31 *1.215   MWh
utl.trf              = utl.database2022(:,3);
utl.trf(5490,1)      = {750};                           % Removing the outlier data 4000Euro
utl.trf              = table2array(utl.trf);
utl.trf(7298:8016,1) = utl.trf(7298:8016,1)* 1.02;      % adding 2 percent inlflation for next 2 monthes of 2022
utl.trf(8017:8736,1) = utl.trf(8017:8736,1)* 1.03;
utl.trf              = (utl.trf'./1000000);             % Wh
utl.inflationRate    = 1.03;                            % utility price annualy inflation rate
utl.inflation        = ones(length(PL),1);
utl.peakPr           = 1;                               % grid peak periode
utl.offPeakPr        = 2;                               % grid off peak periode
utl.normalPr         = 3;                               % grid normal periode
% -------------------------------------------------------------------------End------------------------------------------------------
%Energy storage system parameters
% -------------------------------------------------------------------------Ess------------------------------------------------------
ess.enR_max             = linspace(2.5,20,8).*1000;                 % Maximum delivarable power exchange with battery. W
ess.nominates           = linspace(1,15,15).*1000;                  % Different battery capacity   5000; 
ess.cellNomVoltage      = 3.3;                 % Cell nominal voltage.
ess.cellvoltageLuT      = 3.3 * ones(1,100);   % Cell voltage look up table base on soc.
ess.enRindex            = 0; 
ess.minsoc              = 0.15;                % Minimum State of Charge in Battery.
ess.maxsoc              = 0.9;                 % Maximum State of Charge in Battery.
ess.soh_nom             = 1;                   % State of health
ess.EoL                 = 0.7;                 % End of life
ess.roundTripEf         = 0.97;                % ess roundtrip efficiency
ess.temp                = 30;                  % ess cell temp centigrad
ess.tempRef             = 22;                  % ambient temp centigrad
ess.Crate               = 1;                   % ess cell c rate Ah
ess.energyRouterEf      = 0.98;                % Energy router efficiency
ess.srCell_nom          = [35,70,70,70,70,70,70,70,70,105,105,105,105,105,105];
ess.prlCell_nom         = [8,8,12,16,20,24,28,33,38,27,30,33,35,38,41];
ess.Ea                  = 78.06;       % k.mol/J
ess.R                   = 8.314;       % j/k.mol
ess.ks1                 = -4.029e-4;   % paper : Practical Capacity Fading Model for Li-Ion Battery Cells in Electric Vehicles
ess.ks2                 = -2.167;
ess.ks3                 = 1.408e-5;
ess.ks4                 = 6.13;
ess.Qnom                = 1.1;         % Ah
ess.pricedecrease       = 0.12;
ess.priceSizedec        = 0.03;
% -------------------------------------------------------------------------End------------------------------------------------------
% PV parameters
% -------------------------------------------------------------------------PV-------------------------------------------------------
pv.nominates            = (1:20) *1000;
pv.index                = 0;
% -------------------------------------------------------------------------End------------------------------------------------------
% Simuulation parameters
% -------------------------------------------------------------------------Simulation-----------------------------------------------
simu.period              = 20;   % year
simu.essSamples          = length(ess.nominates);
simu.pvSamples           = length(pv.nominates);
simu.energyRSamples      = length(ess.enR_max);
simu.hardwareSamples     = [simu.energyRSamples, simu.pvSamples, simu.essSamples];
% -------------------------------------------------------------------------End------------------------------------------------------
% Financial parameters              
% -------------------------------------------------------------------------Financial-----------------------------------------------
inv.ess                 = 750;                 % cost of battery ($/kWh). based on Bloomberg data
inv.pv                  = 1300;                % cost of PV ($/kWp). 
inv.infr                = 250;                 % cost of infrastructures ($/kW)
inv.pvpriceSizedec      = 0.04;
inv.infrpriceSizedec    = 0.04;
inv.infrpriceAnnualdec  = 0.06;
inv.essPv               = zeros((simu.hardwareSamples));               % investement on infrastructures                                                  
inv.linearReturnRatio   = zeros((simu.hardwareSamples));               % payback time calculation
inv.profit              = zeros(simu.energyRSamples,simu.pvSamples,simu.essSamples,simu.period);        % profit calculation
inv.regain              = zeros(simu.energyRSamples,simu.pvSamples,simu.essSamples,simu.period); 
inv.annualInflation     = 0.04;
% -------------------------------------------------------------------------End------------------------------------------------------
% Demand parameters              
% -------------------------------------------------------------------------Demand-----------------------------------------------
demand.max              = 5000;                  % Maximum of load demand during a year. W
demand.grothRate        = 1.01;                  % demand increasing trend 
demand.groth            = ones(length(PL),1);

for i= 2:simu.period
    utl.inflation     = [utl.inflation ; ones(length(PL),1)*(utl.inflationRate^i)];
    demand.groth      = [demand.groth  ; ones(length(PL),1)*(demand.grothRate^i)];
end

demand.profile      = (demand.max/max(PL)).* PL';                 % Normalize and adjust peak of load demand to pwr.Max          
demand.profile      = repmat(demand.profile,1,simu.period);
demand.profile      = demand.profile .* demand.groth';

simu.length          = size(demand.profile);
simu.totalSimSamples = [simu.energyRSamples,simu.pvSamples, simu.essSamples, simu.length(1,2)];

utl.trf              = repmat(utl.trf,1,simu.period);
utl.trf              = utl.trf .* utl.inflation';
utl.feedinTrf        = .8 *utl.trf; %Wh
utl.bill             = zeros((simu.length));
utl.billtotal        = sum(demand.profile.*utl.trf);
utl.netSmartBill     = zeros((simu.hardwareSamples));   % Net smart bill of home   (smart utility bill - feed in bill)

for index = 2:simu.length(1,2)
    utl.bill(index)    = utl.bill(index-1) + demand.profile(index)*utl.trf(index);
end


%calculation of demand response by pv ess utl 
demand.energyPv             = zeros((simu.totalSimSamples));
demand.energyEss            = zeros((simu.totalSimSamples));
demand.energyUtl            = zeros((simu.totalSimSamples));
%demand.energyEssPV          = zeros((simu.totalSimSamples));
supply.energyPVEss          = zeros((simu.totalSimSamples));
supply.energygridEss        = zeros((simu.totalSimSamples));
supply.energyEssgrid        = zeros((simu.totalSimSamples));
supply.energyPVgrid         = zeros((simu.totalSimSamples));
%soc states ??? why we need this parameters???
soc.charge                  = zeros((simu.length));
soc.discharge               = zeros((simu.length));
soc.cycleCharge             = zeros((simu.length));
soc.cycleDischarge          = zeros((simu.length));
dummy.soc.charge            = 0;
dummy.soc.discharge         = 0;
dummy.soc.cycleCharge       = 0;
dummy.soc.cycleDischarge    = 0;

% Final data logging
log.ess.sohtotal            = zeros((simu.totalSimSamples));
log.ess.current             = zeros((simu.totalSimSamples));
log.ess.soctotal            = zeros((simu.totalSimSamples));
log.ess.cycleCharge         = zeros((simu.totalSimSamples));
log.ess.cycleDischarge      = zeros((simu.totalSimSamples));
log.utl.feedinEnergy        = zeros((simu.totalSimSamples));
log.utl.importEnergy        = zeros((simu.totalSimSamples));
log.utl.smartBill           = zeros((simu.totalSimSamples));
log.utl.smartBillTotal      = zeros((simu.totalSimSamples));
log.utl.feedinBill          = zeros((simu.totalSimSamples));
log.utl.feedinTotal         = zeros((simu.totalSimSamples));


  
for Enr_size = ess.enR_max
    
    ess.enRindex = ess.enRindex + 1;    
    ess.enrSize  = Enr_size;
    pv.index     = 0;

    for pv_size = pv.nominates

        pv.index                = pv.index +1;
        pv.database             = (pv_size/max(Ppv)).* Ppv';         % Normalize and adjust peak of generated PV to Ppv_max
        pv.database             = repmat(pv.database,1,simu.period);
        pv.datalog(pv.index,:)  = pv.database;
        ess.index               = 0;
    
        for ess_size = ess.nominates

            ess.replace                = 0;
            ess.cap                    = ess_size;
            ess.index                  = ess.index +1;
            energy.flow                = pv.database - demand.profile; % positive surplus negative shortage. Wh
    
            utl.energy                 = zeros((simu.length)); 
            utl.smartBill              = zeros((simu.length));
            utl.smartBillt             = zeros((simu.length)); 
            utl.feedinBill             = zeros((simu.length));
            utl.feedinBillt            = zeros((simu.length)); 
            
            ess.energy                 = zeros((simu.length));
            ess.energy(1)              = ess.maxsoc* ess.cap;
            ess.soc                    = zeros((simu.length));
            ess.soc(1)                 = ess.maxsoc;        
            ess.soh                    = zeros((simu.length));
            ess.soh(1)                 = ess.soh_nom; 
            ess.current                = zeros((simu.length));
            ess.cellFade               = zeros((simu.length));
            ess.parallelCellNum        = ess.prlCell_nom( ess.index   );    %   ess.nominates/1000
            ess.seriesCellnum          = ess.srCell_nom ( ess.index   );     
            ess.packVoltage            = ess.cellNomVoltage * ess.seriesCellnum; % corrrect it at final version
            dummy.year                 = 0;     

            for index = 1:length(demand.profile)
      
                demand.energyPv(ess.enRindex, pv.index, ess.index,index) = min(demand.profile(index),pv.database(index));                
                dummy.clockTime    = rem(index-1,24); 
                dummy.tillMidnight = 23 - dummy.clockTime;
                energy.genPred     = 0;
                energy.demPred     = 0;
            
                if  dummy.clockTime==0   
                  
                    [utl.trfMin,utl.trfMinInd] = min(utl.trf(index:index+23)); % the lowest utility tariff in the day
                    utl.trfMinInd = utl.trfMinInd + index - 1;
                    [utl.trfMax,utl.trfMaxInd] = max(utl.trf(index:index+23)); % the highest utility tariff in the day
                    utl.trfMaxInd = utl.trfMaxInd + index - 1;
                end

                % Predictions
%                 for stepForward = 1:dummy.tillMidnight
%     
%                     energy.genPred  = energy.genPred + pv.database(index+stepForward); 
%                     energy.demPred  = energy.demPred + demand.profile(index+stepForward);                
%                 end
    
                if  utl.trf(index) >= 0.75 * utl.trfMax && utl.trf(index) <= 1.25 * utl.trfMin
                    utl.state = utl.normalPr;
                elseif utl.trf(index) >= 0.75 * utl.trfMax  
                    utl.state = utl.peakPr;
                elseif utl.trf(index) <= 1.25 * utl.trfMin 
                    utl.state = utl.offPeakPr;
                else 
                    utl.state = utl.normalPr;
                end
    
                switch utl.state
                    case utl.normalPr

                          if energy.flow(index) > 0    % energy surplus
    
                           %if  energy.genPred <= energy.demPred % we should charge battery for the near future
                                dummy.essEnergy = ess.energy(index);
                                [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.soc(index),dummysoc,ess.current(index)]= ...
                                battery_update_7(index,ess,'charge',energy.flow(index),soc);
                                supply.energyPVEss(ess.enRindex, pv.index, ess.index,index) = ess.energy(index) - dummy.essEnergy;
                                energy.flow(index)    = 0;
                                % Still we have some extra pv energy 
%                                 if energy.flow(index) > 0
%                                     log.utl.feedinEnergy(ess.enRindex, pv.index, ess.index,index) = energy.flow(index);
%                                     utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);
%                                     energy.flow(index)    = 0;
%                                 elseif energy.flow(index) < 0
%                                     fprintf("Warning1/n");
%                                 end 
                                 
%                            else
%                                 log.utl.feedinEnergy(ess.enRindex, pv.index, ess.index,index) = energy.flow(index);
%                                 utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);  %usd
%                                 energy.flow(index) = 0; 
               %            end

                         elseif energy.flow(index) < 0  % energy shortage
    
                            if  energy.genPred >= energy.demPred   
    
                                dummy.demandEnergy = abs(energy.flow(index));
                                [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.soc(index),dummy.soc,ess.current(index)]= ...
                                battery_update_7(index,ess,'discharge',energy.flow(index),soc);
                                demand.energyEss(ess.enRindex, pv.index, ess.index,index) = dummy.demandEnergy  - abs(energy.flow(index));
    
                                if demand.energyEss(ess.enRindex,pv.index, ess.index,index)<0
                                     fprintf("Warning2\n");
                                     demand.energyEss(ess.enRindex, pv.index, ess.index,index)
                                     energy.flow(index)
                                end
    
                                if energy.flow(index) < 0
                                    demand.energyUtl(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                                    log.utl.importEnergy(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                                    utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                                    energy.flow(index)   = 0;
                                end  
                           else 
                                demand.energyUtl(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                                log.utl.importEnergy(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                                utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                                energy.flow(index)   = 0;                            
                           end
    
                         else
                            fprintf("energy flow zero\n")
                         end
    
                    case utl.offPeakPr
    
                         if energy.flow(index) > 0    % energy surplus
                            dummy.essEnergy =   ess.energy(index);   
                            [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.soc(index),dummy.soc,ess.current(index)]= ...
                            battery_update_7(index,ess,'charge',energy.flow(index),soc);
                            supply.energyPVEss(ess.enRindex, pv.index, ess.index,index) = ess.energy(index) - dummy.essEnergy;
                            energy.flow(index)    = 0;
                            % Still we have some extra pv energy
%                             if energy.flow(index) > 0
%                                 log.utl.feedinEnergy(ess.enRindex, pv.index, ess.index,index) = energy.flow(index);
%                                 utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);
%                                 energy.flow(index)    = 0;
%                             elseif energy.flow(index) < 0
%                                 fprintf("Warning3/n");                             
%                             end                        
    
                         elseif energy.flow(index) < 0 % energy shortage
    
                            demand.energyUtl(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                            log.utl.importEnergy(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                            utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                            energy.flow(index)   = 0;  
                            
                         else
                            print("energy flow zero")
                         end
    
                         if ess.soc(index) < 0.6 && utl.trf(index) == utl.trfMin   % ess charge from grid
    
                            dummy.essEnergy = ess.energy(index);
                            dummy.cellFade  = ess.cellFade(index); 
    
                            ess.fullCharge  = (ess.maxsoc - ess.soc(index))*ess.cap;
                     
                            [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.soc(index),dummy.soc,ess.current(index)]= ...
                            battery_update_7(index,ess,'charge',ess.fullCharge,soc);
                            supply.energygridEss (ess.enRindex, pv.index, ess.index,index) = (ess.energy(index)-dummy.essEnergy)*1.03;
                            log.utl.importEnergy(ess.enRindex, pv.index, ess.index,index) = ...
                            log.utl.importEnergy(ess.enRindex, pv.index, ess.index,index) + ((ess.energy(index)-dummy.essEnergy)*1.03);   %ess.energy(index) - dummy.essEnergy
                                                                           
                            if ess.energy(index) < dummy.essEnergy
                               fprintf("Warning4/n");  
                            end
    
                            utl.smartBill(index) = utl.smartBill(index) + utl.trf(index)*((ess.energy(index)-dummy.essEnergy)*1.03); %ess.energy(index) - dummy.essEnergy
                            ess.cellFade(index)  = dummy.cellFade  + ess.cellFade(index);
    
                         end                     
    
                    case utl.peakPr
    
                         if energy.flow(index) > 0    % energy surplus
                                [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.soc(index),dummy.soc,ess.current(index)]= ...
                            battery_update_7(index,ess,'charge',energy.flow(index),soc);
                            energy.flow(index)    = 0;
                            
%                              
%                              log.utl.feedinEnergy(ess.enRindex,pv.index, ess.index,index) = energy.flow(index);
%                             utl.feedinBill(index) = utl.feedinTrf(index)*energy.flow(index);
%                             energy.flow(index) = 0; 
    
                         elseif energy.flow(index) < 0 % energy shortage

                            dummy.demandEnergy = abs(energy.flow(index));
  
                            [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.soc(index),dummy.soc,ess.current(index)]= ...
                            battery_update_7(index,ess,'discharge',energy.flow(index),soc);
    
                            demand.energyEss(ess.enRindex, pv.index, ess.index,index) = dummy.demandEnergy - abs(energy.flow(index));
                            
                            if demand.energyEss(ess.enRindex, pv.index, ess.index,index) > ess.enrSize
                               fprintf("need for energy router limit5\n")
                            end  
                            
                            if demand.energyEss(ess.enRindex, pv.index, ess.index,index)<0
                                 fprintf("Warning5\n");
                                 demand.energyEss(ess.enRindex, pv.index, ess.index,index)
                                 energy.flow(index)
                            end     
                
                            if energy.flow(index) < 0  
                                demand.energyUtl(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                                log.utl.importEnergy(ess.enRindex, pv.index, ess.index,index) = -energy.flow(index);
                                utl.smartBill(index) = utl.trf(index)*-energy.flow(index);
                                energy.flow(index)   = 0;
                            end  
                         else
                            print("energy flow zero")
                         end
    
%                          if ess.soc(index) > 0.4 && utl.trf(index) == utl.trfMax   % energy export to grid at max point 
%     
%                             dummy.essEnergy = ess.energy(index);
%                             dummy.cellFade  = ess.cellFade(index);
%     
%                             [ess.energy(index),ess.cellFade(index),energy.flow(index),ess.soc(index),dummy.soc,ess.current(index)]= ...
%                             battery_update_7(index,ess,'discharge',-ess.energy(index),soc);
%                             log.utl.feedinEnergy(ess.enRindex, pv.index, ess.index,index) = log.utl.feedinEnergy(ess.enRindex, pv.index, ess.index,index) + ...
%                                                                           (dummy.essEnergy - ess.energy(index)); 
%                             utl.feedinBill(index) = utl.feedinBill(index) + utl.feedinTrf(index)*(dummy.essEnergy - ess.energy(index));
%                             ess.cellFade(index)  = dummy.cellFade  + ess.cellFade(index);
%     
%                             if ess.energy(index) > dummy.essEnergy
%                                fprintf("Warning6\n");  
%                             end                        
%                          end
    
                    otherwise
                        fprintf("otherwise/n");
               end
    
               ess.soh(index) = 1 - sum(ess.cellFade)/(ess.Qnom);  
    
               %Battery replacement condition 
               if (dummy.year == 10 || ess.soh(index) <= 0.65) && ess.replace==0
    
                   ess.change(ess.enRindex, pv.index, ess.index) = index;
                   ess.replace              = 1;
                   ess.cellFade             = zeros((simu.length));
                   ess.soh(index)           = 1; 
                   ess.soc(index)           = .9;
                   ess.energy(index)        = ess.soc(index) * ess.cap;
                   dummy.soc.charge         = 0;
                   dummy.soc.discharge      = 0;
                   dummy.soc.cycleCharge    = 0;
                   dummy.soc.cycleDischarge = 0;               
               end
    
               
               if index ~= length(demand.profile)
                  
                   ess.soh(index+1)            = ess.soh(index); 
                   ess.soc(index+1)            = ess.soc(index);
                   ess.energy(index+1)         = ess.energy(index);
                   utl.smartBillt(index+1)     = utl.smartBillt(index)  + utl.smartBill(index);
                   utl.feedinBillt(index+1)    = utl.feedinBillt(index) + utl.feedinBill(index);  
                   soc.charge(index+1)         = dummy.soc.charge;
                   soc.discharge(index+1)      = dummy.soc.discharge;
                   soc.cycleCharge(index+1)    = dummy.soc.cycleCharge;
                   soc.cycleDischarge(index+1) = dummy.soc.cycleDischarge;
               end
    
               if rem(index,8736)==0
    
                    dummy.year = dummy.year +1;

                    ess.cost(ess.index) = ess.cap * (inv.ess*(1-ess.priceSizedec)^(ess.cap/1000))/1000;
                    pv.cost (pv.index)  =  (inv.pv*(1-inv.pvpriceSizedec)^(pv_size/1000)) * pv_size/1000;
                    inv.infrCost(ess.enRindex) = (inv.infr*(1-inv.infrpriceSizedec)^(Enr_size/1000))*Enr_size/1000;
                    
                    inv.essPv(ess.enRindex, pv.index,ess.index) =  ...
                    ess.cost(ess.index) + pv.cost (pv.index) + inv.infrCost(ess.enRindex);

                    
                    inv.maintenance(dummy.year) = inv.essPv(ess.enRindex, pv.index,ess.index) * 0.01 * (1+inv.annualInflation)^dummy.year;
    
                    if dummy.year == 10
                        inv.replace(dummy.year) = ess.cost(ess.index)*(1+inv.annualInflation)^dummy.year/(1+ess.pricedecrease)^dummy.year;
                    elseif dummy.year == 15
                        inv.replace(dummy.year) = inv.infrCost(ess.enRindex)*(1+inv.annualInflation)^dummy.year/((1+inv.infrpriceAnnualdec)^dummy.year);  
                    else    
                        inv.replace(dummy.year) = 0;
                    end 
    
                                   
                    inv.profit(ess.enRindex, pv.index,ess.index,dummy.year)  = ...
                        sum (demand.profile(index-8735:index).*utl.trf(index-8735:index)) ...
                        -sum(utl.smartBill(index-8735:index)) ...
                        +sum(utl.feedinBill(index-8735:index));  
    
                    %utl.billYear(dummy.year) = utl.bill(index); 
    
                    inv.regain(ess.enRindex, pv.index,ess.index,dummy.year) = ...
                    -inv.essPv(ess.enRindex, pv.index,ess.index) - sum (inv.maintenance) - sum(inv.replace( 1: dummy.year))...
                    + sum (inv.profit(ess.enRindex, pv.index,ess.index,1:dummy.year));
    
               end
            
            end
    
            % End of x years simulation for each combination of PV_BES
            % system data logging
    
            log.ess.sohtotal(ess.enRindex, pv.index,ess.index,:)            = ess.soh';
            log.ess.soctotal(ess.enRindex, pv.index,ess.index,:)            = ess.soc';
            log.ess.cycleCharge(ess.enRindex, pv.index,ess.index,:)         = soc.cycleCharge';
            log.ess.cycleDischarge(ess.enRindex, pv.index,ess.index,:)      = soc.cycleDischarge';
            log.ess.current(ess.enRindex, pv.index,ess.index,:)             = ess.current';
            log.utl.smartBill(ess.enRindex, pv.index,ess.index,:)           = utl.smartBill';
            log.utl.smartBillTotal(ess.enRindex, pv.index,ess.index,:)      = utl.smartBillt';
            log.utl.feedinBill(ess.enRindex, pv.index,ess.index,:)          = utl.feedinBill';
            log.utl.feedinTotal(ess.enRindex, pv.index,ess.index,:)         = utl.feedinBillt';
                                                                                                  
            utl.netSmartBill(ess.enRindex, pv.index,ess.index)              = sum(abs(utl.smartBill)-utl.feedinBill); %minus means profit
            
            inv.linearReturnRatio(ess.enRindex, pv.index,ess.index) = ... 
            inv.essPv(ess.enRindex, pv.index,ess.index) ./ (utl.billtotal - utl.netSmartBill(ess.enRindex, pv.index,ess.index)); 
            inv.linearReturnRatio(ess.enRindex, pv.index,ess.index) = ...
            inv.linearReturnRatio(ess.enRindex, pv.index,ess.index) ./ simu.period;

            % uncomment if you want to simulate more than one sample.
            soc.charge                  = zeros((simu.length));
            soc.discharge               = zeros((simu.length));
            soc.cycleCharge             = zeros((simu.length));
            soc.cycleDischarge          = zeros((simu.length));
            dummy.soc.charge            = 0;
            dummy.soc.discharge         = 0;
            dummy.soc.cycleCharge       = 0;
            dummy.soc.cycleDischarge    = 0;
    
        end      
    end
end

toc;


