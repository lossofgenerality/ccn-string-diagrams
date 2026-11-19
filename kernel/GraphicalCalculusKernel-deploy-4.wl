(* ::Package:: *)
(* GraphicalCalculusKernel: the Wolfram engine behind the "Wolfram kernel" option of string-diagram-editor.html.

   HOW TO DEPLOY
   1. Keep this file with the engine files in one folder, gcDir below (Desktop/Research/Monoidal Graphical Calculus).
      Check gcNotebook, gcPivotal, gcPenrose and gcDuals below: graphical-calculus-2.1-simplify.nb (sections 0–19,
      §2.1.1–2.1.2), pivotal-2.1.3.wl (sections 20–27, §2.1.3, which defines rulesP), penrose-2.2.wl (sections 30–35,
      §2.2, which defines rulesT), pivotal-2.3-2.7.wl (sections 40–47, §2.3–2.7, which defines rulesD and rulesS) and
      braided-2.7-3.2.wl (sections 50–55, §2.7.3 and §3.1–3.2, which defines rulesB, rulesDB, rulesSB) and
      ribbon-3.3.wl (sections 60–64, §3.3.1–3.3.3, which defines twistRules, ribbonRules and withTwists) and
      fusion-4-rules.wl (sections 80–83, Chapter 4, which defines linRules, withLin and lTrace), all in gcDir.
   2. Evaluate this whole file in one go: Get["…/GraphicalCalculusKernel-deploy.wl"], or paste it into one cell.
      If any check fails it stops before CloudDeploy, so a half-loaded kernel is never deployed.
      It loads the notebook's engine itself, so the engine and the API code always share one context.
      You do not need to evaluate the simplify notebook first.
   3. CloudDeploy copies every definition the API uses into the cloud object.
      Redeploying under the same name keeps the URL:
        https://www.wolframcloud.com/obj/ccn2/GraphicalCalculusKernel
      Paste a different URL into the page's "Wolfram kernel URL" field if yours differs.

   PROTOCOL (the same base64-JSON style as LaplacianLabKernel and CameraKernel)
   POST payload_b64 = base64 of UTF-8 JSON
     {"src": [colours], "ls": [{"a": n, "name": "f", "ins": [...], "outs": [...]}, ...],
      "pairings": [["ω","Ω"], ...], "inverses": [["u","u′"], ...], "retracts": [["p","j"], ...], "rightFirst": false, "pivotal": false,
      "spherical": false, "symmetric": false, "ribbon": false}
   pivotal: true uses rulesD (duals written X*, ẽv and c̃oev, Figures 2.2–2.4, the §2.2 rules for caps and cups on a
   tensor product, and the §2.3–2.6 rules: Lemma 2.3, ψ, trace symmetry, inverse boxes); with spherical: true it uses
   rulesS, which adds sphericity (§2.7.1). Otherwise it uses rules (§2.1.2, duals ∨X). Every set also has the braiding
   rules of §3.1–3.2 (rulesB, rulesDB, rulesSB); symmetric: true adds the symmetry rules of §3.1.2.
   Pivotal sets also get the twist rules of §3.3.1–3.3.3 (withTwists); ribbon: true adds θʳ = θˡ (§3.3.2) and,
   by Corollary 3.4, sphericity.
   prefusion: true (Chapter 4) sends one term of a linear combination: "c" (coefficient), "sums", "pairs" and "simples"
   besides src and ls; the reply steps then carry {"c", "sums", "pairs", "src", "ls"}. The rules of §4.3.2–4.7 (linRules)
   go in before trace symmetry.
   Reply JSON: {"steps_b64": base64 of [[rule, {"src": [...], "ls": [[a, name, ins, outs], ...]}], ...],
                "engine": "Wolfram 15."}   or   {"error": "..."}
   Names: "ev_X" <-> Subscript["ev","X"], "coev_X" <-> Subscript["coev","X"],
   "ev~_X" <-> Subscript[OverTilde["ev"],"X"] (ẽv), "coev~_X" <-> Subscript[OverTilde["coev"],"X"] (c̃oev),
   "ψ_X" <-> Subscript["ψ","X"], "ψ⁻¹_X" <-> Subscript[Superscript["ψ","-1"],"X"],
   "τ_{X,Y}" <-> Subscript["τ","X,Y"], "τ⁻¹_{Y,X}" <-> Subscript[Superscript["τ","-1"],"Y,X"],
   "θˡ_X" <-> Subscript["θˡ","X"], "θʳ⁻¹_X" <-> Subscript["θʳ⁻¹","X"] (the twists and their inverses);
   other names are plain strings.
   The API only runs the rewrite rules on the data it is sent (no code is evaluated), so it needs no key.

   By Dara O Shayda and Noor Hoshino (星野ヌール)
   © Computational Classnotes · CC BY-NC-SA 4.0 *)

