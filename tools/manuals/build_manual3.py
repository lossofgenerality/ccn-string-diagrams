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


C("Title", "Simplifier: a programmer's manual")
C("Subtitle", "The Wolfram functions of CCN String Diagrams that rewrite an expression into its normal form")
T("By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0")
T("After Turaev & Virelizier, Monoidal Categories and Topological Field Theory, Chapters 2–4. The package is simplifier.wl, in the same folder as this notebook (Desktop/Research/Monoidal Graphical Calculus). It is the third of three companions. diagram-to-expression.wl turns boxes, lines and arrows into expressions (diagram-to-expression-manual.nb). expression-to-diagram.wl goes the other way (expression-to-diagram-manual.nb). This one goes from an expression to an expression: it applies the rules of the book until none applies, and reports every step. It is the same simplifier as the editor's Simplify button and the GraphicalCalculusKernel: on the 412 recorded editor requests it uses the same rules in the same order, step for step (section 13).")

S("1. Loading the package")
T("Evaluate the cell below once per session. The package loads expression-to-diagram.wl (which loads diagram-to-expression.wl) from the same folder if they are not loaded yet, then loads the rewriting engine, and puts the contexts Simplifier`, ExpressionToDiagram` and DiagramToExpression` on $ContextPath. Private helpers live in Simplifier`Private`; the engine lives in Simplifier`Engine`.")
I('Get[FileNameJoin[{$HomeDirectory, "Desktop", "Research", "Monoidal Graphical Calculus", "simplifier.wl"}]]')
I('engineReadyQ[]')
I('?simplifyText')
I('Names["Simplifier`*"]')
SS("1.1 The engine files")
T("The rules are not copied into simplifier.wl. They are read, every time the package loads, from the files the editor's kernel is built from, so there is one source of truth. $SimplifierEngineFiles lists them in load order:")
P("""graphical-calculus-2.1-simplify.nb   sections 0–19: layered form, level exchange, the loop, the rules of §2.1.2 (vee duals) and the braid rules
pivotal-2.1.3.wl                     §2.1.3: star duals, identity boxes, Figures 2.3 and 2.4
penrose-2.2.wl                       §2.2: (X ⊗ Y)* strands
pivotal-2.3-2.7.wl                   §2.3–2.7: ψ, Lemma 2.3, traces, inverses, sphericity, caps on ⊗
braided-2.7-3.2.wl                   §2.7.3–3.2: retracts, braiding rules, symmetric braidings
ribbon-3.3.wl                        §3.3: twists
fusion-4-rules.wl                    Chapter 4: linear combinations, the rules of §4.3–4.10""")
T("loadEngine (private) evaluates the Input and Code cells of the notebook in order, then Gets the .wl files, all inside Block[{$Context = \"Simplifier`Engine`\", $ContextPath = {\"Simplifier`Engine`\", \"System`\"}}], so none of their names clash with yours or with the two other packages. Each notebook cell gets at most 120 seconds and its messages are silenced: the figure cells of the notebook draw pictures that are not needed here. engineReadyQ[] checks that the rule Associations (rules, rulesP, rulesT, rulesD, rulesS, rulesB, rulesDB, rulesSB, twistRules, ribbonRules, linRules) exist and that normalize and rewriteOnce have definitions. If not, the package prints Simplifier::engine with the folder it looked in.")
I('$SimplifierFolder')
I('$SimplifierEngineFiles')

