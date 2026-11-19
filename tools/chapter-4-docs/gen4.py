import json, os
D = {x['i']: x for x in json.load(open('/home/claude/ch4/ex.json'))}
ED = '../../string-diagram-editor.html'
FOOT = "\n---\n\nBy Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0\n"
NB = "`graphical-calculus-4.nb` (sections 70–79, code in `fusion-4.wl`)"

def eq(i):
    return '$$\n' + ' \\;=\\; '.join(D[i]['tex']) + '\n$$' if sum(len(t) for t in D[i]['tex']) < 150 else '\n\n'.join('$$\n' + ('' if k == 0 else '=\\;') + t + '\n$$' for k, t in enumerate(D[i]['tex']))

def steps_text(i):
    x = D[i]; rows = []
    for k, st in enumerate(x['steps']):
        rs = [' → '.join(r.replace('_', '\\_') for r in t) if t else 'already in normal form' for t in st]
        rows.append(f"| {k + 1} | ${x['tex'][k]}$ | {'; '.join(rs)} |")
    return "| side | expression | rules Simplify uses |\n|---|---|---|\n" + "\n".join(rows)

def example(i, book=None, heading=None):
    x = D[i]; L = []
    L.append(f"### {heading or x['title']}\n")
    if book: L.append(book + "\n")
    sig = "\n".join(l for l in x['sig'].split('\n') if not l.startswith('#'))
    L.append("**Signature and expression** (duals: X\\*, *pre-fusion* ticked):\n")
    L.append("```\n" + sig + "\n```\n")
    L.append("```\n" + x['src'] + "\n```\n")
    L.append(eq(i) + "\n")
    L.append(f"![{x['title']}](img/ex{i}a.png)\n")
    L.append(steps_text(i) + "\n")
    L.append("Normal form:\n")
    L.append('$$\n' + x['nf'][0] + '\n$$\n')
    if not x.get('scalar'): L.append(f"![{x['title']}, simplified](img/ex{i}b.png)\n")
    v = x['verdict'].strip()
    if v: L.append(f"The editor reports: *{v}* · [Open this step in the editor]({ED}#ex={i})\n")
    return "\n".join(L)

PAGES = []
def page(slug, title, body):
    PAGES.append((slug, title)); open(f'/home/claude/ch4/{slug}.md', 'w').write(f"# {title}\n\n" + body + FOOT)

NAV = "[← Chapter 4 index](index.md)\n\n"

page('4-3-2-pairings', '§4.3.2 The pairings ω are symmetric', NAV +
"For a tuple $S$ of signed objects, the evaluation $\\mathrm{ev}_S : X_{S^*}\\otimes X_S\\to\\mathbb 1$ of §2.3.2 gives a pairing "
"$\\omega_S(\\alpha\\otimes\\beta) = \\mathrm{ev}_S(\\alpha\\otimes\\beta)$ on $\\mathrm{Hom}(\\mathbb 1, X_{S^*})\\otimes\\mathrm{Hom}(\\mathbb 1, X_S)$. "
"By isotopy invariance (Theorem 2.6), $\\omega_S(\\alpha\\otimes\\beta) = \\omega_{S^*}(\\beta\\otimes\\alpha)$: the closed diagram can be turned through 180°. "
"The book shows it for $S = ((X,-),(Y,+))$.\n\n"
"In the editor the rule **turning ω_S (§4.3.2, Theorem 2.6)** puts the box with the smaller name first. Here it turns the right side into the left side.\n\n"
+ example(78) +
f"\nIn the Wolfram notebook {NB} the two sides are also equal as matrices in a pivotal category that is not spherical (section 73, `omega432`).\n")

