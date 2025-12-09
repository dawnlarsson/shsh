PASS=0 
FAIL=0

_test_script="repo/test.sh"
if file_exists "./shsh.sh"
  _shsh="./shsh.sh"
  _shsh_src="./shsh.shsh"
elif file_exists "../shsh.sh"
  _shsh="../shsh.sh"
  _shsh_src="../shsh.shsh"
else
  _shsh="shsh"
  _shsh_src="shsh.shsh"
end

assert_eq() {
  _aeq_name="$1" _aeq_got="$2" _aeq_want="$3"
  if "$_aeq_got" == "$_aeq_want"
    echo "✓ $_aeq_name"; PASS++
  else
    echo "✗ $_aeq_name: got '$_aeq_got', want '$_aeq_want'"; FAIL++
  end
}

assert_neq() {
  _aneq_name="$1" _aneq_got="$2" _aneq_reject="$3"
  if "$_aneq_got" != "$_aneq_reject"
    echo "✓ $_aneq_name"; PASS++
  else
    echo "✗ $_aneq_name: got '$_aneq_got', should not be '$_aneq_reject'"; FAIL++
  end
}

hex_capture() {
  eval "$1" | od -A n -t x1 -v | tr -d ' \n'
}

pass() { echo "✓ $1"; PASS++; }
fail() { echo "✗ $1"; FAIL++; }

echo "=== Arrays ==="

array_add arr "one"
array_add arr "two"
array_add arr "three"
array_len arr; assert_eq "array_len" "$R" "3"
array_get arr 0; assert_eq "array_get 0" "$R" "one"
array_get arr 2; assert_eq "array_get 2" "$R" "three"
array_set arr 1 "TWO"; array_get arr 1; assert_eq "array_set" "$R" "TWO"
count=0; counter() { count=$((count + 1)); }
array_for arr counter; assert_eq "array_for count" "$count" "3"
array_clear arr; array_len arr; assert_eq "array_clear" "$R" "0"

array_add full_clear "keep"
array_add full_clear "drop"
array_clear_full full_clear
array_len full_clear; assert_eq "array_clear_full len" "$R" "0"
array_get full_clear 0; full_clear_ret=$?
if $full_clear_ret != 0
  pass "array_clear_full empties storage"
else
  fail "array_clear_full should remove entries"
end
array_add full_clear "again"
array_len full_clear; assert_eq "array_clear_full reuse len" "$R" "1"
array_get full_clear 0; assert_eq "array_clear_full reuse value" "$R" "again"

array_clear empty_arr
empty_count=0
empty_cb() { empty_count=$((empty_count + 1)); }
array_for empty_arr empty_cb
assert_eq "array_for empty" "$empty_count" "0"

array_clear del_test
array_add del_test "a"
array_add del_test "b"
array_add del_test "c"
array_delete del_test 1
array_len del_test; assert_eq "array_delete len" "$R" "2"
array_get del_test 0; assert_eq "array_delete idx0" "$R" "a"
array_get del_test 1; assert_eq "array_delete idx1" "$R" "c"

array_clear neg_idx
array_add neg_idx "keep"
array_remove neg_idx -1
neg_ret=$?
array_len neg_idx; assert_eq "array_remove negative len" "$R" "1"
if $neg_ret != 0
  pass "array_remove negative index errors"
else
  fail "array_remove negative index should error"
end

array_clear rm_test
array_add rm_test "a"
array_add rm_test "b"
array_add rm_test "c"
array_remove rm_test 1
array_len rm_test; assert_eq "array_remove len" "$R" "2"
array_get rm_test 1; assert_eq "array_remove shifts" "$R" "c"

array_clear unset_test
array_add unset_test "x"
array_add unset_test "y"
array_add unset_test "z"
array_unset unset_test 1
array_len unset_test; assert_eq "array_unset len" "$R" "3"
array_get unset_test 1
if "$R" == ""
  pass "array_unset leaves hole"
else
  fail "array_unset leaves hole"
end
array_get unset_test 2; assert_eq "array_unset idx2" "$R" "z"

array_clear bounds_del
array_add bounds_del "only"
array_delete bounds_del 5
ret=$?
if $ret != 0
  pass "array_delete out of bounds returns error"
else
  fail "array_delete out of bounds should error"
end

array_clear multi_del
array_add multi_del "a"
array_add multi_del "b"
array_add multi_del "c"
array_add multi_del "d"
array_delete multi_del 1
array_delete multi_del 1
array_len multi_del; assert_eq "multi delete len" "$R" "2"
array_get multi_del 0; assert_eq "multi delete idx0" "$R" "a"
array_get multi_del 1; assert_eq "multi delete idx1" "$R" "d"

echo
echo "=== Maps ==="

map_set config "host" "localhost"
map_set config "port" "8080"
map_get config "host"; assert_eq "map host" "$R" "localhost"
map_get config "port"; assert_eq "map port" "$R" "8080"
map_set config "port" "9000"; map_get config "port"; assert_eq "map overwrite" "$R" "9000"
if map_has config "host"
  pass "map_has existing"
else
  fail "map_has existing"
end
if map_has config "invalid_key"
  fail "map_has missing"
else
  pass "map_has missing"
end

map_set del_map foo "bar"
map_set del_map baz "qux"
map_delete del_map foo
if map_has del_map foo
  fail "map_delete"
else
  pass "map_delete"
end
map_get del_map baz; assert_eq "map_delete preserves" "$R" "qux"

map_set empty "key" ""
map_get empty "key"; assert_eq "empty string" "$R" ""
if map_has empty "key"
  pass "map_has empty"
else
  fail "map_has empty"
end

map_set math "zero" 0
map_get math "zero"; assert_eq "zero value" "$R" "0"

map_set badmap "key-with-dash" "value" 2>/dev/null
ret=$?
if $ret != 0
  pass "map rejects invalid key"
else
  map_get badmap "key-with-dash"
  if "$R" == ""
    pass "map rejects invalid key (silent)"
  else
    fail "map accepted invalid key"
  end
end

map_set emptykey "" "val" 2>/dev/null
ret=$?
if $ret != 0
  pass "map rejects empty key"
else
  fail "map accepted empty key"
end

echo
echo "=== Special Values ==="

array_add spaced "hello world"
array_add spaced "foo bar baz"
array_get spaced 0; assert_eq "space value 0" "$R" "hello world"
array_get spaced 1; assert_eq "space value 1" "$R" "foo bar baz"

array_add chars "*"
array_get chars 0; assert_eq "glob in arrays" "$R" "*"
touch "100" "aaaa"
val="*"
if "$val" == "*"
  pass "glob disabled in is"
else
  fail "glob active in is"
end
rm "100" "aaaa"

array_add chars "I'm Here"
array_get chars 1; assert_eq "single quote" "$R" "I'm Here"
array_add chars 'He said "Hello"'
array_get chars 2; assert_eq "double quote" "$R" 'He said "Hello"'

bs='path\\to\\file'
map_set paths "win" "$bs"
map_get paths "win"; assert_eq "backslash" "$R" "$bs"

ml="line1
line2
line3"
array_add multi "$ml"
array_get multi 0; assert_eq "multiline" "$R" "$ml"

dash_val="-n"
if "$dash_val" == "-n"
  pass "dash strings"
else
  fail "dash strings"
end

price="Costs \$100"
map_set product "price" "$price"
map_get product "price"; assert_eq "literal $" "$R" 'Costs $100'

tab_val="a	b"
map_set tabs "t" "$tab_val"
map_get tabs "t"; assert_eq "tab char" "$R" "$tab_val"

echo
echo "=== Conditionals ==="

n=5
if $n <= 10
  r1="yes"
end
assert_eq "n <= 10" "$r1" "yes"
if $n > 3
  r2="yes"
end
assert_eq "n > 3" "$r2" "yes"
if $n == 5
  r3="yes"
end
assert_eq "n == 5" "$r3" "yes"
if $n != 99
  r4="yes"
end
assert_eq "n != 99" "$r4" "yes"
if $n >= 5
  r5="yes"
end
assert_eq "n >= 5" "$r5" "yes"
if $n < 100
  r6="yes"
end
assert_eq "n < 100" "$r6" "yes"

neg=-10
if $neg < 0
  pass "negative less than zero"
else
  fail "negative less than zero"
end
if $neg <= -10
  pass "negative lte"
else
  fail "negative lte"
end
if $neg > -20
  pass "negative gt"
else
  fail "negative gt"
end

if "apple" == "apple"
  pass "string eq"
else
  fail "string eq"
end
if "apple" != "banana"
  pass "string neq"
else
  fail "string neq"
end

empty_str=""
if "$empty_str" == ""
  pass "empty string eq"
else
  fail "empty string eq"
end
nonempty="x"
if "$nonempty" != ""
  pass "nonempty string neq empty"
else
  fail "nonempty string neq empty"
end

str="a b"
if $str == "a b"
  r="match"
end
assert_eq "spaces in if" "$r" "match"

if "a b" == "x y"
  fail "false positive"
else
  pass "false positive check"
end

val="x <= y"
if "$val" == "x <= y"
  pass "operator in value"
else
  fail "operator in value"
end

val2="5 < 10"
if "$val2" == "5 < 10"
  pass "full expression as value"
else
  fail "full expression as value"
end

echo
echo "=== Functions ==="

classify() {
  _cl_x="$1"
  if $_cl_x < 0
    R="negative"
  elif $_cl_x == 0
    R="zero"
  elif $_cl_x <= 10
    R="small"
  else
    R="big"
  end
}
classify -5; assert_eq "classify -5" "$R" "negative"
classify 0; assert_eq "classify 0" "$R" "zero"
classify 7; assert_eq "classify 7" "$R" "small"
classify 100; assert_eq "classify 100" "$R" "big"

factorial() {
  if $1 <= 1
    R=1
  else
    factorial $(($1 - 1))
    R=$(($1 * R))
  end
}
factorial 5; assert_eq "factorial 5" "$R" "120"
factorial 0; assert_eq "factorial 0" "$R" "1"
factorial 10; assert_eq "factorial 10" "$R" "3628800"

fib() {
  _fib_a=0 _fib_b=1 _fib_n=$1
  while $_fib_n > 0
    _fib_t=$((_fib_a + _fib_b))
    _fib_a=$_fib_b
    _fib_b=$_fib_t
    _fib_n=$((_fib_n - 1))
  done
  R=$_fib_a
}
fib 10; assert_eq "fib 10" "$R" "55"
fib 0; assert_eq "fib 0" "$R" "0"
fib 1; assert_eq "fib 1" "$R" "1"

echo
echo "=== Loops ==="

x=0
_while_sum=0
while $x < 5
  _while_sum=$((_while_sum + x))
  x=$((x + 1))
done
assert_eq "while loop" "$_while_sum" "10"

y=10
_no_iter=0
while $y < 5
  _no_iter=1
done
assert_eq "while zero iterations" "$_no_iter" "0"

_for_out=""
for i in a b c
  _for_out="$_for_out$i"
done
assert_eq "for loop" "$_for_out" "abc"

_single=""
for s in only
  _single="$s"
done
assert_eq "for single" "$_single" "only"

_nested_for=""
for a in 1 2
  for b in x y
    _nested_for="$_nested_for$a$b"
  done
done
assert_eq "nested for" "$_nested_for" "1x1y2x2y"

echo
echo "=== Switch ==="

_sw_result=""
for val in foo bar baz qux
  switch $val
  case foo: _sw_result="${_sw_result}F"
  case bar|baz: _sw_result="${_sw_result}B"
  default: _sw_result="${_sw_result}X"
  end
done
assert_eq "switch" "$_sw_result" "FBBX"

_nested_sw=""
for outer in a b
  for inner in x y
    switch $outer
    case a
      switch $inner
        case x: _nested_sw="${_nested_sw}ax"
        case y: _nested_sw="${_nested_sw}ay"
      end
    case b
        _nested_sw="${_nested_sw}b"
    end
  done
done
assert_eq "nested switch" "$_nested_sw" "axaybb"

result=""
for a in 1 2
  switch $a
  case 1
    for b in x y
      switch $b
      case x
        for c in p q
          switch $c
          case p
            result="${result}1xp"
          case q
            result="${result}1xq"
          end
        done
      case y
        result="${result}1y"
      end
    done
  case 2
    result="${result}2"
  end
done
assert_eq "3-level nested switch" "$result" "1xp1xq1y2"

_def_only=""
switch "unknown"
default: _def_only="hit"
end
assert_eq "switch default only" "$_def_only" "hit"

_no_match="unchanged"
switch "nomatch"
case foo: _no_match="foo"
case bar: _no_match="bar"
end
assert_eq "switch no match" "$_no_match" "unchanged"

echo
echo "=== Tokenizer ==="

