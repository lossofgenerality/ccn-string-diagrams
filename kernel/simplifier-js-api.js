// ---------------- the editor's interface (hand-written, appended to the generated code) ----------------
// Mirrors Simplifier`payloadTrace, simplifyLDTrace and simplifyTermTrace of simplifier.wl: the same options,
// the same rule set for each mode (R.RULESETS, exported from Simplifier`ruleSet), the same 50-step limit.
const toWL = j => Array.isArray(j) ? j.map(toWL)
  : (j && typeof j === 'object') ? new R.Assoc(Object.entries(j).map(([k, v]) => [k, toWL(v)])) : j;
const fromWL = x => Array.isArray(x) ? x.map(fromWL)
  : x instanceof R.Assoc ? Object.fromEntries(x.entries().map(([k, v]) => [typeof k === 'string' ? k : R.inputForm(k), fromWL(v)]))
  : x instanceof R.Rat ? { n: x.n, d: x.d }
  : x instanceof R.Expr ? R.inputForm(x)
  : x instanceof R.Sym ? x.n : x;
const modeKey = o => [o.pivotal ? 'star' : 'vee', o.spherical ? 'sph' : '-', o.symmetric ? 'sym' : '-', o.ribbon ? 'rib' : '-',
  o.prefusion ? 'pre' : '-', o.rightFirst ? 'rf' : '-'].join('|');
function ruleSet(o) {
  const list = R.RULESETS.get(modeKey(o));
  if (!list) throw new Error('no rule set for mode ' + modeKey(o));
  return new R.Assoc(list.map(([name, kind, f]) => [name, [kind, f]]));
}
function withData(o, body) {          // Block[{pairings = …, inverses = …, retracts = …, lSimples = …}, body]
  const keep = { pairings: R.G.pairings, inverses: R.G.inverses, retracts: R.G.retracts, lSimples: R.G.lSimples, lBound: R.G.lBound };
  R.G.pairings = toWL(o.pairings || []); R.G.inverses = toWL(o.inverses || []); R.G.retracts = toWL(o.retracts || []);
  R.G.lSimples = toWL(o.simples || []);
  try { return body(); } finally { Object.assign(R.G, keep); }
}
const isLD = x => x instanceof R.Expr && x.h === 'LD';
// simplifyLDTrace: [["start", ld0], [rule, ld1], …], every step normalized
function simplifyLDTrace(ld, o = {}) {
  const rs = ruleSet(o), max = o.maxSteps || 50;
  return withData(o, () => {
    let l = R.F.normalize(ld); const steps = [['start', l]];
    while (steps.length < max) {
      const r = R.F.rewriteOnce(l, rs);
      if (!(Array.isArray(r) && typeof r[0] === 'string' && isLD(r[1]))) break;
      l = R.F.normalize(r[1]); steps.push([r[0], l]);
    }
    return steps;
  });
}
// simplifyTermTrace: one term of a Chapter 4 linear combination, <|c, sums, pairs, ld|>
function simplifyTermTrace(term, o = {}) {
  const rs = ruleSet(Object.assign({}, o, { prefusion: true }));
  return withData(o, () => R.F.lTrace(term, rs));
}
// payloadTrace: one request of the editor, as sent to the GraphicalCalculusKernel
function payloadTrace(j) {
  const ld = R.F.jsonToLD(toWL({ src: j.src, ls: j.ls }));
  const o = { pivotal: !!j.pivotal, spherical: !!j.spherical, symmetric: !!j.symmetric, ribbon: !!j.ribbon, rightFirst: !!j.rightFirst,
    pairings: j.pairings, inverses: j.inverses, retracts: j.retracts, simples: j.simples };
  if (j.prefusion && o.pivotal) {
    const pairs = Array.isArray(j.pairs) || !j.pairs ? new R.Assoc() : toWL(j.pairs);
    const term = R.B.Association(R.E('Rule', 'c', toWL(j.c)), R.E('Rule', 'sums', toWL(j.sums || [])), R.E('Rule', 'pairs', pairs), R.E('Rule', 'ld', ld));
    return simplifyTermTrace(term, o);
  }
  return simplifyLDTrace(ld, o);
}
// the reply format of the kernel: [[rule, {src, ls: [[a, name, ins, outs], …]}], …], terms with c, sums, pairs
function editorSteps(steps) {
  return steps.map(([rule, x]) => {
    if (isLD(x)) { const j = fromWL(R.F.ldToJSON(x)); return [rule, j]; }
    const ld = fromWL(R.F.ldToJSON(x.get('ld')));
    return [rule, { c: fromWL(x.get('c')), sums: fromWL(x.get('sums')), pairs: fromWL(x.get('pairs')), src: ld.src, ls: ld.ls }];
  });
}
const API = { R, toWL, fromWL, modeKey, ruleSet, simplifyLDTrace, simplifyTermTrace, payloadTrace,
  trace: j => editorSteps(payloadTrace(j)), ruleNames: o => R.RULESETS.get(modeKey(o)).map(r => r[0]) };
root.CCNSimplifierJS = API;
if (typeof module !== 'undefined') module.exports = API;
