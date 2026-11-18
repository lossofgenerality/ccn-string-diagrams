# CCN String Diagrams

An editor for the graphical calculus of monoidal categories, after Turaev & Virelizier, *Monoidal Categories and Topological Field Theory* (Progress in Mathematics 322, Springer 2017), Chapter 2, §2.1.

**Live page:** https://lossofgenerality.github.io/ccn-string-diagrams/

**Authors:** Dara O Shayda and Noor Hoshino (星野ヌール)

## Files

| File | What it is |
|---|---|
| `index.html` | The landing page |
| `string-diagram-editor.html` | The editor: a single self-contained page that runs offline |
| `kernel/GraphicalCalculusKernel-deploy.wl` | Deploys the Wolfram Cloud API behind the editor's “Wolfram kernel” engine |
| `kernel/penrose-2.2.wl` | §2.2 in Wolfram: caps and cups on tensor products (`rulesT`), Exercise 2.2.5, signed objects, Penrose diagrams by strips, Figure 2.5 and Lemma 2.1 checks |
| `kernel/pivotal-2.3-2.7.wl` | §2.3–2.7 in Wolfram: ψ_X and Lemmas 2.2–2.4, ev_S and Ψ_S, a box turned through 360°, traces, dimensions, sphericity (`rulesD`, `rulesS`), and a weighted vector-space model (Example 2.7.2) for the matrix checks |
| `kernel/braided-2.7-3.2.wl` | §2.7.3 and §3.1–3.2 in Wolfram: Lemma 2.10 (proj_k), braidings τ and the rules (3.1)–(3.3), Reidemeister moves R2–R5, symmetries, the mirror braiding, and a graded vector-space model (Examples 3.1.4–3.1.6) for the matrix checks |
| `kernel/ribbon-3.3.wl` | §3.3.1–3.3.3 in Wolfram: twists θˡ, θʳ as curls, Lemma 3.2, Exercise 3.3.3, ribbon categories, Theorem 3.3 (R1), Corollary 3.4, Lemmas 3.5–3.6, and a graded, weighted vector-space model (ribbon exactly when the weights are ±1) |
| `docs/introduction-to-ccn-string-diagrams.md` (and `.pdf`) | Introduction to CCN String Diagrams: every example in the editor, with its expression, its diagram and what Simplify does. The `.md` is self-contained (all images embedded); `docs/README.md` is the same text with linked images, for reading on GitHub |

## The editor

- A box-and-arcs canvas with boxes, boxes with source or target 𝟙, dots, arc ends and “=” signs. It has undo, save and open, and SVG export.
- A maths keypad: ⊗, ∘, 𝟙, ∨, id, ev, coev, ω, Ω, Ω′, Greek letters and subscripts.
- **Expression → Diagram** and **Diagram → Expression**. Equations are written with `=` between the sides.
- **Simplify**, which applies the rules of §2.1 in priority order and shows every step: level exchange (Figure 2.1), the (2.1) left and right zigzags, the definition of ∨f, and the (2.2) slides through ev and coev. When an equation is entered, the two sides are compared by their normal forms.
- **Pivotal categories (§2.1.3)**, with the “duals: X*” setting: oriented arcs (an X arc points down, an X* arc points up), ev and ẽv drawn as caps, coev and c̃oev drawn as cups, and the rules for the duality identities (Figure 2.2), the two expressions for f* (Figure 2.3) and the dual morphism identities (Figure 2.4). Type ẽv and c̃oev as `ev~_X` and `coev~_X`, and duals as `X*` and `f*`.
- **Penrose diagrams (§2.2)**, also with “duals: X*”: caps and cups on a tensor product split into nested caps and cups, ev_(Y⊗X) = ev_X(id_X* ⊗ ev_Y ⊗ id_X) and the same for coev, ẽv and c̃oev. Type them as `ev_{Y⊗X}`. The examples include Exercise 2.2.5 ((?*₂)⁻¹ ?*₂ = id), Figure 2.5 typed in strip by strip as on p. 38, and Lemma 2.1 (Figure 2.5 with its zigzag straightened gives the same morphism).
- **Double duals, traces and sphericity (§2.3–2.7)**, also with “duals: X*”. The editor identifies X** with X, so ψ_X (typed `ψ_X`, inverse `ψ⁻¹_X`) is the identity, and Lemma 2.3 reads ev_X* = ẽv_X, coev_X* = c̃oev_X. Loops are traces: `ev_X(id_X* ⊗ f)coev~_X` is tr_l(f) and `ev~_X(f ⊗ id_X*)coev_X` is tr_r(f); the rule *trace symmetry* turns a loop so that tr(pq) = tr(qp). A signature line `inverse u u′` lets inverse boxes cancel. Tick **spherical** to add the rule tr_r = tr_l of §2.7.1.
- **Braidings and Reidemeister diagrams (§3.1–3.2)**, in either duals mode. Type the braiding as `τ_{X,Y}` (X over Y) and the other crossing as `τ⁻¹_{Y,X}`; both are drawn as crossings (Figure 3.1). The rules split crossings of tensor products ((3.1)–(3.3)) and apply the Reidemeister moves R2 (a crossing and its inverse cancel), R3 (Yang–Baxter) and R4, R5 (a box slides through a crossing). Tick **symmetric** for a symmetry (§3.1.2, Remark 3.2.3). A signature line `retract p j` declares p j = id (Lemma 2.10).
- **Twists and ribbon categories (§3.3)**, in X* mode. The twists `θˡ_X`, `θʳ_X` and their inverses `θˡ⁻¹_X`, `θʳ⁻¹_X` are built in. A curl drawn with a cup, a crossing and a cap folds to a twist (also when other layers sit between its parts); twists cancel with their inverses, slide through boxes (Lemma 3.2) and split on tensor products (Exercise 3.3.3). Tick **ribbon** for θʳ = θˡ (§3.3.2); R1 (Theorem 3.3) and sphericity (Corollary 3.4) then follow.

