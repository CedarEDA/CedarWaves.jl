import math
def RMS_py(xs, ys):
    area = 0.0
    for i in range(1, len(xs)):
        dx = xs[i] - xs[i-1]
        y1 = ys[i-1]
        y2 = ys[i]
        dy = y2 - y1
        area += dx*(dy**2/3 + y1*y2)  # quadratic shape
    return math.sqrt(area/(xs[-1] - xs[0]))
	
def RMS_modulated_py(fb, fc, offset, xs):
	s1 = [math.sin(2*math.pi*fb*x) for x in xs]  # baseband signal
	s2 = [math.cos(2*math.pi*fc*x) for x in xs]  # carrier signal
	mixed = [s1[i]*s2[i] + offset for i in range(len(s1))]  # modulated signal
	return RMS_py(xs, mixed)

fb = 2
fc = 20
N = 10**6
xs = [i/N for i in range(N+1)]
offset = 0


# Run benchmark
import time
trials = 5
val = RMS_modulated_py(fb, fc, offset, xs)
times = []
min_time = 1e6
tbegin = time.time()
for i in range(trials):
    t1 = time.time()
    val = RMS_modulated_py(fb, fc, offset, xs)
    t2 = time.time()
    min_time = min(min_time, t2 - t1)
tdone = time.time()

ns = (tdone - tbegin)/trials/N * 1e9
avg_time = (tdone - tbegin)/trials

print("Modulated RMS: {val}".format(val=val))

print("Best time of {trials} trials: {min_time}".format(trials=trials, min_time=min_time))
print("Average time of {trials} trials: {avg_time}".format(trials=trials, avg_time=avg_time))

import sys
ver = "{major}.{minor}.{micro}".format(major=sys.version_info[0], minor=sys.version_info[1], micro=sys.version_info[2])
print("Python {ver}     for modulated rms = {val} : {t:>5} ns per iteration average over {trials:>3} trials of {N} points".format(ver=ver, val=val, t=round(ns,1), trials=trials, N=N))
