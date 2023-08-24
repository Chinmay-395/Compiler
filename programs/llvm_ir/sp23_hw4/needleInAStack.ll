%stem = type [ 4 x i64 ] 
%leaf = type { %stem* , i64 , i64 }
%plant = type { %leaf , %leaf* , %stem , %stem* , %leaf , %leaf* }
%hay = type { %plant* , %leaf* , %stem* , %stem* , %leaf* , %plant* }
%stack = type { %hay* , %plant* , %plant* , %hay* }

@stem1 = global %stem [i64 78,i64 84,i64 69,i64 78]
@leaf11 = global %leaf {%stem* @stem1,i64 83,i64 73}
@leaf12 = global %leaf {%stem* @stem1,i64 79,i64 78}
@stem2 = global %stem [i64 80 , i64 73 ,i64 78,i64 69]
@leaf21 = global %leaf {%stem* @stem2,i64 65,i64 87} 
@leaf22 = global %leaf {%stem* @stem2,i64 65,i64 89} 
@stem3 = global %stem [i64 82 , i64 69,i64 83,i64 84]    
@leaf31 = global %leaf {%stem* @stem3,i64 65,i64 78}
@leaf32 = global %leaf {%stem* @stem3,i64 77,i64 69}
@stem4 = global %stem [i64 84 , i64 79,i64 66,i64 69]
@leaf41 = global %leaf {%stem* @stem4,i64 72,i64 79}
@leaf42 = global %leaf {%stem* @stem4,i64 76,i64 69}

@plant1 = global %plant {%leaf {%stem* @stem1,i64 84,i64 79},%leaf* @leaf42,
    %stem [i64 72,i64 69,i64 65,i64 68],%stem* @stem2,
    %leaf {%stem* @stem3,i64 78,i64 76},%leaf* @leaf22}
@plant2 = global %plant {%leaf {%stem* @stem4,i64 73,i64 78},%leaf* @leaf42,
    %stem [i64 77 ,i64 73,i64 78,i64 68],%stem* @stem3,
    %leaf {%stem* @stem3,i64 65,i64 78},%leaf* @leaf32}

@hay1 = global %hay {%plant* @plant1,%leaf* @leaf42,%stem* @stem1,
    %stem* @stem2,%leaf* @leaf41,%plant* @plant2}
@stack = global %stack {%hay* @hay1,%plant* @plant2,%plant* @plant1,%hay* @hay1}

define i64 @search_stem(%stem* %astem){
    %fst = getelementptr %stem, %stem* %astem, i32 0, i32 0
    %snd = getelementptr i64, i64* %fst, i32 1
    %thrd = getelementptr i64, i64* %fst, i32 2
    %frth = getelementptr i64, i64* %fst, i32 3
    %1 = load i64, i64* %fst
    %2 = load i64, i64* %snd
    %3 = load i64, i64* %thrd
    %4 = load i64, i64* %frth
    %5 = add i64 %1, %2 
    %6 = add i64 %5, %3
    %7 = add i64 %6, %4
    ret i64 %7
}

define i64 @search_leaf(%leaf* %aleaf){
    %fst = getelementptr %leaf, %leaf* %aleaf, i32 0, i32 1
    %snd =  getelementptr %leaf, %leaf* %aleaf, i32 0, i32 2
    %1 = load i64, i64* %fst
    %2 = load i64, i64* %snd
    %3 = add i64 %1, %2
    ret i64 %3
}