(* Everything below lives in its own context, so the ClearAll["Global`*"] at the top of the notebooks
   cannot wipe the loader or the API code, even when this file is evaluated in a Global` notebook. *)
Begin["GraphicalCalculusKernel`"];
gcSavedPath = $ContextPath;
$ContextPath = {"System`"};   (* so leftover Global` symbols (rules, normalize, ...) are not picked up *)

gcDir = FileNameJoin[{$HomeDirectory, "Desktop", "Research", "Monoidal Graphical Calculus"}];
gcNotebook = FileNameJoin[{gcDir, "graphical-calculus-2.1-simplify.nb"}];
gcPivotal = FileNameJoin[{gcDir, "pivotal-2.1.3.wl"}];
gcPenrose = FileNameJoin[{gcDir, "penrose-2.2.wl"}];
gcDuals = FileNameJoin[{gcDir, "pivotal-2.3-2.7.wl"}];
gcBraid = FileNameJoin[{gcDir, "braided-2.7-3.2.wl"}];
gcRibbon = FileNameJoin[{gcDir, "ribbon-3.3.wl"}];
gcFusion = FileNameJoin[{gcDir, "fusion-4-rules.wl"}];

(* load the notebook's engine: evaluate its Input cells, in order, in the current context.
   Cells stored as text are read with Get; cells stored as boxes with ToExpression. With (not Module)
   puts the values straight into the code, so nothing here depends on a variable that could be cleared. *)
(* gcReady stays False unless every step below succeeds; CloudDeploy at the end runs only when it is True *)
gcReady = False;
If[! FileExistsQ[gcNotebook], Print["Notebook not found: ", gcNotebook],
 With[{cells = Cases[Get[gcNotebook], Cell[c_, "Input" | "Code", ___] :> c, Infinity], name = FileNameTake[gcNotebook]},
  Scan[Quiet@Check[TimeConstrained[If[StringQ[#], Get[StringToStream[#]], ToExpression[#, StandardForm]]; Null, 120], Null] &, cells];
  Print["Loaded ", Length[cells], " code cells from ", name]]];
If[! FileExistsQ[gcPivotal], Print["Pivotal package not found: ", gcPivotal],
 Quiet[Get[gcPivotal]]; Print["Loaded ", FileNameTake[gcPivotal]]];
If[! FileExistsQ[gcPenrose], Print["Penrose package not found: ", gcPenrose],
 Quiet[Get[gcPenrose]]; Print["Loaded ", FileNameTake[gcPenrose]]];
If[! FileExistsQ[gcDuals], Print["§2.3–2.7 package not found: ", gcDuals],
 Quiet[Get[gcDuals]]; Print["Loaded ", FileNameTake[gcDuals]]];
If[! FileExistsQ[gcBraid], Print["§3.1–3.2 package not found: ", gcBraid],
 Quiet[Get[gcBraid]]; Print["Loaded ", FileNameTake[gcBraid]]];
If[! FileExistsQ[gcRibbon], Print["§3.3 package not found: ", gcRibbon],
 Quiet[Get[gcRibbon]]; Print["Loaded ", FileNameTake[gcRibbon]]];
If[! FileExistsQ[gcFusion], Print["Chapter 4 package not found: ", gcFusion],
 Quiet[Get[gcFusion]]; Print["Loaded ", FileNameTake[gcFusion]]];
gcReady = AssociationQ[rules] && KeyExistsQ[rules, "(2.1) left zigzag"] && AssociationQ[rulesP] && AssociationQ[rulesT] &&
   AssociationQ[rulesD] && AssociationQ[rulesS] && AssociationQ[rulesB] && AssociationQ[rulesDB] && AssociationQ[rulesSB] && AssociationQ[twistRules] && AssociationQ[ribbonRules] && AssociationQ[linRules] &&
   Length[DownValues[normalize]] > 0 && Length[DownValues[rewriteOnce]] > 0;
If[! gcReady, Print["The engine (rules, rulesP, normalize, rewriteOnce) did not load in context ", $Context, ". Check gcNotebook, gcPivotal, gcPenrose, gcDuals, gcBraid, gcRibbon and gcFusion."]];

gcSym[s_String] := With[{m = StringCases[s, RegularExpression["^(ev|coev)(~?)_(.+)$"] -> {"$1", "$2", "$3"}]},
   Which[m =!= {}, Subscript[If[m[[1, 2]] === "~", OverTilde[m[[1, 1]]], m[[1, 1]]], StringTrim[m[[1, 3]], "{" | "}"]],
    StringStartsQ[s, "\[Tau]\:207b\:00b9_"], Subscript[Superscript["\[Tau]", "-1"], StringTrim[StringDrop[s, 4], "{" | "}"]],
    StringStartsQ[s, "\[Tau]_"], Subscript["\[Tau]", StringTrim[StringDrop[s, 2], "{" | "}"]],
    StringStartsQ[s, "\[Psi]\:207b\:00b9_"], Subscript[Superscript["\[Psi]", "-1"], StringTrim[StringDrop[s, 4], "{" | "}"]],
    StringStartsQ[s, "\[Psi]_"], Subscript["\[Psi]", StringTrim[StringDrop[s, 2], "{" | "}"]],
    StringMatchQ[s, RegularExpression["^\[Theta][\:02e1\:02b3](\:207b\:00b9)?_.+$"]],
     With[{k = First[StringPosition[s, "_"]][[1]]}, Subscript[StringTake[s, k - 1], StringTrim[StringDrop[s, k], "{" | "}"]]],
    True, s]];
gcName[Subscript["\[Tau]", x_String]] := "\[Tau]_{" <> x <> "}";
gcName[Subscript[Superscript["\[Tau]", "-1"], x_String]] := "\[Tau]\:207b\:00b9_{" <> x <> "}";
gcName[Subscript[Superscript["\[Psi]", "-1"], x_String]] := "\[Psi]\:207b\:00b9_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
gcName[Subscript[OverTilde[h_String], x_String]] := h <> "~_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
gcName[Subscript[h_String, x_String]] := h <> "_" <> If[StringContainsQ[x, "\[CircleTimes]"], "{" <> x <> "}", x];
gcName[s_String] := s;
gcName[other_] := ToString[other, InputForm];

gcToLD[j_Association] := LD[j["src"], {#["a"], B[gcSym[#["name"]], #["ins"], #["outs"]]} & /@ j["ls"]];
gcFromLD[LD[src_, ls_]] := <|"src" -> src, "ls" -> ({#[[1]], gcName[#[[2, 1]]], #[[2, 2]], #[[2, 3]]} & /@ ls)|>;

(* each layer must fit the strands below it *)
gcValidQ[LD[src_List, ls_List]] := Module[{w = src, ok = True},
   Do[With[{a = l[[1]], i = l[[2, 2]], o = l[[2, 3]]},
     If[! (IntegerQ[a] && 0 <= a && a + Length[i] <= Length[w] && Take[w, {a + 1, a + Length[i]}] === i), ok = False; Break[]];
     w = Join[Take[w, a], o, Drop[w, a + Length[i]]]], {l, ls}];
   ok];
gcValidQ[_] := False;

(* simplifyTrace, started from a layered form instead of a StringDiagram *)
gcTrace[ld_LD, rs_] := Module[{l = normalize[ld], steps, r},
   steps = {{"start", l}};
   If[! MatchQ[l, LD[_List, _List]], Return[$Failed]];
   While[MatchQ[r = rewriteOnce[l, rs], {_String, _LD}] && Length[steps] < 50,
    l = normalize[r[[2]]]; If[! MatchQ[l, LD[_List, _List]], Return[$Failed]]; AppendTo[steps, {r[[1]], l}]];
   steps];

(* "right zigzag first": the two zigzag rules change places, everything else keeps its order (as in the editor) *)
gcRightFirst[rs_Association] := With[{k = Keys[rs], i = First[FirstPosition[Keys[rs], "(2.1) left zigzag"]]},
   AssociationThread[#, Lookup[rs, #]] &[Join[Take[k, i - 1], {k[[i + 1]], k[[i]]}, Drop[k, i + 1]]]];

gcHandler[payloadB64_String] := Module[{j, ld, rs, steps},
   j = Quiet@Check[ImportByteArray[BaseDecode[payloadB64], "RawJSON"], $Failed];
   If[! AssociationQ[j] || ! ListQ[j["src"]] || ! ListQ[j["ls"]], Return[<|"error" -> "bad payload"|>]];
   If[Length[j["ls"]] > 60, Return[<|"error" -> "diagram too large (more than 60 boxes)"|>]];
   ld = Quiet@Check[gcToLD[j], $Failed];
   If[! gcValidQ[ld], Return[<|"error" -> "the layered form does not fit together (colours or positions)"|>]];
   rs = Which[TrueQ[j["pivotal"]] && TrueQ[j["ribbon"]], Join[withTwists[rulesSB], ribbonRules],
     TrueQ[j["pivotal"]], withTwists[If[TrueQ[j["spherical"]], rulesSB, rulesDB]], True, rulesB];
   rs = If[TrueQ[j["symmetric"]], withSymmetry[rs], rs];
   rs = If[TrueQ[j["rightFirst"]], gcRightFirst[rs], rs];
   If[TrueQ[j["prefusion"]], Return[gcHandlerLin[j, ld, rs]]];
   steps = Block[{pairings = Replace[Lookup[j, "pairings", {}], Except[_List] -> {}],
      inverses = Replace[Lookup[j, "inverses", {}], Except[_List] -> {}],
      retracts = Replace[Lookup[j, "retracts", {}], Except[_List] -> {}]},
     TimeConstrained[Quiet@gcTrace[ld, rs], 40, $Aborted]];
   If[steps === $Aborted, Return[<|"error" -> "time limit reached"|>]];
   If[! ListQ[steps], Return[<|"error" -> "the engine did not return a layered form (are rules/normalize loaded in this context?)"|>]];
   <|"steps_b64" -> BaseEncode[ExportByteArray[{#[[1]], gcFromLD[#[[2]]]} & /@ steps, "RawJSON", "Compact" -> True]],
     "engine" -> "Wolfram " <> ToString[$VersionNumber]|>];

(* Chapter 4: one term of a linear combination *)
gcTermJSON[t_] := <|"c" -> t["c"], "sums" -> t["sums"], "pairs" -> t["pairs"], "src" -> t["ld"][[1]], "ls" -> ({#[[1]], gcName[#[[2, 1]]], #[[2, 2]], #[[2, 3]]} & /@ t["ld"][[2]])|>;
gcHandlerLin[j_, ld_, rs_] := Module[{term, steps},
   term = <|"c" -> Replace[Lookup[j, "c", <||>], Except[_Association] -> <|"n" -> 1, "d" -> 1, "at" -> <||>|>],
     "sums" -> Replace[Lookup[j, "sums", {}], Except[_List] -> {}], "pairs" -> Replace[Lookup[j, "pairs", <||>], Except[_Association] -> <||>], "ld" -> ld|>;
   term["c"] = Join[<|"n" -> 1, "d" -> 1, "at" -> <||>|>, term["c"]]; If[! AssociationQ[term["c"]["at"]], term["c"]["at"] = <||>];
   steps = Block[{pairings = Replace[Lookup[j, "pairings", {}], Except[_List] -> {}],
      inverses = Replace[Lookup[j, "inverses", {}], Except[_List] -> {}],
      retracts = Replace[Lookup[j, "retracts", {}], Except[_List] -> {}],
      lSimples = Replace[Lookup[j, "simples", {}], Except[_List] -> {}]},
     TimeConstrained[Quiet@lTrace[term, withLin[rs]], 40, $Aborted]];
   If[steps === $Aborted, Return[<|"error" -> "time limit reached"|>]];
   If[! ListQ[steps], Return[<|"error" -> "the Chapter 4 engine did not return terms"|>]];
   <|"steps_b64" -> BaseEncode[ExportByteArray[{#[[1]], gcTermJSON[#[[2]]]} & /@ steps, "RawJSON", "Compact" -> True]],
     "engine" -> "Wolfram " <> ToString[$VersionNumber]|>];

(* quick local checks before deploying: they should print "definition of ∨f", "Fig. 2.4 slide through right ev",
   "caps and cups on ⊗", "(2.1) right zigzag" (ψ_X written out, X** = X), "trace symmetry (§2.6.1)", "R3: Yang–Baxter",
   "twists cancel (Lemma 3.2)" (two curls drawn out), "ribbon: θʳ = θˡ (§3.3.2)" and, for Chapter 4,
   "(4.8)" (∑_i q_α p_α = id_X) *)
gcCheck[payload_Association, expected_String] := With[{r = gcHandler[BaseEncode[ExportByteArray[payload, "RawJSON", "Compact" -> True]]]},
   With[{got = If[KeyExistsQ[r, "steps_b64"], ImportByteArray[BaseDecode[r["steps_b64"]], "RawJSON"][[-1, 1]], r]},
    Print["Check: ", got, If[got === expected, "  ✓", "  ✗ expected " <> expected]]; got === expected]];
gcReady = gcReady && gcCheck[<|"src" -> {"\[Or]Y"}, "ls" -> {
    <|"a" -> 1, "name" -> "coev_X", "ins" -> {}, "outs" -> {"X", "\[Or]X"}|>,
    <|"a" -> 1, "name" -> "f", "ins" -> {"X"}, "outs" -> {"Y"}|>,
    <|"a" -> 0, "name" -> "ev_Y", "ins" -> {"\[Or]Y", "Y"}, "outs" -> {}|>}|>, "definition of \[Or]f"];
gcReady = gcReady && gcCheck[<|"src" -> {"X", "Y*"}, "pivotal" -> True, "ls" -> {
    <|"a" -> 1, "name" -> "f*", "ins" -> {"Y*"}, "outs" -> {"X*"}|>,
    <|"a" -> 0, "name" -> "ev~_X", "ins" -> {"X", "X*"}, "outs" -> {}|>}|>, "Fig. 2.4 slide through right ev"];
gcReady = gcReady && gcCheck[<|"src" -> {"X*", "Y*", "Y", "X"}, "pivotal" -> True, "ls" -> {
    <|"a" -> 0, "name" -> "ev_{Y\[CircleTimes]X}", "ins" -> {"X*", "Y*", "Y", "X"}, "outs" -> {}|>}|>, "caps and cups on \[CircleTimes]"];
gcReady = gcReady && gcCheck[<|"src" -> {"X"}, "pivotal" -> True, "ls" -> {
    <|"a" -> 1, "name" -> "coev_X*", "ins" -> {}, "outs" -> {"X*", "X"}|>,
    <|"a" -> 0, "name" -> "ev~_X", "ins" -> {"X", "X*"}, "outs" -> {}|>}|>, "(2.1) right zigzag"];
gcReady = gcReady && gcCheck[<|"src" -> {}, "pivotal" -> True, "ls" -> {
    <|"a" -> 0, "name" -> "coev~_X", "ins" -> {}, "outs" -> {"X*", "X"}|>,
    <|"a" -> 1, "name" -> "q", "ins" -> {"X"}, "outs" -> {"Y"}|>,
    <|"a" -> 1, "name" -> "p", "ins" -> {"Y"}, "outs" -> {"X"}|>,
    <|"a" -> 0, "name" -> "ev_X", "ins" -> {"X*", "X"}, "outs" -> {}|>}|>, "trace symmetry (\[Section]2.6.1)"];
gcReady = gcReady && gcCheck[<|"src" -> {"X", "Y", "Z"}, "ls" -> {
    <|"a" -> 0, "name" -> "\[Tau]_{X,Y}", "ins" -> {"X", "Y"}, "outs" -> {"Y", "X"}|>,
    <|"a" -> 1, "name" -> "\[Tau]_{X,Z}", "ins" -> {"X", "Z"}, "outs" -> {"Z", "X"}|>,
    <|"a" -> 0, "name" -> "\[Tau]_{Y,Z}", "ins" -> {"Y", "Z"}, "outs" -> {"Z", "Y"}|>}|>, "R3: Yang\[Dash]Baxter"];
gcReady = gcReady && gcCheck[<|"src" -> {"X"}, "pivotal" -> True, "ls" -> {
    <|"a" -> 1, "name" -> "coev_X", "ins" -> {}, "outs" -> {"X", "X*"}|>,
    <|"a" -> 0, "name" -> "\[Tau]\:207b\:00b9_{X,X}", "ins" -> {"X", "X"}, "outs" -> {"X", "X"}|>,
    <|"a" -> 1, "name" -> "ev~_X", "ins" -> {"X", "X*"}, "outs" -> {}|>,
    <|"a" -> 0, "name" -> "coev~_X", "ins" -> {}, "outs" -> {"X*", "X"}|>,
    <|"a" -> 1, "name" -> "\[Tau]_{X,X}", "ins" -> {"X", "X"}, "outs" -> {"X", "X"}|>,
    <|"a" -> 0, "name" -> "ev_X", "ins" -> {"X*", "X"}, "outs" -> {}|>}|>, "twists cancel (Lemma 3.2)"];
gcReady = gcReady && gcCheck[<|"src" -> {"X"}, "pivotal" -> True, "ribbon" -> True, "ls" -> {
    <|"a" -> 0, "name" -> "\[Theta]\:02b3_X", "ins" -> {"X"}, "outs" -> {"X"}|>}|>, "ribbon: \[Theta]\:02b3 = \[Theta]\:02e1 (\[Section]3.3.2)"];
gcReady = gcReady && gcCheck[<|"src" -> {"X"}, "pivotal" -> True, "prefusion" -> True, "simples" -> {"i"},
    "c" -> <|"n" -> 1, "d" -> 1, "at" -> <||>|>, "sums" -> {"i"}, "pairs" -> <|"\[Alpha]" -> <|"W" -> {"X"}, "t" -> "i"|>|>, "ls" -> {
    <|"a" -> 0, "name" -> "p_\[Alpha]", "ins" -> {"X"}, "outs" -> {"i"}|>,
    <|"a" -> 0, "name" -> "q_\[Alpha]", "ins" -> {"i"}, "outs" -> {"X"}|>}|>, "(4.8)"];

gcDeployed = If[TrueQ[gcReady],
   CloudDeploy[APIFunction[{"payload_b64" -> "String"}, gcHandler[#["payload_b64"]] &, "JSON"],
    "GraphicalCalculusKernel", Permissions -> "Public"],
   "Not deployed: a check failed (see the messages above). The live kernel was left unchanged."];
$ContextPath = gcSavedPath;
End[];
GraphicalCalculusKernel`gcDeployed
