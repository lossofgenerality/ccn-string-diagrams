import json, re
D = json.load(open('/home/claude/intro/ex.json'))

def factors(t):
    """split a TeX composition (A) (B) (C) at top level"""
    out, depth, cur, i = [], 0, '', 0
    while i < len(t):
        c = t[i]
        if c == '(': depth += 1
        if c == ')': depth -= 1
        cur += c
        if depth == 0 and c == ')' and t[i+1:i+3] == ' (':
            out.append(cur.strip()); cur = ''; i += 1
        i += 1
    out.append(cur.strip())
    return [f for f in out if f]

def disp(t):
    if len(t) < 110: return '$$\n' + t + '\n$$'
    fs = factors(t)
    if len(fs) == 1: return '$$\n' + ('\\footnotesize ' if len(t) > 150 else '') + t + '\n$$'
    return '$$\n\\begin{aligned}\n' + ' \\\\\n'.join(('&' if k == 0 else '&\\;') + f for k, f in enumerate(fs)) + '\n\\end{aligned}\n$$'

def eqn(texs):
    if len(texs) == 1: return disp(texs[0])
    short = sum(len(t) for t in texs) < 110
    if short: return '$$\n' + ' \\;=\\; '.join(texs) + '\n$$'
    return '\n\n$$=$$\n\n'.join(disp(t) for t in texs)

def obj(s): return s.replace('⊗', '\\otimes').replace('𝟙', '\\mathbb{1}').replace('∨', '{}^{\\vee}')

def objtex(s):
    parts = [p.strip() for p in s.split('⊗')]
    def a(p):
        if p == '𝟙': return '\\mathbb{1}'
        if p.startswith('∨'): return '{}^{\\vee}' + p[1:]
        if p.endswith('*'): return p[:-1] + '^{*}'
        return p
    return ' \\otimes '.join(a(p) for p in parts)

