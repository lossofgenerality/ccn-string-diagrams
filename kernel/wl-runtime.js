/* wl-runtime.js — a small Wolfram Language runtime for code translated by wl-to-js.wl
   CCN String Diagrams · By Dara O Shayda and Noor Hoshino (星野ヌール)
   © Computational Classnotes · CC BY-NC-SA 4.0

   The translator (wl-to-js.wl) turns the definitions of the Wolfram simplifier into JavaScript. The code it writes
   calls this runtime for everything the Wolfram language does implicitly: the data model, pattern matching,
   the built-in functions the simplifier uses, and applying a value as a function.

   Data model (Wolfram → JavaScript):
     "abc"            → JS string           True, False → true, false       Null → null
     17               → JS number           3/4  → Rat {n: 3, d: 4}
     {a, b}           → JS array            <|k -> v|> → Assoc (ordered, keys compared structurally)
     f[a, b]          → Expr {h: "f", a: [a, b]}   (inert data: LD, B, Subscript, OverTilde, Missing, …)
     unit, None, $Failed, All … → Sym, interned, compared by identity
     Function[…]      → JS function          a definition of the engine → F[name] (see R.apply)
     a sequence x___  → Seq, spliced into the list or call it appears in
   Values are never mutated: every built-in returns a new value, as in Wolfram. */
