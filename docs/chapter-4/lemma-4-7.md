# Lemma 4.7 A dimension identity in fusion categories

[← Chapter 4 index](README.md)

**Lemma 4.7.** In a pivotal fusion category, $\sum_{m,n\in I}\dim_l(m)\dim_l(n)N^{\mathbb 1}_{X\otimes m\otimes Y\otimes n} = \dim_r(X)\dim_r(Y)\dim(\mathcal C)$, and the same with $l$ and $r$ exchanged.

The proof is a chain of scalar identities. Its only diagrammatic ingredient is (4.10), which the editor checks step by step ([§4.6.3](4-6-3-properties.md)). The notebook (section 78, `lemma47[]`) checks every link of the chain in the $\mathbb Z/3$-graded fusion category with $w(g) = \omega^g$ (pivotal, not spherical):

| link | justification in the book | checked |
|---|---|---|
| $\sum_{m,n}\dim_l(m)\dim_l(n)N^{\mathbb 1}_{X m Y n} = \sum_m\dim_l(m)\sum_n\dim_r(n^*)N^{n^*}_{X m Y}$ | $\dim_l(n) = \dim_r(n^*)$, duality | equal |
| $= \sum_m\dim_l(m)\sum_k\dim_r(k)N^k_{X m Y}$ | $n\mapsto n^*$ permutes $I$ | equal |
| $= \sum_m\dim_l(m)\dim_r(X\otimes m\otimes Y)$ | (4.10) | equal |
| $= \dim_r(X)\dim_r(Y)\dim(\mathcal C)$ | ⊗-multiplicativity | equal |

The notebook also checks the version with $l$ and $r$ exchanged.

---

By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0
