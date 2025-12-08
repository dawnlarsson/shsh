#
# shsh comprehensive benchmark suite
# Compares: bash (with bashisms) vs dash vs zsh
#

default ITERATIONS 5000
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHSH_DIR="$(dirname "$SCRIPT_DIR")"

# Colors (if terminal supports it)
if [ -t 1 ]
  BOLD='\033[1m'
  DIM='\033[2m'
  GREEN='\033[32m'
  YELLOW='\033[33m'
  CYAN='\033[36m'
  RESET='\033[0m'
else
  BOLD="" DIM="" GREEN="" YELLOW="" CYAN="" RESET=""
end

# Timing function using python for microsecond precision
now_us() {
  python3 -c 'import time; print(int(time.time()*1000000))'
}

# Format microseconds as human-readable
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

# Calculate speedup ratio
calc_speedup() {
  _base=$1
  _new=$2
  python3 -c "print('%.2fx' % ($_base / $_new))" 2>/dev/null || echo "N/A"
}

# Print section header
section() {
  printf "\n${BOLD}${CYAN}=== %s ===${RESET}\n" "$1"
}

# Print subsection
subsection() {
  printf "\n${YELLOW}--- %s ---${RESET}\n" "$1"
}

# Run a benchmark in specified shell and return time in microseconds
# Usage: run_bench <shell> <code>
run_bench() {
  _shell="$1"
  _code="$2"
  _start=$(now_us)
  $_shell -c "$_code" 2>/dev/null
  _end=$(now_us)
  echo $((_end - _start))
}

# Check available shells
check_shells() {
  printf "${BOLD}Checking available shells...${RESET}\n"
  SHELLS=""
  
  if command -v bash >/dev/null 2>&1
    SHELLS="$SHELLS bash"
    printf "  bash:       $(bash --version | head -1)\n"
  end
  
  if command -v dash >/dev/null 2>&1
    SHELLS="$SHELLS dash"
    printf "  dash:       available\n"
  end
  
  if command -v zsh >/dev/null 2>&1
    SHELLS="$SHELLS zsh"
    printf "  zsh:        $(zsh --version)\n"
  end
  
  if command -v sh >/dev/null 2>&1
    printf "  sh:         $(sh --version 2>&1 | head -1 || echo 'available')\n"
  end
}

# Generate the shsh runtime for embedding
generate_runtime() {
  sed -n '/^# __RUNTIME_START__$/,/^# __RUNTIME_END__$/p' "./shsh.sh"
}

RUNTIME=$(sed -n '/^# __RUNTIME_START__$/,/^# __RUNTIME_END__$/p' "./shsh.sh")

########################################
# BENCHMARK: String Functions
########################################
bench_strings() {
  section "String Functions"
  
  subsection "str_starts (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  str_starts 'hello world' 'hello'
  str_starts 'hello world' 'world'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_str_starts_$shell=$_time"
  done
  
  subsection "str_ends (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  str_ends 'hello world' 'world'
  str_ends 'hello world' 'hello'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_str_ends_$shell=$_time"
  done
  
  subsection "str_contains (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  str_contains 'hello world' 'lo wo'
  str_contains 'hello world' 'xyz'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_str_contains_$shell=$_time"
  done
  
  subsection "str_after/str_before (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  str_after 'hello=world' '='
  str_before 'hello=world' '='
  str_after_last 'a/b/c/d' '/'
  str_before_last 'a/b/c/d' '/'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_str_split_$shell=$_time"
  done
  
  subsection "str_trim/str_ltrim/str_rtrim (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  str_trim '   hello world   '
  str_ltrim '   hello world'
  str_rtrim 'hello world   '
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_str_trim_$shell=$_time"
  done
  
  subsection "str_indent (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  str_indent '    indented line'
  str_indent '		tab indented'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_str_indent_$shell=$_time"
  done
}

