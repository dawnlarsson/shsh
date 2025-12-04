PASS=0 FAIL=0

assert_eq() {
  _aeq_name="$1" _aeq_got="$2" _aeq_want="$3"
  if "$_aeq_got" == "$_aeq_want"
    echo "✓ $_aeq_name"; PASS=$((PASS + 1))
  else
    echo "✗ $_aeq_name: got '$_aeq_got', want '$_aeq_want'"; FAIL=$((FAIL + 1))
  end
}

hex_capture() {
  eval "$1" | od -A n -t x1 -v | tr -d ' \n'
}

pass() { echo "✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "✗ $1"; FAIL=$((FAIL + 1)); }

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

map_set config "host" "localhost"
map_set config "port" "8080"
map_get config "host"; assert_eq "map host" "$R" "localhost"
map_get config "port"; assert_eq "map port" "$R" "8080"
map_set config "port" "9000"; map_get config "port"; assert_eq "map overwrite" "$R" "9000"
if map_has config "host"; then pass "map_has existing"; else fail "map_has existing"; fi
if map_has config "invalid_key"; then fail "map_has missing"; else pass "map_has missing"; fi

array_add spaced "hello world"
array_add spaced "foo bar baz"
array_get spaced 0; assert_eq "space value 0" "$R" "hello world"
array_get spaced 1; assert_eq "space value 1" "$R" "foo bar baz"

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
  while [ "$_fib_n" -gt 0 ]; do
    _fib_t=$((_fib_a + _fib_b))
    _fib_a=$_fib_b
    _fib_b=$_fib_t
    _fib_n=$((_fib_n - 1))
  done
  R=$_fib_a
}
fib 10; assert_eq "fib 10" "$R" "55"

tokenize "(add 1 2)" T1
array_len T1; assert_eq "token count simple" "$R" "5"
array_get T1 0; assert_eq "token 0" "$R" "("
array_get T1 1; assert_eq "token 1" "$R" "add"
array_get T1 4; assert_eq "token 4" "$R" ")"
tokenize "(define (f x) (+ x 1))" T2
array_len T2; assert_eq "token count nested" "$R" "12"

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

if file_exists /tmp/shsh_test.txt; then pass "file_exists yes"; else fail "file_exists yes"; fi
if file_exists /tmp/nonexistent_xyz; then fail "file_exists no"; else pass "file_exists no"; fi
if dir_exists /tmp; then pass "dir_exists yes"; else fail "dir_exists yes"; fi
if dir_exists /tmp/nonexistent_xyz; then fail "dir_exists no"; else pass "dir_exists no"; fi

array_clear L1; array_clear L2
array_add L1 "add"; array_add L1 "6"; array_add L1 "4"
array_get L1 0; assert_eq "AST head" "$R" "add"
array_get L1 1; _v1="$R"
array_get L1 2; _v2="$R"
R=$((_v1 + _v2)); assert_eq "AST eval simple" "$R" "10"

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

map_set empty "key" ""
map_get empty "key"; assert_eq "empty string" "$R" ""
if map_has empty "key"; then pass "map_has empty"; else fail "map_has empty"; fi

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

input='(print "a ( b )")'
tokenize "$input" T_QUOTE
array_len T_QUOTE
if "$R" == 4
  pass "tokenizer quotes"
else
  fail "tokenizer quotes (got $R)"
end

array_clear stress
array_add stress "A"
array_set stress 5 "Z"
array_get stress 0; assert_eq "sparse idx 0" "$R" "A"
array_get stress 5; assert_eq "sparse idx 5" "$R" "Z"
array_len stress; assert_eq "sparse len" "$R" "6"

map_set math "zero" 0
map_get math "zero"; assert_eq "zero value" "$R" "0"

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

INJECTED="no"
malicious_index='0; INJECTED="yes"; :'
array_set exploit_arr "$malicious_index" "payload" 2>/dev/null
if [ "$INJECTED" = "yes" ]; then fail "array index injection"
else pass "array index injection blocked"; fi

SAFE_CHECK="ok"
malicious='valid; SAFE_CHECK="pwned"; :'
map_set danger "$malicious" "value" 2>/dev/null
if [ "$SAFE_CHECK" = "ok" ]; then pass "map key injection blocked"
else fail "map key injection"; fi

err_add=$(array_add "bad-name" "val" 2>&1)
if [ -n "$err_add" ]; then pass "array_add reports errors"
else fail "array_add silent fail"; fi

val="x <= y"
if "$val" == "x <= y"
  pass "operator in value"
