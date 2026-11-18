(* ::Package:: *)
(* Penrose graphical calculus, §2.2 Penrose diagrams and associated morphisms (Turaev & Virelizier, pp. 36–38) *)
(* Sections 30–36. Needs sections 0–19 of graphical-calculus-2.1-simplify.nb and pivotal-2.1.3.wl (sections 20–27) evaluated first. *)


(* ::Section:: *)
(* 30. Caps and cups on tensor products *)

(* A strand coloured (Y⊗X)* is the strand coloured Y⊗X with its arrow turned round. Split into parallel strands it becomes X* ⊗ Y*, in that order: turning a pair of strands round reverses their order. A cap or cup on Y⊗X then becomes two nested caps or cups:
   ev_(Y⊗X) = ev_X (id_X* ⊗ ev_Y ⊗ id_X),   coev_(Y⊗X) = (id_Y ⊗ coev_X ⊗ id_Y* ) coev_Y,
   and the same for ẽv and c̃oev. Under this convention (Y⊗X)* is identified with X*⊗Y* through ?*₂(X, Y), which is then drawn as the identity. Inside a diagram whose free ends are not tensor-dual strands, the identification cancels out, so the morphism does not change. *)

tensorStarQ[c_String] := StringMatchQ[c, "(" ~~ __ ~~ ")*"] && StringContainsQ[c, "\[CircleTimes]"];
tensorStarQ[_] := False;
splitStarMap[c_String] /; tensorStarQ[c] := Reverse[star /@ StringSplit[StringTake[c, {2, -3}], "\[CircleTimes]"]];
splitStarMap[c_] := {c};

partsOf[x_String] := StringSplit[x, "\[CircleTimes]"];
joinParts[ps_List] := StringRiffle[ps, "\[CircleTimes]"];
dualList[ps_List] := Reverse[star /@ ps];

