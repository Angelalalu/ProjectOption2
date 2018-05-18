import numpy as np
from math import exp, log, sqrt
from scipy.stats import norm
from scipy import interpolate
import matplotlib.pyplot as plt
import csv
from scipy.optimize import Bounds
from scipy.optimize import minimize
from scipy.optimize import show_options
import copy
 
### Import Data
print(1)
strike_price = []
bid = []
with open('spOptions_midpoints_04172018.csv') as csvDataFile:
    csvReader = csv.reader(csvDataFile)
    for row in csvReader:
        strike_price.append(row[1])
        bid.append(row[2])

print(2)
strike_price_full = np.asarray(strike_price)
strike_price_full = strike_price_full.astype(np.float)
strike_price = strike_price_full[0::2]
bid = np.asarray(bid)
bid = bid.astype(np.float)
bid = bid[0::2]
#print(strike_price)
#print(bid)
print(3)
### Cubic Spline Interpolation
tck = interpolate.splrep(strike_price, bid)
bid_new = interpolate.splev(strike_price_full, tck, der=0)
plt.plot(strike_price_full,bid_new)
# plt.show()
print(4)
#plt.xlim(2100,2250)

### Optimization Problem
# Bounds
bounds = Bounds(np.zeros([len(strike_price_full),1]), np.full([len(strike_price_full),1], np.inf))
print(bounds)

from scipy.optimize import LinearConstraint
deltaK = strike_price_full[1:] - strike_price_full[0:-1]

print(len(strike_price_full))

A1 = -np.diag(np.ones([1, len(strike_price_full)]).tolist()[0]) + np.diag(np.ones([1, len(strike_price_full) - 1]).tolist()[0], 1)
print(A1.shape)
A1 = A1[:-1, :]
print(A1.shape)

b1 = np.zeros([len(strike_price_full) - 1, 1])
print(b1.shape)

# print(strike_price_full)
print(np.append(deltaK, [0, 0]))

A2 = np.diag(np.append(deltaK, [0, 0])) - np.diag(np.append(deltaK, 0), 1) - np.diag(np.append(0, deltaK), 1) + np.diag(np.append(0, deltaK[:-1]), 2)
print(A2.shape)
A2 = -A2[1:-2, 1:]
print(A2.shape)

b2 = np.zeros([len(strike_price_full) - 2, 1])
print("=" * 20)
print(A1.shape)
print(A2.shape)
A = np.concatenate((A1, A2))
print(b1.shape)
print(b2.shape)
b = np.concatenate((b1, b2))

print(A.shape)
print(b.shape)

ineqLeft = np.full([len(b), 1], -np.inf)
print(ineqLeft.shape)

linear_constraint = LinearConstraint(A, ineqLeft, b)

a = np.array([1, 2, 3, 4, 5])
print(a[:-(5-3)])
print(a[:-(5-4)])
print(a[:-(5-5)])

def CalculateDerivativesWithXandDeltaK(x, deltaK, order):
    for currentOrder in range(order):
        deltaK_avg = np.zeros(len(x) - 1)
        if currentOrder == 0:
            deltaK_avg = deltaK
        else:
            for i in range(currentOrder + 1):
                if currentOrder - i > 0:
                    deltaK_avg = deltaK_avg + deltaK[i:-(currentOrder - i)]
                else:
                    deltaK_avg = deltaK_avg + deltaK[i:]

        deltaK_avg = deltaK_avg / (currentOrder + 1)
        xd = (x[1:] - x[:-1]) / deltaK_avg
        x = copy.deepcopy(xd)

    return xd

print(CalculateDerivativesWithXandDeltaK(strike_price_full, deltaK, 1))
print(CalculateDerivativesWithXandDeltaK(strike_price_full, deltaK, 2))

print("-" * 20)
print(a)
print(abs(a) ** 1.2)
tmp = np.zeros(5)
print(tmp)
print(tmp.shape)
print(deltaK.shape)

def ObjectiveFunction(x):
    xd = CalculateDerivativesWithXandDeltaK(x, deltaK, 3)
    return sum(abs(xd) ** 1.2)

print(ObjectiveFunction(strike_price_full))

show_options('minimize', 'Nelder-Mead')
optOptions = {'maxiter': 1e8,
              'disp': True,
              'xatol': 1e-8,
              'fatol': 1e-8
              }
print(optOptions)
xOpt = minimize(ObjectiveFunction, bid_new, method='Nelder-Mead', constraints=linear_constraint, options=optOptions, bounds=bounds)

print(xOpt.x)