"""Deterministic original PCM assets; no network or third-party recordings."""
from pathlib import Path
import math, random, struct, wave
ROOT = Path(__file__).resolve().parent.parent / 'assets/audio'
ROOT.mkdir(parents=True, exist_ok=True)
RATE = 22050
for name, seconds, frequency, noise in [('river',4,70,.7),('sizzle',2,180,.85),('kettle',3,1700,.35),('fan',2,85,.3),('pour',.6,300,.6),('coin',.28,880,.03),('chime',.4,520,.01)]:
    rng = random.Random(name)
    samples = []
    filtered = 0
    count = round(seconds*RATE)
    loop = name in ['river','sizzle','kettle','fan']
    for i in range(count):
        t=i/RATE
        filtered = .9*filtered+.1*rng.uniform(-1,1)
        random_sample = filtered if name in ['river','fan'] else rng.uniform(-1,1)
        signal = (1-noise)*math.sin(2*math.pi*frequency*t)+noise*random_sample
        envelope = min(1,i/220,(count-i)/220) if loop else math.exp(-t*8)*min(1,i/100)
        samples.append(round(max(-1,min(1,signal*envelope*.55))*32767))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as output:
        output.setnchannels(1);output.setsampwidth(2);output.setframerate(RATE)
        output.writeframes(struct.pack('<'+'h'*count,*samples))
