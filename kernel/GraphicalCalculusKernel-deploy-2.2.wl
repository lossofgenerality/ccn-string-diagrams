(* ::Package:: *)
(* GraphicalCalculusKernel: the Wolfram engine behind the "Wolfram kernel" option of string-diagram-editor.html.

   HOW TO DEPLOY
   1. Keep this file with the engine files in one folder, gcDir below (Desktop/Research/Monoidal Graphical Calculus).
      Check gcNotebook, gcPivotal and gcPenrose below: graphical-calculus-2.1-simplify.nb (sections 0–19, §2.1.1–2.1.2),
      pivotal-2.1.3.wl (sections 20–27, §2.1.3, which defines rulesP) and penrose-2.2.wl (sections 30–35, §2.2,
      which defines rulesT), all in gcDir.
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
      "pairings": [["ω","Ω"], ...], "rightFirst": false, "pivotal": false}
   pivotal: true uses rulesT (duals written X*, ẽv and c̃oev, Figures 2.2–2.4, and the §2.2 rules for caps and cups
   on a tensor product); otherwise rules (§2.1.2, duals ∨X).
   Reply JSON: {"steps_b64": base64 of [[rule, {"src": [...], "ls": [[a, name, ins, outs], ...]}], ...],
                "engine": "Wolfram 15."}   or   {"error": "..."}
   Names: "ev_X" <-> Subscript["ev","X"], "coev_X" <-> Subscript["coev","X"],
   "ev~_X" <-> Subscript[OverTilde["ev"],"X"] (ẽv), "coev~_X" <-> Subscript[OverTilde["coev"],"X"] (c̃oev);
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
gcReady = AssociationQ[rules] && KeyExistsQ[rules, "(2.1) left zigzag"] && AssociationQ[rulesP] && AssociationQ[rulesT] &&
   Length[DownValues[normalize]] > 0 && Length[DownValues[rewriteOnce]] > 0;
If[! gcReady, Print["The engine (rules, rulesP, normalize, rewriteOnce) did not load in context ", $Context, ". Check gcNotebook, gcPivotal and gcPenrose."]];

gcSym[s_String] := With[{m = StringCases[s, RegularExpression["^(ev|coev)(~?)_(.+)$"] -> {"$1", "$2", "$3"}]},
   If[m === {}, s, Subscript[If[m[[1, 2]] === "~", OverTilde[m[[1, 1]]], m[[1, 1]]], StringTrim[m[[1, 3]], "{" | "}"]]]];
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
   rs = If[TrueQ[j["pivotal"]], rulesT, rules];
   rs = If[TrueQ[j["rightFirst"]], gcRightFirst[rs], rs];
   steps = Block[{pairings = Replace[Lookup[j, "pairings", {}], Except[_List] -> {}]},
     TimeConstrained[Quiet@gcTrace[ld, rs], 40, $Aborted]];
   If[steps === $Aborted, Return[<|"error" -> "time limit reached"|>]];
   If[! ListQ[steps], Return[<|"error" -> "the engine did not return a layered form (are rules/normalize loaded in this context?)"|>]];
   <|"steps_b64" -> BaseEncode[ExportByteArray[{#[[1]], gcFromLD[#[[2]]]} & /@ steps, "RawJSON", "Compact" -> True]],
     "engine" -> "Wolfram " <> ToString[$VersionNumber]|>];

(* quick local checks before deploying: they should print "definition of ∨f", "Fig. 2.4 slide through right ev"
   and "caps and cups on ⊗" *)
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

gcDeployed = If[TrueQ[gcReady],
   CloudDeploy[APIFunction[{"payload_b64" -> "String"}, gcHandler[#["payload_b64"]] &, "JSON"],
    "GraphicalCalculusKernel", Permissions -> "Public"],
   "Not deployed: a check failed (see the messages above). The live kernel was left unchanged."];
$ContextPath = gcSavedPath;
End[];
GraphicalCalculusKernel`gcDeployed
