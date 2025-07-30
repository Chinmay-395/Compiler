# Full-Stack Compiler for a C-like Language in OCaml
## High-Level Design and Capabilities
This project is a full-stack compiler that translates a C-like imperative language all the way down to optimized x86 assembly code. It was implemented individually in OCaml (with an LLVM-style backend) and comprises all major compiler phases from lexical analysis to code generation. The overall architecture is organized into clear stages that mirror a modern compiler pipeline:

**Lexical Analysis (Scanning):** The compiler first uses a lexer to convert the raw source code into tokens (identifiers, keywords, symbols, etc.). This phase breaks the input text into meaningful units, making it easier for the parser to digest. It ensures the input stream is free of illegal characters and provides informative errors for malformed tokens.

**Syntax Analysis (Parsing):** Next, a parser (built likely with OCaml’s parsing tools) reads the tokens and constructs an Abstract Syntax Tree (AST) according to the grammar of the C-like language. This phase ensures the program’s structure is syntactically correct (for example, matching braces, correct statement forms, etc.). If any syntax errors are present, the compiler reports them with line numbers. The outcome is a structured AST representing the program’s constructs in a tree form.

**Semantic Analysis:** The AST is then processed for semantic correctness. This includes type checking, scope resolution, and enforcement of language rules. For instance, the compiler verifies that operations receive operands of compatible types and that variables are declared before use. It builds symbol tables for variables and functions, checks function call signatures, and may handle complex language features (like struct field accesses or function pointers in OATv2). This phase ensures the program is type-safe and consistent, rejecting invalid programs (e.g., type errors or undefined variables).

**Intermediate Representation (IR) Generation:** After validation, the compiler translates the AST into a lower-level IR. In this project, the IR was inspired by LLVM IR (OATv2’s IR), essentially a three-address code in Static Single Assignment form (each IR instruction has explicit operands and at most one operation). For example, a high-level expression or control flow construct becomes a sequence of simple instructions (like assignments, binary operations, conditional jumps, etc.). This IR abstracts away high-level syntax, making subsequent optimizations easier. It also explicitly represents control flow with a Control Flow Graph (CFG) of basic blocks, which is essential for advanced analyses.

**Optimization Passes:** The compiler performs several optimization passes on the IR to improve performance and remove redundancies. Key optimizations implemented include Dead Code Elimination (DCE), Constant Propagation, and Constant Folding (detailed below). These are classic dataflow optimizations that operate on the IR’s CFG. They collectively improve the generated code’s efficiency by eliminating unnecessary computations and pre-computing constant values at compile time. The impact is that the final assembly is more efficient (faster and smaller) than naive code. The optimizations are optional (e.g., enabled with a flag like -O1) so one can compile with or without them for comparison.

**Register Allocation:** A crucial backend phase is register allocation, where the compiler decides which program values reside in the CPU’s limited registers at each point. Instead of naively treating every variable as a memory location, the compiler uses graph-coloring algorithms to allocate virtual registers (from the IR) to actual hardware registers, greatly reducing memory access and improving runtime speed. The project implemented an advanced register allocator (beyond simple linear scan or spilling-all) that uses liveness information to minimize spills. This was necessary to achieve near-optimal use of CPU registers and was evaluated against a baseline (like a greedy allocator or no allocation) to demonstrate improved performance.

**Code Generation:** Finally, the compiler emits x86 assembly code (in this case, x86-64) from the optimized IR. In this phase, each IR instruction is translated into one or more x86 instructions, carefully respecting the target platform’s calling convention and constraints. The code generator produces function prologues/epilogues (to set up stack frames), moves data into the appropriate registers for function calls/returns, and uses the allocated registers from the previous phase. The resulting assembly is capable of being assembled and linked into an executable. Because the project targeted a standard platform ABI, the output binaries are interoperable with other C code or libraries. The generated code is also relatively efficient, as the compiler’s optimizations (and some peephole improvements in code selection) produce streamlined instruction sequences.

Overall, the compiler’s design cleanly separates these phases and uses intermediate representations to bridge between the high-level source and low-level machine code. The capability of this project is significant: it can compile non-trivial programs written in a C-like language (including features like functions, loops, conditionals, structures, arrays, etc.) into native x86-64 machine code. By implementing classic optimizations and careful code generation, the compiler not only produces correct output but also relatively efficient code (both in terms of speed and memory usage). This demonstrates a deep understanding of compiler construction – from parsing and semantic analysis all the way to low-level code generation – and yields a toolchain that highlights the impact of each compiler stage on the performance and correctness of the final program.


# Quick Start:

1. clone this repository using `git clone`
2. open the folder in VSCode
3. start an OCaml sandbox terminal
4. run `make test` from the command line
5. open `bin/backend.ml`

See the general toolchain and project instructions on the course web site. The
course web pages have a link to the html version of the homework instructions.


Using ``oatc``
--------------

``oatc`` acts like the clang compiler.  Given several .oat, .ll, .c, and .o
files, it will compile the .oat and .ll files to .s files (using the
frontend and backend) and then combine the results with the .c and .o files to
produce an executable named a.out.  You can also compile the .ll files using
clang instead of the backend, which can be useful for testing
purposes.