page('lemma-4-2', 'Lemma 4.2 Dimensions of simple objects', NAV +
"**Lemma 4.2.** In a non-degenerate pivotal $\\Bbbk$-category: (a) the dimensions $\\dim_l(i)$ and $\\dim_r(i)$ of a simple object $i$ are invertible; "
"(b) every endomorphism $f$ of a simple $i$ is $f = \\dim_l(i)^{-1}\\,\\mathrm{tr}_l(f)\\,\\mathrm{id}_i = \\dim_r(i)^{-1}\\,\\mathrm{tr}_r(f)\\,\\mathrm{id}_i$. "
"It follows that $\\dim_l(i)\\,\\mathrm{tr}_r(f) = \\dim_r(i)\\,\\mathrm{tr}_l(f)$, formula (4.2).\n\n"
"**Proof of (a), step by step.** With $S = ((i,+),(i,-))$, $\\mathrm{coev}_i$ spans $\\mathrm{Hom}(\\mathbb 1, i\\otimes i^*)$, and the $1\\times 1$ matrix of $\\omega_S$ is $\\omega_S(\\mathrm{coev}_i\\otimes\\mathrm{coev}_i)$. "
"The book draws it, straightens it to a circle, and reads off $\\dim_r(i)$:\n\n"
"| step | book | editor |\n|---|---|---|\n"
"| $\\omega_S(\\mathrm{coev}_i\\otimes\\mathrm{coev}_i)$ = the circle | isotopy | (2.1) left zigzag |\n"
"| the circle = $\\dim_r(i)$ | definition of $\\dim_r$ | dim\\_l(i), dim\\_r(i) of a simple object |\n\n"
+ example(79) + "\n" + example(80, "The same with $S = ((i,-),(i,+))$ gives $\\dim_l(i)$.") +
"\n**Part (b).** Declaring `simple i` lets the rule **Lemma 4.2(b)** replace an endomorphism $h$ of $i$ by $\\dim_l(i)^{-1}\\,\\mathrm{tr}_l(h)\\,\\mathrm{id}_i$. A box that already sits alone on a loop is left alone, so the rule stops.\n\n"
+ example(81) + "\n" + example(82, "**(4.2).** The rule **(4.2)** turns a right trace of an endomorphism of a simple object into $\\dim_l(i)^{-1}\\dim_r(i)$ times its left trace.") +
f"\nIn the notebook {NB}, section 73 checks (a), both forms of (b), and (4.2) in matrices (`lemma42`).\n")

page('4-6-1-curvilinear-boxes', '§4.6.1–4.6.2 Curvilinear boxes', NAV +
"Let $i$ be simple and let $(p_\\alpha : X\\to i,\\ q_\\alpha : i\\to X)_{\\alpha\\in A}$ be an $i$-partition of $X$. "
"A diagram that contains $p_\\alpha$ and $q_\\alpha$ and is summed over $\\alpha$ does not depend on the choice of partition, because the tensor $\\sum_\\alpha p_\\alpha\\otimes q_\\alpha$ does not. "
"The book therefore draws the pair as two curvilinear boxes: a semi-disk for $p_\\alpha$ and a compressed rectangle for $q_\\alpha$ (4.6). Pairs may carry several arcs, may be 1-partitions (the $\\mathbb 1$-arc is erased), and are painted in different colours.\n\n"
"**In the editor.** Tick *pre-fusion* (duals: X\\*) and declare a pair in the signature:\n\n"
"```\nsimple i\npartition α : X → i\n```\n\n"
"This gives the boxes `p_α : X → i`, drawn as a semi-disk, and `q_α : i → X`, drawn as a compressed rectangle, in the colour of the pair. `partition β : X* ⊗ Y → 𝟙` declares a 1-partition. "
"An expression is a linear combination: write sums as `∑_i` or `∑_{i∈I}`, and scalars before the morphism, such as `dim_l(i)`, `dim_r(i)`, `N^i_X`, `δ_{i,j}`, `δ_{i°,j}`, `2/3`, or `a_i` after `scalar a`. Powers are written `⁻¹`, and terms are separated by `+` or `−`. "
"In a sum, the pair belongs to the summation variable, as in (4.8). Pair names and summation variables are bound: two expressions that differ only in these names have the same normal form.\n\n"
"**Bent boxes.** By isotopy, a curvilinear box with its arcs bent to the other side is the same as the box drawn with the arcs bent the other way. The editor checks this with the folds of Figure 2.3:\n\n"
+ example(83) + "\n" + example(84) +
"\n**Example 4.6.2** puts two pairs in one quasi-diagram: a red $i$-partition of $X$ and a blue $j$-partition of $X\\otimes Y^*$, together with a box $f : Y\\to i\\otimes Y$. By definition the quasi-diagram is the double sum over $\\alpha$ and $\\beta$ of the diagram with these boxes. "
"In the editor, give each pair its own `partition` line, and the colours follow the order of declaration.\n")

