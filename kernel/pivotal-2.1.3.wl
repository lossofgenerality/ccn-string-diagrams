(* ::Package:: *)
(* Penrose graphical calculus, §2.1.3 The case of pivotal categories (Turaev & Virelizier, pp. 33–35) *)
(* Sections 20–27 of graphical-calculus-2.1-simplify.nb. Needs the earlier sections (0–19) of that notebook to be evaluated first. *)


(* ::Section:: *)
(* 20. §2.1.3 The case of pivotal categories: the symbols *)

(* X*: the dual of X. In a pivotal category one object X* is at the same time the left and the right dual. *)
(* Orientation: every line now carries an arrow. A line coloured X and pointing down contributes X to the source or target. Pointing up, it contributes X*. So id_X* can be drawn as a line labelled X* pointing down, or as a line labelled X pointing up. *)
(* ev_X : X*⊗X → 𝟙 and ẽv_X : X⊗X* → 𝟙: the left and right evaluations, both non-degenerate pairings. They are drawn as caps. *)
(* coev_X : 𝟙 → X⊗X* and c̃oev_X : 𝟙 → X*⊗X: the left and right coevaluations, the inverses of those pairings. They are drawn as cups. *)
(* (1.12), (1.13), the duality identities (Figure 2.2): a cap followed by a cup straightens out. (id_X⊗ev_X)(coev_X⊗id_X) = id_X = (ẽv_X⊗id_X)(id_X⊗c̃oev_X), and (ev_X⊗id_X* )(id_X*⊗coev_X) = id_X* = (id_X*⊗ẽv_X)(c̃oev_X⊗id_X* ). *)
(* f* : Y* → X*: the dual morphism. Pivotality says its two expressions agree (Figure 2.3): (ev_Y⊗id_X* )(id_Y*⊗f⊗id_X* )(id_Y*⊗coev_X) = (id_X*⊗ẽv_Y)(id_X*⊗f⊗id_Y* )(c̃oev_X⊗id_Y* ). *)
(* The dual morphism identities (Figure 2.4): f* slides through any cap or cup and becomes f on the other leg. *)
(* ?*₂(X, Y) : X*⊗Y* → (Y⊗X)*: the monoidal constraint of the dual functor, with an inverse. Both are drawn with a box id_(Y⊗X) where the line Y⊗X splits into Y and X. *)

(* ::Section:: *)
(* 21. Code for the pivotal case *)

(* Colours are strings, and a trailing * marks the dual: "X*", "V*", "(Y⊗X)*". The book's notation is kept: ev, coev for the left pairing and OverTilde["ev"], OverTilde["coev"] for the right. renderP draws arrows on lines and draws ev, ẽv as caps and coev, c̃oev as cups. New rules are added for the duality identities, Figure 2.3 and Figure 2.4, and for removing identity boxes. *)

(* ---- colours and names ---- *)
starQ[s_] := StringQ[s] && StringLength[s] > 1 && StringEndsQ[s, "*"];
star[s_String] := If[StringContainsQ[s, "\[CircleTimes]"] && ! StringStartsQ[s, "("], "(" <> s <> ")*", s <> "*"];
unstar[s_String] := StringDrop[s, -1];
evL[x_] := Subscript["ev", x];  evR[x_] := Subscript[OverTilde["ev"], x];
coevL[x_] := Subscript["coev", x];  coevR[x_] := Subscript[OverTilde["coev"], x];

(* typesetting: X* as a superscript, tilde names upright *)
dispSym[s_String] := Which[
   s === unit, Style[s, Plain],
   starQ[s], Superscript[dispSym[unstar[s]], "*"],
   StringStartsQ[s, "("], s,
   StringStartsQ[s, "\[Or]"], Row[{Style["\[Or]", Smaller, Plain], Style[StringDrop[s, 1], Italic]}],
   StringStartsQ[s, "\[CapitalOmega]"], Style[s, Plain],
   True, Style[s, Italic]];
pretty[e_] := e /. {Subscript[a_, b_] :> dispSym[Subscript[a, b]], s_String :> dispSym[s]};

(* building layered diagrams with several pieces at once *)
besideL[a_LD, b_LD, c__LD] := besideL[besideL[a, b], c];
stackL[a_LD, b_LD, c__LD] := stackL[stackL[a, b], c];

(* ---- renderP: oriented lines, caps and cups ---- *)
$starLabels = False;          (* True: draw X* as a downward line labelled X*  *)
upQ[c_] := starQ[c] && ! $starLabels;
capQ[s_] := MatchQ[s, Subscript["ev" | OverTilde["ev"], _]];
cupQ[s_] := MatchQ[s, Subscript["coev" | OverTilde["coev"], _]];
head[{x_, y_}, dir_] := Polygon[({x, y} + 0.075 #) & /@ (dir /. {
      "up" -> {{-1, -0.8}, {1, -0.8}, {0, 0.9}}, "down" -> {{-1, 0.8}, {1, 0.8}, {0, -0.9}},
      "right" -> {{-0.8, -1}, {-0.8, 1}, {0.9, 0}}, "left" -> {{0.8, -1}, {0.8, 1}, {-0.9, 0}}})];
