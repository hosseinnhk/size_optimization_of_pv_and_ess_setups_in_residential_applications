%discounted pay back calculations:

clc
close all

for index1 = 1:8  
    for index2 = 1:20 
        for index3= 1:15 
            year = 1;
            while inv.regain(index1,index2,index3,year)<0 
                if year ==20
                   paybacktime(index1,index2,index3)  = 21;
                   break
                elseif inv.regain(index1,index2,index3,year+1)>0     
                   slope = inv.regain(index1,index2,index3,year+1) - inv.regain(index1,index2,index3,year);                
                   paybacktime(index1,index2,index3) = (year) - inv.regain(index1,index2,index3,year)/slope; 
                   break
                end
                year = year+1;
            end
        end
    end
end



for pvindex = 1:20
    for batteryindex= 1:15
        [bestpayback(pvindex,batteryindex),ErIndex(pvindex,batteryindex)] = min ( paybacktime(:,pvindex,batteryindex));
%         energyrouertindex(pvindex,batteryindex) = find (paybacktime(:,pvindex,batteryindex) == bestpayback(pvindex,batteryindex) );
%          scatter(energyrouter, paybacktime(energyrouter,1,1))
%          hold on
    end
end

%mesh (bestpayback)


figure
for battery= 1:15
%     y = bestpayback(:,battery);
%     x = 1:20; 
%     f = fit (x',y,'poly2');
%     plot(f)
    plot(bestpayback(:,battery),LineWidth=1.5);
    hold on
end
lgd = legend ("BESS size = 1 kWh",  "BESS size = 2 kWh" , "BESS size = 3 kWh" , "BESS size = 4 kWh",...
    "BESS size = 5 kWh",  "BESS size = 6 kWh" , "BESS size = 7 kWh" , "BESS size = 8 kWh",...
    "BESS size = 9 kWh",  "BESS size = 10 kWh" , "BESS size = 11 kWh" , "BESS size = 12 kWh",...
    "BESS size = 13 kWh",  "BESS size = 14 kWh" , "BESS size = 15 kWh"  ...
    );
lgd.NumColumns = 3;
legend show
hold off

% 
figure 
for pvsize= 1:20

%     y = bestpayback(pv,:);
%     x = 1:15;
%     f = fit (x',y','poly2');
%     plot (f)
    
    plot(bestpayback(pvsize,:),LineWidth=1.5);
    hold on
end
lgd = legend ("PV size = 1 kW",  "PV size = 2 kW" , "PV size = 3 kW" , "PV size = 4 kW",...
    "PV size = 5 kW",  "PV size = 6 kW" , "PV size = 7 kW" , "PV size = 8 kW",...
    "PV size = 9 kW",  "PV size = 10 kW" , "PV size = 11 kW" , "PV size = 12 kW",...
    "PV size = 13 kW",  "PV size = 14 kW" , "PV size = 15 kW" , "PV size = 16 kW",...
    "PV size = 17 kW",  "PV size = 18 kW" , "PV size = 19 kW" , "PV size = 20 kW" ...
    );
lgd.NumColumns = 5;
legend show
hold off

% for pvsize= 1:20
%     [index(pvsize),bestpvbes(pvsize)] = min(bestpayback(pvsize,:));
% end
% 
% bar (bestpvbes)
% for index1 = 1:8
%     for index2= 1:20
%         for index3 = 1:15
%             invessPv(index1,index2,index3) = ess.cap * (inv.ess*(1-ess.priceSizedec)^(ess.cap/1000))/1000 + ...
%             (inv.pv*(1-inv.pvpriceSizedec)^(pv_size/1000)) * pv_size/1000 + ...
%             (inv.infr*(1-inv.infrpriceSizedec)^(Enr_size/1000))*Enr_size/1000;
%         end
%     end
% end
% 
% 
% inv.maintenance(dummy.year) = inv.essPv(ess.enRindex, pv.index,ess.index) * 0.01*(1+inv.annualInflation)^dummy.year;
% 
% if dummy.year == 10
%     inv.replace(dummy.year) = ess.cap*(1+inv.annualInflation)^dummy.year* inv.ess/(1000*(1+ess.pricedecrease)^10);
% elseif dummy.year == 15
%     inv.replace(dummy.year) = inv.infr*Enr_size*(1+inv.annualInflation)^dummy.year/(1000*(1+.05)^15);  
% else    
%     inv.replace(dummy.year) = 0;
% end 
% 
%                
% inv.profit(ess.enRindex, pv.index,ess.index,dummy.year)  = ...
%     sum (demand.profile(index-8735:index).*utl.trf(index-8735:index)) ...
%     -sum(utl.smartBill(index-8735:index)) ...
%     +sum(utl.feedinBill(index-8735:index));  
% 
% %utl.billYear(dummy.year) = utl.bill(index); 
% 
% inv.regain(ess.enRindex, pv.index,ess.index,dummy.year) = ...
% -inv.essPv(ess.enRindex, pv.index,ess.index) - sum (inv.maintenance) - sum(inv.replace( 1: dummy.year))...
% + sum (inv.profit(ess.enRindex, pv.index,ess.index,1:dummy.year));
% inv.payback(ess.enRindex, pv.index,ess.index) = ... 
% inv.essPv(ess.enRindex, pv.index,ess.index) ./ (utl.billtotal - utl.netSmartBill(ess.enRindex, pv.index,ess.index));
% 
% for index1=1:4
%     surf(squeeze(inv.essPv(index1,:,:)))
%     hold on
% end
% 
% 
% for index1 = 1:8 
%     for index2 = 15
%         for index3 = 2
%             scatter3(index1,index2,index3,paybacktime(index1,index2,index3))
%             
%             hold on
%         end
%     end
% end
% 
% 
% for index1 = 1:8
%     for index2 = 15
%         for index3 = 7
%         scatter(paybacktime(index1,index2,index3))
%         hold on 
%         end
%     end
% end
% 
% for i= 1:20
%     plot(bestpayback(i,:));
%     hold on
% end