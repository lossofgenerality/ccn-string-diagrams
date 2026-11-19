cells = []
def C(style, text): cells.append((style, text))
T = lambda s: C("Text", s)
I = lambda s: C("Input", s)
P = lambda s: C("Program", s)
IT = lambda s: C("Item", s)
S = lambda s: C("Section", s)
SS = lambda s: C("Subsection", s)
SSS = lambda s: C("Subsubsection", s)

def fn(name, signature, args, returns, algorithm, notes, examples, messages=None):
    SS(name)
    SSS("Signature")
    P(signature)
    SSS("Arguments")
    for a in args: IT(a)
    SSS("Returns")
    T(returns)
    if algorithm:
        SSS("Algorithm")
        for k, a in enumerate(algorithm): IT(f"{k + 1}. {a}")
    if notes:
        SSS("Notes and limits")
        for n in notes: IT(n)
    if messages:
        SSS("Messages")
        for m in messages: IT(m)
    SSS("Examples")
    for e in examples:
        if e.startswith("#T "): T(e[3:])
        else: I(e)

C("Title", "DiagramToExpression: a programmer's manual")
C("Subtitle", "The Wolfram functions of CCN String Diagrams that turn boxes, lines and arrows into expressions")
T("By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0")
T("After Turaev & Virelizier, Monoidal Categories and Topological Field Theory, Chapter 2. The package is diagram-to-expression.wl, in the same folder as this notebook (Desktop/Research/Monoidal Graphical Calculus). It is self-contained: it needs neither the simplify notebook nor any other engine file.")

S("1. Loading the package")
T("Evaluate the cell below once per session. The package lives in the context DiagramToExpression`, so its names do not collide with the engine's (which live in Global` in the notebooks and in GraphicalCalculusKernel` in the kernel). After loading, the public names are on $ContextPath. The private helpers are in DiagramToExpression`Private`.")
I('Get[FileNameJoin[{$HomeDirectory, "Desktop", "Research", "Monoidal Graphical Calculus", "diagram-to-expression.wl"}]]')
T("Every public symbol has a usage message. For example:")
I('?toExpression')
I('Names["DiagramToExpression`*"]')

S("2. Overview: four representations and the maps between them")
T("A string diagram exists in this project in four forms. The translators convert between them, and three of them end in an algebraic expression:")
IT("StringDiagram[boxes, strands]: a drawn diagram, with coordinates. This is what the notebooks render, and what the reference translator toExpression reads.")
IT("LD[src, layers]: the layered form, one box per layer. This is what the rewrite rules work on, in Wolfram and in the editor's JavaScript.")
IT("Penrose strips {strip1, strip2, ...}: a diagram cut into horizontal strips of boxes and vertical segments, as in §2.2.2 of the book.")
IT("JSON <|\"src\" -> ..., \"ls\" -> ...|>: the layered form as the editor sends it to the GraphicalCalculusKernel, with box names as strings.")
T("The maps:")
P("""StringDiagram --toExpression------------------------> expression
StringDiagram --toLayered---> LD --ldToExpression-------> expression
LD --fromLayered--> StringDiagram    (layeredExpression = toExpression @ fromLayered)
strips --penroseLD--> LD             strips --penroseExpr--> expression
JSON --jsonToLD--> LD --ldToJSON--> JSON          jsonToExpression = ldToExpression @ jsonToLD
expression --toEditorText--> text the editor's parser reads back""")
T("An expression is built from CircleTimes (⊗), SmallCircle (∘), Subscript[\"id\", X] (identities) and unit (𝟙). Morphism symbols are strings (\"f\") or the structured symbols of section 3.3, for example Subscript[\"ev\", \"X\"]. Composition follows the book: g ∘ f means first f, then g.")

