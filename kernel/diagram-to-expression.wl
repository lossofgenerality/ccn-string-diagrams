(* ::Package:: *)
(* ::Title:: *)
(* DiagramToExpression: from boxes, lines and arrows to expressions *)
(* The Wolfram functions of CCN String Diagrams that turn a drawn string diagram into an algebraic expression,
   gathered in one self-contained package (it needs nothing else to be loaded).
   After Turaev & Virelizier, Monoidal Categories and Topological Field Theory, Chapter 2.
   By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0

   The manual is the notebook diagram-to-expression-manual.nb in the same folder.

   Representations (all diagrams read bottom to top, as in the book):
     StringDiagram[{MBox...}, {Strand...}]   a drawn diagram: boxes and lines with coordinates
     LD[src, {{a, B[symbol, ins, outs]}, ...}] the layered form: one box per layer
     {strip, strip, ...}                      a Penrose diagram cut into horizontal strips (§2.2.2)
     <|"src" -> ..., "ls" -> {...}|>          the JSON form the editor sends to the Wolfram kernel
     expression                               CircleTimes (⊗), SmallCircle (∘), Subscript["id", X], unit (𝟙)
   Arrows (orientation, §2.1.3) are carried by the colours: an arc coloured "X" points down, one coloured "X*" points up.

   Translators:
     toExpression[StringDiagram]   geometric slicing           (section 4 of the manual)
     toLayered[StringDiagram]      drawn diagram → layered form (section 5)
     fromLayered[LD]               layered form → drawn diagram (section 6)
     ldToExpression[LD]            layered form → expression, one box per slice (section 7)
     penroseLD, penroseExpr, penroseTarget   Penrose strips → layered form / expression (section 8)
     jsonToLD, ldToJSON, jsonToExpression, editorSymbol, editorName   the kernel's wire format (section 9)
     toEditorText[expr]            an expression as text the editor can read back (section 10)
     arrowOf, strandArrows         the direction of each arc (section 3) *)

BeginPackage["DiagramToExpression`"];

