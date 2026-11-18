(* ::Package:: *)
(* Penrose graphical calculus, §2.3–2.7: double duals, generalized evaluations, isotopy invariance, pivotal structures, traces and dimensions, spherical categories (Turaev & Virelizier, pp. 38–50) *)
(* Sections 40–48. Needs sections 0–19 of graphical-calculus-2.1-simplify.nb, pivotal-2.1.3.wl (sections 20–27) and penrose-2.2.wl (sections 30–35) evaluated first; all live in Desktop/Research/Monoidal Graphical Calculus. *)


(* ::Section:: *)
(* 40. §2.3.1 The double duals: ψ_X and the rules of Lemmas 2.2–2.3 *)

(* X** = (X* )* is its own object, written "X**". An arc coloured X* and pointing up contributes X** to a source or target.
   ψ_X : X → X** is (ẽv_X ⊗ id_X** )(id_X ⊗ coev_X* ). It is drawn as a box ψ_X, and its inverse as a box ψ⁻¹_X.
   Lemma 2.3 rewrites a cap or cup coloured X* as a cap or cup coloured X with ψ^{±1} on the X** leg:
     ev_X*  = ẽv_X (ψ⁻¹_X ⊗ id_X* ),      ẽv_X*  = ev_X (id_X* ⊗ ψ⁻¹_X),
     coev_X* = (id_X* ⊗ ψ_X) c̃oev_X,     c̃oev_X* = (ψ_X ⊗ id_X* ) coev_X.
   With "inverse boxes" (ψ⁻¹ψ = id, ψψ⁻¹ = id) these rules decide Lemma 2.2, Lemma 2.3, Lemma 2.4 and Exercise 2.3.3.
   When an input already identifies X** with X (as the editor does), the strict forms apply: ev_X* = ẽv_X and ψ_X = id_X. *)

psi[x_] := Subscript["\[Psi]", x];
psiInv[x_] := Subscript[Superscript["\[Psi]", "-1"], x];
psiB[x_] := B[psi[x], {x}, {star[star[x]]}];
psiInvB[x_] := B[psiInv[x], {star[star[x]]}, {x}];

(* Lemma 2.3, one cap or cup at a time *)
lemma23[{a_, B[Subscript["ev", c_?starQ], {cc_, c_}, {}]}] /; cc === star[c] :=
  With[{x = unstar[c]}, {{a, psiInvB[x]}, {a, B[evR[x], {x, c}, {}]}}];
lemma23[{a_, B[Subscript[OverTilde["ev"], c_?starQ], {c_, cc_}, {}]}] /; cc === star[c] :=
  With[{x = unstar[c]}, {{a + 1, psiInvB[x]}, {a, B[evL[x], {c, x}, {}]}}];
lemma23[{a_, B[Subscript["coev", c_?starQ], {}, {c_, cc_}]}] /; cc === star[c] :=
  With[{x = unstar[c]}, {{a, B[coevR[x], {}, {c, x}]}, {a + 1, psiB[x]}}];
lemma23[{a_, B[Subscript[OverTilde["coev"], c_?starQ], {}, {cc_, c_}]}] /; cc === star[c] :=
  With[{x = unstar[c]}, {{a, B[coevL[x], {}, {x, c}]}, {a, psiB[x]}}];
lemma23[_] := $Failed;

(* the strict forms, X** = X and ψ_X = id_X, for inputs written that way *)
lemma23strict[{a_, B[Subscript["ev", c_?starQ], {x_, c_}, {}]}] /; x === unstar[c] := {{a, B[evR[x], {x, c}, {}]}};
lemma23strict[{a_, B[Subscript[OverTilde["ev"], c_?starQ], {c_, x_}, {}]}] /; x === unstar[c] := {{a, B[evL[x], {c, x}, {}]}};
lemma23strict[{a_, B[Subscript["coev", c_?starQ], {}, {c_, x_}]}] /; x === unstar[c] := {{a, B[coevR[x], {}, {c, x}]}};
lemma23strict[{a_, B[Subscript[OverTilde["coev"], c_?starQ], {}, {x_, c_}]}] /; x === unstar[c] := {{a, B[coevL[x], {}, {x, c}]}};
lemma23strict[_] := $Failed;
psiStrict[{_, B[Subscript["\[Psi]" | Superscript["\[Psi]", "-1"], x_], {x_}, {x_}]}] := {};
psiStrict[_] := $Failed;