S("3. Conventions")
SS("3.1 Reading direction and coordinates")
IT("Diagrams read bottom to top, as in the book: sources at the bottom, targets at the top. In g ∘ f the box f is below the box g.")
IT("In a StringDiagram, x grows to the right and y grows upwards. A box MBox[name, symbol, {x1, x2}, y] has its centre at height y and is hgt = 0.5 tall, so its bottom edge is at y − 0.25 and its top edge at y + 0.25.")
IT("Left to right is the order of the tensor product: the strand with the smallest x is the leftmost factor.")
SS("3.2 Colours, the unit and arrows")
IT("A colour is an object, written as a string: \"X\", \"Y*\", \"∨X\". A tensor colour such as \"X⊗Y\" is one strand coloured by the product. The rules split it into strands, but the translators leave it as it is.")
IT("unit is the unit object 𝟙. tensor[{}] = unit, and strands coloured unit are dropped by toExpression and ldToExpression, since the book does not draw them.")
IT("Arrows (§2.1.3). In a pivotal category the arcs are oriented, and the orientation is part of the colour: an arc coloured X points down, against the reading direction, and an arc coloured X* points up. No separate arrow data is stored. arrowOf[colour] reads the arrow off the colour (section 5). In §2.1.2 notation, a left dual ∨X is also drawn pointing up.")
SS("3.3 Names of the built-in morphisms")
T("The structured symbols, with the editor's names (section 11 converts between them):")
P("""Subscript["ev", X]                     ev_X      : X* ⊗ X → 𝟙   (∨X ⊗ X → 𝟙 in §2.1.2)
Subscript["coev", X]                   coev_X    : 𝟙 → X ⊗ X*
Subscript[OverTilde["ev"], X]          ev~_X     : X ⊗ X* → 𝟙   (ẽv)
Subscript[OverTilde["coev"], X]        coev~_X   : 𝟙 → X* ⊗ X   (c̃oev)
Subscript["τ", "X,Y"]                  τ_{X,Y}   : X ⊗ Y → Y ⊗ X (the braiding, X over Y)
Subscript[Superscript["τ","-1"], "Y,X"] τ⁻¹_{Y,X} : X ⊗ Y → Y ⊗ X (the inverse of τ_{Y,X})
Subscript["ψ", X], Subscript[Superscript["ψ","-1"], X]   ψ_X, ψ⁻¹_X (§2.3.1)
Subscript["θˡ", X], Subscript["θʳ⁻¹", X], ...              θˡ_X, θʳ⁻¹_X (twists, §3.3.1)
"f", "f*", "p_α", "φ_{i,j}", ...       any other box: a plain string""")

S("4. Data structures")
fn("StringDiagram", "StringDiagram[{MBox[...], ...}, {Strand[...], ...}]",
   ["boxes: a list of MBox[name, symbol, {x1, x2}, y].", "strands: a list of Strand[colour, x, lower, upper]."],
   "An inert head: a drawn diagram. Nothing evaluates.",
   None,
   ["Each strand is one straight vertical segment, from its lower end to its upper end. A line that passes through several boxes is several strands.",
    "Strands refer to boxes by name, so names must be unique. fromLayered names its boxes \"b1\", \"b2\", ... in layer order.",
    "Crossings are not represented. The order of strands at any height is read from their x coordinates."],
   ['d1 = StringDiagram[{MBox["f", "f", {-0.3, 0.3}, 0]}, {Strand["X", 0, Loose[-1], BottomEdge["f"]], Strand["Y", 0, TopEdge["f"], Loose[1]]}]'])
fn("MBox", "MBox[name, symbol, {x1, x2}, y]",
   ["name: a string, used by Strand ends (TopEdge[name], BottomEdge[name]).", "symbol: the morphism, a string or a structured symbol (section 3.3).",
    "{x1, x2}: the left and right edges. toExpression orders boxes and strands in a slice by x1 for boxes and x for strands.", "y: the height of the centre."],
   "An inert head.", None,
   ["The height of every box is hgt = 0.5. Two boxes with the same y are in the same slice for toExpression."],
   ['hgt'])
