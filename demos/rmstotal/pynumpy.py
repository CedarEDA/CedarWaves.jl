import sys
import numpy as np
from time import time

points = 10**int(sys.argv[1])
factor = int(sys.argv[2])
f1 = 5*factor
f2 = 7*factor

t = np.linspace(0, 1, points)
y = np.cos(2*np.pi*f1*t) * np.cos(2*np.pi*f2*t)

def rms_signal_py(xs, ys):
    area = 0.0
    dx = np.diff(xs)
    dy = np.diff(ys)
    ya = ys[1:]*y[:-1]
    area = np.sum(dx*(dy**2/3 + ya))
    return np.sqrt(area/(xs[-1] - xs[0]))

print("python numpy")
ts = time()
rms_signal_py(t, y)
print("first rms time", time()-ts)
ts = time()
for _ in range(10):
    rms_signal_py(t, y)
print("rms time", time()-ts)