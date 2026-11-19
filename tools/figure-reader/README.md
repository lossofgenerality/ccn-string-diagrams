# figreader: reading the book's diagrams automatically

By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0

The figures of Turaev & Virelizier, *Monoidal Categories and Topological Field Theory*, are vector graphics in the PDF: strands are line segments and Bézier curves, boxes are rectangles, arrow heads are small filled shapes, and every label is real text with a position. `figreader.py` reads those drawing instructions (with PyMuPDF) and rebuilds each diagram as a layered form, the data structure of the CCN String Diagrams code. No image recognition or OCR is involved.

```
pip install pymupdf
python3 figreader.py book.pdf 44 45 46 > figure-readings.json     # PDF page numbers
```

The output is a list of equations: `{"page": n, "sides": [{"bbox": [...], "src": [colours], "ls": [[a, name, ins, outs], ...], "error": null}, ...]}`.

How it reads a page:

1. **Primitives**: stroked paths become polylines, bordered rectangles are boxes, small filled shapes are arrow heads, text spans keep position and size.
2. **Pictures**: touching paths and boxes form a picture; pictures on a row are split into equation sides by `=`, and equations by `and`, `or`, commas and wide gaps.
3. **Strands**: paths are cut where they run behind a box and at every turning point in height; top turns are caps, bottom turns cups. Piece ends on a box's top or bottom edge are its outputs or inputs.
4. **Labels**: text inside a box names it (subscripts, ∗, ′ and ∨ handled); other words go to the nearest strand and colour its whole path.
5. **Arrows** (§2.1.3): the tip of each arrow head is compared with the direction of its path; a piece of colour X pointing up contributes X*. Caps and cups are named ev, ẽv, coev, c̃oev from the colours of their legs.
6. **Layers**: boxes, caps and cups are swept bottom to top over the list of strands crossing the current height.

`kernel/figure-reader.wl` (Wolfram) loads the JSON, turns each side into an `LD`, and checks it with `simplifier.wl`: does each side fit together, and do the sides of an equation reach the same normal form (`checkReading`, `readingReport`, `showReading`).

On pages 44–100 of the PDF (book pp. 32–88) the reader finds 265 pictures in 182 groups. 127 pictures are read completely, and 15 of the 59 equations with two or more sides are confirmed by the rules from the reading alone (all of Figures 2.1–2.4, (2.1), (2.2) and the definition of ∨f). Not handled yet: crossings (τ), the filled partition shapes of Chapter 4, labels split over several text spans, and multi-line labels.
