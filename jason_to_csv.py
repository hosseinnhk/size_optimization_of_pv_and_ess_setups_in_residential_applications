import pandas as pd
import numpy as np
import seaborn as sns
import json
import matplotlib.pyplot as plt
import warnings
import matplotlib.patches as mpatches

warnings.filterwarnings('ignore')
pd.set_option('display.max_rows', None)

sns.set_style("whitegrid")
plt.rc('font', family='Times New Roman', size=20)

with open('solar_panel_data2022.json', 'r') as f:
    data = json.load(f)

times = []
powers = []

for entry in data:
    times.append(entry[0])
    powers.append(entry[1])

for i in range(len(times)):
    times[i] = times[i] / 1000

datetime = pd.to_datetime(times, unit='s')
df = pd.DataFrame({'time': datetime, 'power': powers})
df = df.set_index('time')
df = df.resample('5min').asfreq()
df = df.fillna(0)
df = df.loc['1/1/2022':'12/30/2022']
df['date'] = df.index.date
df['time'] = df.index.time
df['date'] = pd.to_datetime(df['date']).dt.date
df['time'] = df['time'].astype(str)
df['datetime'] = pd.to_datetime(df['date'].astype(str) + ' ' + df['time'])
df.drop(columns=['date', 'time'], inplace=True)
df.set_index('datetime', inplace=True)
pv = df
pv.power = pv.power/np.max(pv.power)

print(pv.head())
print(pv.tail())
colors = ['#fc8e0f', '#44af69', '#2b9eb3', '#f8333c']

pv.index = pv.index.map(lambda dt: dt.replace(year=2000))
feb = (pv.index.month == 2) & (pv.index.day == 15)
march = (pv.index.month == 4) & (pv.index.day == 15)
june = (pv.index.month == 6) & (pv.index.day == 15)
oct = (pv.index.month == 10) & (pv.index.day == 15)
month_order = [june, march, oct, feb]
time_labels = pv.loc[feb].index.strftime('%H:%M')
color_cycle = iter(colors)
fig, ax = plt.subplots(figsize=(12, 6))
prev_y = 0
for month in month_order:
    color = next(color_cycle)
    plt.plot(pv.loc[month].power.values*5000, linewidth=2.5, color=color, alpha=0.8)
# plt.fill_between(time_labels, pv.loc[june].power.values*5000, pv.loc[march].power.values*5000,   alpha=0.2, color=colors[0])
# plt.fill_between(time_labels, pv.loc[march].power.values*5000, pv.loc[oct].power.values*5000,  alpha=0.2, color=colors[1])  # '#2b9eb3'
# plt.fill_between(time_labels, pv.loc[oct].power.values*5000, pv.loc[feb].power.values*5000,  alpha=0.2, color=colors[2]) #'#fc8e0f'
# plt.fill_between(time_labels, pv.loc[feb].power.values*5000, 0,  alpha=0.2, color=colors[3]) #

plt.ylabel('Solar Power Generation (W)')
jan_label = mpatches.Patch(color=colors[3], label='February 15, 2020', alpha=0.8)
sep_label = mpatches.Patch(color=colors[2], label='October 15, 2020', alpha=0.8)
march_label = mpatches.Patch(color=colors[1], label='March 15, 2020', alpha=0.8)
june_label = mpatches.Patch(color=colors[0], label='June 15, 2020', alpha=0.8)

