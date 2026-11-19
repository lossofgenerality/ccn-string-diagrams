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


C("Title", "ExpressionToDiagram: a programmer's manual")
C("Subtitle", "The Wolfram functions of CCN String Diagrams that turn expressions into boxes, lines and arrows")
T("By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0")
T("After Turaev & Virelizier, Monoidal Categories and Topological Field Theory, Chapter 2. The package is expression-to-diagram.wl, in the same folder as this notebook (Desktop/Research/Monoidal Graphical Calculus). It is the companion of diagram-to-expression.wl, which goes the other way and has its own manual (diagram-to-expression-manual.nb). The two packages share their data structures, so their functions can be chained in both directions.")

S("1. Loading the package")
T("Evaluate the cell below once per session. The package loads diagram-to-expression.wl from the same folder if it is not loaded yet, and puts both contexts, ExpressionToDiagram` and DiagramToExpression`, on $ContextPath. Private helpers live in ExpressionToDiagram`Private`.")
I('Get[FileNameJoin[{$HomeDirectory, "Desktop", "Research", "Monoidal Graphical Calculus", "expression-to-diagram.wl"}]]')
I('?expressionToLD')
I('Names["ExpressionToDiagram`*"]')

S("2. Overview: the pipeline")
P("""editor text   --parseExpression-->  expression
signature text --parseSignature-->  <|name -> {dom, cod}|>
expression    --typeOf----------->  {dom, cod}
expression    --expressionToLD--->  LD[src, layers]          (the inverse of ldToExpression)
LD            --fromLayered------>  StringDiagram             (DiagramToExpression)
StringDiagram --render / renderP->  Graphics                  (renderP: with arrows, caps and cups)
expression    --expressionToStrips-> Penrose strips           (the inverse of penroseExpr)
idL, boxL, stackL, besideL          build an LD directly, like id, a box, ∘ and ⊗
show, showP, showEq, showEqP, showTrace, showTraceP, showPenrose   picture, formula and type together""")
T("Shortcuts: textToLD[text, sigText] does the first four steps, expressionToDiagram[expr, sig] stops at the StringDiagram, and textToGraphics[text, sigText] draws a typed expression.")
T("An expression is built from SmallCircle (∘), CircleTimes (⊗), Subscript[\"id\", c] (identities) and unit (𝟙). Its symbols are strings (\"f\") or the structured symbols of the built-in morphisms, for example Subscript[\"ev\", \"X\"]. The manual of DiagramToExpression, section 3.3, lists them.")

S("3. Conventions")
SS("3.1 The editor's syntax")
T("parseExpression reads the same text as the editor's Expression box:")
IT("Names are runs of letters, digits, Greek letters and the marks ′ ' ? ∨ * ~ ⁻ ¹ ˡ ʳ †. A name may carry a subscript after _: a single word (ev_X) or a braced group (ev_{X⊗Y}, τ_{X,Y}, φ_{i,j}). As in the editor, a braced subscript longer than one character keeps its braces in the name. editorSymbol then turns built-in names into structured symbols.")
IT("id_X is the identity of X; id_{X⊗Y} is the identity of X ⊗ Y. 𝟙, I and 1 are the unit; id_𝟙 is its identity.")
IT("ẽv and c̃oev may be typed as ev~ and coev~. (x) is ⊗, -> is →, and · is ∘.")
T("Precedence, tightest first:")
P("""juxtaposition   g f      = g ∘ f      (f is applied first)
⊗              a ⊗ b
∘  and  ;       g ∘ f    ;   f ; g  = g ∘ f
( … )           grouping""")
T("So \"g f ⊗ h\" means (g ∘ f) ⊗ h, and \"(ev_Y ⊗ id_X*)(id_Y* ⊗ coev_X)\" is a composite of two tensor products. Nested products and composites are flattened, since ⊗ and ∘ are associative.")
SS("3.2 Duals")
T("The option \"Duals\" chooses how the types of ev, coev, ẽv, c̃oev and of dual boxes are written:")
IT("\"star\" (the default, §2.1.3, pivotal): ev_X : X* ⊗ X → 𝟙, coev_X : 𝟙 → X ⊗ X*, ẽv_X : X ⊗ X* → 𝟙, c̃oev_X : 𝟙 → X* ⊗ X. The dual of a box f : X → Y is f* : Y* → X*. X** is X.")
IT("\"vee\" (§2.1.2, left duals): ev_X : ∨X ⊗ X → 𝟙, coev_X : 𝟙 → X ⊗ ∨X. The dual of f is ∨f : ∨Y → ∨X.")
IT("For a tensor colour, the dual reverses the order: (X ⊗ Y)* = Y* ⊗ X*, so ev_{X⊗Y} : Y* ⊗ X* ⊗ X ⊗ Y → 𝟙.")
SS("3.3 Built-in types")
P("""ev_X, coev_X, ev~_X, coev~_X   as in 3.2
τ_{X,Y}      : X ⊗ Y → Y ⊗ X        (the braiding, §3.1)
τ⁻¹_{Y,X}    : X ⊗ Y → Y ⊗ X        (the inverse of τ_{Y,X})
ψ_X, ψ⁻¹_X  : X → X                 (strict pivotal: X** = X)
θˡ_X, θʳ_X, θˡ⁻¹_X, θʳ⁻¹_X : X → X   (twists, §3.3)
φ_{i,j} : i* → j,  φ⁻¹_{i,j} : j → i*  (Lemma 4.9(a))
f*  (or ∨f)  : the dual of a box f in the signature""")
SS("3.4 Arrows")
T("The orientation of an arc is carried by its colour: X points down (against the reading direction) and X* points up (§2.1.3). renderP draws an arrowhead halfway along every line, using this rule. It draws ev and ẽv as caps and coev and c̃oev as cups, each with an arrowhead that shows which way the arc runs: a cap whose left leg is coloured X* runs to the right. render draws no arrows: it is the unoriented picture of §2.1.1–2.1.2.")

