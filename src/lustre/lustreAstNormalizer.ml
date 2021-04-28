(* This file is part of the Kind 2 model checker.

   Copyright (c) 2020 by the Board of Trustees of the University of Iowa

   Licensed under the Apache License, Version 2.0 (the "License"); you
   may not use this file except in compliance with the License.  You
   may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0 

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
   implied. See the License for the specific language governing
   permissions and limitations under the License. 

 *)
(** Normalize a Lustre AST to ease in translation to a transition system

  The two main requirements of this normalization are to:
    1. Guard any unguarded pre expressions 
    2. Generate any needed local identifiers or oracles

  Identifiers are constructed with a numeral prefix followed by a type suffix.
  e.g. 2_glocal or 6_oracle. These are not valid lustre identifiers and are
  expected to be transformed into indexes with the numeral as a branch and the
  suffix type as the leaf.

  Generated locals/oracles are referenced inside the AST via an Ident expression
  but the actual definition is not added to the AST. Instead it is recoreded in
  the generated_identifiers record.

  pre operators are explicitly guarded in the AST by an oracle variable
  if they were originally unguarded
    e.g. pre expr => oracle -> pre expr

  The following parts of the AST are abstracted by locals:

  1. Arguments to node calls that are not identifiers
    e.g.
      Node expr1 expr2 ... exprn
      =>
      Node l1 l2 ... ln
    where each li is a local variable and li = expri

  2. Arguments to the pre operator that are not identifiers
    e.g.
      pre expr => pre l
    where l = expr

  3. Node calls
    e.g.
      x1, ..., xn = ... op node_call(a, b, c) op ...
      => x1, ..., xn = ... op (l1, ..., ln) op ...
    where (l1, ..., ln) is a group (list) expression
      and each li corresponds to an output of the node_call
      If node_call has only one output, it is instead just an ident expression
    (Note that there is no generated equality here, how the node call is
      referenced at the stage of a LustreNode is by the node_call record where
      the output holds the state variables produced by the node call)

     @author Andrew Marmaduke *)

open Lib

module A = LustreAst
module AH = LustreAstHelpers
module Ctx = TypeCheckerContext

module StringMap = struct
  include Map.Make(struct
    type t = string
    let compare i1 i2 = String.compare i1 i2
  end)
  let keys: 'a t -> key list = fun m -> List.map fst (bindings m)
end

type generated_identifiers = {
    locals : LustreAst.expr StringMap.t;
    oracles : (LustreAst.ident * LustreAst.expr) list;
    calls : ((string list) (* abstraction variables *)
      * LustreAst.expr (* condition expression *)
      * LustreAst.expr (* restart expression *)
      * string (* node name *)
      * (LustreAst.expr list) (* node arguments *)
      * (LustreAst.expr list option)) (* node argument defaults *)
      list
}

let pp_print_generated_identifiers ppf gids =
  let locals_list = StringMap.bindings gids.locals |> List.rev in
  let pp_print_local = pp_print_pair
    Format.pp_print_string
    A.pp_print_expr
    " = "
  in let pp_print_oracle = pp_print_pair
    Format.pp_print_string
    LustreAst.pp_print_expr
    ":"
  in let pp_print_call = (fun ppf (vars, cond, restart, ident, args, defaults) ->
    Format.fprintf ppf 
    "%a = call(%a,(restart %a every %a)(%a),%a)"
    (pp_print_list Format.pp_print_string ",@") vars
      A.pp_print_expr cond
      Format.pp_print_string ident
      A.pp_print_expr restart
      (pp_print_list A.pp_print_expr ",@ ") args
      (pp_print_option
        (pp_print_list A.pp_print_expr ",@ ")) defaults)
  in Format.fprintf ppf "%a\n%a\n%a"
    (pp_print_list pp_print_oracle "\n") gids.oracles
    (pp_print_list pp_print_local "\n") locals_list
    (pp_print_list pp_print_call "\n") gids.calls


(* [i] is module state used to guarantee newly created identifiers are unique *)
let i = ref 0

let empty = {
    locals = StringMap.empty;
    oracles = [];
    calls = [];
  }

let union_keys key id1 id2 = match key, id1, id2 with
  | key, None, None -> None
  | key, (Some v), None -> Some v
  | key, None, (Some v) -> Some v
  (* Identifiers are guaranteed to be unique making this branch impossible *)
  | key, (Some v1), (Some v2) -> assert false

