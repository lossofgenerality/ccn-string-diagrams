(* ::Package:: *)
(* Graphical calculus §2.7.3–2.7.4 and §3.1–3.2.3: sphericity of proj_k, braidings and symmetries, Reidemeister diagrams (Turaev & Virelizier, pp. 50–58) *)
(* Sections 50–57. Needs sections 0–19 of graphical-calculus-2.1-simplify.nb, pivotal-2.1.3.wl, penrose-2.2.wl and pivotal-2.3-2.7.wl evaluated first; all live in Desktop/Research/Monoidal Graphical Calculus. *)


(* ::Section:: *)
(* 50. §2.7.3 Sphericity of proj_k: Lemma 2.10 *)

(* A projective module X of finite type sits in a free module Y = X ⊕ R: j : X → Y is the inclusion and p : Y → X the projection, so p j = id_X while j p is only an idempotent of Y.
   Lemma 2.10 says tr_l(f) is the Hattori–Stallings trace Tr(j f p). The proof is the graphical identity tr_l(j f p) = tr_l(f p j) = tr_l(f): trace symmetry, then p j = id_X.
   "retract" is that one-sided cancellation: a box p directly above a box j on the same line cancels when the pair {p, j} is declared in retracts. *)

retracts = {{"p", "j"}};                         (* p ∘ j = id *)
cancelRetract[{a_, B[j_, {x_}, {y_}]}, {a_, B[p_, {y_}, {x_}]}] /; MemberQ[retracts, {p, j}] := {};
cancelRetract[__] := $Failed;


(* ::Section:: *)
(* 51. §3.1.1 Braidings: the boxes τ_X,Y and τ⁻¹_Y,X, and the rules (3.1)–(3.3) *)

(* τ_X,Y : X ⊗ Y → Y ⊗ X is drawn as a crossing in which the strand coming from X passes over (Figure 3.1). The other crossing is τ⁻¹_Y,X : X ⊗ Y → Y ⊗ X, the inverse of τ_Y,X.
   The subscript is the string "X,Y"; X and Y may be tensor products such as "X⊗Y".
   (3.1) τ_X,Y⊗Z = (id_Y ⊗ τ_X,Z)(τ_X,Y ⊗ id_Z) and (3.2) τ_X⊗Y,Z = (τ_X,Z ⊗ id_Y)(id_X ⊗ τ_Y,Z) split a crossing of tensor products into crossings of single lines; (3.3) τ_X,𝟙 = τ_𝟙,X = id_X. *)

tauSub[x_String, y_String] := x <> "," <> y;
tau[x_, y_] := Subscript["\[Tau]", tauSub[x, y]];
tauInv[y_, x_] := Subscript[Superscript["\[Tau]", "-1"], tauSub[y, x]];
partsU[x_String] := DeleteCases[partsOf[x], unit | "\[DoubleStruckOne]" | "I" | "1"];
tauB[x_, y_] := B[tau[x, y], Join[partsU[x], partsU[y]], Join[partsU[y], partsU[x]]];        (* X ⊗ Y → Y ⊗ X *)
tauInvB[y_, x_] := B[tauInv[y, x], Join[partsU[x], partsU[y]], Join[partsU[y], partsU[x]]];  (* X ⊗ Y → Y ⊗ X, the inverse of τ_Y,X *)
tauQ[s_] := MatchQ[s, Subscript["\[Tau]" | Superscript["\[Tau]", "-1"], _String]];
tauArgs[Subscript[_, s_String]] := StringSplit[s, ",", 2];
tauPos[s_] := MatchQ[s, Subscript["\[Tau]", _]];

