# shsh
Arrays, Maps & modern syntax for POSIX shells.

### Install
```sh
curl -fsSL https://sh.dawn.day | sh
```

Or manually:
```sh
curl -o /usr/local/bin/shsh https://raw.githubusercontent.com/user/shsh/main/shsh.sh
chmod +x /usr/local/bin/shsh
```

### Usage
```sh
shsh script.sh           # run script
shsh -c 'code'           # run inline
shsh -e script.sh        # emit standalone POSIX
shsh -t script.sh        # transform only (no toolkit)
```

---

## Syntax

### Conditionals
```sh
# multi-line
if $x <= 10
  echo "low"
elif $x > 20
  echo "high"
else
  echo "mid"
end

# single-line
if $x <= 10:  echo "low"
elif $x > 20: echo "high"
else:         echo "mid"
```

Operators: `==` `!=` `<` `>` `<=` `>=`

Works with strings and numbers:
```sh
if "$name" == "alice": echo "hi alice"
if $count > 0: echo "has items"
```
---

### Switch
```sh
# multi-line
switch $opt
case a
  run_a
case b|c
  run_bc
default
  exit 1
end

# single-line
switch $opt
case a:   run_a
case b|c: run_bc
default:  exit 1
end
```

---

### Loops
```sh
while $i < 10
  echo $i
  i++
done

for x in a b c
  echo $x
done
```

---

### Arithmetic Operators
```sh
i++          # increment
i--          # decrement
i += 5       # add
i -= 3       # subtract
i *= 2       # multiply
i /= 4       # divide
i %= 3       # modulo
```

---

## Arrays
```sh
array_add arr "first"
array_add arr "second"
array_add arr "third"

array_get arr 0          # R="first"
array_get arr 2          # R="third"
array_len arr            # R=3

array_set arr 1 "SECOND"
array_get arr 1          # R="SECOND"

array_delete arr 1       # remove index 1, shifts elements down
array_unset arr 1        # remove index 1, leaves hole (sparse)
array_clear arr          # remove all
```

---

### Iteration
```sh
print_item() {
  echo "item: $R"
}
array_for arr print_item
```

Return non-zero to break early:
```sh
find_it() {
  [ "$R" = "target" ] && return 1
  return 0
}
array_for arr find_it
```

---

## Maps
```sh
map_set config host "localhost"
map_set config port "8080"

map_get config host      # R="localhost"
map_get config port      # R="8080"

map_has config host      # returns 0 (true)
map_has config missing   # returns 1 (false)

map_delete config port
map_clear config         # remove all keys
```

Keys must be alphanumeric with underscores.
---

### Enumeration
```sh
# get all keys as array
map_keys config keys_arr
array_for keys_arr print_key

# iterate directly (K=key, R=value)
print_entry() {
  echo "$K = $R"
}
map_for config print_entry
```

---

## Defaults
```sh
default host "localhost"       # set if empty or unset
default_unset port "8080"      # set only if unset (preserves empty)
```
---

## Files
```sh
file_read /etc/hostname           # R=contents
file_write /tmp/out.txt "data"
file_append /tmp/out.txt "more"

file_lines /tmp/data.txt lines    # array 'lines' with each line
file_each /tmp/data.txt callback  # call function per line, R=line

file_exists /tmp/foo              # returns 0/1
dir_exists /tmp                   # returns 0/1
```

---

## Tokenizer

For parsing s-expressions or similar:
```sh
tokenize "(add 1 2)" tokens
array_len tokens         # R=5
array_get tokens 0       # R="("
array_get tokens 1       # R="add"
array_get tokens 2       # R="1"
```

Handles quoted strings and nested parens.

---

## Binary Output

Write raw bytes for binary file generation:
```sh
bit_8 0x7f 0x45 0x4c 0x46    # ELF magic
bit_8 "ABC"                   # string bytes
bit_8 65 66 67                # decimal

bit_16 0x1234                 # 2 bytes
bit_32 0xAABBCCDD             # 4 bytes
bit_64 0x1122334455667788     # 8 bytes
bit_128 0x00112233...         # 16 bytes (hex string)
```

---

## How it works

shsh transforms syntax sugar to POSIX shell, then evals a toolkit providing arrays/maps.

```sh
# input
if $x < 10: echo "small"

# transformed
if is "$x < 10"; then
  echo "small"
fi
```

Generate standalone scripts with `-e`:
```sh
shsh -e script.sh > standalone.sh
./standalone.sh  # no shsh dependency
```

Apache 2.0
