#!/usr/bin/env python3
# =============================================================================
# CNK-FarmaStatR - builds the method notes (help level 3) from their sources
#   web/yardim/kaynak/<note>.txt  ->  web/yardim/yontem/<note>.html (+ index.html)
# FSR-TN-PLT-07 v0.1 (Y-K3, Y-K4, Y-K5). Run from the repository root:
#   python3 araclar/yardim_derle.py
# Needs Python 3 and latex2mathml (pip install latex2mathml). Only needed when a
# note changes; the built HTML is committed. Equations become MathML, which the
# browser draws itself (no outside library, no network request).
#
# Source format (one file per note, Turkish and English blocks):
#   @@tr / @@en            language block
#   # Title                note title (first line of a block)
#   ## Heading             section heading
#   - item                 list item (consecutive lines form one list)
#   $$ LaTeX $$ :: source  display equation; the source label is REQUIRED
#                          (document + step/equation number, or "FarmaStatR ...")
#   blank line             paragraph break
#   inline: $LaTeX$, **bold**, *italic*, `code`, [text](url),
#           [[id|value]]   number of a worked example, checked against R
#                          (belgeler/teknik_notlar/FSR-TN-PLT-07_ek/p7_kabul.R)
# Research and education only; not a system validated for GxP environments.
# =============================================================================
import html
import pathlib
import re
import sys

from latex2mathml.converter import convert

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'web' / 'yardim' / 'kaynak'
OUT = ROOT / 'web' / 'yardim' / 'yontem'
NOTES = ['pbe', 'f2', 'msd', 'weibull', 'simulasyon']
DISCLAIMER = {'tr': 'Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.',
              'en': 'For research and education; not a system validated for GxP environments.'}
UI = {'tr': {'lang': 'English', 'back': 'Yöntem notları', 'eq': 'denklem'},
      'en': {'lang': 'Türkçe', 'back': 'Method notes', 'eq': 'equation'}}


def mathml(tex, display):
    m = convert(tex.strip())
    # decimal comma written as 1{,}11 -> one number; thin space after a function name
    m = re.sub(r'<mn>(\d+)</mn><mrow><mo>&#x0002C;</mo></mrow><mn>(\d+)</mn>', r'<mn>\1,\2</mn>', m)
    m = re.sub(r'(<mi>(?:ln|exp|log)</mi>)(?!</msub>)', r'\1<mspace width="0.167em"></mspace>', m)
    if display:
        m = m.replace('display="inline"', 'display="block"')
    return m


def inline(s):
    out, i = [], 0
    for m in re.finditer(r'\$([^$]+)\$', s):          # math first, the rest is escaped
        out.append(fmt(s[i:m.start()]))
        out.append(mathml(m.group(1), False))
        i = m.end()
    out.append(fmt(s[i:]))
    return ''.join(out)


def fmt(s):
    s = html.escape(s, quote=False)
    s = re.sub(r'\[\[([a-z0-9_]+)\|([^\]]+)\]\]', r'<span class="deger" data-deger="\1">\2</span>', s)
    s = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', s)
    s = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', s)
    s = re.sub(r'(?<![\w*])\*(?!\s)(.+?)(?<!\s)\*(?![\w*])', r'<i>\1</i>', s)
    s = re.sub(r'`([^`]+)`', r'<code>\1</code>', s)
    return s


def block(lines, lang, note):
    title, body, para, lst, neq = None, [], [], [], 0

    def flush():
        nonlocal para, lst
        if para:
            body.append('<p>' + inline(' '.join(para)) + '</p>')
            para = []
        if lst:
            body.append('<ul>' + ''.join('<li>' + inline(x) + '</li>' for x in lst) + '</ul>')
            lst = []
    for raw in lines:
        ln = raw.rstrip()
        if ln.startswith('# '):
            flush(); title = ln[2:].strip()
        elif ln.startswith('## '):
            flush(); body.append('<h2>' + inline(ln[3:].strip()) + '</h2>')
        elif ln.startswith('$$'):
            flush()
            m = re.match(r'\$\$(.+)\$\$\s*::\s*(.+)$', ln)
            if not m:
                sys.exit(f'{note}/{lang}: equation without source label: {ln}')
            neq += 1
            src = m.group(2).strip()
            body.append(f'<div class="eq" data-kaynak="{html.escape(src)}"><div class="eq-m">{mathml(m.group(1), True)}</div>'
                        f'<p class="eq-k">({neq}) [{inline(src)}]</p></div>')
        elif ln.startswith('- '):
            if para:
                flush()
            lst.append(ln[2:].strip())
        elif not ln.strip():
            flush()
        else:
            if lst:
                flush()
            para.append(ln.strip())
    flush()
    if not title:
        sys.exit(f'{note}/{lang}: no title')
    return title, '\n'.join(body), neq


