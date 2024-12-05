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

(** Term representation

    Terms are hashconsed for maximal sharing, comparison with physical
    equality and to store type information.

    Terms are lambda trees, see {!Ltree}, with symbols of type
    {!Symbol.t}, free variables of type {!Var.t} and types {!Type.t}.

    The type {!t} is private and cannot be constructed outside
    this module in order to ensure that all equal subterms are
    physically equal for hashconsing.

    Use the constructor functions like {!mk_true}, {!mk_num} etc. to
    construct terms. An exception will be raised if an incorrectly
    typed term is constructed.

    @author Christoph Sticksel, Arjun Viswanathan
*)


(** {1 Types and hash-consing} *)

module T : Ltree.S
  with type symbol = Symbol.t
  and type var = Var.t
  and type sort = Type.t

(** Terms are hashconsed abstract syntax trees *)
type t = T.t
    
(** Terms are hashconsed abstract syntax trees *)
type lambda = T.lambda

(** {1 Hashtables, maps and sets} *)

(** Comparison function on terms *)
val compare : t -> t -> int

(** Equality function on terms *)
val equal : t -> t -> bool

(** Hashing function on terms *)
val hash : t -> int

(** Unique identifier for terms *)
val tag : t -> int

(** Hash table over terms *)
module TermHashtbl : Hashtbl.S with type key = t

(** Set over terms *)
module TermSet : Set.S with type elt = t

(** Map over terms *)
module TermMap : Map.S with type key = t


(** {1 Constructors} *)

(** Create a hashconsed term *)
val mk_term : T.t_node -> t

(** Create a hashconsed lambda expression *)
val mk_lambda : Var.t list -> t -> lambda

(** Import a term from a different instance into this hashcons table *)
val import : t -> t

(** Import a term from a different instance into this hashcons table *)
val import_lambda : lambda -> lambda

(** Returns true if the lamda expression is the identity, i.e. lambda x.x *)
val is_lambda_identity : lambda -> bool

(** Create the propositional constant [true] *)
val mk_true : unit -> t

(** Create the propositional constant [false] *)
val mk_false : unit -> t

(** Create an Boolean negation

    Hint: consider using {!negate} to avoid double negations *)
val mk_not : t -> t

(** Create a Boolean implication *)
val mk_implies : t list -> t

(** Create an Boolean conjunction *)
val mk_and : t list -> t

(** Create an Boolean disjunction *)
val mk_or : t list -> t

(** Create an Boolean exclusive disjunction *)
val mk_xor : t list -> t

(** Create an equality *)
val mk_eq : t list -> t

(** Create an pairwise distinct predicate *)
val mk_distinct : t list -> t

(** Create an if-then-else term *)
val mk_ite : t -> t -> t -> t

(** Create an integer numeral *)
val mk_num : Numeral.t -> t

(** Create an integer numeral *)
val mk_num_of_int : int -> t

(** Create a constructor encoded as a numeral *)
val mk_constr : string -> t

(** Create a floating point decimal *)
val mk_dec : Decimal.t -> t

(*
(** Create a floating point decimal *)
val mk_dec_of_float : float -> t
*)


(* @author Arjun Viswanathan*)
(** Create a constant unsigned bitvector *)
val mk_ubv : Bitvector.t -> t

(** Create a constant bitvector *)
val mk_bv : Bitvector.t -> t

(** Create a signed bitvector sum *)
val mk_bvadd : t list -> t

(** Create a signed bitvector difference *)
val mk_bvsub : t list -> t

(** Create a bitvector produce *)
val mk_bvmul : t list -> t

(** Create a bitvector division *)
val mk_bvudiv : t list -> t

(**Create a signed bitvector division *)
val mk_bvsdiv : t list -> t

(** Create a bitvector modulus *)
val mk_bvurem : t list -> t

(** Create a signed bitvector modulus *)
val mk_bvsrem : t list -> t

(** Create a bitvector conjunction *)
val mk_bvand : t list -> t

(** Create a bitvector disjunction *)
val mk_bvor : t list -> t

(** Create a bitwise negation *)
val mk_bvnot : t -> t

