#!/usr/bin/env python3
"""Extrae plantillas oficiales 4.4.1 por HTTP Range; no instala otro editor."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile

URL = 'https://github.com/godotengine/godot-builds/releases/download/4.4.1-stable/Godot_v4.4.1-stable_export_templates.tpz'
SIZE = 1206040900

class RangeFile(io.RawIOBase):
    def __init__(self): self.position = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self,offset,whence=0):
        self.position = offset if whence == 0 else self.position+offset if whence == 1 else SIZE+offset
        return self.position
    def read(self,size=-1):
        if size < 0: size = SIZE-self.position
        if size == 0 or self.position >= SIZE: return b''
        end = min(SIZE,self.position+size)-1
        request = urllib.request.Request(URL,headers={'Range':f'bytes={self.position}-{end}'})
        with urllib.request.urlopen(request,timeout=60) as response:
            if response.status != 206 or response.headers.get('Content-Range') != f'bytes {self.position}-{end}/{SIZE}':
                raise RuntimeError('Servidor no respeta HTTP Range; detener sin eludir la política de red.')
            data = response.read(end-self.position+1)
        if len(data) != end-self.position+1: raise RuntimeError('Transferencia incompleta')
        self.position += len(data)
        return data

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,required=True)
    args = parser.parse_args(); args.output.mkdir(parents=True,exist_ok=True)
    names = ['version.txt','windows_release_x86_64.exe','windows_release_x86_64_console.exe','linux_release.x86_64']
    report = {'source':URL,'version':'4.4.1.stable','files':[]}
    with zipfile.ZipFile(RangeFile()) as archive:
        for name in names:
            path = args.output/name
            if path.exists(): raise RuntimeError('No sobrescribir plantillas existentes')
            with archive.open('templates/'+name) as source, path.open('wb') as output:
                while block := source.read(4*1024*1024): output.write(block)
            path.chmod(0o700)
            entry = {'file':name,'size':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'zip_crc':archive.getinfo('templates/'+name).CRC}
            report['files'].append(entry); print(json.dumps(entry),flush=True)
    (args.output/'source.json').write_text(json.dumps(report,indent=2)+'\n')

if __name__ == '__main__': main()