It uses the book's conventions. Diagrams read bottom to top (sources at the bottom, so in `gf` the box `f` sits below `g`), composition is written by juxtaposition (`gf`) and binds tighter than ⊗, and the unit is 𝟙.

## Two engines

- **JavaScript (offline):** a port of the rule engine in the Wolfram notebook `graphical-calculus-2.1-simplify.nb`, with the same layered form and the same functions: `swap`, `normalize`, `bubble`, `makeAdjacent` and the rules.
- **Wolfram kernel (notebook):** the page POSTs `payload_b64`, the base64 of the JSON `{src, ls:[{a,name,ins,outs}], pairings, rightFirst, pivotal}`, to `https://www.wolframcloud.com/obj/ccn2/GraphicalCalculusKernel`. The reply is `steps_b64`, the base64 of the JSON `[[rule, {src, ls}]]`. The API only applies the rewrite rules to the data it is sent; it evaluates no code.

Every Wolfram result is also worked out in JavaScript, and the page reports any difference between the two engines.

### Redeploying the kernel

The “Wolfram kernel” option sends the diagram's layered form to `GraphicalCalculusKernel`, a Wolfram Cloud API that runs the rules of the notebook `graphical-calculus-2.1-simplify.nb`. To redeploy it, evaluate [`kernel/GraphicalCalculusKernel-deploy.wl`](kernel/GraphicalCalculusKernel-deploy.wl) in a signed-in Wolfram session.

Put `graphical-calculus-2.1-simplify.nb` (sections 0–19), `pivotal-2.1.3.wl` (sections 20–27, which define `rulesP`), `penrose-2.2.wl` (sections 30–35, which define `rulesT`) `pivotal-2.3-2.7.wl` (sections 40–47, which define `rulesD` and `rulesS`) `braided-2.7-3.2.wl` (sections 50–55, which define `rulesB`, `rulesDB`, `rulesSB`) and `ribbon-3.3.wl` (sections 60–64, which define `twistRules`, `ribbonRules`, `withTwists`; copies of the last four are in `kernel/`) in one folder, `~/Desktop/Research/Monoidal Graphical Calculus`, together with the deploy file, or edit `gcDir` at the top of the `.wl` file. For requests with `pivotal: true` the kernel uses `rulesD`: `rulesP`, the §2.2 rules for caps and cups on a tensor product, and the §2.3–2.6 rules (Lemma 2.3, ψ, trace symmetry, inverse boxes); with `spherical: true` it uses `rulesS`, which adds sphericity. Every set includes the braiding rules of §3.1–3.2; pivotal sets also get the twist rules of §3.3, `ribbon: true` adds θʳ = θˡ and sphericity, and `symmetric: true` adds the symmetry rules. Requests also carry `inverses` and `retracts`, the declared pairs of inverse boxes and retractions. The editor's `ev~_X` and `coev~_X` become `Subscript[OverTilde["ev"], X]` and `Subscript[OverTilde["coev"], X]` there. CloudDeploy runs only when all eight checks pass. Then evaluate the whole file in a signed-in Wolfram session. It loads the notebook's engine, runs a check and calls `CloudDeploy`. Deploying under the same name keeps the URL.

---

© Computational Classnotes · CC BY-NC-SA 4.0
