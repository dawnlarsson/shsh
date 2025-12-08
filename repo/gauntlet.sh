default ITERATIONS 1000

if [ -t 1 ]
  BOLD='\033[1m'
  DIM='\033[2m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  CYAN='\033[36m'
  RED='\033[31m'
  RESET='\033[0m'
else
  BOLD="" DIM="" GREEN="" YELLOW="" CYAN="" RED="" RESET=""
end

now_us() {
  python3 -c 'import time; print(int(time.time()*1000000))'
}

format_time() {
  _us=$1
  if $_us >= 1000000
    _s=$((_us / 1000000))
    _ms=$(((_us % 1000000) / 1000))
    printf "%d.%03ds" "$_s" "$_ms"
  elif $_us >= 1000
    _ms=$((_us / 1000))
    _r=$((_us % 1000))
    printf "%d.%dms" "$_ms" "$((_r / 100))"
  else
    printf "%dµs" "$_us"
  end
}

report() {
  _name="$1"
  _time="$2"
  printf "  ${GREEN}✓${RESET} %-40s ${YELLOW}%s${RESET}\n" "$_name" "$(format_time $_time)"
}

section() {
  printf "\n${BOLD}${CYAN}═══ %s ═══${RESET}\n" "$1"
}

section "IF/ELIF/ELSE CASCADE"

classify_deep() {
  _cd_val=$1
  if $_cd_val < -100: R="very_negative"
  elif $_cd_val < -50: R="negative"
  elif $_cd_val < -10: R="slightly_negative"
  elif $_cd_val < 0: R="tiny_negative"
  elif $_cd_val == 0: R="zero"
  elif $_cd_val < 10: R="tiny_positive"
  elif $_cd_val < 50: R="slightly_positive"
  elif $_cd_val < 100: R="positive"
  else: R="very_positive"
}

_start=$(now_us)
i=0
while $i < $ITERATIONS
  classify_deep -150
  classify_deep -75
  classify_deep -30
  classify_deep -5
  classify_deep 0
  classify_deep 5
  classify_deep 30
  classify_deep 75
  classify_deep 150
  i++
done
_end=$(now_us)
report "classify (9-branch)" $((_end - _start))

# Nested ifs
nested_if_test() {
  _nit_a=$1 _nit_b=$2 _nit_c=$3
  if $_nit_a > 0
    if $_nit_b > 0
      if $_nit_c > 0
        R="all_positive"
      else
        R="c_negative"
      end
    else
      R="b_negative"
    end
  else
    R="a_negative"
  end
}

_start=$(now_us)
i=0
while $i < $ITERATIONS
  nested_if_test 1 1 1
  nested_if_test 1 1 -1
  nested_if_test 1 -1 1
  nested_if_test -1 1 1
  i++
done
_end=$(now_us)
report "nested 3-deep ifs" $((_end - _start))

# Boolean-style conditions
_start=$(now_us)
i=0
_cond_sum=0
while $i < $ITERATIONS
  if $i
    _cond_sum++
  end
  if ! $i
    _cond_sum++
  end
  i++
done
_end=$(now_us)
report "truthiness checks" $((_end - _start))

########################################
# GAUNTLET 2: Switch Statement Stress
########################################
section "SWITCH STATEMENTS"

switch_alphabet() {
  _sa_c="$1"
  switch $_sa_c
  case a|A: R=1
  case b|B: R=2
  case c|C: R=3
  case d|D: R=4
  case e|E: R=5
  case f|F: R=6
  case g|G: R=7
  case h|H: R=8
  case i|I: R=9
  case j|J: R=10
  case k|K: R=11
  case l|L: R=12
  case m|M: R=13
  case n|N: R=14
  case o|O: R=15
  case p|P: R=16
  case q|Q: R=17
  case r|R: R=18
  case s|S: R=19
  case t|T: R=20
  case u|U: R=21
  case v|V: R=22
  case w|W: R=23
  case x|X: R=24
  case y|Y: R=25
  case z|Z: R=26
  default: R=0
  end
}

_start=$(now_us)
i=0
while $i < $ITERATIONS
  switch_alphabet "a"
  switch_alphabet "m"
  switch_alphabet "z"
  switch_alphabet "?"
  i++
done
_end=$(now_us)
report "26-case switch (alphabet)" $((_end - _start))

# Nested switches
switch_nested() {
  _sn_outer="$1"
  _sn_inner="$2"
  switch $_sn_outer
  case foo
    switch $_sn_inner
    case bar: R="foo_bar"
    case baz: R="foo_baz"
    default: R="foo_other"
    end
  case qux
    switch $_sn_inner
    case bar: R="qux_bar"
    case baz: R="qux_baz"
    default: R="qux_other"
    end
  default
    R="unknown"
  end
}

_start=$(now_us)
i=0
while $i < $ITERATIONS
  switch_nested "foo" "bar"
  switch_nested "foo" "baz"
  switch_nested "qux" "bar"
  switch_nested "qux" "xxx"
  switch_nested "xxx" "yyy"
  i++
done
_end=$(now_us)
report "nested switches" $((_end - _start))

# Fall-through simulation with patterns
switch_patterns() {
  _sp_val="$1"
  switch $_sp_val
  case *.txt|*.md|*.sh: R="text"
  case *.jpg|*.png|*.gif|*.bmp: R="image"
  case *.mp3|*.wav|*.flac|*.ogg: R="audio"
  case *.mp4|*.mkv|*.avi|*.mov: R="video"
  case *.tar|*.gz|*.zip|*.7z|*.rar: R="archive"
  case *.py|*.js|*.c|*.go|*.rs: R="code"
  default: R="unknown"
  end
}

_start=$(now_us)
i=0
while $i < $ITERATIONS
  switch_patterns "readme.txt"
  switch_patterns "photo.jpg"
  switch_patterns "song.mp3"
  switch_patterns "movie.mp4"
  switch_patterns "archive.tar.gz"
  switch_patterns "main.py"
  switch_patterns "random.xyz"
  i++
done
_end=$(now_us)
report "pattern matching switch" $((_end - _start))

########################################
# GAUNTLET 3: Try/Catch
########################################
section "TRY/CATCH"

failing_op() {
  return 1
}

succeeding_op() {
  return 0
}

_start=$(now_us)
i=0
_caught=0
while $i < $ITERATIONS
  try
    succeeding_op
    succeeding_op
  catch
    _caught++
  end
  i++
done
_end=$(now_us)
report "try/catch (no errors)" $((_end - _start))

_start=$(now_us)
i=0
_caught=0
while $i < $ITERATIONS
  try
    succeeding_op
    failing_op
    succeeding_op
  catch
    _caught++
  end
  i++
done
_end=$(now_us)
report "try/catch (with error)" $((_end - _start))

# Nested try/catch
_start=$(now_us)
i=0
_outer_caught=0
_inner_caught=0
_nested_iters=$(($ITERATIONS / 10))
while $i < $_nested_iters
  try
    succeeding_op
    try
      failing_op
    catch
      _inner_caught++
    end
    succeeding_op
  catch
    _outer_caught++
  end
  i++
done
_end=$(now_us)
report "nested try/catch" $((_end - _start))

########################################
# GAUNTLET 4: Array Operations
########################################
section "ARRAYS"

_start=$(now_us)
array_clear bench_arr
i=0
while $i < $ITERATIONS
  array_add bench_arr "value_$i"
  i++
done
_end=$(now_us)
report "array_add (sequential)" $((_end - _start))

_start=$(now_us)
i=0
while $i < $ITERATIONS
  array_get bench_arr $i
  i++
done
_end=$(now_us)
report "array_get (sequential)" $((_end - _start))

_start=$(now_us)
i=0
while $i < $ITERATIONS
  array_set bench_arr $i "modified_$i"
  i++
done
_end=$(now_us)
report "array_set (sequential)" $((_end - _start))

_start=$(now_us)
i=0
while $i < $ITERATIONS
  array_len bench_arr
  i++
done
_end=$(now_us)
report "array_len" $((_end - _start))

# Array iteration
array_clear iter_arr
i=0
while $i < 100
  array_add iter_arr "item_$i"
  i++
done
_bench_sum=0
_bench_callback() {
  _bench_sum=$((_bench_sum + 1))
}

_iters=$(($ITERATIONS / 10))
_start=$(now_us)
i=0
while $i < $_iters
  _bench_sum=0
  array_for iter_arr _bench_callback
  i++
done
_end=$(now_us)
report "array_for (100 elements)" $((_end - _start))

########################################
# GAUNTLET 5: Map Operations
########################################
section "MAPS"

_map_iters=$(($ITERATIONS / 2))

_start=$(now_us)
i=0
while $i < $_map_iters
  map_set bench_map "key_$i" "value_$i"
  i++
done
_end=$(now_us)
report "map_set" $((_end - _start))

_start=$(now_us)
i=0
while $i < $_map_iters
  map_get bench_map "key_$i"
  i++
done
_end=$(now_us)
report "map_get" $((_end - _start))

_start=$(now_us)
i=0
while $i < $_map_iters
  map_has bench_map "key_$i"
  i++
done
_end=$(now_us)
report "map_has" $((_end - _start))

# Map iteration
map_clear iter_map
i=0
while $i < 50
  map_set iter_map "k$i" "v$i"
  i++
done
_map_sum=0
_map_callback() {
  _map_sum=$((_map_sum + 1))
}

_iters=$(($ITERATIONS / 20))
_start=$(now_us)
i=0
while $i < $_iters
  _map_sum=0
  map_for iter_map _map_callback
  i++
done
_end=$(now_us)
report "map_for (50 entries)" $((_end - _start))

########################################
# GAUNTLET 6: String Operations
########################################
section "STRING OPERATIONS"

_start=$(now_us)
i=0
while $i < $ITERATIONS
  str_starts "hello world this is a test string" "hello"
  str_starts "hello world this is a test string" "world"
  str_starts "hello world this is a test string" "test"
  i++
done
_end=$(now_us)
report "str_starts" $((_end - _start))

_start=$(now_us)
i=0
while $i < $ITERATIONS
  str_ends "hello world this is a test string" "string"
  str_ends "hello world this is a test string" "test"
  str_ends "hello world this is a test string" "hello"
  i++
done
_end=$(now_us)
report "str_ends" $((_end - _start))

_start=$(now_us)
i=0
while $i < $ITERATIONS
  str_contains "hello world this is a test string" "is a"
  str_contains "hello world this is a test string" "xyz"
  str_contains "hello world this is a test string" "world"
  i++
done
_end=$(now_us)
report "str_contains" $((_end - _start))

_start=$(now_us)
i=0
while $i < $ITERATIONS
  str_after "key=value=extra" "="
  str_before "key=value=extra" "="
  str_after_last "path/to/some/file.txt" "/"
  str_before_last "path/to/some/file.txt" "/"
  i++
done
_end=$(now_us)
report "str_after/before" $((_end - _start))

_start=$(now_us)
i=0
while $i < $ITERATIONS
  str_trim "   lots of whitespace here   "
  str_ltrim "   leading whitespace"
  str_rtrim "trailing whitespace   "
  i++
done
_end=$(now_us)
report "str_trim" $((_end - _start))

########################################
# GAUNTLET 7: Arithmetic & Assignments
########################################
section "ARITHMETIC"

_start=$(now_us)
i=0
_arith_val=0
while $i < $ITERATIONS
  _arith_val++
  i++
done
_end=$(now_us)
report "increment (++)" $((_end - _start))

_start=$(now_us)
i=$ITERATIONS
_arith_val=$ITERATIONS
while $i > 0
  _arith_val--
  i--
done
_end=$(now_us)
report "decrement (--)" $((_end - _start))

_start=$(now_us)
i=0
_arith_val=0
while $i < $ITERATIONS
  _arith_val += 5
  i++
done
_end=$(now_us)
report "compound add (+=)" $((_end - _start))

_start=$(now_us)
i=0
_arith_val=1000000
while $i < $ITERATIONS
  _arith_val -= 1
  i++
done
_end=$(now_us)
report "compound sub (-=)" $((_end - _start))

_start=$(now_us)
i=0
_arith_val=1
_mul_iters=$(($ITERATIONS / 10))
while $i < $_mul_iters
  _arith_val *= 2
  _arith_val /= 2
  i++
done
_end=$(now_us)
report "compound mul/div (*= /=)" $((_end - _start))

########################################
# GAUNTLET 8: Loop Constructs
########################################
section "LOOPS"

# While with comparison
_start=$(now_us)
i=0
_loop_sum=0
while $i < $ITERATIONS
  _loop_sum=$((_loop_sum + i))
  i++
done
_end=$(now_us)
report "while loop (comparison)" $((_end - _start))

# Single-line while
_start=$(now_us)
i=0
_loop_sum=0
while $i < $ITERATIONS: i++; _loop_sum++
_end=$(now_us)
report "single-line while" $((_end - _start))

# For loop
_start=$(now_us)
_for_iters=$(($ITERATIONS / 100))
i=0
while $i < $_for_iters
  for x in a b c d e f g h i j
    _loop_sum++
  done
  i++
done
_end=$(now_us)
report "for loop (10 items)" $((_end - _start))

# Nested loops
_start=$(now_us)
_nest_iters=$(($ITERATIONS / 100))
_loop_sum=0
i=0
while $i < $_nest_iters
  j=0
  while $j < 10
    k=0
    while $k < 10
      _loop_sum++
      k++
    done
    j++
  done
  i++
done
_end=$(now_us)
report "nested 3-deep loops" $((_end - _start))

########################################
# GAUNTLET 9: Functions
########################################
section "FUNCTIONS"

simple_func() {
  R=$(($1 + $2))
}

_start=$(now_us)
i=0
while $i < $ITERATIONS
  simple_func 10 20
  i++
done
_end=$(now_us)
report "simple function call" $((_end - _start))

# Recursive fibonacci (limited depth)
fib_recursive() {
  if $1 <= 1
    R=$1
  else
    fib_recursive $(($1 - 1))
    _fib_a=$R
    fib_recursive $(($1 - 2))
    R=$((_fib_a + R))
  end
}

_start=$(now_us)
_fib_iters=$(($ITERATIONS / 50))
i=0
while $i < $_fib_iters
  fib_recursive 10
  i++
done
_end=$(now_us)
report "recursive fibonacci(10)" $((_end - _start))

# Iterative fibonacci
fib_iterative() {
  _fi_a=0 _fi_b=1 _fi_n=$1
  while $_fi_n > 0
    _fi_t=$((_fi_a + _fi_b))
    _fi_a=$_fi_b
    _fi_b=$_fi_t
    _fi_n--
  done
  R=$_fi_a
}

_start=$(now_us)
i=0
while $i < $ITERATIONS
  fib_iterative 20
  i++
done
_end=$(now_us)
report "iterative fibonacci(20)" $((_end - _start))

# Factorial
factorial() {
  if $1 <= 1
    R=1
  else
    factorial $(($1 - 1))
    R=$(($1 * R))
  end
}

_start=$(now_us)
_fact_iters=$(($ITERATIONS / 10))
i=0
while $i < $_fact_iters
  factorial 10
  i++
done
_end=$(now_us)
report "recursive factorial(10)" $((_end - _start))

########################################
# GAUNTLET 10: Mixed Workload
########################################
section "MIXED WORKLOAD"

complex_operation() {
  _co_type="$1"
  _co_val=$2
  
  switch $_co_type
  case "compute"
    _co_result=0
    _co_i=0
    while $_co_i < 10
      if $_co_val > 50
        _co_result=$((_co_result + _co_val))
      elif $_co_val > 25
        _co_result=$((_co_result + _co_val / 2))
      else
        _co_result=$((_co_result + 1))
      end
      _co_i++
    done
    R=$_co_result
  case "store"
    array_add mixed_arr "$_co_val"
    map_set mixed_map "val_$_co_val" "$_co_val"
    R="stored"
  case "search"
    str_contains "the quick brown fox jumps over the lazy dog" "$_co_val"
    R=$?
  default
    R="unknown"
  end
}

array_clear mixed_arr
map_clear mixed_map

_start=$(now_us)
_mixed_iters=$(($ITERATIONS / 10))
i=0
while $i < $_mixed_iters
  complex_operation "compute" 75
  complex_operation "compute" 30
  complex_operation "compute" 10
  complex_operation "store" "$i"
  complex_operation "search" "fox"
  complex_operation "search" "xyz"
  i++
done
_end=$(now_us)
report "complex mixed operations" $((_end - _start))

# Simulate real-world processing
process_record() {
  _pr_name="$1"
  _pr_value="$2"
  _pr_type="$3"
  
  # Validate
  if "$_pr_name" == "": R="error"; return 1
  
  # Classify
  switch $_pr_type
  case "A"|"B"|"C"
    _pr_category="standard"
  case "X"|"Y"|"Z"
    _pr_category="special"
  default
    _pr_category="unknown"
  end
  
  # Process based on value
  if $_pr_value > 100
    _pr_status="high"
  elif $_pr_value > 50
    _pr_status="medium"
  else
    _pr_status="low"
  end
  
  # Store
  map_set records "$_pr_name" "$_pr_category:$_pr_status:$_pr_value"
  R="ok"
}

map_clear records

_start=$(now_us)
_proc_iters=$(($ITERATIONS / 5))
i=0
while $i < $_proc_iters
  process_record "item_$i" "$((i * 7 % 200))" "A"
  process_record "item_${i}_b" "$((i * 11 % 200))" "X"
  process_record "item_${i}_c" "$((i * 13 % 200))" "Q"
  i++
done
_end=$(now_us)
report "record processing" $((_end - _start))
