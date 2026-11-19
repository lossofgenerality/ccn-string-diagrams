import re
pkg = open('/home/claude/p4/fusion-4.wl').read()
parts = re.split(r'\(\* ::Section:: \*\)\n', pkg)
secs = []
for p in parts[1:]:
    m = re.match(r'\(\* (.*?) \*\)\n', p); title = m.group(1); body = p[m.end():]
    t = re.match(r'\s*\(\* (.*?) \*\)\n', body, re.S); text = ''
    if t: text = t.group(1); body = body[t.end():]
    body = body.replace('(* © Computational Classnotes · CC BY-NC-SA 4.0 *)', '').strip()
    secs.append((title, text, body))


setup = r"""ClearAll["Global`*"];
(* the engine (sections 0–19 give LD, B and rows), all in this folder *)
dir = FileNameJoin[{$HomeDirectory, "Desktop", "Research", "Monoidal Graphical Calculus"}];
With[{cells = Cases[Get[FileNameJoin[{dir, "graphical-calculus-2.1-simplify.nb"}]], Cell[c_, "Input" | "Code", ___] :> c, Infinity]},
 Scan[Quiet@Check[TimeConstrained[ToExpression[#, StandardForm]; Null, 120], Null] &, cells];
 Print["Loaded ", Length[cells], " code cells from graphical-calculus-2.1-simplify.nb"]];
dir = FileNameJoin[{$HomeDirectory, "Desktop", "Research", "Monoidal Graphical Calculus"}];"""
demo = [
 ("The model", [("Text", "Grades of X are {0, 1, 1, 2} and w(g) = 2^g. Then dim_l(X) = Σ 2^(−g), dim_r(X) = Σ 2^g: the category is pivotal and not spherical. The multiplicity of the simple object k_1 in X is 2:"),
   ("Input", '{fScalar[dl["X"]], fScalar[dr["X"]], fN["i", {"X"}]}')]),
 ("A partition pair", [("Text", "The pair (p_α, q_α) of an i-partition of X stands for Σ_α p_α ⊗ q_α: here two basis vectors of grade 1. Stacked as q over p it is id_X restricted to the grade-1 part; summed over i ∈ I it is id_X, which is (4.8):"),
   ("Input", 'withPairs[pairs463, {fTerm[T[1, comp[pB["a"], qB["a"]]]] // MatrixForm, fSum[{TS[1, {"i"}, comp[pB["a"], qB["a"]]]}] // MatrixForm}]')]),
 ("Lemma 4.9(e): the dimension factor", [("Text", "Both sides of Lemma 4.9(e) as matrices (k ⊗ i ⊗ W ⊗ j → j ⊗ k ⊗ i ⊗ W). With the book's factor dim_r(i) dim_r(k)/(dim_r(j) dim_l(k)) they agree; with the naive factor dim_l(i)/dim_l(j) they do not, because the category is not spherical:"),
   ("Input", 'withPairs[lemma49pairs, With[{l = fTerm[lemma49["(e)"][[1]]], r = fTerm[lemma49["(e)"][[2]]], f = fScalar[dr["i"] dr["k"]/(dr["j"] dl["k"])], g = fScalar[dl["i"]/dl["j"]]}, {l == r, l == g/f r, f, g}]]')]),
 ("Lemma 4.6: the S-matrix", [("Text", "Z/3 and Z/5 with the braiding ζ^(gh) · flip are modular. Formula (a) holds; formula (b) as printed fails, and holds with Δ+ in place of dim(C):"),
   ("Input", 'Dataset[<|"Z/3" -> lemma46[3], "Z/5" -> lemma46[5]|>]')]),
]
tests = r"""SeedRandom[47];
<|
 "§4.3.2: \[Omega]_S(\[Alpha] \[CircleTimes] \[Beta]) = \[Omega]_S*(\[Beta] \[CircleTimes] \[Alpha])" -> fEqual[{omega432[[1]]}, {omega432[[2]]}],
 "Lemma 4.2 (a), (b) and (4.2)" -> (And @@ Values[chkList[<||>, lemma42]]),
 "(4.7), (4.8), (4.9), (4.10), every step of (4.10)" -> (And @@ Values[chkList[pairs463, props463]]),
 "Lemma 4.7: the five numbers of the proof agree, also with l, r exchanged" -> With[{r = lemma47[]}, Length[Union[r["steps"]]] == 1 && SameQ @@ r["exchanged"]],
 "Lemma 4.8: \[Star]_S is the contraction vector, S = (X,+) and S = ((X,+),(Y,\[Minus]))" -> (And @@ Values[chkList[lemma48pairs, lemma48]]),
 "Lemma 4.9 (a)\[Dash](g)" -> (And @@ Values[chkList[lemma49pairs, lemma49]]),
 "Lemma 4.10: with a_i = a_1 dim_r(i), f_j,k = g_j,k for all j, k" -> Block[{fA}, fA[g_] := 7 fWt[g]; AllTrue[Flatten[Table[Values[chk410[j, k]], {j, {"j", "k", "n"}}, {k, {"j", "k", "n"}}]], TrueQ]],
 "Lemma 4.10: with a_i = a_1 dim_l(i) or random a_i, f_j,k \[NotEqual] g_j,k" -> Block[{fA}, fA[g_] := 7 fWt[-g];
     NoneTrue[Flatten[Table[chk410[j, k][[1, 2]], {j, {"j", "k", "n"}}, {k, {"j", "k", "n"}}]], TrueQ]],
 "Lemma 4.10: the duality step and the Lemma 4.9(e) step hold for any a_i" -> Block[{fA}, fA[g_] := fA[g] = RandomInteger[{1, 9}];
     AllTrue[Flatten[Table[Rest[Values[chk410[j, k]]], {j, {"j", "k", "n"}}, {k, {"j", "k", "n"}}]], TrueQ]],
 "Lemma 4.6 (a) and \[CapitalDelta]+\[CapitalDelta]- = dim(C) in Z/3 and Z/5" -> AllTrue[{lemma46[3], lemma46[5]}, #["S invertible (modular)"] && #["(a) \[Sum]_j S_i,j S_j,r = dim(C) \[Delta]_i\[SmallCircle],r"] && #["\[CapitalDelta]+ \[CapitalDelta]- = dim(C)"] &],
 "Lemma 4.6 (b): false as printed, true with \[CapitalDelta]+ for dim(C)" -> AllTrue[{lemma46[3], lemma46[5]}, ! #["(b) as printed: \[Sum]_j v_i v_j dim(j) S_i,j = dim(C) dim(i)"] && #["(b) with \[CapitalDelta]+: \[Sum]_j v_i v_j dim(j) S_i,j = \[CapitalDelta]+ dim(i)"] &]
|>"""
cells = [
 ("Title", "Graphical calculus, Chapter 4: non-degenerate, pre-fusion and fusion categories"),
 ("Subtitle", "Turaev & Virelizier, Monoidal Categories and Topological Field Theory, §4.3.2 and §4.5.2–4.7, pp. 70–87 · sections 70–79 · Lemmas 4.2, 4.6–4.10"),
 ("Text", "By Dara O Shayda and Noor Hoshino (星野ヌール)"),
 ("Section", "69. Setup"),
 ("Text", "The first cell loads the engine from this folder (Desktop/Research/Monoidal Graphical Calculus). The code of this notebook is also saved as fusion-4.wl. The editor's symbolic rules for Chapter 4 are in fusion-4-rules.wl, which the GraphicalCalculusKernel loads; this notebook checks the statements, and the proof steps, in a matrix model."),
 ("Input", setup),
]
for title, text, body in secs:
    cells.append(("Section", title))
    if text: cells.append(("Text", text))
    cells.append(("Input", body))