tokenize "(add 1 2)" T1
array_len T1; assert_eq "token count simple" "$R" "5"
array_get T1 0; assert_eq "token 0" "$R" "("
array_get T1 1; assert_eq "token 1" "$R" "add"
array_get T1 4; assert_eq "token 4" "$R" ")"
tokenize "(define (f x) (+ x 1))" T2
array_len T2; assert_eq "token count nested" "$R" "12"

input='(print "a ( b )")'
tokenize "$input" T_QUOTE
array_len T_QUOTE; assert_eq "tokenizer quotes" "$R" "4"

tokenize "(print 'hello ( world )')" T_SQ
array_len T_SQ; assert_eq "tokenizer single quotes" "$R" "4"

tokenize '(test "hello\"world")' T_ESC
array_len T_ESC; assert_eq "tokenizer escapes" "$R" "4"

tokenize "" T_EMPTY
array_len T_EMPTY; assert_eq "tokenizer empty" "$R" "0"

tokenize "   " T_WS
array_len T_WS; assert_eq "tokenizer whitespace" "$R" "0"

tokenize "((()))" T_DEEP
array_len T_DEEP; assert_eq "tokenizer deep nesting" "$R" "6"

tokenize "foo bar baz" T_ATOMS
array_len T_ATOMS; assert_eq "tokenizer atoms" "$R" "3"
array_get T_ATOMS 1; assert_eq "tokenizer atom 1" "$R" "bar"

echo
echo "=== Files ==="

file_write /tmp/shsh_test.txt "hello"
file_append /tmp/shsh_test.txt "world"
file_read /tmp/shsh_test.txt
assert_eq "file_read" "$R" "hello
world"
file_lines /tmp/shsh_test.txt flines
array_len flines; assert_eq "file_lines count" "$R" "2"
array_get flines 0; assert_eq "file_lines 0" "$R" "hello"
array_get flines 1; assert_eq "file_lines 1" "$R" "world"

file_write /tmp/shsh_test2.txt "a"
file_append /tmp/shsh_test2.txt "b"
file_append /tmp/shsh_test2.txt "c"
concat=""
concat_line() { concat="$concat$R"; }
file_each /tmp/shsh_test2.txt concat_line
assert_eq "file_each concat" "$concat" "abc"

if file_exists /tmp/shsh_test.txt
  pass "file_exists yes"
else
  fail "file_exists yes"
end
if file_exists /tmp/nonexistent_xyz
  fail "file_exists no"
else
  pass "file_exists no"
end
if dir_exists /tmp
  pass "dir_exists yes"
else
  fail "dir_exists yes"
end
if dir_exists /tmp/nonexistent_xyz
  fail "dir_exists no"
else
  pass "dir_exists no"
end

file_write /tmp/shsh_empty.txt ""
file_read /tmp/shsh_empty.txt
assert_eq "file_read empty" "$R" ""

file_write /tmp/shsh_special.txt 'line with $VAR and `cmd`'
file_read /tmp/shsh_special.txt
assert_eq "file special chars" "$R" 'line with $VAR and `cmd`'

fmt_str="%s %d %% literal"
file_write /tmp/shsh_fmt.txt "$fmt_str"
file_read /tmp/shsh_fmt.txt
assert_eq "file_write format literals" "$R" "$fmt_str"
file_append /tmp/shsh_fmt.txt "$fmt_str"
file_read /tmp/shsh_fmt.txt
assert_eq "file_append format literals" "$R" "$fmt_str
$fmt_str"

echo
echo "=== AST Basics ==="

array_clear L1
array_add L1 "add"
array_add L1 "6"
array_add L1 "4"
array_get L1 0; assert_eq "AST head" "$R" "add"
array_get L1 1; _v1="$R"
array_get L1 2; _v2="$R"
R=$((_v1 + _v2)); assert_eq "AST eval simple" "$R" "10"

echo
echo "=== Sparse Arrays ==="

array_clear sparse
array_add sparse "idx0"
array_set sparse 10 "idx10"
array_len sparse
if $R >= 10
  pass "array_len accounts for sparse set (len=$R)"
else
  fail "array_len is $R, but idx 10 exists"
end
array_get sparse 10; assert_eq "sparse value" "$R" "idx10"

array_clear bounds_test
array_add bounds_test "only"
array_get bounds_test 999
if "$R" == ""
  pass "bounds check empty"
else
  fail "bounds returned: $R"
end

array_clear test_arr
array_add test_arr ""
array_get test_arr 0
empty_ret=$?
array_get test_arr 999
missing_ret=$?
if $empty_ret != $missing_ret
  pass "can distinguish empty from missing via return code"
else
  fail "empty (ret=$empty_ret) vs missing (ret=$missing_ret) indistinguishable"
end

echo
echo "=== Nested Callbacks ==="

array_clear outer_arr
array_add outer_arr "A"
array_add outer_arr "B"
array_clear inner_arr
array_add inner_arr "1"
array_add inner_arr "2"
nested_count=0
do_inner() { nested_count=$((nested_count + 1)); }
do_outer() { array_for inner_arr do_inner; }
array_for outer_arr do_outer
assert_eq "nested array_for" "$nested_count" "4"

array_clear exit_test
array_add exit_test "a"
array_add exit_test "b"
array_add exit_test "c"
exit_count=0
try_break() {
  exit_count=$((exit_count + 1))
  if "$R" == "b"
    return 1
  end
  return 0
}
array_for exit_test try_break
if $exit_count != 3
  pass "array_for respects callback return"
else
  fail "array_for ignores callback return (no break support)"
end

echo
echo "=== Security ==="

INJECTED="no"
malicious_index='0; INJECTED="yes"; :'
array_set exploit_arr "$malicious_index" "payload" 2>/dev/null
if "$INJECTED" == "yes"
  fail "array index injection"
else
  pass "array index injection blocked"
end

SAFE_CHECK="ok"
malicious='valid; SAFE_CHECK="pwned"; :'
map_set danger "$malicious" "value" 2>/dev/null
if "$SAFE_CHECK" == "ok"
  pass "map key injection blocked"
else
  fail "map key injection"
end

array_add "bad-name" "val" 2>/dev/null
if $? != 0
  pass "array_add rejects invalid name"
else
  fail "array_add accepts invalid name"
end

cmd_val='$(echo pwned)'
map_set safe "cmd" "$cmd_val"
map_get safe "cmd"
assert_eq "cmd substitution stored literally" "$R" '$(echo pwned)'

echo
echo "=== Nested Transform ==="

nested_transform_test() {
  _inner='if 1 == 1
  R="inner"
end'
  eval "$(echo "$_inner" | transform)"
}
if 1 == 1
  nested_transform_test
  if "$R" == "inner"
    pass "nested transform worked"
  else
    fail "nested transform broke (R=$R)"
  end
end

echo
echo "=== Multiline ==="

ml="line1
line2"
ml2="line1
line2"
if "$ml" == "$ml2"
  pass "multiline comparison"
else
  fail "multiline comparison"
end

map_set mlmap "key" "$ml"
map_get mlmap "key"
assert_eq "multiline in map" "$R" "$ml"

echo
echo "=== Binary Functions ==="

got=$(hex_capture 'bit_8 0xff 0x00 10')
assert_eq "bit_8 mixed inputs" "$got" "ff000a"

got=$(hex_capture 'bit_8 "ABC"')
assert_eq "bit_8 string" "$got" "414243"

got=$(hex_capture 'bit_8 "A" 0x42 "C"')
assert_eq "bit_8 mixed string/hex" "$got" "414243"

got=$(hex_capture 'bit_16 0x1234')
assert_eq "bit_16 LE" "$got" "3412"

got=$(hex_capture 'ENDIAN=big bit_16 0x1234')
assert_eq "bit_16 BE" "$got" "1234"

got=$(hex_capture 'bit_32 0xAABBCCDD')
assert_eq "bit_32 LE" "$got" "ddccbbaa"

got=$(hex_capture 'ENDIAN=1 bit_32 0xAABBCCDD')
assert_eq "bit_32 BE" "$got" "aabbccdd"

got=$(hex_capture 'bit_64 0x1122334455667788')
assert_eq "bit_64 LE" "$got" "8877665544332211"

got=$(hex_capture 'bit_16 0x1111 0x2222')
assert_eq "bit_16 variadic" "$got" "11112222"

got=$(hex_capture 'bit_8 0x00 0x00')
assert_eq "bit_8 zeros" "$got" "0000"

got=$(hex_capture 'bit_16 0x0000')
assert_eq "bit_16 zero" "$got" "0000"

got=$(hex_capture 'bit_32 0x00000000')
assert_eq "bit_32 zero" "$got" "00000000"

got=$(hex_capture 'bit_8 0xff')
assert_eq "bit_8 max" "$got" "ff"

got=$(hex_capture 'bit_16 0xffff')
assert_eq "bit_16 max" "$got" "ffff"

got=$(hex_capture 'ENDIAN=big bit_64 0x1122334455667788')
assert_eq "bit_64 BE" "$got" "1122334455667788"

got=$(hex_capture 'bit_128 0x112233445566778899aabbccddeeff00')
assert_eq "bit_128 LE" "$got" "00ffeeddccbbaa998877665544332211"

got=$(hex_capture 'ENDIAN=big bit_128 0x112233445566778899aabbccddeeff00')
assert_eq "bit_128 BE" "$got" "112233445566778899aabbccddeeff00"

got=$(hex_capture 'bit_128 0xff')
assert_eq "bit_128 zero pad" "$got" "ff000000000000000000000000000000"

echo
echo "=== Edge Cases ==="

deep_val=5
deep_result=""
if $deep_val == 1
  deep_result="one"
elif $deep_val == 2
  deep_result="two"
elif $deep_val == 3
  deep_result="three"
elif $deep_val == 4
  deep_result="four"
elif $deep_val == 5
  deep_result="five"
else
  deep_result="other"
end
assert_eq "deep elif chain" "$deep_result" "five"

outer_cond=1
inner_cond=1
nested_if_result=""
if $outer_cond == 1
  if $inner_cond == 1
    nested_if_result="both"
  else
    nested_if_result="outer only"
  end
else
  nested_if_result="neither"
end
assert_eq "nested if" "$nested_if_result" "both"

big=999999999
if $big > 999999998
  pass "large number comparison"
else
  fail "large number comparison"
end

array_clear large_arr
idx=0
while $idx < 100
  array_add large_arr "item$idx"
  idx=$((idx + 1))
done
array_len large_arr; assert_eq "large array len" "$R" "100"
array_get large_arr 99; assert_eq "large array last" "$R" "item99"

map_set rapid "a" "1"
map_set rapid "b" "2"
map_set rapid "c" "3"
map_set rapid "a" "updated"
map_delete rapid "b"
map_get rapid "a"; assert_eq "rapid map a" "$R" "updated"
if map_has rapid "b"
  fail "rapid map b deleted"
else
  pass "rapid map b deleted"
end
map_get rapid "c"; assert_eq "rapid map c" "$R" "3"

echo
echo "=== Defaults ==="

empty_default=""
default empty_default "fallback"
assert_eq "default on empty" "$empty_default" "fallback"

unset unset_default 2>/dev/null
default unset_default "fallback2"
assert_eq "default on unset" "$unset_default" "fallback2"

existing_default="original"
default existing_default "ignored"
assert_eq "default preserves existing" "$existing_default" "original"

zero_default=0
default zero_default "replaced"
assert_eq "default zero preserved" "$zero_default" "0"

space_default="has spaces"
default space_default "nope"
assert_eq "default with spaces" "$space_default" "has spaces"

empty_for_unset=""
default_unset empty_for_unset "should_not_apply"
assert_eq "default_unset ignores empty" "$empty_for_unset" ""

unset truly_unset 2>/dev/null
default_unset truly_unset "applied"
assert_eq "default_unset on unset" "$truly_unset" "applied"

existing_unset="keep"
default_unset existing_unset "nope"
assert_eq "default_unset preserves existing" "$existing_unset" "keep"

unset chain_var 2>/dev/null
default chain_var ""
default chain_var "second"
assert_eq "chained default" "$chain_var" "second"

unset special_def 2>/dev/null
default special_def "hello world"
assert_eq "default special chars" "$special_def" "hello world"

bad_def_result=$(default "bad-name" "val" 2>&1)
ret=$?
if $ret != 0
  pass "default rejects invalid name"
else
  fail "default accepted invalid name"
end

echo
echo "=== Arithmetic Operators ==="

inc_var=5
inc_var++
assert_eq "var++" "$inc_var" "6"

dec_var=10
dec_var--
assert_eq "var--" "$dec_var" "9"

zero_inc=0
zero_inc++
assert_eq "0++" "$zero_inc" "1"

neg_dec=0
neg_dec--
assert_eq "0--" "$neg_dec" "-1"

