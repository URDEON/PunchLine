#!/usr/bin/env python3
"""Rasteriza únicamente vistas SVG estáticas del HUD, usando librsvg y Cairo de Linux."""
import argparse
import ctypes as c
import ctypes.util
from pathlib import Path
import xml.etree.ElementTree as ET


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory',type=Path)
    args = parser.parse_args()
    rsvg = c.CDLL(ctypes.util.find_library('rsvg-2'))
    cairo = c.CDLL(ctypes.util.find_library('cairo'))
    gobject = c.CDLL(ctypes.util.find_library('gobject-2.0'))
    rsvg.rsvg_handle_new_from_data.argtypes = [c.c_char_p,c.c_size_t,c.c_void_p]
    rsvg.rsvg_handle_new_from_data.restype = c.c_void_p
    rsvg.rsvg_handle_render_cairo.argtypes = [c.c_void_p,c.c_void_p]
    rsvg.rsvg_handle_render_cairo.restype = c.c_int
    cairo.cairo_image_surface_create.argtypes = [c.c_int,c.c_int,c.c_int]
    cairo.cairo_image_surface_create.restype = c.c_void_p
    cairo.cairo_create.argtypes = [c.c_void_p]
    cairo.cairo_create.restype = c.c_void_p
    cairo.cairo_surface_write_to_png.argtypes = [c.c_void_p,c.c_char_p]
    cairo.cairo_surface_write_to_png.restype = c.c_int
    cairo.cairo_destroy.argtypes = [c.c_void_p]
    cairo.cairo_surface_destroy.argtypes = [c.c_void_p]
    gobject.g_object_unref.argtypes = [c.c_void_p]
    for source in args.directory.glob('hud_*.svg'):
        root = ET.parse(source).getroot()
        width,height = int(root.attrib['width']),int(root.attrib['height'])
        data = source.read_bytes()
        handle = rsvg.rsvg_handle_new_from_data(data,len(data),None)
        if not handle: raise RuntimeError('SVG inválido: '+str(source))
        surface = cairo.cairo_image_surface_create(0,width,height)
        context = cairo.cairo_create(surface)
        try:
            if not rsvg.rsvg_handle_render_cairo(handle,context): raise RuntimeError('No se pudo dibujar '+str(source))
            if cairo.cairo_surface_write_to_png(surface,str(source.with_suffix('.png')).encode()): raise RuntimeError('No se pudo guardar PNG')
        finally:
            cairo.cairo_destroy(context)
            cairo.cairo_surface_destroy(surface)
            gobject.g_object_unref(handle)
    print('Vistas estáticas PNG exportadas; no son capturas de Godot.')


if __name__ == '__main__': main()
