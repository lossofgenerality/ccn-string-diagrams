(* ::Package:: *)
(* ::Title:: *)
(* ExpressionToDiagram: from expressions to boxes, lines and arrows *)
(* The Wolfram functions of CCN String Diagrams that turn an algebraic expression into a string diagram and draw it,
   gathered in one package. It is the companion of DiagramToExpression (diagram-to-expression.wl, the other direction),
   which it loads from the same folder and whose data structures (StringDiagram, LD, B, ...) it shares.
   After Turaev & Virelizier, Monoidal Categories and Topological Field Theory, Chapter 2.
   By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0

   The manual is the notebook expression-to-diagram-manual.nb in the same folder.

   Pipeline (diagrams read bottom to top, as in the book):
     editor text --parseExpression--> expression --expressionToLD--> LD --fromLayered--> StringDiagram --render/renderP--> Graphics
     signature text --parseSignature--> <|name -> {dom, cod}|>           (types of the boxes)
     expression --typeOf--> {dom, cod}
     expression --expressionToStrips--> Penrose strips (the inverse of penroseExpr)
     idL, boxL, stackL, besideL   build layered forms directly
     show, showP, showEq, showEqP, showTrace, showTraceP, showPenrose   picture + formula + type, side by side
   Arrows: renderP draws an arrowhead halfway along every arc, down for X and up for X*, and caps (ev, ẽv) and
   cups (coev, c̃oev) as half-loops with an arrowhead showing the direction of travel. *)

