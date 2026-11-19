(* ::Package:: *)
(* ::Title:: *)
(* WLToJS: the Wolfram simplifier, translated to JavaScript *)
(* This package reads the definitions of the CCN String Diagrams simplifier, as the Wolfram kernel holds them, and
   writes equivalent JavaScript. Nothing is translated by hand: every rule, every helper and the rewriting machinery
   (normalize, level exchange, rewriteOnce, the Chapter 4 term loop) is taken from its own DownValues, SubValues and
   OwnValues, so a rule added or changed in Wolfram reaches the JavaScript the next time translateSimplifier runs.
   The JavaScript runs on the small runtime wl-runtime.js (data model, pattern matching, built-in functions).
   By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0

   Entry points:
     translateSimplifier[file]      write the whole simplifier (engine closure, rule sets, editor API) to file
     translateSymbols[{f, g, ...}]  the JavaScript for these symbols' definitions
     translateExpression[Hold[e]]   the JavaScript expression for one held Wolfram expression
     simplifierClosure[]            the engine symbols the simplifier needs, found from the rule sets
     $WLToJSBuiltins                the built-in functions the runtime provides; a translation using another one fails *)

If[DownValues[Simplifier`simplifyLD] === {}, Get[FileNameJoin[{DirectoryName[$InputFileName], "simplifier.wl"}]]];

BeginPackage["WLToJS`"];
translateSimplifier::usage = "translateSimplifier[file] translates the simplifier (all engine definitions reachable from the rule sets and the rewriting loop, the rule sets of every mode, and the editor's conversions jsonToLD, ldToJSON, editorSymbol, editorName) to JavaScript and writes it to file. Returns an Association with the counts and any unsupported built-ins.";
translateSymbols::usage = "translateSymbols[{s1, s2, ...}] is the JavaScript defining these engine symbols (their DownValues, SubValues and OwnValues).";
translateExpression::usage = "translateExpression[Hold[expr]] is the JavaScript expression for one held Wolfram expression.";
simplifierClosure::usage = "simplifierClosure[] lists the engine symbols the simplifier uses: the rule functions of the largest rule sets, the rewriting machinery, and everything they call.";
ruleSetTable::usage = "ruleSetTable[] is the Association of every mode key (as the JavaScript computes it) to the rule list {name, kind, function} of that mode.";
$WLToJSBuiltins::usage = "$WLToJSBuiltins lists the System functions the JavaScript runtime wl-runtime.js provides.";
$WLToJSUnsupported::usage = "$WLToJSUnsupported lists System functions met during the last translation that the runtime does not provide.";
WLToJS::unsupported = "These built-in functions are not in the JavaScript runtime: `1`.";

Begin["`Private`"];
ClearAll["WLToJS`Private`*"];   (* a reload starts from clean definitions and attributes *)

$dir = DirectoryName[$InputFileName];
$engineContexts = {"Simplifier`Engine`", "DiagramToExpression`", "DiagramToExpression`Private`"};
$dynamic = {"pairings", "inverses", "retracts", "lSimples", "lBound"};
$WLToJSBuiltins = {"Plus", "Times", "Power", "Equal", "Unequal", "Less", "LessEqual", "Greater", "GreaterEqual", "SameQ", "UnsameQ", "Not",
   "Min", "Max", "Numerator", "Denominator", "Length", "First", "Last", "Rest", "Most", "Reverse", "RotateLeft", "Range", "Take", "Drop",
   "Delete", "Join", "Append", "Prepend", "Flatten", "Map", "MapIndexed", "MapThread", "Apply", "Scan", "Select", "SelectFirst", "AllTrue",
   "Fold", "FoldList", "FixedPoint", "DeleteDuplicates", "DeleteCases", "Complement", "MemberQ", "MatchQ", "FreeQ", "Replace", "FirstPosition",
   "OrderedQ", "Association", "Keys", "Lookup", "KeyDrop", "KeyExistsQ", "KeyValueMap", "StringQ", "MissingQ", "StringJoin", "StringLength",
   "StringTake", "StringDrop", "StringStartsQ", "StringEndsQ", "StringContainsQ", "StringMatchQ", "StringRiffle", "StringSplit", "StringTrim",
   "StringReplace", "StringCases", "StringPosition", "ToCharacterCode", "ToString", "Print", "Subscript", "Superscript", "OverTilde",
   "RegularExpression", "Rule", "Missing", "StringExpression", "Alternatives", "Blank", "BlankSequence", "BlankNullSequence", "Pattern",
   "PatternTest", "HoldPattern", "Span"};
$locals = {};          (* full names of the variables in scope *)
$unsupported = {};

(* ---------- strings and names ---------- *)
q[s_String] := "\"" <> StringReplace[s, {"\\" -> "\\\\", "\"" -> "\\\"", "\n" -> "\\n", "\r" -> "\\r", "\t" -> "\\t",
     c : RegularExpression["[\\x00-\\x1f]"] :> "\\u" <> IntegerString[ToCharacterCode[c][[1]], 16, 4]}] <> "\"";
jsId[name_String] := "v_" <> StringReplace[name, c : RegularExpression["[^A-Za-z0-9]"] :> "_" <> IntegerString[ToCharacterCode[c][[1]], 16]];
SetAttributes[{fullName, shortName, engineQ, localQ, defsQ, globalQ}, HoldAllComplete];
fullName[s_Symbol] := Context[Unevaluated[s]] <> SymbolName[Unevaluated[s]];
shortName[s_Symbol] := SymbolName[Unevaluated[s]];
engineQ[s_Symbol] := MemberQ[$engineContexts, Context[Unevaluated[s]]];
localQ[s_Symbol] := MemberQ[$locals, fullName[s]];
defsQ[s_Symbol] := DownValues[s] =!= {} || SubValues[s] =!= {};
globalQ[s_Symbol] := engineQ[s] && (MemberQ[$dynamic, shortName[s]] || OwnValues[s] =!= {});

(* ---------- expressions ---------- *)
SetAttributes[bindEnv, HoldRest];
SetAttributes[{cx, cxList, cxSym, patNames, clauseJS, loopsJS, tableJS, whichJS, switchJS, modSpec, lval}, HoldAllComplete];
cxList[Hold[args___]] := List @@ (cx /@ Hold[args]);
args[h_Hold] := StringRiffle[cxList[h], ", "];

cx[s_String] := q[s];
cx[n_Integer] := If[n < 0, "(" <> ToString[n] <> ")", ToString[n]];
cx[r_Rational] := "R.times(" <> ToString[Numerator[r]] <> ", R.power(" <> ToString[Denominator[r]] <> ", -1))";
cx[s_Symbol] := cxSym[s];
cxSym[s_Symbol] := Which[
   localQ[s], jsId[shortName[s]],
   Context[Unevaluated[s]] === "System`",
   Switch[shortName[s], "True", "true", "False", "false", "Null", "null", "$Failed", "R.FAILED", "None", "R.NONE", _, "R.sym(" <> q[shortName[s]] <> ")"],
   globalQ[s], "R.G[" <> q[shortName[s]] <> "]",
   True, "R.sym(" <> q[shortName[s]] <> ")"];

(* control *)
cx[If[c_, a_, b_]] := "(R.truthy(" <> cx[c] <> ") ? " <> cx[a] <> " : " <> cx[b] <> ")";
cx[If[c_, a_]] := "(R.truthy(" <> cx[c] <> ") ? " <> cx[a] <> " : null)";
cx[Which[ps___]] := whichJS[Hold[ps]];
whichJS[Hold[c_, v_, rest___]] := "(R.truthy(" <> cx[c] <> ") ? " <> cx[v] <> " : " <> whichJS[Hold[rest]] <> ")";
whichJS[Hold[]] := "null";
cx[Switch[x_, ps___]] := "(($sw) => " <> switchJS[Hold[ps]] <> ")(" <> cx[x] <> ")";
switchJS[Hold[p_, v_, rest___]] := "(R.matchQ($sw, " <> cx[p] <> ") ? " <> cx[v] <> " : " <> switchJS[Hold[rest]] <> ")";
switchJS[Hold[]] := "null";
cx[And[a___]] := "(" <> StringRiffle["R.truthy(" <> # <> ")" & /@ cxList[Hold[a]], " && "] <> ")";
cx[Or[a___]] := "(" <> StringRiffle["R.truthy(" <> # <> ")" & /@ cxList[Hold[a]], " || "] <> ")";
cx[Not[a_]] := "(!R.truthy(" <> cx[a] <> "))";
cx[CompoundExpression[a___]] := "(" <> args[Hold[a]] <> ")";
cx[Catch[e_]] := "R.catch_(() => " <> cx[e] <> ")";
cx[Throw[v_]] := "R.throw_(" <> cx[v] <> ")";
cx[Return[v_]] := "R.return_(" <> cx[v] <> ")";
cx[Return[]] := "R.return_(null)";
cx[Break[]] := "R.break_()";
cx[List[a___]] := "R.list(" <> args[Hold[a]] <> ")";
cx[Part[x_, is___]] := "R.part(" <> cx[x] <> ", " <> args[Hold[is]] <> ")";

(* scopes *)
withLocals[names_List, body_] := Block[{$locals = Join[$locals, names]}, body];
SetAttributes[withLocals, HoldRest];
modSpec[Set[x_Symbol, v_]] := {fullName[x], jsId[shortName[x]], cx[v]};
modSpec[x_Symbol] := {fullName[x], jsId[shortName[x]], None};
cx[With[{inits___}, body_]] := With[{sp = List @@ (modSpec /@ Hold[inits])},
   "((" <> StringRiffle[sp[[All, 2]], ", "] <> ") => " <> withLocals[sp[[All, 1]], cx[body]] <> ")(" <> StringRiffle[sp[[All, 3]], ", "] <> ")"];
cx[Module[{vars___}, body_]] := With[{sp = List @@ (modSpec /@ Hold[vars])},
   "(() => { " <> If[sp === {}, "", "let " <> StringRiffle[If[#[[3]] === None, #[[2]], #[[2]] <> " = " <> #[[3]]] & /@ sp, ", "] <> "; "] <>
    "return " <> withLocals[sp[[All, 1]], cx[body]] <> "; })()"];
cx[Function[body_]] := "((...$s) => " <> cx[body] <> ")";
cx[Function[x_Symbol, body_]] := "((" <> jsId[shortName[x]] <> ") => " <> withLocals[{fullName[x]}, cx[body]] <> ")";
cx[Function[{xs___Symbol}, body_]] := With[{fs = List @@ (Function[Null, fullName[#], HoldAllComplete] /@ Hold[xs]), ids = List @@ (Function[Null, jsId[shortName[#]], HoldAllComplete] /@ Hold[xs])},
   "((" <> StringRiffle[ids, ", "] <> ") => " <> withLocals[fs, cx[body]] <> ")"];
cx[Slot[n_Integer]] := "$s[" <> ToString[n - 1] <> "]";

(* assignment: Wolfram values are never shared, so a changed association or list is a new value *)
lval[x_Symbol] := If[localQ[x], jsId[shortName[x]], "R.G[" <> q[shortName[x]] <> "]"];
cx[Set[x_Symbol, v_]] := "(" <> lval[x] <> " = " <> cx[v] <> ")";
cx[Set[{xs___Symbol}, v_]] := With[{ls = List @@ (lval /@ Hold[xs])},
   "(($t) => (" <> StringRiffle[MapIndexed[#1 <> " = $t[" <> ToString[#2[[1]] - 1] <> "]" &, ls], ", "] <> ", $t))(" <> cx[v] <> ")"];
cx[Set[x_Symbol[k_], v_]] := "(($t) => (" <> lval[x] <> " = " <> lval[x] <> ".put(" <> cx[k] <> ", $t), $t))(" <> cx[v] <> ")";
cx[SetDelayed[f_Symbol[pats___], rhs_]] := "(" <> lval[f] <> " = R.addClause(" <> lval[f] <> ", " <> q[shortName[f]] <> ", " <> clauseJS[Hold[pats], Hold[True], Hold[rhs]] <> "), null)";
cx[AppendTo[x_Symbol, v_]] := "(" <> lval[x] <> " = R.B.Append(" <> lval[x] <> ", " <> cx[v] <> "))";
cx[AddTo[x_Symbol, v_]] := "(" <> lval[x] <> " = R.plus(" <> lval[x] <> ", " <> cx[v] <> "))";
cx[Increment[x_Symbol]] := "(($t) => (" <> lval[x] <> " = R.plus($t, 1), $t))(" <> lval[x] <> ")";
cx[Decrement[x_Symbol]] := "(($t) => (" <> lval[x] <> " = R.plus($t, -1), $t))(" <> lval[x] <> ")";
cx[KeyDropFrom[x_Symbol, k_]] := "(" <> lval[x] <> " = " <> lval[x] <> ".drop(" <> cx[k] <> "))";

(* loops *)
iterVar[Hold[{i_Symbol, spec__}]] := {fullName[i], jsId[shortName[i]], "R.iter([" <> args[Hold[spec]] <> "])"};
iterVar[Hold[{n_}]] := {None, "_", "R.iter([" <> cx[n] <> "])"};
SetAttributes[iterVar, HoldAllComplete];
loopsJS[Hold[it_, rest___], Hold[body_]] := With[{iv = iterVar[Hold[it]]},
   "for (const " <> iv[[2]] <> " of " <> iv[[3]] <> ") { " <> withLocals[DeleteCases[{iv[[1]]}, None], loopsJS[Hold[rest], Hold[body]]] <> " }"];
loopsJS[Hold[], Hold[body_]] := cx[body] <> ";";
cx[Do[body_, its__]] := "(() => { try { " <> loopsJS[Hold[its], Hold[body]] <> " } catch (e) { if (e !== R.BREAK) throw e; } return null; })()";
tableJS[Hold[it_, rest___], Hold[body_]] := With[{iv = iterVar[Hold[it]]},
   "(() => { const $o = []; for (const " <> iv[[2]] <> " of " <> iv[[3]] <> ") { $o.push(" <> withLocals[DeleteCases[{iv[[1]]}, None], tableJS[Hold[rest], Hold[body]]] <> "); } return $o; })()"];
tableJS[Hold[], Hold[body_]] := cx[body];
cx[Table[body_, its__]] := tableJS[Hold[its], Hold[body]];
cx[While[c_, body_]] := "(() => { try { while (R.truthy(" <> cx[c] <> ")) { " <> cx[body] <> "; } } catch (e) { if (e !== R.BREAK) throw e; } return null; })()";
cx[While[c_]] := "(() => { while (R.truthy(" <> cx[c] <> ")) {} return null; })()";

(* patterns in value position: they are data, read by the runtime matcher *)
patNames[p_] := DeleteDuplicates@Cases[Hold[p], Verbatim[Pattern][n_Symbol, _] :> {fullName[n], shortName[n]}, Infinity];
bindEnv[names_List, Hold[body_]] := "{ " <> StringJoin[("const " <> jsId[#[[2]]] <> " = env[" <> q[#[[2]]] <> "]; ") & /@ names] <>
   "return " <> withLocals[names[[All, 1]], cx[body]] <> "; }";
cx[Verbatim[Pattern][n_Symbol, p_]] := "R.E(\"Pattern\", R.sym(" <> q[shortName[n]] <> "), " <> cx[p] <> ")";
Do[With[{h = h0}, cx[Verbatim[h][]] := "R.E(" <> q[SymbolName[h]] <> ")"; cx[Verbatim[h][t_Symbol]] := "R.E(" <> q[SymbolName[h]] <> ", R.sym(" <> q[shortName[t]] <> "))"], {h0, {Blank, BlankSequence, BlankNullSequence}}];
cx[Verbatim[Condition][p_, c_]] := "R.E(\"Condition\", " <> cx[p] <> ", (env) => " <> bindEnv[patNames[p], Hold[c]] <> ")";
cx[RuleDelayed[p_, rhs_]] := "R.E(\"RuleDelayed\", " <> cx[p] <> ", (env) => " <> bindEnv[patNames[p], Hold[rhs]] <> ")";

(* calls *)
cx[h_Symbol[a___]] := Which[
   localQ[h] || globalQ[h], "R.apply(" <> cxSym[h] <> ", [" <> args[Hold[a]] <> "])",
   engineQ[h], "R.callF(" <> q[shortName[h]] <> ", [" <> args[Hold[a]] <> "])",
   Context[Unevaluated[h]] === "System`",
   (If[! MemberQ[$WLToJSBuiltins, shortName[h]], AppendTo[$unsupported, shortName[h]]]; "R.callB(" <> q[shortName[h]] <> ", [" <> args[Hold[a]] <> "])"),
   True, "R.callF(" <> q[shortName[h]] <> ", [" <> args[Hold[a]] <> "])"];
cx[h_[a___]] := "R.apply(" <> cx[h] <> ", [" <> args[Hold[a]] <> "])";
cx[other_] := (AppendTo[$unsupported, ToString[Unevaluated[other], InputForm]]; "undefined");

translateExpression[Hold[e_]] := Block[{$locals = {}}, cx[e]];

(* ---------- definitions ---------- *)
clauseJS[Hold[pats___], Hold[cond_], Hold[rhs_]] := With[{names = patNames[{pats}]},
   "(args) => { const env = R.matchArgs([" <> args[Hold[pats]] <> "], args); if (!env) return R.NO; " <>
    StringJoin[("const " <> jsId[#[[2]]] <> " = env[" <> q[#[[2]]] <> "]; ") & /@ names] <>
    withLocals[names[[All, 1]], If[Hold[cond] === Hold[True], "", "if (!R.truthy(" <> cx[cond] <> ")) return R.NO; "] <> "return " <> cx[rhs] <> ";"] <> " }"];
SetAttributes[defClause, HoldAllComplete];
defClause[Hold[Verbatim[Condition][f_[pats___], c_]], Hold[rhs_]] := clauseJS[Hold[pats], Hold[c], Hold[rhs]];
defClause[Hold[f_[pats___]], Hold[rhs_]] := clauseJS[Hold[pats], Hold[True], Hold[rhs]];
subClause[Hold[Verbatim[Condition][f_[hp___][pats___], c_]], Hold[rhs_]] := clauseJS[Hold[hp, pats], Hold[c], Hold[rhs]];
subClause[Hold[f_[hp___][pats___]], Hold[rhs_]] := clauseJS[Hold[hp, pats], Hold[True], Hold[rhs]];
SetAttributes[subClause, HoldAllComplete];

jsLit[s_String] := q[s];
jsLit[n_Integer] := ToString[n];
jsLit[r_Real] := ToString[CForm[r]];
jsLit[r_Rational] := "R.times(" <> ToString[Numerator[r]] <> ", R.power(" <> ToString[Denominator[r]] <> ", -1))";
jsLit[True] := "true"; jsLit[False] := "false"; jsLit[Null] := "null"; jsLit[$Failed] := "R.FAILED"; jsLit[None] := "R.NONE";
jsLit[l_List] := "[" <> StringRiffle[jsLit /@ l, ", "] <> "]";
jsLit[a_Association] := "R.B.Association(" <> StringRiffle[KeyValueMap["R.E(\"Rule\", " <> jsLit[#1] <> ", " <> jsLit[#2] <> ")" &, a], ", "] <> ")";
jsLit[s_Symbol] := "R.sym(" <> q[SymbolName[s]] <> ")";
jsLit[h_Symbol[a___]] := "R.E(" <> q[SymbolName[h]] <> If[{a} === {}, "", ", " <> StringRiffle[jsLit /@ {a}, ", "]] <> ")";

translateSymbol[HoldComplete[s_Symbol]] := Module[{out = {}, name = SymbolName[Unevaluated[s]]},
   If[OwnValues[s] =!= {}, AppendTo[out, "R.G[" <> q[name] <> "] = " <> jsLit[s] <> ";"]];
   If[MemberQ[$dynamic, name] && OwnValues[s] === {}, AppendTo[out, "R.G[" <> q[name] <> "] = [];"]];
   If[DownValues[s] =!= {}, AppendTo[out, "R.F[" <> q[name] <> "] = R.defn(" <> q[name] <> ", [\n  " <>
       StringRiffle[Replace[DownValues[s], (Verbatim[HoldPattern][lhs_] :> rhs_) :> defClause[Hold[lhs], Hold[rhs]], {1}], ",\n  "] <> "\n]);"]];
   If[SubValues[s] =!= {}, AppendTo[out, "R.SUB[" <> q[name] <> "] = R.subDefn(" <> q[name] <> ", [\n  " <>
       StringRiffle[Replace[SubValues[s], (Verbatim[HoldPattern][lhs_] :> rhs_) :> subClause[Hold[lhs], Hold[rhs]], {1}], ",\n  "] <> "\n]);"]];
   StringRiffle[out, "\n"]];
translateSymbols[syms_List] := Block[{$locals = {}}, StringRiffle[DeleteCases[translateSymbol /@ (Replace[syms, s_Symbol :> HoldComplete[s], {1}]), ""], "\n\n"]];

(* ---------- what the simplifier needs ---------- *)
eng = "Simplifier`Engine`";
modes[] := Flatten[Table[{pv, sp, sy, ri, pf, rf}, {pv, {True, False}}, {sp, {False, True}}, {sy, {False, True}}, {ri, {False, True}}, {pf, {False, True}}, {rf, {False, True}}], 5];
modeKey[{pv_, sp_, sy_, ri_, pf_, rf_}] := StringRiffle[{If[pv, "star", "vee"], If[sp, "sph", "-"], If[sy, "sym", "-"], If[ri, "rib", "-"], If[pf, "pre", "-"], If[rf, "rf", "-"]}, "|"];
ruleSetTable[] := Association[(modeKey[#] -> KeyValueMap[{#1, #2[[1]], #2[[2]]} &,
       Simplifier`ruleSet["Duals" -> If[#[[1]], "star", "vee"], "Spherical" -> #[[2]], "Symmetric" -> #[[3]], "Ribbon" -> #[[4]], "PreFusion" -> #[[5]], "RightZigzagFirst" -> #[[6]]]]) & /@ modes[]];
symsIn[e_] := Union@Cases[e, x_Symbol :> HoldComplete[x], Infinity, Heads -> True];
SetAttributes[symsIn, HoldAllComplete];
engH[HoldComplete[x_]] := MemberQ[$engineContexts, Context[Unevaluated[x]]];
dataQ[v_] := MatchQ[v, _String | _Integer | {___?dataQ} | _Association];   (* a global constant the rules read; leftovers of the notebooks (diagrams) are not *)
usefulH[h : HoldComplete[x_]] := engH[h] && (DownValues[x] =!= {} || SubValues[x] =!= {} || MemberQ[$dynamic, SymbolName[Unevaluated[x]]] || (OwnValues[x] =!= {} && dataQ[x]));
depsH[HoldComplete[x_]] := Select[symsIn @@ {Join[DownValues[x], OwnValues[x], SubValues[x]]}, usefulH];
simplifierClosure[] := Module[{roots},
   roots = Union[Cases[Values[ruleSetTable[]], {_, _, f_} :> HoldComplete @@ {If[AtomQ[f], f, Head[f]]}, Infinity],
     ToExpression[eng <> #, InputForm, HoldComplete] & /@ {"normalize", "rewriteOnce", "lTrace", "pairings", "inverses", "retracts", "lSimples", "lBound"},
     {HoldComplete[DiagramToExpression`jsonToLD], HoldComplete[DiagramToExpression`ldToJSON], HoldComplete[DiagramToExpression`editorSymbol], HoldComplete[DiagramToExpression`editorName]}];
   SortBy[FixedPoint[Union[#, Flatten[depsH /@ #]] &, Select[roots, usefulH]], Function[h, SymbolName @@ (Unevaluated /@ h)]]];

translateSimplifier[file_String] := Module[{syms, body, table, js, api},
   $unsupported = {};
   syms = simplifierClosure[];
   body = translateSymbols[syms];
   table = "R.RULESETS = " <> jsLit[ruleSetTable[]] <> ";";
   api = Import[FileNameJoin[{$dir, "simplifier-js-api.js"}], "Text", CharacterEncoding -> "UTF-8"];
   js = StringJoin["/* simplifier-generated.js — the CCN String Diagrams simplifier, translated from Wolfram by wl-to-js.wl.\n",
     "   Do not edit: run translateSimplifier again after changing the Wolfram rules.\n",
     "   Generated ", DateString["ISODateTime"], " from ", ToString[Length[syms]], " Wolfram symbols.\n",
     "   By Dara O Shayda and Noor Hoshino (星野ヌール) · © Computational Classnotes · CC BY-NC-SA 4.0 */\n",
     "'use strict';\n(function (root) {\nconst R = (typeof module !== 'undefined' && module.exports && typeof require !== 'undefined') ? require('./wl-runtime.js') : root.WLRuntime;\n\n",
     body, "\n\n", table, "\n\n", api, "\n})(typeof globalThis !== 'undefined' ? globalThis : this);\n"];
   Export[file, js, "Text", CharacterEncoding -> "UTF-8"];
   $WLToJSUnsupported = Union[$unsupported];
   If[$WLToJSUnsupported =!= {}, Message[WLToJS::unsupported, $WLToJSUnsupported]];
   <|"File" -> file, "Symbols" -> Length[syms], "Definitions" -> Total[Function[h, Length[DownValues @@ h] + Length[SubValues @@ h]] /@ syms],
     "Modes" -> Length[modes[]], "Bytes" -> FileByteCount[file], "Unsupported" -> $WLToJSUnsupported|>];
End[];
EndPackage[];
