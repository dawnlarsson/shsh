PASS=0 FAIL=0

assert_eq() {
  _aeq_name="$1" _aeq_got="$2" _aeq_want="$3"
  if "$_aeq_got" == "$_aeq_want"
    echo "✓ $_aeq_name"; PASS=$((PASS + 1))
  else
    echo "✗ $_aeq_name: got '$_aeq_got', want '$_aeq_want'"; FAIL=$((FAIL + 1))
  end
}

assert_neq() {
  _aneq_name="$1" _aneq_got="$2" _aneq_reject="$3"
  if "$_aneq_got" != "$_aneq_reject"
    echo "✓ $_aneq_name"; PASS=$((PASS + 1))
  else
    echo "✗ $_aneq_name: got '$_aneq_got', should not be '$_aneq_reject'"; FAIL=$((FAIL + 1))
  end
}

hex_capture() {
  eval "$1" | od -A n -t x1 -v | tr -d ' \n'
}

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

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

# empty array iteration
array_clear empty_arr
empty_count=0
empty_cb() { empty_count=$((empty_count + 1)); }
array_for empty_arr empty_cb
assert_eq "array_for empty" "$empty_count" "0"

# array_delete (shifting)
array_clear del_test
array_add del_test "a"
array_add del_test "b"
array_add del_test "c"
array_delete del_test 1
array_len del_test; assert_eq "array_delete len" "$R" "2"
array_get del_test 0; assert_eq "array_delete idx0" "$R" "a"
array_get del_test 1; assert_eq "array_delete idx1" "$R" "c"

# array_remove (explicit shifting)
array_clear rm_test
array_add rm_test "a"
array_add rm_test "b"
array_add rm_test "c"
array_remove rm_test 1
array_len rm_test; assert_eq "array_remove len" "$R" "2"
array_get rm_test 1; assert_eq "array_remove shifts" "$R" "c"

# array_unset (punch hole)
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

# delete out of bounds
array_clear bounds_del
array_add bounds_del "only"
array_delete bounds_del 5
ret=$?
if $ret != 0
  pass "array_delete out of bounds returns error"
else
  fail "array_delete out of bounds should error"
end

# multiple deletes
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

echo ""
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

# map with empty value
map_set empty "key" ""
map_get empty "key"; assert_eq "empty string" "$R" ""
if map_has empty "key"
  pass "map_has empty"
else
  fail "map_has empty"
end

# map zero value
map_set math "zero" 0
map_get math "zero"; assert_eq "zero value" "$R" "0"

# map key validation
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

echo ""
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

# tab character
tab_val="a	b"
map_set tabs "t" "$tab_val"
map_get tabs "t"; assert_eq "tab char" "$R" "$tab_val"

echo ""
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

# negative numbers
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

# string comparison
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

# empty string checks
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

# spaces in comparison
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

# operators embedded in values
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

echo ""
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

echo ""
echo "=== Loops ==="

x=0
_while_sum=0
while $x < 5
  _while_sum=$((_while_sum + x))
  x=$((x + 1))
done
assert_eq "while loop" "$_while_sum" "10"

# while with zero iterations
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

# for with single item
_single=""
for s in only
  _single="$s"
done
assert_eq "for single" "$_single" "only"

# nested for
_nested_for=""
for a in 1 2
  for b in x y
    _nested_for="$_nested_for$a$b"
  done
done
assert_eq "nested for" "$_nested_for" "1x1y2x2y"

echo ""
echo "=== Switch ==="

_sw_result=""
for val in foo bar baz qux
  switch $val
  case foo
    _sw_result="${_sw_result}F"
  case bar|baz
    _sw_result="${_sw_result}B"
  default
    _sw_result="${_sw_result}X"
  end
done
assert_eq "switch" "$_sw_result" "FBBX"

_nested_sw=""
for outer in a b
  for inner in x y
    switch $outer
    case a
      switch $inner
      case x
        _nested_sw="${_nested_sw}ax"
      case y
        _nested_sw="${_nested_sw}ay"
      end
    case b
      _nested_sw="${_nested_sw}b"
    end
  done
done
assert_eq "nested switch" "$_nested_sw" "axaybb"

# 3-level nested switch
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

