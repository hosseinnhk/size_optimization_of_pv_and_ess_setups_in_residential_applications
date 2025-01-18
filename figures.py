import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import matplotlib.patches as mpatches
import seaborn as sns
sns.set_style("whitegrid")
plt.rc('font', family='Times New Roman', size=20)

df = pd.read_excel('market_price_202122.xlsx', sheet_name='Sheet1')
pv = pd.read_excel('pv_data.xlsx', sheet_name='Sheet1')

df['date'] = pd.to_datetime(df['date']).dt.date
df['time'] = df['time'].astype(str)
df['datetime'] = pd.to_datetime(df['date'].astype(str) + ' ' + df['time'], format="mixed")
df.drop(columns=['date', 'time'], inplace=True)
df.set_index('datetime', inplace=True)

# pv['date'] = pd.to_datetime(pv['date']).dt.date
# pv['time'] = pv['time'].astype(str)
# pv['datetime'] = pd.to_datetime(pv['date'].astype(str) + ' ' + pv['time'])
# pv.drop(columns=['date', 'time'], inplace=True)
# pv.set_index('datetime', inplace=True)

"""Figure 1"""
colors = ['#6A994E', '#3f88c5', '#FC8E0F']
color_cycle = iter(colors)
years_order = [2020, 2021, 2022]
prev_y = 0
fig, ax = plt.subplots(figsize=(12, 6))
for year in years_order:
    df_year = df[df.index.year == year]
    df_year.index = df_year.index.map(lambda dt: dt.replace(year=2000))
    weekly_avg = df_year.resample('5D').mean()
    color = next(color_cycle)
    plt.plot(weekly_avg.index, weekly_avg['Estonia'], label=str(year), linewidth=3, color=color)
    plt.fill_between(weekly_avg.index, weekly_avg['Estonia'], prev_y, alpha=0.2, color=color)
    prev_y = weekly_avg['Estonia'].values


plt.gca().xaxis.set_major_locator(mdates.MonthLocator())
plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%b'))


plt.ylabel('Electricity Market Price (\N{euro sign}/MWh)')
plt.legend()
ax.xaxis.grid(False)
# ax.grid(False)
ax.spines['top'].set_linewidth(2)    # Top border
ax.spines['bottom'].set_linewidth(2) # Bottom border
ax.spines['right'].set_linewidth(2)  # Right border
ax.spines['left'].set_linewidth(2)   # Left border
ax.spines['top'].set_color('black')
ax.spines['bottom'].set_color('black')
ax.spines['right'].set_color('black')
ax.spines['left'].set_color('black')

sns.despine()
labels = ax.get_xticklabels()
plt.setp(labels, x=2, ha='left')
plt.tight_layout()
plt.xlim(weekly_avg.index.min(), weekly_avg.index[-2])
plt.ylim(0, 500)
# plt.savefig('price_trend3.svg', format='svg')
plt.show()

"""Figure 2"""
alpha = 0.7
day_price = df[df.index.year == 2022]
day_price = day_price[day_price.index.month == 8]
day_price = day_price[day_price.index.day == 23]
colors = ['#6A994E' if x < 300 else '#FC8E0F' if x > 600 else '#3f88c5' for x in day_price['Estonia']]
time_labels = day_price.index.strftime('%H:%M')
fig, ax = plt.subplots(figsize=(12, 6))
plt.bar(time_labels, day_price.Estonia, alpha=alpha, color=colors)
# plt.axhspan(0, 300, facecolor='#6A994E', alpha=0.4)
# plt.axhspan(300, 600, facecolor='#3f88c5', alpha=0.4)
# plt.axhspan(600, 800, facecolor='#FC8E0F', alpha=0.4)
plt.ylabel('Electricity Market Price (\N{euro sign}/MWh)')
plt.xticks(time_labels, rotation=45, fontsize=17)
off_peak_patch = mpatches.Patch(color='#6A994E', label='Off-Peak (<300 \N{euro sign}/MWh)', alpha=alpha)
normal_patch = mpatches.Patch(color='#3f88c5', label='Normal (300-600 \N{euro sign}/MWh)', alpha=alpha)
peak_patch = mpatches.Patch(color='#FC8E0F', label='Peak (>600 \N{euro sign}/MWh)', alpha=alpha)
plt.legend(handles=[off_peak_patch, normal_patch, peak_patch], fontsize=17, frameon=False)
plt.xlim(-.5, 23.5)
plt.ylim(0, 800)
ax.xaxis.grid(False)
ax.spines['bottom'].set_linewidth(1.5)
ax.spines['left'].set_linewidth(1.5)
ax.spines['bottom'].set_color('black')
ax.spines['left'].set_color('black')
sns.despine()
plt.tight_layout()
# plt.savefig('daily_price2.svg', format='svg')
plt.show()

"""Figure 3"""
colors = ['#F8333C', '#3f88c5', '#6A994E',  '#FC8E0F']
colors = ['#FAF02D', '#2b9eb3', '#fc8e0f', '#f8333c']    #44af69
colors = ['#FAF02D', '#44af69', '#2b9eb3', '#fc8e0f']
colors = ['#fc8e0f', '#44af69', '#2b9eb3', '#f8333c'] #'#FAF02D',
pv.index = pv.index.map(lambda dt: dt.replace(year=2000))
jan = (pv.index.month == 1) & (pv.index.day == 15)
march = (pv.index.month == 4) & (pv.index.day == 17)
june = (pv.index.month == 6) & (pv.index.day == 15)
sep = (pv.index.month == 9) & (pv.index.day == 15)
days_order = [june, march, sep, jan]
time_labels = pv.loc[jan].index.strftime('%H:%M')
color_cycle = iter(colors)
fig, ax = plt.subplots(figsize=(12, 6))
prev_y = 0
for day in days_order:
    color = next(color_cycle)
    plt.plot(pv.loc[day].pv.values*5000, linewidth=4, color=color, alpha=0.8)
plt.fill_between(time_labels, pv.loc[june].pv.values*5000, pv.loc[march].pv.values*5000,   alpha=0.2, color=colors[0])
plt.fill_between(time_labels, pv.loc[march].pv.values*5000, pv.loc[sep].pv.values*5000,  alpha=0.2, color=colors[1])  # '#2b9eb3'
plt.fill_between(time_labels, pv.loc[sep].pv.values*5000, pv.loc[jan].pv.values*5000,  alpha=0.2, color=colors[2]) #'#fc8e0f'
plt.fill_between(time_labels, pv.loc[jan].pv.values*5000, 0,  alpha=0.2, color=colors[3]) #

plt.ylabel('Solar Energy Generation (Wh)')
jan_label = mpatches.Patch(color=colors[3], label='January 15, 2020', alpha=0.8)
sep_label = mpatches.Patch(color=colors[2], label='September 15, 2020', alpha=0.8)
march_label = mpatches.Patch(color=colors[1], label='March 15, 2020', alpha=0.8)
june_label = mpatches.Patch(color=colors[0], label='June 15, 2020', alpha=0.8)

plt.legend(handles=[jan_label, march_label, june_label, sep_label], fontsize=17, frameon=False)
# ax.xaxis.grid(False)
plt.xticks(range(len(time_labels)), time_labels, rotation=45, fontsize=17)
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
plt.xlim(0, 23)
# plt.savefig('solar_gen5.svg', format='svg')
plt.show()