(* one-box rule: a cap or cup whose colour is a tensor product becomes a nested pair *)
nestCaps[{a_, B[Subscript["ev", x_String], i_, {}]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[i =!= Join[dualList[r], {star[p], p}, r], $Failed,
    {{a + Length[r], B[Subscript["ev", p], {star[p], p}, {}]}, {a, B[Subscript["ev", joinParts[r]], Join[dualList[r], r], {}]}}]];
nestCaps[{a_, B[Subscript["coev", x_String], {}, o_]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[o =!= Join[{p}, r, dualList[r], {star[p]}], $Failed,
    {{a, B[Subscript["coev", p], {}, {p, star[p]}]}, {a + 1, B[Subscript["coev", joinParts[r]], {}, Join[r, dualList[r]]]}}]];
nestCaps[{a_, B[Subscript[OverTilde["ev"], x_String], i_, {}]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[i =!= Join[{p}, r, dualList[r], {star[p]}], $Failed,
    {{a + 1, B[Subscript[OverTilde["ev"], joinParts[r]], Join[r, dualList[r]], {}]}, {a, B[Subscript[OverTilde["ev"], p], {p, star[p]}, {}]}}]];
nestCaps[{a_, B[Subscript[OverTilde["coev"], x_String], {}, o_]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[o =!= Join[dualList[r], {star[p], p}, r], $Failed,
    {{a, B[Subscript[OverTilde["coev"], joinParts[r]], {}, Join[dualList[r], r]]}, {a + Length[r], B[Subscript[OverTilde["coev"], p], {}, {star[p], p}]}}]];
nestCaps[_] := $Failed;

(* rulesT: rulesP with the two tensor rules, placed right after the colour rules *)
rulesT = Join[KeyTake[rulesP, {"unit strands", "\[CircleTimes]-coloured strands"}],
   <|"dual \[CircleTimes]-coloured strands" -> {"colour", splitStarMap}, "caps and cups on \[CircleTimes]" -> {1, nestCaps}|>,
   KeyDrop[rulesP, {"unit strands", "\[CircleTimes]-coloured strands"}]];
rulesTRightFirst = Join[KeyTake[rulesT, {"(2.1) right zigzag"}], rulesT];


(* ::Section:: *)
(* 31. §2.2.5 Exercise: ?*₂(X, Y) and its inverse are inverse to each other *)

(* q2L, q2R, q2iL, q2iR are the four pictures of section 27. Composed in either order, they simplify to an identity: the tensor rules split the Y⊗X strands, the identity box id_(Y⊗X) disappears, and two zigzags straighten. *)

ex225a = stackL[q2L, q2iL];      (* (?*₂)^-1 ∘ ?*₂ : X* ⊗ Y* → X* ⊗ Y*, left pictures *)
ex225b = stackL[q2R, q2iR];      (* the same with the right pictures *)
ex225c = stackL[q2iL, q2L];      (* ?*₂ ∘ (?*₂)^-1 : (Y⊗X)* → (Y⊗X)* *)
ex225d = stackL[q2iR, q2R];
ex225e = stackL[q2L, q2iR];      (* mixing the two pictures *)


(* ::Section:: *)
(* 32. §2.2.1 Signed objects *)

(* A signed object is a pair {X, "+"} or {X, "-"}; it determines X or X*. A tuple S of signed objects determines X_S, the tensor product of its entries, and X_∅ = 𝟙. A row of colours is read back as a tuple: "X" is (X, +) and "X*" is (X, −). *)

signedColour[{x_String, "+"}] := x;
signedColour[{x_String, "-"}] := star[x];
XS[s_List] := signedColour /@ s;                    (* the colours of X_S, left to right *)
XSobj[s_List] := tensor[XS[s]];                     (* X_S as an object; XSobj[{}] = 𝟙 *)
signsOf[cs_List] := If[starQ[#], {unstar[#], "-"}, {#, "+"}] & /@ cs;


(* ::Section:: *)
(* 33. §2.2.2–2.2.3 Penrose diagrams, strips and the associated morphism *)

(* A generic Penrose diagram is cut by horizontal lines into strips. Each strip is a list of pieces, left to right: seg[c] is a vertical segment (c = "X" for an X arc pointing down, c = "X*" for an X arc pointing up), and a box, cap or cup is B[symbol, ins, outs]. Strips are listed from the bottom to the top. penroseLD turns the strips into the layered form, so every tool of §2.1 applies; penroseExpr writes the associated morphism exactly as §2.2.3 does: the monoidal product of the pieces of each strip, composed from the bottom to the top. *)

seg[c_] := {"seg", c};
pieceIns[{"seg", c_}] := {c};  pieceIns[b_B] := ins[b];
pieceOuts[{"seg", c_}] := {c}; pieceOuts[b_B] := outs[b];
pieceMor[{"seg", c_}] := id[c]; pieceMor[b_B] := sym[b];

penroseLD::rows = "Strip `1` expects the lines `2`, but the strip below ends with `3`.";
penroseLD[src_List, strips_List] := Module[{row = src, ls = {}, k = 0},
   Catch[
    Do[k++;
     If[Flatten[pieceIns /@ strip] =!= row, Message[penroseLD::rows, k, Flatten[pieceIns /@ strip], row]; Throw[$Failed]];
     Module[{off = 0}, Do[If[Head[p] === B, AppendTo[ls, {off, p}]; off += Length[outs[p]], off += 1], {p, strip}]];
     row = Flatten[pieceOuts /@ strip], {strip, strips}];
    LD[src, ls]]];
penroseExpr[strips_List] := compose[Reverse[tensor[pieceMor /@ #] & /@ strips]];
penroseTarget[src_List, strips_List] := Last[rows[penroseLD[src, strips]]];

(* Figure 2.5, sliced into the five strips of page 37 *)
gB = B["g", {"X", "Z*"}, {"X", "V"}];       (* g : X ⊗ Z* → X ⊗ V *)
hB = B["h", {"A"}, {"Y*", "B"}];            (* h : A → Y* ⊗ B *)
kB = B["k", {}, {"Z*", "Y"}];               (* k : 𝟙 → Z* ⊗ Y *)
lB = B["l", {}, {}];                        (* l : 𝟙 → 𝟙 *)
evB[x_] := B[evL[x], {star[x], x}, {}];      evtB[x_] := B[evR[x], {x, star[x]}, {}];
coevB[x_] := B[coevL[x], {}, {x, star[x]}];  coevtB[x_] := B[coevR[x], {}, {star[x], x}];
fig25src = {"A*", "A"};
fig25 = {
   {seg["A*"], coevtB["X"], coevtB["X"], seg["A"]},
   {seg["A*"], seg["X*"], evtB["X"], seg["X"], kB, seg["A"]},
   {seg["A*"], evB["X"], coevtB["X"], seg["Z*"], seg["Y"], hB, lB},
   {coevB["U"], seg["A*"], seg["X*"], gB, evtB["Y"], seg["B"]},
   {seg["U"], seg["U*"], seg["A*"], evB["X"], seg["V"], seg["B"]}};
fig25LD = penroseLD[fig25src, fig25];

(* the formula printed on page 38, typed in as it stands *)
fig25book = SmallCircle[
   CircleTimes[id["U"], id["U*"], id["A*"], evL["X"], id["V"], id["B"]],
   CircleTimes[coevL["U"], id["A*"], id["X*"], "g", evR["Y"], id["B"]],
   CircleTimes[id["A*"], evL["X"], coevR["X"], id["Z*"], id["Y"], "h", "l"],
   CircleTimes[id["A*"], id["X*"], evR["X"], id["X"], "k", id["A"]],
   CircleTimes[id["A*"], coevR["X"], coevR["X"], id["A"]]];


(* ::Section:: *)
(* 34. §2.2.4 Lemma 2.1: the morphism does not depend on the slicing *)

(* Three other drawings of Figure 2.5:
   fig25up   pushes k down to the first strip and l up to the last one (transformation (iii));
   fig25flat straightens the zigzag in the X loop, so the loop is a plain circle c̃oev_X then ev_X (transformation (ii));
   fig25wide puts every piece in a strip of its own, the finest slicing (transformations (i) and (iii)).
   All four give the same morphism, both in vector spaces and by simplify. *)

fig25up = {
   {seg["A*"], coevtB["X"], coevtB["X"], kB, seg["A"]},
   {seg["A*"], seg["X*"], evtB["X"], seg["X"], seg["Z*"], seg["Y"], seg["A"]},
   {seg["A*"], evB["X"], coevtB["X"], seg["Z*"], seg["Y"], hB},
   {coevB["U"], seg["A*"], seg["X*"], gB, evtB["Y"], seg["B"]},
   {seg["U"], seg["U*"], seg["A*"], evB["X"], seg["V"], seg["B"], lB}};
fig25flat = {
   {seg["A*"], coevtB["X"], seg["A"]},
   {seg["A*"], seg["X*"], seg["X"], kB, seg["A"]},
   {seg["A*"], evB["X"], coevtB["X"], seg["Z*"], seg["Y"], hB, lB},
   {coevB["U"], seg["A*"], seg["X*"], gB, evtB["Y"], seg["B"]},
   {seg["U"], seg["U*"], seg["A*"], evB["X"], seg["V"], seg["B"]}};
fineStrips[src_, strips_] := Module[{ld = penroseLD[src, strips], rs},
   rs = Most[rows[ld]];
   MapThread[Function[{row, layer}, Join[seg /@ Take[row, layer[[1]]], {layer[[2]]}, seg /@ Drop[row, layer[[1]] + Length[ins[layer[[2]]]]]]], {rs, ld[[2]]}]];
fig25wide = fineStrips[fig25src, fig25];

(* vector spaces: every colour is k², ev and coev pair a basis with its dual basis, g, h, k, l are random *)
SeedRandom[2025];
dims22 = AssociationMap[2 &, Join[#, star /@ #] &[{"X", "Y", "Z", "U", "V", "A", "B"}]];
mats22 = Join[<|"g" -> RandomInteger[{-3, 3}, {4, 4}], "h" -> RandomInteger[{-3, 3}, {4, 2}],
    "k" -> RandomInteger[{-3, 3}, {4, 1}], "l" -> {{RandomInteger[{1, 5}]}}|>,
   Association @@ Flatten[Table[{evL[c] -> {vec[2]}, evR[c] -> {vec[2]}, coevL[c] -> Transpose[{vec[2]}], coevR[c] -> Transpose[{vec[2]}]},
      {c, {"X", "Y", "Z", "U", "V", "A", "B"}}]]];
mat22[ld_LD] := toMatrix[toExpression[fromLayered[ld]], dims22, mats22];
matExpr22[e_] := toMatrix[e, dims22, mats22];


(* ::Section:: *)
(* 35. Showing Penrose diagrams *)

showPenrose[src_List, strips_List] := With[{ld = penroseLD[src, strips]},
   Grid[{{renderP[ld],
      Column[{Style[Row[{Subscript["P", "\[Bullet]"], " = ", pretty[XSobj[signsOf[src]]], "     ",
           Superscript["P", "\[Bullet]"], " = ", pretty[XSobj[signsOf[Last[rows[ld]]]]]}], 13, FontFamily -> "Times"],
        Style[pretty[penroseExpr[strips]], 13, FontFamily -> "Times"]}, Spacings -> 1.2]}},
    Spacings -> 3, Alignment -> {Left, Center}]];

(* © Computational Classnotes · CC BY-NC-SA 4.0 *)