# explanations, by example index: (what the book says, what to look at)
X = {
0: ("§2.1.1 draws the identity of an object $X$ as a plain vertical arc coloured $X$, with no box. Every arc in the editor is an identity.",
    "Type `id_X`. The two dots are the free ends: the source $X$ at the bottom and the target $X$ at the top."),
1: ("A morphism $f\\colon X\\to Y$ is a box with its source arc coming in from below and its target arc leaving at the top.",
    "The signature line `f : X → Y` declares the box; the expression `f` then draws it. Diagram → Expression reads it back as $f$."),
2: ("The composition $gf$ is drawn by stacking: $f$ below $g$, joined by the arc $Y$. The book writes composition by juxtaposition, and so does the editor.",
    "Type `g f`. Juxtaposition binds tighter than $\\otimes$, so `g f ⊗ h` means $(gf)\\otimes h$. `g ∘ f` and `f ; g` are accepted too."),
3: ("§2.1.2: the monoidal product $f\\otimes g$ is drawn by placing the boxes side by side, $f$ on the left.",
    "`f ⊗ g` with `f : X → Y` and `g : U → V`. The source $X\\otimes U$ is read left to right along the bottom."),
4: ("A box may have several arcs on each side; their colours are read left to right.",
    "`f : X ⊗ Y → A ⊗ B ⊗ C` gives a box with two inputs and three outputs."),
5: ("The unit object $\\mathbb 1$ is never drawn. A morphism $\\mathbb 1\\to\\mathbb 1$ is a box with no arcs, $\\mathbb 1\\to X$ has no arc below, and $X\\to\\mathbb 1$ has none above.",
    "Type the unit as `𝟙` (also `I` or `1`). Simplify erases strands coloured $\\mathbb 1$."),
6: ("Figure 2.1, the level-exchange property: boxes on different arcs can slide past each other, so $f\\otimes g = (\\mathrm{id}_Y\\otimes g)(f\\otimes\\mathrm{id}_U) = (f\\otimes \\mathrm{id}_V)(\\mathrm{id}_X\\otimes g)$.",
    "Simplify puts each side in its level-exchange normal form (one box per layer, boxes pushed down and to the left). All three sides reach the same normal form, so the verdict says the equation holds, without any other rule."),
7: ("Formula (2.1), left: for a non-degenerate pairing $\\omega\\colon X\\otimes Y\\to\\mathbb 1$ with inverse $\\Omega\\colon\\mathbb 1\\to Y\\otimes X$, the zigzag on $Y$ straightens: $(\\mathrm{id}_Y\\otimes\\omega)(\\Omega\\otimes\\mathrm{id}_Y)=\\mathrm{id}_Y$.",
    "The signature line `pairing ω Ω` tells the simplifier that $\\omega$ and $\\Omega$ are paired. The rule **(2.1) left zigzag** removes the cup $\\Omega$ and the cap $\\omega$ together."),
8: ("Formula (2.1), right: $(\\omega\\otimes\\mathrm{id}_X)(\\mathrm{id}_X\\otimes\\Omega)=\\mathrm{id}_X$.",
    "The rule **(2.1) right zigzag** straightens the zigzag on $X$."),
9: ("The inverse of a pairing is unique. If $\\Omega$ and $\\Omega'$ are both inverses of $\\omega$, the diagram $(\\mathrm{id}_Y\\otimes\\omega\\otimes\\mathrm{id}_X)(\\Omega'\\otimes\\Omega)$ equals $\\Omega$ by one zigzag and $\\Omega'$ by the other.",
    "With the default order the left zigzag fires first and the result is $\\Omega$. Tick **right zigzag first** and Simplify gives $\\Omega'$ instead: the two answers together prove $\\Omega=\\Omega'$."),
10: ("The bijection (1.10) $\\mathrm{Hom}(T, Z\\otimes X)\\cong\\mathrm{Hom}(T\\otimes Y, Z)$ sends $\\alpha$ to $(\\mathrm{id}_Z\\otimes\\omega)(\\alpha\\otimes\\mathrm{id}_Y)$; the way back sends $\\beta$ to $(\\beta\\otimes\\mathrm{id}_X)(\\mathrm{id}_T\\otimes\\Omega)$. Going there and back gives $\\alpha$ again.",
    "After level exchange the cup $\\Omega$ and the cap $\\omega$ form a zigzag, and **(2.1) right zigzag** removes it, leaving the box $\\alpha$."),
11: ("The other composite of (1.10): starting from $\\beta\\colon T\\otimes Y\\to Z$ and going back and forth gives $\\beta$.",
    "This time the **(2.1) left zigzag** does the work."),
12: ("§2.1.2: with left duals, $\\mathrm{ev}_X\\colon {}^{\\vee}X\\otimes X\\to\\mathbb 1$ is a cap and $\\mathrm{coev}_X\\colon\\mathbb 1\\to X\\otimes{}^{\\vee}X$ is a cup. The dual of $f\\colon X\\to Y$ is ${}^{\\vee}f = (\\mathrm{ev}_Y\\otimes\\mathrm{id}_{{}^{\\vee}X})(\\mathrm{id}_{{}^{\\vee}Y}\\otimes f\\otimes\\mathrm{id}_{{}^{\\vee}X})(\\mathrm{id}_{{}^{\\vee}Y}\\otimes\\mathrm{coev}_X)$.",
    "With **duals: ∨X**, `ev_X`, `coev_X` and `∨f` are built in for every declared box. The rule **definition of ∨f** folds the three-layer picture into the single box ${}^{\\vee}f$."),
13: ("Formula (2.2), left: a dual box slides through a cap, $\\mathrm{ev}_X({}^{\\vee}f\\otimes\\mathrm{id}_X)=\\mathrm{ev}_Y(\\mathrm{id}_{{}^{\\vee}Y}\\otimes f)$.",
    "The rule **(2.2) slide through ev** moves the box from the left leg of the cap to the right leg, turning ${}^{\\vee}f$ into $f$."),
14: ("Formula (2.2), right: $(\\mathrm{id}_Y\\otimes{}^{\\vee}f)\\mathrm{coev}_Y=(f\\otimes\\mathrm{id}_{{}^{\\vee}X})\\mathrm{coev}_X$.",
    "The rule **(2.2) slide through coev** does the same through a cup."),
15: ("The duality identity $(\\mathrm{id}_X\\otimes\\mathrm{ev}_X)(\\mathrm{coev}_X\\otimes\\mathrm{id}_X)=\\mathrm{id}_X$: ev and coev form a non-degenerate pairing.",
    "No `pairing` line is needed: ev and coev are paired automatically, and **(2.1) left zigzag** straightens the arc."),
16: ("§2.1.3, pivotal categories: every arc carries an orientation. An arc coloured $X$ points down, and $\\mathrm{id}_{X^*}$ is the same arc pointing up, so it can be labelled $X^*$ or $X$.",
    "Switch **duals** to **X\\* (§2.1.3, pivotal)**. The examples from here on set it themselves. The editor labels the up arc $X$ and draws its arrow, as on p. 34."),
17: ("A morphism $f\\colon X^*\\otimes Y\\to U\\otimes V^*\\otimes W$ in a pivotal category: each arc's arrow shows whether its colour is starred.",
    "Starred colours point up, plain colours point down, on both sides of the box."),
18: ("The four duality morphisms: $\\mathrm{ev}_X\\colon X^*\\otimes X\\to\\mathbb 1$ and $\\widetilde{\\mathrm{ev}}_X\\colon X\\otimes X^*\\to\\mathbb 1$ are caps, $\\mathrm{coev}_X\\colon\\mathbb 1\\to X\\otimes X^*$ and $\\widetilde{\\mathrm{coev}}_X\\colon\\mathbb 1\\to X^*\\otimes X$ are cups.",
    "Type $\\widetilde{\\mathrm{ev}}$ and $\\widetilde{\\mathrm{coev}}$ as `ev~_X` and `coev~_X`, or use the keypad buttons. The direction of the arrow around each cap or cup tells which one it is."),
19: ("Figure 2.2, the duality identities (1.12): $(\\mathrm{id}_X\\otimes\\mathrm{ev}_X)(\\mathrm{coev}_X\\otimes\\mathrm{id}_X)=\\mathrm{id}_X=(\\widetilde{\\mathrm{ev}}_X\\otimes\\mathrm{id}_X)(\\mathrm{id}_X\\otimes\\widetilde{\\mathrm{coev}}_X)$.",
    "Both zigzags straighten to the arc $X$: the left one by **(2.1) left zigzag**, the right one by **(2.1) right zigzag** (ẽv and c̃oev are paired automatically too)."),
20: ("Figure 2.2, the duality identities (1.13), the same on the arc $X^*$.",
    "Both zigzags straighten to the upward arc $X^*$."),
21: ("Figure 2.3: the dual morphism $f^*\\colon Y^*\\to X^*$ has two expressions, one with $\\mathrm{ev}$, $\\mathrm{coev}$ and one with $\\widetilde{\\mathrm{ev}}$, $\\widetilde{\\mathrm{coev}}$. That they agree is what makes the category pivotal.",
    "The rules **Fig. 2.3 fold (left)** and **Fig. 2.3 fold (right)** turn each picture into the single box $f^*$, so all three sides have the same normal form."),
22: ("Figure 2.4, first identity: $\\mathrm{ev}_X(f^*\\otimes\\mathrm{id}_X)=\\mathrm{ev}_Y(\\mathrm{id}_{Y^*}\\otimes f)$, the pivotal form of (2.2).",
    "**Fig. 2.4 slide through ev** moves the box across the cap."),
23: ("Figure 2.4: $(\\mathrm{id}_Y\\otimes f^*)\\mathrm{coev}_Y=(f\\otimes\\mathrm{id}_{X^*})\\mathrm{coev}_X$.",
    "**Fig. 2.4 slide through coev** moves the box across the cup."),
24: ("Figure 2.4, second line: $\\widetilde{\\mathrm{ev}}_X(\\mathrm{id}_X\\otimes f^*)=\\widetilde{\\mathrm{ev}}_Y(f\\otimes\\mathrm{id}_{Y^*})$.",
    "**Fig. 2.4 slide through right ev**: the same slide through the right cap $\\widetilde{\\mathrm{ev}}$."),
25: ("Figure 2.4: $(f^*\\otimes\\mathrm{id}_Y)\\widetilde{\\mathrm{coev}}_Y=(\\mathrm{id}_{X^*}\\otimes f)\\widetilde{\\mathrm{coev}}_X$.",
    "**Fig. 2.4 slide through right coev**: the same slide through the right cup $\\widetilde{\\mathrm{coev}}$."),
26: ("Exercise 2.1.5: a non-degenerate pairing $\\omega$ with inverse $\\Omega$ gives maps $\\varphi(f)=(\\mathrm{id}_Y\\otimes\\omega)(\\mathrm{id}_Y\\otimes f\\otimes\\mathrm{id}_Y)(\\Omega\\otimes\\mathrm{id}_Y)$ from $\\mathrm{End}(X)$ to $\\mathrm{End}(Y)$, and $\\psi$ back. The claim $\\psi(\\varphi(f))=f$ is typed with $\\varphi(f)$ written out inside $\\psi$.",
    "Two right zigzags straighten the doubled arc, and the box $f$ is left on its own."),
27: ("Exercise 2.1.5: $\\varphi$ reverses composition, $\\varphi(hf)=\\varphi(f)\\varphi(h)$.",
    "The left side is already in normal form. On the right side, the cap of $\\varphi(h)$ and the cup of $\\varphi(f)$ above it form a zigzag, which **(2.1) right zigzag** removes. What is left is the left side: $h$ and $f$ on one bent arc, in the order that $\\varphi(hf)$ has."),
28: ("§2.2: a cap on a tensor product is two nested caps, $\\mathrm{ev}_{Y\\otimes X}=\\mathrm{ev}_X(\\mathrm{id}_{X^*}\\otimes\\mathrm{ev}_Y\\otimes\\mathrm{id}_X)$. The arc $(Y\\otimes X)^*$ is the pair of arcs $X^*, Y^*$, in reversed order.",
    "Type `ev_{Y⊗X}`. The rule **caps and cups on ⊗** splits it into the nested pair."),
29: ("The same for a cup: $\\mathrm{coev}_{Y\\otimes X}=(\\mathrm{id}_Y\\otimes\\mathrm{coev}_X\\otimes\\mathrm{id}_{Y^*})\\mathrm{coev}_Y$.",
    "**caps and cups on ⊗** again."),
30: ("And for the right cap and cup: $\\widetilde{\\mathrm{ev}}_{Y\\otimes X}=\\widetilde{\\mathrm{ev}}_Y(\\mathrm{id}_Y\\otimes\\widetilde{\\mathrm{ev}}_X\\otimes\\mathrm{id}_{Y^*})$ and $\\widetilde{\\mathrm{coev}}_{Y\\otimes X}=(\\mathrm{id}_{X^*}\\otimes\\widetilde{\\mathrm{coev}}_Y\\otimes\\mathrm{id}_X)\\widetilde{\\mathrm{coev}}_X$, side by side.",
    "The rule fires once for each of the two boxes."),
31: ("Exercise 2.2.5: the isomorphism $?^*_2(X,Y)\\colon X^*\\otimes Y^*\\to(Y\\otimes X)^*$ of §1.7.1 (the symbol is printed as “?” in our copy of the book) and its inverse, drawn as in §2.1.3, compose to the identity. Here the left picture of the inverse is stacked on the left picture of $?^*_2$, with the arcs coloured $(Y\\otimes X)^*$ already written as $X^*, Y^*$.",
    "Simplify first splits $\\mathrm{coev}_{Y\\otimes X}$ and $\\mathrm{ev}_{Y\\otimes X}$ into nested caps and cups, then four zigzags straighten the arcs, leaving $\\mathrm{id}_{X^*\\otimes Y^*}$."),
32: ("Figure 2.5, a Penrose diagram (§2.2.2–2.2.3) with boxes $g\\colon X\\otimes Z^*\\to X\\otimes V$, $h\\colon A\\to Y^*\\otimes B$, $k\\colon\\mathbb 1\\to Z^*\\otimes Y$ and $l\\colon\\mathbb 1\\to\\mathbb 1$. Cutting it into horizontal strips gives the five-factor morphism of p. 38, from $P_\\bullet=A^*\\otimes A$ to $P^\\bullet=U\\otimes U^*\\otimes A^*\\otimes V\\otimes B$. The expression is that formula, typed strip by strip, top strip first.",
    "Expression → Diagram rebuilds the picture from the formula (the layout differs from the book's drawing, but it is the same diagram up to isotopy). Simplify straightens the zigzag inside the W-shaped $X$ arc. What is left of it is a closed loop $\\mathrm{ev}_X\\widetilde{\\mathrm{coev}}_X$, the dimension of $X$, which no rule of §2.1–2.2 removes."),
33: ("Lemma 2.1: the morphism of a Penrose diagram does not change under isotopy, under straightening a zigzag (Figure 2.2), or under pushing a cap, cup or box up or down. The right side is Figure 2.5 with the zigzag in the $X$ arc straightened, so its bottom two strips are simpler.",
    "Both sides reach the same normal form, so the equation holds, as Lemma 2.1 says."),
34: ("§2.3.1 defines $\\psi_X = (\\widetilde{\\mathrm{ev}}_X\\otimes\\mathrm{id}_{X^{**}})(\\mathrm{id}_X\\otimes\\mathrm{coev}_{X^*})\\colon X\\to X^{**}$. The editor identifies $X^{**}$ with $X$ (a strict pivotal category), so $\\psi_X$ should be the identity.",
    "**Lemma 2.3 (X\\*\\* = X)** turns the cup $\\mathrm{coev}_{X^*}$ into $\\widetilde{\\mathrm{coev}}_X$; then **(2.1) right zigzag** straightens the arc. The Wolfram notebook keeps $X^{**}$ apart from $X$ and reduces the same picture to a box $\\psi_X$ instead."),
35: ("Lemma 2.2: $\\psi_X$ can also be drawn the other way round, $\\varphi_X = (\\mathrm{id}_{X^{**}}\\otimes\\mathrm{ev}_X)(\\widetilde{\\mathrm{coev}}_{X^*}\\otimes\\mathrm{id}_X)$, and $\\psi_X=\\varphi_X$.",
    "Each side needs one rename by Lemma 2.3 and one zigzag, the left side a right zigzag and the right side a left one."),
36: ("Lemma 2.2: the inverse $\\psi_X^{-1}$ has two pictures, $\\vartheta_X = (\\mathrm{id}_X\\otimes\\widetilde{\\mathrm{ev}}_{X^*})(\\mathrm{coev}_X\\otimes\\mathrm{id}_{X^{**}})$ and $\\nu_X = (\\mathrm{ev}_{X^*}\\otimes\\mathrm{id}_X)(\\mathrm{id}_{X^{**}}\\otimes\\widetilde{\\mathrm{coev}}_X)$. Type $\\psi_X^{-1}$ as `ψ⁻¹_X`.",
    "The box $\\psi^{-1}_X$ is the identity when $X^{**}=X$ (**ψ = id (X\\*\\* = X)**); the two pictures straighten by Lemma 2.3 and a zigzag."),
37: ("Lemma 2.3, first formula: $\\widetilde{\\mathrm{ev}}_X = \\mathrm{ev}_{X^*}(\\psi_X\\otimes\\mathrm{id}_{X^*})$. The right evaluation is the left evaluation of $X^*$, corrected by $\\psi_X$.",
    "On the right side, Lemma 2.3 renames $\\mathrm{ev}_{X^*}$ to $\\widetilde{\\mathrm{ev}}_X$ and the box $\\psi_X$ disappears."),
38: ("Lemma 2.3, second formula: $\\widetilde{\\mathrm{coev}}_X = (\\mathrm{id}_{X^*}\\otimes\\psi_X^{-1})\\,\\mathrm{coev}_{X^*}$.",
    "The same two steps on the cup. The other two formulas of Lemma 2.3 are in the Wolfram notebook, where $\\psi_X$ is a real box."),
39: ("§2.3.2: a tuple of signed objects $S$ gives a generalized evaluation $\\mathrm{ev}_S$, a nest of caps. The book's example is $\\mathrm{ev}_{((X,-),(Y,+))}\\colon (Y^*\\otimes X)\\otimes(X^*\\otimes Y)\\to\\mathbb 1$, with $\\widetilde{\\mathrm{ev}}_X$ inside $\\mathrm{ev}_Y$. Lemma 2.4 says $\\mathrm{ev}_S = \\mathrm{ev}_{X_S}(\\Psi_{S^*}\\otimes\\mathrm{id})$, and with $X^{**}=X$ the isomorphism $\\Psi_{S^*}$ is the identity, so $\\mathrm{ev}_S$ is the cap $\\mathrm{ev}_{X^*\\otimes Y}$.",
    "**caps and cups on ⊗** splits $\\mathrm{ev}_{X^*\\otimes Y}$ into $\\mathrm{ev}_{X^*}$ inside $\\mathrm{ev}_Y$, and Lemma 2.3 renames $\\mathrm{ev}_{X^*}$ to $\\widetilde{\\mathrm{ev}}_X$."),
40: ("Formula (2.3): $(\\mathrm{id}_{X_S}\\otimes\\mathrm{ev}_S)(\\mathrm{coev}_S\\otimes\\mathrm{id}_{X_S}) = \\mathrm{id}_{X_S}$, so $\\mathrm{ev}_S$ is a non-degenerate pairing with inverse $\\mathrm{coev}_S$. Here $S = ((X,-),(Y,+))$ and $X_S = X^*\\otimes Y$.",
    "The nested cap and cup are split, and two left zigzags straighten the two arcs."),
41: ("§2.4, Lemma 2.5 and the naturality of $\\psi$ in §2.5.1: a box turned through 360°, with its arcs following it round, is the box itself. With $X^{**}=X$ the turned picture is $f^{**}$, written out as two nested copies of Figure 2.3.",
    "The inner copy folds into $f^*$; the outer cup and cap are on starred colours, so Lemma 2.3 renames them, $f^*$ slides through the cup and becomes $f$, and a right zigzag straightens the rest."),
42: ("§2.6.1: the left trace of $f\\colon X\\to X$ is the loop $\\mathrm{tr}_l(f) = \\mathrm{ev}_X(\\mathrm{id}_{X^*}\\otimes f)\\widetilde{\\mathrm{coev}}_X$. Traces are symmetric: for $p\\colon X\\to Y$ and $q\\colon Y\\to X$, $\\mathrm{tr}_l(qp)=\\mathrm{tr}_l(pq)$.",
    "The rule **trace symmetry (§2.6.1)** turns a loop so that its boxes start at the first name in a fixed order. Both sides become the loop with $p$ then $q$ on it."),
43: ("The right trace is the loop the other way round, $\\mathrm{tr}_r(f) = \\widetilde{\\mathrm{ev}}_X(f\\otimes\\mathrm{id}_{X^*})\\mathrm{coev}_X$, with the box on the left leg. It is symmetric too.",
    "**trace symmetry** works on right loops as well."),
44: ("§2.6.1: $\\mathrm{tr}_l(f) = \\mathrm{tr}_r(f^*)$. The right trace of the dual box, on a loop coloured $X^*$, is the left trace of the box.",
    "Lemma 2.3 renames the cup and the cap coloured $X^*$; in between, $f^*$ slides through the cup ($\\widetilde{\\mathrm{coev}}_X$) to become $f$ on the other leg."),
45: ("§2.6.1: $\\mathrm{tr}_l(f\\otimes g) = \\mathrm{tr}_l(\\mathrm{tr}_l(f)\\cdot g)$. The loop coloured $X\\otimes Y$ is a loop on $Y$ with a loop on $X$ inside it.",
    "Splitting the cap and the cup on $X\\otimes Y$ gives exactly the nested loops of the right side."),
46: ("§2.6.2: $\\dim_l(X) = \\mathrm{ev}_X\\widetilde{\\mathrm{coev}}_X$ and $\\dim_r(X) = \\widetilde{\\mathrm{ev}}_X\\mathrm{coev}_X$ are the empty loops, and $\\dim_l(X) = \\dim_r(X^*)$.",
    "Lemma 2.3 renames the cup and the cap of the right side, which turns the right loop on $X^*$ into the left loop on $X$."),
47: ("§2.6.2: isomorphic objects have the same dimensions. For an isomorphism $u\\colon X\\to Y$ with inverse $u'$, $\\dim_l(X) = \\mathrm{tr}_l(u'u) = \\mathrm{tr}_l(uu') = \\dim_l(Y)$. The signature line `inverse u u′` declares $u'$ the inverse of $u$.",
    "**trace symmetry** first turns the right side so that it starts at $u$, then **inverse boxes** cancels $u'u$ on both sides, leaving $\\dim_l(X)$."),
48: ("§2.7.1: a spherical category is a pivotal category whose left and right traces agree, $\\mathrm{tr}_l(f) = \\mathrm{tr}_r(f)$. This example switches on **spherical** under the buttons.",
    "With **spherical** on, the rule **sphericity (§2.7.1)** turns a right loop into a left loop. Without it the two traces stay apart, as they should: the Wolfram notebook gives a pivotal category of weighted vector spaces (Example 2.7.2) where they differ."),
49: ("In a spherical category the left and right dimensions agree, and $\\dim(X)$ is the dimension of $X$.",
    "**sphericity** turns the empty right loop into the empty left loop."),
50: ("Lemma 2.9: in a spherical category, a closed diagram may be moved on the sphere $S^2$. Pushing a strand across the point at infinity turns a right trace into a left trace; here $\\mathrm{tr}_r(qp)$ on $X$ becomes $\\mathrm{tr}_l(pq)$ on $Y$.",
    "The left side goes through **sphericity**, the right side through **trace symmetry**, and both end as the left loop with $p$ then $q$ on it."),
51: ("§2.7.3, Lemma 2.10: in the category of projective modules, the left trace is the Hattori–Stallings trace. A projective module $X$ sits in a free module $Y$ with inclusion $j$ and projection $p$, so $pj = \\mathrm{id}_X$; the proof is $\\mathrm{tr}_l(jfp) = \\mathrm{tr}_l(fpj) = \\mathrm{tr}_l(f)$. The signature line `retract p j` declares $pj = \\mathrm{id}_X$.",
    "**trace symmetry** turns the loop so that it starts at $f$; then $j$ sits directly below $p$ and **retract (§2.7.3)** removes them. (Exercise 2.7.4, on equivalent pivotal categories, is a statement about functors and is not in the editor.)"),
52: ("Chapter 3, §3.1.1: a braiding is a natural family of isomorphisms $\\tau_{X,Y}\\colon X\\otimes Y\\to Y\\otimes X$, drawn as a crossing in which the strand from $X$ passes over (Figure 3.1). It is ⊗-multiplicative: (3.1) $\\tau_{X,Y\\otimes Z} = (\\mathrm{id}_Y\\otimes\\tau_{X,Z})(\\tau_{X,Y}\\otimes\\mathrm{id}_Z)$. Type it as `τ_{X,Y⊗Z}`.",
    "The rule **braiding on ⊗ (3.1)–(3.3)** splits the crossing of $X$ over the pair $Y\\otimes Z$ into two crossings of single strands. With the unit, (3.3) $\\tau_{X,\\mathbb 1} = \\tau_{\\mathbb 1,X} = \\mathrm{id}_X$, the same rule removes the box."),
53: ("(3.2): $\\tau_{X\\otimes Y,Z} = (\\tau_{X,Z}\\otimes\\mathrm{id}_Y)(\\mathrm{id}_X\\otimes\\tau_{Y,Z})$.",
    "The same rule, now splitting the left factor."),
54: ("Naturality of the braiding: $\\tau_{X',Y'}(f\\otimes g) = (g\\otimes f)\\tau_{X,Y}$ for $f\\colon X\\to X'$ and $g\\colon Y\\to Y'$. Boxes slide along the strands through the crossing.",
    "The rule **R4, R5: naturality of τ** moves a one-line box from above a crossing to below it, on the same strand. Applied twice, it turns the right side into the left side."),
55: ("Exercise 3.1.12: every braiding satisfies the Yang–Baxter equation $(\\tau_{Y,Z}\\otimes\\mathrm{id}_X)(\\mathrm{id}_Y\\otimes\\tau_{X,Z})(\\tau_{X,Y}\\otimes\\mathrm{id}_Z) = (\\mathrm{id}_Z\\otimes\\tau_{X,Y})(\\tau_{X,Z}\\otimes\\mathrm{id}_Y)(\\mathrm{id}_X\\otimes\\tau_{Y,Z})$. Pictorially it is the Reidemeister move R3: a strand slides over a crossing.",
    "The rule **R3: Yang–Baxter** rewrites three consecutive crossings of the same kind, on positions $a, a+1, a$, into the order $a+1, a, a+1$."),
56: ("Exercise 3.1.12, the proof: naturality of $\\tau_{X,-}$ for the box $\\tau_{Y,Z}\\colon Y\\otimes Z\\to Z\\otimes Y$ reads $\\tau_{X,Z\\otimes Y}(\\mathrm{id}_X\\otimes\\tau_{Y,Z}) = (\\tau_{Y,Z}\\otimes\\mathrm{id}_X)\\tau_{X,Y\\otimes Z}$.",
    "Splitting the crossings of tensor products by (3.1) turns the two sides into the two sides of the Yang–Baxter equation, and **R3** finishes."),
57: ("Figure 3.1: the two kinds of crossing. In $\\tau_{X,Y}$ the strand from $X$ (bottom left) passes over; in $\\tau^{-1}_{Y,X}$ (typed `τ⁻¹_{Y,X}`), the inverse of $\\tau_{Y,X}$, the strand from $Y$ (bottom right) passes over. Both go from $X\\otimes Y$ to $Y\\otimes X$.",
    "The editor draws both as crossings, with a gap in the under-pass."),
58: ("§3.2.2, the move R2: a crossing followed by the inverse crossing on the same two strands is the identity.",
    "**R2 (§3.2.2)** removes the pair."),
59: ("R3 for crossings of the other kind: the Yang–Baxter equation also holds for the inverse crossings $\\tau^{-1}$.",
    "**R3: Yang–Baxter** applies to three crossings of the same kind, positive or negative."),
60: ("R4: a strand that passes over a box can be pushed off it. In formulas this is the naturality of $\\tau_{X,Y}$ in $X$.",
    "**R4, R5: naturality of τ** moves the box below the crossing."),
61: ("R5: the same for a strand that passes under a box, the naturality of the inverse crossing.",
    "The same rule moves the box through $\\tau^{-1}_{Y,X}$."),
62: ("Lemma 3.1 says that the Reidemeister moves R2–R5 preserve the morphism of a Reidemeister diagram, also when strands point up. Here the crossing is on an upward strand coloured $X^*$, with duals written $X^*$.",
    "The box slides through the crossing just as before: in the layered form an upward strand is simply a strand coloured $X^*$. (The move R1 needs the twists of §3.3; see Theorem 3.3 below.)"),
63: ("§3.1.2: a braiding is symmetric when $\\tau_{Y,X}\\tau_{X,Y} = \\mathrm{id}_{X\\otimes Y}$, as for the flip of sets or vector spaces (Examples 3.1.3–3.1.4) and the signed flip of super vector spaces (Example 3.1.5). This example switches on **symmetric** under the buttons.",
    "With **symmetric** on, the rule **τ_Y,X τ_X,Y = id (§3.1.2)** removes two crossings of the same kind stacked on the same strands. Without it the equation is (rightly) not proved."),
64: ("Remark 3.2.3: for a symmetric braiding the two crossings of Figure 3.1 are the same morphism, $\\tau^{-1}_{Y,X} = \\tau_{X,Y}$, so over- and under-passes do not matter.",
    "**symmetry (§3.1.2)** turns every under-crossing into the over-crossing."),
65: ("§3.3.1: in a braided pivotal category the **left twist** is the curl $\\theta^l_X = (\\mathrm{ev}_X \\otimes \\mathrm{id}_X)(\\mathrm{id}_{X^*} \\otimes \\tau_{X,X})(\\widetilde{\\mathrm{coev}}_X \\otimes \\mathrm{id}_X)$: the strand makes a loop to the left and crosses over itself. The twists are built in, typed `θˡ_X`, `θʳ_X`, `θˡ⁻¹_X` and `θʳ⁻¹_X` (keypad *Greek* for θ; ˡ and ʳ are the modifier letters).",
    "**twist fold (§3.3.1)** recognises the cup $\\widetilde{\\mathrm{coev}}_X$, the crossing and the cap $\\mathrm{ev}_X$ and replaces the three by one box $\\theta^l_X$."),
66: ("§3.3.1: the **right twist** $\\theta^r_X = (\\mathrm{id}_X \\otimes \\widetilde{\\mathrm{ev}}_X)(\\tau_{X,X} \\otimes \\mathrm{id}_{X^*})(\\mathrm{id}_X \\otimes \\mathrm{coev}_X)$ is the mirror curl, a loop to the right.",
    "The same rule folds the right-hand curl into $\\theta^r_X$."),
67: ("Lemma 3.2: the twists are invertible, and the inverse of $\\theta^l_X$ is the right-hand curl with the inverse crossing, $(\\theta^l_X)^{-1} = (\\mathrm{id}_X \\otimes \\widetilde{\\mathrm{ev}}_X)(\\tau^{-1}_{X,X} \\otimes \\mathrm{id}_{X^*})(\\mathrm{id}_X \\otimes \\mathrm{coev}_X)$.",
    "**twist fold (§3.3.1)** reads the sign of the crossing: a right-hand curl with $\\tau^{-1}$ becomes $\\theta^{l\\,-1}_X$."),
68: ("Lemma 3.2: likewise $(\\theta^r_X)^{-1}$ is the left-hand curl with the inverse crossing.",
    "The left-hand curl with $\\tau^{-1}$ becomes $\\theta^{r\\,-1}_X$."),
69: ("Lemma 3.2 drawn out: $\\theta^l_X(\\theta^l_X)^{-1} = \\mathrm{id}_X$ with both curls written as cups, crossings and caps.",
    "In the normal form the layers of the two curls interleave, so the fold follows each curl's strands past layers that do not touch them (level exchange). It folds the curl with $\\tau^{-1}$ first, then the other, and **twists cancel (Lemma 3.2)** removes $\\theta^l_X$ with its inverse."),
70: ("Lemma 3.2: $(\\theta^r_X)^{-1}\\theta^r_X = \\mathrm{id}_X$, with the boxes typed directly.",
    "**twists cancel (Lemma 3.2)** removes a twist directly above its inverse on the same strand."),
71: ("Lemma 3.2: the twist is a natural isomorphism, $\\theta_Y g = g\\,\\theta_X$ for every $g : X \\to Y$.",
    "**naturality of θ (Lemma 3.2)** moves a twist from above a one-line box to below it; both sides end as $g\\,\\theta^l_X$."),
72: ("Lemma 3.2 for $\\theta^r$, with the curl on $Y$ drawn out above $g$.",
    "The curl is folded into $\\theta^r_Y$, which then slides below $g$ and becomes $\\theta^r_X$."),
73: ("A curl on an upward strand: the same picture coloured $X^*$ is $\\theta^l_{X^*}$. (Lemma 3.2 also gives $(\\theta^r_X)^* = \\theta^l_{X^*}$; that identity is checked in the Wolfram notebook in matrices.)",
    "With $X^{**} = X$ the cup and cap of the curl are $\\widetilde{\\mathrm{coev}}_{X^*}$ and $\\mathrm{ev}_{X^*}$; the fold, which comes before Lemma 2.3, folds the curl into $\\theta^l_{X^*}$."),
74: ("Exercise 3.3.3: the twist of a tensor product is $\\theta_{X\\otimes Y} = (\\theta_X \\otimes \\theta_Y)\\,\\tau_{Y,X}\\tau_{X,Y}$, and $\\theta_{\\mathbb 1} = \\mathrm{id}_{\\mathbb 1}$.",
    "**twist on ⊗ (Exercise 3.3.3)** writes $\\theta_{X\\otimes Y}$ as the double crossing followed by the twists of the two strands."),
75: ("§3.3.2: a braided pivotal category is **ribbon** when $\\theta^l_X = \\theta^r_X$ for all $X$; the common value is the twist $\\theta_X$. This example switches on **ribbon** under the buttons.",
    "With **ribbon** on, **ribbon: θʳ = θˡ (§3.3.2)** writes every right twist as the left twist. Without it the equation is (rightly) not proved: in a braided pivotal category the two twists can differ."),
76: ("Theorem 3.3: in a ribbon category the move R1 holds: a right-hand curl followed by a left-hand curl with the inverse crossing is the identity, since it is $\\theta^r_X(\\theta^l_X)^{-1} = \\mathrm{id}_X$.",
    "The two curls fold to $\\theta^r_X$ and $\\theta^{l\\,-1}_X$, **ribbon** makes the first $\\theta^l_X$, and **twists cancel** finishes."),
77: ("Corollary 3.4: a ribbon category is spherical, $\\mathrm{tr}_l(k) = \\mathrm{tr}_r(k)$.",
    "With **ribbon** on, the editor (like the kernel) also uses **sphericity (§2.7.1)**, which turns the right loop into the left loop."),
}

