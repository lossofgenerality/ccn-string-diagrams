(* ::Package:: *)
(* Chapter 4 (Turaev & Virelizier, pp. 69–87): §4.3.2, Lemma 4.2, §4.5.2 Lemma 4.6, §4.6 enriched graphical calculus, §4.7 Lemmas 4.8–4.10 *)
(* Sections 70–79: a matrix model of a pivotal fusion category in which every statement and every proof step is checked.
   Needs the engine (sections 0–19) for LD, B and rows; all files live in Desktop/Research/Monoidal Graphical Calculus. *)


(* ::Section:: *)
(* 70. The model: graded vector spaces with a pivotal structure *)

(* Objects are graded vector spaces: a colour is a list of grades, one per basis vector. The simple objects are the
   one-dimensional spaces k_g, so I = the grading group. A character w gives the pivotal structure: ev and coev are the
   plain pairings, ẽv_X and c̃oev_X carry w(g) and 1/w(g) on a basis vector of grade g, so dim_l(k_g) = 1/w(g) and
   dim_r(k_g) = w(g). With w(g) = 2^g the category is pivotal and not spherical, so every dimension factor in §4.7 is
   really tested. The braiding is τ(e_a ⊗ e_b) = q^(g_a g_b) e_b ⊗ e_a. The editor identifies X** with X, so a starred
   colour gets the swapped structure: ev_X* = ẽv_X, ẽv_X* = ev_X, coev_X* = c̃oev_X, c̃oev_X* = coev_X. *)

