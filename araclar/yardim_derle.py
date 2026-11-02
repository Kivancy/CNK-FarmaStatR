#!/usr/bin/env python3
# =============================================================================
# CNK-FarmaStatR - builds the method notes (help level 3) from their sources
#   web/yardim/kaynak/<note>.txt  ->  web/yardim/yontem/<note>.html (+ index.html)
#   web/yardim/kaynak/basit_<note>.txt -> web/yardim/yontem/basit_<note>.html: the note in
#   plain words "for the curious" (FSR-TN-PLT-10, KK-72); no equations; linked both ways.
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
NOTES = ['pbe', 'ema', 'f2', 'msd', 'weibull', 'simulasyon']
DISCLAIMER = {'tr': 'Araştırma ve eğitim amaçlıdır; GxP ortamında valide edilmiş sistem değildir.',
              'en': 'For research and education; not a system validated for GxP environments.'}
UI = {'tr': {'lang': 'English', 'back': 'Yöntem notları', 'eq': 'denklem',
             'basit': 'Meraklısı için bu notun basit anlatımı →', 'teknik': 'Teknik not →',
             'basit_head': 'İstatistiği Anlamaya Meraklılar İçin Notlar'},
      'en': {'lang': 'Türkçe', 'back': 'Method notes', 'eq': 'equation',
             'basit': 'For the curious: this note in plain words →', 'teknik': 'Technical note →',
             'basit_head': 'Notes for the statistically curious'}}


def mathml(tex, display):
    m = convert(tex.strip())
    # decimal comma written as 1{,}11 -> one number; thin space after a function name
    m = re.sub(r'<mn>(\d+)</mn><mrow><mo>&#x0002C;</mo></mrow><mn>(\d+)</mn>', r'<mn>\1,\2</mn>', m)
    m = re.sub(r'(<mi>(?:ln|exp|log)</mi>)(?!</msub>)', r'\1<mspace width="0.167em"></mspace>', m)
    if display:
        m = m.replace('display="inline"', 'display="block"')
    # a command latex2mathml does not know is left as text (e.g. <mi>\arg</mi>): stop the build
    bad = re.findall(r'<m[ion]>\\[A-Za-z]+</m[ion]>', m)
    if bad:
        raise SystemExit(f'unconverted LaTeX {bad} in: {tex.strip()}')
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


def page(note, blocks, simple=False, has_simple=False):
    # simple: the plain-words page basit_<note>; has_simple: technical note that has one (KK-72)
    secs = []
    for lang in ('tr', 'en'):
        title, body, _ = blocks[lang]
        ust = f'<a href="index.html?lang={lang}">{UI[lang]["back"]}</a>'
        if simple:
            ust += f' · <a href="{note}.html?lang={lang}">{UI[lang]["teknik"]}</a>'
        bag = f'<p class="basit-bag"><a href="basit_{note}.html?lang={lang}">{UI[lang]["basit"]}</a></p>\n' if has_simple else ''
        secs.append(f'<section class="not" lang="{lang}" data-lang="{lang}"{" hidden" if lang == "en" else ""}>\n'
                    f'<p class="ust">{ust}</p>\n'
                    f'<h1>{html.escape(title)}</h1>\n<p class="disclaimer">{DISCLAIMER[lang]}</p>\n{bag}{body}\n</section>')
    src = f'basit_{note}' if simple else note
    return f'''<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CNK-FarmaStatR · {html.escape(blocks["tr"][0])}</title>
<!-- Built by araclar/yardim_derle.py from web/yardim/kaynak/{src}.txt (FSR-TN-PLT-{"10" if simple else "07"}). Do not edit by hand.
     Research and education only; not a system validated for GxP environments. -->
<link rel="stylesheet" href="../../app/stil.css">
<link rel="stylesheet" href="not.css">
</head>
<body data-not="{src}">
<header><div><p class="sub">CNK-FarmaStatR</p></div><button id="lang" type="button" class="ghost"></button></header>
<main class="notmain">
{chr(10).join(secs)}
</main>
<script src="not.js"></script>
</body>
</html>
'''


def index(titles, simple_titles):
    secs = []
    for lang in ('tr', 'en'):
        head = 'Yöntem notları' if lang == 'tr' else 'Method notes'
        intro = ('Platformdaki yöntemlerin modeli, denklemleri, karar kuralı ve çalışılmış örneği. Her denklemin yanında kaynağı ya da “Tasarım gereği” etiketi vardır.'
                 if lang == 'tr' else
                 'Model, equations, decision rule and a worked example of the methods in the platform. Every equation carries its source or the label “By design”.')
        items = ''.join(f'<li><a href="{n}.html?lang={lang}">{html.escape(titles[n][lang])}</a></li>' for n in NOTES)
        extra = ''
        if simple_titles:   # FSR-TN-PLT-10 (KK-72)
            sintro = ('Yöntem notlarının günlük dille, denklemsiz ve yürüyen bir örnekle anlatımı. Yeni yöntem içermez; sayıların kaynağı yazılıdır.'
                      if lang == 'tr' else
                      'The method notes in everyday words, without equations and with a running example. No new method; the source of every number is given.')
            sitems = ''.join(f'<li><a href="basit_{n}.html?lang={lang}">{html.escape(simple_titles[n][lang])}</a></li>' for n in NOTES if n in simple_titles)
            extra = f'\n<h2>{UI[lang]["basit_head"]}</h2>\n<p>{sintro}</p>\n<ul>{sitems}</ul>'
        secs.append(f'<section class="not" lang="{lang}" data-lang="{lang}"{" hidden" if lang == "en" else ""}>\n<h1>{head}</h1>\n'
                    f'<p class="disclaimer">{DISCLAIMER[lang]}</p>\n<p>{intro}</p>\n<ul>{items}</ul>{extra}\n</section>')
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


def read_blocks(name):
    txt = (SRC / f'{name}.txt').read_text(encoding='utf-8')
    parts = re.split(r'^@@(tr|en)\s*$', txt, flags=re.M)
    blocks = {}
    for k in range(1, len(parts), 2):
        blocks[parts[k]] = block(parts[k + 1].splitlines(), parts[k], name)
    if set(blocks) != {'tr', 'en'}:
        sys.exit(f'{name}: both @@tr and @@en blocks are needed')
    if blocks['tr'][2] != blocks['en'][2]:
        sys.exit(f'{name}: TR has {blocks["tr"][2]} equations, EN has {blocks["en"][2]}')
    return blocks


def main():
    titles, simple_titles = {}, {}
    for note in NOTES:
        blocks = read_blocks(note)
        has_simple = (SRC / f'basit_{note}.txt').exists()
        titles[note] = {lang: blocks[lang][0] for lang in blocks}
        (OUT / f'{note}.html').write_text(page(note, blocks, has_simple=has_simple), encoding='utf-8')
        print(f'{note}: {blocks["tr"][2]} equations')
        if has_simple:
            sb = read_blocks(f'basit_{note}')
            for lang in ('tr', 'en'):     # plain words: no equations at all (FSR-TN-PLT-10 B-5)
                if sb[lang][2] or '<math' in sb[lang][1]:
                    sys.exit(f'basit_{note}/{lang}: equations are not allowed in a plain-words page')
            simple_titles[note] = {lang: sb[lang][0] for lang in sb}
            (OUT / f'basit_{note}.html').write_text(page(note, sb, simple=True), encoding='utf-8')
            print(f'basit_{note}: plain words')
    (OUT / 'index.html').write_text(index(titles, simple_titles), encoding='utf-8')


if __name__ == '__main__':
    main()
