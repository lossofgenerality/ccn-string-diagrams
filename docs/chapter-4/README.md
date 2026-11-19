# Chapter 4: the enriched graphical calculus

**Dara O Shayda and Noor Hoshino (星野ヌール)**

*After Turaev & Virelizier, “Monoidal Categories and Topological Field Theory”, Chapter 4 (§4.3.2 and §4.5.2–4.7, pp. 70–87).*

Each page below has one result: the statement, then the proof as a chain of steps. Each step is an example in [the editor](../../string-diagram-editor.html), and Simplify uses the rule the book cites for that step. Steps about single basis vectors, and Lemmas 4.6, 4.7 and 4.9(e)–(g), are checked in matrices in the Wolfram notebook `graphical-calculus-4.nb`. Its model is a category of graded vector spaces, pivotal but not spherical, so the left and right dimensions differ.

## Results

- [§4.3.2 The pairings ω are symmetric](4-3-2-pairings.md)
- [Lemma 4.2 Dimensions of simple objects](lemma-4-2.md)
- [§4.6.1–4.6.2 Curvilinear boxes](4-6-1-curvilinear-boxes.md)
- [§4.6.3 Properties (4.7)–(4.10)](4-6-3-properties.md)
- [Lemma 4.6 The S-matrix of a modular category](lemma-4-6.md)
- [Lemma 4.7 A dimension identity in fusion categories](lemma-4-7.md)
- [§4.6.4 Curvilinear boxes in braided categories](4-6-4-braided.md)
- [Lemma 4.8 The contraction vector of a pairing](lemma-4-8.md)
- [Lemma 4.9 Computations with curvilinear boxes](lemma-4-9.md)
- [Lemma 4.10 Which scalars make f = g](lemma-4-10.md)

## Using the editor for Chapter 4

- Set **duals** to X\* (pivotal) and tick **pre-fusion**.
- Signature lines: `simple i j k` (simple objects; summation variables are simple automatically), `partition α : X → i` (an $i$-partition, with boxes `p_α`, `q_α`; use `𝟙` for a 1-partition), `scalar a` (scalars $a_i$). `φ_{i,j} : i* → j` and `φ⁻¹_{i,j}` are built in.
- Expressions are linear combinations: `∑_i dim_l(i) N^i_X`, `δ_{i,j} dim_l(i)⁻¹ ev_i ⊗ coev~_i`, `a_k id_k ⊗ id_j*`.
- New rules, tried before trace symmetry: δ substitution, turning ω_S, Lemma 4.9(a)–(d), (4.7), (4.8), (4.9), isotopy: straightening, dimensions of simple objects, (4.10), (4.2), Lemma 4.2(b). The Wolfram kernel (`fusion-4-rules.wl`) has the same rules in the same order. On all 116 Chapter 4 requests it gives the same steps and the same terms as the JavaScript engine.

## A possible misprint

Lemma 4.6(b) as printed, $\sum_j v_iv_j\dim(j)S_{i,j} = \dim(\mathcal C)\dim(i)$, fails in the modular categories $\mathbb Z/3$ and $\mathbb Z/5$. It holds with $\Delta_+$ in place of $\dim(\mathcal C)$; see [Lemma 4.6](lemma-4-6.md).

---

By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0
