(* ::Package:: *)
(* Chapter 4 rules for the GraphicalCalculusKernel: the enriched graphical calculus of a pivotal pre-fusion category
   (Turaev & Virelizier §4.3.2, Lemma 4.2, (4.7)–(4.10), Lemmas 4.8–4.9). Sections 80–84.
   The same rules, in the same order, as the editor's JavaScript engine (string-diagram-editor.html, "pre-fusion").
   Needs the engine (sections 0–19, 20–27, 30–35, 40–47, 50–55, 60–64) loaded first. *)


(* ::Section:: *)
(* 80. Terms, coefficients and names *)

(* A term is <|"c" -> coefficient, "sums" -> {i, ...}, "pairs" -> <|tag -> <|"W" -> {...}, "t" -> i|>|>, "ld" -> LD[...]|>.
   A coefficient is <|"n" -> n, "d" -> d, "at" -> <|atom -> power|>|> with atoms "dl␁i", "dr␁i", "N␁i␁X⊗Y", "δ␁i␁j", "δo␁i␁j", "a:a␁i"
   (␁ = character 1), the same strings as in the editor. *)

lSep = FromCharacterCode[1];  lUnit = FromCharacterCode[120793];   (* 𝟙 as the editor sends it (U+1D7D9) *)
lSimples = {};  lBound = {};  lPhi = FromCharacterCode[966];   (* φ, as in the editor *)
lFlip[x_String] := If[StringEndsQ[x, "*"], StringDrop[x, -1], x <> "*"];
lBase[x_String] := StringReplace[x, RegularExpression["\\*+$"] -> ""];
lStarQ[x_String] := StringEndsQ[x, "*"];
lSimpleQ[x_String] := x === lUnit || MemberQ[lSimples, lBase[x]] || MemberQ[lBound, lBase[x]];
lSplit[k_String] := StringSplit[k, lSep, All];
lJoin[l_List] := StringRiffle[l, lSep];
lAtomNorm[k_String] := With[{p = lSplit[k]},
   Which[(p[[1]] === "dl" || p[[1]] === "dr") && lStarQ[p[[2]]], lJoin[{If[p[[1]] === "dl", "dr", "dl"], lBase[p[[2]]]}],
    p[[1]] === "\[Delta]" && ! OrderedQ[{p[[2]], p[[3]]}, cpLE], lJoin[{"\[Delta]", p[[3]], p[[2]]}],
    True, k]];