let union ids1 ids2 = {
    locals = StringMap.merge union_keys ids1.locals ids2.locals;
    oracles = ids1.oracles @ ids2.oracles;
    calls = ids1.calls @ ids2.calls
  }

let union_list ids =
  List.fold_left (fun x y -> union x y ) empty ids

let mk_fresh_local expr =
  i := !i + 1;
  let prefix = string_of_int !i in
  let name = prefix ^ "_glocal" in
  let nexpr = A.Ident (Lib.dummy_pos, name) in
  let glocal = StringMap.singleton name expr in
  let gids = { locals = glocal;
    oracles = [];
    calls = [] }
  in nexpr, gids

let mk_fresh_oracle ident =
  i := !i + 1;
  let prefix = string_of_int !i in
  let name = prefix ^ "_oracle" in
  let nexpr = A.Ident (Lib.dummy_pos, name) in
  let gids = { locals = StringMap.empty;
    oracles = [name, ident];
    calls = [] }
  in nexpr, gids

let compute_node_arity ctx ident =
  let node_type = Ctx.lookup_node_ty ctx ident in
  match node_type with
    | Some (A.GroupType ( _, list)) -> List.length list
    | _ -> assert false (* Nodes must have a group type *)

let mk_fresh_call arity cond restart ident args defaults =
  let abstractions = List.init arity (fun x ->
    i := !i + 1;
    let prefix = string_of_int !i in
    prefix ^ "_call")
  in let expr_list = List.map
    (fun name -> A.Ident (Lib.dummy_pos, name))
    abstractions
  in let nexpr = if arity == 1 then 
    List.hd expr_list
    else A.GroupExpr (Lib.dummy_pos, A.ExprList, expr_list) in
  let call = (abstractions, cond, restart, ident, args, defaults) in
  let gids = { locals = StringMap.empty;
    oracles = [];
    calls = [call] }
  in nexpr, gids

let normalize_list ctx f list =
  let over_list (nitems, gids) item =
    let (normal_item, ids) = f ctx item in
    normal_item :: nitems, union ids gids
  in List.fold_left over_list ([], empty) list

let rec normalize (ctx:TypeCheckerContext.tc_context) (decls:LustreAst.t) =
  let over_declarations (nitems, node_maps) item =
    let (normal_item, node_map) = normalize_declaration ctx item in
    normal_item :: nitems, StringMap.merge union_keys node_map node_maps
  in let ast, node_map = List.fold_left over_declarations ([], StringMap.empty) decls in
  
  Log.log L_trace ("===============================================\n"
    ^^ "Generated Identifiers:\n%a\n\n"
    ^^ "Normalized lustre AST:\n%a\n"
    ^^ "===============================================\n")
    (pp_print_list
      (pp_print_pair
        Format.pp_print_string
        pp_print_generated_identifiers
        ":")
      "\n")
      (StringMap.bindings node_map)
    A.pp_print_program ast;

  Res.ok (ast, node_map)

and normalize_declaration ctx = function
  | NodeDecl (pos, decl) ->
    let normal_decl, node_map = normalize_node ctx decl in
    A.NodeDecl(pos, normal_decl), node_map
  | FuncDecl (pos, decl) ->
    let normal_decl, node_map = normalize_node ctx decl in
    A.FuncDecl (pos, normal_decl), node_map
  | decl -> decl, StringMap.empty

and normalize_node ctx
    (id, is_func, params, inputs, outputs, locals, items, contracts) =
  let nitems, gids1 = normalize_list ctx normalize_item items in
  let ncontracts, gids2 = match contracts with
    | Some contracts ->
      let ncontracts, gids = normalize_list ctx normalize_contract contracts in
      (Some ncontracts), gids
    | None -> None, empty
  in let gids = union gids1 gids2 in
  let node_map = StringMap.singleton id gids in
  (id, is_func, params, inputs, outputs, locals, nitems, ncontracts), node_map

and normalize_item ctx = function
  | Body equation ->
    let nequation, gids = normalize_equation ctx equation in
    Body nequation, gids
  | AnnotMain b -> AnnotMain b, empty
  | AnnotProperty (pos, name, expr) ->
    let nexpr, gids = normalize_expr ctx expr in
    AnnotProperty (pos, name, nexpr), gids