page('4-6-3-properties', '§4.6.3 Properties (4.7)–(4.10)', NAV +
"For an object $X$ and a simple object $i$ of a pivotal pre-fusion category:\n\n"
"- **(4.7)** a semi-disk directly on top of its compressed rectangle (the composite $p_\\alpha q_\\alpha$ on the $i$-line) is $N^i_X\\,\\mathrm{id}_i$, where $N^i_X$ is the multiplicity of $i$ in $X$;\n"
"- **(4.8)** $\\sum_{i\\in I} q_\\alpha p_\\alpha = \\mathrm{id}_X$, because the $i$-partitions together form an $I$-partition;\n"
"- **(4.9)** for a 1-partition, $q_\\alpha p_\\alpha f = f$ for $f\\in\\mathrm{Hom}(\\mathbb 1, X)$ and $g\\, q_\\alpha p_\\alpha = g$ for $g\\in\\mathrm{Hom}(X,\\mathbb 1)$;\n"
"- **(4.10)** $\\dim_l(X) = \\sum_i \\dim_l(i) N^i_X$ and $\\dim_r(X) = \\sum_i \\dim_r(i) N^i_X$.\n\n"
"The rules are named after the formulas. **(4.10)** is also a rule: a circle on an object that is not declared simple becomes $\\sum_i \\dim(i) N^i_X$, so that every step of the book's derivation of (4.10) can be checked.\n\n"
+ example(85) + "\n" + example(86) + "\n" + example(87) + "\n" + example(88) +
"\n**The derivation of (4.10), step by step.** The book's chain $\\dim_l(X) = \\cdots = \\sum_i \\dim_l(i)N^i_X$ is typed as one equation with five sides. Each side reduces with the rule the book cites for that step:\n\n"
"| step | book | editor, on the new side |\n|---|---|---|\n"
"| loop $X$ = $\\sum_i$ loop $X$ with $q_\\alpha p_\\alpha$ | (4.8) | (4.8) |\n"
"| = $\\sum_i$ loop $i$ with $p_\\alpha q_\\alpha$ | isotopy | (4.7) applies to the turned loop |\n"
"| = $\\sum_i N^i_X$ loop $i$ | (4.7) | dim\\_l(i), dim\\_r(i) of a simple object |\n"
"| = $\\sum_i \\dim_l(i) N^i_X$ | definition of $\\dim_l$ | — |\n\n"
+ example(89) + "\n" + example(90) +
f"\nThe notebook {NB}, section 74 (`props463`), checks (4.7)–(4.10), and each link of the chain, in matrices.\n")

page('lemma-4-6', 'Lemma 4.6 The S-matrix of a modular category', NAV +
"In a ribbon fusion category the twist acts on a simple $i$ as $v_i\\,\\mathrm{id}_i$. With $\\Delta_\\pm = \\sum_i v_i^{\\pm 1}\\dim(i)^2$ and $S_{i,j} = \\mathrm{tr}(\\tau_{j,i}\\tau_{i,j})$, the category is modular when the S-matrix is invertible. "
"**Lemma 4.6** states (a) $\\sum_j S_{i,j}S_{j,r} = \\dim(\\mathcal C)\\,\\delta_{i^\\circ,r}$, and (b) $\\sum_j v_i v_j\\dim(j)S_{i,j} = \\dim(\\mathcal C)\\dim(i)$. The book cites [Tu1] for both and draws no diagram.\n\n"
"**Checked in matrices.** The notebook (section 78, `lemma46[n]`) builds the modular categories of $\\mathbb Z/3$- and $\\mathbb Z/5$-graded vector spaces, with braiding $\\zeta^{gh}\\cdot$flip ($\\zeta = e^{2\\pi i/n}$). "
"It computes $v_i$ from the curl and $S_{i,j}$ from the trace of the double crossing:\n\n"
"| claim | $\\mathbb Z/3$ | $\\mathbb Z/5$ |\n|---|---|---|\n"
"| S invertible (modular) | yes | yes |\n"
"| (a) | holds | holds |\n"
"| $\\Delta_+\\Delta_- = \\dim(\\mathcal C)$ (§4.5.2) | holds | holds |\n"
"| (b) as printed | **fails** | **fails** |\n"
"| (b) with $\\Delta_+$ in place of $\\dim(\\mathcal C)$ | holds | holds |\n\n"
"In these categories the left side of (b) is the Gauss sum $\\Delta_+$ ($i\\sqrt 3$, $\\sqrt 5$), not $\\dim(\\mathcal C) = 3, 5$. The formula that holds is $\\sum_j v_i v_j\\dim(j)S_{i,j} = \\Delta_+\\dim(i)$, equivalently $\\sum_j v_j\\dim(j)S_{i,j} = \\Delta_+ v_i^{-1}\\dim(i)$. **The printed (b) looks like a misprint.**\n")