########################################
# BENCHMARK: Comparisons (native [ ] tests)
########################################
bench_comparisons() {
  section "Comparisons (native [ ] tests)"
  
  subsection "Numeric comparisons (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  [ \$i -lt 1000 ]
  [ \$i -ge 0 ]
  [ \$i -eq \$i ]
  [ \$i -ne 999 ]
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_is_num_$shell=$_time"
  done
  
  subsection "String comparisons (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  [ \"hello\" = \"hello\" ]
  [ \"hello\" != \"world\" ]
  [ \"abc\" = \"abc\" ]
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_is_str_$shell=$_time"
  done
  
  subsection "Truthiness checks (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  [ -n 'nonempty' ]
  [ -n '' ]
  [ -n 'value' ]
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_is_truth_$shell=$_time"
  done
}

########################################
# BENCHMARK: Default Functions
########################################
bench_defaults() {
  section "Default Functions"
  
  subsection "default (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  unset myvar
  default myvar 'default_value'
  myvar='existing'
  default myvar 'ignored'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_default_$shell=$_time"
  done
  
  subsection "default_unset (${ITERATIONS} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  unset myvar
  default_unset myvar 'default_value'
  myvar=''
  default_unset myvar 'ignored'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_default_unset_$shell=$_time"
  done
}

########################################
# BENCHMARK: Array Operations
########################################
bench_arrays() {
  section "Array Operations"
  
  subsection "array_add (${ITERATIONS} elements)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  array_add myarr \"value\$i\"
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_add_$shell=$_time"
  done
  
  subsection "array_set (${ITERATIONS} elements)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $ITERATIONS ]; do
  array_set myarr \$i \"value\$i\"
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_set_$shell=$_time"
  done
  
  subsection "array_get (${ITERATIONS} lookups)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate
i=0; while [ \$i -lt $ITERATIONS ]; do
  array_set myarr \$i \"value\$i\"
  i=\$((i + 1))
done
# Benchmark gets
i=0; while [ \$i -lt $ITERATIONS ]; do
  array_get myarr \$i
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_get_$shell=$_time"
  done
  
  subsection "array_len (${ITERATIONS} calls)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate
i=0; while [ \$i -lt 100 ]; do
  array_add myarr \"value\$i\"
  i=\$((i + 1))
done
# Benchmark len
i=0; while [ \$i -lt $ITERATIONS ]; do
  array_len myarr
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_len_$shell=$_time"
  done
  
  subsection "array_for (iterating 100 element array, ${ITERATIONS} times)"
  
  _arr_for_iters=$((ITERATIONS / 10))
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate
i=0; while [ \$i -lt 100 ]; do
  array_add myarr \"value\$i\"
  i=\$((i + 1))
done
# Callback
process_item() { : \"\$R\"; }
# Benchmark for
i=0; while [ \$i -lt $_arr_for_iters ]; do
  array_for myarr process_item
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_for_$shell=$_time"
  done
  
  subsection "array_unset (${ITERATIONS} operations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate
i=0; while [ \$i -lt $ITERATIONS ]; do
  array_set myarr \$i \"value\$i\"
  i=\$((i + 1))
done
# Benchmark unset
i=0; while [ \$i -lt $ITERATIONS ]; do
  array_unset myarr \$i
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_unset_$shell=$_time"
  done
  
  subsection "array_remove (removing from 100 element array)"
  
  _arr_rem_iters=$((ITERATIONS / 5))
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_arr_rem_iters ]; do
  # Re-populate each iteration
  j=0; while [ \$j -lt 100 ]; do
    array_set myarr \$j \"value\$j\"
    j=\$((j + 1))
  done
  __shsh_myarr_n=100
  # Remove from beginning (worst case - shifts all elements)
  array_remove myarr 0
  array_remove myarr 0
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_remove_$shell=$_time"
  done
  
  subsection "array_clear (clearing 100 element array, ${ITERATIONS} times)"
  
  _arr_clr_iters=$((ITERATIONS / 5))
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_arr_clr_iters ]; do
  # Re-populate
  j=0; while [ \$j -lt 100 ]; do
    array_set myarr \$j \"value\$j\"
    j=\$((j + 1))
  done
  __shsh_myarr_n=100
  # Clear
  array_clear myarr
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_arr_clear_$shell=$_time"
  done
}

########################################
# BENCHMARK: Map Operations
########################################
bench_maps() {
  section "Map Operations"
  
  _map_iters=$((ITERATIONS / 2))  # Maps are slower
  
  subsection "map_set (${_map_iters} entries)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_map_iters ]; do
  map_set mymap \"key\$i\" \"value\$i\"
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_map_set_$shell=$_time"
  done
  
  subsection "map_get (${_map_iters} lookups)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate
i=0; while [ \$i -lt $_map_iters ]; do
  map_set mymap \"key\$i\" \"value\$i\"
  i=\$((i + 1))
done
# Benchmark gets
i=0; while [ \$i -lt $_map_iters ]; do
  map_get mymap \"key\$i\"
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_map_get_$shell=$_time"
  done
  
  subsection "map_has (${_map_iters} checks)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate
i=0; while [ \$i -lt $_map_iters ]; do
  map_set mymap \"key\$i\" \"value\$i\"
  i=\$((i + 1))
done
# Benchmark has
i=0; while [ \$i -lt $_map_iters ]; do
  map_has mymap \"key\$i\"
  map_has mymap \"nokey\$i\"
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_map_has_$shell=$_time"
  done
  
  subsection "map_delete (${_map_iters} deletions)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate
i=0; while [ \$i -lt $_map_iters ]; do
  map_set mymap \"key\$i\" \"value\$i\"
  i=\$((i + 1))
done
# Benchmark delete
i=0; while [ \$i -lt $_map_iters ]; do
  map_delete mymap \"key\$i\"
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_map_delete_$shell=$_time"
  done
  
  subsection "map_keys (50 entries, ${_map_iters} times)"
  
  _map_keys_iters=$((_map_iters / 5))
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate with 50 entries
i=0; while [ \$i -lt 50 ]; do
  map_set mymap \"key\$i\" \"value\$i\"
  i=\$((i + 1))
done
# Benchmark map_keys
i=0; while [ \$i -lt $_map_keys_iters ]; do
  map_keys mymap keysarr
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_map_keys_$shell=$_time"
  done
  
  subsection "map_for (50 entries, iterating ${_map_iters} times)"
  
  _map_for_iters=$((_map_iters / 5))
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Pre-populate with 50 entries
i=0; while [ \$i -lt 50 ]; do
  map_set mymap \"key\$i\" \"value\$i\"
  i=\$((i + 1))
done
# Callback
process_entry() { : \"\$K\" \"\$R\"; }
# Benchmark map_for
i=0; while [ \$i -lt $_map_for_iters ]; do
  map_for mymap process_entry
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_map_for_$shell=$_time"
  done
  
  subsection "map_clear (50 entries, ${_map_iters} times)"
  
  _map_clr_iters=$((_map_iters / 5))
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_map_clr_iters ]; do
  # Re-populate
  j=0; while [ \$j -lt 50 ]; do
    map_set mymap \"key\$j\" \"value\$j\"
    j=\$((j + 1))
  done
  # Clear
  map_clear mymap
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_map_clear_$shell=$_time"
  done
}

########################################
# BENCHMARK: File Operations
########################################
bench_files() {
  section "File Operations"
  
  # Create temp directory for file tests
  _tmpdir=$(mktemp -d)
  _testfile="$_tmpdir/testfile.txt"
  _testfile2="$_tmpdir/testfile2.txt"
  
  # Create test file with content
  printf "line1\nline2\nline3\nline4\nline5\n" > "$_testfile"
  
  _file_iters=$((ITERATIONS / 5))  # File ops are slower
  
  subsection "file_exists/dir_exists (${_file_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_file_iters ]; do
  file_exists '$_testfile'
  file_exists '/nonexistent/file'
  dir_exists '$_tmpdir'
  dir_exists '/nonexistent/dir'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_file_exists_$shell=$_time"
  done
  
  subsection "file_read (5 line file, ${_file_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_file_iters ]; do
  file_read '$_testfile'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_file_read_$shell=$_time"
  done
  
  subsection "file_write (${_file_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_file_iters ]; do
  file_write '$_testfile2' 'test content line'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_file_write_$shell=$_time"
  done
  
  subsection "file_append (${_file_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Reset file
printf '' > '$_testfile2'
i=0; while [ \$i -lt $_file_iters ]; do
  file_append '$_testfile2' 'appended line'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_file_append_$shell=$_time"
  done
  
  subsection "file_lines (5 line file into array, ${_file_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_file_iters ]; do
  file_lines '$_testfile' mylines
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_file_lines_$shell=$_time"
  done
  
  subsection "file_each (5 line file with callback, ${_file_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
process_line() { : \"\$R\"; }
i=0; while [ \$i -lt $_file_iters ]; do
  file_each '$_testfile' process_line
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_file_each_$shell=$_time"
  done
  
  # Cleanup
  rm -rf "$_tmpdir"
}

########################################
# BENCHMARK: Tokenize Function
########################################
bench_tokenize() {
  section "Tokenize Function"
  
  _tok_iters=$((ITERATIONS / 10))  # Tokenize is slow
  
  subsection "tokenize simple (${_tok_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_tok_iters ]; do
  tokenize 'hello world foo bar' tokens
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_tok_simple_$shell=$_time"
  done
  
  subsection "tokenize with quotes (${_tok_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_tok_iters ]; do
  tokenize 'cmd \"quoted arg\" plain' tokens
  tokenize \"cmd 'single quoted' arg\" tokens
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_tok_quotes_$shell=$_time"
  done
  
  subsection "tokenize with parens (${_tok_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_tok_iters ]; do
  tokenize 'func(arg1 arg2)' tokens
  tokenize '(nested (parens))' tokens
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_tok_parens_$shell=$_time"
  done
}

########################################
# BENCHMARK: Binary Functions
########################################
bench_binary() {
  section "Binary Functions"
  
  _bin_iters=$((ITERATIONS / 5))
  
  subsection "bit_8 (${_bin_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_bin_iters ]; do
  bit_8 65 66 67 68 >/dev/null
  bit_8 0x41 0x42 0x43 >/dev/null
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_bit8_$shell=$_time"
  done
  
  subsection "bit_16 (${_bin_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_bin_iters ]; do
  bit_16 0x1234 0x5678 >/dev/null
  bit_16 1000 2000 3000 >/dev/null
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_bit16_$shell=$_time"
  done
  
  subsection "bit_32 (${_bin_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_bin_iters ]; do
  bit_32 0x12345678 0xDEADBEEF >/dev/null
  bit_32 1000000 2000000 >/dev/null
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_bit32_$shell=$_time"
  done
  
  subsection "bit_64 (${_bin_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_bin_iters ]; do
  bit_64 0x123456789ABCDEF0 >/dev/null
  bit_64 1000000000 >/dev/null
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_bit64_$shell=$_time"
  done
  
  subsection "bit_8 string output (${_bin_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_bin_iters ]; do
  bit_8 '\"Hello\"' >/dev/null
  bit_8 '\"World\"' >/dev/null
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_bit8str_$shell=$_time"
  done
  
  subsection "Endian switching (${_bin_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_bin_iters ]; do
  ENDIAN=little bit_16 0x1234 >/dev/null
  ENDIAN=big bit_16 0x1234 >/dev/null
  ENDIAN=0 bit_32 0x12345678 >/dev/null
  ENDIAN=1 bit_32 0x12345678 >/dev/null
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_endian_$shell=$_time"
  done
}

########################################
# BENCHMARK: Real-world simulation
########################################
bench_realworld() {
  section "Real-world Simulation"
  
  _rw_iters=$((ITERATIONS / 5))
  
  subsection "Config parsing simulation (${_rw_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
parse_config_line() {
  str_contains \"\$1\" '=' || return 1
  str_before \"\$1\" '='; _key=\"\$R\"
  str_after \"\$1\" '='; _val=\"\$R\"
  map_set config \"\$_key\" \"\$_val\"
}

i=0; while [ \$i -lt $_rw_iters ]; do
  parse_config_line \"host=localhost\"
  parse_config_line \"port=8080\"
  parse_config_line \"debug=true\"
  parse_config_line \"timeout=30\"
  map_get config host
  map_get config port
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_rw_config_$shell=$_time"
  done
  
  subsection "Path manipulation simulation (${_rw_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_rw_iters ]; do
  path='/usr/local/bin/program.sh'
  str_after_last \"\$path\" '/'; filename=\"\$R\"
  str_before_last \"\$path\" '/'; dirname=\"\$R\"
  str_after_last \"\$filename\" '.'; ext=\"\$R\"
  str_before_last \"\$filename\" '.'; basename=\"\$R\"
  str_starts \"\$path\" '/'
  str_ends \"\$filename\" '.sh'
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_rw_path_$shell=$_time"
  done
  
  subsection "Text processing simulation (${_rw_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
i=0; while [ \$i -lt $_rw_iters ]; do
  # Simulate processing log lines
  line='   INFO: 2024-01-15 Request processed successfully   '
  str_trim \"\$line\"; clean=\"\$R\"
  str_starts \"\$clean\" 'INFO'
  str_contains \"\$clean\" 'processed'
  str_after \"\$clean\" ': '; rest=\"\$R\"
  str_before \"\$rest\" ' '; date=\"\$R\"
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_rw_text_$shell=$_time"
  done
  
  subsection "Data structure simulation (${_rw_iters} iterations)"
  
  _ds_iters=$((_rw_iters / 2))
  for shell in $SHELLS; do
    _code="
$RUNTIME
# Simulate a simple queue using arrays
enqueue() { array_add queue \"\$1\"; }
dequeue() { array_get queue 0 && array_remove queue 0; }

i=0; while [ \$i -lt $_ds_iters ]; do
  # Enqueue items
  enqueue 'task1'
  enqueue 'task2'
  enqueue 'task3'
  # Process queue
  dequeue
  dequeue
  enqueue 'task4'
  dequeue
  dequeue
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_rw_queue_$shell=$_time"
  done
  
  subsection "Argument parsing simulation (${_rw_iters} iterations)"
  
  for shell in $SHELLS; do
    _code="
$RUNTIME
parse_args() {
  for arg in \"\$@\"; do
    if str_starts \"\$arg\" '--'; then
      str_after \"\$arg\" '--'; _name=\"\$R\"
      if str_contains \"\$_name\" '='; then
        str_before \"\$_name\" '='; _key=\"\$R\"
        str_after \"\$_name\" '='; _val=\"\$R\"
        map_set opts \"\$_key\" \"\$_val\"
      else
        map_set opts \"\$_name\" '1'
      fi
    else
      array_add positional \"\$arg\"
    fi
  done
}

i=0; while [ \$i -lt $_rw_iters ]; do
  parse_args --verbose --config=app.conf --port=8080 file1.txt file2.txt
  map_get opts verbose
  map_get opts config
  array_get positional 0
  map_clear opts
  array_clear positional
  i=\$((i + 1))
done"
    _time=$(run_bench "$shell" "$_code")
    printf "  %-12s %s\n" "$shell:" "$(format_time $_time)"
    eval "time_rw_args_$shell=$_time"
  done
}

########################################
# SUMMARY
########################################

# Format time for summary table (compact)
format_time_compact() {
  _us=$1
  if $_us >= 1000000
    _s=$((_us / 1000000))
    _ms=$(((_us % 1000000) / 1000))
    printf "%d.%02ds" "$_s" "$((_ms / 10))"
  elif $_us >= 1000
    _ms=$((_us / 1000))
    _r=$((_us % 1000))
    printf "%d.%dms" "$_ms" "$((_r / 100))"
  else
    printf "%dµs" "$_us"
  end
}

# Print a summary row with timing data
print_summary_row() {
  _row_name="$1"
  _time_var_prefix="$2"
  
  printf "  %-22s" "$_row_name"
  for shell in $SHELLS; do
    eval "_t=\$${_time_var_prefix}_$shell"
    if "$_t" != ""
      _formatted=$(format_time_compact "$_t")
      eval "_base=\$${_time_var_prefix}_$_baseline"
      _ratio=$(calc_speedup "$_base" "$_t")
      printf "%-18s" "$_formatted ($_ratio)"
    else
      printf "%-18s" "N/A"
    end
  done
  printf "\n"
}

print_summary() {
  section "Summary"
  
  printf "\n${BOLD}Performance by shell (time + speedup vs baseline):${RESET}\n\n"
  
  if "$time_str_starts_dash" != ""
    _baseline="dash"
  else
    _baseline="bash"
  end
  
  printf "%-24s" "Test"
  for shell in $SHELLS; do
    printf "%-18s" "$shell"
  done
  printf "\n"
  printf "%.78s\n" "------------------------------------------------------------------------------"
  
  # String functions
  printf "${CYAN}String Functions${RESET}\n"
  print_summary_row "str_starts" "time_str_starts"
  print_summary_row "str_ends" "time_str_ends"
  print_summary_row "str_contains" "time_str_contains"
  print_summary_row "str_after/before" "time_str_split"
  print_summary_row "str_trim" "time_str_trim"
  print_summary_row "str_indent" "time_str_indent"
  
  # Comparisons
  printf "${CYAN}Comparisons${RESET}\n"
  print_summary_row "cmp (numeric)" "time_is_num"
  print_summary_row "cmp (string)" "time_is_str"
  print_summary_row "cmp (truthiness)" "time_is_truth"
  
  # Defaults
  printf "${CYAN}Defaults${RESET}\n"
  print_summary_row "default" "time_default"
  print_summary_row "default_unset" "time_default_unset"
  
  # Arrays
  printf "${CYAN}Arrays${RESET}\n"
  print_summary_row "array_add" "time_arr_add"
  print_summary_row "array_set" "time_arr_set"
  print_summary_row "array_get" "time_arr_get"
  print_summary_row "array_len" "time_arr_len"
  print_summary_row "array_for" "time_arr_for"
  print_summary_row "array_unset" "time_arr_unset"
  print_summary_row "array_remove" "time_arr_remove"
  print_summary_row "array_clear" "time_arr_clear"
  
  # Maps
  printf "${CYAN}Maps${RESET}\n"
  print_summary_row "map_set" "time_map_set"
  print_summary_row "map_get" "time_map_get"
  print_summary_row "map_has" "time_map_has"
  print_summary_row "map_delete" "time_map_delete"
  print_summary_row "map_keys" "time_map_keys"
  print_summary_row "map_for" "time_map_for"
  print_summary_row "map_clear" "time_map_clear"
  
  # File operations
  printf "${CYAN}File Operations${RESET}\n"
  print_summary_row "file_exists" "time_file_exists"
  print_summary_row "file_read" "time_file_read"
  print_summary_row "file_write" "time_file_write"
  print_summary_row "file_append" "time_file_append"
  print_summary_row "file_lines" "time_file_lines"
  print_summary_row "file_each" "time_file_each"
  
  # Tokenize
  printf "${CYAN}Tokenize${RESET}\n"
  print_summary_row "simple" "time_tok_simple"
  print_summary_row "with quotes" "time_tok_quotes"
  print_summary_row "with parens" "time_tok_parens"
  
  # Binary functions
  printf "${CYAN}Binary Functions${RESET}\n"
  print_summary_row "bit_8" "time_bit8"
  print_summary_row "bit_16" "time_bit16"
  print_summary_row "bit_32" "time_bit32"
  print_summary_row "bit_64" "time_bit64"
  print_summary_row "bit_8 (strings)" "time_bit8str"
  print_summary_row "endian switch" "time_endian"
  
  # Real-world
  printf "${CYAN}Real-world Simulations${RESET}\n"
  print_summary_row "config parsing" "time_rw_config"
  print_summary_row "path manipulation" "time_rw_path"
  print_summary_row "text processing" "time_rw_text"
  print_summary_row "queue simulation" "time_rw_queue"
  print_summary_row "argument parsing" "time_rw_args"
  
  printf "\n${DIM}(Time shown with speedup ratio vs $_baseline baseline. Higher ratio = faster)${RESET}\n"
}

main() {
  printf "${BOLD}shsh Benchmark Suite${RESET}\n"
  printf "Iterations: ${ITERATIONS}\n"
  printf "Date: $(date)\n"
  
  check_shells
  
  bench_strings
  bench_comparisons
  bench_defaults
  bench_arrays
  bench_maps
  bench_files
  bench_tokenize
  bench_binary
  bench_realworld
  
  print_summary
  
  printf "\n${GREEN}Benchmark complete.${RESET}\n"
}

main "$@"
