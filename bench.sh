#!/usr/bin/env sh
# shsh benchmarks

N=1000
echo "=== shsh benchmark (n=$N) ==="

time_it() {
  _start=$(date +%s%N 2>/dev/null || date +%s)
  eval "$2"
  _end=$(date +%s%N 2>/dev/null || date +%s)
  if [ ${#_start} -gt 10 ]; then
    _ms=$(( (_end - _start) / 1000000 ))
    printf "%-25s %d ms\n" "$1" "$_ms"
  else
    printf "%-25s %d s\n" "$1" $((_end - _start))
  fi
}

# array_add
bench_array_add() {
  array_clear bench_arr
  i=0; while [ $i -lt $N ]; do
    array_add bench_arr "item$i"
    i=$((i+1))
  done
}
time_it "array_add x$N" bench_array_add

# array_get (sequential)
bench_array_get() {
  i=0; while [ $i -lt $N ]; do
    array_get bench_arr $i
    i=$((i+1))
  done
}
time_it "array_get x$N" bench_array_get

# array_set
bench_array_set() {
  i=0; while [ $i -lt $N ]; do
    array_set bench_arr $i "new$i"
    i=$((i+1))
  done
}
time_it "array_set x$N" bench_array_set

# array_for
bench_for_count=0
bench_for_cb() { bench_for_count=$((bench_for_count+1)); }
time_it "array_for x$N" "array_for bench_arr bench_for_cb"

# map_set
bench_map_set() {
  i=0; while [ $i -lt $N ]; do
    map_set bench_map "key$i" "val$i"
    i=$((i+1))
  done
}
time_it "map_set x$N" bench_map_set

# map_get
bench_map_get() {
  i=0; while [ $i -lt $N ]; do
    map_get bench_map "key$i"
    i=$((i+1))
  done
}
time_it "map_get x$N" bench_map_get

# is() comparisons
bench_is() {
  i=0; while [ $i -lt $N ]; do
    is "$i < 1000"
    i=$((i+1))
  done
}
time_it "is() x$N" bench_is

# tokenize
bench_tokenize() {
  i=0; while [ $i -lt 100 ]; do
    tokenize "(define (factorial n) (if (<= n 1) 1 (* n (factorial (- n 1)))))" T
    array_clear T
    i=$((i+1))
  done
}
time_it "tokenize x100" bench_tokenize

# bit_8 (string construction)
bench_bit_8() {
  i=0; while [ $i -lt $N ]; do
    bit_8 0x01 0x02 0x03 0x04 0x05 >/dev/null
    i=$((i+1))
  done
}
time_it "bit_8 x$N (5 args)" bench_bit_8

# bit_32 (hex math)
bench_bit_32() {
  i=0; while [ $i -lt $N ]; do
    bit_32 0xAABBCCDD >/dev/null
    i=$((i+1))
  done
}
time_it "bit_32 x$N" bench_bit_32

echo ""
echo "=== memory (vars created) ==="
set | grep -c "^__shsh_" || echo "0"