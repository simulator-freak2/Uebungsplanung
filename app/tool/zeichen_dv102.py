#!/usr/bin/env python3
"""Baut die taktischen Zeichen nach DV 102 organisationsneutral um.

Nach der DV 102 („Taktische Zeichen“, Grundlage auch für die DLRG) sind die
Zeichen für alle Organisationen gleich; die Zugehörigkeit zeigt allein die
Farbe des Grundzeichens. Die Vorlagen von taktisches-zeichen.de liegen aber
je Organisation getrennt vor (Feuerwehr rot, Wasserrettung/Rettungsdienst
weiß …). Dieses Skript

* fasst Einheiten, Fahrzeuge, Personen, Einrichtungen und Führungsstellen
  aller Organisationen zu je einer Kategorie zusammen (Doppelte entfallen),
* markiert in jedem Zeichen die Grundfarbe mit #FEFEFE und die Farbe des
  Inhalts (Schrift, Symbole, innerer Rand) mit #010101. Die Dateien bleiben
  so gültige, weiß/schwarze Zeichen; die App ersetzt beim Anzeigen beide
  Platzhalter durch die Farben der gewählten Organisation,
* schreibt `index.json` neu und `umzug.json`, mit der gespeicherte Skizzen
  die alten Dateipfade auf die neuen umstellen.

Aufruf:  python3 tool/zeichen_dv102.py <alter-zeichen-ordner> assets/zeichen
"""

import json
import os
import re
import shutil
import sys

GRUND = '#FEFEFE'
INHALT = '#010101'

# Neue Kategorie: [(Quellordner, Herkunft)]. Reihenfolge = Vorrang bei Doppelten.
MERGE = {
    'Einheiten': [('Feuerwehr_Einheiten', 'feuerwehr'), ('Wasserrettung_Einheiten', 'wasserrettung')],
    'Fahrzeuge': [('Feuerwehr_Fahrzeuge', 'feuerwehr'), ('Fahrzeuge', 'neutral'), ('Rettungswesen_Fahrzeuge', 'neutral'),
                  ('Wasserrettung_Fahrzeuge', 'wasserrettung')],
    'Personen': [('Feuerwehr_Personen', 'feuerwehr'), ('Personen', 'neutral'), ('Wasserrettung_Personen', 'wasserrettung')],
    'Einrichtungen': [('Einrichtungen', 'neutral'), ('Rettungswesen_Einrichtungen', 'neutral'), ('Wasserrettung_Einrichtungen', 'wasserrettung')],
    'Fuehrungsstellen': [('Fuehrungsstellen', 'neutral')],
}
TITEL = {'Einheiten': 'Einheiten', 'Fahrzeuge': 'Fahrzeuge', 'Personen': 'Personen', 'Einrichtungen': 'Einrichtungen',
         'Fuehrungsstellen': 'Führungsstellen'}
# Ordner, deren Zeichen feste Farben haben (Gefahren sind z. B. immer rot).
FEST = ['Gefahren', 'Schaeden', 'Massnahmen', 'Fernmeldewesen', 'Sonstiges']
REIHENFOLGE = ['Einheiten', 'Fahrzeuge', 'Personen', 'Einrichtungen', 'Fuehrungsstellen', *FEST]

TAG = re.compile(r'<(path|rect|ellipse|circle|line|polygon|polyline|text)\b[^>]*?/?>')
WHITE = {'#FFFFFF', '#FFF', 'WHITE'}
BLACK = {'#000000', '#000', 'BLACK', ''}
RED = {'#FF0000'}
YELLOW = {'#FFFF00'}


def attr(tag, name):
    m = re.search(r'\s%s="([^"]*)"' % name, tag)
    return None if m is None else m.group(1)


def set_attr(tag, name, value):
    if attr(tag, name) is not None:
        return re.sub(r'(\s%s=")[^"]*(")' % name, lambda m: m.group(1) + value + m.group(2), tag, count=1)
    return re.sub(r'^<(\w+)', lambda m: '<%s %s="%s"' % (m.group(1), name, value), tag, count=1)