fn("Strand", "Strand[colour, x, lower, upper]",
   ["colour: the object the strand is coloured by.", "x: the horizontal position.",
    "lower: the bottom end, Loose[y] (a source end at height y) or TopEdge[name] (the strand leaves the top of that box).",
    "upper: the top end, Loose[y] (a target end) or BottomEdge[name] (the strand enters the bottom of that box)."],
   "An inert head.", None,
   ["endY[d, end] gives the height of an end. A strand passes a height y when endY[lower] < y < endY[upper], strictly."],
   ['endY[d1, #] & /@ {Loose[-1], TopEdge["f"], BottomEdge["f"]}'])
fn("LD and B", "LD[src, {{a1, B[symbol1, ins1, outs1]}, {a2, B[...]}, ...}]",
   ["src: the list of source colours, left to right.", "a: the number of strands to the left of the box at the moment it is applied (0 = leftmost).",
    "B[symbol, ins, outs]: the box, with its list of input colours and its list of output colours."],
   "Inert heads. rows[ld] gives the colours between the layers, and validQ[ld] checks that every layer fits.",
   None,
   ["The layers are listed bottom to top. Layer k replaces positions a+1 … a+Length[ins] of the current row by outs.",
    "The form is the same in the notebooks (sections 14–19 of graphical-calculus-2.1-simplify.nb), in the kernel, and in the editor (Core.toLayered).",
    "A box with no inputs and no outputs (a scalar) is allowed: it is inserted at position a and changes nothing."],
   ['ld1 = LD[{"Y*"}, {{1, B[Subscript["coev", "X"], {}, {"X", "X*"}]}, {1, B["f", {"X"}, {"Y"}]}, {0, B[Subscript["ev", "Y"], {"Y*", "Y"}, {}]}}]',
    'rows[ld1]', 'validQ[ld1]'])
fn("Penrose pieces", "{{seg[c], B[...], ...}, {...}, ...}",
   ["A strip is a list of pieces, left to right: seg[c] is a vertical segment of colour c; B[symbol, ins, outs] is a box.", "The strips are listed bottom to top."],
   "seg[c] evaluates to {\"seg\", c}; boxes are inert.", None,
   ["Each strip must start from exactly the colours the strip below ends with: Flatten[pieceIns /@ strip] must equal the previous row."],
   ['strip1 = {seg["A*"], B["g", {"A"}, {"B"}]}', '{pieceIns /@ strip1, pieceOuts /@ strip1, pieceMor /@ strip1}'])
fn("JSON form", "<|\"src\" -> {colours}, \"ls\" -> {<|\"a\" -> a, \"name\" -> name, \"ins\" -> {...}, \"outs\" -> {...}|>, ...}|>",
   ["The editor sends this (as base64 of UTF-8 JSON) to the kernel, and the kernel answers with layers as lists {a, name, ins, outs}.",
    "name is the editor's name of the box (section 3.3)."],
   "An Association.", None, ["In the Chapter 4 mode the request also carries c, sums, pairs and simples; these translators ignore them."],
   ['j1 = <|"src" -> {"X"}, "ls" -> {<|"a" -> 0, "name" -> "coev~_X", "ins" -> {}, "outs" -> {"X*", "X"}|>, <|"a" -> 1, "name" -> "τ_{X,X}", "ins" -> {"X", "X"}, "outs" -> {"X", "X"}|>, <|"a" -> 0, "name" -> "ev_X", "ins" -> {"X*", "X"}, "outs" -> {}|>}|>'])

S("5. Helpers and arrows")
fn("tensor, compose, id", "tensor[{e1, e2, ...}]   compose[{g, f, ...}]   id[c]",
   ["tensor: a list of morphisms, left to right.", "compose: a list of morphisms, the first one applied last.", "id: a colour."],
   "tensor gives unit for {}, e1 for {e1}, and otherwise CircleTimes[e1, e2, ...]. compose gives f for {f}, and otherwise SmallCircle[g, f, ...]. id[c] = Subscript[\"id\", c].",
   None, ["CircleTimes and SmallCircle are left unevaluated, so they display as ⊗ and ∘. compose[{}] has no definition and stays unevaluated."],
   ['{tensor[{}], tensor[{"f"}], tensor[{"f", "g"}], compose[{"g", "f"}], id["X"]}'])