# switch with only default
_def_only=""
switch "unknown"
default
  _def_only="hit"
end
assert_eq "switch default only" "$_def_only" "hit"

# switch no match no default
_no_match="unchanged"
switch "nomatch"
case foo
  _no_match="foo"
case bar
  _no_match="bar"
end
assert_eq "switch no match" "$_no_match" "unchanged"

echo ""
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

# empty input
tokenize "" T_EMPTY
array_len T_EMPTY; assert_eq "tokenizer empty" "$R" "0"

# whitespace only
tokenize "   " T_WS
array_len T_WS; assert_eq "tokenizer whitespace" "$R" "0"

# deeply nested
tokenize "((()))" T_DEEP
array_len T_DEEP; assert_eq "tokenizer deep nesting" "$R" "6"

# just atoms
tokenize "foo bar baz" T_ATOMS
array_len T_ATOMS; assert_eq "tokenizer atoms" "$R" "3"
array_get T_ATOMS 1; assert_eq "tokenizer atom 1" "$R" "bar"

echo ""
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

# empty file
file_write /tmp/shsh_empty.txt ""
file_read /tmp/shsh_empty.txt
assert_eq "file_read empty" "$R" ""

# file with special chars
file_write /tmp/shsh_special.txt 'line with $VAR and `cmd`'
file_read /tmp/shsh_special.txt
assert_eq "file special chars" "$R" 'line with $VAR and `cmd`'

echo ""
echo "=== AST Basics ==="

array_clear L1
array_add L1 "add"
array_add L1 "6"
array_add L1 "4"
array_get L1 0; assert_eq "AST head" "$R" "add"
array_get L1 1; _v1="$R"
array_get L1 2; _v2="$R"
R=$((_v1 + _v2)); assert_eq "AST eval simple" "$R" "10"

echo ""
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

# empty vs missing distinction
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

echo ""
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

# array_for early exit
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

echo ""
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

err_add=$(array_add "bad-name" "val" 2>&1)
if "$err_add" != ""
  pass "array_add reports errors"
else
  fail "array_add silent fail"
end

# command substitution in value (should be stored literally)
cmd_val='$(echo pwned)'
map_set safe "cmd" "$cmd_val"
map_get safe "cmd"
assert_eq "cmd substitution stored literally" "$R" '$(echo pwned)'

echo ""
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

echo ""
echo "=== Multiline ==="

ml="line1
line2"
ml2="line1
line2"
if is "\"$ml\" == \"$ml2\""
  pass "multiline comparison"
else
  fail "multiline comparison"
end

# multiline in map
map_set mlmap "key" "$ml"
map_get mlmap "key"
assert_eq "multiline in map" "$R" "$ml"

echo ""
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

# zero values
got=$(hex_capture 'bit_8 0x00 0x00')
assert_eq "bit_8 zeros" "$got" "0000"

got=$(hex_capture 'bit_16 0x0000')
assert_eq "bit_16 zero" "$got" "0000"

got=$(hex_capture 'bit_32 0x00000000')
assert_eq "bit_32 zero" "$got" "00000000"

# max values
got=$(hex_capture 'bit_8 0xff')
assert_eq "bit_8 max" "$got" "ff"

got=$(hex_capture 'bit_16 0xffff')
assert_eq "bit_16 max" "$got" "ffff"

echo ""
echo "=== Edge Cases ==="

# deeply nested if/elif/else
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

# if inside if
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

# large numbers
big=999999999
if $big > 999999998
  pass "large number comparison"
else
  fail "large number comparison"
end

# array with many elements
array_clear large_arr
idx=0
while $idx < 100
  array_add large_arr "item$idx"
  idx=$((idx + 1))
done
array_len large_arr; assert_eq "large array len" "$R" "100"
array_get large_arr 99; assert_eq "large array last" "$R" "item99"

# rapid map operations
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

echo ""
echo "=== Cleanup ==="
rm -f /tmp/shsh_test.txt /tmp/shsh_test2.txt /tmp/shsh_empty.txt /tmp/shsh_special.txt

echo ""
echo "========================================"
echo "passed: $PASS"
echo "failed: $FAIL"
if $FAIL == 0
  echo "all tests passed!"
else
  exit 1
end