and normalize_contract ctx = function
  | Assume (pos, name, soft, expr) ->
    let nexpr, gids = normalize_expr ctx expr in
    Assume (pos, name, soft, nexpr), gids
  | Guarantee (pos, name, soft, expr) -> 
    let nexpr, gids = normalize_expr ctx expr in
    Guarantee (pos, name, soft, nexpr), gids
  | Mode (pos, name, requires, ensures) ->
    let over_property ctx (pos, name, expr) =
      let nexpr, gids = normalize_expr ctx expr in
      (pos, name, nexpr), gids
    in
    let nrequires, gids1 = normalize_list ctx over_property requires in
    let nensures, gids2 = normalize_list ctx over_property ensures in
    Mode (pos, name, nrequires, nensures), union gids1 gids2
  | ContractCall (pos, name, inputs, outputs) ->
    let ninputs, gids = normalize_list ctx normalize_expr inputs in
    ContractCall (pos, name, ninputs, outputs), gids
  | decl -> decl, empty

and normalize_equation ctx = function
  | Assert (pos, expr) ->
    let nexpr, gids = normalize_expr ctx expr in
    Assert (pos, nexpr), gids
  | Equation (pos, lhs, expr) ->
    let nexpr, gids = normalize_expr ctx expr in
    Equation (pos, lhs, nexpr), gids
  | Automaton (pos, id, states, auto) -> Lib.todo __LOC__

