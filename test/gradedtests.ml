open Util.Assert
open X86
open Oat
open Driver
open Ll
open Backend
open Analysistests
open Datastructures

(* Do NOT modify this file -- we will overwrite it with our *)
(* own version when we test your project.                   *)

(* These tests will be used to grade your assignment *)

let exec_ll_ast path ll_ast args extra_files =
  let () = Platform.verb @@ Printf.sprintf "** exec_ll_ast: %s\n" path in

  let output_path = !Platform.output_path in

  (* First - optimize the ll ast *)
  let _ = Opt.do_opt := true in
  let ll_ast = Opt.optimize ll_ast in

  (* Write out the optimized ll file for debugging purposes *)
  let ll_str = Driver.string_of_ll_ast path ll_ast in
  let dot_ll_file = Platform.gen_name output_path "test" ".ll" in
  let () = write_file dot_ll_file ll_str in

  (* Run the ll backend *)
  let _ = Backend.set_liveness "dataflow" in
  let _ = Backend.set_regalloc "better" in
  let asm_ast = Backend.compile_prog ll_ast in
  let asm_str = X86.string_of_prog asm_ast in

  (* Write out the resulting .s file for debugging purposes *)
  let dot_s_file = Platform.gen_name output_path "test" ".s" in
  let _ = Driver.write_file dot_s_file asm_str in

  (* Create the executable *)
  let exec_file = Platform.gen_name output_path "exec" "" in
  let _ = Platform.link (dot_s_file::extra_files) exec_file in

  (* Run it, piping the output to a temporary file *)
  let tmp_file = Platform.gen_name output_path "tmp" ".txt" in
  let result = Driver.run_program args exec_file tmp_file in
  let () = Platform.sh (Printf.sprintf "rm -f %s %s %s" dot_ll_file exec_file tmp_file) Platform.ignore_error in
  let () = Platform.verb @@ Printf.sprintf "** Executable output:\n%s\n" result in
  result

let exec_ll_file path args =
  let ast = Driver.parse_ll_file path in
  exec_ll_ast path ast args []

let oat_file_e2e_test path args =
  let () = Platform.verb @@ Printf.sprintf "** oat_file_e2e_test: %s\n" path in
  (* Run the Oat typechecker and frontend *)
  let oat_ast = parse_oat_file path in
  Typechecker.typecheck_program oat_ast;
  let ll_ast = Frontend.cmp_prog oat_ast in
  exec_ll_ast path ll_ast args ["bin/runtime.c"]

let pass_all = ref true
let pass_all_executed_ll_file tests =
  List.map (fun (fn, ans) ->
      fn, (fun () ->
          try  assert_eqfs (fun () -> exec_ll_file fn "") ans ()
          with exn -> pass_all := false; raise exn))
    tests

let pass_all_executed_oat_file tests =
  List.map (fun (path, args, ans) ->
      (path ^ " args: " ^ args),
      (fun () ->
         try assert_eqfs (fun () -> oat_file_e2e_test path args) ans ()
         with exn -> pass_all := false; raise exn))
    tests

let compile_with_config live regalloc ll_ast =
  let open Registers in
  let open Backend in
  let _ = set_liveness live in
  let _ = set_regalloc regalloc in
  let asm_ast = compile_prog ll_ast in
  let (histogram,size) = histogram_of_prog asm_ast in
  histogram, size, asm_ast

let assert_quality fn ll_ast =
  if not !pass_all then failwith "Your register allocator failed a correctness test" else
  let _ = Opt.do_opt := true in
  let ll_ast = Opt.optimize ll_ast in
  let h_greedy, size_greedy, x86_greedy = compile_with_config "dataflow" "greedy" ll_ast in
  let h_better, size_better, x86_better = compile_with_config "dataflow" "better" ll_ast in  
  let mem_greedy = Registers.memop_of_prog x86_greedy in
  let mem_better = Registers.memop_of_prog x86_better in  
  let _ =
    if !Driver.print_regs_flag then begin
      Printf.printf "greedy sz: %4d mem: %4d\t\tbetter sz: %4d mem: %4d \t diff_sz: %4d diff_mem: %4d - %s\n"
      size_greedy mem_greedy size_better mem_better (size_greedy - size_better) (mem_greedy - mem_better) fn
    end
  in
  if
    mem_better < mem_greedy then ()
  else if
    size_better < size_greedy then ()
  else failwith @@ Printf.sprintf "greedy is better" 

