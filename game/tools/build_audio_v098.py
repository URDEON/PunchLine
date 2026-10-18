#!/usr/bin/env python3
"""Recorta referencias del usuario y mezcla foley CC0. No cambia el tono de las referencias."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import numpy as np
from scipy.io import wavfile
from scipy.signal import butter, sosfilt

RATE = 48000
REFERENCES = {
    'm1_1': ('2026-10-12 01-24-33',1.37,1.81),
    'm1_2': ('2026-10-12 01-24-33',1.89,2.31),
    'm1_3': ('2026-10-12 01-24-33',2.37,2.70),
    'm1_4': ('2026-10-12 01-24-33',2.76,3.20),
    'rush': ('2026-10-12 01-34-44',1.10,2.59),
    'rush_alt': ('2026-10-12 01-24-19',1.48,2.82),
    'glass_enter': ('2026-10-12 01-24-56',3.04,3.63),
    'dash': ('2026-10-12 01-25-23',1.24,1.89),
    'block': ('2026-10-12 01-39-31',5.24,5.72),
    'evolved_accel': ('2026-10-12 01-26-26',1.25,2.63),
    'domain_open': ('2026-10-12 01-27-02',2.12,3.62),
    'domain_ambient': ('2026-10-12 01-27-02',7.45,12.45),
}


def decode(path):
    data = subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-vn','-ac','1','-ar',str(RATE),'-f','f32le','-'])
    return np.frombuffer(data,dtype='<f4').astype(np.float64)


def normalized(data, peak=.58):
    value = np.max(np.abs(data))
    if value < 1e-8:
        raise ValueError('Fuente silenciosa')
    return data*peak/value


def save(path, data):
    assert np.isfinite(data).all() and np.max(np.abs(data)) < 1
    wavfile.write(path,RATE,np.rint(data*32767).astype(np.int16))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--references',type=Path,required=True,help='Carpeta con los MKV originales o WAV decodificados con el mismo nombre')
    parser.add_argument('--punches',type=Path,required=True,help='37 hits/punches extraído')
    parser.add_argument('--body',type=Path,required=True,help='wet_towel_on_body extraído')
    parser.add_argument('--project',type=Path,default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    output = args.project/'assets/audio/v098';output.mkdir(parents=True,exist_ok=True)
    manifest = []
    decoded = {}
    for name,(stem,start,end) in REFERENCES.items():
        matches = list(args.references.glob(stem+'.mkv'))+list(args.references.glob(stem+'.wav'))
        if not matches:
            raise FileNotFoundError(stem)
        source = matches[0]
        if source not in decoded: decoded[source] = decode(source)
        original = decoded[source][round(start*RATE):round(end*RATE)]
        result = normalized(original)
        save(output/(name+'.wav'),result)
        manifest.append({'file':name+'.wav','source':source.name,'sha256_source':hashlib.sha256(source.read_bytes()).hexdigest(),'start':start,'end':end,'pitch':1.0,'processing':'recorte, mono 48 kHz, ganancia lineal; sin EQ ni capas','gain':float(result.max()/original.max()),'correlation':float(np.corrcoef(original,result)[0,1])})
    lowpass = butter(3,220,fs=RATE,output='sos')
    for i,(punch_id,body_id) in enumerate([(3,8),(10,15),(13,18),(21,24)]):
        punch = decode(next(args.punches.rglob(f'hit{punch_id:02d}.mp3.flac')))
        body = decode(next(args.body.rglob(f'wet_towel_on_body-{body_id:02d}.flac')))
        # Conserva el contacto grabado. El cuerpo grave viene de otra grabación,
        # filtrada, sin añadir osciladores ni música al impacto.
        active = np.flatnonzero(np.abs(punch) > np.max(np.abs(punch))*.025)
        punch = punch[max(0,int(active[0])-240):int(active[-1])+1200]
        active = np.flatnonzero(np.abs(body) > np.max(np.abs(body))*.025)
        body = body[max(0,int(active[0])-240):int(active[-1])+1200]
        count = min(RATE,int(max(len(punch),len(body))))
        result = np.zeros(count)
        result[:min(count,len(punch))] += normalized(punch)[:count]*.8
        filtered = sosfilt(lowpass,body)
        result[:min(count,len(body))] += normalized(filtered)[:count]*.32
        result = normalized(result,.55)
        fade = min(480,len(result)//4);result[-fade:] *= np.linspace(1,0,fade)
        save(output/f'body_{i+1}.wav',result)
        manifest.append({'file':f'body_{i+1}.wav','source_punch':f'hit{punch_id:02d}.mp3.flac','source_body':f'wet_towel_on_body-{body_id:02d}.flac','license':'CC0','processing':'contacto grabado + cuerpo grabado filtrado a 220 Hz, normalización y cola breve'})
    (output/'sources.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Audio generado:',len(manifest),'archivos; referencias sin cambio de tono')


if __name__ == '__main__':
    main()