(* load the companion package from the same folder, unless its translators are already defined *)
If[DownValues[DiagramToExpression`toExpression] === {},
  Get[FileNameJoin[{DirectoryName[$InputFileName], "diagram-to-expression.wl"}]]];

BeginPackage["ExpressionToDiagram`", {"DiagramToExpression`"}];

parseSignature::usage = "parseSignature[text] reads an editor signature, one box per line \"f : X ⊗ Y → Z\" (𝟙 for the unit; # starts a comment), into <|\"f\" -> {{\"X\", \"Y\"}, {\"Z\"}}, ...|>. Lines the parser does not know (pairing, inverse, simple, partition, ...) are ignored.";
parseExpression::usage = "parseExpression[text] reads an expression in the editor's syntax: juxtaposition g f = g ∘ f (binds tightest), then ⊗, then ∘ and ; (f ; g = g ∘ f). Names may carry a subscript, plain (ev_X) or in braces (ev_{X⊗Y}, τ_{X,Y}); id_X is an identity and 𝟙, I or 1 the unit. ẽv and c̃oev may be typed as ev~ and coev~. Built-in names become structured symbols (editorSymbol).";
parseEquation::usage = "parseEquation[text] splits text at \"=\" and parses each side: a list of expressions.";
builtinType::usage = "builtinType[symbol, duals] is the type {dom, cod} of a built-in morphism (ev, coev, ẽv, c̃oev, τ, τ⁻¹, ψ, θ, φ), or Missing[] for any other symbol. duals is \"star\" (X*, §2.1.3, the default) or \"vee\" (∨X, §2.1.2).";
typeOf::usage = "typeOf[expr, sig] is {dom, cod}, the lists of source and target colours of an expression, or $Failed (with a message) when a composite does not fit. sig is a signature Association (parseSignature). Option \"Duals\" -> \"star\" | \"vee\".";
expressionToLD::usage = "expressionToLD[expr, sig] is the layered form LD[src, layers] of an expression: a box becomes one layer, id an identity on its colours, ⊗ puts layered forms side by side (besideL), ∘ stacks them (stackL, the right factor at the bottom). Returns $Failed with a message if a composite does not fit or a box has no type. Option \"Duals\" -> \"star\" | \"vee\".";
expressionToDiagram::usage = "expressionToDiagram[expr, sig] = fromLayered[expressionToLD[expr, sig]], a StringDiagram laid out for render and renderP.";
textToLD::usage = "textToLD[text, sigText] = expressionToLD[parseExpression[text], parseSignature[sigText]].";
textToGraphics::usage = "textToGraphics[text, sigText] draws an expression typed in the editor's syntax with renderP (oriented) or, with \"Oriented\" -> False, with render.";
expressionToStrips::usage = "expressionToStrips[expr, sig] writes an expression of the form (s_n) ∘ ... ∘ (s_1), each s_k a ⊗ of boxes and identities, as Penrose strips {strip_1, ..., strip_n} (bottom to top) for penroseLD; identities become seg pieces. It is the inverse of penroseExpr.";
idL::usage = "idL[colours] is the layered form of an identity: LD[colours, {}].";
boxL::usage = "boxL[symbol, ins, outs] is the layered form of one box: LD[ins, {{0, B[symbol, ins, outs]}}].";
stackL::usage = "stackL[l1, l2, ...] puts l2 on top of l1 (l2 ∘ l1): it needs the target of l1 to be the source of l2.";
besideL::usage = "besideL[l1, l2, ...] puts l2 to the right of l1 (l1 ⊗ l2).";
render::usage = "render[d] draws a StringDiagram (or a layered form) as Graphics without orientation: straight lines with colour labels, boxes as rectangles labelled by their symbols.";
renderP::usage = "renderP[d] draws a StringDiagram or a layered form with orientation (§2.1.3): an arrowhead on every line (down for X, up for X*), ev and ẽv as caps and coev and c̃oev as cups with an arrowhead.";
show::usage = "show[d] is a row: render[d], the expression toExpression[d], and its type source → target.";
showP::usage = "showP[ld] is a row: renderP[ld], its expression and its type.";
showEq::usage = "showEq[{d1, d2, ...}] draws the diagrams with = between them, and the expressions below.";
showEqP::usage = "showEqP[{ld1, ld2, ...}] is showEq with renderP, for layered forms.";
showTrace::usage = "showTrace[steps] draws a list {{rule, ld}, ...} (as simplifyTrace returns it) with the rule names on the arrows, and the expressions below.";
showTraceP::usage = "showTraceP[steps] is showTrace with renderP.";
showPenrose::usage = "showPenrose[src, strips] draws a Penrose diagram and shows its source, its target and the formula penroseExpr.";
pretty::usage = "pretty[expr] typesets the symbols of an expression: names in italics, ev and coev upright, X* as a superscript, ∨X with a small ∨.";
dispSym::usage = "dispSym[symbol] is the typeset form of one symbol (see pretty).";
source::usage = "source[d] is the source object of a StringDiagram: the ⊗ of the colours of its loose bottom ends, left to right.";
target::usage = "target[d] is the target object of a StringDiagram.";
expressionToLD::type = "The composite `1` ∘ `2` does not fit: the target of the right factor is `3`, but the left factor starts from `4`.";
expressionToStrips::shape = "The slice `1` is not a ⊗ of boxes and identities, so the expression is not in Penrose form.";
expressionToLD::untyped = "The box `1` has no type: add a line \"`1` : … → …\" to the signature.";
parseExpression::syntax = "`1`";

Begin["`Private`"];

(* ---------- section 2: signatures and built-in types ---------- *)
unitWordQ[w_String] := MemberQ[{"I", "1", "\[DoubleStruckOne]", FromCharacterCode[120793]}, w];
colourList[s_String] := Select[StringTrim /@ StringSplit[StringTrim[StringTrim[s], "(" | ")"], "\[CircleTimes]"], # =!= "" && ! unitWordQ[#] &];
colourList[unit] := {};
parseSignature[text_String] := Association[Flatten[Function[line,
     With[{l = StringTrim[StringReplace[line, RegularExpression["(#|//).*$"] -> ""]]},
      If[l === "" || ! StringContainsQ[l, ":"] || StringStartsQ[l, "partition"], {},
       With[{k = First[First[StringPosition[l, ":"]]]},
        With[{name = StringDelete[StringTake[l, k - 1], WhitespaceCharacter], rhs = StringDrop[l, k]},
         If[! StringContainsQ[rhs, "\[Rule]" | "\[RightArrow]" | "->"], {},
          With[{p = StringSplit[rhs, "\[Rule]" | "\[RightArrow]" | "->", 2]}, {name -> {colourList[p[[1]]], colourList[p[[2]]]}}]]]]]]] /@
    StringSplit[StringReplace[text, "\[DoubleStruckOne]" -> FromCharacterCode[120793]], "\n"]]];
flipStar[c_String] := If[StringEndsQ[c, "*"], StringDrop[c, -1], c <> "*"];
dualAtom[c_String, duals_] := If[duals === "vee", If[StringStartsQ[c, "\[Or]"], c, "\[Or]" <> c], flipStar[c]];
dualList[cs_List, duals_] := dualAtom[#, duals] & /@ Reverse[cs];
splitPair[s_String] := StringSplit[s, ",", 2];
builtinType[Subscript["ev", x_String], d_ : "star"] := With[{X = colourList[x]}, {Join[dualList[X, d], X], {}}];
builtinType[Subscript["coev", x_String], d_ : "star"] := With[{X = colourList[x]}, {{}, Join[X, dualList[X, d]]}];
builtinType[Subscript[OverTilde["ev"], x_String], d_ : "star"] := With[{X = colourList[x]}, {Join[X, dualList[X, d]], {}}];
builtinType[Subscript[OverTilde["coev"], x_String], d_ : "star"] := With[{X = colourList[x]}, {{}, Join[dualList[X, d], X]}];
builtinType[Subscript["\[Tau]", s_String], _ : "star"] := With[{p = colourList /@ splitPair[s]}, {Join[p[[1]], p[[2]]], Join[p[[2]], p[[1]]]}];
builtinType[Subscript[Superscript["\[Tau]", "-1"], s_String], _ : "star"] := With[{p = colourList /@ splitPair[s]}, {Join[p[[2]], p[[1]]], Join[p[[1]], p[[2]]]}];
builtinType[Subscript["\[Psi]" | Superscript["\[Psi]", "-1"], x_String], _ : "star"] := {colourList[x], colourList[x]};
builtinType[Subscript[t_String, x_String], _ : "star"] /; StringStartsQ[t, "\[Theta]"] := {colourList[x], colourList[x]};
builtinType[s_String, _ : "star"] /; StringMatchQ[s, RegularExpression["^\[CurlyPhi](\:207b\:00b9)?_\\{?[^,{}]+,[^{}]+\\}?$"]] :=
  With[{p = splitPair[StringTrim[StringReplace[s, RegularExpression["^\[CurlyPhi](\:207b\:00b9)?_"] -> ""], "{" | "}"]]},
   If[StringContainsQ[s, "\:207b\:00b9"], {{p[[2]]}, {flipStar[p[[1]]]}}, {{flipStar[p[[1]]]}, {p[[2]]}}]];
builtinType[_, _ : "star"] := Missing[];
(* the type of a box: the signature, a built-in, or the dual of a named box (f* in §2.1.3, ∨f in §2.1.2) *)
boxType[s_, sig_, d_] := Which[
   StringQ[s] && KeyExistsQ[sig, s], sig[s],
   ! MissingQ[builtinType[s, d]], builtinType[s, d],
   StringQ[s] && d =!= "vee" && StringLength[s] > 1 && StringEndsQ[s, "*"] && ListQ[boxType[StringDrop[s, -1], sig, d]],
    With[{t = boxType[StringDrop[s, -1], sig, d]}, {dualList[t[[2]], d], dualList[t[[1]], d]}],
   StringQ[s] && d === "vee" && StringStartsQ[s, "\[Or]"] && ListQ[boxType[StringDrop[s, 1], sig, d]],
    With[{t = boxType[StringDrop[s, 1], sig, d]}, {dualList[t[[2]], d], dualList[t[[1]], d]}],
   True, Missing[]];

(* ---------- section 3: parsing the editor's syntax ---------- *)
wordChar = RegularExpression["[A-Za-z0-9\:0370-\:03ff\:2032'?\[Or]*~\:207b\:00b9\:02e1\:02b3\[Dagger]]"];
tokenize[s0_String] := Module[{s = StringReplace[s0, {"\[DoubleStruckOne]" -> " I ", FromCharacterCode[120793] -> " I ", "\:1ebdv" -> "ev~", "c\:0303oev" -> "coev~", "\:2217" -> "*", "(x)" -> "\[CircleTimes]", "->" -> "\[RightArrow]"}], i = 1, n, out = {}, c, j},
   n = StringLength[s];
   While[i <= n,
    c = StringTake[s, {i}];
    Which[
     StringMatchQ[c, WhitespaceCharacter], i++,
     MemberQ[{"\[CircleTimes]", "\[SmallCircle]", "\[CenterDot]", ";", "(", ")", "_", "{", "}", ",", "=", "\[RightArrow]", ":"}, c],
      AppendTo[out, {"s", If[c === "\[CenterDot]", "\[SmallCircle]", c], i}]; i++,
     StringMatchQ[c, wordChar],
      j = i; While[j <= n && StringMatchQ[StringTake[s, {j}], wordChar], j++];
      AppendTo[out, {"w", StringTake[s, {i, j - 1}], i}]; i = j,
     True, Message[parseExpression::syntax, "Unexpected symbol \[LeftDoubleBracket]" <> c <> "\[RightDoubleBracket] at position " <> ToString[i]]; Throw[$Failed, "parse"]]];
   out];
parseExpression[text_String] := Catch[Module[{T = tokenize[text], p = 1, is, accept, expect, word, expr, tens, juxt, post, atom, startsAtom, fail},
    fail[m_] := (Message[parseExpression::syntax, m <> If[p <= Length[T], " at position " <> ToString[T[[p, 3]]], " at the end"]]; Throw[$Failed, "parse"]);
    is[v_] := p <= Length[T] && T[[p, 1]] === "s" && T[[p, 2]] === v;
    accept[v_] := If[is[v], p++; True, False];
    expect[v_] := If[! accept[v], fail["Expected \[LeftDoubleBracket]" <> v <> "\[RightDoubleBracket]"]];
    word[] := If[p <= Length[T] && T[[p, 1]] === "w", p++; T[[p - 1, 2]], fail["Expected a name"]];
    startsAtom[] := p <= Length[T] && (T[[p, 1]] === "w" || is["("]);
    expr[] := Module[{acc = tens[], op, r},
      While[is["\[SmallCircle]"] || is[";"], op = T[[p, 2]]; p++; r = tens[]; acc = If[op === "\[SmallCircle]", compose[{acc, r}], compose[{r, acc}]]];
      flat[acc]];
    tens[] := Module[{fs = {juxt[]}}, While[accept["\[CircleTimes]"], AppendTo[fs, juxt[]]]; flat[tensor[fs]]];
    juxt[] := Module[{a = post[]}, While[startsAtom[], a = compose[{a, post[]}]]; flat[a]];
    post[] := atom[];
    atom[] := Module[{w, name, s},
      If[accept["("], With[{e = expr[]}, expect[")"]; Return[e, Module]]];
      w = word[];
      If[unitWordQ[w], Return[unit, Module]];
      If[w === "id",
       If[accept["_"], Return[id[subscript[]], Module], fail["id needs a colour: id_X"]]];
      name = w;
      (* as in the editor: a braced subscript of more than one character keeps its braces in the name *)
      If[accept["_"], s = subscriptRaw[]; name = w <> "_" <> If[s[[2]] && StringLength[s[[1]]] > 1, "{" <> s[[1]] <> "}", s[[1]]]];
      editorSymbol[name]];
    subscriptRaw[] := If[accept["{"], Module[{s = ""}, While[p <= Length[T] && ! is["}"], s = s <> T[[p, 2]]; p++]; expect["}"]; {s, True}], {word[], False}];
    subscript[] := With[{s = subscriptRaw[][[1]]}, If[unitWordQ[s], unit, s]];
    If[T === {}, fail["Empty expression"]];
    With[{e = expr[]}, If[p <= Length[T], fail["Unexpected \[LeftDoubleBracket]" <> ToString[T[[p, 2]]] <> "\[RightDoubleBracket]"]]; e]], "parse"];
(* flatten nested products and composites, drop identities of 𝟙 inside a product *)
flat[e_] := e //. {CircleTimes[a___, CircleTimes[b___], c___] :> CircleTimes[a, b, c], SmallCircle[a___, SmallCircle[b___], c___] :> SmallCircle[a, b, c]};
parseEquation[text_String] := parseExpression /@ StringSplit[text, "="];

(* ---------- section 4: layered forms built directly ---------- *)
idL[cs_List] := LD[cs, {}];
boxL[s_, i_List, o_List] := LD[i, {{0, B[s, i, o]}}];
stackL[l1 : LD[s1_, ls1_], LD[s2_, ls2_]] /; Last[rows[l1]] === s2 := LD[s1, Join[ls1, ls2]];
stackL[a_LD, b_LD, c__LD] := stackL[stackL[a, b], c];
besideL[l1 : LD[s1_, ls1_], LD[s2_, ls2_]] := With[{n = Length[Last[rows[l1]]]}, LD[Join[s1, s2], Join[ls1, {#[[1]] + n, #[[2]]} & /@ ls2]]];
besideL[a_LD, b_LD, c__LD] := besideL[besideL[a, b], c];
besideL[a_LD] := a;

(* ---------- section 5: typing and the main translator ---------- *)
Options[typeOf] = {"Duals" -> "star"};
Options[expressionToLD] = {"Duals" -> "star"};
Options[expressionToDiagram] = {"Duals" -> "star"};
typeOf[e_, sig_Association, OptionsPattern[]] := With[{l = expressionToLD[e, sig, "Duals" -> OptionValue["Duals"]]}, If[l === $Failed, $Failed, {l[[1]], Last[rows[l]]}]];
expressionToLD[e_, sig_Association, OptionsPattern[]] := Catch[toLD[e, sig, OptionValue["Duals"]], "type"];
toLD[unit, _, _] := idL[{}];
toLD[Subscript["id", c_], _, _] := idL[colourList[c]];
toLD[e_CircleTimes, sig_, d_] := besideL @@ (toLD[#, sig, d] & /@ List @@ e);
(* g ∘ f: f is the bottom layer; the factors are stacked from the right, checking that each fits on the one below *)
toLD[e_SmallCircle, sig_, d_] := Last[Fold[Function[{low, high}, If[Last[rows[low[[2]]]] === high[[2]][[1]], {high[[1]], stackL[low[[2]], high[[2]]]},
      Message[expressionToLD::type, toEditorText[high[[1]]], toEditorText[low[[1]]], Last[rows[low[[2]]]], high[[2]][[1]]]; Throw[$Failed, "type"]]],
    Reverse[{#, toLD[#, sig, d]} & /@ List @@ e]]];
toLD[s_, sig_, d_] := With[{t = boxType[s, sig, d]}, If[MissingQ[t], Message[expressionToLD::untyped, editorName[s]]; Throw[$Failed, "type"], boxL[s, t[[1]], t[[2]]]]];
expressionToDiagram[e_, sig_Association, opts : OptionsPattern[]] := With[{l = expressionToLD[e, sig, opts]}, If[l === $Failed, $Failed, fromLayered[l]]];
textToLD[text_String, sigText_String, opts : OptionsPattern[expressionToLD]] := With[{e = parseExpression[text]}, If[e === $Failed, $Failed, expressionToLD[e, parseSignature[sigText], opts]]];
Options[textToGraphics] = {"Oriented" -> True, "Duals" -> "star"};
textToGraphics[text_String, sigText_String, OptionsPattern[]] := With[{l = textToLD[text, sigText, "Duals" -> OptionValue["Duals"]]},
   If[l === $Failed, $Failed, If[TrueQ[OptionValue["Oriented"]], renderP[l], render[fromLayered[l]]]]];

(* ---------- section 6: Penrose strips from an expression ---------- *)
expressionToStrips[e_, sig_Association] := Module[{slices = If[Head[e] === SmallCircle, Reverse[List @@ e], {e}], piece},
   piece[Subscript["id", c_]] := seg /@ colourList[c];
   piece[unit] := {};
   piece[e : (_SmallCircle | _CircleTimes)] := (Message[expressionToStrips::shape, toEditorText[e]]; Throw[$Failed, "type"]);
   piece[s_] := With[{t = boxType[s, sig, "star"]}, If[MissingQ[t], Message[expressionToLD::untyped, editorName[s]]; Throw[$Failed, "type"], {B[s, t[[1]], t[[2]]]}]];
   Catch[(Join @@ (piece /@ If[Head[#] === CircleTimes, List @@ #, {#}])) & /@ slices, "type"]];

(* ---------- section 7: drawing ---------- *)
starQ[s_] := StringQ[s] && StringLength[s] > 1 && StringEndsQ[s, "*"];
unstar[s_String] := StringDrop[s, -1];
dispSym[s_String] := Which[s === unit, Style[s, Plain], starQ[s], Superscript[dispSym[unstar[s]], "*"], StringStartsQ[s, "("], s,
   StringStartsQ[s, "\[Or]"], Row[{Style["\[Or]", Smaller, Plain], Style[StringDrop[s, 1], Italic]}], StringStartsQ[s, "\[CapitalOmega]"], Style[s, Plain], True, Style[s, Italic]];
dispSym[Subscript[a_, b_]] := Subscript[Style[a, Plain], dispSym[b]];
dispSym[unit] := "\[DoubleStruckOne]";
dispSym[e_] := e;
pretty[e_] := e /. {Subscript[a_, b_] :> dispSym[Subscript[a, b]], s_String :> dispSym[s], unit -> "\[DoubleStruckOne]"};
labelY[w_, y1_, y2_] := Which[MatchQ[w[[3]], _Loose], y1 + 0.2, MatchQ[w[[4]], _Loose], y2 - 0.2, True, (y1 + y2)/2];
head[{x_, y_}, dir_] := Polygon[({x, y} + 0.075 #) & /@ (dir /. {"up" -> {{-1, -0.8}, {1, -0.8}, {0, 0.9}}, "down" -> {{-1, 0.8}, {1, 0.8}, {0, -0.9}},
        "right" -> {{-0.8, -1}, {-0.8, 1}, {0.9, 0}}, "left" -> {{0.8, -1}, {0.8, 1}, {-0.9, 0}}})];
upQ[c_] := starQ[c];
lineLabel[c_] := If[upQ[c], StringReplace[unstar[c], {"(" -> "", ")" -> ""}], c];
capQ[s_] := MatchQ[s, Subscript["ev" | OverTilde["ev"], _]];
cupQ[s_] := MatchQ[s, Subscript["coev" | OverTilde["coev"], _]];
objs[l_] := tensor[First /@ SortBy[l, #[[2]] &]];
source[d_StringDiagram] := objs[Select[d[[2]], MatchQ[#[[3]], _Loose] &]];
target[d_StringDiagram] := objs[Select[d[[2]], MatchQ[#[[4]], _Loose] &]];
render[ld_LD] := render[fromLayered[ld]];
render[d : StringDiagram[bs_, ws_]] := Module[{lines, boxes, pts, xr, yr},
   lines = Table[With[{x = w[[2]], y1 = endY[d, w[[3]]], y2 = endY[d, w[[4]]], left = Length[w] > 4},
      {Black, AbsoluteThickness[2.4], Line[{{x, y1}, {x, y2}}],
       Text[Style[dispSym[w[[1]]], 12, FontFamily -> "Times"], {x + If[left, -0.08, 0.08], labelY[w, y1, y2]}, {If[left, 1, -1], 0}]}], {w, ws}];
   boxes = Table[{EdgeForm[{Black, AbsoluteThickness[1.2]}], White, Rectangle[{b[[3, 1]], b[[4]] - hgt/2}, {b[[3, 2]], b[[4]] + hgt/2}],
      Black, Text[Style[dispSym[b[[2]]], If[Head[b[[2]]] === Subscript, 13, 15], FontFamily -> "Times"], {Mean[b[[3]]], b[[4]]}]}, {b, bs}];
   pts = Join[Flatten[Table[{{w[[2]], endY[d, w[[3]]]}, {w[[2]], endY[d, w[[4]]]}}, {w, ws}], 1],
     Flatten[Table[{{b[[3, 1]], b[[4]] - hgt/2}, {b[[3, 2]], b[[4]] + hgt/2}}, {b, bs}], 1]];
   {xr, yr} = If[pts === {}, {{0, 1}, {-1, 1}}, CoordinateBounds[pts]]; yr = {Min[yr[[1]], -1], Max[yr[[2]], 1]};
   Graphics[{lines, boxes}, PlotRange -> {xr + {-0.45, 0.45}, yr + {-0.1, 0.1}}, ImageSize -> 62 (xr[[2]] - xr[[1]] + 0.9), BaselinePosition -> Axis]];
renderP[ld_LD] := renderP[fromLayered[ld]];
renderP[d : StringDiagram[bs_, ws_]] := Module[{lines, shapes, pts, xr, yr, legs},
   legs[n_, end_] := SortBy[Select[ws, If[end === "top", #[[4]] === BottomEdge[n], #[[3]] === TopEdge[n]] &], #[[2]] &];
   lines = Table[With[{x = w[[2]], y1 = endY[d, w[[3]]], y2 = endY[d, w[[4]]], left = Length[w] > 4},
      {Black, AbsoluteThickness[2.2], Line[{{x, y1}, {x, y2}}], head[{x, (y1 + y2)/2}, If[upQ[w[[1]]], "up", "down"]],
       Text[Style[dispSym[lineLabel[w[[1]]]], 12, FontFamily -> "Times"], {x + If[left, -0.13, 0.13], labelY[w, y1, y2]}, {If[left, 1, -1], 0}]}], {w, ws}];
   shapes = Table[With[{s = b[[2]], n = b[[1]], y = b[[4]]},
      Which[
       capQ[s] && Length[legs[n, "top"]] == 2,
        With[{x1 = legs[n, "top"][[1, 2]], x2 = legs[n, "top"][[2, 2]], y0 = y - hgt/2},
         {Black, AbsoluteThickness[2.2], BezierCurve[{{x1, y0}, {x1, y0 + 0.67}, {x2, y0 + 0.67}, {x2, y0}}],
          head[{(x1 + x2)/2, y0 + 0.5}, If[upQ[legs[n, "top"][[1, 1]]], "right", "left"]]}],
       cupQ[s] && Length[legs[n, "bottom"]] == 2,
        With[{x1 = legs[n, "bottom"][[1, 2]], x2 = legs[n, "bottom"][[2, 2]], y0 = y + hgt/2},
         {Black, AbsoluteThickness[2.2], BezierCurve[{{x1, y0}, {x1, y0 - 0.67}, {x2, y0 - 0.67}, {x2, y0}}],
          head[{(x1 + x2)/2, y0 - 0.5}, If[upQ[legs[n, "bottom"][[1, 1]]], "left", "right"]]}],
       True, {EdgeForm[{Black, AbsoluteThickness[1.2]}], White, Rectangle[{b[[3, 1]], y - hgt/2}, {b[[3, 2]], y + hgt/2}],
        Black, Text[Style[dispSym[s], If[Head[s] === Subscript, 13, 15], FontFamily -> "Times"], {Mean[b[[3]]], y}]}]], {b, bs}];
   pts = Join[Flatten[Table[{{w[[2]], endY[d, w[[3]]]}, {w[[2]], endY[d, w[[4]]]}}, {w, ws}], 1],
     Flatten[Table[{{b[[3, 1]], b[[4]] - hgt/2}, {b[[3, 2]], b[[4]] + hgt/2}}, {b, bs}], 1]];
   {xr, yr} = If[pts === {}, {{0, 1}, {-1, 1}}, CoordinateBounds[pts]]; yr = {Min[yr[[1]], -1], Max[yr[[2]], 1]};
   Graphics[{lines, shapes}, PlotRange -> {xr + {-0.5, 0.55}, yr + {-0.1, 0.1}}, ImageSize -> 62 (xr[[2]] - xr[[1]] + 1.05), BaselinePosition -> Axis]];

(* ---------- section 8: picture, formula and type together ---------- *)
show[d_] := With[{dd = fromLayered[d]}, Grid[{{render[dd], Style[pretty[toExpression[dd]], 17, FontFamily -> "Times"],
     Style[Row[{pretty[source[dd]], "  \[RightArrow]  ", pretty[target[dd]]}], 12, GrayLevel[0.4]]}}, Spacings -> 3, Alignment -> {Left, Center}]];
showP[d_] := With[{dd = fromLayered[d]}, Grid[{{renderP[dd], Style[pretty[toExpression[dd]], 16, FontFamily -> "Times"],
     Style[Row[{pretty[source[dd]], "  \[RightArrow]  ", pretty[target[dd]]}], 12, GrayLevel[0.4]]}}, Spacings -> 3, Alignment -> {Left, Center}]];
showEq[ds_List] := Column[{Row[Riffle[render /@ ds, Style["  =  ", 20, FontFamily -> "Times"]]],
    Style[Row[Riffle[pretty[toExpression[fromLayered[#]]] & /@ ds, "   =   "]], 16, FontFamily -> "Times"]}, Spacings -> 1];
showEqP[ds_List] := Column[{Row[Riffle[renderP /@ ds, Style["  =  ", 20, FontFamily -> "Times"]]],
    Style[Row[Riffle[pretty[toExpression[fromLayered[#]]] & /@ ds, "   =   "]], 15, FontFamily -> "Times"]}, Spacings -> 1];
showTrace[steps_List, r_ : render] := Column[{
    Row[Flatten[{r[fromLayered[steps[[1, 2]]]], Table[{Column[{Style[steps[[k, 1]], 9, GrayLevel[0.35]], Style["\[LongRightArrow]", 22]}, Alignment -> Center], r[fromLayered[steps[[k, 2]]]]}, {k, 2, Length[steps]}]}], "  "],
    Style[Row[Riffle[pretty[toExpression[fromLayered[#[[2]]]]] & /@ steps, "   \[LongRightArrow]   "]], 14, FontFamily -> "Times"]}, Spacings -> 1];
showTraceP[steps_List] := showTrace[steps, renderP];
showPenrose[src_List, strips_List] := With[{ld = penroseLD[src, strips]}, If[ld === $Failed, $Failed,
    Grid[{{renderP[ld], Column[{Style[Row[{"source ", pretty[tensor[src]], "     target ", pretty[tensor[Last[rows[ld]]]]}], 13, FontFamily -> "Times"],
         Style[pretty[penroseExpr[strips]], 13, FontFamily -> "Times"]}, Spacings -> 1.2]}}, Spacings -> 3, Alignment -> {Left, Center}]]];

End[];
EndPackage[];
