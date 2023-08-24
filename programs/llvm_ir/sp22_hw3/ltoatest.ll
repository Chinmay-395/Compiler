declare void @ll_puts(i8*)
declare i8* @ll_ltoa(i64)
declare i8* @ll_strcat(i8*, i8*)

@sum = global [6 x i8] c"Sum: \00"

define i64 @main(i64 %argc, i8** %argv) {
  %1 = add i64 5, 9
  %ps = call i8* @ll_ltoa(i64 %1)
  %p = call i8* @ll_strcat(i8* @sum, i8* %ps)
  call void @ll_puts(i8* %p)
  ret i64 0
}