fn("ins, outs, sym, rows, validQ", "ins[b]  outs[b]  sym[b]  rows[ld]  validQ[ld]",
   ["b: a box B[symbol, ins, outs].", "ld: a layered form."],
   "The parts of a box; the list of rows of colours (Length[ls] + 1 rows); True or False.",
   ["rows folds the step row ↦ Take[row, a] ++ outs ++ Drop[row, a + Length[ins]] over the layers.",
    "validQ checks, for every layer, that a is a non-negative integer, that the inputs fit in the row, and that the colours at those positions are exactly ins. Any error inside the check gives False."],
   None,
   ['{rows[ld1], validQ[ld1], validQ[LD[{"X"}, {{0, B["f", {"Y"}, {"Z"}]}}]]}'])
fn("boxOf, endY", "boxOf[d, name]   endY[d, end]",
   ["d: a StringDiagram.", "name: a box name.", "end: Loose[y], TopEdge[name] or BottomEdge[name]."],
   "The MBox called name (Missing[\"NotFound\"] if there is none); the height of the end.",
   None, ["endY[d, TopEdge[n]] = y + hgt/2 and endY[d, BottomEdge[n]] = y − hgt/2, where y is the height of box n."],
   ['{boxOf[d1, "f"], endY[d1, TopEdge["f"]]}'])
fn("arrowOf, strandArrows", "arrowOf[colour]   strandArrows[d]",
   ["colour: a colour string.", "d: a StringDiagram."],
   "\"down\" or \"up\"; a list {colour, x, arrow} for every strand of d.",
   ["A colour ending in an odd number of stars (X*) or starting with ∨ (∨X) points up; every other colour points down (§2.1.3, Figure 2.2). X** points down, since the editor identifies X** with X."],
   ["The renderers of the notebooks (renderP) and of the editor draw the arrow halfway along each arc using exactly this rule. The expression does not need the arrows: they are already in the colours of the boxes' inputs and outputs."],
   ['arrowOf /@ {"X", "X*", "∨X", "X**"}'])

S("6. toExpression: a drawn diagram to an expression")
fn("toExpression", "toExpression[StringDiagram[boxes, strands]]",
   ["A StringDiagram. Strands coloured unit are ignored."],
   "An expression: the composite, bottom to top, of one slice per height at which a box sits. Each slice is the ⊗, left to right, of the boxes at that height and of the identities of the strands passing that height.",
   ["Drop the strands coloured unit.",
    "If there are no boxes, return the ⊗ of the identities of the strands, sorted by x.",
    "Collect the distinct heights y of the boxes (Union), lowest first.",
    "For each height y, form the list of items: every box at height y keyed by its left edge x1, and id[colour] for every strand with endY[lower] < y < endY[upper], keyed by its x. Sort by the key and take the ⊗ (tensor).",
    "Compose the slices with the lowest applied first: compose[Reverse[slices]]."],
   ["A slice at height y only sees strands that pass y strictly, so the strands that end on a box at height y are not counted twice: they are inside the box.",
    "Boxes at the same height are tensored side by side. This is the interchange law used in reverse: toExpression gives the coarsest slicing that the geometry allows.",
    "The translator trusts the geometry. It does not check that a strand's colour matches the box it enters, and it does not detect crossings. Strands that cross give a well-formed but wrong expression; the book's §2.1 diagrams have no crossings.",
    "Running time: O(L (B + S) log(B + S)) for L heights, B boxes and S strands.",
    "In the editor, the same job is done by Core.fromDiagram, which reads the canvas."],
   ['toExpression[d1]',
    '#T The left dual of f (Figure 2.3), drawn by fromLayered and read back:',
    'd2 = fromLayered[ld1]; toExpression[d2]',
    '#T A diagram with no boxes is an identity:',
    'toExpression[StringDiagram[{}, {Strand["X", 0, Loose[-1], Loose[1]], Strand["Y", 1, Loose[-1], Loose[1]]}]]'])