S("2. Overview: the pipeline")
P("""editor text  --parseExpression-->  expression          (ExpressionToDiagram)
expression   --expressionToLD--->   LD                  (ExpressionToDiagram)
LD           --normalize-------->   LD in normal form   (level exchange, section 4)
LD           --rewriteOnce------>   {rule, LD}          (the first rule that applies, section 5)
   ... normalize, rewrite, ... until no rule applies or 50 steps
LD           --ldToExpression--->   expression          (DiagramToExpression)
expression   --toEditorText----->   editor text         (DiagramToExpression)""")
T("Entry points, from the most convenient to the most basic:")
P("""simplifyText[text, sigText, opts]       text  -> normal form as text
simplifyTextSteps[text, sigText, opts]  text  -> {{rule, text}, ...}
equationReport[text, sigText, opts]     "a = b" -> sides, steps, verdict
equationHoldsQ[text, sigText, opts]     "a = b" -> True | False
showSimplification[text, sigText, opts] text  -> pictures of every step
simplifyExpression[expr, sig, opts]     expression -> expression
simplifySteps[expr, sig, opts]          expression -> {{rule, expression}, ...}
simplifyLD[ld, opts]                    LD -> LD
simplifyLDTrace[ld, opts]               LD -> {{rule, LD}, ...}
simplifyTerm, simplifyTermTrace         one term of a Chapter 4 linear combination
payloadTrace[payload]                   one request of the editor, as sent to the kernel
ruleSet, ruleNames, ruleInfo, ruleCatalogue          the rules
levelExchange, normalizeLD, adjacentLayers, rewriteOnceLD   the machinery, one step at a time""")
I('simplifyTextSteps["(id_X ⊗ ev_X)(coev_X ⊗ id_X)", "X"]')

S("3. Data: the layered form")
T("The simplifier works on layered forms LD[src, layers], the data structure of DiagramToExpression (its manual, section 3.4). src is the list of colours at the bottom of the diagram, read left to right. layers is the list of boxes from bottom to top, each {a, B[sym, ins, outs]}: the box sym sits on the strands a+1, …, a+Length[ins] of the strands below it (a counts the strands to its left, from 0), takes the colours ins and puts out the colours outs. Every strand not under the box goes straight up.")
I('ld = textToLD["(id_X ⊗ ev_X)(coev_X ⊗ id_X)", "X"]')
I('renderP[fromLayered[ld]]')
T("The engine has its own copies of the heads LD, B and unit (Simplifier`Engine`LD and so on), because it was loaded in its own context. toEngine and fromEngine convert, and every public function of this package takes and returns the heads of DiagramToExpression, so you never see the engine's heads.")
fn("toEngine, fromEngine", "toEngine[x]\nfromEngine[x]",
   ["x: any expression: an LD, a list of steps, a term."],
   "x with the heads LD, B and unit replaced: DiagramToExpression's by the engine's (toEngine), or back (fromEngine).",
   None, ["A plain ReplaceAll: everything else in x is left alone."],
   ['toEngine[ld] // FullForm // Short', 'fromEngine[toEngine[ld]] === ld'])

S("4. Normal form under level exchange")
T("Two boxes side by side can be drawn in either order: f ⊗ g = (f ⊗ id)(id ⊗ g) = (id ⊗ g)(f ⊗ id). This is level exchange (Figure 2.1 of the book). The simplifier fixes one order, so that equal diagrams have equal layered forms more often and the rules see neighbouring boxes as neighbouring layers.")
SS("4.1 The normal form")
T("A layered form is normal when no layer can move below its predecessor while lying entirely to its left. Precisely, layers k (box b₁ at a) and k+1 (box b₂ at b) are out of order (leftQ) when b + Length[ins[b₂]] ≤ a, that is, b₂ sits entirely to the left of the strands b₁ puts out, except in the one case where both boxes are at the same position, b₁ has no outputs and b₂ no inputs (then they touch). normalize swaps out-of-order neighbours until there are none, at most 1000 times. The result has the boxes ordered bottom to top, and from left to right among boxes that could be at the same height.")
fn("normalizeLD", "normalizeLD[ld]",
   ["ld: a layered form LD[src, layers]."],
   "The normal form of ld under level exchange: the same diagram, with its layers reordered.",
   ["Look for the first k with leftQ[layers, k].", "If there is none, return. Otherwise swap layers k and k+1 (levelExchange) and repeat, at most 1000 times."],
   ["The engine function is Simplifier`Engine`normalize. Every step of a trace is normalized."],
   ['normalizeLD[LD[{"X", "Y"}, {{1, B["g", {"Y"}, {"Y"}]}, {0, B["f", {"X"}, {"X"}]}}]]'])