cells.append(("Section", "79a. Walkthrough"))
for h, extra in demo:
    cells.append(("Subsection", h)); cells.extend(extra)
cells += [
 ("Section", "79b. Tests"),
 ("Text", "Every statement is checked in the model of section 70, with random graded boxes. Where a proof is a chain of equalities, every link is checked (the lists in sections 73–77 hold the chains)."),
 ("Input", tests),
 ("Section", "Appendix: what is and is not mechanised"),
 ("Item", "The pointed models (graded vector spaces) have all multiplicities N^k_(i⊗j) ≤ 1; non-simple objects X carry the larger multiplicities. Lemma 4.9 and 4.10 are checked with w(g) = 2^g, where dim_l ≠ dim_r, so every dimension factor matters."),
 ("Item", "Lemma 4.6(b) as printed, Σ_j v_i v_j dim(j) S_i,j = dim(C) dim(i), fails in the modular categories Z/3 and Z/5 (its left side is the Gauss sum Δ+). With Δ+ in place of dim(C) it holds, and Δ+ Δ− = dim(C) holds as stated in §4.5.2."),
 ("Item", "The steps of the proofs of Lemma 4.9(d), (e) that are about single basis vectors (λ_α,β) are checked through the statements they prove; the editor's symbolic rules cover Lemma 4.2, (4.7)–(4.10), Lemma 4.8 for S = (X,+), Lemma 4.9(a)–(d) and the duality and (4.12) steps of Lemma 4.10. Lemma 4.9(e)–(g) and the Lemma 4.9(e) step of Lemma 4.10 are checked here, in matrices."),
 ("Text", "© Computational Classnotes · CC BY-NC-SA 4.0"),
]
def esc(s):
    out = []
    for ch in s:
        o = ord(ch)
        if ch == '\\': out.append('\\\\')
        elif ch == '"': out.append('\\"')
        elif ch == '\n': out.append('\\n')
        elif o < 128: out.append(ch)
        elif o <= 0xFFFF: out.append('\\:%04x' % o)
        else: out.append('\\|%06x' % o)
    return ''.join(out)
nb = 'Notebook[{\n' + ',\n'.join('Cell["%s", "%s"]' % (esc(c), st) for st, c in cells) + '\n}, StyleDefinitions -> "Default.nb"]\n'
open('/mnt/user-data/outputs/graphical-calculus-4.nb', 'w').write(nb)
print(len(cells))