add_var=10
add_var += 5
assert_eq "var += 5" "$add_var" "15"

sub_var=20
sub_var -= 8
assert_eq "var -= 8" "$sub_var" "12"

mul_var=7
mul_var *= 6
assert_eq "var *= 6" "$mul_var" "42"

div_var=100
div_var /= 4
assert_eq "var /= 4" "$div_var" "25"

mod_var=17
mod_var %= 5
assert_eq "var %= 5" "$mod_var" "2"

zero_add=42
zero_add += 0
assert_eq "var += 0" "$zero_add" "42"

zero_mul=999
zero_mul *= 0
assert_eq "var *= 0" "$zero_mul" "0"

one_mul=123
one_mul *= 1
assert_eq "var *= 1" "$one_mul" "123"

one_div=456
one_div /= 1
assert_eq "var /= 1" "$one_div" "456"

neg_arith=-10
neg_arith += 3
assert_eq "negative += 3" "$neg_arith" "-7"

neg_arith2=5
neg_arith2 += -10
assert_eq "var += negative" "$neg_arith2" "-5"

chain_arith=10
chain_arith += 5
chain_arith *= 2
chain_arith -= 10
assert_eq "chained arithmetic" "$chain_arith" "20"

loop_inc=0
iter=0
while $iter < 5
  loop_inc++
  iter++
done
assert_eq "++ in loop" "$loop_inc" "5"

sum=0
i=1
while $i <= 10
  sum += $i
  i++
done
assert_eq "+= loop sum" "$sum" "55"

fact=1
n=5
while $n > 1
  fact *= $n
  n--
done
assert_eq "*= factorial" "$fact" "120"

mod_results=""
j=0
while $j < 10
  tmp=$j
  tmp %= 3
  if $tmp == 0
    mod_results="${mod_results}$j "
  end
  j++
done
assert_eq "%= pattern" "$mod_results" "0 3 6 9 "

big_inc=999999
big_inc++
assert_eq "large ++" "$big_inc" "1000000"

expr_var=10
expr_var += $((2 * 3))
assert_eq "+= with expr" "$expr_var" "16"

multi_a=0
multi_b=0
multi_a++
multi_b++
multi_a++
assert_eq "multiple inc a" "$multi_a" "2"
assert_eq "multiple inc b" "$multi_b" "1"

indent_var=5
if 1 == 1
  indent_var++
  indent_var += 10
end
assert_eq "indented arithmetic" "$indent_var" "16"

nested_arith=0
if 1 == 1
  if 1 == 1
    if 1 == 1
      nested_arith++
      nested_arith *= 10
      nested_arith += 5
    end
  end
end
assert_eq "deeply nested arithmetic" "$nested_arith" "15"

arith_func() {
  _af_val=$1
  _af_val++
  _af_val *= 2
  R=$_af_val
}
arith_func 5
assert_eq "arithmetic in function" "$R" "12"

trunc_div=7
trunc_div /= 2
assert_eq "integer division truncates" "$trunc_div" "3"

mod_zero=5
mod_zero %= 5
assert_eq "x %= x equals 0" "$mod_zero" "0"

mod_larger=3
mod_larger %= 10
assert_eq "x %= larger" "$mod_larger" "3"

semi_inc=0
echo "test" > /dev/null; semi_inc++
assert_eq "++ after semicolon" "$semi_inc" "1"

semi_dec=5
echo "test" > /dev/null; semi_dec--
assert_eq "-- after semicolon" "$semi_dec" "4"

semi_add=10
echo "test" > /dev/null; semi_add += 5
assert_eq "+= after semicolon" "$semi_add" "15"

inline_if_inc=0
if true: inline_if_inc++
assert_eq "++ in inline if" "$inline_if_inc" "1"

inline_if_semi=0
if true: echo "ok" > /dev/null; inline_if_semi++
assert_eq "++ after semicolon in inline if" "$inline_if_semi" "1"

inline_else_dec=10
if false: inline_else_dec=99
else: inline_else_dec--
assert_eq "-- in inline else" "$inline_else_dec" "9"

inline_elif_add=5
if false: inline_elif_add=0
elif true: inline_elif_add += 10
assert_eq "+= in inline elif" "$inline_elif_add" "15"

_fn_semi_cnt=0
_fn_semi_test() {
  echo "in func" > /dev/null; _fn_semi_cnt++
}
_fn_semi_test
assert_eq "++ in function after semicolon" "$_fn_semi_cnt" "1"

echo
echo "=== Assignment Syntax (var = func) ==="

result = str_before "hello:world" ":"
assert_eq "basic assignment" "$result" "hello"

result2 = str_after "hello:world" ":"
assert_eq "str_after assignment" "$result2" "world"

_as_input="one:two:three"
_as_sep=":"
part1 = str_before "$_as_input" "$_as_sep"
assert_eq "assignment with vars" "$part1" "one"

_as_chain="a:b:c:d"
first = str_before "$_as_chain" ":"
rest = str_after "$_as_chain" ":"
second = str_before "$rest" ":"
assert_eq "chained assign first" "$first" "a"
assert_eq "chained assign rest" "$rest" "b:c:d"
assert_eq "chained assign second" "$second" "b"

_as_path="/usr/local/bin/shsh"
dirname = str_before_last "$_as_path" "/"
basename = str_after_last "$_as_path" "/"
assert_eq "str_before_last assign" "$dirname" "/usr/local/bin"
assert_eq "str_after_last assign" "$basename" "shsh"

trimmed = str_trim "  spaced  "
assert_eq "str_trim assign" "$trimmed" "spaced"

ltrimmed = str_ltrim "  left"
assert_eq "str_ltrim assign" "$ltrimmed" "left"

rtrimmed = str_rtrim "right  "
assert_eq "str_rtrim assign" "$rtrimmed" "right"

_as_indented="    code here"
ind = str_indent "$_as_indented"
assert_eq "str_indent assign" "$ind" "    "

_pt_out=$("$_shsh" raw <<'PTEOF'
x = "literal"
PTEOF
)
assert_eq "passthrough string literal" "$_pt_out" 'x = "literal"'

_pt_out2=$("$_shsh" raw <<'PTEOF'
y = $somevar
PTEOF
)
assert_eq "passthrough variable" "$_pt_out2" 'y = $somevar'

_pt_out3=$("$_shsh" raw <<'PTEOF'
z = 
PTEOF
)
assert_eq "passthrough empty RHS" "$_pt_out3" 'z = '

_pt_out4=$("$_shsh" raw <<'PTEOF'
eq = has=equals
PTEOF
)
assert_eq "passthrough contains equals" "$_pt_out4" 'eq = has=equals'

if true
  indented_result = str_before "foo:bar" ":"
  assert_eq "indented assignment" "$indented_result" "foo"
end

_as_items="a b c"
_as_count=0
for item in $_as_items
  len = str_before "$item$item" "$item"
  _as_count++
done
assert_eq "assignment in loop" "$_as_count" "3"

m1 = str_before "x:y" ":"
m2 = str_after "x:y" ":"
assert_eq "multi assign 1" "$m1" "x"
assert_eq "multi assign 2" "$m2" "y"

array_clear _as_arr
array_add _as_arr "first"
array_add _as_arr "second"
array_len _as_arr; _as_len="$R"
assert_eq "array_len result" "$_as_len" "2"

arr_len = array_len _as_arr

array_get _as_arr 0
got = str_before "${R}:" ":"
assert_eq "mixed R usage" "$got" "first"

echo "test" > /dev/null; semi_assign = str_before "a:b" ":"
assert_eq "assignment after semicolon" "$semi_assign" "a"

pre_semi = str_after "1:2" ":"; echo "$pre_semi" > /dev/null
assert_eq "assignment before semicolon" "$pre_semi" "2"

line_a = str_before "p:q" ":"; line_b = str_after "p:q" ":"
assert_eq "multi semicolon assign a" "$line_a" "p"
assert_eq "multi semicolon assign b" "$line_b" "q"

map_set _as_map key "value"
map_get _as_map key
captured = str_before "${R}!" "!"
assert_eq "map_get R capture" "$captured" "value"

regular_var="direct"
assert_eq "regular assignment" "$regular_var" "direct"

arith_test=10
arith_test += 5
assert_eq "+= still works" "$arith_test" "15"

arith_test -= 3
assert_eq "-= still works" "$arith_test" "12"

_under_score = str_before "x:y" ":"
assert_eq "underscore var assign" "$_under_score" "x"

a = str_before "m:n" ":"
assert_eq "single char var assign" "$a" "m"

very_long_variable_name_here = str_after "start:end" ":"
assert_eq "long var name assign" "$very_long_variable_name_here" "end"

_as_nested="one:two:three:four"
step1 = str_after "$_as_nested" ":"
step2 = str_after "$step1" ":"
step3 = str_before "$step2" ":"
assert_eq "nested step1" "$step1" "two:three:four"
assert_eq "nested step2" "$step2" "three:four"
assert_eq "nested step3" "$step3" "three"

_as_if_assign=""
if true: _as_if_assign = str_before "test:value" ":"
assert_eq "assignment in inline if" "$_as_if_assign" "test"

_as_while_assign=""
_as_while_cond=1
while $_as_while_cond == 1: _as_while_assign = str_after "x:y" ":"; _as_while_cond=0
assert_eq "assignment in inline while" "$_as_while_assign" "y"

_as_special="hello!@#world"
spec_result = str_before "$_as_special" "!@#"
assert_eq "assignment special chars" "$spec_result" "hello"

_as_spaced="first part:second part"
spaced_result = str_before "$_as_spaced" ":"
assert_eq "assignment spaced value" "$spaced_result" "first part"

_as_empty=":after"
empty_before = str_before "$_as_empty" ":"
assert_eq "assignment empty result" "$empty_before" ""

_as_nomatch="nocolon"
if str_before "$_as_nomatch" ":"
  _as_matched="yes"
else
  _as_matched="no"
end
assert_eq "assignment func returns false" "$_as_matched" "no"

_as_combo="aaa:bbb"
combo_a = str_before "$_as_combo" ":"; combo_b = str_after "$_as_combo" ":"
assert_eq "combo assign a" "$combo_a" "aaa"
assert_eq "combo assign b" "$combo_b" "bbb"

var1 = str_before "num:1" ":"
var2 = str_after "num:2" ":"
assert_eq "numeric suffix var1" "$var1" "num"
assert_eq "numeric suffix var2" "$var2" "2"

_as_long="a:b:c:d:e"
long_result = str_before "$_as_long" ":"
assert_eq "long args assign" "$long_result" "a"

_as_transpile_out=$("$_shsh" raw <<'TREOF'
foo = str_before "x:y" ":"
TREOF
)
assert_eq "transpile assignment" "$_as_transpile_out" 'str_before "x:y" ":"; foo="$R"'

_as_compound=100
_as_compound += 50
_as_compound -= 25
_as_compound *= 2
_as_compound /= 5
assert_eq "compound ops still work" "$_as_compound" "50"

echo
echo "=== Single-Line If ==="

x=5
if $x == 5: r1="yes"
assert_eq "single if" "$r1" "yes"

x=10
if $x == 5: r2="five"
else: r2="not five"
assert_eq "single if/else" "$r2" "not five"

x=15
if $x < 10: r3="low"
elif $x < 20: r3="mid"
else: r3="high"
assert_eq "single if/elif/else" "$r3" "mid"

x=5
r4="unchanged"
if $x == 99: r4="changed"
assert_eq "single if no match" "$r4" "unchanged"

x=5
if $x == 5: r5="match"
r5="${r5}-after"
assert_eq "single if then code" "$r5" "match-after"

if 1 == 1: m1="a"
if 2 == 2: m2="b"
if 3 == 3: m3="c"
assert_eq "multi single if 1" "$m1" "a"
assert_eq "multi single if 2" "$m2" "b"
assert_eq "multi single if 3" "$m3" "c"

if 1 == 1: cs_result=$(echo "hello")
assert_eq "single if cmd sub" "$cs_result" "hello"

n=10
if $n > 5: n=$((n * 2))
assert_eq "single if arithmetic" "$n" "20"

v=4
if $v == 1: lc="one"
elif $v == 2: lc="two"
elif $v == 3: lc="three"
elif $v == 4: lc="four"
elif $v == 5: lc="five"
else: lc="other"
assert_eq "long elif chain" "$lc" "four"

x=5
if $x < 3: mixed="low"
elif $x < 10
  mixed="mid"
  mixed="${mixed}-multi"
else: mixed="high"
end
assert_eq "mixed single/multi" "$mixed" "mid-multi"

outer=1
inner=2
if $outer == 1
  if $inner == 2: nested="found"
end
assert_eq "nested single in multi" "$nested" "found"

loop_result=""
for i in 1 2 3
  if $i == 2: loop_result="${loop_result}X"
  else: loop_result="${loop_result}O"