fn("levelExchange", "levelExchange[ld, k]",
   ["ld: a layered form.", "k: a layer number, 1 ≤ k < Length[layers]."],
   "The layered form with layers k and k+1 swapped, their positions shifted so the drawing does not change; $Failed when the two boxes touch (one takes a strand the other puts out).",
   ["Let b₁ at a be layer k and b₂ at b be layer k+1.", "If b₂ lies left of b₁'s outputs (b + #ins[b₂] ≤ a), b₂ goes first and b₁ moves by #outs[b₂] − #ins[b₂].", "If b₂ lies right of them (b ≥ a + #outs[b₁]), b₂ goes first at b − #outs[b₁] + #ins[b₁].", "Otherwise $Failed."],
   ["The engine function is Simplifier`Engine`swap, which works on the list of layers."],
   ['levelExchange[LD[{"X", "Y"}, {{0, B["f", {"X"}, {"X"}]}, {1, B["g", {"Y"}, {"Y"}]}}], 1]',
    'levelExchange[LD[{"X"}, {{0, B["f", {"X"}, {"Y"}]}, {0, B["g", {"Y"}, {"Z"}]}}], 1]'])
fn("adjacentLayers", "adjacentLayers[ld, i, j]",
   ["ld: a layered form.", "i < j: two layer numbers."],
   "{ld′, p}: ld′ is ld with layers reordered by level exchange so that the boxes that were layers i and j are now layers p and p+1. $Failed when the layers between them cannot all be moved out of the way.",
   ["If j = i + 1, return {ld, i}.", "Otherwise try to bubble the layer just above i downward below i, or the layer just below j upward above j, by repeated levelExchange (bubble).", "Recurse on the shorter gap; give up when no layer can move."],
   ["This is how two-box rules (kind 2) find their pairs: a cap and a cup joined by a line may be separated by boxes on other strands. The engine function is Simplifier`Engine`makeAdjacent; it is tried for every pair i < j."],
   ['adjacentLayers[LD[{"X", "Y"}, {{0, B["f", {"X"}, {"X"}]}, {1, B["h", {"Y"}, {"Y"}]}, {0, B["g", {"X"}, {"X"}]}}], 1, 3]'])

S("5. The rewriting loop")
T("A rule set is an Association name -> {kind, function}, in priority order. rewriteOnce tries the rules in that order and applies the first one that matches somewhere; the loop then normalizes the result and starts again from the first rule.")
SS("5.1 Rule kinds")
P("""kind      the function is called on                       and returns
"colour"  every colour c (the source and all ins, outs)   a list of colours to put in place of c
1         every layer {a, B[...]}, bottom to top          a list of layers to put in its place, or $Failed
2         every pair of layers i < j that adjacentLayers   a list of layers to put in place of the two, or $Failed
          can bring together, as the two layers
3         every three consecutive layers                  a list of layers to put in place of the three, or $Failed
"ld"      the whole LD                                    a new LD, or $Failed
"term"    a whole term of a linear combination (Ch. 4)    a new term or a list of terms, or $Failed""")
T("A \"colour\" rule applies when the map changes some colour (recolour rebuilds the diagram from the new colours). A rule of kind 1, 2 or 3 is tried at every place, in order, and the first place where it returns something other than $Failed is used (try1, try2, try3). Rule functions are written with one definition per pattern and a final catch-all returning $Failed, for example:")
P("""snakeL[{a_, B[o_, {}, {_, _}]}, {b_, B[w_, {_, _}, {}]}] /; pairQ[w, o] && b == a + 1 := {}
snakeL[__] := $Failed""")
T("This is the left zigzag (2.1): a cup o (no inputs, two outputs) directly below a cap w (two inputs, no outputs) one place to its right, joined by one line; they cancel. pairQ[w, o] holds for (ev_X, coev_X) and (ẽv_X, c̃oev_X) and for every pair declared with the option \"Pairings\".")
fn("rewriteOnceLD", "rewriteOnceLD[ld, opts]",
   ["ld: a layered form.", "opts: the options of simplifyLDTrace (section 7); they choose the rule set and declare pairings, inverses and retracts."],
   "{rule, ld′}: the name of the first rule that applies and its result, not yet normalized. $Failed when no rule applies: ld is in normal form.",
   ["rs = ruleSet[opts].", "For each name in rs, in order: apply its function according to its kind (5.1).", "Return the first success."],
   ["ld is used as given; normalize it first (normalizeLD) to get the same result as the loop."],
   ['rewriteOnceLD[normalizeLD[ld]]', 'rewriteOnceLD[LD[{"X"}, {{0, B["f", {"X"}, {"Y"}]}}]]'])
