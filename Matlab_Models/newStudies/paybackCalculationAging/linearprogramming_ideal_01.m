% here a linear programming optimization tries to minimize the cost
% function which only inlcudes grid and feed in tarifs and no degradation
% is considered for pv or battery. we consider forecasting to be ideal.

clc
clear
%close all;

load('PL_Ppv');
load("utility_tarif.mat")

utl.trf = tarif(:,3);
utl.trf(5490,1) = {750}; 
utl.trf = table2array(utl.trf);
utl.trf = (utl.trf'./1000000);   % Wh
utl.feedin = 0.8;

pv.nominates   = 3000;
pv.database    = (pv.nominates/max(Ppv)).* Ppv'; 

demand.max     = 5000;
demand.profile = (demand.max/max(PL)).* PL';

ess.socmax = 0.95;
ess.socmin = 0.15;
ess.cap    = 10000;
ess.soc    = 0.5;
ess.usage  =  0;

pwr.max   = 5000;
pwr.bt_l  = 0;
pwr.g_l   = 0;
pwr.bt_g  = 0;
pwr.pv_g  = 0;
pwr.pv_l  = 0;
pwr.pv_bt = 0;
pwr.g_bt  = 0;

simu.period   = 1;   % year
simu.length   = length(demand.profile)* simu.period;

res.sol    = zeros(simu.length, 7);
res.flag   = zeros(simu.length, 1);
res.cost   = zeros(simu.length, 1);
res.output = {};

for i=1:simu.length 
    f =[0; -utl.trf(i)*utl.feedin; -utl.trf(i)*utl.feedin; 0; 0; utl.trf(i);  utl.trf(i)];        
    b = [5000; 5000; 5000; (ess.soc-ess.socmin)*ess.cap; (ess.socmax-ess.soc)*ess.cap;
        5000; 3000; 5000];
    a = [1 0 0 1 0 1 0;
         0 1 1 0 0 0 0;
         1 1 0 0 0 0 0;
         1 1 0 0 0 0 0;
         0 0 0 0 1 0 1;
         0 0 0 0 1 0 1;
         0 0 1 1 1 0 0;
         0 0 0 0 0 1 1];
    aeq = [0 0 1 1 1 0 0;
           1 0 0 1 0 1 0];
    beq = [pv.database(i);demand.profile(i)];
    lb = zeros(1,length(f));
    ub = [5000; 5000; 3000; 3000; 3000; 5000; 5000];
    x0 = [];
    i
    options= optimoptions('linprog','Display','iter');
    [sol,fval,exitflag,output] = linprog(f,a,b,aeq,beq,lb,ub,x0,options);
    res.sol(i,:) = sol;
    res.sol(i,:)
    res.cost(i,1) = fval;
    res.flag(i,1) = exitflag;
    res.output = [res.output output];
    ess.usage = ess.soc*ess.cap - res.sol(i,1) - res.sol(i,2) + res.sol(i,5) + res.sol(i,7);
    ess.soc = ess.soc - ess.usage/ess.cap;
    ess.soc
end