let assert_quality_oat fn () =
  let oat_ast = parse_oat_file fn in
  let ll_ast = Frontend.cmp_prog oat_ast in
  assert_quality fn ll_ast

let quality_oat tests =
  List.map (fun (fn, _, _) -> fn, assert_quality_oat fn) tests



let fdecl_of_path path =
  Platform.verb @@ Printf.sprintf "* processing file: %s\n" path;
  let ll_ast = parse_ll_file path in
  match ll_ast.Ll.fdecls with
  | [_, fdecl] -> (fdecl, ll_ast.tdecls)
  | _ -> failwith "test expected one fdecl"

let ll_dfa_file_test path compare analyze expected =
  let (fdecl, _) = fdecl_of_path path in
  let dfa = analyze (Cfg.of_ast fdecl) in
  compare dfa expected
  
let throw_key_diff compare val_to_string a b =
  let keys = LblM.diff_keys compare a b in
  if List.length keys == 0 then ()
  else begin
    let str_a = LblM.to_string val_to_string a in
    let str_b = LblM.to_string val_to_string b in
    failwith @@ Printf.sprintf "Output differs at labels: %s in maps\n%s\n%s\n"
      (String.concat ", " keys)
      str_a
      str_b
  end
    
let ll_opt_file_test path optimize ans =
  let (fdecl, tdecls) = fdecl_of_path path in
  let expected = (Cfg.of_ast @@ fst @@ fdecl_of_path ans).Cfg.blocks in
  let opt = optimize (Cfg.of_ast fdecl) in
  let printer k b = Printf.sprintf "%s %s" (Lbl.to_string k) (Llutil.string_of_block tdecls b) in
  throw_key_diff Llutil.compare_block printer opt expected

