define i64 @square (i64 %n) {
  %res = mul i64 %n, %n
  ret i64 %res
}

define i64 @largest_square (i64 %n) {
  %curr = alloca i64
  %currsq = alloca i64
  store i64 0, i64* %curr
  br label %loop

  preloop:
  store i64 %cvsucc, i64* %curr
  store i64 %cvsuccsq, i64* %currsq
  br label %loop

  loop:

  %cv = load i64, i64* %curr
  %cvsucc = add i64 %cv, 1
  %cvsuccsq = call i64 @square(i64 %cvsucc)
  %condres = icmp sgt i64 %cvsuccsq, %n
  br i1 %condres, label %end, label %preloop

  end:

  %res = load i64, i64* %currsq
  ret i64 %res
}

define i64 @main (i64 %argc, i8** %arcv) {
  %res = call i64 @largest_square(i64 48)
  ret i64 %res
}