lineLabel[c_] := If[upQ[c], StringReplace[unstar[c], {"(" -> "", ")" -> ""}], c];

renderP[ld_LD] := renderP[fromLayered[ld]];
renderP[d : StringDiagram[bs_, ws_]] := Module[{lines, shapes, pts, xr, yr, legs},
   legs[n_, end_] := SortBy[Select[ws, If[end === "top", #[[4]] === BottomEdge[n], #[[3]] === TopEdge[n]] &], #[[2]] &];
   lines = Table[With[{x = w[[2]], y1 = endY[d, w[[3]]], y2 = endY[d, w[[4]]], left = Length[w] > 4},
      {Black, AbsoluteThickness[2.2], Line[{{x, y1}, {x, y2}}],
       head[{x, (y1 + y2)/2}, If[upQ[w[[1]]], "up", "down"]],
       Text[Style[dispSym[lineLabel[w[[1]]]], 12, FontFamily -> "Times"],
        {x + If[left, -0.13, 0.13], labelY[w, y1, y2]}, {If[left, 1, -1], 0}]}], {w, ws}];
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
       True,
       {EdgeForm[{Black, AbsoluteThickness[1.2]}], White,
        Rectangle[{b[[3, 1]], y - hgt/2}, {b[[3, 2]], y + hgt/2}], Black,
        Text[Style[dispSym[s], If[Head[s] === Subscript, 13, 15], FontFamily -> "Times"], {Mean[b[[3]]], y}]}]], {b, bs}];
   pts = Join[Flatten[Table[{{w[[2]], endY[d, w[[3]]]}, {w[[2]], endY[d, w[[4]]]}}, {w, ws}], 1],
     Flatten[Table[{{b[[3, 1]], b[[4]] - hgt/2}, {b[[3, 2]], b[[4]] + hgt/2}}, {b, bs}], 1]];
   {xr, yr} = CoordinateBounds[pts];
   yr = {Min[yr[[1]], -1], Max[yr[[2]], 1]};
   Graphics[{lines, shapes}, PlotRange -> {xr + {-0.5, 0.55}, yr + {-0.1, 0.1}},
    ImageSize -> 62 (xr[[2]] - xr[[1]] + 1.05), BaselinePosition -> Axis]];

showP[d_] := Grid[{{renderP[d], Style[pretty[toExpression[fromLayered[d]]], 16, FontFamily -> "Times"],
     Style[Row[{pretty[source[fromLayered[d]]], "  \[RightArrow]  ", pretty[target[fromLayered[d]]]}], 12, GrayLevel[0.4]]}},
   Spacings -> 3, Alignment -> {Left, Center}];