S("4. Signatures")
fn("parseSignature", "parseSignature[text]",
   ["text: the editor's Signature box, one box per line, name : source → target, with ⊗ between colours and 𝟙 for the unit. Text after # or // is a comment."],
   "An Association name -> {source colours, target colours}.",
   ["Split the text into lines and remove comments.", "Skip empty lines, lines without “:” and lines that start with partition.",
    "Split the rest at the first “:” into a name (spaces removed) and a type, and the type at → (or ->).", "Each side is split at ⊗; parentheses and unit words are dropped."],
   ["The editor's other signature lines (pairing ω Ω, inverse u u′, retract p j, simple i, scalar a) have no “:” and are ignored: they matter to the rewrite rules, not to drawing.",
    "A partition line declares two boxes in the editor (p_α and q_α). Here, write their types out as ordinary lines if you need them."],
   ['sig1 = parseSignature["f : X → Y\\ng : Y ⊗ Z → 𝟙\\n# a comment\\npairing ω Ω"]'])

S("5. Parsing")
fn("parseExpression", "parseExpression[text]",
   ["text: an expression in the editor's syntax (section 3.1)."],
   "An expression, or $Failed with the message parseExpression::syntax, which says what was expected and at which character.",
   ["Tokenize: whitespace is skipped; ⊗ ∘ · ; ( ) _ { } , = → : are symbols; runs of name characters are words. Any other character is an error.",
    "Parse by recursive descent: expr := tens ((∘ | ;) tens)*, tens := juxt (⊗ juxt)*, juxt := atom atom*, atom := ( expr ) | 𝟙 | id_subscript | name [_subscript].",
    "A name with its subscript is passed to editorSymbol, so built-in morphisms become structured symbols.",
    "Nested ⊗ and ∘ are flattened."],
   ["The parser does not need the signature: types are only checked by typeOf and expressionToLD.",
    "f : X → Y inside an expression (the editor's inline typing) is not supported; declare types in the signature."],
   ['parseExpression["(ev_Y ⊗ id_X*)(id_Y* ⊗ f ⊗ id_X*)(id_Y* ⊗ coev_X)"]', 'parseExpression["g f ; h"]', 'parseExpression["τ_{X,Y}(f ⊗ g)"]', 'parseExpression["f ⊗ ⊗ g"]'],
   ["parseExpression::syntax: “Expected a name at position …”, “Unexpected symbol … at position …”, “Empty expression”, and so on."])