fn("simplifyLDTrace", "simplifyLDTrace[ld, opts]",
   ["ld: a layered form LD[src, layers] that fits together (validQ).", "opts: see section 7."],
   "The list of steps {{\"start\", ld₀}, {rule₁, ld₁}, …}: ld₀ = normalizeLD[ld], and each ldₖ is the normalized result of the rule ruleₖ applied to ldₖ₋₁. The last ld is the normal form.",
   ["rs = ruleSet[opts]; declare the pairings, inverses and retracts of opts for the engine.", "l = normalize[ld]; steps = {{\"start\", l}}.", "While rewriteOnce[l, rs] succeeds with {rule, l′} and there are fewer than \"MaxSteps\" steps: l = normalize[l′], append {rule, l}.", "Return steps."],
   ["The loop stops at \"MaxSteps\" (default 50) steps, counting the start, as the editor and the kernel do. A trace of length MaxSteps may not be finished.",
    "The rules only make diagrams smaller or more canonical, so in practice the loop ends long before; but the rule set is not confluent (section 12).",
    "This is the function the kernel's gcTrace calls."],
   ['simplifyLDTrace[ld]', 'simplifyLDTrace[textToLD["g f", "f : X → Y\\ng : Y → Z"]]'],
   ["fromLayered::invalid: ld does not fit together; the result is $Failed."])
fn("simplifyLD", "simplifyLD[ld, opts]", ["As simplifyLDTrace."], "The normal form: the LD of the last step.", None, None,
   ['simplifyLD[ld]'])

S("6. Choosing the rules")
fn("ruleSet", "ruleSet[opts]",
   ["\"Duals\" -> \"star\" (default) or \"vee\": pivotal categories with X** = X (§2.1.3 on) or only left duals (§2.1.2).",
    "\"Spherical\" -> False | True: add sphericity (§2.7.1).",
    "\"Symmetric\" -> False | True: the braiding is symmetric (§3.1.2).",
    "\"Ribbon\" -> False | True: θʳ = θˡ (§3.3.2); implies the spherical rules.",
    "\"PreFusion\" -> False | True: add the Chapter 4 rules on linear combinations (only with \"star\").",
    "\"RightZigzagFirst\" -> False | True: try the right zigzag before the left one."],
   "The Association name -> {kind, function} of the rules, in priority order.",
   ["If \"Duals\" is \"vee\": the rule set rulesB (§2.1.2 rules and braid rules).",
    "Else if \"Ribbon\": withTwists[rulesSB] joined with ribbonRules.",
    "Else: withTwists[rulesSB] if \"Spherical\", withTwists[rulesDB] if not.",
    "If \"Symmetric\": withSymmetry adds the two symmetric rules at the end.",
    "If \"RightZigzagFirst\": swap the two zigzag rules.",
    "If \"PreFusion\": withLin inserts the Chapter 4 term rules after ψ = id (X** = X)."],
   ["This is the choice gcHandler makes in the GraphicalCalculusKernel and the editor makes in Core.rulesFor, so the same options give the same steps.",
    "With \"vee\" the options Spherical, Ribbon and PreFusion are ignored: those rules need star duals."],
   ['ruleNames["Duals" -> "vee"]', 'Length[ruleNames[]]', 'Complement[ruleNames["Spherical" -> True, "Symmetric" -> True, "Ribbon" -> True], ruleNames[]]',
    'Take[ruleNames["RightZigzagFirst" -> True], 6]', 'ruleSet[]["(2.1) left zigzag"]'])
fn("ruleNames", "ruleNames[opts]", ["The options of ruleSet."], "The names of the rules, in priority order: Keys[ruleSet[opts]].", None, None,
   ['ruleNames["Spherical" -> True, "Symmetric" -> True, "Ribbon" -> True, "PreFusion" -> True] // Length'])
