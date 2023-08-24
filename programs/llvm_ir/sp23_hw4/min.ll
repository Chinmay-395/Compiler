@glist = global [5 x i64] [ i64 35, i64 19, i64 44, i64 87, i64 5 ]

define i64 @getmin([5 x i64]* %list) {
  %i = alloca i64
  %curminptr = alloca i64
  store i64 0, i64* %i
  %firsteleptr = getelementptr [5 x i64], [5 x i64]* %list, i32 0, i64 0
  %firstele = load i64, i64* %firsteleptr
  store i64  %firstele, i64* %curminptr
  br label %loop
loop:
  %count = load i64, i64* %i
  %cmp1 = icmp eq i64 %count, 6
  br i1 %cmp1, label %done, label %check
check:
  %ptr = getelementptr [5 x i64], [5 x i64]* %list, i32 0, i64 %count
  %val = load i64, i64* %ptr
  %curminval = load i64, i64* %curminptr 
  %cmp2 = icmp slt i64  %val, %curminval
  %a = add i64 1, %count
  store i64 %a, i64* %i
  br i1 %cmp2, label %update, label %loop
update:
  store i64  %val, i64* %curminptr
  br label %loop
done:
  ret i64 %curminval
}

define i64 @main(i64 %argc, i8** %arcv) {
  %r = call i64 @getmin([5 x i64]* @glist)
  ret i64 %r 
}