else
  fail "operator in value"
end

array_clear bounds_test
array_add bounds_test "only"
array_get bounds_test 999
if [ -z "$R" ]; then pass "bounds check empty"
else fail "bounds returned: $R"; fi

tokenize "(print 'hello ( world )')" T_SQ
array_len T_SQ
if "$R" == 4
  pass "tokenizer single quotes"
else
  fail "tokenizer single quotes"
end

tokenize '(test "hello\"world")' T_ESC
array_len T_ESC
if "$R" == 4
  pass "tokenizer escapes"
else
  fail "tokenizer escapes"
end

array_clear del_test
array_add del_test "a"
array_add del_test "b"
array_add del_test "c"
array_delete del_test 1
array_get del_test 1
if [ -z "$R" ]; then pass "array_delete"
else fail "array_delete"; fi
array_get del_test 0; assert_eq "array_delete preserves" "$R" "a"

map_set del_map foo "bar"
map_set del_map baz "qux"
map_delete del_map foo
if map_has del_map foo; then fail "map_delete"
else pass "map_delete"; fi
map_get del_map baz; assert_eq "map_delete preserves" "$R" "qux"

array_clear outer_arr; array_add outer_arr "A"; array_add outer_arr "B"
array_clear inner_arr; array_add inner_arr "1"; array_add inner_arr "2"
nested_count=0
do_inner() { nested_count=$((nested_count + 1)); }
do_outer() { array_for inner_arr do_inner; }
array_for outer_arr do_outer
assert_eq "nested array_for" "$nested_count" "4"

x=0
_while_sum=0
while $x < 5
  _while_sum=$((_while_sum + x))
  x=$((x + 1))
done
assert_eq "while loop" "$_while_sum" "10"

_for_out=""
for i in a b c
  _for_out="$_for_out$i"
done
assert_eq "for loop" "$_for_out" "abc"

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

array_clear test_arr
array_add test_arr ""
array_get test_arr 0
empty_ret=$?
empty_val="$R"
array_get test_arr 999
missing_ret=$?
missing_val="$R"

if [ "$empty_ret" != "$missing_ret" ]; then
  pass "can distinguish empty from missing via return code"
else
  fail "empty (ret=$empty_ret) vs missing (ret=$missing_ret) indistinguishable"
fi

array_clear sparse
array_add sparse "idx0"
array_set sparse 10 "idx10"
array_len sparse
if [ "$R" -ge 10 ]; then
  pass "array_len accounts for sparse set (len=$R)"
else
  fail "array_len is $R, but idx 10 exists"
fi
array_get sparse 10
if [ "$R" = "idx10" ]; then
  pass "sparse value retrievable"
else
  fail "sparse value lost"
fi

val="a == b"
if is "\"$val\" == \"a == b\""; then
  pass "operator in value handled"
else
  fail "operator in value mis-parsed"
fi

val2="x <= y"
if is "\"$val2\" == \"x <= y\""; then
  pass "comparison op in value handled"
else
  fail "comparison op in value mis-parsed"
fi

tricky="5 < 10"
if is "\"$tricky\" == \"5 < 10\""; then
  pass "full expression as value"
else
  fail "full expression as value failed"
fi

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

map_set badmap "key-with-dash" "value" 2>/dev/null
ret=$?
if [ $ret -ne 0 ]; then
  pass "map rejects invalid key"
else
  map_get badmap "key-with-dash"
  if [ -z "$R" ]; then
    pass "map rejects invalid key (silent)"
  else
    fail "map accepted invalid key"
  fi
fi

array_clear exit_test
array_add exit_test "a"
array_add exit_test "b" 
array_add exit_test "c"
exit_count=0
try_break() {
  exit_count=$((exit_count + 1))
  [ "$R" = "b" ] && return 1
}
array_for exit_test try_break
if [ "$exit_count" -eq 3 ]; then
  fail "array_for ignores callback return (no break support)"
else
  pass "array_for respects callback return"
fi

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
if [ "$result" = "1xp1xq1y2" ]; then
  pass "3-level nested switch"
else
  fail "3-level nested switch: got '$result'"
fi

ml="line1
line2"
ml2="line1
line2"
if is "\"$ml\" == \"$ml2\""
  pass "multiline comparison"
else
  fail "multiline comparison"
end

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

rm -f /tmp/shsh_test.txt /tmp/shsh_test2.txt

echo ""
echo "passed: $PASS"
echo "failed: $FAIL"
if "$FAIL" == 0
  echo "all tests passed!"
else
  exit 1
end