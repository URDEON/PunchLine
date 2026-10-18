#!/usr/bin/env python3
"""Convierte el modelo de dibujo exportado por Godot a SVG de diseño, sin gameplay."""
import argparse
from html import escape
import json
from pathlib import Path


def color(value):
    return f'color:{value[:7]};opacity:{int(value[7:9],16)/255:.4f}'


def svg(data):
    width,height = data['resolution']
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
             '<rect width="100%" height="100%" fill="#111a28"/>']
    for model in data['models']:
        matrix = ','.join(str(v) for v in model['matrix'])
        parts.append(f'<g transform="matrix({matrix})">')
        for item in model['commands']:
            style = color(item['color'])
            if item['type'] in ('polygon','line'):
                points = ' '.join(f'{p[0]},{p[1]}' for p in item['points'])
                if item['type'] == 'polygon': parts.append(f'<polygon points="{points}" fill="currentColor" style="{style}"/>')
                else: parts.append(f'<polyline points="{points}" fill="none" stroke="currentColor" stroke-width="{item["width"]}" stroke-linejoin="round" stroke-linecap="round" style="{style}"/>')
            else:
                fill,stroke = ('currentColor','none') if item['filled'] else ('none','currentColor')
                parts.append(f'<circle cx="{item["center"][0]}" cy="{item["center"][1]}" r="{item["radius"]}" fill="{fill}" stroke="{stroke}" stroke-width="{item["width"]}" style="{style}"/>')
        parts.append('</g>')
    for label in data['labels']:
        matrix = ','.join(str(v) for v in label['matrix'])
        anchor = ['start','middle','end'][min(label['align'],2)]
        x = label['size'][0]*[0,0.5,1][min(label['align'],2)]
        for i,line in enumerate(label['text'].splitlines()):
            parts.append(f'<text transform="matrix({matrix})" x="{x}" y="{label["ascent"]+i*label["font_size"]*1.25}" text-anchor="{anchor}" font-family="DejaVu Sans" font-size="{label["font_size"]}" fill="{label["color"][:7]}">{escape(line)}</text>')
    popup = data.get('character_popup',{})
    if popup:
        x,y = popup['position']
        w,h = popup['size']
        parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="12" fill="#111114" stroke="#28282d"/>')
        for row in popup['rows']:
            x,y = row['position']
            w,h = row['size']
            if not row['disabled']:
                parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="8" fill="#343438"/>')
            text_color = '#88888f' if row['disabled'] else '#eef0f8'
            parts.append(f'<text x="{x+14}" y="{y+h/2+7}" fill="{text_color}" font-family="DejaVu Sans" font-size="18">{escape(row["text"])}</text>')
    button = data['menu_button']
    x,y = button['position']
    w,h = button['size']
    parts += [f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="10" fill="#1c2130" stroke="#343b51"/>',
              f'<text x="{x+w/2}" y="{y+24}" text-anchor="middle" fill="#eef0f8" font-family="DejaVu Sans" font-size="14">{escape(button["text"])}</text>',
              f'<text x="{width/2}" y="{height*0.48}" text-anchor="middle" fill="#64748b" font-family="DejaVu Sans" font-size="{11 if width<600 else 15}">VISTA VECTORIAL DEL HUD</text>',
              f'<text x="{width/2}" y="{height*0.48+20}" text-anchor="middle" fill="#64748b" font-family="DejaVu Sans" font-size="11">No es una captura del juego</text>', '</svg>']
    return '\n'.join(parts)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',type=Path)
    args = parser.parse_args()
    for source in args.directory.glob('hud_*.json'):
        source.with_suffix('.svg').write_text(svg(json.loads(source.read_text())),encoding='utf-8')
    print('Vistas estáticas SVG exportadas.')


if __name__ == '__main__': main()
