// CNK-FarmaStatR - Word (.docx) report in the browser (FSR-TN-PLT-05 v0.2 Sections 4-6; T-4, T-5;
// decisions P5-K1 ... P5-K4, KK-57). No library: a stored (uncompressed) ZIP with fixed OOXML
// parts (P5-K2). The report holds the same strings as the screen: the caller passes the view
// that the screen itself shows (numbers formatted once by bicim.js, P5-K1). Nothing leaves the
// browser. Deterministic: fixed ZIP dates (1980-01-01), no dates in document properties; the
// creation time is one line of text, so two reports of the same result differ only there (R-7).
// Research and education only; not a system validated for GxP environments.

const enc = new TextEncoder();

// ---------------------------------------------------------------- stored ZIP
const CRC = (() => {
  const tb = new Uint32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; tb[n] = c >>> 0; }
  return tb;
})();
function crc32(b) { let c = 0xFFFFFFFF; for (let i = 0; i < b.length; i++) c = CRC[(c ^ b[i]) & 255] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }
export function zipStored(files) {               // files: [[name, Uint8Array]]
  const DOS_TIME = 0, DOS_DATE = 0x21;          // 1980-01-01 00:00
  const parts = [], central = []; let off = 0;
  for (const [name, data] of files) {
    const nb = enc.encode(name), crc = crc32(data);
    const h = new DataView(new ArrayBuffer(30));
    h.setUint32(0, 0x04034b50, true); h.setUint16(4, 20, true); h.setUint16(6, 0x0800, true); h.setUint16(8, 0, true);
    h.setUint16(10, DOS_TIME, true); h.setUint16(12, DOS_DATE, true); h.setUint32(14, crc, true);
    h.setUint32(18, data.length, true); h.setUint32(22, data.length, true); h.setUint16(26, nb.length, true); h.setUint16(28, 0, true);
    parts.push(new Uint8Array(h.buffer), nb, data);
    const c = new DataView(new ArrayBuffer(46));
    c.setUint32(0, 0x02014b50, true); c.setUint16(4, 20, true); c.setUint16(6, 20, true); c.setUint16(8, 0x0800, true); c.setUint16(10, 0, true);
    c.setUint16(12, DOS_TIME, true); c.setUint16(14, DOS_DATE, true); c.setUint32(16, crc, true);
    c.setUint32(20, data.length, true); c.setUint32(24, data.length, true); c.setUint16(28, nb.length, true); c.setUint32(42, off, true);
    central.push(new Uint8Array(c.buffer), nb);
    off += 30 + nb.length + data.length;
  }
  const csize = central.reduce((s, a) => s + a.length, 0);
  const e = new DataView(new ArrayBuffer(22));
  e.setUint32(0, 0x06054b50, true); e.setUint16(8, files.length, true); e.setUint16(10, files.length, true);
  e.setUint32(12, csize, true); e.setUint32(16, off, true);
  const all = [...parts, ...central, new Uint8Array(e.buffer)];
  const out = new Uint8Array(all.reduce((s, a) => s + a.length, 0)); let p = 0;
  for (const a of all) { out.set(a, p); p += a.length; }
  return out;
}

// ---------------------------------------------------------------- OOXML pieces
const x = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const NS = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';
const run = (t, o = {}) => {
  const rp = (o.b ? '<w:b/>' : '') + (o.i ? '<w:i/>' : '') + (o.sz ? `<w:sz w:val="${o.sz}"/>` : '') + (o.color ? `<w:color w:val="${o.color}"/>` : '');
  return `<w:r>${rp ? '<w:rPr>' + rp + '</w:rPr>' : ''}<w:t xml:space="preserve">${x(t)}</w:t></w:r>`;
};
export const P = (t, o = {}) => `<w:p>${o.style ? `<w:pPr><w:pStyle w:val="${o.style}"/></w:pPr>` : o.keep ? '<w:pPr><w:keepNext/></w:pPr>' : ''}${Array.isArray(t) ? t.map((r) => run(r[0], r[1])).join('') : run(t, o)}</w:p>`;
export const H1 = (t) => P(t, { style: 'Heading1' });
export const H2 = (t) => P(t, { style: 'Heading2' });
// rows: arrays of cell texts; first row is the header; num: indexes of right-aligned columns
export function TABLE(rows, num = [], small = false) {
  const cell = (c, i, head) => `<w:tc><w:p><w:pPr>${small ? '<w:spacing w:after="0"/>' : '<w:spacing w:after="0"/>'}${num.includes(i) ? '<w:jc w:val="right"/>' : ''}</w:pPr>` +
    (Array.isArray(c) ? c.map((r, k) => (k ? '<w:r><w:br/></w:r>' : '') + run(r, { b: head || (k === 0 && small), sz: small ? 16 : 18 })).join('')
      : run(c, { b: head, sz: small ? 16 : 18 })) + '</w:p></w:tc>';
  return '<w:tbl><w:tblPr><w:tblStyle w:val="Tablo"/><w:tblW w:w="5000" w:type="pct"/></w:tblPr>' +
    rows.map((r, i) => `<w:tr>${i === 0 ? '<w:trPr><w:tblHeader/></w:trPr>' : '<w:trPr><w:cantSplit/></w:trPr>'}${r.map((c, k) => cell(c, k, i === 0)).join('')}</w:tr>`).join('') +
    '</w:tbl>' + P('');
}