S("7. toLayered: a drawn diagram to the layered form")
fn("toLayered", "toLayered[StringDiagram[boxes, strands]]   toLayered[ld_LD]",
   ["A StringDiagram, or a layered form (returned as it is)."],
   "LD[src, layers]: src is the colours of the strands with a Loose lower end, sorted by x; the layers are the boxes sorted by height, then by left edge.",
   ["The current row is the list of strands with a Loose lower end, sorted by x.",
    "Take the boxes in order of (y, x1). For each box, its input strands are those whose upper end is BottomEdge[box], and its output strands those whose lower end is TopEdge[box], each sorted by x.",
    "The position a is the place of its first input strand in the current row, minus 1. A box with no inputs goes after the strands of the row whose x is left of the box's centre (x1 + x2)/2.",
    "Record {a, B[symbol, colours of the inputs, colours of the outputs]}, and replace the input strands in the row by the output strands.",
    "Return LD[source colours, layers]."],
   ["Boxes at the same height are taken left to right. Any order of independent boxes gives the same morphism (level exchange, Figure 2.1).",
    "Round trip: on the 148 diagrams of the editor's examples without crossings, toLayered[fromLayered[ld]] === ld for 138. In the other 10, the same boxes come back in a different order of layers that commute (level exchange), and the expressions agree."],
   ['toLayered[d2]', 'toLayered[d2] === ld1'])

S("8. fromLayered: the layered form to a drawn diagram")
fn("fromLayered", "fromLayered[LD[src, layers]]   fromLayered[d_StringDiagram]",
   ["A layered form (it must pass validQ), or a StringDiagram (returned as it is)."],
   "A StringDiagram with boxes \"b1\", \"b2\", ... in layer order, and one Strand for every arc segment. If the layered form does not fit together, fromLayered prints fromLayered::invalid and returns $Failed.",
   ["Strands. Give every arc segment a number, with its colour, the layer at which it starts (\"src\" for a source) and the layer at which it ends (none for a target). A box with no inputs and no outputs gets a placeholder token tok[k] in its row, so that it still gets a horizontal place.",
    "Horizontal order. For every row (and every token row), each element must be to the right of its left neighbour. These pairs are the edges of a directed graph; a topological sort orders the segments, and the x index xi of a segment is 1 + the largest xi of its left neighbours (0 if it has none). The x coordinate is 0.8·xi.",
    "Box widths. A box spans the x coordinates of its ports (input and output segments), widened to at least w0 on each side of its centre: 0.5 for structured symbols (ev, coev, ...), 0.32 for names longer than one character, and 0.28 otherwise. Ports get a margin of 0.28; a box without ports gets 0.35.",
    "Heights. Box k sits one level above every earlier box j that feeds one of its input segments, or whose span overlaps its span (with a tolerance of 0.05). The level is rk[k] = 1 + the largest such rk[j], or 0. The y coordinate is rk[k].",
    "Ends. Sources get Loose[ymin − 0.8] and targets Loose[ymax + 0.8], where ymin and ymax are the lowest and highest box heights ({−0.2, 0.2} when there are no boxes)."],
   ["fromLayered is a layout, not a canonical form: two layered forms that differ by level exchange can give the same picture.",
    "Boxes that are independent and do not overlap get the same height, so toExpression of the result puts them in one slice (see layeredExpression in section 9).",
    "The constants are chosen for the renderers render and renderP of the notebooks, which draw a StringDiagram."],
   ['fromLayered[ld1]', 'fromLayered[LD[{"X"}, {{0, B["f", {"Y"}, {"Z"}]}}]]'],
   ["fromLayered::invalid: “The layered form … does not fit together (a layer's position or input colours do not match the strands below it).”"])