* To run the automated test harness do:

        ./oatc --test

* To compile oat files using the backend:

        ./oatc path/to/foo.oat

  - creates output/foo.ll  frontend ll code
  - creates output/foo.s   backend assembly code
  - creates output/foo.o   assembled object file
  - creates a.out          linked executable

 NOTE: by default the .s and .o files are created in 
 a directory called output, and the filenames are 
 chosen so that multiple runs of the compiler will
 not overwrite previous outputs.  foo.ll will be 
 compiled first to foo.s then foo_1.s, foo_2.s, etc.

* To compile oat files using the clang backend:

        ./oatc --clang path/to/foo.oat

* Useful flags:

  | Flag                            | Description                                                                                       |
  |---------------------------------|---------------------------------------------------------------------------------------------------|
  | --regalloc {none,greedy,better} | use the specified register allocator                                                              |
  | --liveness {trivial,dataflow}   | use the specified liveness analysis                                                               |
  | --print-regs                    | prints the register usage statistics for x86 code                                                 |
  | --print-oat                     | pretty prints the Oat abstract syntax to the terminal                                             |
  | --print-ll                      | echoes the ll program to the terminal                                                             |
  | --print-x86                     | echoes the resulting .s file to the terminal                                                      |
  | --interpret-ll                  | runs the ll file through the reference interpreter and outputs the results to the console         |
  | --execute-x86                   | runs the resulting a.out file natively (applies to either the backend or clang-compiled code) |
  | --clang                         | compiles to assembly using clang, not the 341 backend                                             |
  | -v                              | generates verbose output, showing which commands are used for linking, etc.                       |
  | -op ``<dirname>``               | change the output path [DEFAULT=output]                                                           |
  | -o                              | change the generated executable's name [DEFAULT=a.out]                                            |
  | -S                              | stop after generating .s files                                                                    |
  | -c                              | stop after generating .o files                                                                    |
  | -h or --help                    | display the list of options                                                                       |


* Example uses:

Run the test case programs/oat_v1/fact.oat using the backend:

          ./oatc --execute-x86 programs/oat_v1/fact.oat bin/runtime.c 
          120--------------------------------------------------------------- Executing: a.out
          * a.out returned 0


```sql
create table sales (cust varchar(20),prod varchar(20),day integer,month integer,year integer,state char(2),quant integer,date date)

INSERT INTO sales VALUES ('Dan', 'Ham', 17, 6, 2016, 'PA', 825, '2016-06-17');
insert into sales values ('Claire', 'Fish', 28, 11, 2016, 'CT', 84, '2016-11-28');
insert into sales values ('Dan', 'Apple', 12, 11, 2017, 'CT', 973, '2017-11-12');
insert into sales values ('Chae', 'Jellies', 13, 10, 2016, 'NJ', 756, '2016-10-
13');
insert into sales values ('Chae', 'Ham', 11, 4, 2017, 'NY', 464, '2017-04-11');
insert into sales values ('Mia', 'Fish', 25, 9, 2017, 'NJ', 56, '2017-09-25');
insert into sales values ('Mia', 'Dates', 15, 7, 2018, 'PA', 523, '2018-07-15');
insert into sales values ('Claire', 'Fish', 26, 11, 2018, 'CT', 763, '2018-11-26');
insert into sales values ('Dan', 'Butter', 4, 2, 2018, 'NJ', 419, '2018-02-04');
insert into sales values ('Sam', 'Jellies', 5, 7, 2020, 'PA', 156, '2020-07-05');
insert into sales values ('Wally', 'Cherry', 3, 4, 2020, 'CT', 664, '2020-04-03');
insert into sales values ('Chae', 'Apple', 2, 12, 2017, 'NJ', 567, '2017-12-02');
insert into sales values ('Helen', 'Butter', 28, 7, 2020, 'PA', 337, '2020-07-28');
insert into sales values ('Chae', 'Eggs', 2, 2, 2018, 'CT', 665, '2018-02-02');
```

```sql
with monAverage as (
	select prod, month, avg(quant) avgq
	from sales
	group by prod, month
),
bMonth as (
	select a.prod, a.month, b.avgq as beforeAVG
	from monAverage a left join monAverage b on a.prod = b.prod
	and a.month = b.month+1
	order by a.prod, a.month
),
aMonth as (
	select a.prod, a.month, b.avgq as afterAVG
	from monAverage a left join monAverage b on a.prod = b.prod
	and a.month+1 = b.month
	order by a.prod, a.month
),
aux as (
	select a.prod, a.month, b.beforeAVG, c.afterAVG
	from monAverage a, bMonth b, aMonth c
	where a.prod = b.prod and a.month = b.month and b.prod = c.prod and c.month = b.month
	order by a.prod, a.month
)

select h.prod as "PRODUCT", h.month as "MONTH", count(quant) as "SALES_COUNT_BETWEEN_AVGS"
from aux h left join sales s on h.prod = s.prod and h.month = s.month and
((quant between h.beforeAVG and h.afterAVG) or (quant between h.afterAVG and h.beforeAVG))
group by h.prod, h.month
order by h.prod, h.month
```
