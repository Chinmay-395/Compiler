define i64 @step1() {
  ret i64 1
}

define i64 @step2() {
  ret i64 2
}

define i64 @step3() {
  ret i64 3
}

define i64 @step4() {
  ret i64 4
}

define i64 @step5() {
  ret i64 5
}

define i64 @main(i64 %argc, i8** %arcv) {
  %1 = call i64 @step1()
  %2 = call i64 @step2()
  %3 = call i64 @step3()
  %4 = call i64 @step4()
  %5 = call i64 @step5()
  %6 = add i64 %1, %2
  %7 = add i64 %6, %3
  %8 = add i64 %7, %4
  %9 = add i64 %8, %5
  ret i64 %9
}