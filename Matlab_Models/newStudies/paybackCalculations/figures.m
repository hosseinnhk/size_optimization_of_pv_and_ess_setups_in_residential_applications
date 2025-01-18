
figure
subplot(2,2,1);
plot(energy_usage_grid(3*7*24:4*7*24))
hold on
plot(pv_generated_energy(3*7*24:4*7*24))
plot (battery_charge_capacity(3*7*24:4*7*24))
plot(load_energy_demand(3*7*24:4*7*24))

subplot(2,2,2);
plot(energy_usage_grid(20*7*24:21*7*24))
hold on
plot(pv_generated_energy(20*7*24:21*7*24))
plot (battery_charge_capacity(20*7*24:21*7*24))
plot(load_energy_demand(20*7*24:21*7*24))

subplot(2,2,3);
plot(energy_usage_grid(35*7*24:36*7*24))
hold on
plot(pv_generated_energy(35*7*24:36*7*24))
plot (battery_charge_capacity(35*7*24:36*7*24))
plot(load_energy_demand(35*7*24:36*7*24))

subplot(2,2,4);
plot(energy_usage_grid(46*7*24:47*7*24))
hold on
plot(pv_generated_energy(46*7*24:47*7*24))
plot (battery_charge_capacity(46*7*24:47*7*24))
plot(load_energy_demand(46*7*24:47*7*24))