cpLE[a_String, b_String] := ! lLess[b, a];
lLess[a_String, b_String] := With[{x = ToCharacterCode[a, "UTF-16"], y = ToCharacterCode[b, "UTF-16"]},
   Catch[Do[If[x[[k]] != y[[k]], Throw[x[[k]] < y[[k]]]], {k, Min[Length[x], Length[y]]}]; Length[x] < Length[y]]];   (* JavaScript's < on strings *)
lCNorm[c_] := Module[{at = <||>, f},
   KeyValueMap[Function[{k0, p}, With[{k = lAtomNorm[k0], s = lSplit[lAtomNorm[k0]]},
      Which[s[[1]] === "\[Delta]" && s[[2]] === s[[3]], Null,
       (s[[1]] === "dl" || s[[1]] === "dr") && s[[2]] === lUnit, Null,
       s[[1]] === "N" && s[[2]] === lUnit && s[[3]] === "", Null,
       True, at[k] = Lookup[at, k, 0] + p; If[at[k] == 0, KeyDropFrom[at, k]]]]], c["at"]];
   Scan[If[StringMatchQ[#, RegularExpression["^\[Delta]o?\001.*"]] && at[#] > 0, at[#] = 1] &, Keys[at]];
   f = c["n"]/c["d"];
   <|"n" -> Numerator[f], "d" -> Denominator[f], "at" -> at|>];
lCMul[a_, b_] := Module[{at = a["at"]}, KeyValueMap[(at[#1] = Lookup[at, #1, 0] + #2) &, b["at"]];
   lCNorm[<|"n" -> a["n"] b["n"], "d" -> a["d"] b["d"], "at" -> at|>]];
lCAtom[h_String, xs___String] := lCNorm[<|"n" -> 1, "d" -> 1, "at" -> <|lJoin[{h, xs}] -> 1|>|>];
lCPow[c_, 1] := c;
lCPow[c_, p_Integer] := lCNorm[<|"n" -> If[p > 0, c["n"]^p, c["d"]^-p], "d" -> If[p > 0, c["d"]^p, c["n"]^-p], "at" -> (#*p & /@ c["at"])|>];

(* the editor's name of a box, and back *)
lName[Subscript["\[Tau]", x_String]] := "\[Tau]_{" <> x <> "}";
lName[Subscript[Superscript["\[Tau]", "-1"], x_String]] := "\[Tau]\:207b\:00b9_{" <> x <> "}";
lName[Subscript[Superscript["\[Psi]", "-1"], x_String]] := "\[Psi]\:207b\:00b9_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
lName[Subscript[OverTilde[h_String], x_String]] := h <> "~_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
lName[Subscript[h_String, x_String]] := h <> "_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
lName[s_String] := s;
lName[other_] := ToString[other, InputForm];
evSubL[b_B] := Replace[b[[1]], {Subscript["ev", x_String] :> x, _ -> Missing[]}];
coevSubL[b_B] := Replace[b[[1]], {Subscript["coev", x_String] :> x, _ -> Missing[]}];
evtSubL[b_B] := Replace[b[[1]], {Subscript[OverTilde["ev"], x_String] :> x, _ -> Missing[]}];
coevtSubL[b_B] := Replace[b[[1]], {Subscript[OverTilde["coev"], x_String] :> x, _ -> Missing[]}];
dualityQL[b_B] := MatchQ[b[[1]], Subscript["ev" | "coev" | OverTilde["ev"] | OverTilde["coev"], _String]];
objOfSubL[s_String] := Select[StringTrim /@ StringSplit[StringTrim[s, "{" | "}"], "\[CircleTimes]"], # =!= "" && # =!= "I" && # =!= "1" &];
evG[x_String] := B[Subscript["ev", x], {lFlip[x], x}, {}];  coevG[x_String] := B[Subscript["coev", x], {}, {x, lFlip[x]}];
evtG[x_String] := B[Subscript[OverTilde["ev"], x], {x, lFlip[x]}, {}];  coevtG[x_String] := B[Subscript[OverTilde["coev"], x], {}, {lFlip[x], x}];
pTagL[b_B] := If[StringQ[b[[1]]] && StringStartsQ[b[[1]], "p_"], StringDrop[b[[1]], 2], Missing[]];
qTagL[b_B] := If[StringQ[b[[1]]] && StringStartsQ[b[[1]], "q_"], StringDrop[b[[1]], 2], Missing[]];
partQL[b_B] := ! MissingQ[pTagL[b]] || ! MissingQ[qTagL[b]];
pBL[tag_, P_] := B["p_" <> tag, P["W"], If[P["t"] === lUnit, {}, {P["t"]}]];
qBL[tag_, P_] := B["q_" <> tag, If[P["t"] === lUnit, {}, {P["t"]}], P["W"]];
genQL[b_B] := True;


(* ::Section:: *)
(* 81. Renaming a simple object, and δ *)

lRe[v_String] := RegularExpression["(?<=[_{,\[CircleTimes]])" <> StringReplace[v, c : RegularExpression["[.*+?^${}()|\\[\\]\\\\]"] :> "\\" <> c] <> "(?=[*},\[CircleTimes]]|$)"];
lRenameColour[term_, v_String, w_String] := Module[{rc, rn, rB, at = <||>, pairs = <||>},
   rc[x_String] := Which[x === v, w, x === v <> "*", w <> "*", True, x];
   rn[s_String] := StringReplace[s, lRe[v] -> w];
   rB[B[s_, i_, o_]] := B[Replace[s, {Subscript[h_, x_String] :> Subscript[h, StringDrop[rn["_" <> x], 1]], x_String :> rn[x]}], rc /@ i, rc /@ o];
   KeyValueMap[Function[{k, p}, With[{sp = lSplit[k]}, With[{k2 = lJoin[Prepend[If[sp[[1]] === "N", StringRiffle[rc /@ StringSplit[#, "\[CircleTimes]"], "\[CircleTimes]"] & /@ Rest[sp], rc /@ Rest[sp]], sp[[1]]]]},
       at[k2] = Lookup[at, k2, 0] + p]]], term["c"]["at"]];
   KeyValueMap[(pairs[#1] = <|"W" -> (rc /@ #2["W"]), "t" -> rc[#2["t"]]|>) &, term["pairs"]];
   <|"c" -> lCNorm[<|"n" -> term["c"]["n"], "d" -> term["c"]["d"], "at" -> at|>], "sums" -> term["sums"],
     "pairs" -> pairs, "ld" -> LD[rc /@ term["ld"][[1]], {#[[1]], rB[#[[2]]]} & /@ term["ld"][[2]]]|>];
lNameStr[b_B] := With[{s = b[[1]]}, Replace[s, {Subscript[h_, x_String] :> "_" <> x, x_String :> x, _ -> ""}]];
lTermColours[term_] := Module[{s = {}},
   Scan[(s = Join[s, lBase /@ #]) &, rows[term["ld"]]];
   Scan[(s = Join[s, StringCases[lNameStr[#[[2]]], RegularExpression["[_{,\[CircleTimes]]([^_{},\[CircleTimes]*]+)"] -> "$1"]]) &, term["ld"][[2]]];
   KeyValueMap[(s = Join[s, lBase /@ #2["W"], {lBase[#2["t"]]}]) &, term["pairs"]];
   Scan[(s = Join[s, lBase /@ Flatten[StringSplit[#, "\[CircleTimes]"] & /@ Rest[lSplit[#]]]]) &, Keys[term["c"]["at"]]];
   DeleteDuplicates[s]];
lFreshVar[term_] := Module[{used = Join[lTermColours[term], term["sums"]]},
   Catch[Scan[If[! MemberQ[used, #] && ! MemberQ[lSimples, #], Throw[#]] &, {"i", "j", "k", "l", "m", "n", "r", "s"}];
    Module[{k = 1}, While[MemberQ[used, "i" <> ToString[k]], k++]; "i" <> ToString[k]]]];
lFreshTag[term_, t_String] := Module[{u = t <> "\[Prime]"}, While[KeyExistsQ[term["pairs"], u], u = u <> "\[Prime]"]; u];
lWithLd[term_, ls_] := Append[term, "ld" -> LD[term["ld"][[1]], ls]];
lDrop[pairs_, tag_] := KeyDrop[pairs, tag];
lIdentify[term_, u_String, w_String] := Which[u === w, term,
   MemberQ[term["sums"], w], lRenameColour[Append[term, "sums" -> DeleteCases[term["sums"], w]], w, u],
   MemberQ[term["sums"], u], lRenameColour[Append[term, "sums" -> DeleteCases[term["sums"], u]], u, w],
   True, With[{t2 = lRenameColour[term, w, u]}, Append[t2, "c" -> lCMul[t2["c"], lCAtom["\[Delta]", u, w]]]]];
lLayerOf[ls_, test_] := With[{p = FirstPosition[ls, l_ /; test[l[[2]]], Missing[], {1}, Heads -> False]}, If[MissingQ[p], 0, p[[1]]]];
lSplice[ls_, k_, rep_] := Join[Take[ls, k - 1], rep, Drop[ls, k]];


(* ::Section:: *)
(* 82. The rules *)

lDeltaRule[term_] := Catch[KeyValueMap[Function[{k, p}, With[{sp = lSplit[k]},
      If[sp[[1]] === "\[Delta]" && sp[[2]] =!= sp[[3]],
       With[{x = sp[[2]], y = sp[[3]]},
        If[MemberQ[term["sums"], x] || MemberQ[term["sums"], y],
         Throw[lIdentify[Append[term, "c" -> lCNorm[Append[term["c"], "at" -> KeyDrop[term["c"]["at"], k]]]], x, y]]];
        If[MemberQ[lTermColours[Append[term, "c" -> lCNorm[Append[term["c"], "at" -> KeyDrop[term["c"]["at"], k]]]]], y],
         Throw[lRenameColour[term, y, x]]]]]]], term["c"]["at"]]; $Failed];

lCapFor[l_String, r_String] := If[lStarQ[l], evG[r], evtG[l]];
lTurnPairing[term_] := Module[{ls = term["ld"][[2]], n},
   n = Length[ls];
   Catch[Do[With[{A = ls[[k]], Bl = ls[[k + 1]]},
      If[A[[2, 2]] === {} && Bl[[2, 2]] === {},
       With[{m = Length[A[[2, 3]]], oa = A[[2, 3]], ob = Bl[[2, 3]]},
        If[m > 0 && Length[ob] == m && Bl[[1]] == A[[1]] + m && lLess[lName[Bl[[2, 1]]], lName[A[[2, 1]]]] && k + 1 + m <= n,
         If[AllTrue[Range[0, m - 1], With[{c = ls[[k + 2 + #]]}, c[[1]] == A[[1]] + m - 1 - # && c[[2, 3]] === {} && c[[2, 2]] === {oa[[m - #]], ob[[# + 1]]} && dualityQL[c[[2]]]] &],
          Throw[lWithLd[term, Join[Take[ls, k - 1], {{A[[1]], Bl[[2]]}, {A[[1]] + m, A[[2]]}},
             Table[{A[[1]] + m - 1 - t, lCapFor[ob[[m - t]], oa[[t + 1]]]}, {t, 0, m - 1}], Drop[ls, k + 1 + m]]]]]]]]], {k, n - 1}]; $Failed]];

lEmptyLoop[ls_, k_] := If[k + 1 > Length[ls], $Failed, With[{c = ls[[k]], e = ls[[k + 1]]},
    If[c[[1]] =!= e[[1]], $Failed,
     With[{lt = ! MissingQ[coevtSubL[c[[2]]]] && ! MissingQ[evSubL[e[[2]]]] && coevtSubL[c[[2]]] === evSubL[e[[2]]],
       rt = ! MissingQ[coevSubL[c[[2]]]] && ! MissingQ[evtSubL[e[[2]]]] && coevSubL[c[[2]]] === evtSubL[e[[2]]]},
      If[! lt && ! rt, $Failed, With[{X = objOfSubL[If[lt, coevtSubL[c[[2]]], coevSubL[c[[2]]]]]}, If[Length[X] == 1, {lt, X[[1]]}, $Failed]]]]]]];
lDimSimple[term_] := With[{ls = term["ld"][[2]]}, Catch[Do[With[{L = lEmptyLoop[ls, k]},
      If[L =!= $Failed && lSimpleQ[L[[2]]],
       Throw[Append[lWithLd[term, Join[Take[ls, k - 1], Drop[ls, k + 1]]], "c" -> lCMul[term["c"], lCAtom[If[L[[1]], "dl", "dr"], L[[2]]]]]]]], {k, Length[ls] - 1}]; $Failed]];
lDims410[term_] := With[{ls = term["ld"][[2]]}, Catch[Do[With[{L = lEmptyLoop[ls, k]},
      If[L =!= $Failed && ! lSimpleQ[L[[2]]],
       With[{v = lFreshVar[term]},
        Throw[Join[lWithLd[term, Join[Take[ls, k - 1], Drop[ls, k + 1]]],
          <|"c" -> lCMul[term["c"], lCMul[lCAtom[If[L[[1]], "dl", "dr"], v], lCAtom["N", v, L[[2]]]]], "sums" -> Append[term["sums"], v]|>]]]]], {k, Length[ls] - 1}]; $Failed]];

(* two layers of one pair, brought together by level exchange *)
lAdjacentPair[term_, test_] := With[{ls = term["ld"][[2]]}, Catch[
    Do[If[i != j, With[{r = test[ls[[i, 2]], ls[[j, 2]], i < j]},
       If[r =!= $Failed, With[{adj = makeAdjacent[ls, Min[i, j], Max[i, j]]},
         If[adj =!= $Failed, With[{l = adj[[1]], p = adj[[2]]}, With[{res = r[l[[p]], l[[p + 1]], l, p]}, If[res =!= $Failed, Throw[res]]]]]]]]],
     {i, Length[ls]}, {j, Length[ls]}]; $Failed]];
lRule47[term_] := lAdjacentPair[term, Function[{b1, b2, up}, With[{t = qTagL[b1]},
     If[MissingQ[t] || ! KeyExistsQ[term["pairs"], t] || pTagL[b2] =!= t || ! up, $Failed,
      Function[{lq, lp, l, p}, If[lq[[1]] =!= lp[[1]], $Failed, With[{P = term["pairs"][t]},
         Join[lWithLd[term, Join[Take[l, p - 1], Drop[l, p + 1]]], <|"c" -> lCMul[term["c"], lCAtom["N", P["t"], StringRiffle[P["W"], "\[CircleTimes]"]]], "pairs" -> lDrop[term["pairs"], t]|>]]]]]]]];
lRule48[term_] := lAdjacentPair[term, Function[{b1, b2, up}, With[{t = pTagL[b1]},
     If[MissingQ[t] || ! KeyExistsQ[term["pairs"], t] || qTagL[b2] =!= t || ! up || ! MemberQ[term["sums"], term["pairs"][t]["t"]], $Failed,
      Function[{lp, lq, l, p}, If[lp[[1]] =!= lq[[1]], $Failed, With[{P = term["pairs"][t]},
         With[{t2 = Append[lWithLd[term, Join[Take[l, p - 1], Drop[l, p + 1]]], "pairs" -> lDrop[term["pairs"], t]]},
          If[MemberQ[lTermColours[t2], P["t"]], $Failed, Append[t2, "sums" -> DeleteCases[term["sums"], P["t"]]]]]]]]]]]];
lRule49[term_] := Module[{ls = term["ld"][[2]]}, Catch[KeyValueMap[Function[{t, P},
      If[P["t"] === lUnit, Module[{ip = lLayerOf[ls, pTagL[#] === t &], iq = lLayerOf[ls, qTagL[#] === t &]},
        If[ip > 0 && iq > 0, Do[If[k != ip && k != iq, With[{b = ls[[k, 2]]}, If[! partQL[b],
             If[b[[2]] === {} && b[[3]] === P["W"] && k < ip, With[{adj = makeAdjacent[ls, k, ip]},
               If[adj =!= $Failed, With[{l = adj[[1]], p = adj[[2]]}, If[l[[p, 1]] === l[[p + 1, 1]],
                  With[{rest = Join[Take[l, p - 1], Drop[l, p + 1]]}, With[{kq = lLayerOf[rest, qTagL[#] === t &]},
                    Throw[Append[lWithLd[term, lSplice[rest, kq, {{rest[[kq, 1]], b}}]], "pairs" -> lDrop[term["pairs"], t]]]]]]]]]];
             If[Length[P["W"]] == 1 && b[[2]] === {} && Length[b[[3]]] == 1 && k + 2 <= Length[ls],
              With[{x = P["W"][[1]], K = ls[[k + 2]]},
               If[iq == k + 1 && b[[3]] === {lFlip[x]} && ls[[iq, 1]] == ls[[k, 1]] + 1 && K[[1]] == ls[[k, 1]] && evSubL[K[[2]]] === x,
                With[{rest = Delete[ls, {{k}, {iq}, {k + 2}}]}, With[{kp = lLayerOf[rest, pTagL[#] === t &]}, With[{c = rest[[kp, 1]]},
                   Throw[Append[lWithLd[term, lSplice[rest, kp, {{c, b}, {c, K[[2]]}}]], "pairs" -> lDrop[term["pairs"], t]]]]]]]]];
             If[b[[3]] === {} && b[[2]] === P["W"] && k > iq, With[{adj = makeAdjacent[ls, iq, k]},
               If[adj =!= $Failed, With[{l = adj[[1]], p = adj[[2]]}, If[l[[p, 1]] === l[[p + 1, 1]],
                  With[{rest = Join[Take[l, p - 1], Drop[l, p + 1]]}, With[{kp = lLayerOf[rest, pTagL[#] === t &]},
                    Throw[Append[lWithLd[term, lSplice[rest, kp, {{rest[[kp, 1]], b}}]], "pairs" -> lDrop[term["pairs"], t]]]]]]]]]]]]], {k, Length[ls]}]]]]],
     term["pairs"]]; $Failed]];
lStraighten[term_] := Module[{ls = term["ld"][[2]], n}, n = Length[ls];
   Catch[Do[With[{C = ls[[k]]}, Module[{left, right, X, x, a, leg, capT, L, isB, isF, G, K, fPos},
       left = ! MissingQ[coevtSubL[C[[2]]]]; right = ! MissingQ[coevSubL[C[[2]]]];
       If[left || right,
        X = objOfSubL[If[left, coevtSubL[C[[2]]], coevSubL[C[[2]]]]];
        If[Length[X] == 1,
         x = X[[1]]; a = C[[1]]; leg = If[left, a + 1, a];
         capT = If[left, (evSubL[#] === x &), (evtSubL[#] === x &)];
         L = {ls[[k + 1]], ls[[k + 2]], If[k + 3 <= n, ls[[k + 3]], {-9, B["id", {}, {}]}]};
         isB = (#[[1]] == leg && #[[2, 2]] === {x} && #[[2, 3]] === {} &); isF = (#[[2, 2]] === {} && #[[2, 3]] === {x} &);
         G = ls[[k + 1]]; K = ls[[k + 2]];
         If[G[[2, 2]] === {} && Length[G[[2, 3]]] == 1 && G[[1]] == a + 1 && K[[2, 3]] === {},
          If[left && K[[1]] == a + 1 && evSubL[K[[2]]] === x && G[[2, 3]] === {lFlip[x]}, Throw[lWithLd[term, Join[Take[ls, k - 1], {{a, G[[2]]}}, Drop[ls, k + 2]]]]];
          If[right && K[[1]] == a && evtSubL[K[[2]]] === x && G[[2, 3]] === {lFlip[x]}, Throw[lWithLd[term, Join[Take[ls, k - 1], {{a, G[[2]]}}, Drop[ls, k + 2]]]]]];
         If[isB[L[[1]]] && isF[L[[2]]] && L[[2, 1]] == leg && L[[3, 1]] == a && capT[L[[3, 2]]],
          Throw[lWithLd[term, Join[Take[ls, k - 1], {{a, L[[2, 2]]}, {a, L[[1, 2]]}}, Drop[ls, k + 3]]]]];
         fPos = If[left, a + 2, a];
         If[isF[L[[1]]] && L[[1, 1]] == fPos && L[[2, 1]] == a && capT[L[[2, 2]]] && L[[3, 1]] == a && L[[3, 2, 2]] === {x} && L[[3, 2, 3]] === {},
          Throw[lWithLd[term, Join[Take[ls, k - 1], {{a, L[[1, 2]]}, {a, L[[3, 2]]}}, Drop[ls, k + 3]]]]]]]]], {k, n - 2}]; $Failed]];
lRule49a[term_] := Module[{ls = term["ld"][[2]]}, Catch[KeyValueMap[Function[{t, P},
      If[Length[P["W"]] == 1 && P["t"] =!= lUnit && lSimpleQ[P["W"][[1]]] && lSimpleQ[P["t"]],
       Module[{ip = lLayerOf[ls, pTagL[#] === t &], iq = lLayerOf[ls, qTagL[#] === t &], s = P["W"][[1]], j = P["t"]},
        If[ip > 0 && iq > 0,
         If[! lStarQ[s] || lStarQ[j],
          If[! (lStarQ[j] && ! lStarQ[s]),
           Throw[lIdentify[Append[lWithLd[term, Delete[ls, {{ip}, {iq}}]], "pairs" -> lDrop[term["pairs"], t]], lBase[s], lBase[j]]]],
          With[{i = lBase[s]}, With[{phi = B[lPhi <> "_{" <> i <> "," <> j <> "}", {s}, {j}], phiI = B[lPhi <> "\:207b\:00b9_{" <> i <> "," <> j <> "}", {j}, {s}]},
            Throw[Join[lWithLd[term, MapIndexed[Which[#2[[1]] == ip, {#1[[1]], phi}, #2[[1]] == iq, {#1[[1]], phiI}, True, #1] &, ls]],
              <|"pairs" -> lDrop[term["pairs"], t], "c" -> lCMul[term["c"], lCAtom["\[Delta]o", i, j]]|>]]]]]]]]], term["pairs"]]; $Failed]];
lRule49bc[left_][term_] := Module[{ls = term["ld"][[2]]}, Catch[KeyValueMap[Function[{t, P},
      If[P["t"] === lUnit && Length[P["W"]] == 2 && lSimpleQ[P["W"][[1]]] && lSimpleQ[P["W"][[2]]] &&
        If[left, lStarQ[P["W"][[1]]] && ! lStarQ[P["W"][[2]]], ! lStarQ[P["W"][[1]]] && lStarQ[P["W"][[2]]]],
       Module[{i = lBase[P["W"][[1]]], j = lBase[P["W"][[2]]], ip = lLayerOf[ls, pTagL[#] === t &], iq = lLayerOf[ls, qTagL[#] === t &], t2, m},
        If[ip > 0 && iq > 0,
         t2 = lIdentify[Append[term, "pairs" -> lDrop[term["pairs"], t]], i, j];
         m = Which[MemberQ[term["sums"], j], i, MemberQ[term["sums"], i], j, True, i];
         Throw[Append[lWithLd[t2, MapIndexed[Which[#2[[1]] == ip, {#1[[1]], If[left, evG[m], evtG[m]]}, #2[[1]] == iq, {#1[[1]], If[left, coevtG[m], coevG[m]]}, True, #1] &, t2["ld"][[2]]]],
           "c" -> lCMul[t2["c"], lCPow[lCAtom[If[left, "dl", "dr"], m], -1]]]]]]]], term["pairs"]]; $Failed]];
lRule49d[term_] := Module[{ls = term["ld"][[2]]}, Catch[KeyValueMap[Function[{t, P},
      If[P["t"] === lUnit && Length[P["W"]] >= 2,
       Module[{ip = lLayerOf[ls, pTagL[#] === t &], iq = lLayerOf[ls, qTagL[#] === t &], first = P["W"][[1]], last = P["W"][[-1]], left, right, i, W, u, NP, pa, qa, pRep, qRep, ls2},
        If[ip > 0 && iq > 0,
         left = lStarQ[first] && lSimpleQ[first]; right = ! left && lStarQ[last] && lSimpleQ[last];
         If[left || right,
          i = lBase[If[left, first, last]]; W = If[left, Rest[P["W"]], Most[P["W"]]];
          u = lFreshTag[term, t]; NP = <|"W" -> W, "t" -> i|>; pa = ls[[ip, 1]]; qa = ls[[iq, 1]];
          pRep = If[left, {{pa + 1, pBL[u, NP]}, {pa, evG[i]}}, {{pa, pBL[u, NP]}, {pa, evtG[i]}}];
          qRep = If[left, {{qa, coevtG[i]}, {qa + 1, qBL[u, NP]}}, {{qa, coevG[i]}, {qa, qBL[u, NP]}}];
          ls2 = If[ip < iq, lSplice[lSplice[ls, iq, qRep], ip, pRep], lSplice[lSplice[ls, ip, pRep], iq, qRep]];
          Throw[Join[lWithLd[term, ls2], <|"pairs" -> Append[lDrop[term["pairs"], t], u -> NP], "c" -> lCMul[term["c"], lCPow[lCAtom[If[left, "dl", "dr"], i], -1]]|>]]]]]]], term["pairs"]]; $Failed]];
lLoneLoop[ls_, k_] := If[k < 2 || k + 1 > Length[ls], None, With[{b = ls[[k]], c = ls[[k - 1]], e = ls[[k + 1]]},
    Which[c[[1]] =!= e[[1]], None,
     ! MissingQ[coevtSubL[c[[2]]]] && evSubL[e[[2]]] === coevtSubL[c[[2]]] && b[[1]] == c[[1]] + 1, "l",
     ! MissingQ[coevSubL[c[[2]]]] && evtSubL[e[[2]]] === coevSubL[c[[2]]] && b[[1]] == c[[1]], "r",
     True, None]]];
lEndoQ[b_B] := Length[b[[2]]] == 1 && b[[2]] === b[[3]] && lSimpleQ[b[[2, 1]]] && b[[2, 1]] =!= lUnit && ! dualityQL[b] && ! partQL[b];
lRule42b[term_] := With[{ls = term["ld"][[2]]}, Catch[Do[With[{b = ls[[k, 2]]},
      If[lEndoQ[b] && lLoneLoop[ls, k] === None,
       With[{x = b[[2, 1]], n = Length[Last[rows[term["ld"]]]]},
        Throw[Append[lWithLd[term, Join[Drop[ls, {k}], {{n, coevtG[x]}, {n + 1, b}, {n, evG[x]}}]], "c" -> lCMul[term["c"], lCPow[lCAtom["dl", x], -1]]]]]]], {k, Length[ls]}]; $Failed]];
lRule42[term_] := With[{ls = term["ld"][[2]]}, Catch[Do[
     If[lLoneLoop[ls, k] === "r" && lEndoQ[ls[[k, 2]]],
      With[{x = ls[[k, 2, 2, 1]], a = ls[[k - 1, 1]]},
       Throw[Append[lWithLd[term, Join[Take[ls, k - 2], {{a, coevtG[x]}, {a + 1, ls[[k, 2]]}, {a, evG[x]}}, Drop[ls, k + 1]]],
         "c" -> lCMul[term["c"], lCMul[lCPow[lCAtom["dl", x], -1], lCAtom["dr", x]]]]]]], {k, 2, Length[ls] - 1}]; $Failed]];

linRules = <|
   "\[Delta] substitution" -> {"term", lDeltaRule},
   "turning \[Omega]_S (\[Section]4.3.2, Theorem 2.6)" -> {"term", lTurnPairing},
   "Lemma 4.9(a)" -> {"term", lRule49a},
   "Lemma 4.9(b)" -> {"term", lRule49bc[True]},
   "Lemma 4.9(c)" -> {"term", lRule49bc[False]},
   "(4.9)" -> {"term", lRule49},
   "isotopy: straightening (Theorem 2.6)" -> {"term", lStraighten},
   "(4.7)" -> {"term", lRule47},
   "(4.8)" -> {"term", lRule48},
   "Lemma 4.9(d)" -> {"term", lRule49d},
   "dim_l(i), dim_r(i) of a simple object" -> {"term", lDimSimple},
   "(4.10)" -> {"term", lDims410},
   "(4.2)" -> {"term", lRule42},
   "Lemma 4.2(b)" -> {"term", lRule42b}|>;


(* ::Section:: *)
(* 83. Simplifying a term *)

withLin[rs_Association] := With[{k = Keys[rs], i = FirstPosition[Keys[rs], "trace symmetry (\[Section]2.6.1)"]},
   If[MissingQ[i], Join[rs, linRules],
    Join[AssociationThread[Take[k, i[[1]] - 1], Lookup[rs, Take[k, i[[1]] - 1]]], linRules, AssociationThread[Drop[k, i[[1]] - 1], Lookup[rs, Drop[k, i[[1]] - 1]]]]]];
lTidy[term_] := Module[{pairs = <||>},
   Scan[With[{g = If[! MissingQ[pTagL[#[[2]]]], pTagL[#[[2]]], qTagL[#[[2]]]]}, If[! MissingQ[g] && KeyExistsQ[term["pairs"], g] && ! KeyExistsQ[pairs, g], pairs[g] = term["pairs"][g]]] &, term["ld"][[2]]];
   Join[term, <|"c" -> lCNorm[term["c"]], "pairs" -> pairs|>]];
lRewriteOnce[term_, rs_Association] := Catch[KeyValueMap[Function[{name, spec},
      If[spec[[1]] === "term", With[{r = spec[[2]][term]}, If[r =!= $Failed, Throw[{name, r}]]],
       With[{r = rewriteOnce[term["ld"], <|name -> spec|>]}, If[MatchQ[r, {_String, _LD}], Throw[{name, Append[term, "ld" -> r[[2]]]}]]]]], rs]; $Failed];
lTrace[term0_, rs_] := Module[{cur, steps, r, seen},
   cur = lTidy[Append[term0, "ld" -> normalize[term0["ld"]]]];
   steps = {{"start", cur}}; seen = {cur};
   Do[lBound = cur["sums"]; r = lRewriteOnce[cur, rs];
    If[r === $Failed, Break[]];
    cur = lTidy[Append[r[[2]], "ld" -> normalize[r[[2]]["ld"]]]];
    AppendTo[steps, {r[[1]], cur}];
    If[MemberQ[seen, cur], Break[]]; AppendTo[seen, cur];
    If[cur["c"]["n"] == 0, Break[]], {60}];
   steps];

(* © Computational Classnotes · CC BY-NC-SA 4.0 *)