(* caps and cups on ⊗ for inputs with X** = X: the same nests, with the dual of X* written X *)
flipC[c_String] := If[starQ[c], unstar[c], star[c]];
flipList[ps_List] := Reverse[flipC /@ ps];
nestCapsStrict[{a_, B[Subscript["ev", x_String], i_, {}]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[i =!= Join[flipList[r], {flipC[p], p}, r], $Failed,
    {{a + Length[r], B[Subscript["ev", p], {flipC[p], p}, {}]}, {a, B[Subscript["ev", joinParts[r]], Join[flipList[r], r], {}]}}]];
nestCapsStrict[{a_, B[Subscript["coev", x_String], {}, o_]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[o =!= Join[{p}, r, flipList[r], {flipC[p]}], $Failed,
    {{a, B[Subscript["coev", p], {}, {p, flipC[p]}]}, {a + 1, B[Subscript["coev", joinParts[r]], {}, Join[r, flipList[r]]]}}]];
nestCapsStrict[{a_, B[Subscript[OverTilde["ev"], x_String], i_, {}]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[i =!= Join[{p}, r, flipList[r], {flipC[p]}], $Failed,
    {{a + 1, B[Subscript[OverTilde["ev"], joinParts[r]], Join[r, flipList[r]], {}]}, {a, B[Subscript[OverTilde["ev"], p], {p, flipC[p]}, {}]}}]];
nestCapsStrict[{a_, B[Subscript[OverTilde["coev"], x_String], {}, o_]}] /; Length[partsOf[x]] > 1 :=
  With[{p = First[partsOf[x]], r = Rest[partsOf[x]]},
   If[o =!= Join[flipList[r], {flipC[p], p}, r], $Failed,
    {{a, B[Subscript[OverTilde["coev"], joinParts[r]], {}, Join[flipList[r], r]]}, {a + Length[r], B[Subscript[OverTilde["coev"], p], {}, {flipC[p], p}]}}]];
nestCapsStrict[_] := $Failed;
nestCapsD[l_] := With[{r = nestCaps[l]}, If[r =!= $Failed, r, nestCapsStrict[l]]];

(* inverse boxes: u⁻¹ directly above u on the same line, or u above u⁻¹, cancel *)
inverses = {};                                   (* declared pairs {u, u⁻¹} *)
invQ[s1_, s2_] := MemberQ[inverses, {s1, s2} | {s2, s1}] ||
   MatchQ[{s1, s2}, {Subscript["\[Psi]", x_], Subscript[Superscript["\[Psi]", "-1"], x_]} | {Subscript[Superscript["\[Psi]", "-1"], x_], Subscript["\[Psi]", x_]}];
cancelInv[{a_, B[s1_, {c_}, {d_}]}, {a_, B[s2_, {d_}, {c_}]}] /; invQ[s1, s2] := {};
cancelInv[__] := $Failed;

(* naturality of ψ (§2.5.1): f** ψ_X = ψ_Y f, for a box f : X → Y *)
natPsi[{a_, B[Subscript["\[Psi]", x_], {x_}, {xx_}]}, {a_, B[g_String, {xx_}, {yy_}]}] /;
   StringEndsQ[g, "**"] && yy === star[star[unstar[unstar[yy]]]] && StringEndsQ[yy, "**"] :=
  With[{y = StringDrop[yy, -2]}, {{a, B[StringDrop[g, -2], {x}, {y}]}, {a, B[psi[y], {y}, {yy}]}}];
natPsi[__] := $Failed;

(* the four constructions of Lemma 2.2, as layered diagrams *)
psiDef[x_] := LD[{x}, {{1, B[coevL[star[x]], {}, {star[x], star[star[x]]}]}, {0, B[evR[x], {x, star[x]}, {}]}}];      (* ψ_X *)
phiDef[x_] := LD[{x}, {{0, B[coevR[star[x]], {}, {star[star[x]], star[x]}]}, {1, B[evL[x], {star[x], x}, {}]}}];      (* φ_X *)
thetaDef[x_] := LD[{star[star[x]]}, {{0, B[coevL[x], {}, {x, star[x]}]}, {1, B[evR[star[x]], {star[x], star[star[x]]}, {}]}}];   (* ϑ_X *)
nuDef[x_] := LD[{star[star[x]]}, {{1, B[coevR[x], {}, {star[x], x}]}, {0, B[evL[star[x]], {star[star[x]], star[x]}, {}]}}];     (* ν_X *)


(* ::Section:: *)
(* 41. §2.3.2 Generalized evaluations ev_S, coev_S and the isomorphisms Ψ_S *)

(* A tuple S of signed objects {X, "+"} or {X, "-"} (section 32) has a dual tuple S* = ((X_n, −ε_n), …, (X_1, −ε_1)).
   ev_S : X_S* ⊗ X_S → 𝟙 is a nest of caps, the innermost on X_1: ev_(X,+) = ev_X and ev_(X,−) = ẽv_X.
   coev_S : 𝟙 → X_S ⊗ X_S* is a nest of cups: coev_(X,+) = coev_X and coev_(X,−) = c̃oev_X.
   Ψ_S : X_S → (X_S* )* is ψ_X on every (X,+) entry and id_X* on every (X,−) entry; the target is written strand by strand, which is how the tensor rules of section 30 read (X_S* )*. *)

dualTuple[s_List] := Reverse[{#[[1]], If[#[[2]] === "+", "-", "+"]} & /@ s];
capOf[{x_, "+"}] := B[evL[x], {star[x], x}, {}];
capOf[{x_, "-"}] := B[evR[x], {x, star[x]}, {}];
cupOf[{x_, "+"}] := B[coevL[x], {}, {x, star[x]}];
cupOf[{x_, "-"}] := B[coevR[x], {}, {star[x], x}];
evS[s_List] := With[{n = Length[s]}, LD[Join[XS[dualTuple[s]], XS[s]], Table[{n - k, capOf[s[[k]]]}, {k, n}]]];
coevS[s_List] := LD[{}, Table[{k - 1, cupOf[s[[k]]]}, {k, Length[s]}]];
PsiS[s_List] := LD[XS[s], Flatten[MapIndexed[If[#1[[2]] === "+", {{#2[[1]] - 1, psiB[#1[[1]]]}}, {}] &, s], 1]];
PsiInvS[s_List] := LD[Last[rows[PsiS[s]]], Flatten[MapIndexed[If[#1[[2]] === "+", {{#2[[1]] - 1, psiInvB[#1[[1]]]}}, {}] &, s], 1]];
(* the tensor-coloured caps and cups of section 30, on X_S *)
evXS[s_List] := With[{c = XS[s]}, LD[Join[dualList[c], c], {{0, B[evL[joinParts[c]], Join[dualList[c], c], {}]}}]];
coevXS[s_List] := With[{c = XS[s]}, LD[{}, {{0, B[coevL[joinParts[c]], {}, Join[c, dualList[c]]]}}]];
evRXS[s_List] := With[{c = XS[s]}, LD[Join[c, dualList[c]], {{0, B[evR[joinParts[c]], Join[c, dualList[c]], {}]}}]];
coevRXS[s_List] := With[{c = XS[s]}, LD[{}, {{0, B[coevR[joinParts[c]], {}, Join[dualList[c], c]]}}]];


(* ::Section:: *)
(* 42. §2.4 Isotopy invariance: the dual of a diagram, and a box turned through 360° *)

(* dualLD[d] is the left expression of Figure 2.3 wrapped round any diagram d : S → T: the cup coev_S on the right, d in the middle, the cap ev_T on the left. It represents d* : T* → S*.
   Applied twice it turns the diagram through 360°: Lemma 2.5 and the naturality of ψ (§2.5.1) say that Ψ_T⁻¹ d** Ψ_S = d. *)

dualLD[ld_LD] := Module[{s = First[rows[ld]], t = Last[rows[ld]], n},
   n = Length[t];
   LD[dualList[t],
    Join[If[s === {}, {}, {{n, B[If[Length[s] == 1, coevL[First[s]], coevL[joinParts[s]]], {}, Join[s, dualList[s]]]}}],
     {#[[1]] + n, #[[2]]} & /@ ld[[2]],
     If[t === {}, {}, {{0, B[If[Length[t] == 1, evL[First[t]], evL[joinParts[t]]], Join[dualList[t], t], {}]}}]]]];
psiRow[cs_List] := LD[cs, Table[{k - 1, psiB[cs[[k]]]}, {k, Length[cs]}]];
psiInvRow[cs_List] := LD[star /@ (star /@ cs), Table[{k - 1, psiInvB[cs[[k]]]}, {k, Length[cs]}]];
rotate360[ld_LD] := stackL[psiRow[First[rows[ld]]], dualLD[dualLD[ld]], psiInvRow[Last[rows[ld]]]];


(* ::Section:: *)
(* 43. §2.6 Traces and dimensions *)

(* tr_l(f) = ev_X (id_X* ⊗ f) c̃oev_X and tr_r(f) = ẽv_X (f ⊗ id_X* ) coev_X, for f : X → X given as a layered diagram.
   dim_l(X) = tr_l(id_X) = ev_X c̃oev_X and dim_r(X) = tr_r(id_X) = ẽv_X coev_X.
   "trace symmetry" turns a loop so that the boxes on it start at the earliest one in a fixed order. With the slides of Figure 2.4, which move f* off the other leg, it decides tr(pq) = tr(qp) and the identities of §2.6.1.
   "sphericity" (§2.7.1) is used only for spherical categories: it turns a right loop ẽv_X (f ⊗ id) coev_X into the left loop ev_X (id ⊗ f) c̃oev_X. *)

loopColour[cs_List] := If[Length[cs] == 1, First[cs], joinParts[cs]];
trL[f_LD] := With[{c = First[rows[f]], n = Length[First[rows[f]]]},
   LD[{}, Join[{{0, B[coevR[loopColour[c]], {}, Join[dualList[c], c]]}}, {#[[1]] + n, #[[2]]} & /@ f[[2]],
     {{0, B[evL[loopColour[c]], Join[dualList[c], c], {}]}}]]];
trR[f_LD] := With[{c = First[rows[f]]},
   LD[{}, Join[{{0, B[coevL[loopColour[c]], {}, Join[c, dualList[c]]]}}, f[[2]],
     {{0, B[evR[loopColour[c]], Join[c, dualList[c]], {}]}}]]];
dimL[x_] := trL[idL[{x}]];
dimR[x_] := trR[idL[{x}]];

(* a loop: a cup at a, a chain of one-line boxes on one leg, a cap at a, in consecutive layers *)
loopAt[ls_, i_] := Module[{a, b, j, side, chain},
   If[! MatchQ[ls[[i]], {_, B[Subscript["coev" | OverTilde["coev"], _], {}, {_, _}]}], Return[$Failed]];
   {a, b} = ls[[i]]; side = If[MatchQ[b, B[Subscript[OverTilde["coev"], _], __]], a + 1, a];   (* left loop: chain on the right leg *)
   j = i + 1; chain = {};
   While[j <= Length[ls] && MatchQ[ls[[j]], {side, B[_, {_}, {_}]}] && ! MatchQ[ls[[j, 2, 1]], Subscript["coev" | OverTilde["coev"] | "ev" | OverTilde["ev"], _]],
    AppendTo[chain, ls[[j, 2]]]; j++];
   If[j <= Length[ls] && MatchQ[ls[[j]], {a, B[Subscript[If[side == a + 1, "ev", OverTilde["ev"]], _], {_, _}, {}]}],
    {i, j, a, If[side == a + 1, "left", "right"], chain}, $Failed]];
loopLayers[a_, "left", chain_] := With[{x = First[ins[First[chain]]]},
   Join[{{a, B[coevR[x], {}, {star[x], x}]}}, {a + 1, #} & /@ chain, {{a, B[evL[x], {star[x], x}, {}]}}]];
loopLayers[a_, "right", chain_] := With[{x = First[ins[First[chain]]]},
   Join[{{a, B[coevL[x], {}, {x, star[x]}]}}, {a, #} & /@ chain, {{a, B[evR[x], {x, star[x]}, {}]}}]];
(* the order of rotations: box names joined by "|" and compared code point by code point, as the editor does *)
nameStr[s_String] := s; nameStr[s_] := ToString[s, InputForm];
chainKey[ch_] := StringRiffle[nameStr /@ (sym /@ ch), "|"];
cpLess[k1_String, k2_String] := Module[{x = ToCharacterCode[k1, "Unicode"], y = ToCharacterCode[k2, "Unicode"], i = 1},
   While[i <= Min[Length[x], Length[y]] && x[[i]] == y[[i]], i++];
   If[i > Min[Length[x], Length[y]], Length[x] < Length[y], x[[i]] < y[[i]]]];
minRotation[ch_List] := Fold[If[cpLess[chainKey[#2], chainKey[#1]], #2, #1] &, ch, Table[RotateLeft[ch, r], {r, 1, Length[ch] - 1}]];
traceTurn[LD[src_, ls_]] := Catch[Do[With[{lp = loopAt[ls, i]},
     If[lp =!= $Failed && Length[lp[[5]]] > 1,
      With[{best = minRotation[lp[[5]]]},
       If[best =!= lp[[5]], Throw[LD[src, Join[Take[ls, lp[[1]] - 1], loopLayers[lp[[3]], lp[[4]], best], Drop[ls, lp[[2]]]]]]]]]],
    {i, Length[ls]}]; $Failed];
sphericity[LD[src_, ls_]] := Catch[Do[With[{lp = loopAt[ls, i]},
     If[lp =!= $Failed && lp[[4]] === "right",
      Throw[LD[src, Join[Take[ls, lp[[1]] - 1],
         If[lp[[5]] === {}, With[{x = unstar[ins[ls[[lp[[2]], 2]]][[2]]]}, {{lp[[3]], B[coevR[x], {}, {star[x], x}]}, {lp[[3]], B[evL[x], {star[x], x}, {}]}}],
          loopLayers[lp[[3]], "left", lp[[5]]]], Drop[ls, lp[[2]]]]]]]], {i, Length[ls]}]; $Failed];
(* loopAt needs a chain to name the colour of an empty right loop; handle it here *)
sphericity0[LD[src_, ls_]] := Catch[Do[If[k < Length[ls] &&
      MatchQ[ls[[k]], {a_, B[Subscript["coev", x_], {}, {x_, _}]}] && MatchQ[ls[[k + 1]], {ls[[k, 1]], B[Subscript[OverTilde["ev"], ls[[k, 2, 1, 2]]], _, {}]}],
     With[{a = ls[[k, 1]], x = ls[[k, 2, 1, 2]]},
      Throw[LD[src, Join[Take[ls, k - 1], {{a, B[coevR[x], {}, {star[x], x}]}, {a, B[evL[x], {star[x], x}, {}]}}, Drop[ls, k + 1]]]]]], {k, Length[ls]}]; $Failed];
sphericityAll[ld_LD] := With[{r = sphericity0[ld]}, If[r =!= $Failed, r, sphericity[ld]]];

(* whole-diagram rules: rewriteOnce gains the kind "ld" *)
rewriteOnce[ld_LD, rs_Association] := Catch[
   KeyValueMap[Function[{name, spec}, Switch[spec[[1]],
      "colour", With[{new = recolour[ld, spec[[2]]]}, If[new =!= ld, Throw[{name, new}]]],
      1, try1[ld, name, spec[[2]]],
      2, try2[ld, name, spec[[2]]],
      3, try3[ld, name, spec[[2]]],
      "ld", With[{new = spec[[2]][ld]}, If[new =!= $Failed, Throw[{name, new}]]]]], rs];
   $Failed];


(* ::Section:: *)
(* 44. The rule sets rulesD (pivotal) and rulesS (spherical) *)

rulesD = Join[rulesT, <|
    "Lemma 2.3 (X** = X)" -> {1, lemma23strict},
    "\[Psi] = id (X** = X)" -> {1, psiStrict},
    "trace symmetry (\[Section]2.6.1)" -> {"ld", traceTurn},
    "inverse boxes" -> {2, cancelInv},
    "naturality of \[Psi] (\[Section]2.5.1)" -> {2, natPsi},
    "Lemma 2.3" -> {1, lemma23}|>];
rulesD["caps and cups on \[CircleTimes]"] = {1, nestCapsD};
rulesS = Join[rulesD, <|"sphericity (\[Section]2.7.1)" -> {"ld", sphericityAll}|>];


(* ::Section:: *)
(* 45. A matrix model: the pivotal category of weighted vector spaces (Example 2.7.2) *)

(* Each colour X is k^n with a weight w(X) ≠ 0; w(X* ) = 1/w(X), and weights multiply over ⊗. ev and coev are the usual pairing with the dual basis; ẽv_X is w(X) times it and c̃oev_X is 1/w(X) times it, so all four duality identities hold. A box must keep the weight (w(source) = w(target)); then f* = fᵀ by either expression of Figure 2.3, so the category is pivotal. In it ψ_X = w(X)·id, dim_l(X) = n/w(X) and dim_r(X) = n·w(X). It is spherical exactly when every weight is ±1: this is Example 2.7.2 with d = w, made into vector spaces.
   matW[ld, n, w, mats] multiplies the layers directly: n and w are functions of a base colour, mats gives the matrices of named boxes. *)

baseOf[c_String] := StringReplace[c, {"*" -> "", "(" -> "", ")" -> ""}];
starDepth[c_String] := StringCount[c, "*"];
wOf[c_String, w_] := Which[
   StringStartsQ[c, "("], 1/wOf[StringTake[c, {2, -3}], w],
   StringContainsQ[c, "\[CircleTimes]"], Times @@ (wOf[#, w] & /@ StringSplit[c, "\[CircleTimes]"]),
   starQ[c], 1/wOf[unstar[c], w], True, w[c]];
nOf[c_String, n_] := Which[StringContainsQ[c, "\[CircleTimes]"], Times @@ (nOf[#, n] & /@ StringSplit[baseOf[c], "\[CircleTimes]"]), True, n[baseOf[c]]];
pairVec[k_] := Flatten[IdentityMatrix[k]];
matBox[b_B, n_, w_, mats_] := Module[{s = sym[b], i = ins[b], o = outs[b], c},
   Which[
    MatchQ[s, Subscript["id", _]], IdentityMatrix[Times @@ (nOf[#, n] & /@ i)],
    MatchQ[s, Subscript["ev" | OverTilde["ev"] | "coev" | OverTilde["coev"], _]] && StringContainsQ[s[[2]], "\[CircleTimes]"],
     matW[LD[i, nestCaps[{0, b}]], n, w, mats],                                                  (* a nest of caps or cups *)
    MatchQ[s, Subscript["ev", _]], {pairVec[nOf[s[[2]], n]]},
    MatchQ[s, Subscript[OverTilde["ev"], _]], wOf[s[[2]], w] {pairVec[nOf[s[[2]], n]]},
    MatchQ[s, Subscript["coev", _]], Transpose[{pairVec[nOf[s[[2]], n]]}],
    MatchQ[s, Subscript[OverTilde["coev"], _]], Transpose[{pairVec[nOf[s[[2]], n]]}]/wOf[s[[2]], w],
    MatchQ[s, Subscript["\[Psi]", _]], wOf[s[[2]], w] IdentityMatrix[nOf[s[[2]], n]],
    MatchQ[s, Subscript[Superscript["\[Psi]", "-1"], _]], IdentityMatrix[nOf[s[[2]], n]]/wOf[s[[2]], w],
    StringQ[s] && KeyExistsQ[mats, s], mats[s],
    StringQ[s] && StringEndsQ[s, "*"], Transpose[matBox[B[StringDrop[s, -1], o, i], n, w, mats]],
    True, mats[s]]];
matW[ld_LD, n_, w_, mats_] := Module[{rs = rows[ld], m},
   m = IdentityMatrix[Times @@ (nOf[#, n] & /@ First[rs])];
   Do[With[{a = ld[[2, k, 1]], b = ld[[2, k, 2]], row = rs[[k]]},
     m = KroneckerProduct[IdentityMatrix[Times @@ (nOf[#, n] & /@ Take[row, a])], matBox[b, n, w, mats],
         IdentityMatrix[Times @@ (nOf[#, n] & /@ Drop[row, a + Length[ins[b]]])]] . m], {k, Length[ld[[2]]]}];
   m];


(* ::Section:: *)
(* 46. The constructions of pp. 38–50, as layered diagrams *)

SeedRandom[2026];
nW = (2 &); wW = <|"X" -> 2, "Y" -> 2, "Z" -> 4, "U" -> 3, "g" -> 5|>;      (* weights: boxes X → Y and X⊗Y → Z keep them *)
matsW = <|"f" -> RandomInteger[{-3, 3}, {2, 2}], "p" -> RandomInteger[{-3, 3}, {2, 2}], "q" -> RandomInteger[{-3, 3}, {2, 2}],
    "h" -> RandomInteger[{-3, 3}, {2, 4}], "k" -> RandomInteger[{-3, 3}, {2, 2}], "u" -> {{1, 1}, {0, 1}}, "u\[Prime]" -> {{1, -1}, {0, 1}},
    "m" -> RandomInteger[{-3, 3}, {2, 2}], "\[Alpha]" -> {{7}}|>;
mW[ld_] := matW[ld, nW, wW, matsW];
inverses = {{"u", "u\[Prime]"}};      (* u′ is declared the inverse of u *)
fB = boxL["f", {"X"}, {"Y"}];  pB = boxL["p", {"X"}, {"Y"}];  qB = boxL["q", {"Y"}, {"X"}];  kB2 = boxL["k", {"X"}, {"X"}];
hB2 = boxL["h", {"X", "Y"}, {"Z"}];

(* Lemma 2.2 *)
lem22 = <|"\[Psi] = \[Phi]" -> {psiDef["X"], phiDef["X"]}, "\[Psi]\:207b\:00b9 = \[CurlyTheta] = \[Nu]" -> {thetaDef["X"], nuDef["X"], boxL[psiInv["X"], {"X**"}, {"X"}]},
    "\[CurlyTheta]\[Psi] = id" -> {stackL[psiDef["X"], thetaDef["X"]], idL[{"X"}]}, "\[Psi]\[CurlyTheta] = id" -> {stackL[thetaDef["X"], psiDef["X"]], idL[{"X**"}]},
    "\[Nu]\[Phi] = id" -> {stackL[phiDef["X"], nuDef["X"]], idL[{"X"}]}, "\[Phi]\[Nu] = id" -> {stackL[nuDef["X"], phiDef["X"]], idL[{"X**"}]}|>;
(* Lemma 2.3: the four formulas, left side as typed in the book, right side the cap or cup on X* *)
lem23 = <|
   "\:1ebdv_X = ev_X* (\[Psi]_X \[CircleTimes] id_X* )" -> {LD[{"X", "X*"}, {{0, B[evR["X"], {"X", "X*"}, {}]}}],
      LD[{"X", "X*"}, {{0, psiB["X"]}, {0, B[evL["X*"], {"X**", "X*"}, {}]}}]},
   "c\:0303oev_X = (id_X* \[CircleTimes] \[Psi]\:207b\:00b9_X) coev_X*" -> {LD[{}, {{0, B[coevR["X"], {}, {"X*", "X"}]}}],
      LD[{}, {{0, B[coevL["X*"], {}, {"X*", "X**"}]}, {1, psiInvB["X"]}}]},
   "ev_X = \:1ebdv_X* (id_X* \[CircleTimes] \[Psi]_X)" -> {LD[{"X*", "X"}, {{0, B[evL["X"], {"X*", "X"}, {}]}}],
      LD[{"X*", "X"}, {{1, psiB["X"]}, {0, B[evR["X*"], {"X*", "X**"}, {}]}}]},
   "coev_X = (\[Psi]\:207b\:00b9_X \[CircleTimes] id_X* ) c\:0303oev_X*" -> {LD[{}, {{0, B[coevL["X"], {}, {"X", "X*"}]}}],
      LD[{}, {{0, B[coevR["X*"], {}, {"X**", "X*"}]}, {0, psiInvB["X"]}}]}|>;
(* Lemma 2.4 for S = ((X,−),(Y,+)) and for S = ((X,+),(Y,+),(Z,−)) *)
S1 = {{"X", "-"}, {"Y", "+"}};  S2 = {{"X", "+"}, {"Y", "+"}, {"Z", "-"}};
lem24[s_] := <|
   "ev_X_S (\[CapitalPsi]_S* \[CircleTimes] id) = ev_S" -> {stackL[besideL[PsiS[dualTuple[s]], idL[XS[s]]], evXS[s]], evS[s]},
   "\:1ebdv_X_S* (id \[CircleTimes] \[CapitalPsi]_S) = ev_S" -> {stackL[besideL[idL[XS[dualTuple[s]]], PsiS[s]], evRXS[dualTuple[s]]], evS[s]},
   "(id \[CircleTimes] \[CapitalPsi]\:207b\:00b9_S* ) coev_X_S = coev_S" -> {stackL[coevXS[s], besideL[idL[XS[s]], PsiInvS[dualTuple[s]]]], coevS[s]},
   "(\[CapitalPsi]\:207b\:00b9_S \[CircleTimes] id) c\:0303oev_X_S* = coev_S" -> {stackL[coevRXS[dualTuple[s]], besideL[PsiInvS[s], idL[XS[dualTuple[s]]]]], coevS[s]}|>;
(* Exercise 2.3.3: ψ_X* = (ψ_X⁻¹)* , and (ψ_X)* ψ_X* = id *)
ex233 = <|"\[Psi]_X* = (\[Psi]\:207b\:00b9_X)*" -> {LD[{"X*"}, {{0, psiB["X*"]}}], dualLD[LD[{"X**"}, {{0, psiInvB["X"]}}]]},
    "(\[Psi]_X)* \[Psi]_X* = id_X*" -> {stackL[LD[{"X*"}, {{0, psiB["X*"]}}], dualLD[LD[{"X"}, {{0, psiB["X"]}}]]], idL[{"X*"}]}|>;
(* (2.3) and (2.4) *)
zig23[s_] := {stackL[besideL[coevS[s], idL[XS[s]]], besideL[idL[XS[s]], evS[s]]], idL[XS[s]]};
zig24[s_] := {stackL[besideL[idL[XS[dualTuple[s]]], coevS[s]], besideL[evS[s], idL[XS[dualTuple[s]]]]], idL[XS[dualTuple[s]]]};
(* Lemma 2.5 / naturality of ψ: a box turned through 360° *)
rot = <|"f turned through 360\[Degree]" -> {rotate360[fB], fB}, "h : X\[CircleTimes]Y \[RightArrow] Z turned through 360\[Degree]" -> {rotate360[hB2], hB2}|>;
(* §2.6 traces *)
trc = <|
   "tr_l(pq) = tr_l(qp)" -> {trL[stackL[qB, pB]], trL[stackL[pB, qB]]},
   "tr_r(pq) = tr_r(qp)" -> {trR[stackL[qB, pB]], trR[stackL[pB, qB]]},
   "tr_l(f) = tr_r(f* )" -> {trL[kB2], trR[boxL["k*", {"X*"}, {"X*"}]]},
   "tr_r(f) = tr_l(f* )" -> {trR[kB2], trL[boxL["k*", {"X*"}, {"X*"}]]},
   "tr_l(f) = tr_l(f** )" -> {trL[kB2], trL[dualLD[dualLD[kB2]]]},
   "tr_l(f \[CircleTimes] g) = tr_l(tr_l(f)\[CenterDot]g)" -> {trL[LD[{"X", "Y"}, {{0, B["k", {"X"}, {"X"}]}, {1, B["m", {"Y"}, {"Y"}]}}]],
      stackL[LD[{}, {{0, B[coevR["Y"], {}, {"Y*", "Y"}]}}], besideL[idL[{"Y*"}], trL[kB2], boxL["m", {"Y"}, {"Y"}]], LD[{"Y*", "Y"}, {{0, B[evL["Y"], {"Y*", "Y"}, {}]}}]]},
   "tr_l(f\[CenterDot]\[Alpha]) = \[Alpha] tr_l(f)" -> {trL[besideL[kB2, boxL["\[Alpha]", {}, {}]]], stackL[trL[kB2], boxL["\[Alpha]", {}, {}]]},
   "tr_l on X*: ev_X* (id \[CircleTimes] f) c\:0303oev_X* = \:1ebdv_X (id \[CircleTimes] f) coev_X" -> {trL[boxL["k*", {"X*"}, {"X*"}]],
      LD[{}, {{0, B[coevL["X"], {}, {"X", "X*"}]}, {1, B["k*", {"X*"}, {"X*"}]}, {0, B[evR["X"], {"X", "X*"}, {}]}}]},
   "tr_r on X*: \:1ebdv_X* (f \[CircleTimes] id) coev_X* = ev_X (f \[CircleTimes] id) c\:0303oev_X" -> {trR[boxL["k*", {"X*"}, {"X*"}]],
      LD[{}, {{0, B[coevR["X"], {}, {"X*", "X"}]}, {0, B["k*", {"X*"}, {"X*"}]}, {0, B[evL["X"], {"X*", "X"}, {}]}}]}|>;
dms = <|"dim_l(X) = dim_r(X* )" -> {dimL["X"], dimR["X*"]}, "dim_l(X) = dim_l(X** )" -> {dimL["X"], dimL["X**"]},
    "dim_r(X) = dim_l(X* )" -> {dimR["X"], dimL["X*"]}, "dim_r(X) = dim_r(X** )" -> {dimR["X"], dimR["X**"]},
    "isomorphic objects: tr_l(u\[Prime]u) = tr_l(uu\[Prime])" -> {trL[stackL[boxL["u", {"X"}, {"Y"}], boxL["u\[Prime]", {"Y"}, {"X"}]]],
      trL[stackL[boxL["u\[Prime]", {"Y"}, {"X"}], boxL["u", {"X"}, {"Y"}]]]}|>;
(* Exercise 2.4.4: a loop reversed and recoloured X* *)
ex244 = <|"loop reversed: ev_X c\:0303oev_X = \:1ebdv_X* coev_X*" -> {dimL["X"], dimR["X*"]},
    "loop with a box, reversed: tr_l(f) = tr_r(f* )" -> {trL[kB2], trR[boxL["k*", {"X*"}, {"X*"}]]}|>;
(* Theorem 2.7, strand by strand: ψ_(X⊗Y) is ψ_X ⊗ ψ_Y *)
psiXY = LD[{"X", "Y"}, {{2, B[coevL["Y*\[CircleTimes]X*"], {}, {"Y*", "X*", "X**", "Y**"}]}, {0, B[evR["X\[CircleTimes]Y"], {"X", "Y", "Y*", "X*"}, {}]}}];
thm27 = <|"\[Psi]_(X\[CircleTimes]Y) = \[Psi]_X \[CircleTimes] \[Psi]_Y" -> {psiXY, besideL[LD[{"X"}, {{0, psiB["X"]}}], LD[{"Y"}, {{0, psiB["Y"]}}]]}|>;
(* §2.7 sphericity *)
sph = <|"tr_l(f) = tr_r(f)" -> {trL[kB2], trR[kB2]}, "dim_l(X) = dim_r(X)" -> {dimL["X"], dimR["X"]},
    "Lemma 2.9: tr_r(pq) = tr_l(qp), a loop pushed across \[Infinity]" -> {trR[stackL[qB, pB]], trL[stackL[pB, qB]]}|>;


(* ::Section:: *)
(* 47. Checking an identity by the rules and in the matrix model *)

byRules[{l__}, rs_: rulesD] := SameQ @@ (simplifyLD[#, rs] & /@ {l});
inMatrices[{l__}, w_: wW] := Equal @@ (matW[#, nW, w, matsW] & /@ {l});
stepsKeepW[ld_, rs_: rulesD, w_: wW] := Equal @@ (matW[#[[2]], nW, w, matsW] & /@ simplifyTrace[ld, rs]);

(* © Computational Classnotes · CC BY-NC-SA 4.0 *)
