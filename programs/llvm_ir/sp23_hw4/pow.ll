define i64 @pow(i64 %a, i64 %b){
    %cmp1 = icmp eq i64 %b, 0
    br i1 %cmp1, label %true, label %false
true:
    ret i64 1
false:
    %answer = alloca i64
    store i64 %a, i64* %answer
    %increment = alloca i64
    store i64 %a, i64* %increment
    %i = alloca i64
    store i64 1, i64* %i
    br label %outer.loop
outer.loop:
    %1 = load i64, i64* %i
    %cmp2 = icmp slt i64 %1, %b
    br i1 %cmp2, label %check.inner, label %exit.outer
check.inner:
    %j = alloca i64
    store i64 1, i64* %j
    br label %inner.loop
inner.loop:
    %2 = load i64, i64* %j
    %cmp3 = icmp slt i64 %2, %a
    br i1 %cmp3, label %inner.body, label %outer.body
outer.body:
    %3 = load i64, i64* %answer
    store i64 %3, i64* %increment
    %4 = load i64, i64* %i
    %i.next = add i64 %4, 1
    store i64 %i.next, i64* %i
    br label %outer.loop
inner.body:
    %5 = load i64, i64* %answer
    %6 = load i64, i64* %increment
    %7 = add i64 %5, %6
    store i64 %7, i64* %answer
    %8 = load i64, i64* %j
    %j.next = add i64 %8, 1
    store i64 %j.next, i64* %j
    br label %inner.loop

exit.outer:
    %9 = load i64, i64* %answer
    ret i64 %9
}

define i64 @main(i64 %argc, i8** %argv) {
    %r = call i64 @pow(i64 5, i64 3)
    ret i64 %r
}