GROUPS = [
 ("§2.1.1–2.1.2 Categories and monoidal categories", range(0, 7)),
 ("§2.1.2 Pairings and the zigzag identities (2.1)", range(7, 12)),
 ("§2.1.2 Left duals: ∨f and the identities (2.2)", range(12, 16)),
 ("§2.1.3 Pivotal categories: Figures 2.2–2.4", range(16, 26)),
 ("Exercise 2.1.5 Pairings and anti-isomorphisms", range(26, 28)),
 ("§2.2 Penrose diagrams", range(28, 34)),
 ("§2.3 Double duals and generalized evaluations", range(34, 41)),
 ("§2.4–2.6 Isotopy, traces and dimensions", range(41, 48)),
 ("§2.7 Spherical categories", range(48, 52)),
 ("§3.1 Braidings and symmetries", range(52, 58)),
 ("§3.2 The Reidemeister calculus", range(58, 63)),
 ("§3.1.2 Symmetries and Remark 3.2.3", range(63, 65)),
 ("§3.3.1 Twists and Lemma 3.2", range(65, 74)),
 ("Exercise 3.3.3 Twists of tensor products", range(74, 75)),
 ("§3.3.2 Ribbon categories", range(75, 78)),
]

L = []
A = L.append
A("# Introduction to CCN String Diagrams\n")
A("**Dara O Shayda and Noor Hoshino (星野ヌール)**\n")
A("*A guided tour of the examples in the CCN String Diagrams editor, after Turaev & Virelizier, “Monoidal Categories and Topological Field Theory”, Chapters 2–3, §2.1–3.3 (pp. 31–62).*\n")
A("© Computational Classnotes · CC BY-NC-SA 4.0\n")
A("Editor: <https://lossofgenerality.github.io/ccn-string-diagrams/string-diagram-editor.html> · Source: <https://github.com/lossofgenerality/ccn-string-diagrams>\n")
A("## Contents\n")
A("1. The editor\n2. Conventions and typing\n3. How the simplifier works\n" + "".join(f"{k+4}. {g[0]}\n" for k, g in enumerate(GROUPS)) + f"{len(GROUPS)+4}. The two engines\n")
A("## 1. The editor\n")
A("CCN String Diagrams is a box-and-arrow editor for the graphical calculus of monoidal categories. It runs in one HTML page, online or offline. The canvas on the left holds the diagram; the panel on the right holds the expression, a keypad of the book's symbols, the three main buttons and the result.\n")
A("![The editor with Figure 2.3 loaded and simplified](img/ui.png)\n")
A("- **Expression → Diagram** draws the typed expression.\n- **Diagram → Expression** reads the drawn diagram back as an expression, in the book's notation.\n- **Simplify** rewrites the diagram step by step with the rules of the book, shows every step with the name of the rule used, and, for an equation, says whether both sides reach the same normal form.\n")
A("Every example in this document is in the editor's **Load an example…** menu. Loading one fills in the expression and the signature, sets the duals mode, and draws the diagram. Each section below shows the expression (symbolic), the diagram the editor draws (graphical), and what Simplify does with it. The pictures are screenshots of the editor itself.\n")
A("## 2. Conventions and typing\n")
A("The editor follows the book:\n")
A("- **Diagrams read bottom to top.** Sources are at the bottom and targets at the top, so in $gf$ the box $f$ sits below $g$. (The direction can be flipped in the toolbar.)\n"
  "- **Composition is juxtaposition:** `g f` is $gf$. It binds tighter than $\\otimes$; `g ∘ f` and `f ; g` are also accepted.\n"
  "- **$\\otimes$ is side by side**, left to right. Type `⊗` (or `(x)`).\n"
  "- **The unit** $\\mathbb 1$ is typed `𝟙`, `I` or `1`, and is never drawn.\n"
  "- **Identities** are `id_X`; tensor colours are written in braces, `id_{X⊗Y}` or `ev_{Y⊗X}`.\n"
  "- **Duals.** With *duals: ∨X* (§2.1.2) the left dual is `∨X`, and `ev_X`, `coev_X`, `∨f` are built in. With *duals: X\\** (§2.1.3, pivotal) the dual is `X*`, arcs carry arrows ($X$ points down, $X^*$ points up), and `ev_X`, `ev~_X` ($\\widetilde{\\mathrm{ev}}_X$), `coev_X`, `coev~_X` ($\\widetilde{\\mathrm{coev}}_X$) and `f*` are built in.\n")
