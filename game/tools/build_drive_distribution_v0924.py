"""Creates native, automatically mounted Godot packs below Drive's per-file limit."""
import argparse,json,struct,subprocess,tempfile
from pathlib import Path

def main():
    p=argparse.ArgumentParser(description=__doc__)
    for key in ['godot','template','pack','output']:p.add_argument('--'+key,type=Path,required=True)
    a=p.parse_args();project=Path(__file__).resolve().parents[1];output=a.output.resolve();output.mkdir(parents=True,exist_ok=True)
    with a.pack.open('rb') as f:
        header=f.read(100)
        if header[:4]!=b'GDPC' or struct.unpack_from('<I',header,4)[0]!=2:raise SystemExit('Unsupported PCK')
        count=struct.unpack_from('<I',header,96)[0];entries=[]
        for _ in range(count):
            length=struct.unpack('<I',f.read(4))[0];name=f.read(length).rstrip(b'\0').decode()
            offset,size=struct.unpack('<QQ',f.read(16));digest=f.read(16).hex();flags=struct.unpack('<I',f.read(4))[0]
            entries.append(dict(path=name,size=size,md5=digest))
    with tempfile.TemporaryDirectory(prefix='punchline_dist_') as temp:
        temp=Path(temp);index=temp/'entries.json';index.write_text(json.dumps(entries))
        subprocess.run([str(a.godot.resolve()),'--headless','--main-pack',str(a.pack.resolve()),'--script',str(project/'tools/package_content_v0924.gd'),'--',str(index),str(output)],check=True)
        index.unlink()
        config=(project/'project.godot').read_text().replace('res://launcher.tscn','res://boot.tscn')
        (temp/'project.godot').write_text(config)
        for name in ['boot.gd','boot.tscn']:(temp/name).write_bytes((project/'tools/distribution'/name).read_bytes())
        (temp/'export_presets.cfg').write_text('''[preset.0]
name="Windows Desktop"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
script_export_mode=0
[preset.0.options]
custom_template/release="'''+a.template.resolve().as_posix()+'''"
binary_format/embed_pck=false
binary_format/architecture="x86_64"
debug/export_console_wrapper=0
application/modify_resources=false
application/product_name="PunchLine"
application/file_version="0.9.24.0"
application/product_version="0.9.24.0"
''')
        subprocess.run([str(a.godot.resolve()),'--headless','--editor','--path',str(temp),'--import'],check=True)
        subprocess.run([str(a.godot.resolve()),'--headless','--path',str(temp),'--export-release','Windows Desktop',str(output/'PunchLine_0.9.24.exe')],check=True)
    for f in output.iterdir():
        if f.is_file() and f.stat().st_size>100*1024*1024:raise SystemExit('File exceeds Drive limit: '+str(f))
    print('DISTRIBUTION_READY',output)

if __name__=='__main__':main()