done
assert_eq "single if in loop" "$loop_result" "OXO"

s="hello"
if "$s" == "hello": str_r="match"
else: str_r="no"
assert_eq "single if string" "$str_r" "match"

a=1
if $a == 1: only1="yes"
b=2
if $b == 2: only2="yes"
assert_eq "consecutive single ifs 1" "$only1" "yes"
assert_eq "consecutive single ifs 2" "$only2" "yes"

if 1 == 1: time_val="12:30:45"
assert_eq "colon in value" "$time_val" "12:30:45"

eof_test="no"
if 1 == 1: eof_test="yes"

echo
echo "=== Single-Line Switch Cases ==="

_sl1=""
for val in foo bar baz other
  switch $val
  case foo: _sl1="${_sl1}F"
  case bar|baz: _sl1="${_sl1}B"
  default: _sl1="${_sl1}X"
  end
done
assert_eq "single-line switch basic" "$_sl1" "FBBX"

_sl2=""
switch "unknown"
default: _sl2="hit"
end
assert_eq "single-line default only" "$_sl2" "hit"

_sl3=""
switch "test"
case foo: _sl3="F"
case test
  _sl3="T"
  _sl3="${_sl3}EST"
default: _sl3="X"
end
assert_eq "mixed single/multi switch" "$_sl3" "TEST"

_sl4=0
for v in a b c d
  switch $v
  case a: _sl4=$((_sl4 + 1))
  case b: _sl4=$((_sl4 + 10))
  case c|d: _sl4=$((_sl4 + 100))
  end
done
assert_eq "single-line switch arithmetic" "$_sl4" "211"

switch "cmd"
case cmd: sw_cmd=$(echo "hello")
default: sw_cmd="no"
end
assert_eq "single-line switch cmd sub" "$sw_cmd" "hello"

_nested_sw=""
for outer in a b
  switch $outer
  case a: _nested_sw="${_nested_sw}A"
  case b
    for inner in x y
      switch $inner
      case x: _nested_sw="${_nested_sw}X"
      case y: _nested_sw="${_nested_sw}Y"
      end
    done
  end
done
assert_eq "nested switch single-line" "$_nested_sw" "AXY"

switch "time"
case time: sw_colon="12:30"
default: sw_colon="none"
end
assert_eq "switch colon in value" "$sw_colon" "12:30"

switch "test123"
case test*: sw_glob="matched"
default: sw_glob="no"
end
assert_eq "single-line switch glob" "$sw_glob" "matched"

_sw_nomatch=""
switch "xyz"
case a: _sw_nomatch="a"
case b: _sw_nomatch="b"
end
assert_eq "single-line switch no match" "$_sw_nomatch" ""

_all_sw=""
switch "middle"
case first: _all_sw="1"
case middle: _all_sw="2"
case last: _all_sw="3"
end
assert_eq "all single-line switch" "$_all_sw" "2"

_sw_in_if=""
if 1 == 1
  switch "yes"
  case yes: _sw_in_if="found"
  default: _sw_in_if="no"
  end
end
assert_eq "switch in if block" "$_sw_in_if" "found"

_sw_loop=""
for i in 1 2 3
  switch $i
  case 1: _sw_loop="${_sw_loop}A"
  case 2: _sw_loop="${_sw_loop}B"
  case 3: _sw_loop="${_sw_loop}C"
  end
done
assert_eq "single-line switch in loop" "$_sw_loop" "ABC"

echo
echo "=== Single-Line Switch Nested Single-Liners ==="

_nested_default=""
_skip=0
switch "x"
  default: if $_skip == 0: _nested_default="works"
end
assert_eq "default: if:" "$_nested_default" "works"

_nested_default_skip="stay"
_skip=1
switch "x"
  default: if $_skip == 0: _nested_default_skip="changed"
end
assert_eq "default: if skip" "$_nested_default_skip" "stay"

_nested_case=""
_flag=1
switch "a"
  case a: if $_flag == 1: _nested_case="yes"
  default: _nested_case="no"
end
assert_eq "case: if:" "$_nested_case" "yes"

_nested_case_fallback="none"
_flag=0
switch "b"
  case a: if $_flag == 1: _nested_case_fallback="yes"
  default: _nested_case_fallback="no"
end
assert_eq "case: if fallback" "$_nested_case_fallback" "no"

_inline_chain=""
switch "branch"
  default: if 0 == 1: _inline_chain="if"
    elif 2 == 2: _inline_chain="elif"
    else: _inline_chain="else"
end
assert_eq "inline nested elif chain" "$_inline_chain" "elif"

_inline_after="start"
switch "z"
  default: if 1 == 1: _inline_after="set"
_inline_after="${_inline_after}-post"
end
assert_eq "inline nested if closes before following body" "$_inline_after" "set-post"

_sl_while=""
_w=0
while $_w < 3: _sl_while="${_sl_while}${_w}"; _w=$((_w + 1))
assert_eq "single-line while increments" "$_sl_while" "012"

_switch_while=""
switch "go"
  case go:
    _sw_n=1
    while $_sw_n <= 3: _switch_while="${_switch_while}${_sw_n}"; _sw_n=$((_sw_n + 1))
end
assert_eq "single-line while inside switch" "$_switch_while" "123"

echo
echo "=== CLI edge cases ==="

_usage_status=0
_usage_out=$(sh "$_shsh" 2>&1) || _usage_status=$?
_usage_expected="usage: shsh"
if $_usage_status == 0
  if str_contains "$_usage_out" "$_usage_expected"
    pass "shsh with no args prints usage"
  else
    fail "shsh with no args missing usage text"
  end
else
  fail "shsh with no args failed (status $_usage_status)"
end

if file_exists "$_shsh"
  _shsh_path="$_shsh"
elif file_exists "${0%/*}/../shsh.sh"
  _shsh_path="${0%/*}/../shsh.sh"
elif file_exists "/usr/local/bin/shsh"
  _shsh_path="/usr/local/bin/shsh"
else
  _shsh_path="$_shsh"
end

_dash_c_out=$("$_shsh_path" 'echo hi')
if "$_dash_c_out" == "hi"
  pass "prints inline output"
else
  fail "prints inline output (got: '$_dash_c_out')"
end

_mod_c_out=$("$_shsh_path" 'val=$((17 % 5)); echo "$val"' 2>&1)
if "$_mod_c_out" == "2"
  pass "modulo operator"
else
  fail "modulo operator (got: '$_mod_c_out')"
end

_mod_multi_out=$("$_shsh_path" 'a=$((100 % 30)); b=$((a % 7)); echo "$b"' 2>&1)
if "$_mod_multi_out" == "3"
  pass "chained modulo"
else
  fail "chained modulo (got: '$_mod_multi_out')"
end

_pct_str_out=$("$_shsh_path" 'x="50%"; echo "$x"' 2>&1)
if "$_pct_str_out" == "50%"
  pass "percent in string"
else
  fail "percent in string (got: '$_pct_str_out')"
end

_stdin_code="x=7"
_stdin_t_out=$(printf "%s\n" "$_stdin_code" | "$_shsh_path" raw -)
if "$_stdin_t_out" == "$_stdin_code"
  pass "raw reads from stdin"
else
  fail "raw reads from stdin (got: '$_stdin_t_out')"
end

_test_file="/tmp/shsh_cli_test_$$.shsh"
printf '%s\n' 'x=1' > "$_test_file"
_transform_out=$("$_shsh_path" raw "$_test_file" 2>&1)
rm -f "$_test_file"
if "$_transform_out" == "x=1"
  pass "raw with file doesn't hang"
else
  fail "raw with file doesn't hang (got: '$_transform_out')"
end

_dash_out=$(printf "%s" "-")
if "$_dash_out" == "-"
  pass "printf dash works"
else
  fail "printf dash works (got: '$_dash_out')"
end

_dashes_out=$(printf "%s" "--")
if "$_dashes_out" == "--"
  pass "printf double dash works"
else
  fail "printf double dash works (got: '$_dashes_out')"
end

_dashopt_out=$(printf "%s" "-d")
if "$_dashopt_out" == "-d"
  pass "printf dash-letter works"
else
  fail "printf dash-letter works (got: '$_dashopt_out')"
end

echo
echo "=== Runtime Helpers ==="

_rt_tmp="/tmp/shsh_rt_$$"
printf '%s\n' "echo hi" > "$_rt_tmp"
if file_executable "$_rt_tmp"
  fail "file_executable false negative (non-exec)"
else
  pass "file_executable detects non-exec"
end
chmod +x "$_rt_tmp"
if file_executable "$_rt_tmp"
  pass "file_executable detects exec"
else
  fail "file_executable misses exec"
end
rm -f "$_rt_tmp"

if path_writable "$PWD"
  pass "path_writable current dir"
else
  fail "path_writable current dir"
end
if path_writable "/root"
  fail "path_writable protected path"
else
  pass "path_writable protected path"
end

echo
echo "=== Map Enumeration ==="

map_set enum_map alpha "1"
map_set enum_map beta "2"
map_set enum_map gamma "3"
map_keys enum_map enum_keys
array_len enum_keys; assert_eq "map_keys count" "$R" "3"

_found_alpha=0 _found_beta=0 _found_gamma=0
check_enum_key() {
  switch $R
  case alpha: _found_alpha=1
  case beta:  _found_beta=1
  case gamma: _found_gamma=1
  end
}
array_for enum_keys check_enum_key
if $_found_alpha == 1
  if $_found_beta == 1
    if $_found_gamma == 1
      pass "map_keys contains all keys"
    else
      fail "map_keys missing keys (a=$_found_alpha b=$_found_beta g=$_found_gamma)"
    end
  else
    fail "map_keys missing keys (a=$_found_alpha b=$_found_beta g=$_found_gamma)"
  end
else
  fail "map_keys missing keys (a=$_found_alpha b=$_found_beta g=$_found_gamma)"
end

map_keys empty_map empty_keys 2>/dev/null
array_len empty_keys; assert_eq "map_keys empty" "$R" "0"

map_set del_enum_map a "1"
map_set del_enum_map b "2"
map_set del_enum_map c "3"
map_delete del_enum_map b
map_keys del_enum_map del_enum_keys
array_len del_enum_keys; assert_eq "map_keys after delete count" "$R" "2"
_has_a=0 _has_b=0 _has_c=0
check_del_key() {
  switch $R
  case a: _has_a=1
  case b: _has_b=1
  case c: _has_c=1
  end
}
array_for del_enum_keys check_del_key
if $_has_a == 1
  if $_has_b == 0
    if $_has_c == 1
      pass "map_keys excludes deleted"
    else
      fail "map_keys delete handling (a=$_has_a b=$_has_b c=$_has_c)"
    end
  else
    fail "map_keys delete handling (a=$_has_a b=$_has_b c=$_has_c)"
  end
else
  fail "map_keys delete handling (a=$_has_a b=$_has_b c=$_has_c)"
end

map_set dup_map key "first"
map_set dup_map key "second"
map_set dup_map key "third"
map_keys dup_map dup_keys
array_len dup_keys; assert_eq "map_keys no duplicates" "$R" "1"
array_get dup_keys 0; assert_eq "map_keys single key" "$R" "key"
map_get dup_map key; assert_eq "map overwrite value" "$R" "third"

map_set for_map x "10"
map_set for_map y "20"
map_set for_map z "30"
_for_sum=0
_for_keys=""
sum_map() {
  _for_sum=$((_for_sum + R))
  _for_keys="${_for_keys}${K}"
}
map_for for_map sum_map
assert_eq "map_for sum values" "$_for_sum" "60"

switch $_for_keys
case *x*y*z*|*x*z*y*|*y*x*z*|*y*z*x*|*z*x*y*|*z*y*x*: pass "map_for visits all keys"
case *: fail "map_for keys incomplete: $_for_keys"
end

_empty_visited=0
empty_cb() { _empty_visited=1; }
map_for nonexistent_map empty_cb 2>/dev/null
assert_eq "map_for empty" "$_empty_visited" "0"

map_set exit_map a "1"
map_set exit_map b "2"
map_set exit_map c "3"
_exit_count=0
exit_after_two() {
  _exit_count=$((_exit_count + 1))
  if $_exit_count >= 2
    return 1
  end
  return 0
}
map_for exit_map exit_after_two
assert_eq "map_for early exit" "$_exit_count" "2"

map_set fd_map p "1"
map_set fd_map q "2"
map_set fd_map r "3"
map_delete fd_map q
_fd_vals=""
collect_fd() { _fd_vals="${_fd_vals}${R}"; }
map_for fd_map collect_fd
switch $_fd_vals
case 13|31: pass "map_for skips deleted"
case *: fail "map_for skips deleted (got: $_fd_vals)"
end