fMod = 0;  fw = 2;  fq = 3;                          (* the group Z (fMod = 0) or Z/n (fMod = n); weight base; braiding base *)
fGr = <|"X" -> {0, 1, 1, 2}, "Y" -> {1, -1, 0}, "W" -> {2, 2, 0, 1}, "i" -> {1}, "j" -> {2}, "k" -> {-1}, "n" -> {1}|>;
fI = Range[-4, 6];                                   (* the simple objects k_g that sums over I run through *)
fUnit = "\[DoubleStruckOne]";
gnorm[g_] := If[fMod == 0, g, Mod[g, fMod]];
fStarQ[c_String] := StringEndsQ[c, "*"];
fStar[c_String] := If[fStarQ[c], StringDrop[c, -1], c <> "*"];
fBase[c_String] := StringReplace[c, "*" -> ""];
fParity[c_String] := Mod[StringCount[c, "*"], 2];
fGrades[c_String] := If[fParity[c] == 1, gnorm /@ (-fGr[fBase[c]]), gnorm /@ fGr[fBase[c]]];
fDim[c_String] := Length[fGrades[c]];
fDims[cs_List] := Times @@ (fDim /@ cs);
fWt[g_] := fw^g;
fBasis[cs_List] := Tuples[Range /@ (fDim /@ cs)];      (* basis of a tensor product, first colour most significant *)
fGradeOf[cs_List, idx_List] := gnorm[Total[MapThread[fGrades[#1][[#2]] &, {cs, idx}]]];
fSimpleGrade[c_String] := If[c === fUnit, 0, First[fGrades[c]]];

(* the four caps and cups *)
fEv[x_] := With[{g = fGrades[x], n = fDim[x]}, {Flatten[Table[If[a == b, If[fParity[x] == 0, 1, fWt[-g[[a]]]], 0], {a, n}, {b, n}]]}];   (* x* ⊗ x → 𝟙 *)
fEvt[x_] := With[{g = fGrades[x], n = fDim[x]}, {Flatten[Table[If[a == b, If[fParity[x] == 0, fWt[g[[a]]], 1], 0], {a, n}, {b, n}]]}];   (* x ⊗ x* → 𝟙 *)
fCoev[x_] := With[{g = fGrades[x], n = fDim[x]}, Transpose[{Flatten[Table[If[a == b, If[fParity[x] == 0, 1, fWt[g[[a]]]], 0], {a, n}, {b, n}]]}]];   (* 𝟙 → x ⊗ x* *)
fCoevt[x_] := With[{g = fGrades[x], n = fDim[x]}, Transpose[{Flatten[Table[If[a == b, If[fParity[x] == 0, fWt[-g[[a]]], 1], 0], {a, n}, {b, n}]]}]];   (* 𝟙 → x* ⊗ x *)
fFlip[x_, y_, s_] := With[{gx = fGrades[x], gy = fGrades[y], nx = fDim[x], ny = fDim[y]},
   Normal[SparseArray[Flatten[Table[{(b - 1) nx + a, (a - 1) ny + b} -> fq^(s gx[[a]] gy[[b]]), {a, nx}, {b, ny}]], {nx ny, nx ny}]]];

(* random morphisms that respect the grading *)
fRandom[dom_List, cod_List] := Table[If[fGradeOf[cod, o] == fGradeOf[dom, i], RandomInteger[{-3, 3}], 0], {o, fBasis[cod]}, {i, fBasis[dom]}];


(* ::Section:: *)
(* 71. Partition pairs (§4.4.1, §4.6.1) and the evaluation of a quasi-diagram *)

(* A pair is declared as tag -> {W, i}: an i-partition of W = X1 ⊗ ... ⊗ Xn (i simple, or fUnit for a 1-partition).
   Its boxes are B[Subscript["p", tag], W, {i}] (the semi-disk p_α : W → i) and B[Subscript["q", tag], {i}, W]
   (the compressed rectangle q_α : i → W); for i = 𝟙 the i-arc is erased. The pair stands for Σ_α p_α ⊗ q_α, so a
   quasi-diagram is evaluated as the sum over the basis vectors α of Hom(W, i) for every pair, as in (4.4)–(4.6):
   p_α is the coordinate of the basis vector α of grade g_i, q_α its inclusion. *)

fPairs = <||>;
pB[t_] := With[{d = fPairs[t]}, B[Subscript["p", t], d[[1]], If[d[[2]] === fUnit, {}, {d[[2]]}]]];
qB[t_] := With[{d = fPairs[t]}, B[Subscript["q", t], If[d[[2]] === fUnit, {}, {d[[2]]}], d[[1]]]];
fAlphas[t_] := With[{d = fPairs[t]}, Select[fBasis[d[[1]]], fGradeOf[d[[1]], #] == fSimpleGrade[d[[2]]] &]];
fN[i_String, ws_List] := Count[fBasis[ws], v_ /; fGradeOf[ws, v] == fSimpleGrade[i]];   (* the multiplicity index N^i_W *)
fMats = <||>;

fBoxMat[b_B, env_] := With[{s = b[[1]], in = b[[2]], out = b[[3]]},
   Which[
    MatchQ[s, Subscript["ev", _]], fEv[s[[2]]],
    MatchQ[s, Subscript[OverTilde["ev"], _]], fEvt[s[[2]]],
    MatchQ[s, Subscript["coev", _]], fCoev[s[[2]]],
    MatchQ[s, Subscript[OverTilde["coev"], _]], fCoevt[s[[2]]],
    MatchQ[s, Subscript["\[Tau]", _]] && Length[in] == 2, fFlip[in[[1]], in[[2]], 1],
    MatchQ[s, Subscript[Superscript["\[Tau]", "-1"], _]] && Length[in] == 2, fFlip[in[[1]], in[[2]], -1],
    MatchQ[s, Subscript["p", _]], With[{al = env[s[[2]]], bs = fBasis[in]}, {Boole[# === al] & /@ bs}],
    MatchQ[s, Subscript["q", _]], With[{al = env[s[[2]]], bs = fBasis[out]}, Transpose[{Boole[# === al] & /@ bs}]],
    s === "id", IdentityMatrix[fDims[in]],
    KeyExistsQ[fMats, s], fMats[s],
    True, (fMats[s] = fRandom[in, out])]];
fEvalEnv[ld_LD, env_] := Module[{rs = rows[ld], m},
   m = IdentityMatrix[fDims[First[rs]]];
   Do[With[{a = ld[[2, k, 1]], b = ld[[2, k, 2]], row = rs[[k]]},
     m = KroneckerProduct[IdentityMatrix[fDims[Take[row, a]]], fBoxMat[b, env], IdentityMatrix[fDims[Drop[row, a + Length[b[[2]]]]]]] . m], {k, Length[ld[[2]]]}];
   m];
fTags[ld_LD] := DeleteDuplicates[Cases[ld[[2]], B[Subscript["p" | "q", t_], __] :> t, Infinity]];
fEval[ld_LD] := With[{ts = fTags[ld]},
   If[ts === {}, fEvalEnv[ld, <||>],
    Total[fEvalEnv[ld, AssociationThread[ts, #]] & /@ Tuples[fAlphas /@ ts]] /. 0 -> 0]];
fEval0[ld_LD] := With[{m = fEval[ld]}, If[m === 0, ConstantArray[0, {fDims[Last[rows[ld]]], fDims[First[rows[ld]]]}], m]];

(* terms of the enriched calculus: {coefficient, {summation variables}, LD}. Scalars: dl[c], dr[c], NN[i, W], del[i, j], a[i] *)
fScalar[e_] := e /. {dl[c_String] :> Total[fWt[-#] & /@ fGrades[c]], dr[c_String] :> Total[fWt /@ fGrades[c]],
     NN[i_String, ws_List] :> fN[i, ws], del[i_String, j_String] :> Boole[fSimpleGrade[i] == fSimpleGrade[j]],
     delo[i_String, j_String] :> Boole[gnorm[-fSimpleGrade[i]] == fSimpleGrade[j]], a[c_String] :> fA[fSimpleGrade[c]]};
fA[g_] := fA[g] = RandomInteger[{1, 9}];
fTerm[{c_, {}, ld_LD}] := fScalar[c] fEval0[ld];
fTerm[{c_, {v_, rest___}, ld_LD}] := Total[Table[Block[{fGr = Append[fGr, v -> {g}], fPairs = fPairs},
     fTerm[{c, {rest}, ld}]], {g, fI}]];
fSum[terms_List] := Total[fTerm /@ terms];
fEqual[l_List, r_List] := (Expand[fSum[l] - fSum[r]] // Flatten // Union) === {0};
fEqualAll[sides_List] := And @@ (fEqual[First[sides], #] & /@ Rest[sides]);


(* ::Section:: *)
(* 72. Building diagrams: composition (bottom first) and tensor products of boxes *)

ev[x_] := B[Subscript["ev", x], {fStar[x], x}, {}];  evt[x_] := B[Subscript[OverTilde["ev"], x], {x, fStar[x]}, {}];
coev[x_] := B[Subscript["coev", x], {}, {x, fStar[x]}];  coevt[x_] := B[Subscript[OverTilde["coev"], x], {}, {fStar[x], x}];
tauF[x_, y_] := B[Subscript["\[Tau]", x <> "," <> y], {x, y}, {y, x}];
box[f_, d_List, c_List] := B[f, d, c];
idc[cs___String] := {"id", {cs}};
(* an expression: a box B[...], {"id", colours}, tens[e1, e2, ...] or comp[e1, e2, ...] with e1 applied first *)
fDom[b_B] := b[[2]];  fCod[b_B] := b[[3]];  fDom[{"id", cs_}] := cs;  fCod[{"id", cs_}] := cs;
fDom[tens[es__]] := Join @@ (fDom /@ {es});  fCod[tens[es__]] := Join @@ (fCod /@ {es});
fDom[comp[es__]] := fDom[First[{es}]];  fCod[comp[es__]] := fCod[Last[{es}]];
fLayers[b_B] := {{0, b}};  fLayers[{"id", _}] := {};
fLayers[comp[es__]] := Join @@ (fLayers /@ {es});
fLayers[tens[es__]] := Module[{off = 0, out = {}, es2 = {es}},
   Do[out = Join[out, {#[[1]] + off, #[[2]]} & /@ fLayers[es2[[k]]]]; off += Length[fCod[es2[[k]]]], {k, Length[es2]}];
   out];
toLD4[e_] := LD[fDom[e], fLayers[e]];
T[c_, e_] := {c, {}, toLD4[e]};  TS[c_, vs_List, e_] := {c, vs, toLD4[e]};



(* ::Section:: *)
(* 73. §4.3.2 and Lemma 4.2 *)

(* ω_S(α ⊗ β) = ev_S(α ⊗ β) is unchanged when the closed diagram is turned through 180°: ω_((X,−),(Y,+))(α ⊗ β) = ω_((Y,−),(X,+))(β ⊗ α) *)
alB = box["\[Alpha]", {}, {"Y*", "X"}];  beB = box["\[Beta]", {}, {"X*", "Y"}];
omega432 = {T[1, comp[tens[alB, beB], tens[idc["Y*"], evt["X"], idc["Y"]], ev["Y"]]], T[1, comp[tens[beB, alB], tens[idc["X*"], evt["Y"], idc["X"]], ev["X"]]]};
hB = box["h", {"i"}, {"i"}];
trLc[c_, f_] := comp[coevt[c], tens[idc[fStar[c]], f], ev[c]];  trRc[c_, f_] := comp[coev[c], tens[f, idc[fStar[c]]], evt[c]];
lemma42 = <|
   "(a) \[Omega]_S(coev_i \[CircleTimes] coev_i) = dim_r(i)" -> {T[1, comp[tens[coev["i"], coev["i"]], tens[idc["i"], ev["i"], idc["i*"]], evt["i"]]], T[1, trRc["i", idc["i"]]], T[dr["i"], idc[]]},
   "(a) with S = ((i,\[Minus]),(i,+)): dim_l(i)" -> {T[1, comp[tens[coevt["i"], coevt["i"]], tens[idc["i*"], evt["i"], idc["i"]], ev["i"]]], T[dl["i"], idc[]]},
   "(b) f = dim_l(i)\:207b\:00b9 tr_l(f) id_i" -> {T[1, hB], T[dl["i"]^-1, tens[idc["i"], trLc["i", hB]]]},
   "(b) f = dim_r(i)\:207b\:00b9 tr_r(f) id_i" -> {T[1, hB], T[dr["i"]^-1, tens[idc["i"], trRc["i", hB]]]},
   "(4.2) dim_l(i) tr_r(f) = dim_r(i) tr_l(f)" -> {T[dl["i"], trRc["i", hB]], T[dr["i"], trLc["i", hB]]}|>;


(* ::Section:: *)
(* 74. §4.6.3: (4.7)–(4.10) *)

fPairs = <|"a" -> {{"X"}, "i"}, "u" -> {{"X"}, fUnit}|>;
fB = box["f", {}, {"X"}];  gB = box["g", {"X"}, {}];
props463 = <|
   "(4.7) p q = N^i_X id_i" -> {T[1, comp[qB["a"], pB["a"]]], T[NN["i", {"X"}], idc["i"]]},
   "(4.8) \[Sum]_i q p = id_X" -> {TS[1, {"i"}, comp[pB["a"], qB["a"]]], T[1, idc["X"]]},
   "(4.9) q p f = f" -> {T[1, comp[fB, pB["u"], qB["u"]]], T[1, fB]},
   "(4.9) g q p = g" -> {T[1, comp[pB["u"], qB["u"], gB]], T[1, gB]},
   "(4.10) dim_l(X) = \[Sum]_i dim_l(i) N^i_X" -> {T[1, comp[coevt["X"], ev["X"]]], TS[1, {"i"}, trLc["X", comp[pB["a"], qB["a"]]]],
      TS[1, {"i"}, trLc["i", comp[qB["a"], pB["a"]]]], TS[NN["i", {"X"}], {"i"}, trLc["i", idc["i"]]], TS[dl["i"] NN["i", {"X"}], {"i"}, idc[]]},
   "(4.10) dim_r(X) = \[Sum]_i dim_r(i) N^i_X" -> {T[1, comp[coev["X"], evt["X"]]], TS[1, {"i"}, trRc["X", comp[pB["a"], qB["a"]]]],
      TS[1, {"i"}, trRc["i", comp[qB["a"], pB["a"]]]], TS[dr["i"] NN["i", {"X"}], {"i"}, idc[]]}|>;


(* ::Section:: *)
(* 75. Lemma 4.8: the contraction vector of ω_S *)

lemma48pairs = <|"u" -> {{"X"}, fUnit}, "v" -> {{"X", "Y*"}, fUnit}|>;
lemma48 = Block[{fPairs = lemma48pairs},
   With[{f1 = box["f1", {}, {"X"}], g1 = box["g1", {}, {"X*"}], f2 = box["f2", {}, {"X", "Y*"}], g2 = box["g2", {}, {"Y", "X*"}],
     pbent1 = comp[coevt["X"], tens[idc["X*"], pB["u"]]],
     pbent2 = comp[coev["Y"], tens[idc["Y"], coevt["X"], idc["Y*"]], tens[idc["Y", "X*"], pB["v"]]],
     evS2 = comp[tens[idc["Y"], ev["X"], idc["Y*"]], evt["Y"]]},
    <|"S = (X,+): (id \[CircleTimes] \[Omega]_S)(\[Star]_S \[CircleTimes] f) = f" -> {T[1, tens[qB["u"], comp[tens[pbent1, f1], ev["X"]]]], T[1, comp[f1, pB["u"], qB["u"]]], T[1, f1]},
     "S = (X,+): (\[Omega]_S \[CircleTimes] id)(g \[CircleTimes] \[Star]_S) = g" -> {T[1, tens[comp[tens[g1, qB["u"]], ev["X"]], pbent1]], T[1, g1]},
     "S = ((X,+),(Y,\[Minus])): (id \[CircleTimes] \[Omega]_S)(\[Star]_S \[CircleTimes] f) = f" -> {T[1, tens[qB["v"], comp[tens[pbent2, f2], evS2]]], T[1, comp[f2, pB["v"], qB["v"]]], T[1, f2]},
     "S = ((X,+),(Y,\[Minus])): (\[Omega]_S \[CircleTimes] id)(g \[CircleTimes] \[Star]_S) = g" -> {T[1, tens[comp[tens[g2, qB["v"]], evS2], pbent2]], T[1, g2]}|>]];


(* ::Section:: *)
(* 76. Lemma 4.9 *)

lemma49pairs = <|"b" -> {{"i"}, "j"}, "b2" -> {{"i"}, "n"}, "c" -> {{"i*"}, "k"}, "c2" -> {{"i*"}, "j"},
   "d" -> {{"i*", "j"}, fUnit}, "d2" -> {{"i*", "n"}, fUnit}, "e" -> {{"i", "j*"}, fUnit}, "e2" -> {{"i", "n*"}, fUnit},
   "a2" -> {{"X"}, "i"}, "o" -> {{"i*", "X"}, fUnit}, "o2" -> {{"X", "i*"}, fUnit},
   "ei" -> {{"k*", "j", "W*"}, "i"}, "ej" -> {{"k", "i", "W"}, "j"}, "fi" -> {{"W*", "j", "k*"}, "i"}, "fj" -> {{"W", "i", "k"}, "j"},
   "gA" -> {{"X"}, "j"}, "gB" -> {{"j", "Y"}, "i"}, "gC" -> {{"X", "Y"}, "i"}, "gA2" -> {{"Y"}, "j"}, "gB2" -> {{"X", "j"}, "i"}|>;
fMats["\[Phi]"] = {{5}};  fMats["\[Phi]\:207b\:00b9"] = {{1/5}};
lemma49 = Block[{fPairs = lemma49pairs},
   <|"(a) i \[NotEqual] j" -> {T[1, tens[pB["b"], qB["b"]]], T[del["i", "j"], idc["i", "i"]]},
     "(a) i = j" -> {T[1, tens[pB["b2"], qB["b2"]]], T[del["i", "n"], idc["i", "i"]]},
     "(a) i* \[TildeEqual] j" -> {T[1, tens[pB["c"], qB["c"]]], T[delo["i", "k"], tens[box["\[Phi]", {"i*"}, {"k"}], box["\[Phi]\:207b\:00b9", {"k"}, {"i*"}]]]},
     "(a) i* \[NotTilde] j" -> {T[1, tens[pB["c2"], qB["c2"]]], T[delo["i", "j"], tens[box["\[Phi]", {"i*"}, {"j"}], box["\[Phi]\:207b\:00b9", {"j"}, {"i*"}]]]},
     "(b) i \[NotEqual] j" -> {T[1, tens[pB["d"], qB["d"]]], T[del["i", "j"] dl["i"]^-1, tens[ev["i"], coevt["i"]]]},
     "(b) i = j" -> {T[1, tens[pB["d2"], qB["d2"]]], T[del["i", "n"] dl["i"]^-1, tens[ev["i"], coevt["i"]]]},
     "(c) i \[NotEqual] j" -> {T[1, tens[pB["e"], qB["e"]]], T[del["i", "j"] dr["i"]^-1, tens[evt["i"], coev["i"]]]},
     "(c) i = j" -> {T[1, tens[pB["e2"], qB["e2"]]], T[del["i", "n"] dr["i"]^-1, tens[evt["i"], coev["i"]]]},
     "(d)" -> {T[1, tens[pB["a2"], qB["a2"]]],
        T[dl["i"], tens[comp[tens[coev["i"], idc["X"]], tens[idc["i"], pB["o"]]], comp[tens[idc["i"], qB["o"]], tens[evt["i"], idc["X"]]]]],
        T[dr["i"], tens[comp[tens[idc["X"], coevt["i"]], tens[pB["o2"], idc["i"]]], comp[tens[qB["o2"], idc["i"]], tens[idc["X"], ev["i"]]]]]},
     "(e)" -> {T[1, tens[comp[tens[idc["k"], qB["ei"], idc["W"]], tens[evt["k"], idc["j"], ev["W"]]], comp[tens[coev["k"], idc["j"], coevt["W"]], tens[idc["k"], pB["ei"], idc["W"]]]]],
        T[dr["i"] dr["k"]/(dr["j"] dl["k"]), tens[pB["ej"], qB["ej"]]]},
     "(f)" -> {T[1, tens[comp[tens[idc["W"], qB["fi"], idc["k"]], tens[evt["W"], idc["j"], ev["k"]]], comp[tens[coev["W"], idc["j"], coevt["k"]], tens[idc["W"], pB["fi"], idc["k"]]]]],
        T[dl["i"] dl["k"]/(dl["j"] dr["k"]), tens[pB["fj"], qB["fj"]]]},
     "(g)" -> {TS[1, {"j"}, tens[comp[tens[pB["gA"], idc["Y"]], pB["gB"]], comp[qB["gB"], tens[qB["gA"], idc["Y"]]]]],
        T[1, tens[pB["gC"], qB["gC"]]],
        TS[1, {"j"}, tens[comp[tens[idc["X"], pB["gA2"]], pB["gB2"]], comp[qB["gB2"], tens[idc["X"], qB["gA2"]]]]]}|>];


(* ::Section:: *)
(* 77. Lemma 4.10 *)

(* f_j,k = a_k c̃oev_k ev_j and g_j,k = Σ_i a_i (q* ⊗ p)(id_j* ⊗ c̃oev_i ⊗ id_j), (p, q) a k-partition of i ⊗ j *)
qStar[t_, x_, y_, z_] := comp[tens[idc[fStar[y], fStar[x]], coev[z]], tens[idc[fStar[y], fStar[x]], qB[t], idc[fStar[z]]],
   tens[idc[fStar[y]], ev[x], idc[y], idc[fStar[z]]], tens[ev[y], idc[fStar[z]]]];     (* q : z → x ⊗ y, q* : y* ⊗ x* → z* *)
f410[j_, k_] := T[a[k], comp[ev[j], coevt[k]]];
g410[j_, k_] := TS[a["i"], {"i"}, comp[tens[idc[fStar[j]], coevt["i"], idc[j]], tens[qStar["h", "i", j, k], pB["h"]]]];
dualize410[{c_, vs_, ld_LD}, j_, k_] := {c, vs, toLD4[comp[tens[idc[k, fStar[j]], coev[j]], tens[idc[k], {"ld", ld}, idc[fStar[j]]], tens[evt[k], idc[k, fStar[j]]]]]};
fLayers[{"ld", l_LD}] := l[[2]];  fDom[{"ld", l_LD}] := l[[1]];  fCod[{"ld", l_LD}] := Last[rows[l]];
pairs410[j_, k_] := <|"h" -> {{"i", j}, k}, "r" -> {{k, fStar[j]}, "i"}|>;
lemma410[j_, k_] := Block[{fPairs = Join[fPairs, pairs410[j, k]]},
   <|"f = g" -> {{f410[j, k]}, {g410[j, k]}},
     "by duality: f \[LongLeftRightArrow] a_k id" -> {{dualize410[f410[j, k], j, k]}, {T[a[k], idc[k, fStar[j]]]}},
     "Lemma 4.9(e) step" -> {{dualize410[g410[j, k], j, k]}, {TS[a["i"] dr[k]/dr["i"], {"i"}, comp[pB["r"], qB["r"]]]}}|>];


(* ::Section:: *)
(* 78. Lemma 4.6 (S-matrix) and Lemma 4.7 in Z/n-graded models *)

(* Lemma 4.7 in Z/3 with w(g) = ω^g (pivotal fusion, not spherical): the proof as a chain of five equal numbers *)
lemma47[] := Block[{fMod = 3, fw = Exp[2 Pi I/3], fI = {0, 1, 2}, fGr = <|"X" -> {0, 1, 1, 2}, "Y" -> {1, 1, 0}, "m" -> {0}, "nn" -> {0}, "kk" -> {0}|>},
   Module[{lhs, dimC, sumI},
    sumI[v_, f_] := Total[Table[Block[{fGr = Append[fGr, v -> {g}]}, f[]], {g, fI}]];
    dimC = sumI["m", fScalar[dl["m"] dr["m"]] &];
    lhs[l_] := sumI["m", sumI["nn", fScalar[l["m"] l["nn"]] fN[fUnit, {"X", "m", "Y", "nn"}] &] &];
    <|"steps" -> FullSimplify /@ {lhs[dl],
        sumI["m", fScalar[dl["m"]] sumI["nn", fScalar[dr["nn*"]] fN["nn*", {"X", "m", "Y"}] &] &],
        sumI["m", fScalar[dl["m"]] sumI["kk", fScalar[dr["kk"]] fN["kk", {"X", "m", "Y"}] &] &],
        sumI["m", fScalar[dl["m"]] Total[fWt /@ Flatten[Outer[gnorm[#1 + #2 + #3] &, fGrades["X"], fGrades["m"], fGrades["Y"]]]] &],
        fScalar[dr["X"] dr["Y"]] dimC},
     "exchanged" -> FullSimplify /@ {lhs[dr], fScalar[dl["X"] dl["Y"]] dimC}|>]];
(* Lemma 4.6 in the modular category of Z/n-graded vector spaces, n odd, braiding ζ^(gh) flip with ζ = e^(2πi/n), spherical (w = 1) *)
curlS = toLD4[comp[tens[coevt["s"], idc["s"]], tens[idc["s*"], tauF["s", "s"]], tens[ev["s"], idc["s"]]]];
lemma46[n_] := Block[{fMod = n, fw = 1, fq = Exp[2 Pi I/n], fI = Range[0, n - 1], fGr = <||>},
   Module[{v, S, dim, dimC, dp, dm},
    v = Table[Block[{fGr = <|"s" -> {g}|>}, fEval0[curlS][[1, 1]]], {g, fI}];                                 (* twist scalars v_i *)
    S = Table[Block[{fGr = <|"s" -> {g}, "t" -> {h}|>}, Tr[fFlip["t", "s", 1] . fFlip["s", "t", 1]]], {g, fI}, {h, fI}];   (* S_i,j = tr(τ_j,i τ_i,j) *)
    dim = ConstantArray[1, n]; dimC = Total[dim^2]; dp = Total[v dim^2]; dm = Total[dim^2/v];
    <|"S invertible (modular)" -> (FullSimplify[Det[S]] =!= 0),
      "(a) \[Sum]_j S_i,j S_j,r = dim(C) \[Delta]_i\[SmallCircle],r" -> (Union[Flatten[Table[FullSimplify[Sum[S[[i, j]] S[[j, r]], {j, n}] - dimC Boole[Mod[i + r - 2, n] == 0]], {i, n}, {r, n}]]] === {0}),
      "\[CapitalDelta]+ \[CapitalDelta]- = dim(C)" -> (FullSimplify[dp dm - dimC] == 0),
      "(b) as printed: \[Sum]_j v_i v_j dim(j) S_i,j = dim(C) dim(i)" -> (Union[Table[FullSimplify[Sum[v[[i]] v[[j]] dim[[j]] S[[i, j]], {j, n}] - dimC dim[[i]]], {i, n}]] === {0}),
      "(b) with \[CapitalDelta]+: \[Sum]_j v_i v_j dim(j) S_i,j = \[CapitalDelta]+ dim(i)" -> (Union[Table[FullSimplify[Sum[v[[i]] v[[j]] dim[[j]] S[[i, j]], {j, n}] - dp dim[[i]]], {i, n}]] === {0}),
      "\[CapitalDelta]+" -> FullSimplify[dp]|>]];

(* ::Section:: *)
(* 79. Checking *)

pairs463 = <|"a" -> {{"X"}, "i"}, "u" -> {{"X"}, fUnit}|>;
withPairs[ps_, expr_] := Block[{fPairs = ps}, expr];
SetAttributes[withPairs, HoldRest];
chkList[ps_, assoc_] := withPairs[ps, KeyValueMap[#1 -> fEqualAll[List /@ #2] &, assoc]];
chk410[j_, k_] := Block[{fPairs = pairs410[j, k]}, KeyValueMap[#1 -> fEqual @@ #2 &, lemma410[j, k]]];

(* © Computational Classnotes · CC BY-NC-SA 4.0 *)
