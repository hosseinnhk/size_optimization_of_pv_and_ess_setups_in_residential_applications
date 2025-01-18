% figure
% subplot(2,2,1)
% yyaxis right
% plot (ess.soc(80000:80100))
% hold on 
% yyaxis left
% plot (ess.current(80000:80100))
% hold off
% subplot(2,2,2)
% plot (ess.soh)
% subplot(2,2,3)
% yyaxis left
% plot(soc.cycleDischarge(1:1000)+soc.cycleCharge(1:1000))
% hold on 
% yyaxis right
% plot(soc.charge(1:1000),'-.','LineWidth',1,'Color','r')
% plot(soc.discharge(1:1000))
% hold off
% subplot(2,2,4)
% plot((soc.cycleDischarge+soc.cycleCharge)/2)
% 
% min(ess.soh)
% max(soc.cycleCharge)
% max(soc.cycleDischarge)
% bar (ess.soc(200:300))



%figure
% for index1 = 1:20
%     for index2 = 1:15
%         plot(squeeze(inv.regain(index1,index2,:)))        
%         hold on
%     end
% end


% figure
% surf (log.utl.feedinTotal(:,:,end))
% hold on
% surf (log.utl.feedinTotal(10,:,:))
% hold on
% surf (log.utl.feedinTotal(19,:,:))

% figure
% grid on
% surf(log.ess.sohtotal(:,:,47300))

%surf(log.ess.cycleCharge(:,:,end))
%grid off
% 
% figure
% 
% z = linspace(5,20,4).*1000;
% x = (1:20) *1000;
% y = linspace(1,15,15).*1000;

%scatter3(z,x,y,log.ess.sohtotal(:,:,:,end))
% for index  =1:4
% surf (squeeze(log.ess.sohtotal(index,:,:,end)))
% %legend show
% hold on
% end

% 
% 
% figure 
% for index = 1:4
% 
% surf (squeeze(inv.payback(index,:,:))*15)
% hold on
% end
% 
% figure 
% surf(inv.essPv)
% 
% figure 
% surf(log.utl.feedinTotal(:,:,end))
% 
% figure 
% surf(log.utl.smartBillTotal(:,:,end))

% 