fn("parseEquation", "parseEquation[text]",
   ["text: an equation, with = between its sides."], "The list of the parsed sides.", None, [],
   ['parseEquation["(ev_X ⊗ id_X)(id_X* ⊗ τ_{X,X})(coev~_X ⊗ id_X) = θˡ_X"]'])

S("6. Types")
fn("builtinType", "builtinType[symbol, duals]",
   ["symbol: a structured symbol or a string.", "duals: \"star\" or \"vee\" (default \"star\")."],
   "{source colours, target colours} for a built-in morphism (section 3.3), or Missing[] for any other symbol.", None, [],
   ['builtinType[Subscript["ev", "X⊗Y"], "star"]', 'builtinType[Subscript["coev", "X"], "vee"]', 'builtinType[Subscript[Superscript["τ", "-1"], "Y,X"]]', 'builtinType["f"]'])
fn("typeOf", "typeOf[expr, sig, \"Duals\" -> duals]",
   ["expr: an expression.", "sig: a signature (parseSignature).", "\"Duals\": \"star\" (default) or \"vee\"."],
   "{source colours, target colours}, or $Failed with a message of expressionToLD (the type is computed by building the layered form).",
   ["A box's type comes, in this order, from the signature, from builtinType, or (for f* or ∨f) from the type of f, dualized: f* : (target of f)* → (source of f)*."],
   None,
   ['typeOf[parseExpression["g (f ⊗ id_Z)"], sig1]', 'typeOf[parseExpression["f*"], sig1]', 'typeOf[parseExpression["∨f"], sig1, "Duals" -> "vee"]'])

S("7. Building layered forms directly")
fn("idL, boxL, stackL, besideL", "idL[cs]   boxL[s, ins, outs]   stackL[l1, l2, ...]   besideL[l1, l2, ...]",
   ["cs, ins, outs: lists of colours.", "s: a symbol.", "l1, l2, ...: layered forms."],
   "idL[cs] = LD[cs, {}]. boxL[s, ins, outs] = LD[ins, {{0, B[s, ins, outs]}}]. stackL[l1, l2] = l2 ∘ l1, l2 on top. besideL[l1, l2] = l1 ⊗ l2, l2 on the right.",
   ["stackL concatenates the layers. It is defined only when the target of l1 equals the source of l2; otherwise it stays unevaluated.",
    "besideL first applies all the layers of l1, then those of l2, shifted right by the width of l1's target. So the left factor is drawn first: the same convention as the editor's Core.toLayered."],
   ["These are the combinators the notebooks use to write diagrams by hand (sections 14–19 of graphical-calculus-2.1-simplify.nb)."],
   ['stackL[boxL["f", {"X"}, {"Y"}], boxL["g", {"Y"}, {"Z"}]]', 'besideL[boxL["f", {"X"}, {"Y"}], idL[{"U"}], boxL["h", {"V"}, {}]]', 'stackL[boxL["f", {"X"}, {"Y"}], boxL["g", {"W"}, {"Z"}]]'])

S("8. From an expression to a diagram")
fn("expressionToLD", "expressionToLD[expr, sig, \"Duals\" -> duals]",
   ["expr: an expression.", "sig: a signature.", "\"Duals\": \"star\" (default) or \"vee\"."],
   "The layered form LD[src, layers], or $Failed with a message.",
   ["unit ↦ idL[{}]; Subscript[\"id\", c] ↦ idL of the colours of c (a tensor colour \"X⊗Y\" gives two strands).",
    "A box s ↦ boxL[s, dom, cod], with its type from section 6. A box without a type is an error (expressionToLD::untyped).",
    "a ⊗ b ⊗ ... ↦ besideL of the translations of the factors.",
    "g ∘ f ∘ ... ↦ the translations stacked from the right: f first. Each factor must start from the target of the one below; if not, expressionToLD::type names the two factors and both rows of colours."],
   ["expressionToLD is the Wolfram twin of the editor's Core.toLayered. On the 148 sides of the editor's examples without crossings, it gives exactly the same layered form, position for position and name for name, in both duals modes (the test in section 13 checks this from tests/editor-text-layered.json).",
    "It inverts ldToExpression: expressionToLD[ldToExpression[ld], sig] === ld for all 148.",
    "The result is not normalized. Use the engine's normalize, or simplifyTrace, to bring it to the normal form used by the rewrite rules."],
   ['ld1 = expressionToLD[parseExpression["(ev_Y ⊗ id_X*)(id_Y* ⊗ f ⊗ id_X*)(id_Y* ⊗ coev_X)"], sig1]',
    'expressionToLD[parseExpression["g f"], parseSignature["f : X → Y\\ng : Z → W"]]', 'expressionToLD[parseExpression["k"], sig1]'],
   ["expressionToLD::type: “The composite g ∘ f does not fit: the target of the right factor is …, but the left factor starts from ….”",
    "expressionToLD::untyped: “The box k has no type: add a line \"k : … → …\" to the signature.”"])
