(* ::Package:: *)
(* ::Title:: *)
(* Simplifier: from expressions to expressions *)
(* The rewriting engine of CCN String Diagrams, from an expression (or the editor's text) to its normal form, with a
   clean, documented interface. The engine itself is the code of the notebooks: this package loads it, as the
   GraphicalCalculusKernel does, into its own context Simplifier`Engine`, chooses the rule set the way the editor and
   the kernel do, and converts between the engine's layered forms and those of DiagramToExpression and
   ExpressionToDiagram (diagram-to-expression.wl, expression-to-diagram.wl), which it loads from the same folder.
   After Turaev & Virelizier, Monoidal Categories and Topological Field Theory, Chapters 2–4.
   By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0

   The manual is the notebook simplifier-manual.nb in the same folder.

   Pipeline:
     text --parseExpression--> expression --expressionToLD--> LD --normalize--> LD --rewrite loop--> LD --ldToExpression--> expression
   Entry points:
     simplifyText[text, sigText, opts]       the editor's text in, the normal form as editor text out
     simplifyTextSteps[text, sigText, opts]  every step: {rule, editor text}
     equationReport[text, sigText, opts]     both sides of an equation, their steps and the verdict
     simplifyExpression, simplifySteps        the same on expressions with a signature Association
     simplifyLD, simplifyLDTrace              the same on layered forms
     simplifyTerm, simplifyTermTrace          one term of a Chapter 4 linear combination
     ruleSet, ruleNames, ruleInfo, ruleCatalogue   the rules, in priority order, and what each one does
     levelExchange, normalizeLD, adjacentLayers, rewriteOnceLD   the machinery, one step at a time *)

If[DownValues[ExpressionToDiagram`expressionToLD] === {},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "expression-to-diagram.wl"}]]];

BeginPackage["Simplifier`", {"DiagramToExpression`", "ExpressionToDiagram`"}];

$SimplifierFolder::usage = "$SimplifierFolder is the folder the engine files are read from: the folder of simplifier.wl.";
$SimplifierEngineFiles::usage = "$SimplifierEngineFiles lists the engine files, in the order they are loaded.";
engineReadyQ::usage = "engineReadyQ[] is True when every engine file loaded and the rule sets exist.";
ruleSet::usage = "ruleSet[opts] is the Association of rules, name -> {kind, function}, in priority order, for the options \"Duals\", \"Spherical\", \"Symmetric\", \"Ribbon\", \"PreFusion\" and \"RightZigzagFirst\": the same choice as the editor and the kernel.";
ruleNames::usage = "ruleNames[opts] = Keys[ruleSet[opts]].";
ruleInfo::usage = "ruleInfo[name] is an Association describing a rule: \"Book\" (where it comes from), \"Kind\", \"Function\" (the engine function), \"File\", \"Effect\" (what it rewrites into what).";
ruleCatalogue::usage = "ruleCatalogue[opts] is a Dataset of ruleInfo for every rule of ruleSet[opts], in priority order.";
simplifyLDTrace::usage = "simplifyLDTrace[ld, opts] simplifies a layered form: the list of steps {{rule, ld}, ...}, starting with {\"start\", normalize[ld]}. Each later step names the rule that was used and gives the normalized result.";
simplifyLD::usage = "simplifyLD[ld, opts] is the normal form: the layered form of the last step of simplifyLDTrace.";
simplifyExpression::usage = "simplifyExpression[expr, sig, opts] is the normal form of an expression, as an expression (ldToExpression of simplifyLD).";
simplifySteps::usage = "simplifySteps[expr, sig, opts] is the list {{rule, expression}, ...} of the steps.";
simplifyText::usage = "simplifyText[text, sigText, opts] reads an expression in the editor's syntax with its signature, and returns the normal form as editor text.";
simplifyTextSteps::usage = "simplifyTextSteps[text, sigText, opts] is the list {{rule, editor text}, ...} of the steps.";
equationReport::usage = "equationReport[text, sigText, opts] simplifies every side of an equation \"a = b = ...\": an Association with \"Sides\" (the normal forms as text), \"Steps\" (the rules used on each side), \"Holds\" (True when all normal forms agree) and \"Verdict\" (the editor's sentence).";
equationHoldsQ::usage = "equationHoldsQ[text, sigText, opts] is True when all sides of the equation reach the same normal form.";
showSimplification::usage = "showSimplification[text, sigText, opts] draws the steps with renderP (showTraceP), and the expressions below.";
simplifyTermTrace::usage = "simplifyTermTrace[term, opts] simplifies one term of a Chapter 4 linear combination: term is <|\"c\" -> coefficient, \"sums\" -> {...}, \"pairs\" -> <|...|>, \"ld\" -> LD[...]|> (the kernel's form, section 9 of the manual), with \"PreFusion\" -> True and \"Simples\" -> {...}. Returns {{rule, term}, ...}.";
simplifyTerm::usage = "simplifyTerm[term, opts] is the last term of simplifyTermTrace.";
payloadTrace::usage = "payloadTrace[payload] runs one request of the editor, as sent to the GraphicalCalculusKernel (an Association with src, ls, pivotal, spherical, symmetric, ribbon, rightFirst, pairings, inverses, retracts, and for Chapter 4 prefusion, simples, c, sums, pairs), and returns the steps.";
levelExchange::usage = "levelExchange[ld, k] swaps layers k and k+1 when their boxes do not touch (Figure 2.1), or returns $Failed.";
normalizeLD::usage = "normalizeLD[ld] is the normal form under level exchange: while some layer k+1 lies entirely to the left of layer k, swap them.";
adjacentLayers::usage = "adjacentLayers[ld, i, j] tries to bring layers i < j next to each other by level exchange: {ld', p} with the two boxes at p and p+1, or $Failed.";
rewriteOnceLD::usage = "rewriteOnceLD[ld, opts] applies the first rule of ruleSet[opts] that matches anywhere: {rule, ld'} (not normalized), or $Failed when no rule applies.";
toEngine::usage = "toEngine[x] replaces the heads LD, B and unit of DiagramToExpression by those of the engine.";
fromEngine::usage = "fromEngine[x] replaces the engine's heads LD, B and unit by those of DiagramToExpression.";
Simplifier::engine = "The engine did not load from `1`: check that graphical-calculus-2.1-simplify.nb, pivotal-2.1.3.wl, penrose-2.2.wl, pivotal-2.3-2.7.wl, braided-2.7-3.2.wl, ribbon-3.3.wl and fusion-4-rules.wl are in that folder.";

Begin["`Private`"];

(* ---------- section 2: loading the engine ---------- *)
$SimplifierFolder = DirectoryName[$InputFileName];
$SimplifierEngineFiles = {"graphical-calculus-2.1-simplify.nb", "pivotal-2.1.3.wl", "penrose-2.2.wl", "pivotal-2.3-2.7.wl", "braided-2.7-3.2.wl", "ribbon-3.3.wl", "fusion-4-rules.wl"};
loadEngine[] := Block[{$Context = "Simplifier`Engine`", $ContextPath = {"Simplifier`Engine`", "System`"}},
   With[{nb = FileNameJoin[{$SimplifierFolder, First[$SimplifierEngineFiles]}]},
    If[FileExistsQ[nb],
     With[{cells = Cases[Get[nb], Cell[c_, "Input" | "Code", ___] :> c, Infinity]},     (* sections 0–19 of the notebook, in order *)
      Scan[Quiet@Check[TimeConstrained[If[StringQ[#], Get[StringToStream[#]], ToExpression[#, StandardForm]]; Null, 120], Null] &, cells]]]];
   Scan[With[{f = FileNameJoin[{$SimplifierFolder, #}]}, If[FileExistsQ[f], Quiet[Get[f]]]] &, Rest[$SimplifierEngineFiles]]];
loadEngine[];
engineReadyQ[] := And @@ (AssociationQ[Symbol["Simplifier`Engine`" <> #]] & /@ {"rules", "rulesP", "rulesT", "rulesD", "rulesS", "rulesB", "rulesDB", "rulesSB", "twistRules", "ribbonRules", "linRules"}) &&
   Length[DownValues[Simplifier`Engine`normalize]] > 0 && Length[DownValues[Simplifier`Engine`rewriteOnce]] > 0;
If[! engineReadyQ[], Message[Simplifier::engine, $SimplifierFolder]];

(* ---------- section 3: heads ---------- *)
toEngine[x_] := x /. {DiagramToExpression`LD -> Simplifier`Engine`LD, DiagramToExpression`B -> Simplifier`Engine`B, DiagramToExpression`unit -> Simplifier`Engine`unit};
fromEngine[x_] := x /. {Simplifier`Engine`LD -> DiagramToExpression`LD, Simplifier`Engine`B -> DiagramToExpression`B, Simplifier`Engine`unit -> DiagramToExpression`unit};

(* ---------- section 4: choosing the rules (the same choice as the editor and the kernel) ---------- *)
Options[ruleSet] = {"Duals" -> "star", "Spherical" -> False, "Symmetric" -> False, "Ribbon" -> False, "PreFusion" -> False, "RightZigzagFirst" -> False};
rightFirst[rs_Association] := With[{k = Keys[rs], i = First[FirstPosition[Keys[rs], "(2.1) left zigzag"]]},
   AssociationThread[#, Lookup[rs, #]] &[Join[Take[k, i - 1], {k[[i + 1]], k[[i]]}, Drop[k, i + 1]]]];
ruleSet[OptionsPattern[]] := Module[{piv = OptionValue["Duals"] =!= "vee", rs},
   rs = Which[piv && TrueQ[OptionValue["Ribbon"]], Join[Simplifier`Engine`withTwists[Simplifier`Engine`rulesSB], Simplifier`Engine`ribbonRules],
     piv, Simplifier`Engine`withTwists[If[TrueQ[OptionValue["Spherical"]], Simplifier`Engine`rulesSB, Simplifier`Engine`rulesDB]],
     True, Simplifier`Engine`rulesB];
   If[TrueQ[OptionValue["Symmetric"]], rs = Simplifier`Engine`withSymmetry[rs]];
   If[TrueQ[OptionValue["RightZigzagFirst"]], rs = rightFirst[rs]];
   If[TrueQ[OptionValue["PreFusion"]] && piv, rs = Simplifier`Engine`withLin[rs]];
   rs];
ruleNames[opts : OptionsPattern[ruleSet]] := Keys[ruleSet[opts]];

(* ---------- section 5: the simplification loop ---------- *)
Options[simplifyLDTrace] = Join[Options[ruleSet], {"Pairings" -> {}, "Inverses" -> {}, "Retracts" -> {}, "MaxSteps" -> 50}];
ruleOpts[o_List] := FilterRules[o, Options[ruleSet]];
withData[o_List, body_] := With[{f = FilterRules[o, Options[simplifyLDTrace]]}, Block[{Simplifier`Engine`pairings = OptionValue[simplifyLDTrace, f, "Pairings"],
    Simplifier`Engine`inverses = OptionValue[simplifyLDTrace, f, "Inverses"], Simplifier`Engine`retracts = OptionValue[simplifyLDTrace, f, "Retracts"]}, body]];
SetAttributes[withData, HoldRest];
simplifyLDTrace[ld_DiagramToExpression`LD, opts : OptionsPattern[]] := Module[{rs = ruleSet[Sequence @@ ruleOpts[{opts}]], l, steps, r, max = OptionValue["MaxSteps"]},
   If[! validQ[ld], Message[fromLayered::invalid, Short[ld]]; Return[$Failed]];
   withData[{opts},
    l = Simplifier`Engine`normalize[toEngine[ld]]; steps = {{"start", l}};
    While[MatchQ[r = Simplifier`Engine`rewriteOnce[l, rs], {_String, _Simplifier`Engine`LD}] && Length[steps] < max,
     l = Simplifier`Engine`normalize[r[[2]]]; AppendTo[steps, {r[[1]], l}]]];
   fromEngine[steps]];
simplifyLD[ld_, opts : OptionsPattern[simplifyLDTrace]] := With[{s = simplifyLDTrace[ld, opts]}, If[s === $Failed, $Failed, s[[-1, 2]]]];

(* ---------- section 6: expressions and text ---------- *)
dualsOf[o_List] := OptionValue[simplifyLDTrace, FilterRules[o, Options[simplifyLDTrace]], "Duals"];
simplifySteps[e_, sig_Association, opts : OptionsPattern[simplifyLDTrace]] := With[{ld = expressionToLD[e, sig, "Duals" -> dualsOf[{opts}]]},
   If[ld === $Failed, $Failed, With[{s = simplifyLDTrace[ld, opts]}, If[s === $Failed, $Failed, {#[[1]], ldToExpression[#[[2]]]} & /@ s]]]];
simplifyExpression[e_, sig_Association, opts : OptionsPattern[simplifyLDTrace]] := With[{s = simplifySteps[e, sig, opts]}, If[s === $Failed, $Failed, s[[-1, 2]]]];
textSteps[text_String, sigText_String, opts___] := With[{e = parseExpression[text]}, If[e === $Failed, $Failed, simplifySteps[e, parseSignature[sigText], opts]]];
simplifyTextSteps[text_String, sigText_String, opts : OptionsPattern[simplifyLDTrace]] := With[{s = textSteps[text, sigText, opts]}, If[s === $Failed, $Failed, {#[[1]], toEditorText[#[[2]]]} & /@ s]];
simplifyText[text_String, sigText_String, opts : OptionsPattern[simplifyLDTrace]] := With[{s = simplifyTextSteps[text, sigText, opts]}, If[s === $Failed, $Failed, s[[-1, 2]]]];
equationReport[text_String, sigText_String, opts : OptionsPattern[simplifyLDTrace]] := Module[{sides = StringTrim /@ StringSplit[text, "="], sig = parseSignature[sigText], tr},
   tr = Function[s, With[{e = parseExpression[s]}, If[e === $Failed, $Failed, With[{ld = expressionToLD[e, sig, "Duals" -> dualsOf[{opts}]]}, If[ld === $Failed, $Failed, simplifyLDTrace[ld, opts]]]]]] /@ sides;
   If[MemberQ[tr, $Failed], Return[$Failed]];
   With[{holds = SameQ @@ (#[[-1, 2]] & /@ tr)},
    <|"Sides" -> (toEditorText[ldToExpression[#[[-1, 2]]]] & /@ tr), "Steps" -> (Rest[#[[All, 1]]] & /@ tr), "NormalForms" -> (#[[-1, 2]] & /@ tr), "Holds" -> holds,
      "Verdict" -> If[Length[sides] < 2, "One side: no equation to check.", If[holds, "\[Checkmark] Both sides reduce to the same normal form, so the equation holds.",
         "The normal forms differ. The rules did not prove this equation (that does not show it is false)."]]|>]];
equationHoldsQ[text_String, sigText_String, opts : OptionsPattern[simplifyLDTrace]] := With[{r = equationReport[text, sigText, opts]}, AssociationQ[r] && TrueQ[r["Holds"]]];
showSimplification[text_String, sigText_String, opts : OptionsPattern[simplifyLDTrace]] := With[{e = parseExpression[text]},
   If[e === $Failed, $Failed, With[{ld = expressionToLD[e, parseSignature[sigText], "Duals" -> dualsOf[{opts}]]},
     If[ld === $Failed, $Failed, If[dualsOf[{opts}] === "vee", showTrace[simplifyLDTrace[ld, opts]], showTraceP[simplifyLDTrace[ld, opts]]]]]]];

(* ---------- section 7: Chapter 4 terms ---------- *)
Options[simplifyTermTrace] = Join[Options[simplifyLDTrace], {"Simples" -> {}}];
simplifyTermTrace[term_Association, opts : OptionsPattern[]] := Module[{rs = ruleSet[Sequence @@ FilterRules[{opts, "PreFusion" -> True}, Options[ruleSet]]], s},
   s = Block[{Simplifier`Engine`lSimples = OptionValue["Simples"]}, withData[{opts}, Simplifier`Engine`lTrace[toEngine[term], rs]]];
   fromEngine[s]];
simplifyTerm[term_Association, opts : OptionsPattern[simplifyTermTrace]] := Last[simplifyTermTrace[term, opts]][[2]];

(* ---------- section 8: one request of the editor ---------- *)
payloadTrace[j_Association] := Module[{ld = jsonToLD[j], opts},
   opts = {"Duals" -> If[TrueQ[j["pivotal"]], "star", "vee"], "Spherical" -> TrueQ[j["spherical"]], "Symmetric" -> TrueQ[j["symmetric"]], "Ribbon" -> TrueQ[j["ribbon"]],
     "RightZigzagFirst" -> TrueQ[j["rightFirst"]], "Pairings" -> Lookup[j, "pairings", {}], "Inverses" -> Lookup[j, "inverses", {}], "Retracts" -> Lookup[j, "retracts", {}]};
   If[TrueQ[j["prefusion"]],
    simplifyTermTrace[<|"c" -> j["c"], "sums" -> j["sums"], "pairs" -> Replace[j["pairs"], {} -> <||>], "ld" -> ld|>, Sequence @@ opts, "Simples" -> Lookup[j, "simples", {}]],
    simplifyLDTrace[ld, Sequence @@ opts]]];

(* ---------- section 9: the machinery ---------- *)
levelExchange[ld : DiagramToExpression`LD[src_, ls_], k_Integer] := With[{r = Simplifier`Engine`swap[toEngine[ls], k]}, If[r === $Failed, $Failed, DiagramToExpression`LD[src, fromEngine[r]]]];
normalizeLD[ld_DiagramToExpression`LD] := fromEngine[Simplifier`Engine`normalize[toEngine[ld]]];
adjacentLayers[ld : DiagramToExpression`LD[src_, ls_], i_Integer, j_Integer] := With[{r = Simplifier`Engine`makeAdjacent[toEngine[ls], i, j]},
   If[r === $Failed, $Failed, {DiagramToExpression`LD[src, fromEngine[r[[1]]]], r[[2]]}]];
rewriteOnceLD[ld_DiagramToExpression`LD, opts : OptionsPattern[simplifyLDTrace]] := With[{rs = ruleSet[Sequence @@ ruleOpts[{opts}]]},
   withData[{opts}, fromEngine[Simplifier`Engine`rewriteOnce[toEngine[ld], rs]]]];

(* ---------- section 10: the rule catalogue ---------- *)
info = <|
  "unit strands" -> {"§2.1.2 (𝟙 is not drawn)", "unitMap", "graphical-calculus-2.1-simplify.nb", "erases every strand coloured 𝟙"},
  "\[CircleTimes]-coloured strands" -> {"§2.1.2", "splitMap", "graphical-calculus-2.1-simplify.nb", "splits a strand coloured X⊗Y into two strands X, Y (colours in parentheses are left alone)"},
  "dual \[CircleTimes]-coloured strands" -> {"§2.2, ?*\:2082", "splitStarMap", "penrose-2.2.wl", "splits a strand coloured (X⊗Y)* into Y*, X*"},
  "caps and cups on \[CircleTimes]" -> {"§2.2, Lemma 2.4", "nestCapsD", "pivotal-2.3-2.7.wl", "ev_{Y⊗X} = ev_X(id_X* ⊗ ev_Y ⊗ id_X), and the same for coev, ẽv, c̃oev: a cap or cup on a tensor colour becomes nested caps or cups"},
  "(2.1) left zigzag" -> {"(2.1), Figure 2.2", "snakeL", "graphical-calculus-2.1-simplify.nb", "a cup Ω directly below a cap ω, joined by one line, with the cap one place to the right of the cup, cancels when (ω, Ω) is a declared pairing or an (ev, coev) pair"},
  "(2.1) right zigzag" -> {"(2.1), Figure 2.2", "snakeR", "graphical-calculus-2.1-simplify.nb", "the mirror image: the cap one place to the left of the cup"},
  "definition of \[Or]f" -> {"§2.1.2", "foldDual", "graphical-calculus-2.1-simplify.nb", "coev_X, then f : X → Y on the X leg, then ev_Y: folds into the box ∨f : ∨Y → ∨X"},
  "(2.2) slide through ev" -> {"(2.2)", "slideEv", "graphical-calculus-2.1-simplify.nb", "a dual box ∨f on the left leg of ev_X moves to the right leg as f"},
  "(2.2) slide through coev" -> {"(2.2)", "slideCoev", "graphical-calculus-2.1-simplify.nb", "a dual box on the right leg of coev moves to the left leg"},
  "identity boxes" -> {"§2.1.3", "idBox", "pivotal-2.1.3.wl", "removes a box id_X : X → X"},
  "Fig. 2.3 fold (left)" -> {"Figure 2.3", "starFoldL", "pivotal-2.1.3.wl", "coev_X, f on the X leg, ev_Y: folds into f* : Y* → X* (X* written with a star)"},
  "Fig. 2.3 fold (right)" -> {"Figure 2.3", "starFoldR", "pivotal-2.1.3.wl", "the same with c̃oev and ẽv on the other side"},
  "Fig. 2.4 slide through ev" -> {"Figure 2.4", "slideStarEv", "pivotal-2.1.3.wl", "f* on the left leg of ev_X moves to the right leg as f"},
  "Fig. 2.4 slide through coev" -> {"Figure 2.4", "slideStarCoev", "pivotal-2.1.3.wl", "f* on the right leg of coev moves to the left leg as f"},
  "Fig. 2.4 slide through right ev" -> {"Figure 2.4", "slideStarEvR", "pivotal-2.1.3.wl", "f* on the right leg of ẽv_X moves to the left leg as f"},
  "Fig. 2.4 slide through right coev" -> {"Figure 2.4", "slideStarCoevR", "pivotal-2.1.3.wl", "f* on the left leg of c̃oev moves to the right leg as f"},
  "twist fold (\[Section]3.3.1)" -> {"§3.3.1, Lemma 3.2", "twistFold", "ribbon-3.3.wl", "a curl (cup, crossing, cap) becomes θˡ_X, θʳ_X or an inverse; layers that do not touch the curl may sit between its parts"},
  "Lemma 2.3 (X** = X)" -> {"Lemma 2.3, with X** = X", "lemma23strict", "pivotal-2.3-2.7.wl", "ev_X* = ẽv_X, ẽv_X* = ev_X, coev_X* = c̃oev_X, c̃oev_X* = coev_X (the editor's strict pivotal convention)"},
  "\[Psi] = id (X** = X)" -> {"§2.3.1, with X** = X", "psiStrict", "pivotal-2.3-2.7.wl", "removes ψ_X and ψ⁻¹_X when X** = X"},
  "trace symmetry (\[Section]2.6.1)" -> {"§2.6.1", "traceTurn", "pivotal-2.3-2.7.wl", "turns a loop whose boxes sit on one leg so that the chain starts at its smallest box name (code-point order): tr(pq) = tr(qp)"},
  "inverse boxes" -> {"§2.6.2", "cancelInv", "pivotal-2.3-2.7.wl", "u′ u and u u′ cancel for a declared pair (\"Inverses\" -> {{\"u\", \"u′\"}}); ψ and ψ⁻¹ cancel too"},
  "naturality of \[Psi] (\[Section]2.5.1)" -> {"§2.5.1", "natPsi", "pivotal-2.3-2.7.wl", "f** ψ_X = ψ_Y f (only when X** is kept apart from X)"},
  "Lemma 2.3" -> {"Lemma 2.3", "lemma23", "pivotal-2.3-2.7.wl", "ev_X* = ẽv_X (ψ⁻¹ ⊗ id) and the other three, when X** is kept apart from X"},
  "sphericity (\[Section]2.7.1)" -> {"§2.7.1", "sphericityAll", "pivotal-2.3-2.7.wl", "spherical categories only: a right loop ẽv (f ⊗ id) coev becomes the left loop ev (id ⊗ f) c̃oev"},
  "braiding on \[CircleTimes] (3.1)\[Dash](3.3)" -> {"(3.1)–(3.3)", "braidSplit", "braided-2.7-3.2.wl", "a crossing of tensor products splits into crossings of single strands; a crossing with 𝟙 disappears"},
  "retract (\[Section]2.7.3)" -> {"§2.7.3, Lemma 2.10", "cancelRetract", "braided-2.7-3.2.wl", "p j = id for a declared retraction (\"Retracts\" -> {{\"p\", \"j\"}})"},
  "R2 (\[Section]3.2.2)" -> {"§3.2.2", "cancelCross", "braided-2.7-3.2.wl", "a crossing and its inverse on the same strands cancel"},
  "R4, R5: naturality of \[Tau]" -> {"§3.1.1, §3.2.2", "naturalTau", "braided-2.7-3.2.wl", "a one-line box above a crossing moves below it, on the other strand"},
  "R3: Yang\[Dash]Baxter" -> {"Exercise 3.1.12", "yangBaxter", "braided-2.7-3.2.wl", "three crossings of one kind on positions a, a+1, a become a+1, a, a+1"},
  "twists cancel (Lemma 3.2)" -> {"Lemma 3.2", "cancelTwist", "ribbon-3.3.wl", "a twist directly on its inverse cancels"},
  "naturality of \[Theta] (Lemma 3.2)" -> {"Lemma 3.2", "naturalTwist", "ribbon-3.3.wl", "a twist above a one-line box moves below it"},
  "twist on \[CircleTimes] (Exercise 3.3.3)" -> {"Exercise 3.3.3", "twistTensor", "ribbon-3.3.wl", "θ_{X⊗Y} = (θ_X ⊗ θ_Y) τ_{Y,X} τ_{X,Y}; θ_𝟙 = id"},
  "ribbon: \[Theta]\:02b3 = \[Theta]\:02e1 (\[Section]3.3.2)" -> {"§3.3.2", "ribbonTwist", "ribbon-3.3.wl", "ribbon categories only: θʳ becomes θˡ (and the inverses)"},
  "symmetry (\[Section]3.1.2)" -> {"§3.1.2, Remark 3.2.3", "symmetricTau", "braided-2.7-3.2.wl", "symmetric braidings only: an under-crossing τ⁻¹_{Y,X} becomes the over-crossing τ_{X,Y}"},
  "\[Tau]_Y,X \[Tau]_X,Y = id (\[Section]3.1.2)" -> {"§3.1.2", "cancelSym", "braided-2.7-3.2.wl", "symmetric braidings only: two over-crossings of the same pair cancel"},
  "\[Delta] substitution" -> {"Chapter 4", "lDeltaRule", "fusion-4-rules.wl", "δ_{i,j}: a sum over j collapses, otherwise the larger name is renamed to the smaller"},
  "turning \[Omega]_S (\[Section]4.3.2, Theorem 2.6)" -> {"§4.3.2", "lTurnPairing", "fusion-4-rules.wl", "a closed pairing ev_S(β ⊗ α) is turned to put the box with the smaller name first"},
  "Lemma 4.9(a)" -> {"Lemma 4.9(a)", "lRule49a", "fusion-4-rules.wl", "a j-partition of a simple i is δ_{i,j}(id, id); of i*, δ_{i°,j}(φ_{i,j}, φ⁻¹_{i,j})"},
  "Lemma 4.9(b)" -> {"Lemma 4.9(b)", "lRule49bc[True]", "fusion-4-rules.wl", "a 1-partition of i* ⊗ j is δ_{i,j} dim_l(i)⁻¹ (ev_i, c̃oev_i)"},
  "Lemma 4.9(c)" -> {"Lemma 4.9(c)", "lRule49bc[False]", "fusion-4-rules.wl", "a 1-partition of i ⊗ j* is δ_{i,j} dim_r(i)⁻¹ (ẽv_i, coev_i)"},
  "(4.9)" -> {"(4.9)", "lRule49", "fusion-4-rules.wl", "for a 1-partition, q p f = f and g q p = g (also g paired with q by a cap)"},
  "isotopy: straightening (Theorem 2.6)" -> {"Theorem 2.6", "lStraighten", "fusion-4-rules.wl", "a box without outputs bent round a cup and paired by a cap with f becomes b f; a box inside a cup capped with its other leg is straightened"},
  "(4.7)" -> {"(4.7)", "lRule47", "fusion-4-rules.wl", "p_α q_α = N^i_W id_i (the semi-disk on top of its compressed rectangle)"},
  "(4.8)" -> {"(4.8)", "lRule48", "fusion-4-rules.wl", "∑_i q_α p_α = id_W, when i appears nowhere else"},
  "Lemma 4.9(d)" -> {"Lemma 4.9(d)", "lRule49d", "fusion-4-rules.wl", "a 1-partition of i* ⊗ W (or W ⊗ i*) is dim_l(i)⁻¹ (or dim_r(i)⁻¹) times an i-partition of W, bent"},
  "dim_l(i), dim_r(i) of a simple object" -> {"§2.4, Lemma 4.2", "lDimSimple", "fusion-4-rules.wl", "an empty loop on a simple object is the scalar dim_l(i) or dim_r(i)"},
  "(4.10)" -> {"(4.10)", "lDims410", "fusion-4-rules.wl", "an empty loop on any other object X is ∑_i dim(i) N^i_X"},
  "(4.2)" -> {"(4.2)", "lRule42", "fusion-4-rules.wl", "tr_r(f) = dim_l(i)⁻¹ dim_r(i) tr_l(f) for f on a simple i"},
  "Lemma 4.2(b)" -> {"Lemma 4.2(b)", "lRule42b", "fusion-4-rules.wl", "an endomorphism f of a simple i is dim_l(i)⁻¹ tr_l(f) id_i (unless it already sits alone on a loop)"}|>;
kindText = <|"colour" -> "colour map (every strand)", 1 -> "one box", 2 -> "two boxes, brought together by level exchange", 3 -> "three consecutive boxes",
   "ld" -> "the whole diagram", "term" -> "a whole term (Chapter 4)"|>;
ruleInfo[name_String] := With[{d = Lookup[info, name, {"", "", "", ""}], spec = Lookup[ruleSet["Duals" -> "star", "Spherical" -> True, "Symmetric" -> True, "Ribbon" -> True, "PreFusion" -> True], name, Lookup[Simplifier`Engine`rules, name, {Missing[], Missing[]}]]},
   <|"Rule" -> name, "Book" -> d[[1]], "Kind" -> Lookup[kindText, spec[[1]], spec[[1]]], "Function" -> d[[2]], "File" -> d[[3]], "Effect" -> d[[4]]|>];
ruleCatalogue[opts : OptionsPattern[ruleSet]] := Dataset[ruleInfo /@ ruleNames[opts]];

End[];
EndPackage[];