def page(note, blocks):
    secs = []
    for lang in ('tr', 'en'):
        title, body, _ = blocks[lang]
        secs.append(f'<section class="not" lang="{lang}" data-lang="{lang}"{" hidden" if lang == "en" else ""}>\n'
                    f'<p class="ust"><a href="index.html?lang={lang}">{UI[lang]["back"]}</a></p>\n'
                    f'<h1>{html.escape(title)}</h1>\n<p class="disclaimer">{DISCLAIMER[lang]}</p>\n{body}\n</section>')
    return f'''<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CNK-FarmaStatR · {html.escape(blocks["tr"][0])}</title>
<!-- Built by araclar/yardim_derle.py from web/yardim/kaynak/{note}.txt (FSR-TN-PLT-07). Do not edit by hand.
     Research and education only; not a system validated for GxP environments. -->
<link rel="stylesheet" href="../../app/stil.css">
<link rel="stylesheet" href="not.css">
</head>
<body data-not="{note}">
<header><div><p class="sub">CNK-FarmaStatR</p></div><button id="lang" type="button" class="ghost"></button></header>
<main class="notmain">
{chr(10).join(secs)}
</main>
<script src="not.js"></script>
</body>
</html>
'''


def index(titles):
    secs = []
    for lang in ('tr', 'en'):
        head = 'Yöntem notları' if lang == 'tr' else 'Method notes'
        intro = ('Platformdaki yöntemlerin modeli, denklemleri, karar kuralı ve çalışılmış örneği. Her denklemin yanında kaynağı ya da “FarmaStatR türetimi” etiketi vardır.'
                 if lang == 'tr' else
                 'Model, equations, decision rule and a worked example of the methods in the platform. Every equation carries its source or the label “FarmaStatR derivation”.')
        items = ''.join(f'<li><a href="{n}.html?lang={lang}">{html.escape(titles[n][lang])}</a></li>' for n in NOTES)
        secs.append(f'<section class="not" lang="{lang}" data-lang="{lang}"{" hidden" if lang == "en" else ""}>\n<h1>{head}</h1>\n'
                    f'<p class="disclaimer">{DISCLAIMER[lang]}</p>\n<p>{intro}</p>\n<ul>{items}</ul>\n</section>')
    return f'''<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CNK-FarmaStatR · Yöntem notları</title>
<!-- Built by araclar/yardim_derle.py (FSR-TN-PLT-07). Research and education only; not a system validated for GxP environments. -->
<link rel="stylesheet" href="../../app/stil.css">
<link rel="stylesheet" href="not.css">
</head>
<body data-not="index">
<header><div><p class="sub">CNK-FarmaStatR</p></div><button id="lang" type="button" class="ghost"></button></header>
<main class="notmain">
{chr(10).join(secs)}
</main>
<script src="not.js"></script>
</body>
</html>
'''


def main():
    titles = {}
    for note in NOTES:
        txt = (SRC / f'{note}.txt').read_text(encoding='utf-8')
        parts = re.split(r'^@@(tr|en)\s*$', txt, flags=re.M)
        blocks = {}
        for k in range(1, len(parts), 2):
            blocks[parts[k]] = block(parts[k + 1].splitlines(), parts[k], note)
        if set(blocks) != {'tr', 'en'}:
            sys.exit(f'{note}: both @@tr and @@en blocks are needed')
        if blocks['tr'][2] != blocks['en'][2]:
            sys.exit(f'{note}: TR has {blocks["tr"][2]} equations, EN has {blocks["en"][2]}')
        titles[note] = {lang: blocks[lang][0] for lang in blocks}
        (OUT / f'{note}.html').write_text(page(note, blocks), encoding='utf-8')
        print(f'{note}: {blocks["tr"][2]} equations')
    (OUT / 'index.html').write_text(index(titles), encoding='utf-8')


if __name__ == '__main__':
    main()