fn("expressionToDiagram, textToLD, textToGraphics", "expressionToDiagram[expr, sig]   textToLD[text, sigText]   textToGraphics[text, sigText, \"Oriented\" -> True]",
   ["expr, sig: as above.", "text, sigText: the editor's Expression and Signature boxes, as strings.", "\"Oriented\": True for renderP (arrows), False for render. \"Duals\" as above."],
   "A StringDiagram (fromLayered of the layered form), a layered form, or Graphics; $Failed if parsing or typing fails.", None, [],
   ['expressionToDiagram[parseExpression["g (f ⊗ id_Z)"], sig1]', 'textToGraphics["(ev_Y ⊗ id_X*)(id_Y* ⊗ f ⊗ id_X*)(id_Y* ⊗ coev_X)", "f : X → Y"]',
    'textToGraphics["(ev_Y ⊗ id_∨X)(id_∨Y ⊗ f ⊗ id_∨X)(id_∨Y ⊗ coev_X)", "f : X → Y", "Duals" -> "vee", "Oriented" -> False]'])

S("9. Penrose strips from an expression")
fn("expressionToStrips", "expressionToStrips[expr, sig]",
   ["expr: an expression in Penrose form, s_n ∘ … ∘ s_1, where each slice s_k is a ⊗ of boxes and identities (or a single box or identity).", "sig: a signature."],
   "The strips {strip_1, …, strip_n}, bottom to top. Each box becomes B[s, dom, cod] and each identity id_c becomes seg pieces, one per colour of c. Returns $Failed with a message if a slice is not a ⊗ of boxes and identities.",
   ["List the slices bottom first (the factors of the composite, reversed).", "In each slice, map every factor to its pieces and join them."],
   ["It inverts penroseExpr: penroseExpr[expressionToStrips[e, sig]] gives e back when every identity is on a single colour.",
    "Types use the \"star\" convention."],
   ['strips1 = expressionToStrips[parseExpression["h (id_A* ⊗ g)"], parseSignature["g : A → B\\nh : A* ⊗ B → C"]]', 'penroseLD[{"A*", "A"}, strips1]',
    'showPenrose[{"A*", "A"}, strips1]'],
   ["expressionToStrips::shape: “The slice … is not a ⊗ of boxes and identities …”"])

S("10. Drawing")
fn("render", "render[d]   render[ld]",
   ["d: a StringDiagram; ld: a layered form (it is laid out with fromLayered first)."],
   "Graphics: every strand is a vertical line of thickness 2.4, labelled with its colour near its loose end (or halfway); every box is a white rectangle with a black edge, labelled with its symbol (dispSym).",
   ["Lines: from (x, endY[lower]) to (x, endY[upper]). The label goes 0.08 to the right, 0.2 inside a loose end.",
    "Boxes: the rectangle {x1, y − hgt/2} – {x2, y + hgt/2}, with the symbol at the centre in Times, size 13 for structured symbols and 15 otherwise.",
    "Plot range: the bounding box of all ends and corners, at least −1 … 1 vertically, padded by 0.45 horizontally and 0.1 vertically. The image is 62 points per unit of width."],
   ["render shows no orientation. Use renderP for pivotal diagrams."],
   ['render[ld1]'])
