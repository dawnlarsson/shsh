PASS=0 FAIL=0

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

# array_remove rejects negative index
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

map_set emptykey "" "val" 2>/dev/null
ret=$?
if $ret != 0
  pass "map rejects empty key"
else
  fail "map accepted empty key"
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
default: _def_only="hit"
end
assert_eq "switch default only" "$_def_only" "hit"

# switch no match no default
_no_match="unchanged"
switch "nomatch"
case foo: _no_match="foo"
case bar: _no_match="bar"
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

fmt_str="%s %d %% literal"
file_write /tmp/shsh_fmt.txt "$fmt_str"
file_read /tmp/shsh_fmt.txt
assert_eq "file_write format literals" "$R" "$fmt_str"
file_append /tmp/shsh_fmt.txt "$fmt_str"
file_read /tmp/shsh_fmt.txt
assert_eq "file_append format literals" "$R" "$fmt_str
$fmt_str"

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

array_add "bad-name" "val" 2>/dev/null
if $? != 0
  pass "array_add rejects invalid name"
else
  fail "array_add accepts invalid name"
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

got=$(hex_capture 'ENDIAN=big bit_64 0x1122334455667788')
assert_eq "bit_64 BE" "$got" "1122334455667788"

got=$(hex_capture 'bit_128 0x112233445566778899aabbccddeeff00')
assert_eq "bit_128 LE" "$got" "00ffeeddccbbaa998877665544332211"

got=$(hex_capture 'ENDIAN=big bit_128 0x112233445566778899aabbccddeeff00')
assert_eq "bit_128 BE" "$got" "112233445566778899aabbccddeeff00"

got=$(hex_capture 'bit_128 0xff')
assert_eq "bit_128 zero pad" "$got" "ff000000000000000000000000000000"

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
echo "=== Defaults ==="

# default on empty
empty_default=""
default empty_default "fallback"
assert_eq "default on empty" "$empty_default" "fallback"

# default on unset
unset unset_default 2>/dev/null
default unset_default "fallback2"
assert_eq "default on unset" "$unset_default" "fallback2"

# default preserves existing
existing_default="original"
default existing_default "ignored"
assert_eq "default preserves existing" "$existing_default" "original"

# default with zero (0 is not empty)
zero_default=0
default zero_default "replaced"
assert_eq "default zero preserved" "$zero_default" "0"

# default with spaces
space_default="has spaces"
default space_default "nope"
assert_eq "default with spaces" "$space_default" "has spaces"

# default_unset on empty (should NOT replace)
empty_for_unset=""
default_unset empty_for_unset "should_not_apply"
assert_eq "default_unset ignores empty" "$empty_for_unset" ""

# default_unset on truly unset
unset truly_unset 2>/dev/null
default_unset truly_unset "applied"
assert_eq "default_unset on unset" "$truly_unset" "applied"

# default_unset preserves existing
existing_unset="keep"
default_unset existing_unset "nope"
assert_eq "default_unset preserves existing" "$existing_unset" "keep"

# chained defaults
unset chain_var 2>/dev/null
default chain_var ""
default chain_var "second"
assert_eq "chained default" "$chain_var" "second"

# default with special chars in value
unset special_def 2>/dev/null
default special_def "hello world"
assert_eq "default special chars" "$special_def" "hello world"

# default invalid name rejected
bad_def_result=$(default "bad-name" "val" 2>&1)
ret=$?
if $ret != 0
  pass "default rejects invalid name"
else
  fail "default accepted invalid name"
end

echo ""
echo "=== Arithmetic Operators ==="

# increment
inc_var=5
inc_var++
assert_eq "var++" "$inc_var" "6"

# decrement
dec_var=10
dec_var--
assert_eq "var--" "$dec_var" "9"

# increment from zero
zero_inc=0
zero_inc++
assert_eq "0++" "$zero_inc" "1"

# decrement to negative
neg_dec=0
neg_dec--
assert_eq "0--" "$neg_dec" "-1"

# += basic
add_var=10
add_var += 5
assert_eq "var += 5" "$add_var" "15"

# -= basic
sub_var=20
sub_var -= 8
assert_eq "var -= 8" "$sub_var" "12"

