import tushare as ts
import pandas as pd
import matplotlib.pyplot as plt

df = ts.get_hist_data('513030', start='2014-01-01', end='2016-12-08')
df = df[::-1]
with pd.plot_params.use('x_compat', True):
    df.close.plot(color='r', grid='on')

#with pd.plot_params.use('x_compat', True):
#    df.high.plot(color='r', figsize=(10,4), grid='on')
#    df.low.plot(color='b', figsize=(10,4), grid='on')

plt.show()