page('lemma-4-7', 'Lemma 4.7 A dimension identity in fusion categories', NAV +
"**Lemma 4.7.** In a pivotal fusion category, $\\sum_{m,n\\in I}\\dim_l(m)\\dim_l(n)N^{\\mathbb 1}_{X\\otimes m\\otimes Y\\otimes n} = \\dim_r(X)\\dim_r(Y)\\dim(\\mathcal C)$, and the same with $l$ and $r$ exchanged.\n\n"
"The proof is a chain of scalar identities. Its only diagrammatic ingredient is (4.10), which the editor checks step by step ([§4.6.3](4-6-3-properties.md)). "
"The notebook (section 78, `lemma47[]`) checks every link of the chain in the $\\mathbb Z/3$-graded fusion category with $w(g) = \\omega^g$ (pivotal, not spherical):\n\n"
"| link | justification in the book | checked |\n|---|---|---|\n"
"| $\\sum_{m,n}\\dim_l(m)\\dim_l(n)N^{\\mathbb 1}_{X m Y n} = \\sum_m\\dim_l(m)\\sum_n\\dim_r(n^*)N^{n^*}_{X m Y}$ | $\\dim_l(n) = \\dim_r(n^*)$, duality | equal |\n"
"| $= \\sum_m\\dim_l(m)\\sum_k\\dim_r(k)N^k_{X m Y}$ | $n\\mapsto n^*$ permutes $I$ | equal |\n"
"| $= \\sum_m\\dim_l(m)\\dim_r(X\\otimes m\\otimes Y)$ | (4.10) | equal |\n"
"| $= \\dim_r(X)\\dim_r(Y)\\dim(\\mathcal C)$ | ⊗-multiplicativity | equal |\n\n"
"The notebook also checks the version with $l$ and $r$ exchanged.\n")

page('4-6-4-braided', '§4.6.4 Curvilinear boxes in braided categories', NAV +
"In a braided pivotal pre-fusion category, naturality of the braiding lets a curvilinear box pass under or over a strand. The editor's R4/R5 rule moves a one-line box through a crossing, and it treats `p_α` and `q_α` like any other box:\n\n"
+ example(101) +
"\nMoving boxes with several arcs through a bundle of crossings is not in the editor.\n")

page('lemma-4-8', 'Lemma 4.8 The contraction vector of a pairing', NAV +
"**Lemma 4.8.** The contraction vector of $\\omega_S$ is $\\ast_{\\omega_S} = q_\\alpha\\otimes_\\Bbbk(\\text{the semi-disk with its arcs bent up})$, for a 1-partition $(p_\\alpha, q_\\alpha)$ of $X_S$ (4.11). "
"The proof checks the two zigzag identities of a contraction vector, each in three steps. The editor follows the steps for $S = (X,+)$:\n\n"
"| step | book | editor |\n|---|---|---|\n"
"| (i) $(\\mathrm{id}\\otimes\\omega_S)(\\ast_S\\otimes f)$ = diagram | definitions | — (typed as the first side) |\n"
"| (ii) = $q_\\alpha p_\\alpha f$ | isotopy | isotopy: straightening (Theorem 2.6) |\n"
"| (iii) = $f$ | (4.9) | (4.9) |\n\n"
+ example(91) +
"\nThe second identity uses (4.9) first and then isotopy, in the book's order:\n\n"
"| step | book | editor |\n|---|---|---|\n"
"| (i) $(\\omega_S\\otimes\\mathrm{id})(g\\otimes\\ast_S)$ = diagram | definitions | — |\n"
"| (ii) = $g$ with its arc bent | (4.9) | (4.9) |\n"
"| (iii) = $g$ | isotopy | isotopy: straightening (Theorem 2.6) |\n\n"
+ example(92) +
f"\nFor tuples $S$ with several arcs, such as $S = ((X,+),(Y,-))$, the lemma is checked in matrices in {NB}, section 75 (`lemma48`).\n")

