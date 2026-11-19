const fs=require('fs');const html=fs.readFileSync(process.argv[2],'utf8');
eval(html.match(/<script id="core">([\s\S]*?)<\/script>/)[1]+';global.Core=Core');
const SIG=eval('({'+html.match(/const SIG = \{([\s\S]*?)\n\};/)[1]+'})');
const EX=eval('['+html.match(/const EX = \[([\s\S]*?)\n\];/)[1]+']');
const out=[];
const lsOf=ld=>ld.ls.map(({a,B})=>{const ty=Core.typeOf(B);return {a,name:B.t==='swap'?'__σ_'+B.a.length:B.name,ins:ty.dom,outs:ty.cod};});
for(const [t,src,sk,m] of EX){ const fus=m==='fus'; const piv=m==='star'||m==='sph'||m==='symstar'||m==='rib'||fus; Core.opts.pivotal=piv; Core.opts.spherical=m==='sph'; Core.opts.ribbon=m==='rib'; Core.opts.prefusion=fus; Core.opts.symmetric=m==='sym'||m==='symstar'; const S=Core.parseSig(SIG[sk]);
 src.split('=').forEach((x,i)=>{
  for (const rf of [false,true]) {
   const base={pairings:S.pairings,inverses:S.inverses,retracts:S.retracts,rightFirst:rf,pivotal:piv,spherical:m==='sph'||m==='rib',ribbon:m==='rib',symmetric:m==='sym'||m==='symstar'};
   if (!fus) { const e=Core.parse(x,S.sig); const ld=Core.toLayered(e); const r=Core.simplifyTrace(e,{pairings:S.pairings,inverses:S.inverses,retracts:S.retracts,rightFirst:rf});
     out.push({title:t+' #'+i+(rf?' rf':''), js:r.steps.map(s=>s.rule).slice(1), payload:{...base,src:ld.src,ls:lsOf(ld)}}); }
   else { const pts=Core.parseLin(x.trim(),S); const r=Core.simplifyLin(pts,S,{pairings:S.pairings,rightFirst:rf}); const terms=Core.termsOf(pts,S);
     terms.forEach((tm,j)=>{ out.push({title:t+' #'+i+'.'+j+(rf?' rf':''), js:r.traces[j].steps.map(s=>s.rule).slice(1),
       jsFinal:(({c,sums,pairs,ld})=>({c,sums,pairs,src:ld.src,ls:lsOf(ld).map(l=>[l.a,l.name,l.ins,l.outs])}))(r.traces[j].term),
       payload:{...base,prefusion:true,simples:S.simples,c:tm.c,sums:tm.sums,pairs:tm.pairs,src:tm.ld.src,ls:lsOf(tm.ld)}}); }); }
  }});}
fs.writeFileSync(process.argv[3],JSON.stringify(out));console.log(out.length, out.filter(o=>o.payload.prefusion).length);
