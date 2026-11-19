const fs=require('fs'),path=require('path');const ROOT=path.join(__dirname,'..','..');const html=fs.readFileSync(path.join(ROOT,'string-diagram-editor.html'),'utf8');
eval(html.match(/<script id="core">([\s\S]*?)<\/script>/)[1]+';global.Core=Core');
const SIG=eval('({'+html.match(/const SIG = \{([\s\S]*?)\n\};/)[1]+'})');
const EX=eval('['+html.match(/const EX = \[([\s\S]*?)\n\];/)[1]+']');
const out=[];
for(const [t,src,sk,m] of EX){ if(m==='fus') continue; const piv=m!=='vee'&&m!=='sym'&&m!==undefined; Core.opts.pivotal=piv&&(m!=='vee'); 
 const S=Core.parseSig(SIG[sk]);
 src.split('=').forEach((x,i)=>{ const e=Core.parse(x.trim(),S.sig); const ld=Core.toLayered(e);
  if (ld.ls.some(l=>l.B.t==='swap')) return;
  out.push({title:t+' #'+i, text:x.trim(), sig:SIG[sk], duals:Core.opts.pivotal?'star':'vee', src:ld.src, ls:ld.ls.map(({a,B})=>{const ty=Core.typeOf(B);return [a,B.name,ty.dom,ty.cod];})}); });}
fs.writeFileSync('/mnt/user-data/outputs/editor-text-layered.json',JSON.stringify(out));console.log(out.length);
