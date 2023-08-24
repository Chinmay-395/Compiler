define i64 @editAllRegs(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
  %1 = add i64 %a, %b
  %2 = add i64 %1, %c
  %3 = add i64 %2, %d
  %4 = add i64 %3, %e
  %5 = add i64 %4, %f
  ret i64 %5
}

define i64 @useAfterCall(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
  %saveA = alloca i64
  %saveB = alloca i64
  %saveC = alloca i64
  %saveD = alloca i64
  %saveE = alloca i64
  %saveF = alloca i64
  store i64 %a, i64* %saveA
  store i64 %b, i64* %saveB
  store i64 %c, i64* %saveC
  store i64 %d, i64* %saveD
  store i64 %e, i64* %saveE
  store i64 %f, i64* %saveF
  %sum = call i64 @editAllRegs(i64 2, i64 4, i64 6, i64 8, i64 10, i64 12)
  %cmpSum = icmp eq i64 %sum, 42
  br i1 %cmpSum, label %goodSum, label %badSum
badSum:
  ret i64 255
goodSum:
  %loadA = load i64, i64* %saveA
  %loadB = load i64, i64* %saveB
  %loadC = load i64, i64* %saveC
  %loadD = load i64, i64* %saveD
  %loadE = load i64, i64* %saveE
  %loadF = load i64, i64* %saveF
  %cmpA = icmp ne i64 %loadA, %a
  %cmpB = icmp ne i64 %loadB, %b
  %cmpC = icmp ne i64 %loadC, %c
  %cmpD = icmp ne i64 %loadD, %d
  %cmpE = icmp ne i64 %loadE, %e
  %cmpF = icmp ne i64 %loadF, %f
  %1 = add i64 %cmpA, %cmpB
  %2 = add i64 %1, %cmpC
  %3 = add i64 %2, %cmpD
  %4 = add i64 %3, %cmpE
  %5 = add i64 %4, %cmpF
  ret i64 %5
}

define i64 @main(i64 %argc, i8** %arcv) {
  %1 = call i64 @useAfterCall(i64 49, i64 96, i64 18, i64 62, i64 61, i64 63)
  ret i64 %1
}

