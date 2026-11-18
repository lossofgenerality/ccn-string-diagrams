(* ::Package:: *)
(* GraphicalCalculusKernel: the Wolfram engine behind the "Wolfram kernel" option of string-diagram-editor.html.

   HOW TO DEPLOY
   1. Check gcNotebook below points at your graphical-calculus-2.1-simplify.nb.
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
      "pairings": [["ω","Ω"], ...], "rightFirst": false}
   Reply JSON: {"steps_b64": base64 of [[rule, {"src": [...], "ls": [[a, name, ins, outs], ...]}], ...],
                "engine": "Wolfram 15."}   or   {"error": "..."}
   Names: "ev_X" <-> Subscript["ev","X"], "coev_X" <-> Subscript["coev","X"]; other names are plain strings.
   The API only runs the rewrite rules on the data it is sent (no code is evaluated), so it needs no key.

   © Computational Classnotes · CC BY-NC-SA 4.0 *)

gcNotebook = FileNameJoin[{$HomeDirectory, "Downloads", "graphical-calculus-2.1-simplify.nb"}];

(* load the notebook's engine: evaluate its Input cells, in order, in the current context *)
Module[{nb, cells, path = gcNotebook},
 If[! FileExistsQ[path], Print["Notebook not found: ", path]; Abort[]];
 nb = Get[path];
 cells = Cases[nb, Cell[c_, "Input" | "Code", ___] :> c, Infinity];
 Scan[Quiet@Check[TimeConstrained[ToExpression[#, StandardForm]; Null, 120], Null] &, cells];
 Print["Loaded ", Length[cells], " code cells from ", FileNameTake[path]]];
If[! (AssociationQ[rules] && KeyExistsQ[rules, "(2.1) left zigzag"] && Length[DownValues[normalize]] > 0 && Length[DownValues[rewriteOnce]] > 0),
 Print["The engine (rules, normalize, rewriteOnce) did not load in context ", $Context, ". Check gcNotebook."]; Abort[]];

gcSym[s_String] := Which[
   StringStartsQ[s, "ev_"], Subscript["ev", StringTrim[StringDrop[s, 3], "{" | "}"]],
   StringStartsQ[s, "coev_"], Subscript["coev", StringTrim[StringDrop[s, 5], "{" | "}"]],
   True, s];
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
   rs = If[TrueQ[j["rightFirst"]], Join[KeyTake[rules, {"(2.1) right zigzag"}], rules], rules];
   steps = Block[{pairings = Replace[Lookup[j, "pairings", {}], Except[_List] -> {}]},
     TimeConstrained[Quiet@gcTrace[ld, rs], 40, $Aborted]];
   If[steps === $Aborted, Return[<|"error" -> "time limit reached"|>]];
   If[! ListQ[steps], Return[<|"error" -> "the engine did not return a layered form (are rules/normalize loaded in this context?)"|>]];
   <|"steps_b64" -> BaseEncode[ExportByteArray[{#[[1]], gcFromLD[#[[2]]]} & /@ steps, "RawJSON", "Compact" -> True]],
     "engine" -> "Wolfram " <> ToString[$VersionNumber]|>];

(* quick local check before deploying: should show "definition of ∨f" *)
With[{p = BaseEncode[ExportByteArray[<|"src" -> {"\[Or]Y"}, "ls" -> {
        <|"a" -> 1, "name" -> "coev_X", "ins" -> {}, "outs" -> {"X", "\[Or]X"}|>,
        <|"a" -> 1, "name" -> "f", "ins" -> {"X"}, "outs" -> {"Y"}|>,
        <|"a" -> 0, "name" -> "ev_Y", "ins" -> {"\[Or]Y", "Y"}, "outs" -> {}|>}|>, "RawJSON", "Compact" -> True]]},
 With[{r = gcHandler[p]},
  If[KeyExistsQ[r, "steps_b64"], Print["Check: ", ImportByteArray[BaseDecode[r["steps_b64"]], "RawJSON"][[-1, 1]]],
   Print["Check failed: ", r]; Abort[]]]];

CloudDeploy[
 APIFunction[{"payload_b64" -> "String"}, gcHandler[#["payload_b64"]] &, "JSON"],
 "GraphicalCalculusKernel", Permissions -> "Public"]
