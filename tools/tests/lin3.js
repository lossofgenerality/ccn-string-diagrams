const fs=require('fs');const html=fs.readFileSync('/home/claude/ccn-string-diagrams/string-diagram-editor.html','utf8');
eval(html.match(/<script id="core">([\s\S]*?)<\/script>/)[1]+';global.Core=Core');
const SIG=eval('({'+html.match(/const SIG = \{([\s\S]*?)\n\};/)[1]+'})');
const EX=eval('['+html.match(/const EX = \[([\s\S]*?)\n\];/)[1]+']');
for (const [t,src,sk,m] of EX) { if (m!=='fus') continue; Core.opts.pivotal=true; Core.opts.prefusion=true; const S=Core.parseSig(SIG[sk]);
  try { const rs=src.split('=').map(x=>Core.simplifyLin(Core.parseLin(x.trim(),S),S,{pairings:S.pairings}));
  const ok=rs.every(r=>r.key===rs[0].key); console.log(ok?'✓':'✗', t); if(!ok) rs.forEach(r=>console.log('    ',r.traces.map(tr=>tr.steps.map(s=>s.rule).join('→')).join(' | '),' ⇒ ',Core.linText(r.terms)));
  } catch(e){ console.log('ERR',t,e.message); } }