fn("ruleInfo, ruleCatalogue", "ruleInfo[name]\nruleCatalogue[opts]",
   ["name: a rule name, as in ruleNames.", "opts: the options of ruleSet."],
   "ruleInfo: an Association with \"Rule\", \"Book\" (where the rule comes from), \"Kind\" (in words), \"Function\" (the engine function), \"File\" (where it is defined) and \"Effect\" (what it rewrites into what). ruleCatalogue: a Dataset of ruleInfo for each rule of ruleSet[opts], in order.",
   None, ["The engine functions are in the context Simplifier`Engine`: Definition[Simplifier`Engine`snakeL] shows the code."],
   ['ruleInfo["(2.1) left zigzag"]', 'ruleCatalogue["Duals" -> "vee"]', 'Definition[Simplifier`Engine`snakeL]'])
SS("6.1 Which rules each mode uses")
P("""mode (options)                         rules
"Duals" -> "vee"                       12: unit, ⊗ strands, zigzags, ∨f, (2.2) slides, braid rules
default (star duals, pivotal)          31: adds dual ⊗ strands, caps on ⊗, id boxes, Fig. 2.3, Fig. 2.4, twist fold,
                                           X** = X, trace symmetry, inverses, ψ, Lemma 2.3, twists
"Spherical" -> True                    32: adds sphericity (§2.7.1) after Lemma 2.3
"Symmetric" -> True                    33: adds symmetry (§3.1.2) and τ_Y,X τ_X,Y = id at the end
"Ribbon" -> True                       33: spherical, and adds ribbon θʳ = θˡ at the end
"PreFusion" -> True                    45: adds 14 Chapter 4 term rules after ψ = id (X** = X)
all four                               49""")

S("7. Options of the simplification functions")
T("simplifyLDTrace and every function built on it take the options of ruleSet and these:")
IT("\"Pairings\" -> {{ω, Ω}, …}: declared pairs of a cap ω : X ⊗ Y → 𝟙 and a cup Ω : 𝟙 → Y ⊗ X that satisfy the zigzag identities (2.1), like the editor's pairings box. Default {}.")
IT("\"Inverses\" -> {{u, u′}, …}: declared inverse boxes, cancelled by the rule inverse boxes. Default {}.")
IT("\"Retracts\" -> {{p, j}, …}: declared retractions p j = id (§2.7.3). Default {}.")
IT("\"MaxSteps\" -> 50: the most steps a trace may have.")
T("The declarations are passed to the engine with Block over Simplifier`Engine`pairings, inverses and retracts, so they hold only during the call.")
I('simplifyTextSteps["(id_Y ⊗ ω)(Ω ⊗ id_Y)", "ω : X ⊗ Y → 𝟙\\nΩ : 𝟙 → Y ⊗ X", "Pairings" -> {{"ω", "Ω"}}]')
I('simplifyTextSteps["u′ u", "u : X → Y\\nu′ : Y → X", "Inverses" -> {{"u", "u′"}}]')

S("8. Expressions and text")
fn("simplifySteps, simplifyExpression", "simplifySteps[expr, sig, opts]\nsimplifyExpression[expr, sig, opts]",
   ["expr: an expression (SmallCircle, CircleTimes, Subscript[\"id\", c], unit and box symbols), as parseExpression returns.", "sig: the signature, an Association name -> {dom, cod} (parseSignature).", "opts: section 7."],
   "simplifySteps: {{rule, expression}, …}, the trace with each LD turned back into an expression by ldToExpression. simplifyExpression: the last expression.",
   ["ld = expressionToLD[expr, sig, \"Duals\" -> the \"Duals\" option].", "simplifyLDTrace[ld, opts].", "ldToExpression on each step."],
   ["The expressions of the trace are those of ldToExpression: products are grouped by layers, so they may be bracketed differently from what you typed."],
   ['sig = parseSignature["f : X → Y\\ng : Y → Z"]', 'simplifySteps[parseExpression["g f"], sig]',
    'simplifyExpression[parseExpression["ev_X (f* ⊗ id_X)"], parseSignature["f : X → Y"]]'],
   ["expressionToLD::type and ::untyped (from ExpressionToDiagram) when the expression does not typecheck; the result is $Failed."])
