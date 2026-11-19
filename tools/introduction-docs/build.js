const fs=require('fs'),path=require('path');
const md=require('markdown-it')({html:true,linkify:true}).use(require('markdown-it-texmath'),{engine:require('katex'),delimiters:'dollars',katexOptions:{throwOnError:false,strict:false}});
const src=fs.readFileSync('intro.md','utf8');
const body=md.render(src);
const kcss=path.resolve('node_modules/katex/dist/katex.min.css');
const html=`<!DOCTYPE html><html><head><meta charset="utf-8"><title>Introduction to CCN String Diagrams</title>
<link rel="stylesheet" href="file://${kcss}">
<style>
@page{size:A4;margin:18mm 16mm 18mm 16mm}
body{font-family:"Latin Modern Roman","DejaVu Math TeX Gyre","DejaVu Serif",serif;font-size:11pt;line-height:1.45;color:#1a1a1a;max-width:none}
h1{font-size:24pt;margin:0 0 6pt;color:#5a1d12} h2{font-size:16pt;color:#5a1d12;border-bottom:1px solid #d9c9bf;padding-bottom:3pt;margin-top:22pt;page-break-after:avoid}
h3{font-size:12.5pt;margin-top:16pt;page-break-after:avoid;color:#2b2b2b}
code{font-family:"DejaVu Sans Mono",monospace;font-size:9pt;background:#f6f2ee;padding:0 2px;border-radius:2px}
pre{background:#f6f2ee;padding:6pt 8pt;border-radius:4px;white-space:pre-wrap;word-break:break-word;page-break-inside:avoid}
pre code{background:none;padding:0}
img{display:block;max-width:100%;max-height:68mm;margin:6pt auto;page-break-inside:avoid}
table{border-collapse:collapse;font-size:9.5pt;margin:6pt 0} td,th{border:1px solid #d9c9bf;padding:3pt 5pt;vertical-align:top} th{background:#f6f2ee}
.katex-display{overflow:hidden;margin:6pt 0;font-size:0.92em} eqn{display:block;overflow:hidden}
a{color:#7a2a18}
section{page-break-inside:avoid}
hr{border:0;border-top:1px solid #d9c9bf;margin-top:24pt}
</style></head><body>${body}</body></html>`;
fs.writeFileSync('out/intro.html',html);