StringDiagram::usage = "StringDiagram[boxes, strands] is a drawn string diagram: a list of MBox[...] and a list of Strand[...]. Diagrams read bottom to top.";
MBox::usage = "MBox[name, symbol, {x1, x2}, y] is a box called name (a string used by strands to refer to it), labelled by the morphism symbol, spanning x1..x2 horizontally, with its centre at height y. A box is hgt = 0.5 tall.";
Strand::usage = "Strand[colour, x, lower, upper] is a vertical line of colour (an object, e.g. \"X\" or \"X*\") at horizontal position x, from the end lower to the end upper. Each end is Loose[y] (a free end at height y), TopEdge[name] (the top of box name: the strand leaves that box) or BottomEdge[name] (the bottom of box name: the strand enters that box).";
Loose::usage = "Loose[y] is a free end of a strand at height y: a source end (bottom) or a target end (top).";
TopEdge::usage = "TopEdge[name]: the strand starts at the top (output side) of the box called name.";
BottomEdge::usage = "BottomEdge[name]: the strand ends at the bottom (input side) of the box called name.";
LD::usage = "LD[src, layers] is the layered form of a diagram: src is the list of source colours, left to right; each layer {a, B[symbol, ins, outs]} is one box with a strands to its left. Layers are listed bottom to top.";
B::usage = "B[symbol, ins, outs] is a box with input colours ins (left to right) and output colours outs.";
unit::usage = "unit is the unit object 𝟙: tensor[{}] = unit; strands coloured unit are not drawn and are dropped by toExpression.";
hgt::usage = "hgt = 0.5, the height of a box in StringDiagram coordinates.";
tensor::usage = "tensor[{a, b, ...}] = a ⊗ b ⊗ ... (CircleTimes); tensor[{}] = unit and tensor[{a}] = a.";
compose::usage = "compose[{g, f}] = g ∘ f (SmallCircle), the first element applied last; compose[{f}] = f.";
id::usage = "id[c] = Subscript[\"id\", c], the identity of the colour c.";
ins::usage = "ins[B[s, i, o]] = i, the input colours.";
outs::usage = "outs[B[s, i, o]] = o, the output colours.";
sym::usage = "sym[B[s, i, o]] = s, the morphism symbol.";
rows::usage = "rows[LD[src, ls]] is the list of rows of colours: the source, then the colours after each layer.";
validQ::usage = "validQ[ld] is True when every layer of ld fits the strands below it (position in range, input colours matching).";
endY::usage = "endY[d, end] is the height of a strand end: y for Loose[y], the top or bottom of the box for TopEdge/BottomEdge.";
boxOf::usage = "boxOf[d, name] is the MBox of the StringDiagram d called name.";
toExpression::usage = "toExpression[StringDiagram[...]] reads a drawn diagram as an expression: it cuts the diagram at every height where a box sits, writes each slice as the ⊗ of its boxes and of the identities of the strands that pass through it, and composes the slices bottom to top.";
toLayered::usage = "toLayered[StringDiagram[...]] is the layered form LD[...] of a drawn diagram: the boxes in order of height (then of x), each with the number of strands to its left. toLayered[ld_LD] = ld.";
fromLayered::usage = "fromLayered[LD[...]] lays out a layered form as a StringDiagram: strands get horizontal positions from a topological sort, boxes get heights so that boxes that overlap horizontally, or are connected, are stacked. fromLayered[StringDiagram[...]] returns it unchanged.";
ldToExpression::usage = "ldToExpression[LD[...]] is the expression of a layered form without laying it out: one slice per layer, id ⊗ box ⊗ id, composed bottom to top.";
layeredExpression::usage = "layeredExpression[ld] = toExpression[fromLayered[ld]]: the expression the notebooks show for a layered form (boxes that fit side by side share a slice).";
seg::usage = "seg[c] is a vertical segment of colour c in a Penrose strip (§2.2.2): an identity piece.";
pieceIns::usage = "pieceIns[piece] is the list of input colours of a Penrose piece: {c} for seg[c], ins[b] for a box b.";
pieceOuts::usage = "pieceOuts[piece] is the list of output colours of a Penrose piece.";
pieceMor::usage = "pieceMor[piece] is the morphism of a Penrose piece: id[c] for seg[c], the symbol for a box.";
penroseLD::usage = "penroseLD[src, strips] is the layered form of a Penrose diagram given as horizontal strips, listed bottom to top; each strip is a list of pieces (seg[c] or B[...]). Each strip must start from the colours the previous strip ends with.";
penroseExpr::usage = "penroseExpr[strips] is the expression of a Penrose diagram: the ⊗ of the pieces of each strip, composed bottom to top, exactly as the book writes it (p. 38).";
penroseTarget::usage = "penroseTarget[src, strips] is the list of target colours of a Penrose diagram.";
editorSymbol::usage = "editorSymbol[name] turns the editor's name of a box (\"ev_X\", \"coev~_X\", \"τ_{X,Y}\", \"ψ⁻¹_X\", \"θˡ_X\", ...) into the Wolfram symbol (Subscript[\"ev\", \"X\"], ...). Other names stay strings.";
editorName::usage = "editorName[symbol] is the inverse of editorSymbol: the name the editor uses.";
jsonToLD::usage = "jsonToLD[<|\"src\" -> ..., \"ls\" -> {<|\"a\" -> a, \"name\" -> name, \"ins\" -> ..., \"outs\" -> ...|>, ...}|>] is the layered form of a diagram sent by the editor.";
ldToJSON::usage = "ldToJSON[ld] is the JSON form <|\"src\" -> ..., \"ls\" -> {{a, name, ins, outs}, ...}|> the kernel sends back to the editor.";
jsonToExpression::usage = "jsonToExpression[j] = ldToExpression[jsonToLD[j]].";
toEditorText::usage = "toEditorText[expr] writes an expression in the editor's syntax: composition by juxtaposition (g f = g ∘ f), ⊗, id_X, 𝟙, names as editorName gives them.";
arrowOf::usage = "arrowOf[colour] is \"down\" for an arc coloured X and \"up\" for X* (§2.1.3: an X arc points against the reading direction). An even number of stars points down again (X** = X); a colour written with ∨ (§2.1.2) points up.";
strandArrows::usage = "strandArrows[StringDiagram[...]] lists {colour, x, arrowOf[colour]} for every strand.";
fromLayered::invalid = "The layered form `1` does not fit together (a layer's position or input colours do not match the strands below it).";
penroseLD::rows = "Strip `1` starts from the colours `2`, but the strip below it ends with `3`.";

Begin["`Private`"];