S("9. ldToExpression and layeredExpression: the layered form to an expression")
fn("ldToExpression", "ldToExpression[LD[src, layers]]",
   ["A layered form."],
   "The expression with one slice per layer: the slice of layer k is id ⊗ … ⊗ box ⊗ … ⊗ id, with one identity for each strand left and right of the box. The slices are composed bottom to top. With no layers it is the ⊗ of the identities of src. For an invalid form it prints fromLayered::invalid and returns $Failed.",
   ["r = rows[ld].", "For layer k = {a, b}: tensor[ id /@ Take[r[[k]], a]  ++  {sym[b]}  ++  id /@ Drop[r[[k]], a + Length[ins[b]]] ], leaving out unit strands.",
    "compose[Reverse[slices]]."],
   ["This is exactly what the editor's Core.fromLayered does in JavaScript before Core.tidy merges identities. It needs no layout, and it is linear in the number of layers.",
    "It is the finest slicing; toExpression of a drawing is the coarsest. Both are the same morphism, by the interchange law."],
   ['ldToExpression[ld1]', 'ldToExpression[LD[{"X", "Y"}, {}]]'])
fn("layeredExpression", "layeredExpression[ld]",
   ["A layered form."],
   "toExpression[fromLayered[ld]], or $Failed if fromLayered fails.",
   None, ["This is the expression the notebooks show for a simplified diagram: simplify[d] returns fromLayered[simplifyLD[d]], and the notebooks read it with toExpression."],
   ['ldA = LD[{"X"}, {{0, B["α", {}, {}]}, {0, B["β", {}, {"X"}]}, {1, B["γ", {"X"}, {}]}}];', '{ldToExpression[ldA], layeredExpression[ldA]}'])

S("10. Penrose strips (§2.2.2)")
fn("penroseLD", "penroseLD[src, strips]",
   ["src: the source colours.", "strips: the strips, bottom to top; each strip is a list of pieces seg[c] and B[...], left to right."],
   "The layered form: for each strip, from left to right, every box becomes a layer whose position is the number of colours to its left at that point of the strip. If a strip does not start from the colours the strip below ends with, penroseLD prints penroseLD::rows and returns $Failed.",
   ["row = src.", "For each strip: check Flatten[pieceIns /@ strip] === row.",
    "Walk the strip with an offset off = 0: a segment adds 1 to off; a box b gives the layer {off, b} and adds Length[outs[b]] to off. (The boxes to the left have already been applied, so the offset counts their outputs.)",
    "row = Flatten[pieceOuts /@ strip].", "Return LD[src, layers]."],
   ["Several boxes in one strip become consecutive layers, left to right."],
   ['penS = {{seg["A*"], B["g", {"A"}, {"B"}]}, {B["h", {"A*", "B"}, {"C"}]}};', 'penroseLD[{"A*", "A"}, penS]', 'penroseLD[{"A"}, penS]'],
   ["penroseLD::rows: “Strip k starts from the colours …, but the strip below it ends with ….”"])
fn("penroseExpr", "penroseExpr[strips]",
   ["The strips, as for penroseLD."],
   "compose[Reverse[tensor[pieceMor /@ #] & /@ strips]]: each strip is the ⊗ of its pieces (id[c] for a segment), and the strips are composed bottom to top. This is the formula the book writes for a Penrose diagram (p. 38).",
   None, ["penroseExpr does not check the colours; use penroseLD or penroseTarget for that."],
   ['penroseExpr[penS]'])
fn("penroseTarget", "penroseTarget[src, strips]",
   ["As for penroseLD."], "The target colours Last[rows[penroseLD[src, strips]]], or $Failed.", None, [],
   ['penroseTarget[{"A*", "A"}, penS]'])

S("11. The kernel's wire format")
fn("editorSymbol", "editorSymbol[name]",
   ["The editor's name of a box (a string)."],
   "The Wolfram symbol (section 3.3). Names that are not built in stay strings.",
   ["ev_X, coev_X, ev~_X, coev~_X → Subscript[\"ev\" | \"coev\" | OverTilde[...], X], with braces removed from {X⊗Y}.",
    "τ⁻¹_{Y,X} → Subscript[Superscript[\"τ\", \"-1\"], \"Y,X\"]; τ_{X,Y} → Subscript[\"τ\", \"X,Y\"].",
    "ψ⁻¹_X, ψ_X → Subscript[Superscript[\"ψ\", \"-1\"], X], Subscript[\"ψ\", X].",
    "θˡ_X, θʳ_X, θˡ⁻¹_X, θʳ⁻¹_X → Subscript[\"θˡ\", X], ...",
    "Anything else → the string itself (f, f*, p_α, φ_{i,j}, ...)."],
   ["The patterns are tried in this order. ψ and τ are matched by prefix, so a box called τ_something that is not a braiding would be read as one."],
   ['editorSymbol /@ {"ev_X", "coev~_{X⊗Y}", "τ⁻¹_{Y,X}", "ψ_X", "θʳ⁻¹_X", "f*"}'])
