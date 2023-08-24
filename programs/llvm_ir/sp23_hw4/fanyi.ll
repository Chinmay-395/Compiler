%t1 = type { i64, i64, i64 }
%t2 = type [ 2 x %t1 ]
%t3 = type [ 4 x %t1 ]
%t4 = type { i64, i64, i64, i64, i64, i64 }

@pn1 = global %t2 [ %t1 { i64 1, i64 2, i64 3}, %t1 {i64 4, i64 5, i64 6} ]
@pn2 = global %t2 [ %t1 { i64 11, i64 22, i64 33}, %t1 {i64 44, i64 55, i64 66} ]
@pn3 = global %t2 [ %t1 { i64 111, i64 222, i64 333}, %t1 {i64 444, i64 555, i64 666} ]
@pn4 = global %t1 {i64 81, i64 82, i64 83}

define i64 @main(i64 %argc, i8** %arcv) {
  %pn0 = bitcast %t2* @pn1 to %t3*
  %lbl0 = getelementptr %t3, %t3* %pn0, i64 1, i64 0
  %pn3 = bitcast %t1* %lbl0 to %t4*
  %pb1 = getelementptr %t4, %t4* %pn3, i64 1, i32 2
  %ret = load i64, i64* %pb1
  ;; ret = 83
  ret i64 %ret
}