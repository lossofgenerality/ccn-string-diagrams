(* ::Package:: *)
(* GraphicalCalculusKernel: the Wolfram engine behind the "Wolfram kernel" option of string-diagram-editor.html.

   HOW TO DEPLOY
   1. Check gcNotebook below points at your graphical-calculus-2.1.3-pivotal.nb. That notebook loads
      graphical-calculus-2.1-simplify.nb from the same folder and adds the pivotal rules rulesP (§2.1.3).
   2. Evaluate this whole file (paste it into one cell of a NEW notebook, or Get it).
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
   pivotal: true uses rulesP (duals written X*, ẽv and c̃oev, Figures 2.2–2.4); otherwise rules (§2.1.2, duals ∨X).
   Reply JSON: {"steps_b64": base64 of [[rule, {"src": [...], "ls": [[a, name, ins, outs], ...]}], ...],
                "engine": "Wolfram 15."}   or   {"error": "..."}
   Names: "ev_X" <-> Subscript["ev","X"], "coev_X" <-> Subscript["coev","X"], "ev~_X" <-> Subscript["ev~","X"] (ẽv),
   "coev~_X" <-> Subscript["coev~","X"] (c̃oev); other names are plain strings.
   The API only runs the rewrite rules on the data it is sent (no code is evaluated), so it needs no key.

   By Dara O Shayda and Noor Hoshino (星野ヌール)
   © Computational Classnotes · CC BY-NC-SA 4.0 *)

gcNotebook = FileNameJoin[{$HomeDirectory, "Downloads", "graphical-calculus-2.1.3-pivotal.nb"}];

(* load the notebook's engine: evaluate its Input cells, in order, in the current context.
   Cells stored as text are read with Get; cells stored as boxes with ToExpression. *)
gcRun[c_String] := Get[StringToStream[c]];
gcRun[c_] := ToExpression[c, StandardForm];
Module[{nb, cells, path = gcNotebook},
 If[! FileExistsQ[path], Print["Notebook not found: ", path]; Abort[]];
 nb = Get[path];
 cells = Cases[nb, Cell[c_, "Input" | "Code", ___] :> c, Infinity];
 Scan[Quiet@Check[TimeConstrained[gcRun[#]; Null, 120], Null] &, cells];
 Print["Loaded ", Length[cells], " code cells from ", FileNameTake[path]]];
If[! (AssociationQ[rules] && KeyExistsQ[rules, "(2.1) left zigzag"] && AssociationQ[rulesP] && Length[DownValues[normalize]] > 0 && Length[DownValues[rewriteOnce]] > 0),
 Print["The engine (rules, rulesP, normalize, rewriteOnce) did not load in context ", $Context, ". Check gcNotebook."]; Abort[]];

gcSym[s_String] := With[{m = StringCases[s, RegularExpression["^(ev|coev)(~?)_(.+)$"] -> {"$1$2", "$3"}]},
   If[m === {}, s, Subscript[m[[1, 1]], StringTrim[m[[1, 2]], "{" | "}"]]]];
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

gcHandler[payloadB64_String] := Module[{j, ld, rs, steps},
   j = Quiet@Check[ImportByteArray[BaseDecode[payloadB64], "RawJSON"], $Failed];
   If[! AssociationQ[j] || ! ListQ[j["src"]] || ! ListQ[j["ls"]], Return[<|"error" -> "bad payload"|>]];
   If[Length[j["ls"]] > 60, Return[<|"error" -> "diagram too large (more than 60 boxes)"|>]];
   ld = Quiet@Check[gcToLD[j], $Failed];
   If[! gcValidQ[ld], Return[<|"error" -> "the layered form does not fit together (colours or positions)"|>]];
   rs = If[TrueQ[j["pivotal"]], rulesP, rules];
   rs = If[TrueQ[j["rightFirst"]], Join[KeyTake[rs, {"(2.1) right zigzag"}], rs], rs];
   steps = Block[{pairings = Replace[Lookup[j, "pairings", {}], Except[_List] -> {}]},
     TimeConstrained[Quiet@gcTrace[ld, rs], 40, $Aborted]];
   If[steps === $Aborted, Return[<|"error" -> "time limit reached"|>]];
   If[! ListQ[steps], Return[<|"error" -> "the engine did not return a layered form (are rules/normalize loaded in this context?)"|>]];
   <|"steps_b64" -> BaseEncode[ExportByteArray[{#[[1]], gcFromLD[#[[2]]]} & /@ steps, "RawJSON", "Compact" -> True]],
     "engine" -> "Wolfram " <> ToString[$VersionNumber]|>];

(* quick local checks before deploying: they should print "definition of ∨f" and "Figure 2.4: slide through ẽv" *)
gcCheck[payload_Association] := With[{r = gcHandler[BaseEncode[ExportByteArray[payload, "RawJSON", "Compact" -> True]]]},
   If[KeyExistsQ[r, "steps_b64"], Print["Check: ", ImportByteArray[BaseDecode[r["steps_b64"]], "RawJSON"][[-1, 1]]],
    Print["Check failed: ", r]; Abort[]]];
gcCheck[<|"src" -> {"\[Or]Y"}, "ls" -> {
    <|"a" -> 1, "name" -> "coev_X", "ins" -> {}, "outs" -> {"X", "\[Or]X"}|>,
    <|"a" -> 1, "name" -> "f", "ins" -> {"X"}, "outs" -> {"Y"}|>,
    <|"a" -> 0, "name" -> "ev_Y", "ins" -> {"\[Or]Y", "Y"}, "outs" -> {}|>}|>];
gcCheck[<|"src" -> {"X", "Y*"}, "pivotal" -> True, "ls" -> {
    <|"a" -> 1, "name" -> "f*", "ins" -> {"Y*"}, "outs" -> {"X*"}|>,
    <|"a" -> 0, "name" -> "ev~_X", "ins" -> {"X", "X*"}, "outs" -> {}|>}|>];

CloudDeploy[
 APIFunction[{"payload_b64" -> "String"}, gcHandler[#["payload_b64"]] &, "JSON"],
 "GraphicalCalculusKernel", Permissions -> "Public"]