def num(tag, name, default=0.0):
    v = attr(tag, name)
    try:
        return float(v)
    except (TypeError, ValueError):
        return default


def bbox(tag):
    kind = re.match(r'<(\w+)', tag).group(1)
    if kind == 'rect':
        x, y = num(tag, 'x'), num(tag, 'y')
        return x, y, x + num(tag, 'width'), y + num(tag, 'height')
    if kind in ('ellipse', 'circle'):
        cx, cy = num(tag, 'cx'), num(tag, 'cy')
        rx = num(tag, 'rx', num(tag, 'r'))
        ry = num(tag, 'ry', num(tag, 'r'))
        return cx - rx, cy - ry, cx + rx, cy + ry
    d = attr(tag, 'd') or ''
    if re.search(r'[a-z]', d.replace('e', '')):
        return 10, 64, 246, 192
    n = [float(v) for v in re.findall(r'-?\d+(?:\.\d+)?', d)]
    xs, ys = n[0::2], n[1::2]
    return (min(xs), min(ys), max(xs), max(ys)) if xs and ys else (10, 64, 246, 192)


def start(tag):
    """Ein Bezugspunkt des Elements, um zu prüfen, ob es im Grundzeichen liegt."""
    kind = re.match(r'<(\w+)', tag).group(1)
    if kind in ('ellipse', 'circle'):
        return num(tag, 'cx'), num(tag, 'cy')
    if kind == 'line':
        return None  # gesondert
    if kind in ('rect', 'text'):
        return num(tag, 'x', 128), num(tag, 'y', 128)
    m = re.match(r'\s*[Mm]\s*(-?[\d.]+)[\s,]+(-?[\d.]+)', attr(tag, 'd') or attr(tag, 'points') or '')
    return (float(m.group(1)), float(m.group(2))) if m else (128, 128)


def inside(tag, box):
    x0, y0, x1, y1 = box
    kind = re.match(r'<(\w+)', tag).group(1)
    if kind == 'line':
        pts = [(num(tag, 'x1'), num(tag, 'y1')), (num(tag, 'x2'), num(tag, 'y2'))]
    else:
        pts = [start(tag)]
    return all(x0 - 1 <= x <= x1 + 1 and y0 - 1 <= y <= y1 + 1 for x, y in pts)


def color(v):
    return None if v is None else v.strip().upper()


def is_base(tag, colors):
    fill = color(attr(tag, 'fill'))
    return fill in colors and ('url(#symbol)' in tag or color(attr(tag, 'stroke')) in BLACK | WHITE)


def convert(svg, origin):
    """Setzt die Platzhalter. Gibt (svg, farbig, grundfarbe) zurück."""
    svg = re.sub(r'viewbox=', 'viewBox=', svg)
    body_start = svg.find('</defs>')
    body_start = body_start + 7 if body_start >= 0 else svg.find('>', svg.find('<svg')) + 1
    head, body = svg[:body_start], svg[body_start:]
    tags = list(TAG.finditer(body))
    red = origin == 'feuerwehr'
    base_colors = RED if red else WHITE | YELLOW
    base = next((m for m in tags if is_base(m.group(0), base_colors)), None)
    if base is None:
        return svg, False, None
    btag = base.group(0)
    grund = 'fuehrung' if color(attr(btag, 'fill')) in YELLOW else 'hilfsorganisation'
    box = bbox(btag)
    clipped = 'url(#symbol)' in btag
    has_outline = any(
        m.start() > base.start() and color(attr(m.group(0), 'fill')) == 'NONE' and num(m.group(0), 'stroke-width', 1) <= 2
        for m in tags)

    out, pos = [], 0
    for m in tags:
        tag = m.group(0)
        new = tag
        if m is base:
            new = set_attr(new, 'fill', GRUND)
            s = color(attr(tag, 'stroke'))
            if red and s in WHITE:
                new = set_attr(new, 'stroke', INHALT)
            elif not red and s in BLACK and (clipped or has_outline):
                new = set_attr(new, 'stroke', INHALT)
        elif red:
            new = re.sub(r'((?:fill|stroke)\s*:\s*)#(?:FFFFFF|ffffff|FFF|fff)\b', lambda x: x.group(1) + INHALT, new)
            for a in ('fill', 'stroke'):
                c = color(attr(tag, a))
                if c in WHITE:
                    new = set_attr(new, a, INHALT)
                elif c in RED:
                    new = set_attr(new, a, GRUND)
        elif m.start() > base.start():
            kind = m.group(1)
            fill, stroke = color(attr(tag, 'fill')), color(attr(tag, 'stroke'))
            outline = fill == 'NONE' and num(tag, 'stroke-width', 1) <= 2
            if not outline and inside(tag, box):
                if fill is None and kind != 'line':
                    new = set_attr(new, 'fill', INHALT)
                elif fill in BLACK and fill != '':
                    new = set_attr(new, 'fill', INHALT)
                if stroke in BLACK and stroke != '':
                    new = set_attr(new, 'stroke', INHALT)
        out.append(body[pos:m.start()])
        out.append(new)
        pos = m.end()
    out.append(body[pos:])
    return head + ''.join(out), True, grund