braidSplit[{a_, B[s_?tauQ, i_, o_]}] := Module[{x, y, px, py},
   {x, y} = tauArgs[s]; px = partsU[x]; py = partsU[y];
   Which[
    px === {} || py === {}, {},                                                             (* (3.3) *)
    tauPos[s] && Length[py] > 1, {{a, tauB[x, First[py]]}, {a + 1, tauB[x, joinParts[Rest[py]]]}},          (* (3.1) *)
    tauPos[s] && Length[px] > 1, {{a + 1, tauB[joinParts[Rest[px]], y]}, {a, tauB[First[px], y]}},          (* (3.2) *)
    ! tauPos[s] && Length[py] > 1, {{a + 1, tauInvB[x, joinParts[Rest[py]]]}, {a, tauInvB[x, First[py]]}},   (* inverse of (3.1) *)
    ! tauPos[s] && Length[px] > 1, {{a, tauInvB[First[px], y]}, {a + 1, tauInvB[joinParts[Rest[px]], y]}},   (* inverse of (3.2) *)
    True, $Failed]];
braidSplit[_] := $Failed;


(* ::Section:: *)
(* 52. §3.2.2 The Reidemeister moves R2–R5 as rules *)

(* R2: a crossing and the inverse crossing on the same two lines cancel.
   R4, R5: a box slides through a crossing (naturality of τ): a one-line box just above a crossing moves below it, onto the same strand.
   R3: the Yang–Baxter equation (Exercise 3.1.12), (τ_Y,Z ⊗ id_X)(id_Y ⊗ τ_X,Z)(τ_X,Y ⊗ id_Z) = (id_Z ⊗ τ_X,Y)(τ_X,Z ⊗ id_Y)(id_X ⊗ τ_Y,Z), used from left to right on three consecutive crossings of the same kind. *)

crossingB[pos_, {l_String, r_String}] := If[pos, tauB[l, r], tauInvB[r, l]];      (* the crossing on the lines l, r *)
invTau[Subscript["\[Tau]", s_String]] := Subscript[Superscript["\[Tau]", "-1"], s];
invTau[Subscript[Superscript["\[Tau]", "-1"], s_String]] := Subscript["\[Tau]", s];
cancelCross[{a_, B[s1_?tauQ, {l_, r_}, {r_, l_}]}, {a_, B[s2_?tauQ, {r_, l_}, {l_, r_}]}] /; s2 === invTau[s1] := {};
cancelCross[__] := $Failed;
plainBoxQ[s_] := StringQ[s];
naturalTau[{a_, B[s_?tauQ, {l_, r_}, {r_, l_}]}, {a_, B[g_?plainBoxQ, {r_}, {r2_}]}] :=
  {{a + 1, B[g, {r}, {r2}]}, {a, crossingB[tauPos[s], {l, r2}]}};
naturalTau[{a_, B[s_?tauQ, {l_, r_}, {r_, l_}]}, {b_, B[g_?plainBoxQ, {l_}, {l2_}]}] /; b == a + 1 :=
  {{a, B[g, {l}, {l2}]}, {a, crossingB[tauPos[s], {l2, r}]}};
naturalTau[__] := $Failed;
yangBaxter[LD[src_, ls_]] := Module[{rs = rows[LD[src, ls]]},
   Catch[Do[With[{c1 = ls[[k]], c2 = ls[[k + 1]], c3 = ls[[k + 2]]},
      If[tauQ[sym[c1[[2]]]] && tauQ[sym[c2[[2]]]] && tauQ[sym[c3[[2]]]] &&
        Length[ins[c1[[2]]]] == Length[ins[c2[[2]]]] == Length[ins[c3[[2]]]] == 2 &&
        c2[[1]] == c1[[1]] + 1 && c3[[1]] == c1[[1]] &&
        Equal @@ (tauPos /@ (sym /@ {c1[[2]], c2[[2]], c3[[2]]})),
       With[{a = c1[[1]], e = tauPos[sym[c1[[2]]]], row = rs[[k]]},
        Module[{x = row[[a + 1]], y = row[[a + 2]], z = row[[a + 3]]},
         Throw[LD[src, Join[Take[ls, k - 1],
            {{a + 1, crossingB[e, {y, z}]}, {a, crossingB[e, {x, z}]}, {a + 1, crossingB[e, {x, y}]}}, Drop[ls, k + 2]]]]]]]],
     {k, Length[ls] - 2}]; $Failed]];