fn("simplifyTextSteps, simplifyText", "simplifyTextSteps[text, sigText, opts]\nsimplifyText[text, sigText, opts]",
   ["text: an expression in the editor's syntax (the manual of ExpressionToDiagram, section 3.1).", "sigText: the editor's signature box, one declaration per line (\"f : X → Y\"); colours that only appear in identities and duals need no declaration (write just \"X\").", "opts: section 7."],
   "simplifyTextSteps: {{rule, editor text}, …}. simplifyText: the normal form as editor text.",
   ["parseExpression, parseSignature, then simplifySteps, then toEditorText on each expression."], None,
   ['simplifyText["(id_X ⊗ ev_X)(coev_X ⊗ id_X)", "X"]', 'simplifyTextSteps["ev_X (f* ⊗ id_X)", "f : X → Y"]',
    'simplifyTextSteps["(ev_X ⊗ id_{∨X})(id_{∨X} ⊗ coev_X)", "X", "Duals" -> "vee"]'])
fn("equationReport, equationHoldsQ", "equationReport[text, sigText, opts]\nequationHoldsQ[text, sigText, opts]",
   ["text: an equation \"a = b\" (or \"a = b = c …\") in the editor's syntax.", "sigText, opts: as simplifyText."],
   "equationReport: an Association with \"Sides\" (the normal forms as text), \"Steps\" (the rule names used on each side), \"NormalForms\" (their LDs), \"Holds\" (True when all normal forms are identical) and \"Verdict\" (the sentence the editor shows). $Failed when a side does not parse or typecheck. equationHoldsQ: the \"Holds\" entry, False on failure.",
   ["Split text at =.", "Simplify each side with simplifyLDTrace.", "Compare the normal forms with SameQ."],
   ["True proves the equation: every rule is an identity of the book. False does not disprove it: the rules are not complete, so equal morphisms may have different normal forms (section 12)."],
   ['equationReport["ev_X (f* ⊗ id_X) = ev_Y (id_{Y*} ⊗ f)", "f : X → Y"]', 'equationHoldsQ["f = g", "f : X → Y\\ng : X → Y"]'])
fn("showSimplification", "showSimplification[text, sigText, opts]",
   ["As simplifyText."], "A picture of each step: the diagram drawn with renderP (with arrows, caps and cups; render for \"vee\"), the rule above it and the expression below (showTraceP of ExpressionToDiagram).",
   None, None, ['showSimplification["(id_X ⊗ ev_X)(coev_X ⊗ id_X)", "X"]'])

S("9. Chapter 4: terms of linear combinations")
T("In Chapter 4 a morphism is a linear combination of diagrams with coefficients in the ground ring and sums over simple objects. The editor and the kernel simplify one term at a time. A term is an Association:")
P("""<|"c"     -> <|"n" -> 1, "d" -> 1, "at" -> <|atom -> power, ...|>|>,   the coefficient n/d ∏ atom^power
  "sums"  -> {"i", ...},                                             summation variables (simple objects)
  "pairs" -> <|...|>,                                                pairs (α, β) of a partition
  "ld"    -> LD[src, layers]|>                                       the diagram""")