fn("renderP", "renderP[d]   renderP[ld]",
   ["As for render."],
   "Graphics of the oriented diagram (§2.1.3): lines of thickness 2.2 with an arrowhead halfway, labelled with the colour without its star (an up arrow already says X*); caps and cups for ev, ẽv, coev and c̃oev; rectangles for every other box.",
   ["For every strand: a line and an arrowhead at its midpoint, pointing up if the colour is starred (upQ) and down otherwise. The label is lineLabel[colour]: X* is labelled X.",
    "For a box ev or ẽv with two input legs: a Bézier cap from the left leg to the right leg, rising 0.67, with an arrowhead at the top pointing right if the left leg is starred, left otherwise.",
    "For a box coev or c̃oev with two output legs: a Bézier cup, falling 0.67, with an arrowhead at the bottom pointing left if the left leg is starred, right otherwise.",
    "Every other box: a rectangle, as in render.", "Plot range as in render, padded by 0.5 on the left and 0.55 on the right."],
   ["The arrowheads are drawn by head[{x, y}, dir], a small triangle of size 0.075 pointing up, down, left or right.",
    "The editor's canvas follows the same rules (Figure 2.2 of the book)."],
   ['renderP[ld1]', 'renderP[textToLD["(ev_X ⊗ id_X)(id_X* ⊗ τ_{X,X})(coev~_X ⊗ id_X)", ""]]'])
fn("dispSym, pretty", "dispSym[symbol]   pretty[expr]",
   ["A symbol; an expression."],
   "The typeset form: names in italics; ev, coev, id upright with the subscript typeset; X* as X with a superscript star; ∨X with a small upright ∨; names starting with Ω or ( upright; unit as 𝟙.",
   None, [], ['pretty[parseExpression["(ev_Y ⊗ id_X*)(id_Y* ⊗ f* ⊗ id_X*)"]]'])
fn("source, target", "source[d]   target[d]",
   ["d: a StringDiagram."], "The ⊗, left to right, of the colours of the strands with a loose lower end (source) or upper end (target); unit if there are none.",
   None, [], ['{source[fromLayered[ld1]], target[fromLayered[ld1]]}'])

S("11. Pictures with their formulas")
fn("show, showP", "show[d]   showP[d]",
   ["A StringDiagram or a layered form."],
   "A row of three: the picture (render or renderP), the expression read back by toExpression (typeset by pretty), and the type source → target in grey.",
   None, ["The formula is read back from the picture, so it shows what the picture means. Comparing it with the expression you started from checks the drawing."],
   ['show[ld1]', 'showP[ld1]'])
fn("showEq, showEqP", "showEq[{d1, d2, ...}]   showEqP[{ld1, ld2, ...}]",
   ["A list of diagrams or layered forms."], "The pictures in a row with = between them, and the expressions below.", None, [],
   ['#T Figure 2.4: a box slides through ẽv.', 'showEqP[textToLD[#, "f : X → Y"] & /@ StringSplit["ev~_Y(f ⊗ id_Y*) = ev~_X(id_X ⊗ f*)", "="]]'])
fn("showTrace, showTraceP", "showTrace[steps]   showTraceP[steps]",
   ["steps: a list {{rule, ld}, …}, as the engine's simplifyTrace returns it. The first rule is usually \"start\"."],
   "The pictures of the steps with the rule names over the arrows between them, and the expressions below.", None, ["showTraceP draws the steps with renderP."],
   ['showTraceP[{{"start", textToLD["(id_X ⊗ ev_X)(coev_X ⊗ id_X)", ""]}, {"(2.1) left zigzag", idL[{"X"}]}}]'])
fn("showPenrose", "showPenrose[src, strips]", ["As for penroseLD."], "renderP of the Penrose diagram beside its source, its target and the formula penroseExpr; $Failed if the strips do not fit.", None, [],
   ['showPenrose[{"A*", "A"}, strips1]'])

S("12. How the translators relate to the editor's JavaScript")
IT("Core.parseSig ↔ parseSignature (the editor also reads pairing, inverse, retract, simple, partition and scalar lines).")
IT("Core.parse ↔ parseExpression (the editor also accepts inline types f : X → Y and the dagger †).")
IT("Core.toLayered ↔ expressionToLD: the same layered form on all 148 example sides (section 13).")
IT("Core.toDiagram (layout on the canvas) ↔ fromLayered; the canvas renderer ↔ render and renderP.")

