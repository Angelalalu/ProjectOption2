import numpy as np
from math import exp, log, sqrt
from scipy.stats import norm
from scipy import interpolate
import matplotlib.pyplot as plt
import csv
from scipy.optimize import Bounds
 
### Import Data
strike_price = []
bid = []
with open('spOptions_midpoints_04172018.csv') as csvDataFile:
    csvReader = csv.reader(csvDataFile)
    for row in csvReader:
        strike_price.append(row[1])
        bid.append(row[2])

strike_price_full = np.asarray(strike_price)
strike_price_full = strike_price_full.astype(np.float)
strike_price = strike_price_full[0::2]
bid = np.asarray(bid)
bid = bid.astype(np.float)
bid = bid[0::2]
#print(strike_price)
#print(bid)

### Cubic Spline Interpolation
tck = interpolate.splrep(strike_price, bid)
bid_new = interpolate.splev(strike_price_full, tck, der=0)
plt.plot(strike_price_full,bid_new)
plt.show()
#plt.xlim(2100,2250)

### Optimization Problem
# Bounds
bounds = Bounds(np.zeros([len(strike_price_full),1]))

