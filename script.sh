multitime -n 10 ./oatc --liveness trivial --regalloc none programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc --liveness dataflow --regalloc greedy programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc --liveness dataflow --regalloc better programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc --clang programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --liveness trivial --regalloc none programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --liveness dataflow --regalloc greedy programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --liveness dataflow --regalloc better programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --clang programs/oat_v1/regalloctest.oat bin/runtime.c
multitime -n 10 ./oatc --liveness trivial --regalloc none programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc --liveness dataflow --regalloc greedy programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc --liveness dataflow --regalloc better programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc --clang programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc -O1 --liveness trivial --regalloc none programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc -O1 --liveness dataflow --regalloc greedy programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc -O1 --liveness dataflow --regalloc better programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc -O1 --clang programs/llvm_ir/matmul.ll
multitime -n 10 ./oatc --liveness trivial --regalloc none programs/custom_test.oat bin/runtime.c
multitime -n 10 ./oatc --liveness dataflow --regalloc greedy programs/custom_test.oat bin/runtime.c
multitime -n 10 ./oatc --liveness dataflow --regalloc better programs/custom_test.oat bin/runtime.c
multitime -n 10 ./oatc --clang programs/custom_test.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --liveness trivial --regalloc none programs/custom_test.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --liveness dataflow --regalloc greedy programs/custom_test.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --liveness dataflow --regalloc better programs/custom_test.oat bin/runtime.c
multitime -n 10 ./oatc -O1 --clang programs/custom_test.oat bin/runtime.c