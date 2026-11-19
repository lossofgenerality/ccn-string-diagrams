// test-generated.js — run the JavaScript simplifier translated from Wolfram on the recorded editor requests.
// Compares, for each request, the rule sequence with the editor's own JavaScript (field js) and with the Wolfram
// kernel, and the final form with the Wolfram kernel's (wolfram-finals-2.1-4.json).
// CCN String Diagrams · By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0
const path = require('path'), fs = require('fs');
const dir = path.resolve(process.argv[2] && !process.argv[2].startsWith('--') ? process.argv[2] : __dirname);
// each file is looked for in the folder given, its parent, and its tests/ subfolder
const find = f => [dir, path.join(dir, '..'), path.join(dir, 'tests')].map(d => path.join(d, f)).find(p => fs.existsSync(p));
const S = require(find('simplifier-generated.js'));
const req = JSON.parse(fs.readFileSync(find('editor-requests-2.1-4.json'), 'utf8'));
const wf = JSON.parse(fs.readFileSync(find('wolfram-finals-2.1-4.json'), 'utf8'));
const canon = x => JSON.stringify(x, (k, v) => (v && typeof v === 'object' && !Array.isArray(v)) ? Object.fromEntries(Object.entries(v).sort()) : v);
let okRules = 0, okFinal = 0, errors = 0; const bad = [];
const t0 = Date.now();
req.forEach((r, i) => {
  try {
    const steps = S.trace(r.payload);
    const rules = steps.slice(1).map(s => s[0]);
    const sameRules = canon(rules) === canon(r.js);
    if (sameRules) okRules++;
    const last = steps[steps.length - 1][1];
    const mine = last.ls !== undefined && last.c === undefined ? { src: last.src, ls: last.ls } : { c: last.c, sums: last.sums, pairs: last.pairs, ld: { src: last.src, ls: last.ls } };
    const sameFinal = canon(mine) === canon(wf[i].final);
    if (sameFinal) okFinal++;
    if (!sameRules || !sameFinal) bad.push({ i: i + 1, title: r.title, rules, expected: r.js, final: sameFinal ? 'same' : { js: mine, wolfram: wf[i].final } });
  } catch (e) { errors++; bad.push({ i: i + 1, title: r.title, error: String(e && e.stack || e).split('\n').slice(0, 4).join(' | ') }); }
});
console.log(JSON.stringify({ requests: req.length, sameRules: okRules, sameFinal: okFinal, errors, ms: Date.now() - t0 }));
if (process.argv.includes('--show')) console.log(JSON.stringify(bad.slice(0, +process.argv[process.argv.indexOf('--show') + 1] || 5), null, 1));