fn("editorName", "editorName[symbol]",
   ["A Wolfram symbol."], "The editor's name: the inverse of editorSymbol. A tensor subscript gets braces, as in ev_{X⊗Y}. Other expressions are written with ToString[…, InputForm].", None,
   ["editorName[editorSymbol[n]] === n for every name the editor sends, except that a braced single subscript such as ev_{X} comes back as ev_X."],
   ['editorName /@ editorSymbol /@ {"ev_X", "coev~_{X⊗Y}", "τ⁻¹_{Y,X}", "ψ_X", "θʳ⁻¹_X", "f*"}'])
fn("jsonToLD, ldToJSON, jsonToExpression", "jsonToLD[j]   ldToJSON[ld]   jsonToExpression[j]",
   ["j: the JSON Association of section 4.", "ld: a layered form."],
   "The layered form, the reply form <|\"src\" -> ..., \"ls\" -> {{a, name, ins, outs}, ...}|>, and the expression.",
   ["jsonToLD maps every layer <|a, name, ins, outs|> to {a, B[editorSymbol[name], ins, outs]}.",
    "ldToJSON maps every layer {a, B[s, ins, outs]} to {a, editorName[s], ins, outs}.",
    "jsonToExpression[j] = ldToExpression[jsonToLD[j]]."],
   ["These are the kernel's gcToLD and gcFromLD (GraphicalCalculusKernel-deploy-4.wl) under readable names. The kernel also checks the form with gcValidQ, the same test as validQ."],
   ['jsonToLD[j1]', 'ldToJSON[jsonToLD[j1]]', 'jsonToExpression[j1]'])

S("12. toEditorText: an expression as editor text")
fn("toEditorText", "toEditorText[expr]",
   ["An expression made of CircleTimes, SmallCircle, Subscript[\"id\", c], unit and symbols."],
   "A string in the editor's syntax, which the editor's Expression box reads back: composition by juxtaposition (g f means g ∘ f), ⊗ with spaces around it, id_X (id_{X⊗Y} for a tensor colour, id_𝟙 for unit), and editorName for every symbol.",
   ["A tensor product at the top is written plainly (a ⊗ b). Inside a composition, it gets brackets.",
    "A composition is its factors written side by side. A space separates two plain names (g f); no space is needed next to a bracket ((a ⊗ b)(c ⊗ d)). Inside a tensor product, a composition gets brackets."],
   ["The round trip expression → text → editor gives back the same morphism. The editor may tidy the text further, for example by merging id_X ⊗ id_Y into id_{X ⊗ Y}."],
   ['toEditorText[ldToExpression[ld1]]', 'toEditorText[jsonToExpression[j1]]', 'toEditorText[compose[{"g", "f"}]]'])

S("13. How the translators relate to the editor's JavaScript")
IT("Core.toLayered (JavaScript) reads an expression into a layered form. It has no Wolfram twin here, because the Wolfram notebooks build layered forms from StringDiagrams (toLayered) or Penrose strips (penroseLD).")
IT("Core.fromLayered (JavaScript) turns a layered form into an expression: this is ldToExpression. The JavaScript name says 'from layered', and it gives an expression, not a picture.")
IT("Core.fromDiagram (JavaScript) reads the canvas (boxes and arcs with coordinates): this is toExpression.")
IT("Core.toDiagram (JavaScript) lays an expression out on the canvas: the counterpart of fromLayered.")
IT("The kernel converts the editor's JSON with gcToLD and gcFromLD: jsonToLD and ldToJSON.")