# *= basic
mul_var=7
mul_var *= 6
assert_eq "var *= 6" "$mul_var" "42"

# /= basic
div_var=100
div_var /= 4
assert_eq "var /= 4" "$div_var" "25"

# %= basic
mod_var=17
mod_var %= 5
assert_eq "var %= 5" "$mod_var" "2"

# += with zero
zero_add=42
zero_add += 0
assert_eq "var += 0" "$zero_add" "42"

# *= with zero
zero_mul=999
zero_mul *= 0
assert_eq "var *= 0" "$zero_mul" "0"

# *= with one (identity)
one_mul=123
one_mul *= 1
assert_eq "var *= 1" "$one_mul" "123"

# /= by one
one_div=456
one_div /= 1
assert_eq "var /= 1" "$one_div" "456"

# negative arithmetic
neg_arith=-10
neg_arith += 3
assert_eq "negative += 3" "$neg_arith" "-7"

neg_arith2=5
neg_arith2 += -10
assert_eq "var += negative" "$neg_arith2" "-5"

# chained operations
chain_arith=10
chain_arith += 5
chain_arith *= 2
chain_arith -= 10
assert_eq "chained arithmetic" "$chain_arith" "20"

# increment in loop
loop_inc=0
iter=0
while $iter < 5
  loop_inc++
  iter++
done
assert_eq "++ in loop" "$loop_inc" "5"

# += in loop (sum 1..10)
sum=0
i=1
while $i <= 10
  sum += $i
  i++
done
assert_eq "+= loop sum" "$sum" "55"

# factorial with *=
fact=1
n=5
while $n > 1
  fact *= $n
  n--
done
assert_eq "*= factorial" "$fact" "120"

# %= in loop (find pattern)
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

# large increment
big_inc=999999
big_inc++
assert_eq "large ++" "$big_inc" "1000000"

# arithmetic with expressions
expr_var=10
expr_var += $((2 * 3))
assert_eq "+= with expr" "$expr_var" "16"

# multiple increments same line (each on own line though)
multi_a=0
multi_b=0
multi_a++
multi_b++
multi_a++
assert_eq "multiple inc a" "$multi_a" "2"
assert_eq "multiple inc b" "$multi_b" "1"

# indented arithmetic (in if block)
indent_var=5
if 1 == 1
  indent_var++
  indent_var += 10
end
assert_eq "indented arithmetic" "$indent_var" "16"

# deeply nested arithmetic
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

# arithmetic in function
arith_func() {
  _af_val=$1
  _af_val++
  _af_val *= 2
  R=$_af_val
}
arith_func 5
assert_eq "arithmetic in function" "$R" "12"

# division truncation (integer division)
trunc_div=7
trunc_div /= 2
assert_eq "integer division truncates" "$trunc_div" "3"

# modulo edge cases
mod_zero=5
mod_zero %= 5
assert_eq "x %= x equals 0" "$mod_zero" "0"

mod_larger=3
mod_larger %= 10
assert_eq "x %= larger" "$mod_larger" "3"

# ++ after semicolon (semicolon-separated statements)
semi_inc=0
echo "test" > /dev/null; semi_inc++
assert_eq "++ after semicolon" "$semi_inc" "1"

# -- after semicolon
semi_dec=5
echo "test" > /dev/null; semi_dec--
assert_eq "-- after semicolon" "$semi_dec" "4"

# += after semicolon
semi_add=10
echo "test" > /dev/null; semi_add += 5
assert_eq "+= after semicolon" "$semi_add" "15"

# ++ in inline if statement body
inline_if_inc=0
if true: inline_if_inc++
assert_eq "++ in inline if" "$inline_if_inc" "1"

# ++ with preceding statement in inline if
inline_if_semi=0
if true: echo "ok" > /dev/null; inline_if_semi++
assert_eq "++ after semicolon in inline if" "$inline_if_semi" "1"

# -- in inline else
inline_else_dec=10
if false: inline_else_dec=99
else: inline_else_dec--
assert_eq "-- in inline else" "$inline_else_dec" "9"

# += in inline elif
inline_elif_add=5
if false: inline_elif_add=0
elif true: inline_elif_add += 10
assert_eq "+= in inline elif" "$inline_elif_add" "15"

