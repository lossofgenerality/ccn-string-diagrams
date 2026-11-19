const fs=require('fs');const html=fs.readFileSync('/home/claude/ccn-string-diagrams/string-diagram-editor.html','utf8');
eval(html.match(/<script id="core">([\s\S]*?)<\/script>/)[1]+';global.Core=Core');
Core.opts.pivotal=true;
const run=(sigT, src)=>{ const S=Core.parseSig(sigT); if(S.errs.length) console.log(S.errs);
  const sides=src.split('=').map(x=>Core.parseLin(x.trim(),S));
  const rs=sides.map(pts=>Core.simplifyLin(pts,S,{pairings:S.pairings}));
  rs.forEach((r,i)=>{ console.log(' side',i, r.traces.map(t=>t.steps.map(s=>s.rule).join(' → ')).join(' | '), '  ⇒ ', Core.linText(r.terms)); });
  console.log(rs.every(r=>r.key===rs[0].key)?'  ✓':'  ✗', '\n');
};
module.exports=run;
if (require.main===module){
 const sig='simple i j\npartition α : X → i\npartition β : X → 𝟙\nf : 𝟙 → X\ng : X → 𝟙\nh : i → i';
 run(sig,'p_α q_α = N^i_X id_i');
 run(sig,'∑_i q_α p_α = id_X');
 run(sig,'q_β p_β f = f');
 run(sig,'g q_β p_β = g');
 run(sig,'ev_X coev~_X = ∑_i ev_X(id_X* ⊗ q_α p_α)coev~_X = ∑_i ev_i(id_i* ⊗ p_α q_α)coev~_i = ∑_i N^i_X ev_i coev~_i = ∑_i dim_l(i) N^i_X');
 run(sig,'h = dim_l(i)⁻¹ (id_i ⊗ ev_i(id_i* ⊗ h)coev~_i)');
 run(sig,'dim_l(i) ev~_i(h ⊗ id_i*)coev_i = dim_r(i) ev_i(id_i* ⊗ h)coev~_i');
 run(sig,'ev~_i(id_i ⊗ ev_i ⊗ id_i*)(coev_i ⊗ coev_i) = ev~_i coev_i = dim_r(i)');
}
