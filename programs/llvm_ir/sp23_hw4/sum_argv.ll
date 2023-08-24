define i64 @getChar(i8* %str, i64 %idx) {
  %base = bitcast i8* %str to i64*
  %addr = add i64 %base, %idx
  %dword = load i64, i64* %addr
  %c = and i64 %dword, 255
  ret i64 %c
}

define i64 @atoi(i8* %str) {
  %i = alloca i64
  %acc = alloca i64
  store i64 0, i64* %i
  store i64 0, i64* %acc
  br label %loop
loop:
  %ti = load i64, i64* %i
  %tacc = load i64, i64* %acc
  %c = call i64 @getChar(i8* %str, i64 %ti)
  %cond = icmp ne i64 %c, 0
  br i1 %cond, label %loop_body, label %end
loop_body:
  %inci = add i64 %ti, 1
  %shiftAcc = mul i64 %tacc, 10
  %digit = sub i64 %c, 48
  store i64 %inci, i64* %i
  %newAcc = add i64 %shiftAcc, %digit
  store i64 %newAcc, i64* %acc
  br label %loop
end:
  %res = load i64, i64* %acc
  ret i64 %res
}

define i64 @main(i64 %argc, i8** %argv) {
  %i = alloca i64
  %acc = alloca i64
  store i64 1, i64* %i
  store i64 0, i64* %acc
  br label %loop
loop:
  %ti = load i64, i64* %i
  %tacc = load i64, i64* %acc
  %cond = icmp ne i64 %ti, %argc
  br i1 %cond, label %loop_body, label %end
loop_body:
  %offset = mul i64 %ti, 8
  %strAddr = add i64 %offset, %argv
  %str = load i8*, i8** %strAddr
  %num = call i64 @atoi(i8* %str)
  %inci = add i64 %ti, 1
  store i64 %inci, i64* %i
  %newAcc = add i64 %num, %tacc
  store i64 %newAcc, i64* %acc
  br label %loop
end:
  %result = load i64, i64* %acc
  ret i64 %result
}