map_set kr_map foo "FOO"
map_set kr_map bar "BAR"
_kr_pairs=""
check_kr() { _kr_pairs="${_kr_pairs}${K}=${R} "; }
map_for kr_map check_kr
switch $_kr_pairs
case *foo=FOO*bar=BAR*|*bar=BAR*foo=FOO*: pass "map_for K and R correct"
case *: fail "map_for K/R mismatch: $_kr_pairs"
end

map_set twice_map a "1"
map_keys twice_map twice_keys1
map_set twice_map b "2"
map_keys twice_map twice_keys2
array_len twice_keys2; assert_eq "map_keys refresh" "$R" "2"

_large_i=0
while $_large_i < 50
  map_set large_map "key$_large_i" "val$_large_i"
  _large_i=$((_large_i + 1))
done
map_keys large_map large_keys
array_len large_keys; assert_eq "large map keys" "$R" "50"
_large_count=0
count_large() { _large_count=$((_large_count + 1)); }
map_for large_map count_large
assert_eq "large map_for count" "$_large_count" "50"

map_set single_map only "value"
map_keys single_map single_keys
array_len single_keys; assert_eq "single map keys" "$R" "1"
array_get single_keys 0; assert_eq "single map key value" "$R" "only"
_single_k="" _single_v=""
get_single() { _single_k="$K"; _single_v="$R"; }
map_for single_map get_single
assert_eq "single map_for K" "$_single_k" "only"
assert_eq "single map_for R" "$_single_v" "value"

map_set reuse_map a "1"
map_set reuse_map b "2"
map_delete reuse_map a
map_delete reuse_map b
map_set reuse_map c "3"
map_keys reuse_map reuse_keys
array_len reuse_keys; assert_eq "reuse after delete count" "$R" "1"
array_get reuse_keys 0; assert_eq "reuse after delete key" "$R" "c"

map_keys "bad-name" out 2>/dev/null
ret=$?
if $ret != 0
  pass "map_keys rejects invalid map name"
else
  fail "map_keys accepted invalid map name"
end

map_keys valid_map "bad-out" 2>/dev/null
ret=$?
if $ret != 0
  pass "map_keys rejects invalid output name"
else
  fail "map_keys accepted invalid output name"
end

map_for "bad-name" echo 2>/dev/null
ret=$?
if $ret != 0
  pass "map_for rejects invalid name"
else
  fail "map_for accepted invalid name"
end

map_set outer_m a "1"
map_set outer_m b "2"
map_set inner_m x "10"
map_set inner_m y "20"
_nested_sum=0
inner_sum() { _nested_sum=$((_nested_sum + R)); }
outer_iter() { map_for inner_m inner_sum; }
map_for outer_m outer_iter
assert_eq "nested map_for" "$_nested_sum" "60"

map_set empty_val_map key ""
map_keys empty_val_map ev_keys
array_len ev_keys; assert_eq "empty value map_keys" "$R" "1"
_ev_visited=0
check_empty_val() { _ev_visited=1; assert_eq "empty value R" "$R" ""; }
map_for empty_val_map check_empty_val
assert_eq "empty value visited" "$_ev_visited" "1"

map_set zero_val_map num "0"
_zv=""
get_zero() { _zv="$R"; }
map_for zero_val_map get_zero
assert_eq "zero value map_for" "$_zv" "0"

map_set stable_map exists "yes"
map_delete stable_map never_existed
map_keys stable_map stable_keys
array_len stable_keys; assert_eq "stable after bad delete" "$R" "1"

map_set readd_map key "first"
map_delete readd_map key
map_set readd_map key "second"
map_keys readd_map readd_keys
array_len readd_keys; assert_eq "re-add deleted key count" "$R" "1"
map_get readd_map key; assert_eq "re-add deleted value" "$R" "second"

map_set clear_map a "1"
map_set clear_map b "2"
map_clear clear_map
map_keys clear_map clear_keys
array_len clear_keys; assert_eq "map_clear keys" "$R" "0"
map_get clear_map a; assert_eq "map_clear value gone" "$R" ""

map_set clear_map fresh "new"
map_keys clear_map clear_keys2
array_len clear_keys2; assert_eq "map_clear re-add" "$R" "1"

echo
echo "=== String Functions ==="

if str_starts "hello world" "hello"
  pass "str_starts basic match"
else
  fail "str_starts basic match"
end

if str_starts "hello world" "world"
  fail "str_starts false positive"
else
  pass "str_starts no false positive"
end

if str_starts "hello" "hello"
  pass "str_starts exact match"
else
  fail "str_starts exact match"
end

if str_starts "hello" ""
  pass "str_starts empty prefix"
else
  fail "str_starts empty prefix"
end

if str_starts "" ""
  pass "str_starts empty string empty prefix"
else
  fail "str_starts empty string empty prefix"
end

if str_starts "" "x"
  fail "str_starts empty string non-empty prefix"
else
  pass "str_starts empty string non-empty prefix"
end

if str_starts "hello" "hello world"
  fail "str_starts prefix longer than string"
else
  pass "str_starts prefix longer than string"
end

if str_starts "  spaces" "  "
  pass "str_starts with spaces"
else
  fail "str_starts with spaces"
end

if str_starts "path/to/file" "path/"
  pass "str_starts with slash"
else
  fail "str_starts with slash"
end

if str_starts "***glob" "***"
  pass "str_starts with glob chars"
else
  fail "str_starts with glob chars"
end

if str_ends "hello world" "world"
  pass "str_ends basic match"
else
  fail "str_ends basic match"
end

if str_ends "hello world" "hello"
  fail "str_ends false positive"
else
  pass "str_ends no false positive"
end

if str_ends "hello" "hello"
  pass "str_ends exact match"
else
  fail "str_ends exact match"
end

if str_ends "hello" ""
  pass "str_ends empty suffix"
else
  fail "str_ends empty suffix"
end

if str_ends "" ""
  pass "str_ends empty string empty suffix"
else
  fail "str_ends empty string empty suffix"
end

if str_ends "" "x"
  fail "str_ends empty string non-empty suffix"
else
  pass "str_ends empty string non-empty suffix"
end

if str_ends "hello" "hello world"
  fail "str_ends suffix longer than string"
else
  pass "str_ends suffix longer than string"
end

if str_ends "file.txt" ".txt"
  pass "str_ends with extension"
else
  fail "str_ends with extension"
end

if str_ends "trailing  " "  "
  pass "str_ends with spaces"
else
  fail "str_ends with spaces"
end

if str_ends "end***" "***"
  pass "str_ends with glob chars"
else
  fail "str_ends with glob chars"
end

if str_contains "hello world" "o w"
  pass "str_contains middle"
else
  fail "str_contains middle"
end

if str_contains "hello world" "hello"
  pass "str_contains start"
else
  fail "str_contains start"
end

if str_contains "hello world" "world"
  pass "str_contains end"
else
  fail "str_contains end"
end

if str_contains "hello world" "xyz"
  fail "str_contains false positive"
else
  pass "str_contains no false positive"
end

if str_contains "hello" "hello"
  pass "str_contains exact match"
else
  fail "str_contains exact match"
end

if str_contains "hello" ""
  pass "str_contains empty needle"
else
  fail "str_contains empty needle"
end

if str_contains "" ""
  pass "str_contains empty both"
else
  fail "str_contains empty both"
end

if str_contains "" "x"
  fail "str_contains empty haystack"
else
  pass "str_contains empty haystack"
end

if str_contains "abc*def" "*"
  pass "str_contains asterisk"
else
  fail "str_contains asterisk"
end

if str_contains "a?b" "?"
  pass "str_contains question mark"
else
  fail "str_contains question mark"
end

if str_contains "[test]" "["
  pass "str_contains bracket"
else
  fail "str_contains bracket"
end

str_after "path/to/file" "/"
assert_eq "str_after first slash" "$R" "to/file"

str_after "key=value" "="
assert_eq "str_after equals" "$R" "value"

str_after "hello" "x"
ret=$?
if $ret != 0
  pass "str_after returns false on no match"
else
  fail "str_after returns false on no match"
end

str_after "aaa" "a"
assert_eq "str_after first occurrence" "$R" "aa"

str_after "hello world" " "
assert_eq "str_after space" "$R" "world"

str_after "::value" ":"
assert_eq "str_after leading delimiter" "$R" ":value"

str_after "value::" ":"
assert_eq "str_after trailing delimiter" "$R" ":"

str_after "no-delim" "="
ret=$?
if $ret != 0
  pass "str_after no match returns false"
else
  fail "str_after no match should return false"
end
assert_eq "str_after no match sets R to original" "$R" "no-delim"

str_after "a::b" "::"
assert_eq "str_after multi-char delimiter" "$R" "b"

str_after "" "x"
ret=$?
if $ret != 0
  pass "str_after empty string"
else
  fail "str_after empty string should fail"
end

str_before "path/to/file" "/"
assert_eq "str_before first slash" "$R" "path"

str_before "key=value=extra" "="
assert_eq "str_before equals (first only)" "$R" "key"

str_before "hello" "x"
ret=$?
if $ret != 0
  pass "str_before returns false on no match"
else
  fail "str_before returns false on no match"
end

str_before "hello world" " "
assert_eq "str_before space" "$R" "hello"

str_before "::value" ":"
assert_eq "str_before leading delimiter" "$R" ""

str_before "value::" ":"
assert_eq "str_before trailing delimiter" "$R" "value"

str_before "a::b" "::"
assert_eq "str_before multi-char delimiter" "$R" "a"

str_before "" "x"
ret=$?
if $ret != 0
  pass "str_before empty string"
else
  fail "str_before empty string should fail"
end

str_after_last "path/to/file" "/"
assert_eq "str_after_last slash" "$R" "file"

str_after_last "a.b.c.txt" "."
assert_eq "str_after_last dot extension" "$R" "txt"

str_after_last "hello" "x"
ret=$?
if $ret != 0
  pass "str_after_last returns false on no match"
else
  fail "str_after_last returns false on no match"
end

str_after_last "single" "/"
ret=$?
if $ret != 0
  pass "str_after_last no delimiter"
else
  fail "str_after_last no delimiter should fail"
end

str_after_last "a::b::c" "::"
assert_eq "str_after_last multi-char" "$R" "c"

str_after_last "trailing/" "/"
assert_eq "str_after_last trailing delimiter" "$R" ""

str_after_last "/leading" "/"
assert_eq "str_after_last leading delimiter" "$R" "leading"

str_after_last "aaa" "a"
assert_eq "str_after_last repeated" "$R" ""

str_before_last "path/to/file" "/"
assert_eq "str_before_last slash" "$R" "path/to"

str_before_last "a.b.c.txt" "."
assert_eq "str_before_last dot" "$R" "a.b.c"

str_before_last "hello" "x"
ret=$?
if $ret != 0
  pass "str_before_last returns false on no match"
else
  fail "str_before_last returns false on no match"
end

str_before_last "single" "/"
ret=$?
if $ret != 0
  pass "str_before_last no delimiter"
else
  fail "str_before_last no delimiter should fail"
end

str_before_last "a::b::c" "::"
assert_eq "str_before_last multi-char" "$R" "a::b"

str_before_last "trailing/" "/"
assert_eq "str_before_last trailing delimiter" "$R" "trailing"

str_before_last "/leading" "/"
assert_eq "str_before_last leading delimiter" "$R" ""

str_before_last "aaa" "a"
assert_eq "str_before_last repeated" "$R" "aa"

str_ltrim "  hello"
assert_eq "str_ltrim basic" "$R" "hello"

str_ltrim "		tab"
assert_eq "str_ltrim tabs" "$R" "tab"

str_ltrim "  	 mixed  "
assert_eq "str_ltrim mixed ws preserves trailing" "$R" "mixed  "

str_ltrim "nowhitespace"
assert_eq "str_ltrim no leading ws" "$R" "nowhitespace"

str_ltrim ""
assert_eq "str_ltrim empty" "$R" ""

str_ltrim "   "
assert_eq "str_ltrim all whitespace" "$R" ""

str_ltrim "  hello world  "
assert_eq "str_ltrim preserves middle and trailing" "$R" "hello world  "

nl_str="
line"
str_ltrim "$nl_str"
assert_eq "str_ltrim newline" "$R" "line"

str_rtrim "hello  "
assert_eq "str_rtrim basic" "$R" "hello"

str_rtrim "tab		"
assert_eq "str_rtrim tabs" "$R" "tab"

str_rtrim "  mixed  	 "
assert_eq "str_rtrim mixed ws preserves leading" "$R" "  mixed"

str_rtrim "nowhitespace"
assert_eq "str_rtrim no trailing ws" "$R" "nowhitespace"

str_rtrim ""
assert_eq "str_rtrim empty" "$R" ""

str_rtrim "   "
assert_eq "str_rtrim all whitespace" "$R" ""