showEqP[ds_List] := Column[{Row[Riffle[renderP /@ ds, Style["  =  ", 20, FontFamily -> "Times"]]],
    Style[Row[Riffle[pretty[toExpression[fromLayered[#]]] & /@ ds, "   =   "]], 15, FontFamily -> "Times"]}, Spacings -> 1];
showTraceP[steps_] := Block[{render = renderP}, showTrace[steps]];

(* ---- rules for the pivotal case ---- *)
(* the right pairing ẽv_X has inverse c̃oev_X *)
pairQ[w_, o_] := MemberQ[pairings, {w, o}] ||
   MatchQ[{w, o}, {Subscript["ev", x_], Subscript["coev", x_]} | {Subscript[OverTilde["ev"], x_], Subscript[OverTilde["coev"], x_]}];
(* keep the ∨ fold for ∨-coloured lines only, so it does not fire on X* lines *)
ClearAll[foldDual];
foldDual[{a_, B[Subscript["coev", x_], {}, {x_, dx_?dualQ}]}, {a2_, B[f_String, {x_}, {y_}]},
    {a3_, B[Subscript["ev", y_], {dy_?dualQ, y_}, {}]}] /; a2 == a && a3 == a - 1 := {{a - 1, B["\[Or]" <> f, {dy}, {dx}]}};
foldDual[__] := $Failed;
(* do not split parenthesised colours such as (Y⊗X)* *)
splitMap[c_String] := If[StringContainsQ[c, "("], {c}, StringSplit[c, "\[CircleTimes]"]]; splitMap[c_] := {c};

(* Figure 2.3, read right to left: either composite folds into f* *)
starFoldL[{a_, B[Subscript["coev", x_], {}, {x_, xs_}]}, {a2_, B[f_String, {x_}, {y_}]},
    {a3_, B[Subscript["ev", y_], {ys_, y_}, {}]}] /; a2 == a && a3 == a - 1 && xs === star[x] && ys === star[y] :=
  {{a - 1, B[star[f], {ys}, {xs}]}};
starFoldL[__] := $Failed;
starFoldR[{a_, B[Subscript[OverTilde["coev"], x_], {}, {xs_, x_}]}, {a2_, B[f_String, {x_}, {y_}]},
    {a3_, B[Subscript[OverTilde["ev"], y_], {y_, ys_}, {}]}] /; a2 == a + 1 && a3 == a + 1 && xs === star[x] && ys === star[y] :=
  {{a, B[star[f], {ys}, {xs}]}};
starFoldR[__] := $Failed;

(* Figure 2.4: f* slides through a cap or a cup and becomes f *)
slideStarEv[{a_, B[fs_?starQ, {ys_}, {xs_}]}, {b_, B[Subscript["ev", x_], {xs_, x_}, {}]}] /; b == a :=
  With[{y = unstar[ys]}, {{a + 1, B[unstar[fs], {x}, {y}]}, {a, B[Subscript["ev", y], {ys, y}, {}]}}];
slideStarEv[__] := $Failed;
slideStarCoev[{a_, B[Subscript["coev", y_], {}, {y_, ys_}]}, {b_, B[fs_?starQ, {ys_}, {xs_}]}] /; b == a + 1 :=
  With[{x = unstar[xs]}, {{a, B[Subscript["coev", x], {}, {x, xs}]}, {a, B[unstar[fs], {x}, {y}]}}];
slideStarCoev[__] := $Failed;
slideStarEvR[{a1_, B[fs_?starQ, {ys_}, {xs_}]}, {b_, B[Subscript[OverTilde["ev"], x_], {x_, xs_}, {}]}] /; a1 == b + 1 :=
  With[{y = unstar[ys]}, {{b, B[unstar[fs], {x}, {y}]}, {b, B[Subscript[OverTilde["ev"], y], {y, ys}, {}]}}];
slideStarEvR[__] := $Failed;
slideStarCoevR[{a_, B[Subscript[OverTilde["coev"], y_], {}, {ys_, y_}]}, {b_, B[fs_?starQ, {ys_}, {xs_}]}] /; b == a :=
  With[{x = unstar[xs]}, {{a, B[Subscript[OverTilde["coev"], x], {}, {xs, x}]}, {a + 1, B[unstar[fs], {x}, {y}]}}];
slideStarCoevR[__] := $Failed;

(* an identity box whose inputs and outputs agree is just lines *)
idBox[{a_, B[Subscript["id", _], i_, o_]}] /; i === o := {};
idBox[_] := $Failed;

(* the engine gains one-box rules *)
try1[LD[src_, ls_], name_, r_] := Do[With[{rep = r[ls[[k]]]},
    If[rep =!= $Failed, Throw[{name, LD[src, Join[Take[ls, k - 1], rep, Drop[ls, k]]]}]]], {k, Length[ls]}];
rewriteOnce[ld_LD, rs_Association] := Catch[
   KeyValueMap[Function[{name, spec}, Switch[spec[[1]],
      "colour", With[{new = recolour[ld, spec[[2]]]}, If[new =!= ld, Throw[{name, new}]]],
      1, try1[ld, name, spec[[2]]],
      2, try2[ld, name, spec[[2]]],
      3, try3[ld, name, spec[[2]]]]], rs];
   $Failed];

rulesP = Join[rules, <|
    "identity boxes" -> {1, idBox},
    "Fig. 2.3 fold (left)" -> {3, starFoldL}, "Fig. 2.3 fold (right)" -> {3, starFoldR},
    "Fig. 2.4 slide through ev" -> {2, slideStarEv}, "Fig. 2.4 slide through coev" -> {2, slideStarCoev},
    "Fig. 2.4 slide through right ev" -> {2, slideStarEvR},
    "Fig. 2.4 slide through right coev" -> {2, slideStarCoevR}|>];

(* vector spaces: X = k², Y = k³; every ev, coev is the identity matrix flattened; f* = transpose of f *)
dimsP = <|"X" -> 2, "Y" -> 3, "X*" -> 2, "Y*" -> 3, "Y\[CircleTimes]X" -> 6, "(Y\[CircleTimes]X)*" -> 6|>;
pairMat[n_] := {Flatten[IdentityMatrix[n]]};
matsP = Join[<|"f" -> fM, "f*" -> Transpose[fM]|>,
   Association @@ Flatten[Table[With[{n = dimsP[c]}, {evL[c] -> pairMat[n], evR[c] -> pairMat[n],
       coevL[c] -> Transpose[pairMat[n]], coevR[c] -> Transpose[pairMat[n]]}], {c, {"X", "Y", "Y\[CircleTimes]X"}}]]];
matOf[d_] := toMatrix[toExpression[fromLayered[d]], dimsP, matsP];

(* ::Section:: *)
(* 22. Oriented lines *)

(* id_X* drawn both ways: a line labelled X* pointing down, or a line labelled X pointing up. They are the same morphism. *)

idXs = idL[{"X*"}];
Row[{tx[Subscript["id", Superscript["X", "*"]]], tx[" = "], Block[{$starLabels = True}, renderP[idXs]], tx["  =  "], renderP[idXs]}]
(* A morphism f : X*⊗Y → U⊗V*⊗W. The lines for X* and V* point up and carry the labels X and V. *)

fPiv = StringDiagram[{MBox["f", "f", {-0.3, 1.5}, 0]},
   {Strand["U", 0, TopEdge["f"], Loose[1]], Strand["V*", 0.6, TopEdge["f"], Loose[1]], Strand["W", 1.2, TopEdge["f"], Loose[1]],
    Strand["X*", 0.3, Loose[-1], BottomEdge["f"]], Strand["Y", 0.9, Loose[-1], BottomEdge["f"]]}];
showP[fPiv]

(* ::Section:: *)
(* 23. Caps and cups *)


capsCups = {boxL[evL["X"], {"X*", "X"}, {}], boxL[evR["X"], {"X", "X*"}, {}],
   boxL[coevL["X"], {}, {"X", "X*"}], boxL[coevR["X"], {}, {"X*", "X"}]};
Grid[{pretty /@ {evL["X"], evR["X"], coevL["X"], coevR["X"]}, renderP /@ capsCups,
   Style[Row[{pretty[source[fromLayered[#]]], " \[RightArrow] ", pretty[target[fromLayered[#]]]}], 11, GrayLevel[0.4]] & /@ capsCups},
  Spacings -> {4, 1}]

(* ::Section:: *)
(* 24. Figure 2.2: The duality identities (1.12), (1.13) *)

(* Each identity is built from layers, then simplify straightens it with a zigzag rule. The left pairing ev pairs with coev, and the right pairing ẽv with c̃oev. *)

d12a = stackL[besideL[boxL[coevL["X"], {}, {"X", "X*"}], idL[{"X"}]], besideL[idL[{"X"}], boxL[evL["X"], {"X*", "X"}, {}]]];
d12b = stackL[besideL[idL[{"X"}], boxL[coevR["X"], {}, {"X*", "X"}]], besideL[boxL[evR["X"], {"X", "X*"}, {}], idL[{"X"}]]];
d13a = stackL[besideL[idL[{"X*"}], boxL[coevL["X"], {}, {"X", "X*"}]], besideL[boxL[evL["X"], {"X*", "X"}, {}], idL[{"X*"}]]];
d13b = stackL[besideL[boxL[coevR["X"], {}, {"X*", "X"}], idL[{"X*"}]], besideL[idL[{"X*"}], boxL[evR["X"], {"X", "X*"}, {}]]];
Column[showTraceP[simplifyTrace[#, rulesP]] & /@ {d12a, d12b, d13a, d13b}, Spacings -> 3]

(* ::Section:: *)
(* 25. Figure 2.3: Two expressions for the dual morphism f* *)

(* The left expression uses ev_Y and coev_X, and the right one uses ẽv_Y and c̃oev_X. Both fold into the single box f* : Y* → X*. Pivotality is exactly the statement that the two agree. *)

fsL = stackL[besideL[idL[{"Y*"}], boxL[coevL["X"], {}, {"X", "X*"}]],
   besideL[idL[{"Y*"}], boxL["f", {"X"}, {"Y"}], idL[{"X*"}]], besideL[boxL[evL["Y"], {"Y*", "Y"}, {}], idL[{"X*"}]]];
fsR = stackL[besideL[boxL[coevR["X"], {}, {"X*", "X"}], idL[{"Y*"}]],
   besideL[idL[{"X*"}], boxL["f", {"X"}, {"Y"}], idL[{"Y*"}]], besideL[idL[{"X*"}], boxL[evR["Y"], {"Y", "Y*"}, {}]]];
fstarL = boxL["f*", {"Y*"}, {"X*"}];
Column[{showEqP[{fstarL, fsL, fsR}], showTraceP[simplifyTrace[fsL, rulesP]], showTraceP[simplifyTrace[fsR, rulesP]]}, Spacings -> 3]

(* ::Section:: *)
(* 26. Figure 2.4: The dual morphism identities *)

(* ev_X(f*⊗id_X) = ev_Y(id_Y*⊗f), (id_Y⊗f* )coev_Y = (f⊗id_X* )coev_X, ẽv_X(id_X⊗f* ) = ẽv_Y(f⊗id_Y* ), and (f*⊗id_Y)c̃oev_Y = (id_X*⊗f)c̃oev_X. The first line is (2.2) with ∨ replaced by *. *)

fS = boxL["f*", {"Y*"}, {"X*"}]; fP = boxL["f", {"X"}, {"Y"}];
fig24 = {
   {stackL[besideL[fS, idL[{"X"}]], boxL[evL["X"], {"X*", "X"}, {}]], stackL[besideL[idL[{"Y*"}], fP], boxL[evL["Y"], {"Y*", "Y"}, {}]]},
   {stackL[boxL[coevL["Y"], {}, {"Y", "Y*"}], besideL[idL[{"Y"}], fS]], stackL[boxL[coevL["X"], {}, {"X", "X*"}], besideL[fP, idL[{"X*"}]]]},
   {stackL[besideL[idL[{"X"}], fS], boxL[evR["X"], {"X", "X*"}, {}]], stackL[besideL[fP, idL[{"Y*"}]], boxL[evR["Y"], {"Y", "Y*"}, {}]]},
   {stackL[boxL[coevR["Y"], {}, {"Y*", "Y"}], besideL[fS, idL[{"Y"}]]], stackL[boxL[coevR["X"], {}, {"X*", "X"}], besideL[idL[{"X*"}], fP]]}};
Column[showTraceP[simplifyTrace[First[#], rulesP]] & /@ fig24, Spacings -> 3]

(* ::Section:: *)
(* 27. The monoidal constraint ?*₂(X, Y) and its inverse *)

(* The box id_(Y⊗X) marks where the line Y⊗X meets the two lines Y and X. These diagrams are drawn and evaluated in vector spaces. The simplifier does not reduce them, because their caps and cups are on the tensor-coloured line Y⊗X and its dual. The checks are: both pictures of ?*₂ agree, both pictures of its inverse agree, and the two composites are identities. *)

idYX[i_, o_] := B[Subscript["id", "Y\[CircleTimes]X"], i, o];
q2L = LD[{"X*", "Y*"}, {{2, B[coevL["Y\[CircleTimes]X"], {}, {"Y\[CircleTimes]X", "(Y\[CircleTimes]X)*"}]},
    {2, idYX[{"Y\[CircleTimes]X"}, {"Y", "X"}]}, {1, B[evL["Y"], {"Y*", "Y"}, {}]}, {0, B[evL["X"], {"X*", "X"}, {}]}}];
q2R = LD[{"X*", "Y*"}, {{0, B[coevR["Y\[CircleTimes]X"], {}, {"(Y\[CircleTimes]X)*", "Y\[CircleTimes]X"}]},
    {1, idYX[{"Y\[CircleTimes]X"}, {"Y", "X"}]}, {2, B[evR["X"], {"X", "X*"}, {}]}, {1, B[evR["Y"], {"Y", "Y*"}, {}]}}];
q2iL = LD[{"(Y\[CircleTimes]X)*"}, {{1, B[coevL["Y"], {}, {"Y", "Y*"}]}, {2, B[coevL["X"], {}, {"X", "X*"}]},
    {1, idYX[{"Y", "X"}, {"Y\[CircleTimes]X"}]}, {0, B[evL["Y\[CircleTimes]X"], {"(Y\[CircleTimes]X)*", "Y\[CircleTimes]X"}, {}]}}];
q2iR = LD[{"(Y\[CircleTimes]X)*"}, {{0, B[coevR["X"], {}, {"X*", "X"}]}, {1, B[coevR["Y"], {}, {"Y*", "Y"}]},
    {2, idYX[{"Y", "X"}, {"Y\[CircleTimes]X"}]}, {2, B[evR["Y\[CircleTimes]X"], {"Y\[CircleTimes]X", "(Y\[CircleTimes]X)*"}, {}]}}];
Column[{Row[{tx[Row[{"?", Subsuperscript["", "2", "*"], "(X,Y) = "}]], showEqP[{q2L, q2R}]}],
   Row[{tx[Row[{"(?", Subsuperscript["", "2", "*"], "(X,Y)", Superscript[")", "-1"], " = "}]], showEqP[{q2iL, q2iR}]}]}, Spacings -> 3]

With[{m = matOf /@ {q2L, q2R, q2iL, q2iR}},
 <|"both pictures of ?*\:2082 agree" -> m[[1]] == m[[2]], "both pictures of the inverse agree" -> m[[3]] == m[[4]],
  "inverse \[SmallCircle] ?*\:2082 = id" -> m[[3]] . m[[1]] == IdentityMatrix[6],
  "?*\:2082 \[SmallCircle] inverse = id" -> m[[1]] . m[[3]] == IdentityMatrix[6],
  "?*\:2082 is a permutation (it reorders X*\[CircleTimes]Y*)" -> (Sort[Flatten[m[[1]]]] == Join[ConstantArray[0, 30], ConstantArray[1, 6]])|>]

(* © Computational Classnotes · CC BY-NC-SA 4.0 *)
