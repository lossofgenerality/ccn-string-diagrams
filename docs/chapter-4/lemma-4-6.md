# Lemma 4.6 The S-matrix of a modular category

[← Chapter 4 index](README.md)

In a ribbon fusion category the twist acts on a simple $i$ as $v_i\,\mathrm{id}_i$. With $\Delta_\pm = \sum_i v_i^{\pm 1}\dim(i)^2$ and $S_{i,j} = \mathrm{tr}(\tau_{j,i}\tau_{i,j})$, the category is modular when the S-matrix is invertible. **Lemma 4.6** states (a) $\sum_j S_{i,j}S_{j,r} = \dim(\mathcal C)\,\delta_{i^\circ,r}$, and (b) $\sum_j v_i v_j\dim(j)S_{i,j} = \dim(\mathcal C)\dim(i)$. The book cites [Tu1] for both and draws no diagram.

**Checked in matrices.** The notebook (section 78, `lemma46[n]`) builds the modular categories of $\mathbb Z/3$- and $\mathbb Z/5$-graded vector spaces, with braiding $\zeta^{gh}\cdot$flip ($\zeta = e^{2\pi i/n}$). It computes $v_i$ from the curl and $S_{i,j}$ from the trace of the double crossing:

| claim | $\mathbb Z/3$ | $\mathbb Z/5$ |
|---|---|---|
| S invertible (modular) | yes | yes |
| (a) | holds | holds |
| $\Delta_+\Delta_- = \dim(\mathcal C)$ (§4.5.2) | holds | holds |
| (b) as printed | **fails** | **fails** |
| (b) with $\Delta_+$ in place of $\dim(\mathcal C)$ | holds | holds |

In these categories the left side of (b) is the Gauss sum $\Delta_+$ ($i\sqrt 3$, $\sqrt 5$), not $\dim(\mathcal C) = 3, 5$. The formula that holds is $\sum_j v_i v_j\dim(j)S_{i,j} = \Delta_+\dim(i)$, equivalently $\sum_j v_j\dim(j)S_{i,j} = \Delta_+ v_i^{-1}\dim(i)$. **The printed (b) looks like a misprint.**

---

By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0
