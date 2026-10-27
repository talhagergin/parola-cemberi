"""Reproducible original PCM sound effects. No third-party audio licenses."""
import math
import struct
import wave
from pathlib import Path

DEST = Path(__file__).resolve().parents[1] / 'assets' / 'audio'
NOTES = {
    'correct': [(660,.09,.46),(880,.16,.52)],
    'wrong': [(220,.16,.48),(165,.24,.42)],
    'pass': [(420,.09,.38),(330,.14,.34)],
    'hint': [(520,.08,.36),(700,.14,.42)],
    'streak': [(660,.08,.42),(830,.08,.47),(1050,.22,.54)],
    'warning': [(780,.10,.44),(780,.10,.44),(980,.16,.50)],
    'complete': [(523,.11,.42),(659,.11,.46),(784,.11,.50),(1047,.30,.56)],
}
DEST.mkdir(parents=True, exist_ok=True)
for name, notes in NOTES.items():
    samples = []
    for frequency, duration, volume in notes:
        for i in range(int(duration * 44100)):
            t = i / 44100
            envelope = min(1, t/.008) * min(1, (duration-t)/.035)
            signal = .85*math.sin(2*math.pi*frequency*t) + .15*math.sin(4*math.pi*frequency*t)
            samples.append(int(32767*volume*envelope*signal))
        samples.extend([0]*int(.025*44100))
    with wave.open(str(DEST / (name+'.wav')), 'wb') as output:
        output.setparams((1,2,44100,0,'NONE','not compressed'))
        output.writeframes(struct.pack('<'+'h'*len(samples),*samples))
