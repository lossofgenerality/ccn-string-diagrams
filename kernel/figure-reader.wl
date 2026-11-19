(* ::Package:: *)
(* ::Title:: *)
(* FigureReader: diagrams read automatically from the book, checked by the simplifier *)
(* The reading itself is done by tools/figure-reader/figreader.py, which takes the vector drawing instructions of a PDF
   page (line segments, rectangles, Bezier curves, filled arrow heads and positioned text, through PyMuPDF) and
   rebuilds every string diagram on the page as a layered form. It writes a JSON list of equations:
     [{"page": n, "sides": [{"bbox": [x0,y0,x1,y1], "src": [colours], "ls": [[a, name, ins, outs], ...], "error": null}, ...]}, ...]
   This package turns those readings into the layered forms of DiagramToExpression and checks them with
   Simplifier: does each side fit together, and do the sides of an equation reach the same normal form.
   By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0 *)

If[DownValues[Simplifier`simplifyLD] === {}, Get[FileNameJoin[{DirectoryName[$InputFileName], "simplifier.wl"}]]];

BeginPackage["FigureReader`", {"Simplifier`", "ExpressionToDiagram`", "DiagramToExpression`"}];

importReadings::usage = "importReadings[file] reads the JSON written by figreader.py: a list of equations, each an Association with \"page\" and \"sides\".";
readingToLD::usage = "readingToLD[side] is the layered form LD[src, {{a, B[symbol, ins, outs]}, ...}] of one side, with names turned into symbols by editorSymbol.";
readingDuals::usage = "readingDuals[eq] is \"vee\" when a colour of the equation is written with ∨ (§2.1.2), and \"star\" otherwise (§2.1.3 on).";
readingPairings::usage = "readingPairings[eq] guesses the declared pairings of an equation: every box named ω… with every box named Ω….";
completeQ::usage = "completeQ[eq] is True when the reader named every strand and box of the equation (no \"?\") and met no error.";
checkReading::usage = "checkReading[eq] is an Association: \"Page\", \"Sides\" (the sides as editor text), \"Complete\", \"Valid\" (every side fits together), \"NormalForms\" (as editor text), \"Holds\" (all normal forms agree), \"Adjacent\" (each side has the normal form of the next, for proofs written as chains).";
readingReport::usage = "readingReport[eqs] counts the pictures and equations read, complete, valid and confirmed by the rules.";
showReading::usage = "showReading[eq] draws every side of an equation as read (renderP, or render for ∨ duals), separated by =.";

Begin["`Private`"];
importReadings[file_String] := Import[file, "RawJSON"];
readingToLD[s_Association] := LD[s["src"], {#[[1]], B[editorSymbol[#[[2]]], #[[3]], #[[4]]]} & /@ s["ls"]];
readingDuals[e_Association] := If[StringContainsQ[ToString[e["sides"], InputForm], "∨"], "vee", "star"];
readingPairings[e_Association] := With[{n = DeleteDuplicates@Cases[e["sides"], {_, x_String, _, _} :> x, Infinity]},
   Tuples[{Select[n, StringStartsQ[#, "ω"] &], Select[n, StringStartsQ[#, "Ω"] &]}]];
completeQ[e_Association] := FreeQ[e["sides"], "?" | s_String /; StringContainsQ[s, "?"]] && AllTrue[e["sides"], #["error"] === Null &];
txt[ld_] := Quiet@Check[toEditorText[ldToExpression[ld]], "—"];
checkReading[e_Association] := Module[{lds = readingToLD /@ e["sides"], du = readingDuals[e], valid, nf},
   valid = Quiet[validQ /@ lds];
   nf = If[And @@ valid, Quiet[simplifyLD[#, "Duals" -> du, "Pairings" -> readingPairings[e]]] & /@ lds, $Failed];
   <|"Page" -> e["page"], "Sides" -> (txt /@ lds), "Complete" -> completeQ[e], "Valid" -> And @@ valid,
     "NormalForms" -> If[ListQ[nf], txt /@ nf, $Failed],
     "Holds" -> If[ListQ[nf] && Length[nf] > 1, SameQ @@ nf, Missing["OneSide"]],
     "Adjacent" -> If[ListQ[nf] && Length[nf] > 1, SameQ @@@ Partition[nf, 2, 1], {}]|>];
readingReport[eqs_List] := Module[{c = checkReading /@ eqs, multi},
   multi = Select[c, Length[#Sides] > 1 &];
   <|"Pictures" -> Total[Length[#sides] & /@ eqs], "Groups" -> Length[eqs], "Complete pictures" -> Count[Flatten[(FreeQ[#, "?"] && #["error"] === Null) & /@ #sides & /@ eqs], True],
     "Equations (two sides or more)" -> Length[multi], "Equations read completely" -> Count[multi, _?(#Complete &)],
     "Confirmed by the rules (same normal form)" -> Count[multi, _?(#Holds === True &)],
     "Confirmed step by step (each side = the next)" -> Count[multi, _?(#Adjacent =!= {} && And @@ #Adjacent &)]|>];
showReading[e_Association] := With[{du = readingDuals[e]},
   Row[Riffle[Show[If[du === "vee", render, renderP][fromLayered[readingToLD[#]]], ImageSize -> {UpTo[160], UpTo[130]}] & /@ e["sides"], Style["  =  ", 16]]]];
End[];
EndPackage[];