S("14. Tests")
T("Each line should be True.")
I('''<|
 "toExpression of a drawn f" -> (toExpression[d1] === "f"),
 "Figure 2.3: toExpression[fromLayered[ld]] = ldToExpression[ld]" -> (toExpression[fromLayered[ld1]] === ldToExpression[ld1]),
 "toLayered[fromLayered[ld]] = ld" -> (toLayered[fromLayered[ld1]] === ld1),
 "no boxes: an identity" -> (toExpression[StringDiagram[{}, {Strand["X", 0, Loose[-1], Loose[1]]}]] === id["X"]),
 "unit strands are dropped" -> (toExpression[StringDiagram[{}, {Strand[unit, 0, Loose[-1], Loose[1]], Strand["X", 1, Loose[-1], Loose[1]]}]] === id["X"]),
 "invalid layered forms fail" -> (Quiet[fromLayered[LD[{"X"}, {{0, B["f", {"Y"}, {"Z"}]}}]]] === $Failed && Quiet[ldToExpression[LD[{"X"}, {{1, B["f", {"X"}, {"Z"}]}}]]] === $Failed),
 "Penrose: the layered form and the target" -> (penroseLD[{"A*", "A"}, penS] === LD[{"A*", "A"}, {{1, B["g", {"A"}, {"B"}]}, {0, B["h", {"A*", "B"}, {"C"}]}}] && penroseTarget[{"A*", "A"}, penS] === {"C"}),
 "Penrose: a mismatch fails" -> (Quiet[penroseLD[{"A"}, penS]] === $Failed),
 "Penrose: penroseExpr = ldToExpression of penroseLD (here)" -> (penroseExpr[penS] === compose[{"h", tensor[{id["A*"], "g"}]}]),
 "JSON round trip" -> (ldToJSON[jsonToLD[j1]] === <|"src" -> j1["src"], "ls" -> ({#a, #name, #ins, #outs} & /@ j1["ls"])|>),
 "editor names round trip" -> (editorName /@ editorSymbol /@ {"ev_X", "coev~_{X⊗Y}", "τ⁻¹_{Y,X}", "ψ_X", "θʳ⁻¹_X", "f*"} === {"ev_X", "coev~_{X⊗Y}", "τ⁻¹_{Y,X}", "ψ_X", "θʳ⁻¹_X", "f*"}),
 "editor text of the curl θˡ_X (§3.3.1)" -> (toEditorText[jsonToExpression[j1]] === "(ev_X ⊗ id_X)(id_X* ⊗ τ_{X,X})(coev~_X ⊗ id_X)"),
 "arrows" -> (arrowOf /@ {"X", "X*", "∨X", "X**"} === {"down", "up", "up", "down"})
|>''')

S("15. Index of public symbols")
for name, what in [
  ("StringDiagram, MBox, Strand, Loose, TopEdge, BottomEdge", "drawn diagrams (section 4)"),
  ("LD, B, unit, hgt", "layered forms, boxes, the unit, the box height (sections 3–4)"),
  ("tensor, compose, id, ins, outs, sym, rows, validQ, boxOf, endY", "helpers (section 5)"),
  ("arrowOf, strandArrows", "arrows (section 5)"),
  ("toExpression", "drawn diagram → expression (section 6)"),
  ("toLayered", "drawn diagram → layered form (section 7)"),
  ("fromLayered", "layered form → drawn diagram (section 8)"),
  ("ldToExpression, layeredExpression", "layered form → expression (section 9)"),
  ("seg, pieceIns, pieceOuts, pieceMor, penroseLD, penroseExpr, penroseTarget", "Penrose strips (section 10)"),
  ("editorSymbol, editorName, jsonToLD, ldToJSON, jsonToExpression", "the kernel's wire format (section 11)"),
  ("toEditorText", "expression → editor text (section 12)")]:
    IT(f"{name}: {what}.")
T("© Computational Classnotes · CC BY-NC-SA 4.0")

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
open('/mnt/user-data/outputs/diagram-to-expression-manual.nb', 'w').write(nb)
print(len(cells), sum(1 for c in cells if c[0] == 'Input'))
