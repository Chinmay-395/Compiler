%struct = type { [5 x [2 x i64]] }

@tmp = global %struct { [5 x [2 x i64]] [ [2 x i64] [i64 1, i64 2], [2 x i64] [i64 3, i64 4], [2 x i64] [i64 5, i64 6], [2 x i64] [i64 7, i64 8], [2 x i64] [i64 9, i64 10] ] }

define i64 @main(i64 %argc, i8** %argv) {
  %1 = getelementptr %struct, %struct* @tmp, i32 0, i32 0, i32 1, i32 0
  %2 = load i64, i64* %1
  ret i64 %2
}
