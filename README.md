[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/ZUXYzx5M)
# HW10: Constant Propagation, Register Allocation, Experiments

Quick Start:

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