; Robert Feliciano and Matthew Thomas

; counts the number of one bits in an integer

define i64 @count_bits(i64 %n){
    %count = add i64 0, 0
    br label %loop
loop:
    %lsb = and i64 1, %n                            ; determine whether the least significant bit is a 1 or 0 by using a bitwise AND 
    %temp = add i64 %count, %lsb                    ; if the LSB is 1 we add 1 to the bits flipped. otherwise we add 0. 
    %count = add i64 0, %temp                       ; set the counter equal to the termporary value
    %shifted = lshr i64 %n, 1                       ; shift n by 1 to the right
    %n = add i64 0, %shifted                        ; set n equal to the shifted value
    %iszero = icmp eq i64 0, %shifted               ; check if n is now zero
    br i1 %iszero, label %return, label %loop       ; if it is zero go to the return label otherwise go to the loop
return:
    ret i64 %count
}

define i64 @main(i64 %argc, i8** %arcv) {
    %flipped = call i64 @count_bits(i64 24897543853433223)
    ret i64 %flipped
}