# ++ in function with semicolon
_fn_semi_cnt=0
_fn_semi_test() {
  echo "in func" > /dev/null; _fn_semi_cnt++
}
_fn_semi_test
assert_eq "++ in function after semicolon" "$_fn_semi_cnt" "1"

echo ""
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

echo ""
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

echo ""
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

echo ""
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

_dash_c_out=$("$_shsh_path" -c 'echo hi')
if "$_dash_c_out" == "hi"
  pass "-c prints inline output"
else
  fail "-c prints inline output (got: '$_dash_c_out')"
end

_stdin_code="x=7"
_stdin_t_out=$(printf "%s\n" "$_stdin_code" | "$_shsh_path" -t -)
if "$_stdin_t_out" == "$_stdin_code"
  pass "-t reads from stdin"
else
  fail "-t reads from stdin (got: '$_stdin_t_out')"
end

_test_file="/tmp/shsh_cli_test_$$.shsh"
printf '%s\n' 'x=1' > "$_test_file"
_transform_out=$("$_shsh_path" -t "$_test_file" 2>&1)
rm -f "$_test_file"
if "$_transform_out" == "x=1"
  pass "-t with file doesn't hang"
else
  fail "-t with file doesn't hang (got: '$_transform_out')"
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

echo ""
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

echo ""
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
if $_found_alpha == 1 && $_found_beta == 1 && $_found_gamma == 1
  pass "map_keys contains all keys"
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
if $_has_a == 1 && $_has_b == 0 && $_has_c == 1
  pass "map_keys excludes deleted"
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

echo ""
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

echo ""
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

echo ""
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

echo ""
echo "=== Compiler Output Validation ==="

# Test that compiled switch produces valid shell syntax
cat > /tmp/shsh_switch_compile.shsh << 'SHSH'
switch $x
  case a: echo a
  case b: echo b
end
SHSH
_compiled="$(sh "$_shsh" -t /tmp/shsh_switch_compile.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "switch compilation produces valid shell"
else
  fail "switch compilation produces invalid shell"
end

# Test nested switch compilation
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
_compiled="$(sh "$_shsh" -t /tmp/shsh_nested_switch.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "nested switch compilation produces valid shell"
else
  fail "nested switch compilation produces invalid shell"
end

# Test 3-level nested switch
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
_compiled="$(sh "$_shsh" -t /tmp/shsh_3level_switch.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "3-level nested switch compilation valid"
else
  fail "3-level nested switch compilation invalid"
end

# Test switch with default
cat > /tmp/shsh_switch_default.shsh << 'SHSH'
switch $x
  case a: echo a
  default: echo other
end
SHSH
_compiled="$(sh "$_shsh" -t /tmp/shsh_switch_default.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "switch with default compilation valid"
else
  fail "switch with default compilation invalid"
end

# Test switch inside if
cat > /tmp/shsh_switch_in_if.shsh << 'SHSH'
if $cond == 1
  switch $x
    case a: echo a
    case b: echo b
  end
end
SHSH
_compiled="$(sh "$_shsh" -t /tmp/shsh_switch_in_if.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "switch inside if compilation valid"
else
  fail "switch inside if compilation invalid"
end

# Test single-line while with colon
cat > /tmp/shsh_while_colon.shsh << 'SHSH'
i=0
while $i < 3: i=$((i + 1))
echo done
SHSH
_compiled="$(sh "$_shsh" -t /tmp/shsh_while_colon.shsh)"
if sh -n -c "$_compiled" 2>/dev/null
  pass "single-line while compilation valid"
else
  fail "single-line while compilation invalid"
end

# Test compiled switch actually runs correctly
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

# Test nested switch runs correctly
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

# Test bootstrap produces stable output (compile twice = same result)
sh "$_shsh" -t $_shsh_src > /tmp/shsh_boot1.sh
chmod +x /tmp/shsh_boot1.sh
sh /tmp/shsh_boot1.sh -t $_shsh_src > /tmp/shsh_boot2.sh
if diff -q /tmp/shsh_boot1.sh /tmp/shsh_boot2.sh >/dev/null 2>&1
  pass "bootstrap produces stable output"
else
  fail "bootstrap produces different output on second compile"
