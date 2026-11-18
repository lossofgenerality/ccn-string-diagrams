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

## The editor

- A box-and-arcs canvas with boxes, boxes with source or target 𝟙, dots, arc ends and “=” signs. It has undo, save and open, and SVG export.
- A maths keypad: ⊗, ∘, 𝟙, ∨, id, ev, coev, ω, Ω, Ω′, Greek letters and subscripts.
- **Expression → Diagram** and **Diagram → Expression**. Equations are written with `=` between the sides.
- **Simplify**, which applies the rules of §2.1 in priority order and shows every step: level exchange (Figure 2.1), the (2.1) left and right zigzags, the definition of ∨f, and the (2.2) slides through ev and coev. When an equation is entered, the two sides are compared by their normal forms.
- **Pivotal categories (§2.1.3)**, with the “duals: X*” setting: oriented arcs (an X arc points down, an X* arc points up), ev and ẽv drawn as caps, coev and c̃oev drawn as cups, and the rules for the duality identities (Figure 2.2), the two expressions for f* (Figure 2.3) and the dual morphism identities (Figure 2.4). Type ẽv and c̃oev as `ev~_X` and `coev~_X`, and duals as `X*` and `f*`.

It uses the book's conventions. Diagrams read bottom to top (sources at the bottom, so in `gf` the box `f` sits below `g`), composition is written by juxtaposition (`gf`) and binds tighter than ⊗, and the unit is 𝟙.

## Two engines

- **JavaScript (offline):** a port of the rule engine in the Wolfram notebook `graphical-calculus-2.1-simplify.nb`, with the same layered form and the same functions: `swap`, `normalize`, `bubble`, `makeAdjacent` and the rules.
- **Wolfram kernel (notebook):** the page POSTs `payload_b64`, the base64 of the JSON `{src, ls:[{a,name,ins,outs}], pairings, rightFirst, pivotal}`, to `https://www.wolframcloud.com/obj/ccn2/GraphicalCalculusKernel`. The reply is `steps_b64`, the base64 of the JSON `[[rule, {src, ls}]]`. The API only applies the rewrite rules to the data it is sent; it evaluates no code.

Every Wolfram result is also worked out in JavaScript, and the page reports any difference between the two engines.

### Redeploying the kernel

The “Wolfram kernel” option sends the diagram's layered form to `GraphicalCalculusKernel`, a Wolfram Cloud API that runs the rules of the notebook `graphical-calculus-2.1-simplify.nb`. To redeploy it, evaluate [`kernel/GraphicalCalculusKernel-deploy.wl`](kernel/GraphicalCalculusKernel-deploy.wl) in a signed-in Wolfram session.

Put `graphical-calculus-2.1-simplify.nb` (sections 0–19) and `pivotal-2.1.3.wl` (sections 20–27, which define `rulesP`) in `~/Downloads`, or edit `gcNotebook` and `gcPivotal` at the top of the `.wl` file. The kernel uses `rulesP` for requests with `pivotal: true`. The editor's `ev~_X` and `coev~_X` become `Subscript[OverTilde["ev"], X]` and `Subscript[OverTilde["coev"], X]` there. CloudDeploy runs only when both checks pass. Then evaluate the whole file in a signed-in Wolfram session. It loads the notebook's engine, runs a check and calls `CloudDeploy`. Deploying under the same name keeps the URL.

---

© Computational Classnotes · CC BY-NC-SA 4.0