page('lemma-4-9', 'Lemma 4.9 Computations with curvilinear boxes', NAV +
"**Lemma 4.9** lists seven identities that hold inside any diagram (the 'gray area'). In the editor the gray area is everything else in the expression; the examples put the two boxes side by side. "
"Parts (a)–(d) are editor rules named after the lemma. Parts (e)–(g) are checked in matrices.\n\n"
"**(a)** A $j$-partition of a simple $i$ is $\\delta_{i,j}$ times $(\\mathrm{id}_i, \\mathrm{id}_i)$. A $j$-partition of $i^*$ is $\\delta_{i^\\circ,j}$ times $(\\varphi_{i,j}, \\varphi_{i,j}^{-1})$ for an isomorphism $\\varphi_{i,j} : i^*\\to j$, typed `φ_{i,j}`. "
"With $\\delta_{i,j}$ the editor renames $j$ to $i$ in the term. In a sum over $j$, the sum collapses (**δ substitution**).\n\n"
+ example(93) + "\n" + example(94) +
"\n**(b), (c)** A 1-partition of $i^*\\otimes j$ is $\\delta_{i,j}\\dim_l(i)^{-1}(\\mathrm{ev}_i, \\widetilde{\\mathrm{coev}}_i)$. A 1-partition of $i\\otimes j^*$ is $\\delta_{i,j}\\dim_r(i)^{-1}(\\widetilde{\\mathrm{ev}}_i, \\mathrm{coev}_i)$.\n\n"
+ example(95) + "\n" + example(96) +
"\n**(d)** An $i$-partition of $X$ equals $\\dim_l(i)$ times a 1-partition of $i^*\\otimes X$ with the $i$-arc bent, and also $\\dim_r(i)$ times a 1-partition of $X\\otimes i^*$. "
"The rule **Lemma 4.9(d)** rewrites a 1-partition of $i^*\\otimes X$ (or of $X\\otimes i^*$) as $\\dim_l(i)^{-1}$ (or $\\dim_r(i)^{-1}$) times a new $i$-partition of $X$ with a cap and a cup. The zigzags then straighten the bends:\n\n"
+ example(97) +
"\n**(e), (f), (g)** relate partitions whose arcs are bent in more complicated ways:\n\n"
"- (e): an $i$-partition of $k^*\\otimes j\\otimes X^*$ with its $k$- and $X$-arcs bent equals $\\frac{\\dim_r(i)\\dim_r(k)}{\\dim_r(j)\\dim_l(k)}$ times a $j$-partition of $k\\otimes i\\otimes X$;\n"
"- (f): the mirror image, with factor $\\frac{\\dim_l(i)\\dim_l(k)}{\\dim_l(j)\\dim_r(k)}$;\n"
"- (g): $\\sum_j$ (an $i$-partition of $j\\otimes Y$ on top of a $j$-partition of $X$) = an $i$-partition of $X\\otimes Y$ = $\\sum_j$ (an $i$-partition of $X\\otimes j$ on top of a $j$-partition of $Y$).\n\n"
f"These are checked in matrices in {NB}, section 76 (`lemma49`), in a pivotal category that is not spherical ($w(g) = 2^g$). There $\\dim_l\\neq\\dim_r$, so the factors in (e) and (f) are really tested. The walkthrough shows that the book's factor in (e) is right and that the symmetric guess $\\dim_l(i)/\\dim_l(j)$ is wrong. "
"The editor does not have rules for (e)–(g) yet.\n")