end

# Test -e strips unused functions
cat > /tmp/shsh_strip_test.shsh << 'SHSH'
echo "simple"
SHSH
_strip_out="$(sh "$_shsh" -e /tmp/shsh_strip_test.shsh)"
_full_out="$(sh "$_shsh" -E /tmp/shsh_strip_test.shsh)"
_strip_lines="$(printf '%s\n' "$_strip_out" | wc -l)"
_full_lines="$(printf '%s\n' "$_full_out" | wc -l)"
if $_strip_lines < $_full_lines
  pass "emit -e strips unused runtime functions"
else
  fail "emit -e should produce smaller output than -E"
end

# Test stripped output still runs
cat > /tmp/shsh_strip_run.shsh << 'SHSH'
array_add items "a"
array_add items "b"
array_len items
echo "$R"
SHSH
sh "$_shsh" -e /tmp/shsh_strip_run.shsh > /tmp/shsh_strip_run.sh
_strip_run_out="$(sh /tmp/shsh_strip_run.sh)"
assert_eq "stripped script runs correctly" "$_strip_run_out" "2"

rm -f /tmp/shsh_switch_compile.shsh /tmp/shsh_nested_switch.shsh /tmp/shsh_3level_switch.shsh
rm -f /tmp/shsh_switch_default.shsh /tmp/shsh_switch_in_if.shsh /tmp/shsh_while_colon.shsh
rm -f /tmp/shsh_switch_run.shsh /tmp/shsh_nested_run.shsh /tmp/shsh_boot1.sh /tmp/shsh_boot2.sh
rm -f /tmp/shsh_strip_test.shsh /tmp/shsh_strip_run.shsh /tmp/shsh_strip_run.sh

echo ""
echo "=== Try/Catch ==="

# Basic try/catch - catches error
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

# Try/catch - no error path
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

# Try without catch - suppresses error
_tc_nocatch=""
try
  _tc_nocatch="${_tc_nocatch}A"
  false
  _tc_nocatch="${_tc_nocatch}B"
end
_tc_nocatch="${_tc_nocatch}C"
assert_eq "try without catch" "$_tc_nocatch" "AC"

# Try without catch - no error
_tc_nocatch2=""
try
  _tc_nocatch2="${_tc_nocatch2}A"
  true
  _tc_nocatch2="${_tc_nocatch2}B"
end
_tc_nocatch2="${_tc_nocatch2}C"
assert_eq "try without catch no error" "$_tc_nocatch2" "ABC"

# Nested try/catch - inner catches
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

# Nested try/catch - outer catches
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

# Try/catch with command that returns non-zero
_tc_exit=""
try
  _tc_exit="${_tc_exit}A"
  sh -c 'exit 5'
  _tc_exit="${_tc_exit}B"
catch
  _tc_exit="${_tc_exit}C"
end
assert_eq "try/catch exit code" "$_tc_exit" "AC"

# Try/catch with failing command in pipeline - last command matters
_tc_pipe=""
try
  _tc_pipe="${_tc_pipe}A"
  echo "test" | grep "test" > /dev/null
  _tc_pipe="${_tc_pipe}B"
catch
  _tc_pipe="${_tc_pipe}C"
end
assert_eq "try/catch pipeline success" "$_tc_pipe" "AB"

# Try/catch - multiple statements before failure
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

# Try/catch inside if
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

# Try/catch inside while
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

# If inside try
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

# While inside try
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

# Triple nested try
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

# Catch block can have its own logic
_tc_catchlogic=""
try
  false
catch
  if true
    _tc_catchlogic="caught"
  end
end
assert_eq "catch with logic" "$_tc_catchlogic" "caught"

# Variable set in try is visible after
_tc_varscope=""
try
  _tc_varscope="set"
catch
  _tc_varscope="error"
end
assert_eq "try variable scope" "$_tc_varscope" "set"

# Error code captured
try
  sh -c 'exit 42'
catch
  _tc_errcode="$error"
end
assert_eq "error code captured" "$_tc_errcode" "42"

echo ""
echo "========================================"
echo "passed: $PASS"
echo "failed: $FAIL"
if $FAIL == 0
  echo "all tests passed!"
else
  exit 1
end