(* §3.1.2 symmetries and Remark 3.2.3: if τ is symmetric, τ⁻¹_Y,X = τ_X,Y, so over- and under-passes do not matter *)
symmetricTau[{a_, B[s_, i_, o_]}] /; tauQ[s] && ! tauPos[s] := With[{yx = tauArgs[s]}, {{a, B[tau[yx[[2]], yx[[1]]], i, o]}}];
symmetricTau[_] := $Failed;

braidRules = <|
   "braiding on \[CircleTimes] (3.1)\[Dash](3.3)" -> {1, braidSplit},
   "retract (\[Section]2.7.3)" -> {2, cancelRetract},
   "R2 (\[Section]3.2.2)" -> {2, cancelCross},
   "R4, R5: naturality of \[Tau]" -> {2, naturalTau},
   "R3: Yang\[Dash]Baxter" -> {"ld", yangBaxter}|>;
cancelSym[{a_, B[Subscript["\[Tau]", s1_String], {l_, r_}, {r_, l_}]}, {a_, B[Subscript["\[Tau]", s2_String], {r_, l_}, {l_, r_}]}] := {};
cancelSym[__] := $Failed;
symRules = <|"symmetry (\[Section]3.1.2)" -> {1, symmetricTau}, "\[Tau]_Y,X \[Tau]_X,Y = id (\[Section]3.1.2)" -> {2, cancelSym}|>;

rulesB = Join[rules, braidRules];          (* braided monoidal, duals written ∨X *)
rulesDB = Join[rulesD, braidRules];        (* braided pivotal *)
rulesSB = Join[rulesS, braidRules];        (* braided spherical *)
withSymmetry[rs_Association] := Join[rs, symRules];


(* ::Section:: *)
(* 53. A matrix model: graded vector spaces with a bicharacter (Examples 3.1.4–3.1.6) *)

(* Each colour X is k^n with a grade g(X) in ℤ; g(X* ) = −g(X), grades add over ⊗. The braiding is c(g, h) times the flip, with c(g, h) = q^(g h) (Example 3.1.6 with α = 1).
   q = −1 and grades mod 2 give super vector spaces (Example 3.1.5); q = 1 gives the flip of Example 3.1.4. The braiding is symmetric exactly when c(h, g) c(g, h) = 1.
   Duality is the usual pairing (weights 1), so the category is spherical. Boxes must keep the grade. *)

