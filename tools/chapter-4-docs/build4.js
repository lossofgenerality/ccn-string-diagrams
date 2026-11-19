const fs=require('fs'),path=require('path');
const md=require('markdown-it')({html:true,linkify:true}).use(require('markdown-it-texmath'),{engine:require('katex'),delimiters:'dollars',katexOptions:{throwOnError:false,strict:false}});
const pages=['index',...JSON.parse(fs.readFileSync('pages.json','utf8')).map(p=>p[0])];
const css=`body{font-family:"Latin Modern Roman","Cambria Math","DejaVu Serif",Georgia,serif;font-size:17px;line-height:1.5;color:#1a1a1a;max-width:960px;margin:24px auto;padding:0 18px}
h1{font-size:30px;color:#5a1d12;margin-bottom:6px} h2{font-size:22px;color:#5a1d12;border-bottom:1px solid #d9c9bf;padding-bottom:3px;margin-top:28px} h3{font-size:18px;margin-top:24px}
code{font-family:"DejaVu Sans Mono",Menlo,monospace;font-size:13px;background:#f6f2ee;padding:0 3px;border-radius:3px}
pre{background:#f6f2ee;padding:8px 10px;border-radius:5px;white-space:pre-wrap} pre code{background:none;padding:0}
img{display:block;max-width:100%;max-height:340px;margin:8px auto} table{border-collapse:collapse;font-size:15px;margin:8px 0} td,th{border:1px solid #d9c9bf;padding:4px 7px;vertical-align:top} th{background:#f6f2ee}
.katex-display{overflow-x:auto;overflow-y:hidden} a{color:#7a2a18} hr{border:0;border-top:1px solid #d9c9bf;margin-top:30px}`;
for (const p of pages) {
  const src=fs.readFileSync(p+'.md','utf8').replace(/\]\(([a-z0-9-]+)\.md\)/g,'](./$1.html)');
  const title=(src.match(/^# (.*)$/m)||[,'Chapter 4'])[1];
  const html=`<!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title} · CCN String Diagrams</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.11/dist/katex.min.css"><style>${css}</style></head><body>${md.render(src)}</body></html>`;
  fs.mkdirSync('out',{recursive:true}); fs.writeFileSync('out/'+p+'.html',html);
}
console.log(pages.length);