S("13. Tests")
T("Each line should be True. The last two lines compare with the editor itself: tests/editor-text-layered.json holds, for every side of the editor's examples without crossings, the text, the signature, the duals mode and the layered form computed by the editor's JavaScript (Core.toLayered).")
I('''etl = Import[FileNameJoin[{$HomeDirectory, "Desktop", "Research", "Monoidal Graphical Calculus", "tests", "editor-text-layered.json"}], "RawJSON"];
<|
 "parse: juxtaposition, ⊗ and ;" -> (parseExpression["g f ; h"] === SmallCircle["h", "g", "f"] && parseExpression["a ⊗ b c"] === CircleTimes["a", SmallCircle["b", "c"]]),
 "parse: subscripts and built-ins" -> (parseExpression["τ_{X,Y} ev~_{X⊗Y} θˡ_X"] === SmallCircle[Subscript["τ", "X,Y"], Subscript[OverTilde["ev"], "X⊗Y"], Subscript["θˡ", "X"]]),
 "parse: errors give $Failed" -> (Quiet[parseExpression["f ⊗ ⊗ g"]] === $Failed && Quiet[parseExpression[""]] === $Failed),
 "signature" -> (parseSignature["f : X → Y\\ng : Y ⊗ Z → 𝟙\\npairing a b"] === <|"f" -> {{"X"}, {"Y"}}, "g" -> {{"Y", "Z"}, {}}|>),
 "types of duals" -> (typeOf[parseExpression["f*"], sig1] === {{"Y*"}, {"X*"}} && typeOf[parseExpression["∨f"], sig1, "Duals" -> "vee"] === {{"∨Y"}, {"∨X"}}),
 "type errors give $Failed" -> (Quiet[expressionToLD[parseExpression["f f"], sig1]] === $Failed && Quiet[expressionToLD[parseExpression["k"], sig1]] === $Failed),
 "Figure 2.3 as a layered form" -> (ld1 === LD[{"Y*"}, {{1, B[Subscript["coev", "X"], {}, {"X", "X*"}]}, {1, B["f", {"X"}, {"Y"}]}, {0, B[Subscript["ev", "Y"], {"Y*", "Y"}, {}]}}]),
 "round trip: expression → LD → expression" -> (ldToExpression[ld1] === parseExpression["(ev_Y ⊗ id_X*)(id_Y* ⊗ f ⊗ id_X*)(id_Y* ⊗ coev_X)"]),
 "Penrose round trip" -> (penroseExpr[strips1] === parseExpression["h (id_A* ⊗ g)"]),
 "drawing gives Graphics" -> (Head[renderP[ld1]] === Graphics && Head[render[ld1]] === Graphics),
 "the editor's 148 layered forms, exactly" -> AllTrue[etl, With[{l = Quiet[textToLD[#text, #sig, "Duals" -> #duals]]}, l =!= $Failed && ldToJSON[l]["src"] === #src && ldToJSON[l]["ls"] === #ls] &],
 "expressionToLD inverts ldToExpression on the same 148" -> AllTrue[etl, With[{ld = jsonToLD[<|"src" -> #src, "ls" -> (<|"a" -> #[[1]], "name" -> #[[2]], "ins" -> #[[3]], "outs" -> #[[4]]|> & /@ #ls)|>]},
     Quiet[expressionToLD[ldToExpression[ld], parseSignature[#sig], "Duals" -> #duals]] === ld] &]
|>''')

S("14. Index of public symbols")
for name, what in [
  ("parseSignature", "signature text → types (section 4)"),
  ("parseExpression, parseEquation", "editor text → expression (section 5)"),
  ("builtinType, typeOf", "types (section 6)"),
  ("idL, boxL, stackL, besideL", "layered forms built directly (section 7)"),
  ("expressionToLD, expressionToDiagram, textToLD, textToGraphics", "expression → layered form → drawn diagram → picture (section 8)"),
  ("expressionToStrips", "expression → Penrose strips (section 9)"),
  ("render, renderP, dispSym, pretty, source, target", "drawing (section 10)"),
  ("show, showP, showEq, showEqP, showTrace, showTraceP, showPenrose", "pictures with formulas (section 11)"),
  ("from DiagramToExpression: LD, B, StringDiagram, fromLayered, toExpression, ldToExpression, penroseLD, penroseExpr, editorSymbol, editorName, ldToJSON, jsonToLD, toEditorText, ...", "see diagram-to-expression-manual.nb")]:
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
open('/mnt/user-data/outputs/expression-to-diagram-manual.nb', 'w').write(nb)
print(len(cells), sum(1 for c in cells if c[0] == 'Input'))
