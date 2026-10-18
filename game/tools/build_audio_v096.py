"""Sonidos originales reproducibles. Sin muestras de música comercial."""
from pathlib import Path
from array import array
import math, random, wave, subprocess
ROOT=Path(__file__).resolve().parents[1]; OUT=ROOT/'assets/audio/v096';OUT.mkdir(exist_ok=True)
SR=44100; rng=random.Random(24096)
def save(name,samples,loop=False):
 peak=max(abs(x) for x in samples) or 1
 pcm=array('h',(round(x/peak*.72*32767) for x in samples))
 target=OUT/(name+'.wav')
 with wave.open(str(target),'wb') as f: f.setparams((1,2,SR,len(pcm),'NONE',''));f.writeframes(pcm.tobytes())
 if loop:
  subprocess.run(['ffmpeg','-v','error','-y','-i',str(target),'-c:a','libvorbis','-q:a','4',str(OUT/(name+'.ogg'))],check=True);target.unlink()
def tone(name,notes,duration):
 samples=[]
 for i in range(round(duration*SR)):
  t=i/SR; env=min(1,t/.008)*math.exp(-t*14)*(1-t/duration)
  samples.append(env*sum(math.sin(math.tau*hz*t+math.sin(t*3)*.1) for hz in notes))
 save(name,samples)
tone('menu_open',[440,660],.24);tone('menu_close',[330,495],.18)
tone('checkpoint',[660,880,1320],.34);tone('recovery',[220,330],.25)
tone('jump',[260,520],.12);tone('kogane',[740,1110],.36)
save('domain_ambient',[(math.sin(math.tau*55*i/SR)*.4+math.sin(math.tau*82.5*i/SR)*.2+math.sin(math.tau*110*i/SR)*.12)*(1+.12*math.sin(math.tau*i/SR*.25)) for i in range(SR*8)],True)
music=[0.0]*(SR*8)
def instrument(start,duration,kind,hz=55):
 for j in range(int(duration*SR)):
  index=int(start*SR)+j
  if index>=len(music):break
  t=j/SR
  if kind=='kick':value=math.sin(math.tau*(48*t+8*(1-math.exp(-t*30))))*math.exp(-t*18)*.8
  elif kind=='snare':value=rng.uniform(-1,1)*math.exp(-t*25)*.25+math.sin(math.tau*180*t)*math.exp(-t*35)*.16
  elif kind=='hat':value=rng.uniform(-1,1)*math.exp(-t*65)*.10
  else:value=(math.sin(math.tau*hz*t)+.2*math.sin(math.tau*hz*2*t))*min(1,t/.01)*math.exp(-t*7)*.3
  music[index]+=value
for beat in range(16):
 instrument(beat*.5,.24,'kick')
 if beat%2:instrument(beat*.5,.18,'snare')
 for sub in range(2):instrument(beat*.5+sub*.25,.06,'hat')
 for sub,note in [(0,[55,65.406,73.416,49][beat//4]),(.32,[110,130.812,146.832,98][beat//4])]:instrument(beat*.5+sub,.17,'bass',note)
save('projection_groove',music,True)
print('9 recursos originales:',OUT)