A("The **signature** box declares the boxes, one per line:\n")
A("```\nf : X → Y\ng : Y → Z\nω : X ⊗ Y → 𝟙\nΩ : 𝟙 → Y ⊗ X\npairing ω Ω\n```\n")
A("`pairing ω Ω` says that $\\Omega$ is the inverse of the pairing $\\omega$, so the zigzag rules may cancel them. The keypad (tabs *Book*, *Greek*, *Letters*) types every symbol, and the preview under the expression typesets it as in the book.\n")
A("## 3. How the simplifier works\n")
A("The simplifier works on the **layered form** of a diagram: the source colours, then one box per layer, each with the number of arcs to its left. **Level exchange** (Figure 2.1) lets two layers swap when their boxes do not touch, and every diagram is brought to a normal form in which boxes sit as low and as far left as they can. The rules are then tried in this order, and the first one that applies is used:\n")
A("| Rule | Book | What it does |\n|---|---|---|\n"
  "| unit strands, ⊗-coloured strands | §2.1.2 | erase arcs coloured $\\mathbb 1$; split an arc coloured $X\\otimes Y$ into two |\n"
  "| caps and cups on ⊗ (pivotal) | §2.2 | $\\mathrm{ev}_{Y\\otimes X}=\\mathrm{ev}_X(\\mathrm{id}_{X^*}\\otimes\\mathrm{ev}_Y\\otimes\\mathrm{id}_X)$ and the same for coev, ẽv, c̃oev |\n"
  "| (2.1) left zigzag, (2.1) right zigzag | (2.1), Fig. 2.2 | cancel a pairing and its inverse that form a zigzag |\n"
  "| definition of ∨f / Fig. 2.3 fold (left) | §2.1.2, Fig. 2.3 | fold cup–box–cap into the dual box |\n"
  "| Fig. 2.3 fold (right) | Fig. 2.3 | the same with ẽv and c̃oev |\n"
  "| (2.2) slide through ev / coev, Fig. 2.4 slides | (2.2), Fig. 2.4 | move a dual box across a cap or cup |\n"
  "| Lemma 2.3 (X\\*\\* = X), ψ = id (X\\*\\* = X) | §2.3.1 | with $X^{**}=X$: $\\mathrm{ev}_{X^*}=\\widetilde{\\mathrm{ev}}_X$, $\\mathrm{coev}_{X^*}=\\widetilde{\\mathrm{coev}}_X$ and the reverse, and $\\psi_X=\\mathrm{id}_X$ |\n"
  "| trace symmetry (§2.6.1) | §2.6.1 | turn a loop so that its boxes start at the first name in code-point order |\n"
  "| inverse boxes | §2.6.2 | cancel $u'u$ and $uu'$ for a declared pair `inverse u u′` |\n"
  "| sphericity (§2.7.1) | §2.7.1 | spherical only: a right loop becomes a left loop |\n"
  "| retract (§2.7.3) | §2.7.3 | cancel $pj$ for a declared retraction `retract p j` |\n"
  "| braiding on ⊗ (3.1)–(3.3) | §3.1.1 | split a crossing of tensor products into crossings of single strands; remove a crossing with $\\mathbb 1$ |\n"
  "| R2 (§3.2.2) | §3.2.2 | a crossing and its inverse cancel |\n"
  "| R4, R5: naturality of τ | §3.1.1, §3.2.2 | a one-line box moves from above a crossing to below it |\n"
  "| R3: Yang–Baxter | Exercise 3.1.12 | three crossings of one kind on positions $a, a+1, a$ become $a+1, a, a+1$ |\n"
  "| twist fold (§3.3.1) | §3.3.1, Lemma 3.2 | pivotal only, tried before Lemma 2.3: a curl (cup, crossing, cap) becomes $\\theta^l_X$, $\\theta^r_X$ or an inverse; layers that do not touch the curl may sit between its parts |\n"
  "| twists cancel, naturality of θ | Lemma 3.2 | a twist and its inverse cancel; a twist moves below a one-line box |\n"
  "| twist on ⊗ (Exercise 3.3.3) | Exercise 3.3.3 | $\\theta_{X\\otimes Y} = (\\theta_X\\otimes\\theta_Y)\\tau_{Y,X}\\tau_{X,Y}$, $\\theta_{\\mathbb 1} = \\mathrm{id}$ |\n"
  "| ribbon: θʳ = θˡ (§3.3.2) | §3.3.2, Cor. 3.4 | ribbon only: the right twist is the left twist; ribbon also switches on sphericity |\n"
  "| symmetry (§3.1.2), τ_Y,X τ_X,Y = id | §3.1.2 | symmetric only: under-crossings become over-crossings, and a crossing twice is the identity |\n")
