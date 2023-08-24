define i64 @decr_while_loop(i64 %n) {
    %remaining = alloca i64
    store i64 %n, i64* %remaining
    br label %loop
loop:
    %check = load i64, i64* %remaining
    %cmp0 = icmp eq i64 %check, 0
    br i1 %cmp0, label %leave, label %decrement

leave:
    ret i64 %check

decrement:
    %tmp0 = load i64, i64* %remaining
    %remaining.next = sub i64 %tmp0, 1
    store i64 %remaining.next, i64* %remaining
    br label %loop
}

define i64 @main(i64 %argc, i8** %argv) {
    %returnVal = call i64 @decr_while_loop(i64 25)
    ret i64 %returnVal
}