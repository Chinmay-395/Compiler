define i64 @tribonacci(i64 %n) {
entry:
  %cmp0 = icmp eq i64 %n, 0
  br i1 %cmp0, label %if_then0, label %if_else0

if_then0:
  ret i64 0

if_else0:
  %cmp1 = icmp eq i64 %n, 1
  br i1 %cmp1, label %if_then1, label %if_else1

if_then1:
  ret i64 1

if_else1:
  %cmp2 = icmp eq i64 %n, 2
  br i1 %cmp2, label %if_then2, label %if_else2

if_then2:
  ret i64 1

if_else2:
  %prev1 = alloca i64
  %prev2 = alloca i64
  %prev3 = alloca i64
  %sum = alloca i64
  %0 = add i64 %n, -1
  %call = call i64 @tribonacci(i64 %0)
  store i64 %call, i64* %prev1
  %1 = add i64 %n, -2
  %call2 = call i64 @tribonacci(i64 %1)
  store i64 %call2, i64* %prev2
  %2 = add i64 %n, -3
  %call3 = call i64 @tribonacci(i64 %2)
  store i64 %call3, i64* %prev3
  %prev1_val = load i64, i64* %prev1
  %prev2_val = load i64, i64* %prev2
  %prev3_val = load i64, i64* %prev3
  %sum_val = add i64 %prev1_val, %prev2_val
  %sum_val2 = add i64 %sum_val, %prev3_val
  store i64 %sum_val2, i64* %sum
  %sum_val3 = load i64, i64* %sum
  ret i64 %sum_val3
}

define i64 @main(i64 %argc, i8** %argv) {
  %n = add i64 5, 0
  %result = call i64 @tribonacci(i64 %n)
    ret i64 %result

}