T("The atoms are strings: \"dl\\001i\" is dim_l(i), \"dr\\001i\" is dim_r(i), \"N\\001i\\001W\" is N^i_W, \"δ\\001i\\001j\" is δ_{i,j} (names sorted), \"δo\\001i\\001j\" is δ_{i°,j}, and \"a:…\" is a free atom (the separator is the character with code 1). The term rules (kind \"term\") of fusion-4-rules.wl rewrite whole terms; the diagram rules act on the term's ld. lTrace is the loop for terms; it is the same loop as simplifyLDTrace.")
fn("simplifyTermTrace, simplifyTerm", "simplifyTermTrace[term, opts]\nsimplifyTerm[term, opts]",
   ["term: a term as above.", "opts: section 7, with \"PreFusion\" -> True implied, and \"Simples\" -> {names}: the colours that are simple objects (§4.1). Summation variables are always treated as simple."],
   "simplifyTermTrace: {{rule, term}, …}. simplifyTerm: the last term.",
   ["rs = ruleSet[opts, \"PreFusion\" -> True].", "Block over Simplifier`Engine`lSimples; declare pairings, inverses, retracts.", "Simplifier`Engine`lTrace[term, rs]."],
   ["A term rule may give several terms (for example (4.8) or (4.10)); then lTrace continues on the first one and keeps the rest, as the editor does. Lemma 4.9(e)–(g) are not rules: they are checked in the matrix model of fusion-4.wl."],
   ['term = <|"c" -> <|"n" -> 1, "d" -> 1, "at" -> <||>|>, "sums" -> {}, "pairs" -> <||>, "ld" -> textToLD["ev_i coev~_i", "i"]|>;',
    'simplifyTermTrace[term, "Simples" -> {"i"}]'])

S("10. One request of the editor")
fn("payloadTrace", "payloadTrace[payload]",
   ["payload: an Association with the keys the editor sends to the GraphicalCalculusKernel: src and ls (the diagram as JSON: ls is a list of <|\"a\" -> position, \"name\" -> editor name, \"ins\" -> colours, \"outs\" -> colours|>, read by jsonToLD), pivotal, spherical, symmetric, ribbon, rightFirst, pairings, inverses, retracts; for Chapter 4 also prefusion, simples, c, sums and pairs."],
   "The steps: simplifyLDTrace, or simplifyTermTrace when prefusion is True.",
   ["Turn the flags into the options of section 7 (pivotal False means \"Duals\" -> \"vee\").", "Call simplifyLDTrace or simplifyTermTrace."],
   ["This is how section 13 checks the package against the editor."],
   ['payloadTrace[<|"pivotal" -> True, "src" -> {"X"}, "ls" -> {<|"a" -> 0, "name" -> "coev_X", "ins" -> {}, "outs" -> {"X", "X*"}|>, <|"a" -> 1, "name" -> "ev_X", "ins" -> {"X*", "X"}, "outs" -> {}|>}|>]'])

S("11. The rule catalogue")
T("Every rule of the largest rule set (\"Spherical\", \"Symmetric\", \"Ribbon\" and \"PreFusion\" all True), in priority order, with the book reference, the engine function and what it does:")
I('ruleCatalogue["Spherical" -> True, "Symmetric" -> True, "Ribbon" -> True, "PreFusion" -> True]')
T("The same as text, to read or copy:")
I('Column[StringRiffle[Values[#[[{"Rule", "Book", "Kind", "Function", "File"}]]], "  |  "] <> "\\n      " <> #["Effect"] & /@ ruleInfo /@ ruleNames["Spherical" -> True, "Symmetric" -> True, "Ribbon" -> True, "PreFusion" -> True]]')
SS("11.1 Why this order")
IT("Colour rules first: once 𝟙 strands are erased and ⊗ strands split, every other rule can assume single colours.")
IT("Zigzags and folds before slides: cancelling first keeps the diagram small; a slide only moves a box.")
IT("The strict X** = X rules before Lemma 2.3 and naturality of ψ: in the editor X** is X, so ψ never appears unless you type it.")
IT("Trace symmetry and sphericity late: they turn whole loops into a canonical shape, which is only useful once nothing else applies.")
IT("Braids after the pivotal rules, and the symmetric and ribbon rules last, since they only exist in those modes.")
IT("The Chapter 4 term rules after the strict rules and before trace symmetry, so partitions are expanded and δs substituted while the diagram is still in the shape of the book's figures.")

S("12. Limits")
IT("Not confluent: two orders of rules can lead to different normal forms of the same morphism. The fixed order makes the result deterministic, not canonical. So equationHoldsQ can answer False for a true equation.")
IT("Not complete: some identities of the book have no rule (for example Lemma 4.9(e)–(g), checked in the matrix model instead, and the general isotopy of Theorem 2.6 beyond the straightenings listed).")
IT("Rules only simplify: nothing is ever expanded, except the colour rules and Lemma 2.3, which make later rules applicable.")
IT("At most 50 steps by default (\"MaxSteps\").")
IT("Box names are compared as strings: f and f′ are different boxes, and trace symmetry orders loops by code points.")
IT("Lemma 4.6(b) as printed in the book does not hold for the rules (the left side gives Δ⁺); this is documented as a likely misprint in the Chapter 4 pages.")