// inline picture i (1-based) of R.images, width w and height h in pixels at 96 dpi scaled to the
// text width (FSR-TN-PLT-14, KK-80). Only reports that carry images use it (GR-7).
const IMG_NS = 'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"';
export function IMG(i, w, h, title) {
  const cx = 6120000, cy = Math.round(cx * h / w);   // 17 cm wide
  return `<w:p><w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="${cx}" cy="${cy}"/><wp:docPr id="${i}" name="${x(title)}"/>` +
    '<wp:cNvGraphicFramePr><a:graphicFrameLocks noChangeAspect="1"/></wp:cNvGraphicFramePr><a:graphic><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">' +
    `<pic:pic><pic:nvPicPr><pic:cNvPr id="${i}" name="grafik${i}.png"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="rIdImg${i}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>` +
    `<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="${cx}" cy="${cy}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>`;
}

function docx(body, headerText, footerText, images = []) {
  const f = (s) => enc.encode('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n' + s);
  const footer = `<w:ftr ${NS}><w:p><w:pPr><w:pStyle w:val="Footer"/></w:pPr>${run(footerText + ' · ')}` +
    '<w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p></w:ftr>';
  return zipStored([
    ['[Content_Types].xml', f(`<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/>${images.length ? '<Default Extension="png" ContentType="image/png"/>' : ''}<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/word/header1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/></Types>`)],
    ['_rels/.rels', f('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>')],
    ['word/_rels/document.xml.rels', f(`<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" Target="header1.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/><Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>${images.map((_, k) => `<Relationship Id="rIdImg${k + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/grafik${k + 1}.png"/>`).join('')}</Relationships>`)],
    ['word/settings.xml', f(`<w:settings ${NS}><w:defaultTabStop w:val="709"/><w:compat><w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat></w:settings>`)],
    ['word/styles.xml', f(`<w:styles ${NS}><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Calibri"/><w:sz w:val="20"/><w:szCs w:val="20"/><w:lang w:val="tr-TR" w:eastAsia="en-US" w:bidi="ar-SA"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="80" w:line="259" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>` +
      '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>' +
      '<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:after="120"/></w:pPr><w:rPr><w:b/><w:color w:val="1F5F8B"/><w:sz w:val="32"/></w:rPr></w:style>' +
      '<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="80"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:color w:val="1F5F8B"/><w:sz w:val="26"/></w:rPr></w:style>' +
      '<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="160" w:after="60"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="22"/></w:rPr></w:style>' +
      '<w:style w:type="paragraph" w:styleId="Beyan"><w:name w:val="Beyan"/><w:basedOn w:val="Normal"/><w:pPr><w:shd w:val="clear" w:color="auto" w:fill="FFF4E0"/><w:spacing w:after="60"/></w:pPr><w:rPr><w:b/><w:color w:val="7A4A00"/></w:rPr></w:style>' +
      '<w:style w:type="paragraph" w:styleId="Header"><w:name w:val="header"/><w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="right"/></w:pPr><w:rPr><w:color w:val="5F5F5A"/><w:sz w:val="16"/></w:rPr></w:style>' +
      '<w:style w:type="paragraph" w:styleId="Footer"><w:name w:val="footer"/><w:basedOn w:val="Normal"/><w:pPr><w:jc w:val="center"/></w:pPr><w:rPr><w:color w:val="7A4A00"/><w:sz w:val="16"/></w:rPr></w:style>' +
      '<w:style w:type="paragraph" w:styleId="Kucuk"><w:name w:val="Kucuk"/><w:basedOn w:val="Normal"/><w:rPr><w:color w:val="5F5F5A"/><w:sz w:val="17"/></w:rPr></w:style>' +
      '<w:style w:type="table" w:default="1" w:styleId="TableNormal"><w:name w:val="Normal Table"/><w:tblPr><w:tblInd w:w="0" w:type="dxa"/><w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="108" w:type="dxa"/><w:bottom w:w="0" w:type="dxa"/><w:right w:w="108" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>' +
      '<w:style w:type="table" w:styleId="Tablo"><w:name w:val="Tablo"/><w:basedOn w:val="TableNormal"/><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="999999"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="D9D8D2"/></w:tblBorders><w:tblCellMar><w:top w:w="30" w:type="dxa"/><w:left w:w="70" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/><w:right w:w="70" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style></w:styles>')],
    ['word/header1.xml', f(`<w:hdr ${NS}><w:p><w:pPr><w:pStyle w:val="Header"/></w:pPr>${run(headerText)}</w:p></w:hdr>`)],
    ['word/footer1.xml', f(footer)],
    ...images.map((im, k) => [`word/media/grafik${k + 1}.png`, im.bytes]),
    ['word/document.xml', f(`<w:document ${NS}${images.length ? ' ' + IMG_NS : ''}><w:body>${body}<w:sectPr><w:headerReference w:type="default" r:id="rId2"/><w:footerReference w:type="default" r:id="rId3"/><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1021" w:bottom="1134" w:left="1021" w:header="567" w:footer="567" w:gutter="0"/></w:sectPr></w:body></w:document>`)]
  ]);
}