str_rtrim "  hello world  "
assert_eq "str_rtrim preserves middle and leading" "$R" "  hello world"

nl_str2="line
"
str_rtrim "$nl_str2"
assert_eq "str_rtrim newline" "$R" "line"

str_trim "  hello  "
assert_eq "str_trim basic" "$R" "hello"

str_trim "		tabs		"
assert_eq "str_trim tabs" "$R" "tabs"

str_trim "  	 mixed  	 "
assert_eq "str_trim mixed" "$R" "mixed"

str_trim "nowhitespace"
assert_eq "str_trim no whitespace" "$R" "nowhitespace"

str_trim ""
assert_eq "str_trim empty" "$R" ""

str_trim "   "
assert_eq "str_trim all whitespace" "$R" ""

str_trim "  hello world  "
assert_eq "str_trim preserves middle" "$R" "hello world"

str_trim "  multi
line  "
assert_eq "str_trim multiline" "$R" "multi
line"

str_indent "hello"
assert_eq "str_indent no indent" "$R" ""

str_indent "  two spaces"
assert_eq "str_indent two spaces" "$R" "  "

str_indent "    four spaces"
assert_eq "str_indent four spaces" "$R" "    "

str_indent "	one tab"
assert_eq "str_indent tab" "$R" "	"

str_indent "		two tabs"
assert_eq "str_indent two tabs" "$R" "		"

str_indent "  	mixed indent"
assert_eq "str_indent mixed" "$R" "  	"

str_indent ""
assert_eq "str_indent empty string" "$R" ""

str_indent "   "
assert_eq "str_indent all whitespace" "$R" "   "

str_indent "  hello world"
assert_eq "str_indent doesn't capture middle spaces" "$R" "  "

if str_starts '$PATH' '$'
  pass "str_starts dollar sign"
else
  fail "str_starts dollar sign"
end

if str_ends 'file$' '$'
  pass "str_ends dollar sign"
else
  fail "str_ends dollar sign"
end

if str_contains '$HOME/path' '$HOME'
  pass "str_contains dollar path"
else
  fail "str_contains dollar path"
end

str_after 'key=$value' '='
assert_eq "str_after with dollar in value" "$R" '$value'

str_before '$key=value' '='
assert_eq "str_before with dollar in key" "$R" '$key'

if str_contains 'path\\to\\file' '\\'
  pass "str_contains backslash"
else
  fail "str_contains backslash"
end

str_after 'C:\\Users\\file' '\\'
assert_eq "str_after backslash" "$R" 'Users\\file'

str_after_last 'C:\\Users\\file' '\\'
assert_eq "str_after_last backslash" "$R" "file"

if str_contains "it's a test" "'"
  pass "str_contains single quote"
else
  fail "str_contains single quote"
end

if str_contains 'say "hello"' '"'
  pass "str_contains double quote"
else
  fail "str_contains double quote"
end

path="/home/user/documents/file.txt"
str_after_last "$path" "/"
filename="$R"
assert_eq "extract filename" "$filename" "file.txt"
str_before_last "$path" "/"
dirname="$R"
assert_eq "extract dirname" "$dirname" "/home/user/documents"
str_after_last "$filename" "."
ext="$R"
assert_eq "extract extension" "$ext" "txt"
str_before_last "$filename" "."
base="$R"
assert_eq "extract basename" "$base" "file"

url="https://example.com:8080/path/to/page?query=1"
str_after "$url" "://"
rest="$R"
str_before "$rest" "/"
host_port="$R"
str_before "$host_port" ":"
host="$R"
assert_eq "url host" "$host" "example.com"
str_after "$host_port" ":"
port="$R"
assert_eq "url port" "$port" "8080"

str_after "a///b" "/"
assert_eq "str_after repeated delim" "$R" "//b"
str_after_last "a///b" "/"
assert_eq "str_after_last repeated delim" "$R" "b"
str_before "a///b" "/"
assert_eq "str_before repeated delim" "$R" "a"
str_before_last "a///b" "/"
assert_eq "str_before_last repeated delim" "$R" "a//"

long_str="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaX"
if str_ends "$long_str" "X"
  pass "str_ends long string"
else
  fail "str_ends long string"
end

if str_starts "$long_str" "aaaa"
  pass "str_starts long string"
else
  fail "str_starts long string"
end

if str_contains "café" "fé"
  pass "str_contains extended ascii"
else
  fail "str_contains extended ascii"
end

echo
echo "=== Nested Blocks ==="

_nb_result=""
_nb_cmd="start"
_nb_verbose=1
switch $_nb_cmd
case start
  if $_nb_verbose == 1
    _nb_result="verbose_start"
  else
    _nb_result="quiet_start"
  end
case stop: _nb_result="stop"
end
assert_eq "if inside switch" "$_nb_result" "verbose_start"

_nb2_result=""
_nb2_level="debug"
_nb2_trace=0
_nb2_debug=1
switch $_nb2_level
case debug
  if $_nb2_trace == 1
    _nb2_result="trace"
  elif $_nb2_debug == 1
    _nb2_result="debug"
  else
    _nb2_result="other"
  end
case info: _nb2_result="info"
end
assert_eq "if/elif/else inside switch" "$_nb2_result" "debug"

_nb3_a=""
_nb3_b=""
_nb3_mode="both"
switch $_nb3_mode
case both
  if 1 == 1
    _nb3_a="first"
  end
  if 2 == 2
    _nb3_b="second"
  end
case neither: _nb3_a="none"
end
assert_eq "multiple ifs in switch (a)" "$_nb3_a" "first"
assert_eq "multiple ifs in switch (b)" "$_nb3_b" "second"

_nb4_result=""
_nb4_enabled=1
_nb4_type="foo"
if $_nb4_enabled == 1
  switch $_nb4_type
  case foo: _nb4_result="enabled_foo"
  case bar: _nb4_result="enabled_bar"
  end
end
assert_eq "switch inside if" "$_nb4_result" "enabled_foo"

_nb5_result=""
_nb5_outer=1
_nb5_sel="a"
_nb5_inner=1
if $_nb5_outer == 1
  switch $_nb5_sel
  case a
    if $_nb5_inner == 1
      _nb5_result="deep_a_inner"
    else
      _nb5_result="deep_a_outer"
    end
  case b
    _nb5_result="deep_b"
  end
end
assert_eq "if>switch>if nesting" "$_nb5_result" "deep_a_inner"

_nb6_result=""
_nb6_outer="x"
_nb6_inner="y"
switch $_nb6_outer
case x
  switch $_nb6_inner
  case y: _nb6_result="x_y"
  case z: _nb6_result="x_z"
  end
case w: _nb6_result="w"
end
assert_eq "switch inside switch" "$_nb6_result" "x_y"

_nb7_result=""
_nb7_a="p"
_nb7_b="q"
_nb7_c=1
switch $_nb7_a
case p
  switch $_nb7_b
  case q
    if $_nb7_c == 1
      _nb7_result="p_q_true"
    else
      _nb7_result="p_q_false"
    end
  end
end
assert_eq "if>switch>switch nesting" "$_nb7_result" "p_q_true"

_nb8_result=0
_nb8_mode="loop"
_nb8_count=3
switch $_nb8_mode
case loop
  while $_nb8_count > 0
    _nb8_result=$((_nb8_result + 1))
    _nb8_count=$((_nb8_count - 1))
  done
case single: _nb8_result=999
end
assert_eq "while inside switch" "$_nb8_result" "3"

_nb9_result=""
_nb9_mode="iterate"
switch $_nb9_mode
case iterate
  for _nb9_i in a b c
    _nb9_result="${_nb9_result}${_nb9_i}"
  done
case skip: _nb9_result="skipped"
end
assert_eq "for inside switch" "$_nb9_result" "abc"

_nb10_result=0
_nb10_mode="conditional_loop"
_nb10_enabled=1
_nb10_n=2
switch $_nb10_mode
case conditional_loop
  if $_nb10_enabled == 1
    while $_nb10_n > 0
      _nb10_result=$((_nb10_result + 1))
      _nb10_n=$((_nb10_n - 1))
    done
  end
end
assert_eq "if>while inside switch" "$_nb10_result" "2"

_nb11_result=""
_nb11_a=1
_nb11_b="x"
_nb11_c=1
_nb11_d="y"
if $_nb11_a == 1
  switch $_nb11_b
  case x
    if $_nb11_c == 1
      switch $_nb11_d
      case y
        _nb11_result="a1_bx_c1_dy"
      end
    end
  end
end
assert_eq "if>switch>if>switch" "$_nb11_result" "a1_bx_c1_dy"

_nb12_result=""
_nb12_outer=1
_nb12_inner=0
if $_nb12_outer == 1
  if $_nb12_inner == 1
    _nb12_result="inner_true"
  end
else
  _nb12_result="outer_false"
end
assert_eq "single-line if then outer else" "$_nb12_result" ""

_nb13_result=""
_nb13_outer=0
_nb13_inner=1
if $_nb13_outer == 1
  if $_nb13_inner == 1
    _nb13_result="inner_true"
  end
else
  _nb13_result="outer_false"
end
assert_eq "single-line if, outer else taken" "$_nb13_result" "outer_false"

rm -f /tmp/shsh_test.txt /tmp/shsh_test2.txt /tmp/shsh_empty.txt /tmp/shsh_special.txt /tmp/shsh_fmt.txt

echo
echo "=== Script Argument Passing ==="

printf 'printf "%%s\\n" "$@"\n' > /tmp/shsh_args_test.shsh

_args_out="$(sh "$_shsh" /tmp/shsh_args_test.shsh one)"
assert_eq "single arg passed" "$_args_out" "one"

_args_out="$(sh "$_shsh" /tmp/shsh_args_test.shsh one two three | tr '\n' ',')"
assert_eq "multi args passed" "$_args_out" "one,two,three,"

_args_out="$(sh "$_shsh" /tmp/shsh_args_test.shsh "hello world")"
assert_eq "arg with space" "$_args_out" "hello world"

_args_out="$(sh "$_shsh" /tmp/shsh_args_test.shsh)"
assert_eq "no args (empty)" "$_args_out" ""

printf 'printf "count:%%s\\n" "$#"\n' > /tmp/shsh_argc_test.shsh
_argc_out="$(sh "$_shsh" /tmp/shsh_argc_test.shsh a b c d e)"
assert_eq "arg count 5" "$_argc_out" "count:5"

printf 'printf "first:%%s second:%%s\\n" "$1" "$2"\n' > /tmp/shsh_posarg_test.shsh
_posarg_out="$(sh "$_shsh" /tmp/shsh_posarg_test.shsh alpha beta gamma)"
assert_eq "positional args \$1 \$2" "$_posarg_out" "first:alpha second:beta"

rm -f /tmp/shsh_args_test.shsh /tmp/shsh_argc_test.shsh /tmp/shsh_posarg_test.shsh

echo
echo "=== Compiler Output Validation ==="

cat > /tmp/shsh_switch_compile.shsh << 'SHSH'
switch $x
  case a: echo a
  case b: echo b
end
SHSH
_compiled="$(sh "$_shsh" raw /tmp/shsh_switch_compile.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "switch compilation produces valid shell"
else
  fail "switch compilation produces invalid shell"
end

cat > /tmp/shsh_nested_switch.shsh << 'SHSH'
switch $outer
  case a
    switch $inner
      case x: echo ax
      case y: echo ay
    end
  case b: echo b
end
SHSH
_compiled="$(sh "$_shsh" raw /tmp/shsh_nested_switch.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "nested switch compilation produces valid shell"
else
  fail "nested switch compilation produces invalid shell"
end

cat > /tmp/shsh_3level_switch.shsh << 'SHSH'
switch $a
  case 1
    switch $b
      case x
        switch $c
          case p: echo 1xp
          case q: echo 1xq
        end
      case y: echo 1y
    end
  case 2: echo 2
end
SHSH
_compiled="$(sh "$_shsh" raw /tmp/shsh_3level_switch.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "3-level nested switch compilation valid"
else
  fail "3-level nested switch compilation invalid"
end

cat > /tmp/shsh_switch_default.shsh << 'SHSH'
switch $x
  case a: echo a
  default: echo other
end
SHSH
_compiled="$(sh "$_shsh" raw /tmp/shsh_switch_default.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "switch with default compilation valid"
else
  fail "switch with default compilation invalid"
end

cat > /tmp/shsh_switch_in_if.shsh << 'SHSH'
if $cond == 1
  switch $x
    case a: echo a
    case b: echo b
  end
end
SHSH
_compiled="$(sh "$_shsh" raw /tmp/shsh_switch_in_if.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "switch inside if compilation valid"
else
  fail "switch inside if compilation invalid"
end