def main(src, dst):
    old_index = json.load(open(os.path.join(src, 'index.json'), encoding='utf-8'))
    names = {z['datei']: z['name'] for c in old_index for z in c['zeichen']}
    for d in os.listdir(dst):
        p = os.path.join(dst, d)
        if os.path.isdir(p):
            shutil.rmtree(p)

    index, moves = [], {}
    cats = {}
    for cat, sources in MERGE.items():
        os.makedirs(os.path.join(dst, cat), exist_ok=True)
        entries, seen = [], {}
        for folder, origin in sources:
            for f in sorted(os.listdir(os.path.join(src, folder))):
                old = '%s/%s' % (folder, f)
                name = names.get(old, f[:-4].replace('_', ' '))
                key = f.lower()
                target = f
                if key in seen:
                    if origin != 'wasserrettung':
                        # gleiches Zeichen einer anderen Organisation: entfällt
                        moves[old] = {'datei': seen[key], 'organisation': 'hilfsorganisation'}
                        continue
                    target = f[:-4] + '_Wasserrettung.svg'
                    name = name + ' (Wasserrettung)'
                svg, colored, grund = convert(open(os.path.join(src, old), encoding='utf-8').read(), origin)
                open(os.path.join(dst, cat, target), 'w', encoding='utf-8').write(svg)
                entry = {'datei': '%s/%s' % (cat, target), 'name': name}
                if colored:
                    entry['grund'] = grund
                entries.append(entry)
                seen[target.lower()] = entry['datei']
                moves[old] = {'datei': entry['datei'], 'organisation': 'feuerwehr' if origin == 'feuerwehr' else (grund or 'hilfsorganisation')}
        entries.sort(key=lambda e: e['name'].lower())
        cats[cat] = entries
    for folder in FEST:
        shutil.copytree(os.path.join(src, folder), os.path.join(dst, folder))
        cats[folder] = next(c['zeichen'] for c in old_index if c['zeichen'][0]['datei'].startswith(folder + '/'))
    old_titles = {c['zeichen'][0]['datei'].split('/')[0]: c['kategorie'] for c in old_index}
    for cat in REIHENFOLGE:
        index.append({'kategorie': TITEL.get(cat, old_titles.get(cat, cat)), 'zeichen': cats[cat]})
    # Pfade, die unverändert bleiben, brauchen keinen Eintrag.
    moves = {'assets/zeichen/' + k: {**v, 'datei': 'assets/zeichen/' + v['datei']} for k, v in sorted(moves.items()) if k != v['datei']}
    json.dump(index, open(os.path.join(dst, 'index.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    json.dump(moves, open(os.path.join(dst, 'umzug.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('%d Zeichen, davon %d einfärbbar; %d alte Pfade umgestellt' % (
        sum(len(c['zeichen']) for c in index), sum(1 for c in index for z in c['zeichen'] if 'grund' in z), len(moves)))


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