// ---------------------------------------------------------------- the report (Table 4.1 of FSR-TN-PLT-05)
// R: { kind: 'tek' | 'tasarim', t, lang, created, header, disclaimer_tr, disclaimer_en,
//      identity: [[label, value]], versions: [[label, value]], files: [[file, pinned, sha, status]] | null,
//      params: [[label, value]], source, result: [xml ...], warnings: [text], link (null: no Section 9), sources?,
//      veri? [xml ...]: Section 9 'Analysed data' of the analysis reports (FSR-TN-PLT-11, KK-75),
//      images? [{ bytes, w, h }]: PNG pictures referred to by IMG(i, ...) in result (FSR-TN-PLT-14, KK-80) }
export function buildReport(R) {
  const t = R.t;
  const b = [];
  b.push(P(t('rp_title_' + R.kind), { style: 'Title' }));
  b.push(P(R.disclaimer_tr, { style: 'Beyan' }), P(R.disclaimer_en, { style: 'Beyan' }));
  b.push(P([[t('rp_created') + ': ', { b: true }], [R.created, {}]]));
  b.push(H1('1. ' + t('rp_s_identity')), TABLE([[t('rp_field'), t('rp_value')], ...R.identity]));
  b.push(H1('2. ' + t('rp_s_versions')), TABLE([[t('rp_field'), t('rp_value')], ...R.versions]));
  if (R.files) b.push(TABLE([[t('rp_file'), t('rp_pinned'), 'SHA-256', t('rp_status')], ...R.files], [], true));
  b.push(H1('3. ' + t('rp_s_params')), TABLE([[t('rp_param'), t('rp_value')], ...R.params]));
  b.push(H1('4. ' + t('rp_s_source')), P(R.source));
  b.push(H1('5. ' + t('rp_s_result')), ...R.result);
  b.push(H1('6. ' + t('rp_s_warnings')), ...(R.warnings.length ? R.warnings.map((w) => P(w)) : [P(t('rp_none'))]));
  const src = R.sources || ['fda', 'ema', 'sim'].map((k) => [t('rp_src_' + k + '_k'), t('rp_src_' + k)]);   // P6: own list for analyses
  b.push(H1('7. ' + t('rp_s_sources')), TABLE([[t('rp_topic'), t('rp_ref')], ...src]));
  b.push(H1('8. ' + t('rp_s_validation')), P(t('rp_validation_' + R.kind)));
  // Section 9 only where the link reproduces the result (simulation); analysis reports carry no
  // link, because the user's data never leave the browser (owner decision KK-71, FSR-LOG-01 G-122).
  if (R.link) b.push(H1('9. ' + t('rp_s_link')), P(t('rp_link_note')), P(R.link, { sz: 16 }));
  else if (R.veri) b.push(H1('9. ' + t('rp_s_data')), ...R.veri);   // FSR-TN-PLT-11 (KK-75)
  return docx(b.join(''), R.header, R.disclaimer_tr + ' · ' + R.disclaimer_en, R.images || []);
}

// download helper (no network request: an object URL of the bytes made here)
export function download(bytes, name) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(new Blob([bytes], { type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' }));
  a.download = name; a.click(); setTimeout(() => URL.revokeObjectURL(a.href), 1000);
}
export const stamp = (d = new Date()) => d.toISOString().replace(/[:.]/g, '-').slice(0, 19);
