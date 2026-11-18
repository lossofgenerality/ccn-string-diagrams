(* ::Package:: *)
(* Graphical calculus §3.3.1–3.3.3: twists, ribbon categories, Lemmas 3.2, 3.5, 3.6, Theorem 3.3, Corollary 3.4 (Turaev & Virelizier, pp. 59–62) *)
(* Sections 60–65. Needs the earlier engine (sections 0–19, 20–27, 30–35, 40–47, 50–55) evaluated first; all files live in Desktop/Research/Monoidal Graphical Calculus. *)


(* ::Section:: *)
(* 60. §3.3.1 Twists: the curls θˡ_X, θʳ_X and their inverses *)

(* θˡ_X = (ev_X ⊗ id_X)(id_X* ⊗ τ_X,X)(c̃oev_X ⊗ id_X) and θʳ_X = (id_X ⊗ ẽv_X)(τ_X,X ⊗ id_X* )(id_X ⊗ coev_X) are curls on the strand X.
   By Lemma 3.2 their inverses are the curls with the other crossing:
   (θˡ_X)⁻¹ = (id_X ⊗ ẽv_X)(τ⁻¹_X,X ⊗ id_X* )(id_X ⊗ coev_X) and (θʳ_X)⁻¹ = (ev_X ⊗ id_X)(id_X* ⊗ τ⁻¹_X,X)(c̃oev_X ⊗ id_X).
   "twist fold" recognises the four curls, in three consecutive layers, and replaces each by a box θˡ_X, θʳ_X, θˡ⁻¹_X or θʳ⁻¹_X. *)

thetaL[x_] := Subscript["\[Theta]\:02e1", x];  thetaR[x_] := Subscript["\[Theta]\:02b3", x];
thetaLInv[x_] := Subscript["\[Theta]\:02e1\:207b\:00b9", x];  thetaRInv[x_] := Subscript["\[Theta]\:02b3\:207b\:00b9", x];
twistQ[s_] := MatchQ[s, Subscript["\[Theta]\:02e1" | "\[Theta]\:02b3" | "\[Theta]\:02e1\:207b\:00b9" | "\[Theta]\:02b3\:207b\:00b9", _String]];
twistB[t_, x_] := B[t[x], partsU[x], partsU[x]];

(* the curls, as layered diagrams on a strand coloured x *)
curlL[x_, pos_] := LD[{x}, {{0, B[coevR[x], {}, {star[x], x}]}, {1, crossingB[pos, {x, x}]}, {0, B[evL[x], {star[x], x}, {}]}}];   (* θˡ, or (θʳ)⁻¹ *)
curlR[x_, pos_] := LD[{x}, {{1, B[coevL[x], {}, {x, star[x]}]}, {0, crossingB[pos, {x, x}]}, {1, B[evR[x], {x, star[x]}, {}]}}];   (* θʳ, or (θˡ)⁻¹ *)
thetaLDef[x_] := curlL[x, True];  thetaRInvDef[x_] := curlL[x, False];
thetaRDef[x_] := curlR[x, True];  thetaLInvDef[x_] := curlR[x, False];

(* The three layers of a curl need not be consecutive: layers between them that do not touch the curl's three strands are allowed (level exchange).
   For each cup in turn, the window w..w+2 of the curl's strands is followed up the diagram; the first complete curl is folded,
   and the twist box takes the place of the crossing. *)
