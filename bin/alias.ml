(** Alias Analysis *)

open Ll
open Datastructures

(* The lattice of abstract pointers ----------------------------------------- *)
module SymPtr =
  struct
    type t = MayAlias           (* uid names a pointer that may be aliased *)
           | Unique             (* uid is the unique name for a pointer *)
           | UndefAlias         (* uid is not in scope or not a pointer *)

    let compare : t -> t -> int = Stdlib.compare

    let to_string = function
      | MayAlias -> "MayAlias"
      | Unique -> "Unique"
      | UndefAlias -> "UndefAlias"

  end

(* The analysis computes, at each program point, which UIDs in scope are a unique name
   for a stack slot and which may have aliases *)
type fact = SymPtr.t UidM.t

(* flow function across Ll instructions ------------------------------------- *)
(* TASK: complete the flow function for alias analysis. 

   - After an alloca, the defined UID is the unique name for a stack slot
   - A pointer returned by a load, call, bitcast, or GEP may be aliased
   - A pointer passed as an argument to a call, bitcast, GEP, or store
     (as the value being stored) may be aliased
   - Other instructions do not define pointers

 *)
let insn_flow ((u,i):uid * insn) (d:fact) : fact =
  let check_uid_is_single, operands = 
    begin
      match i with
        | Binop (op, ty, e1, e2) -> false, []
        | Alloca ty -> true, []
        | Load(ty, op) -> 
            begin 
              match ty with
              | Ptr Ptr _ -> false, [Id u]
              | _ -> false , []
            end
        | Store (ty, src,dest) ->
            begin 
              match ty with
              | Ptr _ -> false, [src]
              | _ -> false, []
                (* | _ -> failwith "" *)
            end
        | Icmp (ty, op, e1, e2) -> false, []
        | Call (ret, op1, op2) -> false, Id u :: List.map snd op2
        | Bitcast(input_type, op, output_ty) -> false, [Id u; op]
        | Gep (ty, op, op1) -> false, [Id u; op]
        (* | _ -> failwith "failed" *)
    end in
  let psuedo_name_operand_ty = 
    List.map (fun x -> 
      begin 
        match x with 
        | Id uid -> Some (uid, SymPtr.MayAlias) 
        | _ -> None 
      end
    ) operands
   in
  let operand_type = 
    (if check_uid_is_single then Some (u, SymPtr.Unique) else None) :: psuedo_name_operand_ty in
  let aliased_helper acc t = 
    begin 
      match t with
      | Some (uid, s ) -> UidM.add uid s acc
      | None -> acc
    end in
  List.fold_left aliased_helper d operand_type


(* The flow function across terminators is trivial: they never change alias info *)
let terminator_flow t (d:fact) : fact = d

(* module for instantiating the generic framework --------------------------- *)
module Fact =
  struct
    type t = fact
    let forwards = true

    let insn_flow = insn_flow
    let terminator_flow = terminator_flow
    
    (* UndefAlias is logically the same as not having a mapping in the fact. To
       compare dataflow facts, we first remove all of these *)
    let normalize : fact -> fact = 
      UidM.filter (fun _ v -> v != SymPtr.UndefAlias)

    let compare (d:fact) (e:fact) : int = 
      UidM.compare SymPtr.compare (normalize d) (normalize e)

    let to_string : fact -> string =
      UidM.to_string (fun _ v -> SymPtr.to_string v)

    (* TASK: complete the "combine" operation for alias analysis.

       The alias analysis should take the meet over predecessors to compute the
       flow into a node. You may find the UidM.merge function useful.

       It may be useful to define a helper function that knows how to take the
       meet of two SymPtr.t facts.
    *)
    let combine (ds:fact list) : fact =
      List.fold_left (UidM.union (fun _ x y ->
        let find_fac = List.find (fun z -> x = z || y = z)
        [SymPtr.UndefAlias; SymPtr.MayAlias; SymPtr.Unique] in Some find_fac
        )) UidM.empty ds
  end

(* instantiate the general framework ---------------------------------------- *)
module Graph = Cfg.AsGraph (Fact)
module Solver = Solver.Make (Fact) (Graph)

(* expose a top-level analysis operation ------------------------------------ *)
let analyze (g:Cfg.t) : Graph.t =
  (* the analysis starts with every node set to bottom (the map of every uid 
     in the function to UndefAlias *)
  let init l = UidM.empty in

  (* the flow into the entry node should indicate that any pointer parameter 
     to the function may be aliased *)
  let alias_in = 
    List.fold_right 
      (fun (u,t) -> match t with
                    | Ptr _ -> UidM.add u SymPtr.MayAlias
                    | _ -> fun m -> m) 
      g.Cfg.args UidM.empty 
  in
  let fg = Graph.of_cfg init alias_in g in
  Solver.solve fg