(* ---------- section 2: the shared pieces ---------- *)
hgt = 0.5;
tensor[{}] := unit;
tensor[{a_}] := a;
tensor[l_List] := CircleTimes @@ l;
compose[{a_}] := a;
compose[l_List] := SmallCircle @@ l;
id[c_] := Subscript["id", c];
ins[B[_, i_, _]] := i;
outs[B[_, _, o_]] := o;
sym[B[s_, _, _]] := s;
stepRow[row_, {a_, b_B}] := Join[Take[row, a], outs[b], Drop[row, a + Length[ins[b]]]];
rows[LD[src_, ls_]] := FoldList[stepRow, src, ls];
validQ[ld : LD[_, ls_]] := Quiet[Check[TrueQ[And @@ MapThread[
       IntegerQ[#2[[1]]] && 0 <= #2[[1]] && #2[[1]] + Length[ins[#2[[2]]]] <= Length[#1] &&
         Take[#1, {#2[[1]] + 1, #2[[1]] + Length[ins[#2[[2]]]]}] === ins[#2[[2]]] &, {Most[rows[ld]], ls}]], False]];
validQ[_] := False;
boxOf[StringDiagram[bs_, _], n_] := SelectFirst[bs, First[#] === n &];
endY[d_, Loose[y_]] := y;
endY[d_, TopEdge[n_]] := boxOf[d, n][[4]] + hgt/2;
endY[d_, BottomEdge[n_]] := boxOf[d, n][[4]] - hgt/2;

(* ---------- section 3: arrows ---------- *)
arrowOf[c_String] := If[OddQ[StringLength[c] - StringLength[StringTrim[c, RegularExpression["\\*+$"]]]] || StringStartsQ[c, "\[Or]"], "up", "down"];   (* X** = X points down again *)
arrowOf[_] := "down";
strandArrows[StringDiagram[_, ws_]] := {#[[1]], #[[2]], arrowOf[#[[1]]]} & /@ ws;

(* ---------- section 4: toExpression ---------- *)
toExpression[d : StringDiagram[bs_, ws0_]] := Module[{ws, levels, slice},
   ws = Select[ws0, First[#] =!= unit &];                                         (* 𝟙-strands are not drawn *)
   If[bs === {}, Return[tensor[id /@ First /@ SortBy[ws, #[[2]] &]]]];            (* no boxes: identities, left to right *)
   levels = Union[#[[4]] & /@ bs];                                                 (* the heights of the boxes *)
   slice[y_] := tensor[Last /@ SortBy[Join[
        {#[[3, 1]], #[[2]]} & /@ Select[bs, #[[4]] == y &],                        (* boxes at height y, keyed by their left edge *)
        {#[[2]], id[#[[1]]]} & /@ Select[ws, endY[d, #[[3]]] < y < endY[d, #[[4]]] &]],   (* strands passing height y *)
       First]];
   compose[Reverse[slice /@ levels]]];                                             (* the lowest slice is applied first *)

(* ---------- section 5: toLayered ---------- *)
toLayered[ld_LD] := ld;
toLayered[d : StringDiagram[bs_, ws_]] := Module[{idx = Range[Length[ws]], xOf, row, layers = {}, inW, outW, a},
   xOf[i_] := ws[[i, 2]];
   row = SortBy[Select[idx, MatchQ[ws[[#, 3]], _Loose] &], xOf];                  (* the strands that start at the bottom *)
   Do[
    inW = SortBy[Select[idx, ws[[#, 4]] === BottomEdge[b[[1]]] &], xOf];          (* strands entering the box *)
    outW = SortBy[Select[idx, ws[[#, 3]] === TopEdge[b[[1]]] &], xOf];            (* strands leaving it *)
    a = If[inW === {}, Count[row, i_ /; xOf[i] < Mean[b[[3]]]], First[FirstPosition[row, First[inW]]] - 1];
    AppendTo[layers, {a, B[b[[2]], ws[[inW, 1]], ws[[outW, 1]]]}];
    row = Join[Take[row, a], outW, Drop[row, a + Length[inW]]],
    {b, SortBy[bs, {#[[4]], #[[3, 1]]} &]}];                                       (* boxes by height, then from the left *)
   LD[ws[[SortBy[Select[idx, MatchQ[ws[[#, 3]], _Loose] &], xOf], 1]], layers]];

(* ---------- section 6: fromLayered ---------- *)
fromLayered[StringDiagram[a___]] := StringDiagram[a];
fromLayered[ld : LD[src_, ls_]] /; validQ[ld] := Module[{cnt = 0, col = <||>, lower = <||>, upper = <||>, newW, row, rowsW, toks = {},
    edges, preds, xi = <||>, nb = Length[ls], ports, sp, rk = <||>, ys, ymin, ymax, w0},
   (* 1. strands: every arc segment gets a number, its colour, the layer it starts at and the layer it ends at *)
   newW[c_, lo_] := (cnt++; col[cnt] = c; lower[cnt] = lo; cnt);
   row = newW[#, "src"] & /@ src; rowsW = {row};
   Do[With[{a = ls[[k, 1]], b = ls[[k, 2]]}, Module[{inW = Take[row, {a + 1, a + Length[ins[b]]}], outW},
       Scan[(upper[#] = k) &, inW];
       If[ins[b] === {} && outs[b] === {}, AppendTo[toks, Join[Take[row, a], {tok[k]}, Drop[row, a]]]];   (* a box with no lines still needs a place *)
       outW = newW[#, k] & /@ outs[b];
       row = Join[Take[row, a], outW, Drop[row, a + Length[inW]]];
       AppendTo[rowsW, row]]], {k, nb}];
   (* 2. horizontal order: x is the longest chain of left neighbours, found by a topological sort *)
   edges = Union @@ (Partition[#, 2, 1] & /@ Join[rowsW, toks]);
   preds = GroupBy[edges, Last -> First];
   Do[xi[v] = Max[0, 1 + (xi /@ Lookup[preds, Key[v], {}])],
    {v, TopologicalSort[Graph[Join[Range[cnt], Cases[Flatten[toks], _tok]], DirectedEdge @@@ edges]]}];
   (* 3. the horizontal span of each box covers its ports *)
   ports[k_] := Select[Range[cnt], lower[#] === k || Lookup[upper, #, 0] === k &];
   Do[With[{xs = If[ports[k] === {}, {0.8 xi[tok[k]]}, 0.8 xi /@ ports[k]], s = sym[ls[[k, 2]]]},
     w0 = Which[Head[s] === Subscript, 0.5, StringQ[s] && StringLength[s] > 1, 0.32, True, 0.28];
     sp[k] = Mean[MinMax[xs]] + {-1, 1} Max[(Max[xs] - Min[xs])/2 + If[ports[k] === {}, 0.35, 0.28], w0]], {k, nb}];
   (* 4. heights: a box sits one above every earlier box it is connected to or overlaps horizontally *)
   Do[rk[k] = Max[0, 1 + (rk /@ Select[Range[k - 1], Function[j,
          MemberQ[lower /@ Select[Range[cnt], Lookup[upper, #, 0] === k &], j] || (sp[j][[1]] < sp[k][[2]] + 0.05 && sp[k][[1]] < sp[j][[2]] + 0.05)]])], {k, nb}];
   ys = Table[1. rk[k], {k, nb}];
   {ymin, ymax} = If[nb == 0, {-0.2, 0.2}, MinMax[ys]];
   (* 5. assemble: boxes b1, b2, ... and one strand per arc segment *)
   StringDiagram[
    Table[MBox["b" <> ToString[k], sym[ls[[k, 2]]], sp[k], ys[[k]]], {k, nb}],
    Table[Strand[col[w], 0.8 xi[w], If[lower[w] === "src", Loose[ymin - 0.8], TopEdge["b" <> ToString[lower[w]]]],
      If[KeyExistsQ[upper, w], BottomEdge["b" <> ToString[upper[w]]], Loose[ymax + 0.8]]], {w, cnt}]]];
fromLayered[ld_LD] := (Message[fromLayered::invalid, Short[ld]]; $Failed);

(* ---------- section 7: ldToExpression and layeredExpression ---------- *)
ldToExpression[ld : LD[src_, {}]] := tensor[id /@ DeleteCases[src, unit]];
ldToExpression[ld : LD[src_, ls_]] /; validQ[ld] := With[{rs = rows[ld]},
   compose[Reverse[Table[With[{a = ls[[k, 1]], b = ls[[k, 2]], r = rs[[k]]},
       tensor[Join[id /@ DeleteCases[Take[r, a], unit], {sym[b]}, id /@ DeleteCases[Drop[r, a + Length[ins[b]]], unit]]]], {k, Length[ls]}]]]];
ldToExpression[ld_LD] := (Message[fromLayered::invalid, Short[ld]]; $Failed);
layeredExpression[ld_LD] := With[{d = fromLayered[ld]}, If[d === $Failed, $Failed, toExpression[d]]];

(* ---------- section 8: Penrose strips (§2.2.2) ---------- *)
seg[c_] := {"seg", c};
pieceIns[{"seg", c_}] := {c};  pieceIns[b_B] := ins[b];
pieceOuts[{"seg", c_}] := {c}; pieceOuts[b_B] := outs[b];
pieceMor[{"seg", c_}] := id[c]; pieceMor[b_B] := sym[b];
penroseLD[src_List, strips_List] := Module[{row = src, ls = {}, k = 0},
   Catch[
    Do[k++;
     If[Flatten[pieceIns /@ strip] =!= row, Message[penroseLD::rows, k, Flatten[pieceIns /@ strip], row]; Throw[$Failed]];
     Module[{off = 0}, Do[If[Head[p] === B, AppendTo[ls, {off, p}]; off += Length[outs[p]], off += 1], {p, strip}]];
     row = Flatten[pieceOuts /@ strip], {strip, strips}];
    LD[src, ls]]];
penroseExpr[strips_List] := compose[Reverse[tensor[pieceMor /@ #] & /@ strips]];
penroseTarget[src_List, strips_List] := With[{ld = penroseLD[src, strips]}, If[ld === $Failed, $Failed, Last[rows[ld]]]];

(* ---------- section 9: the kernel's wire format ---------- *)
editorSymbol[s_String] := With[{m = StringCases[s, RegularExpression["^(ev|coev)(~?)_(.+)$"] -> {"$1", "$2", "$3"}]},
   Which[m =!= {}, Subscript[If[m[[1, 2]] === "~", OverTilde[m[[1, 1]]], m[[1, 1]]], StringTrim[m[[1, 3]], "{" | "}"]],
    StringStartsQ[s, "\[Tau]\:207b\:00b9_"], Subscript[Superscript["\[Tau]", "-1"], StringTrim[StringDrop[s, 4], "{" | "}"]],
    StringStartsQ[s, "\[Tau]_"], Subscript["\[Tau]", StringTrim[StringDrop[s, 2], "{" | "}"]],
    StringStartsQ[s, "\[Psi]\:207b\:00b9_"], Subscript[Superscript["\[Psi]", "-1"], StringTrim[StringDrop[s, 4], "{" | "}"]],
    StringStartsQ[s, "\[Psi]_"], Subscript["\[Psi]", StringTrim[StringDrop[s, 2], "{" | "}"]],
    StringMatchQ[s, RegularExpression["^\[Theta][\:02e1\:02b3](\:207b\:00b9)?_.+$"]],
     With[{k = First[StringPosition[s, "_"]][[1]]}, Subscript[StringTake[s, k - 1], StringTrim[StringDrop[s, k], "{" | "}"]]],
    True, s]];
editorName[Subscript["\[Tau]", x_String]] := "\[Tau]_{" <> x <> "}";
editorName[Subscript[Superscript["\[Tau]", "-1"], x_String]] := "\[Tau]\:207b\:00b9_{" <> x <> "}";
editorName[Subscript[Superscript["\[Psi]", "-1"], x_String]] := "\[Psi]\:207b\:00b9_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
editorName[Subscript[OverTilde[h_String], x_String]] := h <> "~_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
editorName[Subscript[h_String, x_String]] := h <> "_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
editorName[s_String] := s;
editorName[other_] := ToString[other, InputForm];
jsonToLD[j_Association] := LD[j["src"], {#["a"], B[editorSymbol[#["name"]], #["ins"], #["outs"]]} & /@ j["ls"]];
ldToJSON[LD[src_, ls_]] := <|"src" -> src, "ls" -> ({#[[1]], editorName[#[[2, 1]]], #[[2, 2]], #[[2, 3]]} & /@ ls)|>;
jsonToExpression[j_Association] := ldToExpression[jsonToLD[j]];

(* ---------- section 10: toEditorText ---------- *)
etObj[c_] := If[c === unit, "\[DoubleStruckOne]", c];
et[unit, _] := "id_\[DoubleStruckOne]";
et[Subscript["id", c_], _] := "id_" <> If[StringQ[c] && StringContainsQ[c, "\[CircleTimes]"], "{" <> c <> "}", ToString[etObj[c]]];
et[e_CircleTimes, ctx_] := With[{s = StringRiffle[et[#, "tens"] & /@ List @@ e, " \[CircleTimes] "]}, If[ctx === "top", s, "(" <> s <> ")"]];
(* composition is juxtaposition, first factor applied last; a space separates two plain names (g f), none is needed next to a bracket *)
et[e_SmallCircle, ctx_] := With[{parts = et[#, "comp"] & /@ List @@ e},
   With[{s = Fold[If[#1 === "", #2, #1 <> If[StringEndsQ[#1, ")"] || StringStartsQ[#2, "("], "", " "] <> #2] &, "", parts]},
    If[ctx === "tens", "(" <> s <> ")", s]]];
et[e_CircleTimes, "comp"] := "(" <> StringRiffle[et[#, "tens"] & /@ List @@ e, " \[CircleTimes] "] <> ")";
et[s_, _] := editorName[s];
toEditorText[e_] := et[e, "top"];

End[];
EndPackage[];