A("Each step is shown with its rule name. An equation holds when all its sides reach the same normal form. Every rule makes the diagram smaller, so Simplify always stops.\n")

for k, (gname, rng) in enumerate(GROUPS):
    A(f"## {k+4}. {gname}\n")
    for i in rng:
        x = D[i]; book, look = X[i]
        A(f"### {x['title']}\n")
        A(book + "\n")
        A("**Type it.** Signature and expression:\n")
        sig = "\n".join(l for l in x['sig'].split('\n') if not l.startswith('#'))
        A("```\n" + sig + "\n```\n")
        A("```\n" + x['src'] + "\n```\n")
        A("**Symbolic.** The editor typesets it as\n")
        A(eqn(x['tex']) + "\n")
        dom, cod = x['type'][0]
        A(f"a morphism from ${objtex(dom)}$ to ${objtex(cod)}$.\n")
        A("**Graphical.** Expression → Diagram draws:\n")
        A(f"![{x['title']}](img/ex{i:02d}a.png)\n")
        rules = [s[0] for s in x['steps'][0][1:]]
        rules_all = sorted({s[0] for st in x['steps'] for s in st[1:]}, key=lambda r: [s[0] for st in x['steps'] for s in st].index(r))
        A("**Simplify.** " + look + "\n")
        if rules_all:
            seqs = []
            for st in x['steps']:
                rs = [s[0] for s in st[1:]]
                seqs.append(' → '.join(rs) if rs else 'already in normal form')
            if len(seqs) == 1: A(f"Steps: {seqs[0]}.\n")
            else: A("Steps, side by side: " + "; ".join(f"side {j+1}: {s}" for j, s in enumerate(seqs)) + ".\n")
            nfs = list(dict.fromkeys(x['nf']))
            A("Normal form:\n")
            A(disp(nfs[0]) + "\n")
            A(f"![{x['title']}, simplified](img/ex{i:02d}b.png)\n")
        else:
            A("No rewriting rule applies: the diagram is already in normal form" + (", and all sides have the same normal form." if len(x['tex']) > 1 else ".") + "\n")
        v = x['verdict'].strip()
        if v: A(f"The editor reports: *{v}*\n")