plt.legend(handles=[jan_label, march_label, june_label, sep_label], fontsize=17, frameon=False)
# ax.xaxis.grid(False)
ax.xaxis.set_major_locator(plt.MaxNLocator(nbins=len(time_labels)//12))
ax.set_xticklabels(pv.loc[feb].index[::12].strftime('%H:%M'), rotation=45, fontsize=17)
# plt.xticks(range(len(time_labels)), time_labels, rotation=45, fontsize=17)
# ax.grid(False)

ax.spines['bottom'].set_linewidth(1.5)
ax.spines['left'].set_linewidth(1.5)
ax.spines['bottom'].set_color('black')
ax.spines['left'].set_color('black')

sns.despine()
# labels = ax.get_xticklabels()
# plt.setp(labels, x=2, ha='left')
plt.tight_layout()
# plt.xlim(weekly_avg.index.min(), weekly_avg.index[-2])
# plt.xlim(12, 22*12)
# plt.savefig('solar_gen5.svg', format='svg')
plt.show()

# df.to_csv('solarPower_test5.csv')

# weather = pd.read_csv('h_tallinn_2020-01-01_2023-04-20.csv')
# weather['date'] = pd.to_datetime(weather['date'])
# weather['time'] = pd.to_datetime(weather['time'], format='%H:%M:%S').dt.time
# weather = weather.set_index(['date', 'time'])
# weather = weather.drop(columns=['Unnamed: 0'])
# weather = weather.loc['2/1/2021':'1/31/2023']
#
# for i in range(1, 168):
#     solar_power[f'shift_{i}'] = solar_power.power.shift(i).fillna(method='bfill')
# # solar_power.to_csv('solarPower_test6.csv')

# corr = solar_power.corr()
# mask = np.triu(np.ones_like(corr, dtype=bool))
# fig, ax = plt.subplots(figsize=(11, 11))
# sns.heatmap(corr, mask=mask, cbar=True, vmin=-1, vmax=1, fmt='.2f', annot_kws={'size': 3.5},
#             annot=True, square=True, cmap=plt.cm.Blues)
# # print(solar_power.columns)
# plt.tight_layout()
# plt.show()

# fig, ax = plt.subplots(figsize=(3, 30))
# x = corr[['power']]
# sns.heatmap(x, cbar=True, vmin=-1, vmax=1, fmt='.2f', annot_kws={'size': 12, 'rotation': 90},
#             annot=True, square=True, cmap=plt.cm.Blues)
# plt.savefig("corr_half_power.svg", format='svg')
# plt.show()

# correlations = solar_power.corr()['power'].sort_values(ascending=False)
# plt.plot(correlations)
# plt.show()

# print('Most positive Correlations:\n', correlations.head(10))
# print('Most negative Correlations:\n', correlations.tail(10))

# corr_list = []
# for index in correlations.index:
#     if 0.70 < correlations[index]:
#         corr_list.append(index)
# solar_power = solar_power[corr_list]
# power = solar_power['power']
# solar_power = solar_power.drop(['power'], axis=1)
# key = lambda x: int(x.split('_')[-1])
# solar_power = solar_power.reindex(sorted(solar_power.columns, key=key, reverse=False), axis=1)
# solar_power.insert(loc=0, column='power', value=power)
# # solar_power.to_csv('solarPower_test7.csv')
# merged_df = pd.concat([weather, solar_power], axis=1)
# merged_df = merged_df.drop_duplicates()
# # merged_df.to_csv('solarPower_test8.csv')
# solar_pos = pd.read_csv('solar_positional_data.csv')
# solar_pos = solar_pos.reset_index()
# solar_pos['date'] = pd.to_datetime(solar_pos['date'])
# solar_pos['time'] = pd.to_datetime(solar_pos['time'], format='%H:%M:%S').dt.time
# solar_pos = solar_pos.drop('index', axis=1)
# solar_pos = solar_pos.set_index(['date', 'time'])
# sol_pos_df = pd.concat([merged_df, solar_pos], axis=1)
# sol_pos_df.to_csv('solarPower_test9.csv')

# df_2021 = df['2021-01-01':'2021-12-31']
# pw1 = solar_power.loc['2022-01-01']
# pw2 = solar_power.loc['2022-07-04']
# index1 = np.arange(0, max(len(pw1), len(pw2)), step=max(len(pw1), len(pw2)) / len(pw1))
# index2 = np.arange(0, max(len(pw1), len(pw2)), step=max(len(pw1), len(pw2)) / len(pw2))
# pw1 = pw1.set_index(keys=index1)
# pw2 = pw2.set_index(keys=index2)
#
# fig, ax = plt.subplots(dpi=180)
# ax.plot(pw1, label='pw1')
# ax.plot(pw2, label='pw2')
# plt.legend()
# plt.show()
