(* This file is part of the Kind 2 model checker.

   Copyright (c) 2015 by the Board of Trustees of the University of Iowa

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

open Lib

(* Module abbreviations *)
module I = LustreIdent 
module D = LustreIndex
module E = LustreExpr

type contract =
  { 

    (* Identifier of contract *)
    contract_name : LustreIdent.t;

    (* Position of the contract in the input *)
    contract_pos: position;

    (* Invariant from requirements of contract *)
    contract_req : LustreExpr.expr;

    (* Invariant from ensures of contract *)
    contract_ens : LustreExpr.expr

  }


type t = 

  {

    name : LustreIdent.t;

    inputs : StateVar.t LustreIndex.t;

    outputs : StateVar.t LustreIndex.t;

    output_ufs : UfSymbol.t LustreIndex.t;

    global_contracts : contract list;

    mode_contracts : contract list;

  }


(* An empty function *)
let empty_function name = 
  { name = name;
    inputs = D.empty;
    outputs = D.empty;
    output_ufs = D.empty;
    global_contracts = [];
    mode_contracts = [] }



(* Pretty-print array bounds of index *)
let pp_print_array_dims safe ppf idx = 

  match D.array_bounds_of_index idx with 

    (* Print only if not empty *)
    | [] -> ()

    | bounds -> 

      Format.fprintf 
        ppf
        "^%a"
        (pp_print_list (E.pp_print_expr safe) "^")
        bounds


(* Pretty-print a function input or output *)
let pp_print_input_output safe ppf (idx, var) =

  Format.fprintf ppf
    "%a: %a%a"
    (E.pp_print_lustre_var safe) var
    (E.pp_print_lustre_type safe) (StateVar.type_of_state_var var)
    (pp_print_array_dims safe) idx



(* Pretty-print an assumption *)
let pp_print_require safe ppf expr =
  Format.fprintf ppf
    "@[<hv 2>--@@require@ @[<h>%a@];@]"
    (E.pp_print_expr safe) expr


(* Pretty-print a guarantee *)
let pp_print_ensure safe ppf sv =
  Format.fprintf ppf
    "@[<hv 2>--@@ensure @[<h>%a@];@]"
    (E.pp_print_expr safe) sv


(* Pretty-print a named mode contract. *)
let pp_print_mode_contract safe ppf { contract_name; contract_req; contract_ens } =
  Format.fprintf
    ppf
    "@[<v>--@@contract %a;@,%a@,%a@]"
    (I.pp_print_ident false) contract_name
    (pp_print_require safe) contract_req
    (pp_print_ensure safe) contract_ens


(* Pretty-print an anonymous global contract. *)
let pp_print_global_contract 
    safe
    ppf
    { contract_name; contract_req; contract_ens } =

    Format.fprintf
      ppf
      "@[<v>-- %a@,%a@,%a@]"
      (I.pp_print_ident false) contract_name
      (pp_print_require safe) contract_req
      (pp_print_ensure safe) contract_ens


(* Pretty-print a node *)
let pp_print_function 
    safe
    ppf 
    { name;
      inputs; 
      outputs; 
      output_ufs;
      global_contracts;
      mode_contracts } = 

  Format.fprintf ppf 
    "@[<hv>@[<hv 2>function %a@ @[<hv 1>(%a)@]@;<1 -2>\
     returns@ @[<hv 1>(%a)@];@]@ \
     @[<v>%a@]%t@[<v>%a@]@\n%a"

    (* %a *)
    (I.pp_print_ident safe) name

    (* %a *)
    (pp_print_list (pp_print_input_output safe) ";@ ") 
    (List.map
       (* Remove first index of input argument for printing *)
       (function ([], e) -> ([], e) | (_ :: tl, e) -> (tl, e))
       (D.bindings inputs))

    (* %a *)
    (pp_print_list (pp_print_input_output safe) ";@ ") 
    (List.map
       (* Remove first index of output argument for printing *)
       (function ([], e) -> ([], e) | (_ :: tl, e) -> (tl, e))
       (D.bindings outputs))

    (pp_print_list (pp_print_global_contract safe) "@,") global_contracts

    (function ppf -> 
      if global_contracts <> [] && mode_contracts <> [] then 
        Format.pp_print_newline ppf ())

    (pp_print_list (pp_print_mode_contract safe) "@,") mode_contracts

    (pp_print_list UfSymbol.pp_print_uf_symbol "@,") (D.values output_ufs)

(* ********************************************************************** *)
(* Find functions in lists                                                *)
(* ********************************************************************** *)


(* Return true if a node of the given name exists in the a list of nodes *)
let exists_function_of_name name functs =

  List.exists
    (function { name = funct_name } -> name = funct_name)
    functs


(* Return the node of the given name from a list of nodes *)
let function_of_name name functs =

  List.find
    (function { name = funct_name } -> name = funct_name)
    functs


(* Return the name of the function *)
let name_of_function { name } = name

(* Return the scope of the name of the function *)
let scope_of_function { name } = name |> I.to_scope
