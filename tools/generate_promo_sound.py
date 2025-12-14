import math
import wave
import struct
from pathlib import Path

OUTPUT = Path('android/app/src/main/res/raw/promo_chime.wav')
OUTPUT.parent.mkdir(parents=True, exist_ok=True)

def main():
    sample_rate = 44100
    duration = 0.6  # seconds
    frequency = 880.0
    volume = 0.4
    total_frames = int(sample_rate * duration)

    with wave.open(str(OUTPUT), 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        for i in range(total_frames):
            t = i / sample_rate
            envelope = math.exp(-3 * t)  # quick fade out
            sample = volume * envelope * math.sin(2 * math.pi * frequency * t)
            wf.writeframes(struct.pack('<h', int(sample * 32767)))

    print(f'Generated custom sound at {OUTPUT}')


if __name__ == '__main__':
    main()