(** Create a bitvector negation (2's complement) *)
val mk_bvneg : t -> t

(** Negates a term by modifying the top node if it is a bvneg or an
   machine integer constant. *)
val mk_bvneg_simplify : t -> t

(** Create a bitvector left shift *)
val mk_bvshl : t list -> t

(** Create a bitvector logical right shift *)
val mk_bvlshr : t list -> t

(** Create a bitvector arithmetic right shift *)
val mk_bvashr : t list -> t

(** Create an unsigned bitvector less-than comparison *)
val mk_bvult : t list -> t

(** Create an unsigned bitvector less-than-or-equal-to comparison *)
val mk_bvule : t list -> t

(** Create an unsigned bitvector greater-than comparison *)
val mk_bvugt : t list -> t

(** Create an unsigned bitvector greater-than-or-eqaul-to comparison *)
val mk_bvuge : t list -> t

(** Create a bitvector less-than comparison *)
val mk_bvslt : t list -> t

(** Create a bitvector less-than-or-equal-to comparison *)
val mk_bvsle : t list -> t

(** Create a bitvector greater-than comparison *)
val mk_bvsgt : t list -> t

(** Create a bitvector greater-than=or-eqaul-to comparison *)
val mk_bvsge : t list -> t


(** Create an integer or real difference *)
val mk_minus : t list -> t

(** Create an integer or real sum *)
val mk_plus : t list -> t

(** Create an integer or real product *)
val mk_times : t list -> t

(** Create a real quotient *)
val mk_div : t list -> t

(** Create an integer quotient *)
val mk_intdiv : t list -> t

(** Create an integer modulus *)
val mk_mod : t -> t -> t

(** Create an absolute value *)
val mk_abs : t -> t

(** Create a less-or-equal predicate *)
val mk_leq : t list -> t

(** Create a less-than predicate *)
val mk_lt : t list -> t

(** Create a greater-or-equal predicate *)
val mk_geq : t list -> t

(** Create a greater-than predicate *)
val mk_gt : t list -> t

(** Create a conversion to a real decimal *)
val mk_to_real : t -> t

(** Create a conversion to an integer numeral *)
val mk_to_int : t -> t

(** Create a conversion from uint8 to an integer numeral *)
val mk_uint8_to_int : t -> t

(** Create a conversion from uint16 to an integer numeral *)
val mk_uint16_to_int : t -> t

(** Create a conversion from uint32 to an integer numeral *)
val mk_uint32_to_int : t -> t

(** Create a conversion from uint64 to an integer numeral *)
val mk_uint64_to_int : t -> t

(** Create a conversion from int8 to an integer numeral *)
val mk_int8_to_int : t -> t

(** Create a conversion from int16 to an integer numeral *)
val mk_int16_to_int : t -> t

(** Create a conversion from int32 to an integer numeral *)
val mk_int32_to_int : t -> t

(** Create a conversion from int64 to an integer numeral *)
val mk_int64_to_int : t -> t

(** Create a conversion to an unsigned integer8 numeral *)
val mk_to_uint8 : t -> t

(** Create a conversion to an unsigned integer16 numeral *)
val mk_to_uint16 : t -> t

(** Create a conversion to an unsigned integer32 numeral *)
val mk_to_uint32 : t -> t

(** Create a conversion to an unsigned integer64 numeral *)
val mk_to_uint64 : t -> t

(** Create a conversion to an integer8 numeral *)
val mk_to_int8 : t -> t

(** Create a conversion to an integer16 numeral *)
val mk_to_int16 : t -> t

(** Create a conversion to an integer32 numeral *)
val mk_to_int32 : t -> t

(** Create a conversion to an integer64 numeral *)
val mk_to_int64 : t -> t

(** Create a bitvector to nat conversion *)
val mk_bv2nat : t -> t

(** Create a BV extraction *)
val mk_bvextract : Numeral.t -> Numeral.t -> t -> t

(** Create a BV concatenation *)
val mk_bvconcat : t -> t -> t

(** Create a BV sign extension *)
val mk_bvsignext : Numeral.t -> t -> t

(** Create a predicate for coincidence of a real with an integer *)
val mk_is_int : t -> t

(** Create a predicate for divisibility by a constant integer *)
val mk_divisible : Numeral.t -> t -> t

(** Create select from an array at a particular index *)
val mk_select : t -> t -> t

(** Functionally update an array at a given index *)
val mk_store : t -> t -> t -> t

(** Uniquely name a term with an integer and return a named term and
    its name *)
val mk_named : t -> int * t

(** [set_inter_group t g] associates term [t] with
    interpolation group [g] and return the corresponing
    interpolation group term *)
val set_inter_group : t -> string -> t

(** Name term with the given integer in a given namespace

    This is a basic function, the caller has to generate the name, and
    ensure the name is used only once. Use with caution, or better
    only use {!mk_named}, which will create a unique name.

    The namespace ["t"] will be rejected, because this is the
    namespace used by {!mk_named}. *)
val mk_named_unsafe : t -> string -> int -> t 

(** Create an uninterpreted constant or function *)
val mk_uf : UfSymbol.t -> t list -> t
    
(** Create a symbol to be bound to a term *)
val mk_var : Var.t -> t 

(** Create a binding of symbols to terms *)
val mk_let : (Var.t * t) list -> t -> t

(** Return a hashconsed existentially quantified term *)
val mk_exists : ?fundef:bool -> Var.t list -> t -> t

(** Return a hashconsed universally quantified term *)
val mk_forall : ?fundef:bool -> Var.t list -> t -> t

(** {1 Constant terms} *)

(** The propositional constant [true] *)
val t_true : t 

(** The propositional constant [false] *)
val t_false : t 


(** {2 Prefix and infix operators for term construction} *)

module Abbrev :
sig

  (** Prefix operator to create an numeral *)
  val ( ?%@ ) : int -> t

  (** Prefix operator to create an Boolean negation *)
  val ( !@ ) : t -> t

  (** Infix operator to create a Boolean implication *)
  val ( =>@ ) : t -> t -> t

  (** Infix operator to create a Boolean conjunction *)
  val ( &@ ) : t -> t -> t

  (** Infix operator to create a Boolean disjunction *)
  val ( |@ ) : t -> t -> t

  (** Infix operator to create an equality *)
  val ( =@ ) : t -> t -> t 

  (** Prefix operator to create an integer or real negation *)
  val ( ~@ ) : t -> t

  (** Infix operator to create an integer or real difference *)
  val ( -@ ) : t -> t -> t

  (** Infix operator to create an integer or real sum *)
  val ( +@ ) : t -> t -> t

  (** Infix operator to create an integer or real product *)
  val ( *@ ) : t -> t -> t

  (** Infix operator to create a real quotient *)
  val ( //@ ) : t -> t -> t

  (** Infix operator to create an integer quotient *)
  val ( /%@ ) : t -> t -> t

  (** Infix operator to create a less-or-equal predicate *)
  val ( <=@ ) : t -> t -> t

  (** Infix operator to create a less-than predicate *)
  val ( <@ ) : t -> t -> t

  (** Infix operator to create a greater-or-equal predicate *)
  val ( >=@ ) : t -> t -> t

  (** Infix operator to create a greater-than predicate *)
  val ( >@ ) : t -> t -> t

end

(** {1 Additional term constructors} *)

(** Create the propositional constant [true] or [false] *)
val mk_bool : bool -> t 

(** Create a constant *)
val mk_const_of_symbol_node : Symbol.symbol -> t 

(** Create constant of a hashconsed symbol *)
val mk_const : Symbol.t -> t 

(** Create a function application *)
val mk_app_of_symbol_node : Symbol.symbol -> t list -> t

(** Create a function application of a hashconsed symbol *)
val mk_app : Symbol.t -> t list -> t

(** Increment integer or real term by one *)
val mk_succ : t -> t 

(** Decrement integer or real term by one *)
val mk_pred : t -> t

(** Negate term, avoiding double negation *)
val negate : t -> t

(* Negates a term by modifying the top node if it is a uminus or an
   arithmetic constant. *)
val mk_minus_simplify : t -> t

(** Negates a term by modifying the top node if it is a not, true,
    false, or an arithmetic inequality. *)
val negate_simplify : t -> t 

(** Remove top negation from term, otherwise return term unchanged *)
val unnegate : t -> t 

(** {1 Accessor functions} *)

(** Return the type of the term *)
val type_of_term : t -> Type.t

(** Return the node of the hashconsed term *)
val node_of_term : t -> T.t_node

(** Flatten top node of term *)
val destruct : t -> T.flat

(** Returns [true] if the term has quantifiers *)
val has_quantifier : t -> bool

(** Convert a flat term to a term *)
val construct : T.flat -> t

val get_atoms : t -> TermSet.t

(** Return true if the term is a simple Boolean atom, that is, has
    type Boolean and does not contain subterms of type Boolean *)
val is_atom : t -> bool

(** Return true if the top symbol of the term is a negation *)
val is_negated : t -> bool

(** Return [true] if the term is a free variable *)
val is_free_var : t -> bool

(** Return the variable of a free variable term *)
val free_var_of_term : t -> Var.t

(** Return [true] if the term is a bound variable *)
val is_bound_var : t -> bool

(** Return [true] if the term is a leaf symbol *)
val is_leaf : t -> bool

(** Return the symbol of a leaf term *)
val leaf_of_term : t -> Symbol.t

(** Return [true] if the term is a function application *)
val is_node : t -> bool

(** Return the symbol of a function application *)
val node_symbol_of_term : t -> Symbol.t

(** Return the arguments of a function application *)
val node_args_of_term : t -> t list

(** Return [true] if the term is a let binding *)
val is_let : t -> bool

(** Return [true] if the term is an existential quantifier *)
val is_exists : t -> bool

(** Return true if the term is a universal quantifier *)
val is_forall : t -> bool 

(** Return true if the term is a named term *)
val is_named : t -> bool

(** Return the term of a named term *)
val term_of_named : t -> t

(** Return the name of a named term *)
val name_of_named : t -> int

(** Return true if the term is an interpolation group term *)
val is_interp_group : t -> bool

(** Return the term of an interpolation group term *)
val term_of_interp_group : t -> t

(** Return the name of an interpolation group term *)
val name_of_interp_group : t -> string


(** Return true if the term is an integer constant *)
val is_numeral : t -> bool

(** Return true if the term is a negative integer constant *)
val is_negative_numeral : t -> bool

(** Return integer constant of a term *)
val numeral_of_term : t -> Numeral.t

(** Return bitvector constant of a term (sign-agnostic) *)
val bitvector_of_term : t -> Bitvector.t

(** Return signed bitvector constant of a term *)
val sbitvector_of_term : t -> Bitvector.t

(** Return unsigned bitvector constant of a term *)
val ubitvector_of_term : t -> Bitvector.t

(** Return true if the term is a (sign-agnostic) bitvector consant *)
val is_bitvector : t -> bool

(** Return true if the term is a signed bitvector constant *)
val is_sbitvector : t -> bool

(** Return true if the term is an unsigned bitvector constant *)
val is_ubitvector : t -> bool

(** Return true if the term is a decimal constant *)
val is_decimal : t -> bool

(** Return decimal constant of a term *)
val decimal_of_term : t -> Decimal.t

(** Return true if the term is a Boolean constant *)
val is_bool : t -> bool

(** Return Boolean constant of a term *)
val bool_of_term : t -> bool

(** Return true if the term is an application of the select operator *)
val is_select : t -> bool

(** Return true if the term is an application of the store operator *)
val is_store : t -> bool

(** Return true if the term is an application of the ite operator *)
val is_ite : t -> bool

(** Return the indexes and the array variable of the select operator

    The array argument of a select is either another select operation
    or a variable. For the expression [(select (select A j) k)] return
    the pair [A] and [[j; k]]. *)
val indexes_and_var_of_select : t -> Var.t * t list

val array_and_indexes_of_select : t -> t * t list

val var_of_select_store : t -> Var.t

(** {1 Pretty-printing} *)

(** Pretty-print a term *)
val pp_print_term : Format.formatter -> t -> unit

(** Pretty-print a term to the standard formatter *)
val print_term : t -> unit

(** Return a string representation of a term *)
val string_of_term : t -> string 

(** Pretty-print a lambda abstraction *)
val pp_print_lambda : Format.formatter -> lambda -> unit

(** Pretty-print a lambda abstraction to the standard formatter *)
val print_lambda : lambda -> unit

(** Return a string representation of a lambda abstraction *)
val string_of_lambda : lambda -> string 

(** {1 Conversions} *)

(** Evaluate the term bottom-up and right-to-left. The evaluation
    function is called at each node of the term with the the term
    being evaluated, and the list of values computed for the
    subterms. Let bindings are lazily unfolded. *)
val eval_t : ?fail_on_quantifiers:bool -> (T.flat -> 'a list -> 'a) -> t -> 'a

(** Beta-evaluate a lambda expression *)
val eval_lambda : lambda -> t list -> t

(** Partialy Beta-evaluate a lambda expression *)
val partial_eval_lambda : lambda -> t list -> lambda

(** Tail-recursive bottom-up right-to-left map on the term
    
    Not every subterm is a proper term, since the de Bruijn indexes are
    shifted. Therefore, the function [f] is called with the number of
    let bindings the subterm is under as first argument, so that the
    indexes can be adjusted in the subterm if necessary. *)
val map : (int -> T.t -> T.t) -> t -> t

(*
(** Substitutes the free variables appearing in a term according to a
    state var mapping. *)
val substitute_variables : (StateVar.t * StateVar.t) list -> t -> t
*)

(** Apply a substitution variable -> term *)
val apply_subst : (Var.t * t) list -> t -> t

(** Return a new term with each state variable replaced 

    [map_state_vars t f] returns a new term of [t] with each occurring
    state variable [s] replaced by the result of the evaluation [f s].
*)
val map_state_vars : (StateVar.t -> StateVar.t) -> t -> t

(** Return a new term with each variable instance replaced *)
val map_vars : (Var.t -> Var.t) -> t -> t

(** Convert [(= 0 (mod t n))] to [(divisble n t)]

    The term [n] must be an integer numeral. *)
val mod_to_divisible : t -> t

(** Convert [(divisble n t)] to [(= 0 (mod t n))] *)
val divisible_to_mod : t -> t

(** Convert negative numerals and decimals to negations of their
    absolute value *)
val nums_to_pos_nums : t -> t 

(** Add to offset of state variable instances

    Negative values are allowed *)
val bump_state : Numeral.t -> t -> t

(** Apply function to term for instants 0..k *)
val bump_and_apply_k : (t -> unit) -> Numeral.t -> t -> unit

(** Return the state variables occurring in the term *)
val state_vars_of_term : t -> StateVar.StateVarSet.t

(** Return the variables occurring in the term *)
val vars_of_term : t -> Var.VarSet.t

(** Return the state variables at given offset in term *)
val state_vars_at_offset_of_term : Numeral.t -> t -> StateVar.StateVarSet.t

(** Return the state variables at given offset in term *)
val vars_at_offset_of_term : Numeral.t -> t -> Var.VarSet.t

(** Return the minimal and maximal offset of state variable instances

    Return [(None, None)] if there are no state variable instances in
    the term. *)
val var_offsets_of_term : t -> Numeral.t option * Numeral.t option


(** {1 Arrays } *)

(** Return the select symbols occurring in the term *)
val select_symbols_of_term : t -> Symbol.SymbolSet.t

(** Return the terms of the form (select ...) that appear in a term *)
val select_terms : t -> TermSet.t

(** Convert terms of the form [(select (select a i) j)] to [(select a i j)] for
    multi-dimensional arrays *)
val convert_select : t -> t

(** Use fresh function symbols to encode partial select applications and add
    constraint that [forall i, fresh a i = select a i], returns the modified
    term and the list of new fresh symbols to declare. This is only useful when
    using the fun-rec option of cvc5, it does nothing otherwise. *)
val partial_selects : t -> t * UfSymbol.t list

(** Inverse transformation of [!convert_select] *)
val reinterpret_select : t -> t

(** Return (array) indexes of a state variable appearing in a term *)
val indexes_of_state_var : StateVar.t -> t -> t list list

(** Return a term where the top-level select of the given term has been pushed
    until reaching a subterm that is not an ITE. If the top-level symbol is not
    a select, then the given term is returned unaltered *)
val push_select : t -> t

(** {1 Statistics} *)

(** return statistics of hashconsing *)
val stats : unit -> int * int * int * int * int * int
    
(* 
   Local Variables:
   compile-command: "make -C .. -k"
   tuareg-interactive-program: "./kind2.top -I ./_build -I ./_build/SExpr"
   indent-tabs-mode: nil
   End: 
*)