S("13. Tests")
T("These cells check the package against the editor. tests/editor-requests-2.1-4.json holds 412 requests recorded from the editor (Chapters 2–4, 116 of them Chapter 4 terms) with the rule names the editor's JavaScript used. The package must use the same rules in the same order on every one.")
I('req = Import[FileNameJoin[{$SimplifierFolder, "tests", "editor-requests-2.1-4.json"}], "RawJSON"]; Length[req]')
I('res = Table[With[{s = Quiet@payloadTrace[r["payload"]]}, ListQ[s] && Rest[s[[All, 1]]] === r["js"]], {r, req}]; {Count[res, True], Length[res]}')
T("tests/editor-text-layered.json holds the 148 example sides of the editor, as text and as layered forms. Simplifying the text and simplifying the layered form must give the same rules and the same normal form:")
I('ex = Import[FileNameJoin[{$SimplifierFolder, "tests", "editor-text-layered.json"}], "RawJSON"]; Length[ex]')
I('toLD[e_] := LD[e["src"], {#[[1]], B[editorSymbol[#[[2]]], #[[3]], #[[4]]]} & /@ e["ls"]];\nchk = Table[Quiet@With[{a = simplifyTextSteps[e["text"], e["sig"], "Duals" -> e["duals"]], b = simplifyLDTrace[toLD[e], "Duals" -> e["duals"]]},\n   ListQ[a] && ListQ[b] && a[[All, 1]] === b[[All, 1]] && a[[-1, 2]] === toEditorText[ldToExpression[b[[-1, 2]]]]], {e, ex}]; {Count[chk, True], Length[chk]}')
T("A few identities of Chapter 2, each True:")
I('{equationHoldsQ["(id_X ⊗ ev_X)(coev_X ⊗ id_X) = id_X", "X"], equationHoldsQ["(ev_X ⊗ id_{X*})(id_{X*} ⊗ coev_X) = id_{X*}", "X"], equationHoldsQ["ev_X (f* ⊗ id_X) = ev_Y (id_{Y*} ⊗ f)", "f : X → Y"], equationHoldsQ["(id_X ⊗ ev_X)(coev_X ⊗ id_X) = id_X", "X", "Duals" -> "vee"]}')

S("14. Index of public symbols")
for name, what in [
  ("$SimplifierFolder, $SimplifierEngineFiles, engineReadyQ", "loading (section 1)"),
  ("toEngine, fromEngine", "heads (section 3)"),
  ("normalizeLD, levelExchange, adjacentLayers", "level exchange (section 4)"),
  ("rewriteOnceLD, simplifyLDTrace, simplifyLD", "the loop (section 5)"),
  ("ruleSet, ruleNames, ruleInfo, ruleCatalogue", "the rules (sections 6 and 11)"),
  ("simplifySteps, simplifyExpression, simplifyTextSteps, simplifyText, equationReport, equationHoldsQ, showSimplification", "expressions and text (section 8)"),
  ("simplifyTermTrace, simplifyTerm", "Chapter 4 terms (section 9)"),
  ("payloadTrace", "editor requests (section 10)"),
  ("from ExpressionToDiagram and DiagramToExpression: parseExpression, parseSignature, expressionToLD, textToLD, renderP, showTraceP, LD, B, ldToExpression, toEditorText, jsonToLD, editorSymbol, ...", "see their manuals")]:
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
open('/mnt/user-data/outputs/simplifier-manual.nb', 'w').write(nb)
import json
json.dump([c for st, c in cells if st == 'Input'], open('/mnt/user-data/outputs/simplifier-manual-inputs.json','w'), ensure_ascii=False)
print(len(cells), sum(1 for c in cells if c[0] == 'Input'))