A(f"## {len(GROUPS)+4}. The two engines\n")
A("Simplify can run on either of two engines, chosen with **engine** under the buttons:\n")
A("- **JavaScript (offline):** a port of the Wolfram notebook engine, with the same layered form, the same level exchange and the same rules in the same order. It needs no network.\n"
  "- **Wolfram kernel:** the page sends the layered form to the `GraphicalCalculusKernel` API in the Wolfram Cloud, which runs the rules of the Wolfram notebooks (`graphical-calculus-2.1-simplify.nb`, `pivotal-2.1.3.wl`, `penrose-2.2.wl`, `pivotal-2.3-2.7.wl`, `braided-2.7-3.2.wl`, `ribbon-3.3.wl`). The page then compares the kernel's answer with the JavaScript engine and reports any difference.\n")
A("For §2.3–2.7 the editor works in a strict pivotal category: it identifies $X^{**}$ with $X$ and $\\psi_X$ with $\\mathrm{id}_X$. The Wolfram notebook `graphical-calculus-2.3-2.7.nb` keeps $X^{**}$ apart from $X$, draws $\\psi_X$ as a box, and proves Lemmas 2.2–2.4, Exercise 2.3.3 and Theorem 2.7 (strand by strand) with it; for the editor's inputs the kernel uses the strict forms of the same rules.\n")
A("For §3.3 the notebook `graphical-calculus-3.3.nb` also checks, in graded vector spaces with weights, that the model with weight 2 is braided pivotal but not ribbon, that the weights ±1 give a ribbon category, the duals of twists in Lemma 3.2, (3.4), Corollary 3.4, Lemma 3.5 for super vector spaces and Lemma 3.6.\n")
A("On every example in this document, both engines give the same sequence of rules and the same result. In the Wolfram notebooks the same identities are also checked in vector spaces, where $\\otimes$ is the Kronecker product and composition is the matrix product.\n")
A("---\n")
A("By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0\n")
open('/home/claude/intro/intro.md', 'w').write("\n".join(L))
print(len("\n".join(L)))
