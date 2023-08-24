%vec = type [4 x i64]
%mat = type [4 x %vec]

@inp = global %mat [%vec [i64 8, i64 3, i64 -6, i64 2],
                    %vec [i64 2, i64 -4, i64 4, i64 -3],
                    %vec [i64 -1, i64 0, i64 3, i64 8],
                    %vec [i64 -9, i64 3, i64 4, i64 -2]]

define i64 @getelement(%mat* %inp, i64 %i, i64 %j){
    %1 = getelementptr %mat, %mat* %inp, i64 0, i64 %i, i64 %j
    %2 = load i64, i64* %1
    ret i64 %2
}

define i64 @trace(%mat* %inp, i64 %n){
    %i = alloca i64
    %acc = alloca i64
    store i64 0, i64* %i
    store i64 1, i64* %acc
    br label %loop
loop:
    %ci = load i64, i64* %i
    %end = icmp eq i64 %ci, %n
    br i1 %end, label %end, label %loop_body
loop_body:
    %ele = call i64 @getelement(%mat* %inp, i64 %ci, i64 %ci)
    %cur = load i64, i64* %acc
    %next = mul i64 %ele, %cur
    store i64 %next, i64* %acc
    %ni = add i64 %ci, 1
    store i64 %ni, i64* %i
    br label %loop
end:
    %r = load i64, i64* %acc
    ret i64 %r
}

define i64 @main(i64 %argc, i8** %argv){
    %res = call i64 @trace(%mat* @inp, i64 4)
    ret i64 %res
}