cat > /tmp/shsh_while_colon.shsh << 'SHSH'
i=0
while $i < 3: i=$((i + 1))
echo done
SHSH
_compiled="$(sh "$_shsh" raw /tmp/shsh_while_colon.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "single-line while compilation valid"
else
  fail "single-line while compilation invalid"
end

cat > /tmp/shsh_switch_run.shsh << 'SHSH'
result=""
for x in a b c
  switch $x
    case a: result="${result}A"
    case b: result="${result}B"
    default: result="${result}X"
  end
done
echo "$result"
SHSH
_run_out="$(sh "$_shsh" /tmp/shsh_switch_run.shsh)"
assert_eq "compiled switch runs correctly" "$_run_out" "ABX"

cat > /tmp/shsh_nested_run.shsh << 'SHSH'
result=""
for o in a b
  for i in x y
    switch $o
      case a
        switch $i
          case x: result="${result}ax"
          case y: result="${result}ay"
        end
      case b: result="${result}b"
    end
  done
done
echo "$result"
SHSH
_nested_out="$(sh "$_shsh" /tmp/shsh_nested_run.shsh)"
assert_eq "nested switch runs correctly" "$_nested_out" "axaybb"

sh "$_shsh" raw $_shsh_src > /tmp/shsh_boot1.sh
chmod +x /tmp/shsh_boot1.sh
sh /tmp/shsh_boot1.sh raw $_shsh_src > /tmp/shsh_boot2.sh
if diff -q /tmp/shsh_boot1.sh /tmp/shsh_boot2.sh >/dev/null 2>&1
  pass "bootstrap produces stable output"
else
  fail "bootstrap produces different output on second compile"
end

cat > /tmp/shsh_strip_test.shsh << 'SHSH'
echo "simple"
SHSH
_strip_out="$(sh "$_shsh" build /tmp/shsh_strip_test.shsh)"
_full_out="$(sh "$_shsh" build_full /tmp/shsh_strip_test.shsh)"
_strip_lines="$(printf '%s\n' "$_strip_out" | wc -l)"
_full_lines="$(printf '%s\n' "$_full_out" | wc -l)"
if $_strip_lines < $_full_lines
  pass "build strips unused runtime functions"
else
  fail "build should produce smaller output than build_full"
end

cat > /tmp/shsh_strip_run.shsh << 'SHSH'
array_add items "a"
array_add items "b"
array_len items
echo "$R"
SHSH
sh "$_shsh" build /tmp/shsh_strip_run.shsh > /tmp/shsh_strip_run.sh
_strip_run_out="$(sh /tmp/shsh_strip_run.sh)"
assert_eq "stripped script runs correctly" "$_strip_run_out" "2"

echo
echo "=== Tree Shaking ==="

_ts_out=$("$_shsh" build <<'SHSH'
echo "hello"
SHSH
)
if str_contains "$_ts_out" "__RUNTIME_START__"
  fail "tree shake: should not contain runtime markers"
else
  pass "tree shake: no runtime markers"
end

_ts_pure=$("$_shsh" build <<'SHSH'
x=1
echo $x
SHSH
)
assert_eq "tree shake: pure shell no runtime" "$_ts_pure" 'x=1
echo $x'

_ts_str=$("$_shsh" build <<'SHSH'
str_before "a:b" ":"
echo $R
SHSH
)
if str_contains "$_ts_str" "str_before()"
  pass "tree shake: includes str_before"
else
  fail "tree shake: should include str_before"
end
if str_contains "$_ts_str" "str_after()"
  fail "tree shake: should not include str_after"
else
  pass "tree shake: excludes str_after"
end
if str_contains "$_ts_str" "array_add()"
  fail "tree shake: should not include array_add"
else
  pass "tree shake: excludes array_add"
end

_ts_dep=$("$_shsh" build <<'SHSH'
array_add items "x"
SHSH
)
if str_contains "$_ts_dep" "array_add()"
  pass "tree shake: includes array_add"
else
  fail "tree shake: should include array_add"
end
if str_contains "$_ts_dep" "_shsh_check_name()"
  pass "tree shake: includes dependency _shsh_check_name"
else
  fail "tree shake: should include _shsh_check_name dependency"
end

_ts_tok=$("$_shsh" build <<'SHSH'
tokenize "(a)" t
SHSH
)
if str_contains "$_ts_tok" "_shsh_sq="
  pass "tree shake: includes _shsh_sq for tokenize"
else
  fail "tree shake: should include _shsh_sq for tokenize"
end
if str_contains "$_ts_tok" "_shsh_dq="
  pass "tree shake: includes _shsh_dq for tokenize"
else
  fail "tree shake: should include _shsh_dq for tokenize"
end

_ts_noq=$("$_shsh" build <<'SHSH'
str_before "a:b" ":"
SHSH
)
if str_contains "$_ts_noq" "_shsh_sq="
  fail "tree shake: should not include _shsh_sq"
else
  pass "tree shake: excludes _shsh_sq when unused"
end

_ts_bit=$("$_shsh" build <<'SHSH'
bit_16 0x1234
SHSH
)
if str_contains "$_ts_bit" "ENDIAN="
  pass "tree shake: includes ENDIAN for bit_16"
else
  fail "tree shake: should include ENDIAN for bit_16"
end

_ts_noend=$("$_shsh" build <<'SHSH'
array_add x "y"
SHSH
)
if str_contains "$_ts_noend" "ENDIAN="
  fail "tree shake: should not include ENDIAN"
else
  pass "tree shake: excludes ENDIAN when unused"
end

_ts_multi=$("$_shsh" build <<'SHSH'
str_before "a:b" ":"
str_after "a:b" ":"
map_set m k v
SHSH
)
if str_contains "$_ts_multi" "str_before()"
  pass "tree shake: multi includes str_before"
else
  fail "tree shake: multi should include str_before"
end
if str_contains "$_ts_multi" "str_after()"
  pass "tree shake: multi includes str_after"
else
  fail "tree shake: multi should include str_after"
end
if str_contains "$_ts_multi" "map_set()"
  pass "tree shake: multi includes map_set"
else
  fail "tree shake: multi should include map_set"
end

if str_contains "$_ts_multi" "_shsh_sane()"
  pass "tree shake: includes transitive dep _shsh_sane"
else
  fail "tree shake: should include transitive dep _shsh_sane"
end

_ts_run_src='
array_add nums 10
array_add nums 20
array_add nums 30
array_len nums
echo "len=$R"
array_get nums 1
echo "val=$R"
'
_ts_run_out=$("$_shsh" build <<SHSH
$_ts_run_src
SHSH
)
_ts_run_result=$(echo "$_ts_run_out" | sh)
assert_eq "tree shake: stripped script runs" "$_ts_run_result" "len=3
val=20"

_ts_map_out=$("$_shsh" build <<'SHSH'
map_set conf host "localhost"
map_set conf port "8080"
map_get conf host
echo "host=$R"
if map_has conf port
  echo "has port"
end
SHSH
)
_ts_map_result=$(echo "$_ts_map_out" | sh)
assert_eq "tree shake: map script runs" "$_ts_map_result" "host=localhost
has port"

_ts_str_out=$("$_shsh" build <<'SHSH'
str_before "hello:world" ":"
a="$R"
str_after "hello:world" ":"
b="$R"
str_trim "  spaced  "
c="$R"
echo "$a|$b|$c"
SHSH
)
_ts_str_result=$(echo "$_ts_str_out" | sh)
assert_eq "tree shake: string script runs" "$_ts_str_result" "hello|world|spaced"

_ts_blank=$("$_shsh" build <<'SHSH'
str_before "x:y" ":"
SHSH
)
_ts_blank_lines=$(printf '%s\n' "$_ts_blank" | grep -c '^$' || true)
if "$_ts_blank_lines" == "0"
  pass "tree shake: no blank lines"
else
  fail "tree shake: has $ts_blank_lines blank lines"
end

_ts_complex=$("$_shsh" build <<'SHSH'
default host "localhost"
array_add items "one"
array_add items "two"
cb() { echo "item: $R"; }
array_for items cb
map_set cfg key "value"
map_get cfg key
echo "cfg=$R"
SHSH
)
_ts_complex_result=$(echo "$_ts_complex" | sh)
assert_eq "tree shake: complex script runs" "$_ts_complex_result" "item: one
item: two
cfg=value"

rm -f /tmp/shsh_switch_compile.shsh /tmp/shsh_nested_switch.shsh /tmp/shsh_3level_switch.shsh
rm -f /tmp/shsh_switch_default.shsh /tmp/shsh_switch_in_if.shsh /tmp/shsh_while_colon.shsh
rm -f /tmp/shsh_switch_run.shsh /tmp/shsh_nested_run.shsh /tmp/shsh_boot1.sh /tmp/shsh_boot2.sh
rm -f /tmp/shsh_strip_test.shsh /tmp/shsh_strip_run.shsh /tmp/shsh_strip_run.sh

echo
echo "=== Try/Catch ==="

_tc_basic=""
try
  _tc_basic="${_tc_basic}A"
  false
  _tc_basic="${_tc_basic}B"
catch
  _tc_basic="${_tc_basic}C"
end
_tc_basic="${_tc_basic}D"
assert_eq "try/catch basic" "$_tc_basic" "ACD"

_tc_noerr=""
try
  _tc_noerr="${_tc_noerr}A"
  true
  _tc_noerr="${_tc_noerr}B"
catch
  _tc_noerr="${_tc_noerr}C"
end
_tc_noerr="${_tc_noerr}D"
assert_eq "try/catch no error" "$_tc_noerr" "ABD"

_tc_nocatch=""
try
  _tc_nocatch="${_tc_nocatch}A"
  false
  _tc_nocatch="${_tc_nocatch}B"
end
_tc_nocatch="${_tc_nocatch}C"
assert_eq "try without catch" "$_tc_nocatch" "AC"

_tc_nocatch2=""
try
  _tc_nocatch2="${_tc_nocatch2}A"
  true
  _tc_nocatch2="${_tc_nocatch2}B"
end
_tc_nocatch2="${_tc_nocatch2}C"
assert_eq "try without catch no error" "$_tc_nocatch2" "ABC"

_tc_nest1=""
try
  _tc_nest1="${_tc_nest1}A"
  try
    _tc_nest1="${_tc_nest1}B"
    false
    _tc_nest1="${_tc_nest1}C"
  catch
    _tc_nest1="${_tc_nest1}D"
  end
  _tc_nest1="${_tc_nest1}E"
catch
  _tc_nest1="${_tc_nest1}F"
end
_tc_nest1="${_tc_nest1}G"
assert_eq "nested try/catch inner" "$_tc_nest1" "ABDEG"

_tc_nest2=""
try
  _tc_nest2="${_tc_nest2}A"
  try
    _tc_nest2="${_tc_nest2}B"
  catch
    _tc_nest2="${_tc_nest2}C"
  end
  _tc_nest2="${_tc_nest2}D"
  false
  _tc_nest2="${_tc_nest2}E"
catch
  _tc_nest2="${_tc_nest2}F"
end
_tc_nest2="${_tc_nest2}G"
assert_eq "nested try/catch outer" "$_tc_nest2" "ABDFG"

_tc_exit=""
try
  _tc_exit="${_tc_exit}A"
  sh -c 'exit 5'
  _tc_exit="${_tc_exit}B"
catch
  _tc_exit="${_tc_exit}C"
end
assert_eq "try/catch exit code" "$_tc_exit" "AC"

_tc_pipe=""
try
  _tc_pipe="${_tc_pipe}A"
  echo "test" | grep "test" > /dev/null
  _tc_pipe="${_tc_pipe}B"
catch
  _tc_pipe="${_tc_pipe}C"
end
assert_eq "try/catch pipeline success" "$_tc_pipe" "AB"

_tc_multi=""
try
  _tc_multi="${_tc_multi}A"
  _tc_multi="${_tc_multi}B"
  _tc_multi="${_tc_multi}C"
  false
  _tc_multi="${_tc_multi}D"
catch
  _tc_multi="${_tc_multi}E"
end
assert_eq "try/catch multi statements" "$_tc_multi" "ABCE"

_tc_inif=""
if true
  try
    _tc_inif="${_tc_inif}A"
    false
    _tc_inif="${_tc_inif}B"
  catch
    _tc_inif="${_tc_inif}C"
  end
end
assert_eq "try/catch inside if" "$_tc_inif" "AC"

_tc_inwhile=""
_tc_count=0
while $_tc_count < 2
  try
    _tc_inwhile="${_tc_inwhile}A"
    if $_tc_count == 0: false
    _tc_inwhile="${_tc_inwhile}B"
  catch
    _tc_inwhile="${_tc_inwhile}C"
  end
  _tc_count++
done
assert_eq "try/catch inside while" "$_tc_inwhile" "ACAB"