gradeOf[c_String, gr_] := Which[
   StringStartsQ[c, "("], -gradeOf[StringTake[c, {2, -3}], gr],
   StringContainsQ[c, "\[CircleTimes]"], Total[gradeOf[#, gr] & /@ StringSplit[c, "\[CircleTimes]"]],
   starQ[c], -gradeOf[unstar[c], gr], True, gr[c]];
flipM[m_, n_] := Normal[SparseArray[Flatten[Table[{(j - 1) m + i, (i - 1) n + j} -> 1, {i, m}, {j, n}], 1], {m n, m n}]];
matG[ld_LD, n_, gr_, q_, mats_] := Module[{rs = rows[ld], m, dimC, box},
   dimC[cs_List] := Times @@ (nOf[#, n] & /@ cs);
   box[b_B] := With[{s = sym[b]},
     Which[
      tauQ[s] && Length[ins[b]] == 2,
       With[{l = ins[b][[1]], r = ins[b][[2]]},
        If[tauPos[s], q^(gradeOf[l, gr] gradeOf[r, gr]), q^(-gradeOf[l, gr] gradeOf[r, gr])] flipM[nOf[l, n], nOf[r, n]]],
      tauQ[s], matG[LD[ins[b], braidSplit[{0, b}]], n, gr, q, mats],
      True, matBox[b, n, (1 &), mats]]];
   m = IdentityMatrix[dimC[First[rs]]];
   Do[With[{a = ld[[2, k, 1]], b = ld[[2, k, 2]], row = rs[[k]]},
     m = KroneckerProduct[IdentityMatrix[dimC[Take[row, a]]], box[b], IdentityMatrix[dimC[Drop[row, a + Length[ins[b]]]]]] . m], {k, Length[ld[[2]]]}];
   m];


(* ::Section:: *)
(* 54. The constructions of pp. 50–58, as layered diagrams *)

SeedRandom[3021];
nG = (2 &);  grG = <|"X" -> 1, "Y" -> 2, "Z" -> 1, "U" -> 1|>;  qG = 3;     (* braided, not symmetric *)
grS = <|"X" -> 1, "Y" -> 0, "Z" -> 1, "U" -> 1|>;                          (* super vector spaces with q = −1 *)
matsG = <|"f" -> RandomInteger[{-3, 3}, {2, 2}], "g" -> RandomInteger[{-3, 3}, {2, 2}], "k" -> RandomInteger[{-3, 3}, {2, 2}],
    "p" -> {{1, 0, 0}, {0, 1, 0}}, "j" -> {{1, 0}, {0, 1}, {0, 0}}|>;
mG[ld_, q_: qG, gr_: grG] := matG[ld, nG, gr, q, matsG];
inG[{l__}, q_: qG, gr_: grG] := Equal @@ (mG[#, q, gr] & /@ {l});

(* §2.7.3: Lemma 2.10 with X = k² inside Y = k³ *)
nHS = <|"X" -> 2, "Y" -> 3|>;
fXX = boxL["f", {"X"}, {"X"}];  jB = boxL["j", {"X"}, {"Y"}];  pB3 = boxL["p", {"Y"}, {"X"}];
lem210 = <|"tr_l(j f p) = tr_l(f)" -> {trL[stackL[pB3, fXX, jB]], trL[fXX]}|>;
hsTrace := With[{m = matsG}, {Tr[m["j"] . m["f"] . m["p"]], First[First[matW[trL[fXX], (nHS[#] &), (1 &), matsG]]]}];

(* §3.1.1 *)
br = <|
   "(3.1) \[Tau]_X,Y\[CircleTimes]Z = (id_Y \[CircleTimes] \[Tau]_X,Z)(\[Tau]_X,Y \[CircleTimes] id_Z)" -> {LD[{"X", "Y", "Z"}, {{0, tauB["X", "Y\[CircleTimes]Z"]}}],
      LD[{"X", "Y", "Z"}, {{0, tauB["X", "Y"]}, {1, tauB["X", "Z"]}}]},
   "(3.2) \[Tau]_X\[CircleTimes]Y,Z = (\[Tau]_X,Z \[CircleTimes] id_Y)(id_X \[CircleTimes] \[Tau]_Y,Z)" -> {LD[{"X", "Y", "Z"}, {{0, tauB["X\[CircleTimes]Y", "Z"]}}],
      LD[{"X", "Y", "Z"}, {{1, tauB["Y", "Z"]}, {0, tauB["X", "Z"]}}]},
   "naturality: \[Tau]_X',Y (f \[CircleTimes] g) = (g \[CircleTimes] f) \[Tau]_X,Y" -> {LD[{"X", "Y"}, {{0, B["f", {"X"}, {"X"}]}, {1, B["g", {"Y"}, {"Y"}]}, {0, tauB["X", "Y"]}}],
      LD[{"X", "Y"}, {{0, tauB["X", "Y"]}, {0, B["g", {"Y"}, {"Y"}]}, {1, B["f", {"X"}, {"X"}]}}]},
   "inverse of (3.1)" -> {LD[{"Y", "Z", "X"}, {{0, tauInvB["X", "Y\[CircleTimes]Z"]}}], LD[{"Y", "Z", "X"}, {{1, tauInvB["X", "Z"]}, {0, tauInvB["X", "Y"]}}]},
   "Exercise 3.1.12: Yang\[Dash]Baxter" -> {LD[{"X", "Y", "Z"}, {{0, tauB["X", "Y"]}, {1, tauB["X", "Z"]}, {0, tauB["Y", "Z"]}}],
      LD[{"X", "Y", "Z"}, {{1, tauB["Y", "Z"]}, {0, tauB["X", "Z"]}, {1, tauB["X", "Y"]}}]},
   "Exercise 3.1.12: naturality for the box \[Tau]_Y,Z gives Yang\[Dash]Baxter" -> {
      LD[{"X", "Y", "Z"}, {{1, tauB["Y", "Z"]}, {0, tauB["X", "Z\[CircleTimes]Y"]}}], LD[{"X", "Y", "Z"}, {{0, tauB["X", "Y\[CircleTimes]Z"]}, {0, tauB["Y", "Z"]}}]}|>;
(* Reidemeister moves R2–R5 (Figure 3.2) *)
rm = <|
   "R2: \[Tau]\:207b\:00b9_X,Y \[Tau]_X,Y = id" -> {LD[{"X", "Y"}, {{0, tauB["X", "Y"]}, {0, tauInvB["X", "Y"]}}], idL[{"X", "Y"}]},
   "R2: \[Tau]_X,Y \[Tau]\:207b\:00b9_X,Y = id" -> {LD[{"Y", "X"}, {{0, tauInvB["X", "Y"]}, {0, tauB["X", "Y"]}}], idL[{"Y", "X"}]},
   "R3 with inverse crossings" -> {LD[{"X", "Y", "Z"}, {{0, tauInvB["Y", "X"]}, {1, tauInvB["Z", "X"]}, {0, tauInvB["Z", "Y"]}}],
      LD[{"X", "Y", "Z"}, {{1, tauInvB["Z", "Y"]}, {0, tauInvB["Z", "X"]}, {1, tauInvB["Y", "X"]}}]},
   "R4: a strand over a box" -> {LD[{"X", "Y"}, {{0, tauB["X", "Y"]}, {1, B["f", {"X"}, {"X"}]}}], LD[{"X", "Y"}, {{0, B["f", {"X"}, {"X"}]}, {0, tauB["X", "Y"]}}]},
   "R5: a strand under a box" -> {LD[{"X", "Y"}, {{0, tauInvB["Y", "X"]}, {1, B["f", {"X"}, {"X"}]}}], LD[{"X", "Y"}, {{0, B["f", {"X"}, {"X"}]}, {0, tauInvB["Y", "X"]}}]},
   "Lemma 3.1, an upward strand: a crossing of X* passes a box" -> {LD[{"X*", "Y"}, {{0, tauB["X*", "Y"]}, {0, B["g", {"Y"}, {"Y"}]}}],
      LD[{"X*", "Y"}, {{1, B["g", {"Y"}, {"Y"}]}, {0, tauB["X*", "Y"]}}]}|>;
(* §3.1.2 symmetries, Remark 3.2.3 *)
sy = <|"\[Tau]_Y,X \[Tau]_X,Y = id" -> {LD[{"X", "Y"}, {{0, tauB["X", "Y"]}, {0, tauB["Y", "X"]}}], idL[{"X", "Y"}]},
    "Remark 3.2.3: over and under passes agree" -> {LD[{"X", "Y"}, {{0, tauInvB["Y", "X"]}}], LD[{"X", "Y"}, {{0, tauB["X", "Y"]}}]}|>;
(* §3.1.7 the mirror braiding τ̄_X,Y = τ⁻¹_Y,X also satisfies (3.1), (3.2) and Yang–Baxter *)
mirror[ld_LD] := ld /. {B[Subscript["\[Tau]", s_String], i_, o_] :> With[{xy = StringSplit[s, ",", 2]}, B[tauInv[xy[[2]], xy[[1]]], i, o]],
     B[Subscript[Superscript["\[Tau]", "-1"], s_String], i_, o_] :> With[{yx = StringSplit[s, ",", 2]}, B[tau[yx[[2]], yx[[1]]], i, o]]};


(* ::Section:: *)
(* 55. Checking: rules and the graded model *)

byRulesB[{l__}, rs_: rulesDB] := SameQ @@ (simplifyLD[#, rs] & /@ {l});
stepsKeepG[ld_, rs_: rulesDB, q_: qG, gr_: grG] := Equal @@ (mG[#[[2]], q, gr] & /@ simplifyTrace[ld, rs]);

(* © Computational Classnotes · CC BY-NC-SA 4.0 *)