'use strict';
(function (root) {
  const R = {};

  // ---------------- data model ----------------
  class Sym { constructor(n) { this.n = n; } toString() { return this.n; } }
  const SYMS = new Map();
  const sym = n => { let s = SYMS.get(n); if (!s) { s = new Sym(n); SYMS.set(n, s); } return s; };
  class Expr { constructor(h, a) { this.h = h; this.a = a; } }
  class Rat { constructor(n, d) { this.n = n; this.d = d; } }
  class Seq { constructor(items) { this.items = items; } }
  class Assoc {
    constructor(entries) { this.m = new Map(); if (entries) for (const [k, v] of entries) this.m.set(key(k), [k, v]); }
    get size() { return this.m.size; }
    has(k) { return this.m.has(key(k)); }
    get(k) { const e = this.m.get(key(k)); return e ? e[1] : undefined; }
    put(k, v) { const a = new Assoc(); a.m = new Map(this.m); a.m.set(key(k), [k, v]); return a; }
    drop(k) { const a = new Assoc(); a.m = new Map(this.m); a.m.delete(key(k)); return a; }
    entries() { return [...this.m.values()]; }
  }
  const FAILED = sym('$Failed'), NONE = sym('None');
  Object.assign(R, { Sym, sym, Expr, Rat, Seq, Assoc, FAILED, NONE });
  const E = (h, ...a) => new Expr(h, a);
  R.E = E;

  // structural key: equal keys ⇔ SameQ
  function key(x) {
    if (typeof x === 'string') return 's' + JSON.stringify(x);
    if (typeof x === 'number') return 'n' + x;
    if (typeof x === 'boolean') return x ? 'T' : 'F';
    if (x === null || x === undefined) return 'N';
    if (x instanceof Sym) return 'y' + x.n;
    if (x instanceof Rat) return 'r' + x.n + '/' + x.d;
    if (Array.isArray(x)) return '{' + x.map(key).join(',') + '}';
    if (x instanceof Expr) return x.h + '[' + x.a.map(key).join(',') + ']';
    if (x instanceof Assoc) return '<|' + x.entries().map(([k, v]) => key(k) + '>' + key(v)).join(',') + '|>';
    if (typeof x === 'function') return 'fn' + (x.__id || (x.__id = ++fnId));
    return '?' + String(x);
  }
  let fnId = 0;
  R.key = key;
  const sameQ = (a, b) => a === b || key(a) === key(b);
  R.sameQ = sameQ;

  function headName(x) {
    if (typeof x === 'string') return 'String';
    if (typeof x === 'number') return Number.isInteger(x) ? 'Integer' : 'Real';
    if (x instanceof Rat) return 'Rational';
    if (Array.isArray(x)) return 'List';
    if (x instanceof Assoc) return 'Association';
    if (x instanceof Expr) return x.h;
    if (typeof x === 'function') return 'Function';
    return 'Symbol';
  }
  R.headName = headName;

  // ---------------- signals ----------------
  class ThrowSig { constructor(v) { this.v = v; } }
  class RetSig { constructor(v) { this.v = v; } }
  const BREAK = { brk: true };
  R.ThrowSig = ThrowSig; R.RetSig = RetSig; R.BREAK = BREAK;
  R.throw_ = v => { throw new ThrowSig(v); };
  R.return_ = v => { throw new RetSig(v); };
  R.break_ = () => { throw BREAK; };
  R.catch_ = f => { try { return f(); } catch (e) { if (e instanceof ThrowSig) return e.v; throw e; } };

  // ---------------- sequences, lists, calls ----------------
  const splice = xs => { if (!xs.some(x => x instanceof Seq)) return xs; const o = []; for (const x of xs) x instanceof Seq ? o.push(...x.items) : o.push(x); return o; };
  R.list = (...xs) => splice(xs);
  R.F = {};      // engine functions (filled by the generated code)
  R.SUB = {};    // definitions of the form f[a][b] (SubValues)
  R.G = {};      // global variables of the engine (pairings, inverses, retracts, lSimples, lBound, constants)
  R.B = {};      // built-in functions
  function apply(f, args) {
    args = splice(args);
    if (typeof f === 'function') return f(...args);
    if (f instanceof Sym) {
      if (R.F[f.n]) return R.F[f.n](...args);
      if (R.B[f.n]) return R.B[f.n](...args);
      return new Expr(f.n, args);
    }
    if (f instanceof Expr && R.SUB[f.h]) return R.SUB[f.h](f.a, args);
    if (f instanceof Assoc) { const v = f.get(args[0]); return v === undefined ? E('Missing', 'KeyAbsent', args[0]) : v; }
    throw new Error('cannot apply ' + key(f));
  }
  R.apply = apply;
  R.call = (name, args) => apply(sym(name), args);
  const truthy = x => x === true;
  R.truthy = truthy;

  // a definition: try its clauses in order; a clause returns R.NO when it does not apply
  const NO = { no: true };
  R.NO = NO;
  R.defn = (name, clauses) => {
    const f = (...args) => {
      for (const c of clauses) {
        let r;
        try { r = c(args); } catch (e) { if (e instanceof RetSig) return e.v; throw e; }
        if (r !== NO) return r;
      }
      return new Expr(name, args);
    };
    f.clauses = clauses;
    return f;
  };
  R.addClause = (f, name, clause) => R.defn(name, [...((f && f.clauses) || []), clause]);
  R.subDefn = (name, clauses) => (heads, args) => {
    for (const c of clauses) {
      let r;
      try { r = c([...heads, ...args]); } catch (e) { if (e instanceof RetSig) return e.v; throw e; }
      if (r !== NO) return r;
    }
    return new Expr(name, args);
  };
  R.callF = (name, args) => { args = splice(args); const f = R.F[name]; return f ? f(...args) : new Expr(name, args); };
  R.callB = (name, args) => { const f = R.B[name]; if (!f) throw new Error('built-in ' + name + ' is not in wl-runtime.js'); return f(...splice(args)); };

  // ---------------- pattern matching ----------------
  // Patterns are ordinary values: Expr with heads Blank, BlankSequence, BlankNullSequence, Pattern, PatternTest,
  // Condition (second argument: a JS function of the bindings), Alternatives, HoldPattern.
  const PH = new Set(['Blank', 'BlankSequence', 'BlankNullSequence', 'Pattern', 'PatternTest', 'Condition', 'Alternatives', 'HoldPattern']);
  function hasPattern(p) {
    if (p instanceof Expr) return PH.has(p.h) || p.a.some(hasPattern);
    if (Array.isArray(p)) return p.some(hasPattern);
    return false;
  }
  const isSeqPat = p => p instanceof Expr && (p.h === 'BlankSequence' || p.h === 'BlankNullSequence' || (p.h === 'Pattern' && isSeqPat(p.a[1])) || (p.h === 'PatternTest' && isSeqPat(p.a[0])));
  const blankOK = (p, v) => p.a.length === 0 || headName(v) === p.a[0].n;
  function bind(env, name, v) {
    if (Object.prototype.hasOwnProperty.call(env, name)) return sameQ(env[name], v) ? env : null;
    const e = Object.assign({}, env); e[name] = v; return e;
  }
  function match(p, v, env) {
    if (p instanceof Expr) {
      switch (p.h) {
        case 'Blank': return blankOK(p, v) ? env : null;
        case 'Pattern': { const e = match(p.a[1], v, env); return e && bind(e, p.a[0].n, v); }
        case 'PatternTest': { const e = match(p.a[0], v, env); return e && truthy(apply(p.a[1], [v])) ? e : null; }
        case 'Condition': { const e = match(p.a[0], v, env); return e && truthy(p.a[1](e)) ? e : null; }
        case 'Alternatives': for (const q of p.a) { const e = match(q, v, env); if (e) return e; } return null;
        case 'HoldPattern': return match(p.a[0], v, env);
        case 'BlankSequence': case 'BlankNullSequence': return null;
      }
      if (!hasPattern(p)) return sameQ(p, v) ? env : null;
      if (!(v instanceof Expr) || v.h !== p.h) return null;
      return matchSeq(p.a, 0, v.a, 0, env);
    }
    if (Array.isArray(p)) {
      if (!hasPattern(p)) return sameQ(p, v) ? env : null;
      if (!Array.isArray(v)) return null;
      return matchSeq(p, 0, v, 0, env);
    }
    return sameQ(p, v) ? env : null;
  }
  // match a sequence of patterns against a sequence of values, with backtracking over sequence patterns
  function matchSeq(ps, i, vs, j, env) {
    if (i === ps.length) return j === vs.length ? env : null;
    const p = ps[i];
    if (isSeqPat(p)) {
      const min = seqMin(p);
      for (let k = vs.length; k >= j + min; k--) {
        const part = vs.slice(j, k);
        const e = matchSeqPat(p, part, env);
        if (e) { const r = matchSeq(ps, i + 1, vs, k, e); if (r) return r; }
      }
      return null;
    }
    if (j >= vs.length) return null;
    const e = match(p, vs[j], env);
    return e && matchSeq(ps, i + 1, vs, j + 1, e);
  }
  const seqMin = p => p.h === 'Pattern' ? seqMin(p.a[1]) : p.h === 'PatternTest' ? seqMin(p.a[0]) : (p.h === 'BlankSequence' ? 1 : 0);
  function matchSeqPat(p, part, env) {
    if (p.h === 'Pattern') { const e = matchSeqPat(p.a[1], part, env); return e && bind(e, p.a[0].n, new Seq(part)); }
    if (p.h === 'PatternTest') { const e = matchSeqPat(p.a[0], part, env); return e && part.every(x => truthy(apply(p.a[1], [x]))) ? e : null; }
    return part.every(x => blankOK(p, x)) ? env : null;
  }
  R.match = match;
  R.matchArgs = (ps, args) => matchSeq(ps, 0, args, 0, {});
  R.matchQ = (v, p) => match(p, v, {}) !== null;

  // ---------------- numbers ----------------
  const gcd = (a, b) => { a = Math.abs(a); b = Math.abs(b); while (b) [a, b] = [b, a % b]; return a; };
  const rat = (n, d) => { if (d < 0) { n = -n; d = -d; } const g = gcd(n, d) || 1; n /= g; d /= g; return d === 1 ? n : new Rat(n, d); };
  const nd = x => x instanceof Rat ? [x.n, x.d] : [x, 1];
  const isNum = x => typeof x === 'number' || x instanceof Rat;
  function plus(...xs) {
    if (!xs.every(isNum)) throw new Error('Plus of ' + xs.map(key).join(', '));
    let [n, d] = [0, 1]; for (const x of xs) { const [a, b] = nd(x); [n, d] = [n * b + a * d, d * b]; } return rat(n, d);
  }
  function times(...xs) {
    if (!xs.every(isNum)) throw new Error('Times of ' + xs.map(key).join(', '));
    let [n, d] = [1, 1]; for (const x of xs) { const [a, b] = nd(x); n *= a; d *= b; } return rat(n, d);
  }
  function power(x, p) {
    if (!isNum(x) || typeof p !== 'number' || !Number.isInteger(p)) throw new Error('Power');
    const [a, b] = nd(x); return p >= 0 ? rat(a ** p, b ** p) : rat(b ** -p, a ** -p);
  }
  const num = x => { const [a, b] = nd(x); return a / b; };
  const eq2 = (a, b) => isNum(a) && isNum(b) ? num(a) === num(b) : sameQ(a, b);
  Object.assign(R, { plus, times, power });

  // ---------------- strings ----------------
  const cps = s => Array.from(s);   // Wolfram counts characters (code points), not UTF-16 units
  const reEsc = s => s.replace(/[.*+?^${}()|[\]\\\/]/g, '\\$&');
  // a string pattern as a regular expression source; named Pattern[] parts become named groups
  function sre(p) {
    if (typeof p === 'string') return reEsc(p);
    if (p instanceof Expr) {
      switch (p.h) {
        case 'RegularExpression': return '(?:' + p.a[0] + ')';
        case 'StringExpression': return p.a.map(sre).join('');
        case 'Alternatives': return '(?:' + p.a.map(sre).join('|') + ')';
        case 'Pattern': return '(?<' + p.a[0].n + '>' + sre(p.a[1]) + ')';
        case 'Blank': return '[\\s\\S]';
        case 'BlankSequence': return '[\\s\\S]+';
        case 'BlankNullSequence': return '[\\s\\S]*';
      }
    }
    throw new Error('string pattern ' + key(p));
  }
  const groupsEnv = m => Object.assign({}, m.groups || {});
  // the right side of a string rule: a value with $1, $2 … in its strings, or a JS function of the bindings
  function srhs(rhs, m) {
    if (typeof rhs === 'function') return rhs(groupsEnv(m));
    const sub = x => typeof x === 'string' ? x.replace(/\$(\d+)/g, (_, d) => m[+d] ?? '') : Array.isArray(x) ? x.map(sub) : x;
    return sub(rhs);
  }
  const ruleParts = r => { if (r instanceof Expr && (r.h === 'Rule' || r.h === 'RuleDelayed')) return [r.a[0], r.a[1]]; throw new Error('rule ' + key(r)); };
  R.sre = sre;

  // ---------------- printing (ToString[x, InputForm]) ----------------
  function inputForm(x) {
    if (typeof x === 'string') return JSON.stringify(x).replace(/\\u([0-9a-f]{4})/gi, (_, h) => String.fromCharCode(parseInt(h, 16)));
    if (typeof x === 'number') return String(x);
    if (typeof x === 'boolean') return x ? 'True' : 'False';
    if (x === null) return 'Null';
    if (x instanceof Sym) return x.n;
    if (x instanceof Rat) return x.n + '/' + x.d;
    if (Array.isArray(x)) return '{' + x.map(inputForm).join(', ') + '}';
    if (x instanceof Expr) return x.h + '[' + x.a.map(inputForm).join(', ') + ']';
    if (x instanceof Assoc) return '<|' + x.entries().map(([k, v]) => inputForm(k) + ' -> ' + inputForm(v)).join(', ') + '|>';
    return String(x);
  }
  R.inputForm = inputForm;

  // ---------------- parts ----------------
  function partOne(x, i) {
    if (i instanceof Expr && i.h === 'Span') {
      const xs = x instanceof Expr ? x.a : x, n = xs.length;
      const a = i.a[0] < 0 ? n + i.a[0] + 1 : i.a[0], b = i.a[1] instanceof Sym ? n : (i.a[1] < 0 ? n + i.a[1] + 1 : i.a[1]);
      const r = xs.slice(a - 1, b); return x instanceof Expr ? new Expr(x.h, r) : r;
    }
    if (x instanceof Assoc) { const v = x.get(i); if (v === undefined) throw new Error('Part key ' + key(i)); return v; }
    const xs = x instanceof Expr ? x.a : x;
    if (!Array.isArray(xs)) throw new Error('Part of ' + key(x));
    if (i === 0) return x instanceof Expr ? sym(x.h) : sym('List');
    const k = i < 0 ? xs.length + i : i - 1;
    if (k < 0 || k >= xs.length) throw new Error('Part ' + i + ' of ' + key(x));
    return xs[k];
  }
  R.part = (x, ...is) => is.reduce(partOne, x);

  // ---------------- iteration helpers for Do and Table ----------------
  // an iterator spec, already evaluated: [n] | [lo, hi] | [lo, hi, step] | [list]
  R.iter = spec => {
    if (spec.length === 1) { const v = spec[0]; if (Array.isArray(v)) return v; const o = []; for (let k = 1; k <= v; k++) o.push(k); return o; }
    const [lo, hi, st = 1] = spec; const o = []; for (let k = lo; st > 0 ? k <= hi : k >= hi; k += st) o.push(k); return o;
  };

  // ---------------- built-in functions ----------------
  const B = R.B;
  const fail = (n, args) => { throw new Error('built-in ' + n + ' not supported for ' + args.map(key).join(', ')); };
  const ls = x => x instanceof Expr ? x.a : x;
  Object.assign(B, {
    Plus: plus, Times: times, Power: power,
    Equal: (...xs) => xs.every((x, i) => i === 0 || eq2(xs[i - 1], x)),
    Unequal: (a, b) => !eq2(a, b),
    Less: (...xs) => xs.every((x, i) => i === 0 || num(xs[i - 1]) < num(x)),
    LessEqual: (...xs) => xs.every((x, i) => i === 0 || num(xs[i - 1]) <= num(x)),
    Greater: (...xs) => xs.every((x, i) => i === 0 || num(xs[i - 1]) > num(x)),
    GreaterEqual: (...xs) => xs.every((x, i) => i === 0 || num(xs[i - 1]) >= num(x)),
    SameQ: (...xs) => xs.every((x, i) => i === 0 || sameQ(xs[i - 1], x)),
    UnsameQ: (a, b) => !sameQ(a, b),
    Not: x => !truthy(x),
    Min: (...xs) => { xs = xs.flat(Infinity); return xs.reduce((a, b) => num(b) < num(a) ? b : a); },
    Max: (...xs) => { xs = xs.flat(Infinity); return xs.reduce((a, b) => num(b) > num(a) ? b : a); },
    Numerator: x => nd(x)[0], Denominator: x => nd(x)[1],
    Length: x => x instanceof Assoc ? x.size : Array.isArray(x) ? x.length : x instanceof Expr ? x.a.length : 0,
    First: x => R.part(x, 1), Last: x => R.part(x, -1),
    Rest: x => ls(x).slice(1), Most: x => ls(x).slice(0, -1),
    Reverse: x => [...x].reverse(),
    RotateLeft: (x, n = 1) => { const k = ((n % x.length) + x.length) % x.length; return [...x.slice(k), ...x.slice(0, k)]; },
    Range: (a, b, s) => b === undefined ? R.iter([a]) : R.iter(s === undefined ? [a, b] : [a, b, s]),
    Take: (x, n) => Array.isArray(n) ? R.part(x, E('Span', n[0], n[1])) : n >= 0 ? x.slice(0, n) : x.slice(x.length + n),
    Drop: (x, n) => Array.isArray(n) ? x.filter((_, i) => i !== (n[0] < 0 ? x.length + n[0] : n[0] - 1)) : n >= 0 ? x.slice(n) : x.slice(0, x.length + n),
    Delete: (x, pos) => { const ks = new Set((Array.isArray(pos[0]) ? pos : [pos]).map(p => p[0] < 0 ? x.length + p[0] : p[0] - 1)); return x.filter((_, i) => !ks.has(i)); },
    Join: (...xs) => xs[0] instanceof Assoc ? xs.reduce((a, b) => b.entries().reduce((c, [k, v]) => c.put(k, v), a)) : [].concat(...xs.map(ls)),
    Append: (x, v) => x instanceof Assoc ? (Array.isArray(v) ? v : [v]).reduce((a, r) => { const [k, w] = ruleParts(r); return a.put(k, w); }, x) : [...x, v],
    Prepend: (x, v) => [v, ...x],
    Flatten: x => x.flat(Infinity),
    Map: (f, x) => x instanceof Assoc ? new Assoc(x.entries().map(([k, v]) => [k, apply(f, [v])])) : ls(x).map(v => apply(f, [v])),
    MapIndexed: (f, x) => x.map((v, i) => apply(f, [v, [i + 1]])),
    MapThread: (f, xs) => xs[0].map((_, i) => apply(f, xs.map(l => l[i]))),
    Apply: (f, x) => apply(f, ls(x)),
    Scan: (f, x) => { for (const v of ls(x)) apply(f, [v]); return null; },
    Select: (x, f) => x.filter(v => truthy(apply(f, [v]))),
    SelectFirst: (x, f) => { for (const v of x) if (truthy(apply(f, [v]))) return v; return E('Missing', 'NotFound'); },
    AllTrue: (x, f) => x.every(v => truthy(apply(f, [v]))),
    Fold: (f, x, l) => l.reduce((a, v) => apply(f, [a, v]), x),
    FoldList: (f, x, l) => { const o = [x]; let a = x; for (const v of l) { a = apply(f, [a, v]); o.push(a); } return o; },
    FixedPoint: (f, x, n = Infinity) => { let a = x; for (let k = 0; k < n; k++) { const b = apply(f, [a]); if (sameQ(a, b)) return b; a = b; } return a; },
    DeleteDuplicates: x => { const seen = new Set(); return x.filter(v => { const k = key(v); if (seen.has(k)) return false; seen.add(k); return true; }); },
    DeleteCases: (x, p) => x.filter(v => !R.matchQ(v, p)),
    Complement: (x, ...ys) => { const out = new Set(ys.flat().map(key)); const r = B.DeleteDuplicates(x.filter(v => !out.has(key(v)))); return r.sort((a, b) => num(a) - num(b)); },
    MemberQ: (x, p) => ls(x).some(v => R.matchQ(v, p)),
    MatchQ: (v, p) => R.matchQ(v, p),
    FreeQ: (x, p) => { const walk = v => R.matchQ(v, p) || (Array.isArray(v) ? v.some(walk) : v instanceof Expr ? v.a.some(walk) : false); return !walk(x); },
    Replace: (v, rules) => { for (const r of Array.isArray(rules) ? rules : [rules]) { const [p, rhs] = ruleParts(r); const e = match(p, v, {}); if (e) return typeof rhs === 'function' && r.h === 'RuleDelayed' ? rhs(e) : rhs; } return v; },
    FirstPosition: (x, p, def = E('Missing', 'NotFound')) => { const i = x.findIndex(v => R.matchQ(v, p)); return i < 0 ? def : [i + 1]; },
    OrderedQ: (x, f) => x.every((v, i) => i === 0 || (f ? truthy(apply(f, [x[i - 1], v])) : key(x[i - 1]) <= key(v))),
    // associations
    Association: (...rs) => new Assoc(splice(rs).flatMap(r => r instanceof Assoc ? r.entries() : [ruleParts(r)])),
    Keys: a => a.entries().map(e => e[0]),
    Lookup: (a, k, d) => { const v = a.get(k); return v === undefined ? (d === undefined ? E('Missing', 'KeyAbsent', k) : d) : v; },
    KeyDrop: (a, ks) => (Array.isArray(ks) ? ks : [ks]).reduce((b, k) => b.drop(k), a),
    KeyExistsQ: (a, k) => a.has(k),
    KeyValueMap: (f, a) => a.entries().map(([k, v]) => apply(f, [k, v])),
    // predicates
    StringQ: x => typeof x === 'string', MissingQ: x => x instanceof Expr && x.h === 'Missing',
    // strings
    StringJoin: (...xs) => splice(xs).flat(Infinity).join(''),
    StringLength: s => cps(s).length,
    StringTake: (s, n) => { const c = cps(s); if (Array.isArray(n)) { const a = n[0] < 0 ? c.length + n[0] + 1 : n[0], b = n[1] < 0 ? c.length + n[1] + 1 : n[1]; return c.slice(a - 1, b).join(''); } return (n >= 0 ? c.slice(0, n) : c.slice(c.length + n)).join(''); },
    StringDrop: (s, n) => { const c = cps(s); return (n >= 0 ? c.slice(n) : c.slice(0, c.length + n)).join(''); },
    StringStartsQ: (s, p) => new RegExp('^' + sre(p)).test(s),
    StringEndsQ: (s, p) => new RegExp(sre(p) + '$').test(s),
    StringContainsQ: (s, p) => new RegExp(sre(p)).test(s),
    StringMatchQ: (s, p) => new RegExp('^(?:' + sre(p) + ')$').test(s),
    StringRiffle: (xs, sep = ' ') => xs.join(sep),
    StringSplit: (s, sep, n) => {
      if (sep === undefined) return s.split(/\s+/).filter(x => x !== '');
      const re = new RegExp(sre(sep));
      let parts;
      if (typeof n === 'number') { parts = []; let rest = s; while (parts.length < n - 1) { const m = rest.match(re); if (!m) break; parts.push(rest.slice(0, m.index)); rest = rest.slice(m.index + m[0].length); } parts.push(rest); }
      else parts = s.split(new RegExp(sre(sep), 'g'));
      if (n instanceof Sym && n.n === 'All') return parts;
      while (parts.length && parts[0] === '') parts.shift();
      while (parts.length && parts[parts.length - 1] === '') parts.pop();
      return parts;
    },
    StringTrim: (s, p) => p === undefined ? s.trim() : s.replace(new RegExp('^' + sre(p)), '').replace(new RegExp(sre(p) + '$'), ''),
    StringReplace: (s, rules) => {
      for (const r of Array.isArray(rules) ? rules : [rules]) {
        const [p, rhs] = ruleParts(r);
        s = s.replace(new RegExp(sre(p), 'g'), (...m) => { const groups = typeof m[m.length - 1] === 'object' ? m[m.length - 1] : undefined; const mm = m.slice(0, -2 - (groups ? 1 : 0)); mm.groups = groups; return srhs(rhs, mm); });
        if (!Array.isArray(rules) || rules.length > 1) { /* several rules: applied one after another (the engine uses one) */ }
      }
      return s;
    },
    StringCases: (s, r) => { const [p, rhs] = r instanceof Expr && (r.h === 'Rule' || r.h === 'RuleDelayed') ? ruleParts(r) : [r, '$0']; const out = []; for (const m of s.matchAll(new RegExp(sre(p), 'g'))) out.push(rhs === '$0' ? m[0] : srhs(rhs, m)); return out; },
    StringPosition: (s, p) => { const out = []; const c = s; for (const m of c.matchAll(new RegExp(sre(p), 'g'))) { const a = cps(c.slice(0, m.index)).length + 1; out.push([a, a + cps(m[0]).length - 1]); } return out; },
    ToCharacterCode: (s, enc) => enc === 'UTF-16' ? [...s].flatMap(ch => { const o = []; for (let i = 0; i < ch.length; i++) o.push(ch.charCodeAt(i)); return o; }) : cps(s).map(ch => ch.codePointAt(0)),
    ToString: (x, form) => typeof x === 'string' && !form ? x : (form ? inputForm(x) : (typeof x === 'number' ? String(x) : inputForm(x))),
    Print: (...xs) => { console.log(...xs.map(x => typeof x === 'string' ? x : inputForm(x))); return null; },
  });
  // constructors that stay as data
  for (const h of ['Subscript', 'Superscript', 'OverTilde', 'RegularExpression', 'Rule', 'Missing', 'StringExpression', 'Alternatives', 'Blank', 'BlankSequence', 'BlankNullSequence', 'Pattern', 'PatternTest', 'HoldPattern', 'Span'])
    if (!B[h]) B[h] = (...a) => new Expr(h, splice(a));

  root.WLRuntime = R;
  if (typeof module !== 'undefined') module.exports = R;
})(typeof globalThis !== 'undefined' ? globalThis : this);