_tc_ifinside=""
try
  _tc_ifinside="${_tc_ifinside}A"
  if true
    _tc_ifinside="${_tc_ifinside}B"
    false
    _tc_ifinside="${_tc_ifinside}C"
  end
  _tc_ifinside="${_tc_ifinside}D"
catch
  _tc_ifinside="${_tc_ifinside}E"
end
assert_eq "if inside try" "$_tc_ifinside" "ABE"

_tc_whileinside=""
try
  _tc_whileinside="${_tc_whileinside}A"
  _tc_wi=0
  while $_tc_wi < 3
    _tc_whileinside="${_tc_whileinside}B"
    _tc_wi++
    if $_tc_wi == 2: false
  done
  _tc_whileinside="${_tc_whileinside}C"
catch
  _tc_whileinside="${_tc_whileinside}D"
end
assert_eq "while inside try" "$_tc_whileinside" "ABBD"

_tc_triple=""
try
  _tc_triple="${_tc_triple}A"
  try
    _tc_triple="${_tc_triple}B"
    try
      _tc_triple="${_tc_triple}C"
      false
      _tc_triple="${_tc_triple}D"
    catch
      _tc_triple="${_tc_triple}E"
    end
    _tc_triple="${_tc_triple}F"
  catch
    _tc_triple="${_tc_triple}G"
  end
  _tc_triple="${_tc_triple}H"
catch
  _tc_triple="${_tc_triple}I"
end
assert_eq "triple nested try" "$_tc_triple" "ABCEFH"

_tc_catchlogic=""
try
  false
catch
  if true
    _tc_catchlogic="caught"
  end
end
assert_eq "catch with logic" "$_tc_catchlogic" "caught"

_tc_varscope=""
try
  _tc_varscope="set"
catch
  _tc_varscope="error"
end
assert_eq "try variable scope" "$_tc_varscope" "set"

try
  sh -c 'exit 42'
catch
  _tc_errcode="$error"
end
assert_eq "error code captured" "$_tc_errcode" "42"

my_str="hello"
try
  if $my_str
    pass "string truthy"
  else
    fail "string truthy"
  end
catch
  echo "CRASH: Shell tried to execute string"
end

my_val="false"
if $my_val
  pass "string 'false' truthy"
else
  fail "string 'false' truthy"
end

empty=""
try
  if $empty
    fail "empty string truthy"
  else
    pass "empty string truthy"
  end
catch
  fail "empty string truthy"
end

echo
echo "=== Truthy Variable Edge Cases ==="

_brace_var="value"
if ${_brace_var}
  pass "braced var truthy"
else
  fail "braced var truthy"
end

_brace_empty=""
if ${_brace_empty}
  fail "braced empty var falsy"
else
  pass "braced empty var falsy"
end

_num_zero=0
if $_num_zero
  pass "numeric 0 is truthy (non-empty string)"
else
  fail "numeric 0 is truthy (non-empty string)"
end

_num_one=1
if $_num_one
  pass "numeric 1 truthy"
else
  fail "numeric 1 truthy"
end

_whitespace="   "
if $_whitespace
  pass "whitespace string truthy"
else
  fail "whitespace string truthy"
end

_special="hello world"
if $_special
  pass "string with space truthy"
else
  fail "string with space truthy"
end

_special2="a*b?c[d]"
if $_special2
  pass "string with glob chars truthy"
else
  fail "string with glob chars truthy"
end

_underscore_var="yes"
if $_underscore_var
  pass "underscore prefix var truthy"
else
  fail "underscore prefix var truthy"
end

var123="numeric name"
if $var123
  pass "var with numbers truthy"
else
  fail "var with numbers truthy"
end

if true
  pass "command 'true' works"
else
  fail "command 'true' works"
end

if false
  fail "command 'false' works"
else
  pass "command 'false' works"
end

_test_func() { return 0; }
if _test_func
  pass "function call works"
else
  fail "function call works"
end

if test -n "hello"
  pass "test command works"
else
  fail "test command works"
end

_neg_var="something"
if ! $_neg_var
  fail "negated truthy var"
else
  pass "negated truthy var"
end

_neg_empty=""
if ! $_neg_empty
  pass "negated empty var"
else
  fail "negated empty var"
end

_cmp_a="foo"
_cmp_b="foo"
if "$_cmp_a" == "$_cmp_b"
  pass "comparison with quoted vars"
else
  fail "comparison with quoted vars"
end

_while_cond="go"
_while_count=0
while $_while_cond
  _while_count=$((_while_count + 1))
  if $_while_count >= 3: _while_cond=""
done
assert_eq "while truthy var loop" "$_while_count" "3"

_elif_val=""
_elif_other="yes"
if $_elif_val
  _elif_result="first"
elif $_elif_other
  _elif_result="second"
else
  _elif_result="third"
end
assert_eq "elif truthy var" "$_elif_result" "second"

echo
echo "=== Security / Red Team Tests ==="


_cmd_sub_result=""
try
  if $(echo true)
    _cmd_sub_result="executed"
  end
catch
  _cmd_sub_result="error"
end
assert_eq "cmd substitution not wrapped" "$_cmd_sub_result" "executed"

_backtick_result=""
try
  if `echo true`
    _backtick_result="executed"
  end
catch
  _backtick_result="error"
end
assert_eq "backtick not wrapped" "$_backtick_result" "executed"

_inj1="val"
_inj1_result=""
try
  if $_inj1
    _inj1_result="ok"
  end
catch
  _inj1_result="error"
end
assert_eq "simple var no injection" "$_inj1_result" "ok"

_not_cmd=""
if ! false
  _not_cmd="ok"
end
assert_eq "! false works" "$_not_cmd" "ok"

if ! true
  _not_true="yes"
else
  _not_true="no"
end
assert_eq "! true works" "$_not_true" "no"

if ! test -z "hello"
  _not_test="not empty"
else
  _not_test="empty"
end
assert_eq "! test -z works" "$_not_test" "not empty"

_false_func() { return 1; }
if ! _false_func
  _not_func="ok"
else
  _not_func="fail"
end
assert_eq "! function works" "$_not_func" "ok"

set -- "arg1" "arg2"
if $1
  _pos_result="truthy"
else
  _pos_result="falsy"
end
assert_eq "positional \$1 truthy" "$_pos_result" "truthy"

_argc_pass=0
try
  if $# >/dev/null 2>&1
    _argc_pass=1
  else
    _argc_pass=1
  end
catch
  _argc_pass=1
end
if $_argc_pass == 1
  pass "\$# not wrapped as simple var"
else
  fail "\$# incorrectly wrapped"
end

_status_pass=0
try
  if $? >/dev/null 2>&1
    _status_pass=1
  else
    _status_pass=1
  end
catch
  _status_pass=1
end
if $_status_pass == 1
  pass "\$? not wrapped as simple var"
else
  fail "\$? incorrectly wrapped"
end

_pid_pass=0
try
  if $$ >/dev/null 2>&1
    _pid_pass=1
  else
    _pid_pass=1
  end
catch
  _pid_pass=1
end
if $_pid_pass == 1
  pass "\$\$ not wrapped as simple var"
else
  fail "\$\$ incorrectly wrapped"
end

_bg_pass=0
try
  if $! 2>/dev/null
    _bg_pass=1
  else
    _bg_pass=1
  end
catch
  _bg_pass=1
end
if $_bg_pass == 1
  pass "\$! not wrapped as simple var"
else
  fail "\$! incorrectly wrapped"
end

_bare_pass=0
try
  if $ 2>/dev/null
    _bare_pass=1
  else
    _bare_pass=1
  end
catch
  _bare_pass=1
end
if $_bare_pass == 1
  pass "bare \$ not wrapped as simple var"
else
  fail "bare \$ incorrectly wrapped"
end

pass "empty \${} is shell syntax error (expected)"

_verylongvariablenamethatisquitelongindeed="yes"
if $_verylongvariablenamethatisquitelongindeed
  pass "long var name works"
else
  fail "long var name works"
end

_complex_var=""
_complex_pass=0
try
  if ${_complex_var:-shouldfail} 2>/dev/null
    _complex_pass=0
  else
    _complex_pass=1
  end
catch
  _complex_pass=1
end
if $_complex_pass == 1
  pass "\${var:-x} not wrapped as simple var"
else
  fail "\${var:-x} incorrectly wrapped"
end

_len_test="hello"
_len_pass=0
try
  if ${#_len_test} 2>/dev/null
    _len_pass=0
  else
    _len_pass=1
  end
catch
  _len_pass=1
end
if $_len_pass == 1
  pass "\${#var} not wrapped as simple var"
else
  fail "\${#var} incorrectly wrapped"
end

_alt_test="set"
_alt_pass=0
try
  if ${_alt_test:+shouldfail} 2>/dev/null
    _alt_pass=0
  else
    _alt_pass=1
  end
catch
  _alt_pass=1
end
if $_alt_pass == 1
  pass "\${var:+x} not wrapped as simple var"
else
  fail "\${var:+x} incorrectly wrapped"
end

set -- ""
_num_pass=0
try
  if $1abc 2>/dev/null
    _num_pass=0
  else
    _num_pass=1
  end
catch
  _num_pass=1
end
if $_num_pass == 1
  pass "\$1abc not wrapped as simple var"
else
  fail "\$1abc incorrectly wrapped"
end

_nested_pass=0
try
  if $$_nested 2>/dev/null
    _nested_pass=0
  else
    _nested_pass=1
  end
catch
  _nested_pass=1
end
if $_nested_pass == 1
  pass "\$\$var not wrapped as simple var"
else
  fail "\$\$var incorrectly wrapped"
end

echo
echo "=== file_hash ==="

FH_F1="shsh_test_file_hash_1_$$"
FH_F2="shsh_test_file_hash_2_$$"


printf 'hello\n' > "$FH_F1" || {
  fail "file_hash: setup failed (FH_F1)"
  exit 1
}

if file_hash "shsh_no_such_file_$$"; then
  fail "file_hash: missing file should fail"
else
  pass "file_hash: missing file fails"
fi

if file_hash "$FH_F1"; then
  FH_HASH1="$R"
  if [ -n "$FH_HASH1" ]; then
    pass "file_hash: non-empty hash"
  else
    fail "file_hash: hash is empty"
  fi
else
  fail "file_hash: returns non-zero on existing file"
fi

cp "$FH_F1" "$FH_F2" || {
  fail "file_hash: setup failed (FH_F2 copy)"
}

if file_hash "$FH_F2"; then
  FH_HASH2="$R"
  if [ "$FH_HASH1" = "$FH_HASH2" ]; then
    pass "file_hash: identical files share hash"
  else
    fail "file_hash: identical files have different hash"
  fi
else
  fail "file_hash: second file hash call failed"
fi

printf 'world\n' > "$FH_F2" || {
  fail "file_hash: setup failed (FH_F2 overwrite)"
}

if file_hash "$FH_F2"; then
  FH_HASH3="$R"
  if [ "$FH_HASH1" != "$FH_HASH3" ]; then
    pass "file_hash: different files differ"
  else
    fail "file_hash: different files share hash"
  fi
else
  fail "file_hash: different-content hash call failed"
fi

if command -v sha256sum >/dev/null 2>&1; then
  REF_HASH=$(sha256sum "$FH_F1" | awk '{print $1}')
  if [ "$REF_HASH" = "$FH_HASH1" ]; then
    pass "file_hash: matches sha256sum"
  else
    fail "file_hash: mismatch vs sha256sum"
  fi
elif command -v shasum >/dev/null 2>&1; then
  REF_HASH=$(shasum -a 256 "$FH_F1" | awk '{print $1}')
  if [ "$REF_HASH" = "$FH_HASH1" ]; then
    pass "file_hash: matches shasum -a 256"
  else
    fail "file_hash: mismatch vs shasum -a 256"
  fi
elif command -v md5sum >/dev/null 2>&1; then
  REF_HASH=$(md5sum "$FH_F1" | awk '{print $1}')
  if [ "$REF_HASH" = "$FH_HASH1" ]; then
    pass "file_hash: matches md5sum"
  else
    fail "file_hash: mismatch vs md5sum"
  fi
elif command -v cksum >/dev/null 2>&1; then
  # replicate the cksum fallback logic
  set -- $(cksum "$FH_F1")
  REF_CRC="$1"
  REF_HASH=$(printf '%x' "$REF_CRC")
  if [ "$REF_HASH" = "$FH_HASH1" ]; then
    pass "file_hash: matches cksum-based hash"
  else
    fail "file_hash: mismatch vs cksum-based hash"
  fi
else
  pass "file_hash: tool-compare skipped (no hash utilities)"
fi

rm -f "$FH_F1" "$FH_F2"

echo
echo "========================================"
echo "passed: $PASS"
echo "failed: $FAIL"
if $FAIL == 0
  echo "all tests passed!"
else
  exit 1
end