and normalize_expr ?guard ctx  =
  let generate_fresh_ids ctx ?guard expr =
    (* If [expr] is already an id or const then we don't create a fresh local *)
    if AH.expr_is_id expr then
      expr, empty
    else
      let nexpr, gids1 = normalize_expr ctx ?guard expr in
      let iexpr, gids2 = mk_fresh_local nexpr in
      iexpr, union gids1 gids2
  in function
  (* ************************************************************************ *)
  (* Node calls                                                               *)
  (* ************************************************************************ *)
  | Call (pos, id, args) ->
    let arity = compute_node_arity ctx id in
    let cond = A.Const (Lib.dummy_pos, A.True) in
    let restart =  A.Const (Lib.dummy_pos, A.False) in
    let nargs, gids1 = normalize_list ctx (generate_fresh_ids ?guard) args in
    let nexpr, gids2 = mk_fresh_call arity cond restart id nargs None in
    nexpr, union gids1 gids2
  | Condact (pos, cond, restart, id, args, defaults) ->
    let arity = compute_node_arity ctx id in
    let ncond, gids1 = normalize_expr ?guard ctx cond in
    let nrestart, gids2 = normalize_expr ?guard ctx restart in
    let nargs, gids3 = normalize_list ctx (generate_fresh_ids ?guard) args in
    let ndefaults, gids4 = normalize_list ctx (normalize_expr ?guard) defaults in
    let nexpr, gids5 = mk_fresh_call arity ncond nrestart id nargs (Some ndefaults) in
    let gids = union_list [gids1; gids2; gids3; gids4; gids5] in
    nexpr, gids
  | RestartEvery (pos, id, args, restart) ->
    let arity = compute_node_arity ctx id in
    let cond = A.Const (dummy_pos, A.True) in
    let nrestart, gids1 = normalize_expr ?guard ctx restart in
    let nargs, gids2 = normalize_list ctx (generate_fresh_ids ?guard) args in
    let nexpr, gids3 = mk_fresh_call arity cond nrestart id nargs None in
    let gids = union_list [gids1; gids2; gids3] in
    nexpr, gids
  (* ************************************************************************ *)
  (* Guarding and abstracting pres                                            *)
  (* ************************************************************************ *)
  | Arrow (pos, expr1, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard:(Some nexpr1) ctx expr2 in
    let gids = union gids1 gids2 in
    Arrow (pos, nexpr1, nexpr2), gids
  | Pre (pos, expr) ->
    let nexpr, gids1 = (generate_fresh_ids ctx ?guard) expr in
    let guard, gids2, previously_guarded = match guard with
      | Some guard -> guard, empty, true
      | None -> let guard, gids = mk_fresh_oracle nexpr in
        guard, gids, false
    in let gids = union gids1 gids2 in
    if previously_guarded then Pre (pos, nexpr), gids
    else Arrow (Lib.dummy_pos, guard, Pre (pos, nexpr)), gids
  (* ************************************************************************ *)
  (* The remaining expr kinds are all just structurally recursive             *)
  (* ************************************************************************ *)
  | Ident _ as expr -> expr, empty
  | ModeRef _ as expr -> expr, empty
  | RecordProject (pos, expr, i) ->
    let nexpr, gids = normalize_expr ?guard ctx expr in
    RecordProject (pos, nexpr, i), gids
  | TupleProject (pos, expr, i) ->
    let nexpr, gids = normalize_expr ?guard ctx expr in
    TupleProject (pos, nexpr, i), gids
  | Const _ as expr -> expr, empty
  | UnaryOp (pos, op, expr) ->
    let nexpr, gids = normalize_expr ?guard ctx expr in
    UnaryOp (pos, op, nexpr), gids
  | BinaryOp (pos, op, expr1, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    BinaryOp (pos, op, nexpr1, nexpr2), union gids1 gids2
  | TernaryOp (pos, op, expr1, expr2, expr3) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    let nexpr3, gids3 = normalize_expr ?guard ctx expr3 in
    let gids = union (union gids1 gids2) gids3 in
    TernaryOp (pos, op, nexpr1, nexpr2, nexpr3), gids
  | NArityOp (pos, op, expr_list) ->
    let nexpr_list, gids = normalize_list ctx (normalize_expr ?guard) expr_list in
    NArityOp (pos, op, nexpr_list), gids
  | ConvOp (pos, op, expr) ->
    let nexpr, gids = normalize_expr ?guard ctx expr in
    ConvOp (pos, op, nexpr), gids
  | CompOp (pos, op, expr1, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    CompOp (pos, op, nexpr1, nexpr2), union gids1 gids2
  | RecordExpr (pos, id, id_expr_list) ->
    let normalize' ctx ?guard (id, expr) =
      let nexpr, gids = normalize_expr ?guard ctx expr in
      (id, nexpr), gids
    in 
    let nid_expr_list, gids = normalize_list ctx (normalize' ?guard) id_expr_list in
    RecordExpr (pos, id, nid_expr_list), gids
  | GroupExpr (pos, kind, expr_list) ->
    let nexpr_list, gids = normalize_list ctx (normalize_expr ?guard) expr_list in
    GroupExpr (pos, kind, nexpr_list), gids
  | StructUpdate (pos, expr1, i, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    StructUpdate (pos, nexpr1, i, nexpr2), union gids1 gids2
  | ArrayConstr (pos, expr1, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    ArrayConstr (pos, nexpr1, nexpr2), union gids1 gids2
  | ArraySlice (pos, expr1, (expr2, expr3)) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    let nexpr3, gids3 = normalize_expr ?guard ctx expr3 in
    let gids = union (union gids1 gids2) gids3 in
    ArraySlice (pos, nexpr1, (nexpr2, nexpr3)), gids
  | ArrayIndex (pos, expr1, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    ArrayIndex (pos, nexpr1, nexpr2), union gids1 gids2
  | ArrayConcat (pos, expr1, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    ArrayConcat (pos, nexpr1, nexpr2), union gids1 gids2
  | Quantifier (pos, kind, vars, expr) ->
    let nexpr, gids = normalize_expr ?guard ctx expr in
    Quantifier (pos, kind, vars, nexpr), gids
  | When (pos, expr, clock_expr) ->
    let nexpr, gids = normalize_expr ?guard ctx expr in
    When (pos, nexpr, clock_expr), gids
  | Current (pos, expr) ->
    let nexpr, gids = normalize_expr ?guard ctx expr in
    Current (pos, nexpr), gids
  | Activate (pos, id, expr1, expr2, expr_list) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    let nexpr_list, gids3 = normalize_list ctx (normalize_expr ?guard) expr_list in
    let gids = union (union gids1 gids2) gids3 in
    Activate (pos, id, nexpr1, nexpr2, nexpr_list), gids
  | Merge (pos, id, id_expr_list) ->
    let normalize' ctx ?guard (id, expr) =
    let nexpr, gids = normalize_expr ?guard ctx expr in
      (id, nexpr), gids
    in 
    let nid_expr_list, gids = normalize_list ctx (normalize' ?guard) id_expr_list in
    Merge (pos, id, nid_expr_list), gids
  | Last _ as expr -> expr, empty
  | Fby (pos, expr1, i, expr2) ->
    let nexpr1, gids1 = normalize_expr ?guard ctx expr1 in
    let nexpr2, gids2 = normalize_expr ?guard ctx expr2 in
    Fby (pos, nexpr1, i, nexpr2), union gids1 gids2
  | CallParam (pos, id, type_list, expr_list) ->
    let nexpr_list, gids = normalize_list ctx (normalize_expr ?guard) expr_list in
    CallParam (pos, id, type_list, nexpr_list), gids
