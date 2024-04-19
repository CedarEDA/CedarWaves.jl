using CedarWaves
s1 = PWL([-2, 2], [-10, 10])
x1 = XMeasure(s1, 1/9)
CedarWaves.get_value(x1)
x1.x
x1.value
x1.y