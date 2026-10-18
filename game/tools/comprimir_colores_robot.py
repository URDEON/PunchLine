#!/usr/bin/env python3
"""Codificación de texturas sin pérdida. Requiere los PNG de Fuentes, FFmpeg y Pillow."""
import hashlib
import json
from pathlib import Path
import subprocess
from PIL import Image

root = Path(__file__).resolve().parent.parent
report = []
for source in sorted((root/'assets/characters/robots').glob('*/color_*.png')):
    target = source.with_suffix('.webp')
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(source),
                    '-c:v','libwebp','-lossless','1','-compression_level','6','-pix_fmt','bgra',str(target)],check=True)
    original = Image.open(source).convert('RGBA')
    compressed = Image.open(target).convert('RGBA')
    assert original.size == compressed.size and original.tobytes() == compressed.tobytes()
    report.append({'source':source.relative_to(root).as_posix(),'target':target.relative_to(root).as_posix(),
                   'size':original.size,'identical_rgba':True,
                   'pixel_sha256':hashlib.sha256(original.tobytes()).hexdigest(),
                   'source_bytes':source.stat().st_size,'target_bytes':target.stat().st_size})
if len(report) != 16:
    raise SystemExit('Se requieren los 16 PNG del respaldo de Fuentes; no se modificaron los archivos originales.')
print(json.dumps(report,indent=2))