let dfa_liveness_file (tests : (string * 'a Datastructures.LblM.t) list) =
  let open Liveness in
  let analyze f = Graph.dfa (analyze f) in
  let printer k s = Printf.sprintf "%s %s" (Lbl.to_string k) (UidS.to_string s) in  
  List.map (fun (path, ans) -> 
    ("liveness: " ^ path, 
     fun () -> ll_dfa_file_test path (throw_key_diff Fact.compare printer) analyze ans)) tests

let dfa_alias_file tests =
  let open Alias in
  let analyze f = Graph.dfa (analyze f) in
  let printer k f = Printf.sprintf "%s %s" (Lbl.to_string k) (Alias.Fact.to_string f) in    
  List.map (fun (path, ans) ->
    ("alias: " ^ path, 
     fun () -> ll_dfa_file_test path (throw_key_diff Fact.compare printer) analyze ans)) tests

let dfa_constprop_file tests =
  let open Constprop in
  let analyze f = Graph.dfa (analyze f) in
  let printer k f = Printf.sprintf "%s %s" (Lbl.to_string k) (Constprop.Fact.to_string f) in      
  List.map (fun (path, ans) ->
    ("constprop: " ^ path, 
     fun () -> ll_dfa_file_test path (throw_key_diff Fact.compare printer) analyze ans)) tests

let opt_dce_file tests =
  let opt g =
    let ag = Alias.analyze g in
    let lg = Liveness.analyze g in
    let g = Dce.run lg ag g in
    g.Cfg.blocks
  in
  List.map (fun (path, ans) ->
      (Printf.sprintf "dce opt: %s, %s" 
                      (Filename.basename path) (Filename.basename ans), 
       fun () -> ll_opt_file_test path opt ans)) tests

let opt_constfold_file tests =
  let opt g =
    let cg = Constprop.analyze g in
    let g = Constprop.run cg g in
    g.Cfg.blocks
  in
  List.map (fun (path, ans) ->
      (Printf.sprintf "constprop opt: %s, %s" 
                      (Filename.basename path) (Filename.basename ans), 
       fun () -> ll_opt_file_test path opt ans)) tests

(* this test harness is used for part iv of the homework -------------------- *)
let executed_fullopt_file tests =
  let opt n g = let g = Opt.pass n g in g.Cfg.blocks in
  List.map (fun (n, path, ans) ->
      (Printf.sprintf "fullopt %d iterations: %s" n path,
       fun () -> ll_opt_file_test path (opt n) ans)) tests


let binop_tests =
  [ "programs/llvm_ir/add.ll", "14"
  ; "programs/llvm_ir/sub.ll", "1"
  ; "programs/llvm_ir/mul.ll", "45"
  ; "programs/llvm_ir/and.ll", "0"
  ; "programs/llvm_ir/or.ll",  "1"
  ; "programs/llvm_ir/xor.ll", "0"
  ; "programs/llvm_ir/shl.ll", "168"
  ; "programs/llvm_ir/lshr.ll", "10"
  ; "programs/llvm_ir/ashr.ll", "5" ]

let calling_convention_tests =
  [ "programs/llvm_ir/call.ll", "42"
  ; "programs/llvm_ir/call1.ll", "17" 
  ; "programs/llvm_ir/call2.ll", "19"
  ; "programs/llvm_ir/call3.ll", "34"
  ; "programs/llvm_ir/call4.ll", "34"
  ; "programs/llvm_ir/call5.ll", "24"
  ; "programs/llvm_ir/call6.ll", "26"            
  ; "programs/llvm_ir/call7.ll", "7"
  ; "programs/llvm_ir/call8.ll", "21"
  ]

let memory_tests =
  [ "programs/llvm_ir/alloca1.ll", "17"
  ; "programs/llvm_ir/alloca2.ll", "17"
  ; "programs/llvm_ir/global1.ll", "12"    
  ]

let terminator_tests =
  [ "programs/llvm_ir/return.ll", "0"
  ; "programs/llvm_ir/return42.ll", "42"
  ; "programs/llvm_ir/br1.ll", "9"
  ; "programs/llvm_ir/br2.ll", "17"    
  ; "programs/llvm_ir/cbr1.ll", "7"
  ; "programs/llvm_ir/cbr2.ll", "9"
  ; "programs/llvm_ir/cbr3.ll", "9"
  ]

let bitcast_tests =
  [ "programs/llvm_ir/bitcast1.ll", "3"
  ]

let gep_tests =
  [ "programs/llvm_ir/gep1.ll", "6"
  ; "programs/llvm_ir/gep2.ll", "4"
  ; "programs/llvm_ir/gep3.ll", "1"
  ; "programs/llvm_ir/gep4.ll", "2"
  ; "programs/llvm_ir/gep5.ll", "4"
  ; "programs/llvm_ir/gep6.ll", "7"
  ; "programs/llvm_ir/gep7.ll", "7"    
  ; "programs/llvm_ir/gep8.ll", "2"
  ; "programs/llvm_ir/gep9.ll", "5"
  ; "programs/llvm_ir/gep10.ll", "3"            
  ]


let arithmetic_tests =
  [ "programs/llvm_ir/add_twice.ll", "29" 
  ; "programs/llvm_ir/sub_neg.ll", "255" (* Why, oh why, does the termianl only report the last byte? *)
  ; "programs/llvm_ir/arith_combo.ll", "4"
  ; "programs/llvm_ir/return_intermediate.ll", "18" ]

let sum_tree_tests = ["programs/llvm_ir/sum_tree.ll", "116"]
let gcd_euclidian_tests = [ "programs/llvm_ir/gcd_euclidian.ll", "2"]
let sieve_tests = [["bin/cinterop.c"], "programs/llvm_ir/sieve.ll", [], "1"]
let binary_search_tests = ["programs/llvm_ir/binarysearch.ll", "8"]
let gep_5_deep_tests = ["programs/llvm_ir/qtree.ll", "3"]
let binary_gcd_tests = ["programs/llvm_ir/binary_gcd.ll", "3"]
let linear_search_tests = ["programs/llvm_ir/linear_search.ll", "1"]
let lfsr_tests = ["programs/llvm_ir/lfsr.ll", "108"]
let naive_factor_tests = 
  [ "programs/llvm_ir/naive_factor_prime.ll", "1"
  ; "programs/llvm_ir/naive_factor_nonprime.ll", "0"
  ]
let euclid_recursive_test = ["programs/llvm_ir/euclid.ll", "2"]
let matmul_tests = ["programs/llvm_ir/matmul.ll", "0"]

let large_tests = [ "programs/llvm_ir/list1.ll", "3"
                  ; "programs/llvm_ir/cbr.ll", "42"
                  ; "programs/llvm_ir/factorial.ll", "120"
                  ; "programs/llvm_ir/factrect.ll", "120"
                  ]

let ll_tests =
  binop_tests 
  @ terminator_tests 
  @ memory_tests 
  @ calling_convention_tests 
  @ bitcast_tests
  @ gep_tests 
  @ arithmetic_tests 
  @ sum_tree_tests
  @ gcd_euclidian_tests
  @ binary_search_tests
  @ gep_5_deep_tests
  @ binary_gcd_tests
  @ linear_search_tests
  @ lfsr_tests
  @ naive_factor_tests
  @ euclid_recursive_test
  @ matmul_tests
  @ large_tests

(* Should not be used for quality tests *)
let greedy_is_good_tests = [
 ("programs/oat_v1/easyrun1.oat", "", "17");
 ("programs/oat_v1/easyrun2.oat", "", "35");
 ("programs/oat_v1/easyrun5.oat", "", "212");
 ("programs/oat_v1/easyrun6.oat", "", "9");
 ("programs/oat_v1/easyrun7.oat", "", "23");
 ("programs/oat_v1/easyrun8.oat", "", "160");
 ("programs/oat_v1/path1.oat", "", "17");
 ("programs/oat_v1/run26.oat", "", "0");
 ("programs/oat_v1/run27.oat", "", "99");
 ("programs/oat_v1/run29.oat", "", "1");
 ("programs/oat_v1/run30.oat", "", "9");
 ("programs/oat_v1/run31.oat", "", "9");
 ("programs/oat_v1/run13.oat", "", "1");
 ("programs/oat_v1/run38.oat", "", "31");
 ("programs/oat_v1/run40.oat", "", "8");
 ("programs/oat_v1/run60.oat", "", "85");
 ("programs/oat_v1/heap.oat", "", "1");
 ("programs/oat_v2/ifq2.oat", "", "5");
 ("programs/oat_v2/length1.oat", "", "5");
 ("programs/oat_v1/lcs.oat", "", "OAT0");
]


let oat_v1_easiest_tests = [
  ("programs/oat_v1/easyrun3.oat", "", "73");
  ("programs/oat_v1/easyrun4.oat", "", "6");
  ("programs/oat_v1/easyrun9.oat", "", "236");
]

(* Should not be used for quality tests *)
let oat_v1_globals_tests = [
  ("programs/oat_v1/globals1.oat", "", "42");
  ("programs/oat_v1/globals2.oat", "", "17");
  ("programs/oat_v1/globals3.oat", "", "17");
  ("programs/oat_v1/globals4.oat", "", "5");
  ("programs/oat_v1/globals5.oat", "", "17");
  ("programs/oat_v1/globals6.oat", "", "15");
]

let oat_v1_path_tests = [
 ("programs/oat_v1/path2.oat", "", "35");
 ("programs/oat_v1/path3.oat", "", "3");
 ("programs/oat_v1/arrayargs1.oat", "", "17");
 ("programs/oat_v1/arrayargs2.oat", "", "17");
 ("programs/oat_v1/arrayargs4.oat", "", "0"); 
]

let oat_v1_easy_tests = [
    ("programs/oat_v1/run28.oat", "", "18");
    ("programs/oat_v1/run32.oat", "", "33");
    ("programs/oat_v1/run21.oat", "", "99");
    ("programs/oat_v1/run33.oat", "", "1");
    ("programs/oat_v1/run34.oat", "", "66");
    ("programs/oat_v1/run39.oat", "a", "2");
    ("programs/oat_v1/run42.oat", "", "2");
    ("programs/oat_v1/run49.oat", "", "abc0");
    ("programs/oat_v1/run50.oat", "", "abcde0");
    ("programs/oat_v1/run61.oat", "", "3410");
]

let oat_v1_medium_tests = [
  ("programs/oat_v1/fact.oat", "", "1200");
  ("programs/oat_v1/run1.oat", "", "153");
  ("programs/oat_v1/run2.oat", "", "6");
  ("programs/oat_v1/run8.oat", "", "2");
  ("programs/oat_v1/run9.oat", "", "4");
  ("programs/oat_v1/run10.oat", "", "5");
  ("programs/oat_v1/run11.oat", "", "7");
  ("programs/oat_v1/run14.oat", "", "16");
  ("programs/oat_v1/run15.oat", "", "19");
  ("programs/oat_v1/run16.oat", "", "13");
  ("programs/oat_v1/run22.oat", "", "abc0");
  ("programs/oat_v1/run23.oat", "", "1230");
  ("programs/oat_v1/run25.oat", "", "nnn0");
  ("programs/oat_v1/run46.oat", "", "420");
  ("programs/oat_v1/run47.oat", "", "3");
  ("programs/oat_v1/run48.oat", "", "11");
  ("programs/oat_v1/lib4.oat", "", "53220");
  ("programs/oat_v1/lib5.oat", "", "20");
  ("programs/oat_v1/lib6.oat", "", "56553");
  ("programs/oat_v1/lib7.oat", "", "53");
  ("programs/oat_v1/lib8.oat", "", "Hello world!0");
  ("programs/oat_v1/lib9.oat", "a b c d", "abcd5");
  ("programs/oat_v1/lib11.oat", "", "45");
  ("programs/oat_v1/lib14.oat", "", "~}|{zyxwvu0");
  ("programs/oat_v1/lib15.oat", "123456789", "456780");
  ("programs/oat_v1/regalloctest.oat", "", "0");
  ("programs/oat_v1/regalloctest2.oat", "", "137999986200000000")  
]

let oat_v1_hard_tests = [
("programs/oat_v1/fac.oat", "", "120");
("programs/oat_v1/bsort.oat", "", "y}xotnuw notuwxy}255");
("programs/oat_v1/msort.oat", "", "~}|{zyxwvu uvwxyz{|}~ 0");
("programs/oat_v1/msort2.oat", "", "~}|{zyxwvu uvwxyz{|}~ 0");
("programs/oat_v1/selectionsort.oat", "", "01253065992000");
("programs/oat_v1/matrixmult.oat", "", "19 16 13 23 \t5 6 7 6 \t19 16 13 23 \t5 6 7 6 \t0");
]

let oat_v1_old_student_tests = [
    ("programs/oat_v1/binary_search.oat", "", "Correct!0")
  ; ("programs/oat_v1/xor_shift.oat", "", "838867572\n22817190600")
  ; ("programs/oat_v1/sieve.oat", "", "25")
  ; ("programs/oat_v1/fibo.oat", "", "0")
  ; ("programs/oat_v1/lfsr.oat", "", "TFTF FFTT0")
  ; ("programs/oat_v1/gnomesort.oat", "", "01253065992000")
  ; ("programs/oat_v1/josh_joyce_test.oat", "", "0")
  ; ("programs/oat_v1/gcd.oat", "", "16")
  ; ("programs/oat_v1/insertion_sort.oat", "", "42")
  ; ("programs/oat_v1/maxsubsequence.oat", "", "107")
]

let struct_tests = [
("programs/oat_v2/compile_assign_struct.oat", "", "16");
("programs/oat_v2/compile_basic_struct.oat", "", "7");
("programs/oat_v2/compile_global_struct.oat", "", "254");
("programs/oat_v2/compile_nested_struct.oat", "", "10");
("programs/oat_v2/compile_return_struct.oat", "", "0");
("programs/oat_v2/compile_struct_array.oat", "", "15");
("programs/oat_v2/compile_struct_fptr.oat", "", "7");
("programs/oat_v2/compile_various_fields.oat", "", "hello253"); 
]

let fptr_tests = [
  ("programs/oat_v2/compile_array_fptr.oat", "", "2");
  ("programs/oat_v2/compile_func_argument.oat", "", "4");
  ("programs/oat_v2/compile_global_fptr.oat", "", "7");
  ("programs/oat_v2/compile_global_fptr_unordered.oat", "", "2");
  ("programs/oat_v2/compile_scall_fptr.oat", "", "4");
  ("programs/oat_v2/compile_var_fptr.oat", "", "1");
  ("programs/oat_v2/compile_local_fptr.oat", "", "5");
  ("programs/oat_v2/compile_function_shadow.oat", "", "12");
  ("programs/oat_v2/compile_global_struct_fptr.oat", "", "20");
  ("programs/oat_v2/compile_builtin_argument.oat", "", "abab0");    
]

let regalloc_challenge_tests = [
 ("programs/oat_v1/arrayargs3.oat", "", "34");
 ("programs/oat_v1/run41.oat", "", "3");
 ("programs/oat_v1/run51.oat", "", "341");
 ("programs/oat_v1/run52.oat", "", "15");
 ("programs/oat_v1/run54.oat", "", "10");
 ("programs/oat_v1/run55.oat", "", "6");    
 ("programs/oat_v1/qsort.oat", "", "kpyf{shomfhkmopsy{255");
 ("programs/oat_v1/count_sort.oat", "", "AFHZAAEYC\nAAACEFHYZ0");
]

let new_tests = [
  ("programs/oat_v2/ifq1.oat", "", "4");
  ("programs/oat_v2/length2.oat", "", "3");  
  ("programs/oat_v2/initarr1.oat", "", "1");
  ("programs/oat_v2/initarr2.oat", "", "2");
]

let oat_regalloc_quality_tests =
  oat_v1_easiest_tests
  @ oat_v1_path_tests
  @ oat_v1_easy_tests
  @ oat_v1_medium_tests
  @ oat_v1_hard_tests
  @ oat_v1_old_student_tests
  @ struct_tests
  @ fptr_tests
  @ new_tests
  @ regalloc_challenge_tests


let oat_correctness_tests =
  oat_regalloc_quality_tests
  @ oat_v1_globals_tests
  @ greedy_is_good_tests

let dce_opt_tests =
  [ "programs/llvm_ir/analysis1_cf_opt.ll", "programs/llvm_ir/analysis1_dce_opt.ll"
  ; "programs/llvm_ir/analysis2_cf_opt.ll", "programs/llvm_ir/analysis2_dce_opt.ll"
  ; "programs/llvm_ir/analysis3_cf_opt.ll", "programs/llvm_ir/analysis3_dce_opt.ll"
  ; "programs/llvm_ir/analysis4_cf_opt.ll", "programs/llvm_ir/analysis4_dce_opt.ll"
  ; "programs/llvm_ir/analysis5_cf_opt.ll", "programs/llvm_ir/analysis5_dce_opt.ll"
  ; "programs/llvm_ir/analysis6_cf_opt.ll", "programs/llvm_ir/analysis6_dce_opt.ll"
  ; "programs/llvm_ir/analysis7_cf_opt.ll", "programs/llvm_ir/analysis7_dce_opt.ll"
  ; "programs/llvm_ir/analysis8_cf_opt.ll", "programs/llvm_ir/analysis8_dce_opt.ll"
  ; "programs/llvm_ir/analysis9_cf_opt.ll", "programs/llvm_ir/analysis9_dce_opt.ll"
  ; "programs/llvm_ir/analysis10_cf_opt.ll", "programs/llvm_ir/analysis10_dce_opt.ll"
  ; "programs/llvm_ir/analysis11_cf_opt.ll", "programs/llvm_ir/analysis11_dce_opt.ll"
  ; "programs/llvm_ir/analysis12_cf_opt.ll", "programs/llvm_ir/analysis12_dce_opt.ll"
  ; "programs/llvm_ir/analysis13_cf_opt.ll", "programs/llvm_ir/analysis13_dce_opt.ll"
  ; "programs/llvm_ir/analysis14_cf_opt.ll", "programs/llvm_ir/analysis14_dce_opt.ll"
  ; "programs/llvm_ir/analysis15_cf_opt.ll", "programs/llvm_ir/analysis15_dce_opt.ll"
  ; "programs/llvm_ir/analysis16_cf_opt.ll", "programs/llvm_ir/analysis16_dce_opt.ll"
  ; "programs/llvm_ir/analysis17_cf_opt.ll", "programs/llvm_ir/analysis17_dce_opt.ll"
  ; "programs/llvm_ir/analysis18_cf_opt.ll", "programs/llvm_ir/analysis18_dce_opt.ll"
  ; "programs/llvm_ir/analysis19_cf_opt.ll", "programs/llvm_ir/analysis19_dce_opt.ll"
  ]

let constprop_opt_tests =
  [ "programs/llvm_ir/analysis1.ll", "programs/llvm_ir/analysis1_cf_opt.ll"
  ; "programs/llvm_ir/analysis2.ll", "programs/llvm_ir/analysis2_cf_opt.ll"
  ; "programs/llvm_ir/analysis3.ll", "programs/llvm_ir/analysis3_cf_opt.ll"
  ; "programs/llvm_ir/analysis4.ll", "programs/llvm_ir/analysis4_cf_opt.ll"
  ; "programs/llvm_ir/analysis5.ll", "programs/llvm_ir/analysis5_cf_opt.ll"
  ; "programs/llvm_ir/analysis6.ll", "programs/llvm_ir/analysis6_cf_opt.ll"
  ; "programs/llvm_ir/analysis7.ll", "programs/llvm_ir/analysis7_cf_opt.ll"
  ; "programs/llvm_ir/analysis8.ll", "programs/llvm_ir/analysis8_cf_opt.ll"
  ; "programs/llvm_ir/analysis9.ll", "programs/llvm_ir/analysis9_cf_opt.ll"
  ; "programs/llvm_ir/analysis10.ll", "programs/llvm_ir/analysis10_cf_opt.ll"
  ; "programs/llvm_ir/analysis11.ll", "programs/llvm_ir/analysis11_cf_opt.ll"
  ; "programs/llvm_ir/analysis12.ll", "programs/llvm_ir/analysis12_cf_opt.ll"
  ; "programs/llvm_ir/analysis13.ll", "programs/llvm_ir/analysis13_cf_opt.ll"
  ; "programs/llvm_ir/analysis14.ll", "programs/llvm_ir/analysis14_cf_opt.ll"
  ; "programs/llvm_ir/analysis15.ll", "programs/llvm_ir/analysis15_cf_opt.ll"
  ; "programs/llvm_ir/analysis16.ll", "programs/llvm_ir/analysis16_cf_opt.ll"
  ; "programs/llvm_ir/analysis17.ll", "programs/llvm_ir/analysis17_cf_opt.ll"
  ; "programs/llvm_ir/analysis18.ll", "programs/llvm_ir/analysis18_cf_opt.ll"
  ; "programs/llvm_ir/analysis19.ll", "programs/llvm_ir/analysis19_cf_opt.ll"
  ]

let student_piazza_tests =
[
("programs/student/sp22_tests/4waymerge.oat", "", "0");
("programs/student/sp22_tests/Insertion_sort.oat", "", "70");
("programs/student/sp22_tests/binomCoefficient.oat", "", "0");
("programs/student/sp22_tests/bubble_sort.oat", "", "0");
("programs/student/sp22_tests/cocktail.oat", "", "42");
("programs/student/sp22_tests/conv.oat", "", "329214263976168");
("programs/student/sp22_tests/deep_loop.oat", "", "10000000000");
("programs/student/sp22_tests/evil.oat", "", "135");
("programs/student/sp22_tests/fibonacci.oat", "", "0");
("programs/student/sp22_tests/fizzbuzz.oat", "", "0");
("programs/student/sp22_tests/game_of_life.oat", "", "0");
("programs/student/sp22_tests/game_of_life2.oat", "", "0");
("programs/student/sp22_tests/gary.oat", "", "0");
("programs/student/sp22_tests/longest_increasing_subsequence.oat", "", "1111");
("programs/student/sp22_tests/nbonacci.oat", "", "102334155\n60903071");
("programs/student/sp22_tests/number_of_islands.oat", "", "31");
("programs/student/sp22_tests/ramanujan.oat", "", "4");
("programs/student/sp22_tests/rec_matrix_traversal.oat", "", "7056720");
("programs/student/sp22_tests/three_by_three.oat", "", "18251145292");
("programs/student/sp22_tests/vertex_cover_approx.oat", "", "Vertex Cover 2-Approximation:0 1 3 4 5 6 0");
]

let tests : suite =
  [
  Test("solver / liveness analysis tests", dfa_liveness_file liveness_analysis_tests);
  Test("alias analysis tests", dfa_alias_file alias_analysis_tests);
  Test("dce optimization tests", opt_dce_file dce_opt_tests);
  GradedTest("constprop analysis tests", 15, dfa_constprop_file constprop_analysis_tests);
  GradedTest("constprop optimization tests", 10, opt_constfold_file constprop_opt_tests);
  Test("ll regalloc correctness tests", pass_all_executed_ll_file ll_tests);
  Test("oat regalloc correctness tests", pass_all_executed_oat_file (oat_correctness_tests @ regalloc_challenge_tests));
  Test("student submitted correct tests", pass_all_executed_oat_file student_piazza_tests);
  GradedTest("student submitted quality tests", 0, quality_oat student_piazza_tests);
  GradedTest("oat regalloc quality tests", 35, quality_oat oat_regalloc_quality_tests); 
  ]

let manual_tests : suite =
  [ GradedTest ("Your Test Posted on Slack", 5, [(*SOLN*)("manually graded", assert_fail)(*STUBWITH*)])
  ; GradedTest ("Your Timing Analysis Posted on Slack", 5, [(*SOLN*)("manually graded", assert_fail)(*STUBWITH*)])
  ]

let graded_tests : suite =
  tests @ manual_tests