twistFold[ld : LD[src_, ls_]] := Module[{rs = rows[ld], n = Length[ls]},
   Catch[Do[Module[{a = ls[[i, 1]], b = ls[[i, 2]], type = None, x, w, w0, stage = 1, sg, jj, wj, right = {}, tp, ep, lo, hi},
      Which[MatchQ[sym[b], Subscript[OverTilde["coev"], _String]] && Length[outs[b]] == 2, type = "L"; w = a,
       MatchQ[sym[b], Subscript["coev", _String]] && Length[outs[b]] == 2 && a >= 1, type = "R"; w = a - 1];
      lo[] := If[stage == 2 && type == "R", w + 1, w]; hi[] := If[stage == 2 && type == "L", w + 1, w + 2];
      If[type =!= None && Length[rs[[i]]] > w && rs[[i, w + 1]] === sym[b][[2]],
       x = sym[b][[2]];
       Do[With[{p = ls[[j, 1]], bb = ls[[j, 2]]}, With[{ni = Length[ins[bb]], no = Length[outs[bb]]},
          tp = If[type == "L", w + 1, w]; ep = If[type == "L", w, w + 1];
          Which[
           stage == 1 && p == tp && tauQ[sym[bb]] && ins[bb] === {x, x}, sg = tauPos[sym[bb]]; jj = j; wj = w; stage = 2,
           (* a one-line box on the incoming strand, before the crossing, stays below the twist *)
           stage == 1 && ni == 1 && no == 1 && p == If[type == "L", w + 2, w], If[type == "L", AppendTo[right, j]],
           stage == 2 && p == ep && ni == 2 && sym[bb] === If[type == "L", Subscript["ev", x], Subscript[OverTilde["ev"], x]],
            Throw[LD[src, Table[Which[k == jj, {wj, twistB[Which[type == "L" && sg, thetaL, type == "L", thetaRInv, sg, thetaR, True, thetaLInv], x]},
                 MemberQ[right, k], {ls[[k, 1]] - 2, ls[[k, 2]]}, True, ls[[k]]], {k, Complement[Range[n], {i, j}]}]]],
           (* outside the strands still in use: all three before the crossing; after it, the curl's outgoing strand is free *)
           If[ni == 0, p <= lo[], p + ni - 1 < lo[]], w += no - ni,
           p > hi[], AppendTo[right, j],
           True, Break[]]]], {j, i + 1, n}]]], {i, n}]; $Failed]];


(* ::Section:: *)
(* 61. Lemma 3.2 and §3.3.2: the rules for twists *)

(* twists and their inverses cancel; a twist slides down through a one-line box (naturality, Lemma 3.2);
   on a tensor product it is Exercise 3.3.3, θ_X⊗Y = (θ_X ⊗ θ_Y) τ_Y,X τ_X,Y, and θ_𝟙 = id_𝟙.
   A ribbon category (§3.3.2) has θˡ = θʳ; "ribbon" writes every θʳ as θˡ. *)

twistInvQ[s1_, s2_] := MatchQ[{s1, s2},
   {Subscript["\[Theta]\:02e1", x_], Subscript["\[Theta]\:02e1\:207b\:00b9", x_]} | {Subscript["\[Theta]\:02e1\:207b\:00b9", x_], Subscript["\[Theta]\:02e1", x_]} |
   {Subscript["\[Theta]\:02b3", x_], Subscript["\[Theta]\:02b3\:207b\:00b9", x_]} | {Subscript["\[Theta]\:02b3\:207b\:00b9", x_], Subscript["\[Theta]\:02b3", x_]}];
cancelTwist[{a_, B[s1_, {c_}, {c_}]}, {a_, B[s2_, {c_}, {c_}]}] /; twistInvQ[s1, s2] := {};
cancelTwist[__] := $Failed;
naturalTwist[{a_, B[f_String, {x_}, {y_}]}, {a_, B[Subscript[h_, y_], {y_}, {y_}]}] /; twistQ[Subscript[h, y]] :=
  {{a, B[Subscript[h, x], {x}, {x}]}, {a, B[f, {x}, {y}]}};
naturalTwist[__] := $Failed;
twistTensor[{a_, B[Subscript[h_, x_String], i_, i_]}] /; twistQ[Subscript[h, x]] := With[{ps = partsU[x]},
   Which[ps === {}, {},
    Length[ps] > 1 && (h === "\[Theta]\:02e1" || h === "\[Theta]\:02b3"),
     With[{p = First[ps], r = joinParts[Rest[ps]]},
      {{a, tauB[p, r]}, {a, tauB[r, p]}, {a, B[Subscript[h, p], {p}, {p}]}, {a + 1, B[Subscript[h, r], partsU[r], partsU[r]]}}],
    True, $Failed]];
twistTensor[_] := $Failed;
ribbonTwist[{a_, B[Subscript["\[Theta]\:02b3", x_], i_, o_]}] := {{a, B[Subscript["\[Theta]\:02e1", x], i, o]}};
ribbonTwist[{a_, B[Subscript["\[Theta]\:02b3\:207b\:00b9", x_], i_, o_]}] := {{a, B[Subscript["\[Theta]\:02e1\:207b\:00b9", x], i, o]}};
ribbonTwist[_] := $Failed;

twistRules = <|
   "twist fold (\[Section]3.3.1)" -> {"ld", twistFold},
   "twists cancel (Lemma 3.2)" -> {2, cancelTwist},
   "naturality of \[Theta] (Lemma 3.2)" -> {2, naturalTwist},
   "twist on \[CircleTimes] (Exercise 3.3.3)" -> {1, twistTensor}|>;
ribbonRules = <|"ribbon: \[Theta]\:02b3 = \[Theta]\:02e1 (\[Section]3.3.2)" -> {1, ribbonTwist}|>;

(* the fold goes in before Lemma 2.3, so that a curl on an upward strand is recognised before its cap and cup are rewritten *)
withTwists[rs_Association] := With[{k = Keys[rs], i = First[FirstPosition[Keys[rs], "Lemma 2.3 (X** = X)"]]},
   Join[AssociationThread[Take[k, i - 1], Lookup[rs, Take[k, i - 1]]], KeyTake[twistRules, {"twist fold (\[Section]3.3.1)"}],
    AssociationThread[Drop[k, i - 1], Lookup[rs, Drop[k, i - 1]]], KeyDrop[twistRules, {"twist fold (\[Section]3.3.1)"}]]];
rulesTw = withTwists[rulesDB];                               (* braided pivotal *)
rulesRib = Join[withTwists[rulesSB], ribbonRules];           (* ribbon; spherical by Corollary 3.4 *)


(* ::Section:: *)
(* 62. A matrix model with twists: graded vector spaces with a bicharacter and weights *)

(* Colours are graded (grade g, braiding q^(g h) · flip) and weighted (ẽv_X = w(X)·pairing, c̃oev_X = pairing/w(X)); boxes keep grade and weight.
   Then θˡ_X = q^(g²)/w(X)·id and θʳ_X = q^(g²) w(X)·id, so the category is ribbon exactly when w(X)² = 1 for every X; with w = 1 it is ribbon with twist q^(g²).
   Lemma 3.5's pivotal structure ẽv_X = ev_X τ_X,X* is the weight w(X) = q^(−g²), a character only when q^(2gh) = 1, that is, for a symmetry. *)

matGW[ld_LD, n_, gr_, q_, w_, mats_] := Module[{rs = rows[ld], m, dimC, box},
   dimC[cs_List] := Times @@ (nOf[#, n] & /@ cs);
   box[b_B] := With[{s = sym[b]},
     Which[
      tauQ[s] && Length[ins[b]] == 2,
       With[{l = ins[b][[1]], r = ins[b][[2]]},
        If[tauPos[s], q^(gradeOf[l, gr] gradeOf[r, gr]), q^(-gradeOf[l, gr] gradeOf[r, gr])] flipM[nOf[l, n], nOf[r, n]]],
      tauQ[s], matGW[LD[ins[b], braidSplit[{0, b}]], n, gr, q, w, mats],
      twistQ[s] && Length[ins[b]] == 1, With[{x = s[[2]]},
        matGW[Switch[s[[1]], "\[Theta]\:02e1", thetaLDef[x], "\[Theta]\:02b3", thetaRDef[x], "\[Theta]\:02e1\:207b\:00b9", thetaLInvDef[x], _, thetaRInvDef[x]], n, gr, q, w, mats]],
      twistQ[s], matGW[LD[ins[b], twistTensor[{0, b}]], n, gr, q, w, mats],
      True, matBox[b, n, w, mats]]];
   m = IdentityMatrix[dimC[First[rs]]];
   Do[With[{a = ld[[2, k, 1]], b = ld[[2, k, 2]], row = rs[[k]]},
     m = KroneckerProduct[IdentityMatrix[dimC[Take[row, a]]], box[b], IdentityMatrix[dimC[Drop[row, a + Length[ins[b]]]]]] . m], {k, Length[ld[[2]]]}];
   m];


(* ::Section:: *)
(* 63. The constructions of pp. 59–62, as layered diagrams *)

SeedRandom[3303];
nT = (2 &);  grT = <|"X" -> 1, "Y" -> 2, "Z" -> 1|>;  qT = 3;
wBraided = <|"X" -> 2, "Y" -> 2, "Z" -> 2|>;          (* braided pivotal, not ribbon *)
wRibbon = <|"X" -> 1, "Y" -> -1, "Z" -> 1|>;          (* ribbon *)
matsT = <|"f" -> RandomInteger[{-3, 3}, {2, 2}], "g" -> RandomInteger[{-3, 3}, {2, 2}]|>;
mT[ld_, w_: wBraided, q_: qT, gr_: grT] := matGW[ld, nT, gr, q, w, matsT];
inT[{l__}, w_: wBraided, q_: qT, gr_: grT] := Equal @@ (mT[#, w, q, gr] & /@ {l});
boxT[t_, x_] := LD[partsU[x], {{0, twistB[t, x]}}];

lem32 = <|
   "the curl is \[Theta]\:02e1_X" -> {thetaLDef["X"], boxT[thetaL, "X"]},
   "\[Theta]\:02e1_X (\[Theta]\:02e1_X)\:207b\:00b9 = id (the curls of Lemma 3.2)" -> {stackL[thetaLInvDef["X"], thetaLDef["X"]], idL[{"X"}]},
   "(\[Theta]\:02e1_X)\:207b\:00b9 \[Theta]\:02e1_X = id" -> {stackL[thetaLDef["X"], thetaLInvDef["X"]], idL[{"X"}]},
   "\[Theta]\:02b3_X (\[Theta]\:02b3_X)\:207b\:00b9 = id" -> {stackL[thetaRInvDef["X"], thetaRDef["X"]], idL[{"X"}]},
   "naturality: \[Theta]\:02e1_Z f = f \[Theta]\:02e1_X" -> {stackL[boxL["f", {"X"}, {"Z"}], boxT[thetaL, "Z"]], stackL[boxT[thetaL, "X"], boxL["f", {"X"}, {"Z"}]]},
   "naturality: \[Theta]\:02b3_Z f = f \[Theta]\:02b3_X" -> {stackL[boxL["f", {"X"}, {"Z"}], thetaRDef["Z"]], stackL[thetaRDef["X"], boxL["f", {"X"}, {"Z"}]]},
   "a curl on an upward strand is \[Theta]\:02e1_X*" -> {thetaLDef["X*"], boxT[thetaL, "X*"]}|>;
(* matrix-only parts of Lemma 3.2 and (3.4): duals of twists and traces of twists *)
lem32m = <|
   "(\[Theta]\:02b3_X)* = \[Theta]\:02e1_X*" -> {dualLD[thetaRDef["X"]], thetaLDef["X*"]},
   "(\[Theta]\:02e1_X)* = \[Theta]\:02b3_X*" -> {dualLD[thetaLDef["X"]], thetaRDef["X*"]},
   "(3.4) tr_r(\[Theta]\:02e1_X) = tr_l(\[Theta]\:02b3_X)" -> {trR[thetaLDef["X"]], trL[thetaRDef["X"]]}|>;
ex333 = <|"\[Theta]\:02e1_X\[CircleTimes]Y = (\[Theta]\:02e1_X \[CircleTimes] \[Theta]\:02e1_Y) \[Tau]_Y,X \[Tau]_X,Y" -> {boxT[thetaL, "X\[CircleTimes]Y"],
      stackL[LD[{"X", "Y"}, {{0, tauB["X", "Y"]}, {0, tauB["Y", "X"]}}], besideL[boxT[thetaL, "X"], boxT[thetaL, "Y"]]]},
    "\[Theta]\:02b3_X\[CircleTimes]Y = (\[Theta]\:02b3_X \[CircleTimes] \[Theta]\:02b3_Y) \[Tau]_Y,X \[Tau]_X,Y" -> {boxT[thetaR, "X\[CircleTimes]Y"],
      stackL[LD[{"X", "Y"}, {{0, tauB["X", "Y"]}, {0, tauB["Y", "X"]}}], besideL[boxT[thetaR, "X"], boxT[thetaR, "Y"]]]}|>;
(* the curl picture of θ_X⊗Y, written out with tensor caps: checked in matrices *)
thetaLXY = LD[{"X", "Y"}, {{0, B[coevR["X\[CircleTimes]Y"], {}, {"Y*", "X*", "X", "Y"}]}, {2, tauB["X\[CircleTimes]Y", "X\[CircleTimes]Y"]},
     {0, B[evL["X\[CircleTimes]Y"], {"Y*", "X*", "X", "Y"}, {}]}}];
(* §3.3.2 ribbon categories, Theorem 3.3, Corollary 3.4 *)
rib = <|"ribbon: \[Theta]\:02e1_X = \[Theta]\:02b3_X" -> {thetaLDef["X"], thetaRDef["X"]},
    "Theorem 3.3, R1: the double curl \[Theta]\:02b3_X (\[Theta]\:02e1_X)\:207b\:00b9 is id_X" -> {stackL[thetaLInvDef["X"], thetaRDef["X"]], idL[{"X"}]},
    "Theorem 3.3, R1 on an upward strand" -> {stackL[thetaLInvDef["X*"], thetaRDef["X*"]], idL[{"X*"}]}|>;
ribm = <|"self-dual twist: (\[Theta]_X)* = \[Theta]_X*" -> {dualLD[thetaLDef["X"]], thetaLDef["X*"]}|>;
cor34 = <|"Corollary 3.4: tr_l(f) = tr_r(f)" -> {trL[boxL["g", {"X"}, {"X"}]], trR[boxL["g", {"X"}, {"X"}]]}|>;
(* Lemma 3.5: a symmetry and ẽv_X = ev_X τ_X,X* give a ribbon category with twist id; super vector spaces *)
wLemma35[gr_, q_] := (q^(-gr[#]^2) &);
lem35 = <|"\[Theta]\:02e1_X = id" -> {thetaLDef["X"], idL[{"X"}]}, "\[Theta]\:02b3_X = id" -> {thetaRDef["X"], idL[{"X"}]},
    "\:1ebdv_X = ev_X \[Tau]_X,X*" -> {LD[{"X", "X*"}, {{0, B[evR["X"], {"X", "X*"}, {}]}}], LD[{"X", "X*"}, {{0, tauB["X", "X*"]}, {0, B[evL["X"], {"X*", "X"}, {}]}}]}|>;
(* Lemma 3.6: tr(f) = ω(f ⊗ id_Y) P(∗ω) for a non-degenerate pairing ω : X ⊗ Y → k *)
lemma36[] := Module[{n = 3, M, f, g, om, contr, P},
   M = RandomInteger[{-3, 3}, {n, n}]; While[Det[M] == 0, M = RandomInteger[{-3, 3}, {n, n}]];
   f = RandomInteger[{-3, 3}, {n, n}]; g = RandomInteger[{-3, 3}, {n, n}];
   om = Flatten[M];                                   (* ω(x ⊗ y) = xᵀ M y *)
   contr = Flatten[Inverse[M]];                       (* ∗ω ∈ Y ⊗ X, the inverse of ω *)
   P = flipM[n, n];                                    (* Y ⊗ X → X ⊗ Y *)
   {om . KroneckerProduct[f, IdentityMatrix[n]] . P . contr == Tr[f], om . KroneckerProduct[IdentityMatrix[n], g] . P . contr == Tr[g],
    om . P . contr == Tr[IdentityMatrix[n]]}];


(* ::Section:: *)
(* 64. Checking *)

byRulesT[{l__}, rs_: rulesTw] := SameQ @@ (simplifyLD[#, rs] & /@ {l});
stepsKeepT[ld_, rs_: rulesTw, w_: wBraided] := Equal @@ (mT[#[[2]], w] & /@ simplifyTrace[ld, rs]);

(* © Computational Classnotes · CC BY-NC-SA 4.0 *)