page('lemma-4-10', 'Lemma 4.10 Which scalars make f = g', NAV +
"**Lemma 4.10.** Let $(a_i)_{i\\in I}$ be scalars, $f_{j,k} = a_k\\,\\widetilde{\\mathrm{coev}}_k\\,\\mathrm{ev}_j$, and $g_{j,k} = \\sum_i a_i\\,(q_\\alpha^*\\otimes p_\\alpha)(\\mathrm{id}_{j^*}\\otimes\\widetilde{\\mathrm{coev}}_i\\otimes\\mathrm{id}_j)$ for a $k$-partition $(p_\\alpha, q_\\alpha)$ of $i\\otimes j$. "
"Then $f_{j,k} = g_{j,k}$ for all $j,k\\in I$ if and only if $a_i = a_{\\mathbb 1}\\dim_r(i)$ for all $i$.\n\n"
"**The proof, step by step.**\n\n"
"| step | book | checked by |\n|---|---|---|\n"
"| bend $f$ and $g$ (duality): $f_{j,k}$ becomes $a_k\\,\\mathrm{id}_{k\\otimes j^*}$ | duality | editor: the (2.1) zigzags |\n"
"| the bent $g_{j,k}$ is $\\sum_i a_i\\frac{\\dim_r(k)}{\\dim_r(i)}\\, q_\\rho p_\\rho$, an $i$-partition of $k\\otimes j^*$ | Lemma 4.9(e) | notebook, matrices |\n"
"| so $f = g$ iff (4.12): $a_k\\,\\mathrm{id}_{k\\otimes j^*} = \\sum_i a_i\\frac{\\dim_r(k)}{\\dim_r(i)} q_\\rho p_\\rho$ | | |\n"
"| if $a_i = a_{\\mathbb 1}\\dim_r(i)$ then (4.12) holds | (4.8) | editor: (4.8) |\n"
"| conversely, (4.12) at $k = \\mathbb 1$, $j = i^*$ gives $a_{\\mathbb 1} = a_i\\dim_r(i)^{-1}$ | Lemma 4.9(a) | editor: Lemma 4.9(a), δ |\n\n"
+ example(98) + "\n" + example(99) + "\n" + example(100) +
f"\nThe notebook {NB}, section 77 (`lemma410`, `chk410`), checks the whole lemma in matrices for all $j,k$ in $\\{{k_{{-1}}, k_1, k_2\\}}$: "
"$f = g$ holds when $a_i = a_{\\mathbb 1}\\dim_r(i)$, fails for $a_i = a_{\\mathbb 1}\\dim_l(i)$ and for random $a_i$, and the duality step and the Lemma 4.9(e) step hold for any $a_i$.\n")

idx = "# Chapter 4: the enriched graphical calculus\n\n**Dara O Shayda and Noor Hoshino (星野ヌール)**\n\n"
idx += ("*After Turaev & Virelizier, “Monoidal Categories and Topological Field Theory”, Chapter 4 (§4.3.2 and §4.5.2–4.7, pp. 70–87).*\n\n"
"Each page below has one result: the statement, then the proof as a chain of steps. Each step is an example in [the editor](../../string-diagram-editor.html), and Simplify uses the rule the book cites for that step. "
"Steps about single basis vectors, and Lemmas 4.6, 4.7 and 4.9(e)–(g), are checked in matrices in the Wolfram notebook `graphical-calculus-4.nb`. Its model is a category of graded vector spaces, pivotal but not spherical, so the left and right dimensions differ.\n\n"
"## Results\n\n")
for slug, title in PAGES: idx += f"- [{title}]({slug}.md)\n"
idx += ("\n## Using the editor for Chapter 4\n\n"
"- Set **duals** to X\\* (pivotal) and tick **pre-fusion**.\n"
"- Signature lines: `simple i j k` (simple objects; summation variables are simple automatically), `partition α : X → i` (an $i$-partition, with boxes `p_α`, `q_α`; use `𝟙` for a 1-partition), `scalar a` (scalars $a_i$). `φ_{i,j} : i* → j` and `φ⁻¹_{i,j}` are built in.\n"
"- Expressions are linear combinations: `∑_i dim_l(i) N^i_X`, `δ_{i,j} dim_l(i)⁻¹ ev_i ⊗ coev~_i`, `a_k id_k ⊗ id_j*`.\n"
"- New rules, tried before trace symmetry: δ substitution, turning ω_S, Lemma 4.9(a)–(d), (4.7), (4.8), (4.9), isotopy: straightening, dimensions of simple objects, (4.10), (4.2), Lemma 4.2(b). The Wolfram kernel (`fusion-4-rules.wl`) has the same rules in the same order. On all 116 Chapter 4 requests it gives the same steps and the same terms as the JavaScript engine.\n\n"
"## A possible misprint\n\nLemma 4.6(b) as printed, $\\sum_j v_iv_j\\dim(j)S_{i,j} = \\dim(\\mathcal C)\\dim(i)$, fails in the modular categories $\\mathbb Z/3$ and $\\mathbb Z/5$. It holds with $\\Delta_+$ in place of $\\dim(\\mathcal C)$; see [Lemma 4.6](lemma-4-6.md).\n")
open('/home/claude/ch4/index.md', 'w').write(idx + FOOT)
json.dump(PAGES, open('/home/claude/ch4/pages.json', 'w'), ensure_ascii=False)
print(len(PAGES))