define i64 @search_plant(%plant* %aplant){
    %leaf11 = getelementptr %plant, %plant* %aplant, i32 0, i32 0, i32 1 
    %leaf12 = getelementptr %plant, %plant* %aplant, i32 0, i32 0, i32 2
    %leaf2ptr = getelementptr %plant, %plant* %aplant, i32 0, i32 1
    %stem11 = getelementptr %plant, %plant* %aplant, i32 0, i32 2, i32 0
    %stem12 = getelementptr i64, i64* %stem11, i32 1
    %stem13 = getelementptr i64, i64* %stem12, i32 1
    %stem14 = getelementptr i64, i64* %stem13, i32 1
    %stem2ptr = getelementptr %plant, %plant* %aplant, i32 0, i32 3
    %leaf31 = getelementptr %plant, %plant* %aplant, i32 0, i32 4, i32 1
    %leaf32 = getelementptr %plant, %plant* %aplant, i32 0, i32 4, i32 2
    %leaf4ptr = getelementptr %plant, %plant* %aplant, i32 0, i32 5
    %leaf2 = load %leaf*, %leaf** %leaf2ptr
    %leaf4 = load %leaf*, %leaf** %leaf4ptr
    %stem2 = load %stem*, %stem** %stem2ptr
    %1 = load i64, i64* %leaf11
    %2 = load i64, i64* %leaf12
    %3 = call i64 @search_leaf(%leaf* %leaf2)
    %4 = load i64, i64* %stem11
    %5 = load i64, i64* %stem12
    %6 = load i64, i64* %stem13
    %7 = load i64, i64* %stem14
    %8 = call i64 @search_stem(%stem* %stem2)
    %9 = load i64, i64* %leaf31
    %10 = load i64, i64* %leaf32
    %11 = call i64 @search_leaf(%leaf* %leaf4)
    %12 = add i64 %1, %2 
    %13 = add i64 %12, %3
    %14 = add i64 %4, %5
    %15 = add i64 %14, %6
    %16 = add i64 %15, %7
    %17 = sub i64 %16, %13
    %18 = add i64 %17, %8 
    %19 = sub i64 %18, %9
    %20 = sub i64 %19, %10
    %21 = sub i64 %20, %11
    ret i64 %21
}

define i64 @search_hay(%hay* %bundle){
    %plant1ptr = getelementptr %hay, %hay* %bundle, i32 0, i32 0 
    %leaf1ptr = getelementptr %hay, %hay* %bundle, i32 0, i32 1
    %stem1ptr = getelementptr %hay, %hay* %bundle, i32 0, i32 2
    %stem2ptr = getelementptr %hay, %hay* %bundle, i32 0, i32 3
    %leaf2ptr = getelementptr %hay, %hay* %bundle, i32 0, i32 4
    %plant2ptr = getelementptr %hay, %hay* %bundle, i32 0, i32 5
    %plant1 = load %plant*, %plant** %plant1ptr
    %leaf1 = load %leaf*, %leaf** %leaf1ptr
    %stem1 = load %stem*, %stem** %stem1ptr
    %stem2 = load %stem*, %stem** %stem2ptr
    %leaf2 = load %leaf*, %leaf** %leaf2ptr
    %plant2 = load %plant*, %plant** %plant2ptr
    %1 = call i64 @search_plant(%plant* %plant1)
    %2 = call i64 @search_leaf(%leaf* %leaf1)
    %3 = call i64 @search_stem(%stem* %stem1)
    %4 = call i64 @search_stem(%stem* %stem2)
    %5 = call i64 @search_leaf(%leaf* %leaf2)
    %6 = call i64 @search_plant(%plant* %plant2)
    %7 = add i64 %1, %2
    %8 = add i64 %3, %7
    %9 = sub i64 %8, %4
    %10 = sub i64 %9, %5
    %11 = sub i64 %10, %6
    ret i64 %11
}

define i64 @search_stack(%stack* %astack){
    %hayptr = getelementptr %stack, %stack* %astack, i32 0, i32 3
    %plant1ptr = getelementptr %stack, %stack* %astack, i32 0, i32 1
    %plant2ptr = getelementptr %plant*, %plant** %plant1ptr, i32 1  
    %temp = alloca %hay*
    %temphay = load %hay*, %hay** %hayptr
    store %hay* %temphay, %hay** %temp
    %hey = load %hay*, %hay** %temp
    %plant1 = load %plant*, %plant** %plant1ptr
    %plant2 = load %plant*, %plant** %plant2ptr
    %1 = call i64 @search_plant(%plant* %plant1)
    %2 = call i64 @search_plant(%plant* %plant2)
    %3 = call i64 @search_hay(%hay* %hey) 
    %4 = sub i64 %3, %2
    %5 = add i64 %4, %1
    ret i64 %5
}

@needle = global i64 5

define i1 @main(i64 %argc, i8** %argv){
    %1 = call i64 @search_stack(%stack* @stack)
    %2 = load i64, i64* @needle
    %3 = add i64 %1, 2
    %4 = icmp eq i64 %3, %2
    ret i1 %4
}

