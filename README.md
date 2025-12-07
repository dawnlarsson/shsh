# shsh
Self-hosting shell transpiler with a beautifully simple high level syntax for POSIX shells.

Passing all 449 tests.

- **Clean Syntax** — `if`/`elif`/`else`/`end`, `switch`/`case`/`default`/`end`, `try`/`catch`/`end`
- **Comparisons** — `==`, `!=`, `<`, `>`, `<=`, `>=` for strings and numbers
- **Arithmetic** — `i++`, `i--`, `i += 5`, `i -= 3`, `i *= 2`, `i /= 4`, `i %= 3`
- **Single-line Forms** — `if $x > 0: echo "yes"`, `case a: run_a`
- **Try/Catch** — Error handling with `try`/`catch`/`end` blocks
- **Arrays** — `array_add`, `array_get`, `array_set`, `array_len`, `array_for`, `array_delete`
- **Maps** — `map_set`, `map_get`, `map_has`, `map_for`, `map_keys`, `map_delete`
- **Strings** — `str_starts`, `str_ends`, `str_contains`, `str_before`, `str_after`, `str_trim`
- **Files** — `file_read`, `file_write`, `file_lines`, `file_each`, `file_exists`, `dir_exists`
- **Defaults** — `default var "value"`, `default_unset var "value"`
- **Binary Output** — `bit_8`, `bit_16`, `bit_32`, `bit_64`, `bit_128` for raw byte writing
- **Tokenizer** — `tokenize` for parsing s-expressions and quoted strings
- **Self-hosting** — shsh is written in shsh
- **Standalone Emit** — Generate dependency-free POSIX scripts with `shsh -e` & automatic tree-shaking

### Install
```sh
curl -fsSL https://sh.dawn.day | sh
```

Or manually:
```sh
curl -o /usr/local/bin/shsh https://raw.githubusercontent.com/dawnlarsson/shsh/main/shsh.sh
chmod +x /usr/local/bin/shsh
```

### Usage
```sh
shsh script.sh           # run script
shsh -c 'code'           # run inline
shsh -e script.sh        # emit standalone POSIX
shsh -t script.sh        # transform only (no toolkit)
```

### Building shsh itself
```sh
sh shsh.sh -t shsh.shsh > _shsh.sh && mv _shsh.sh shsh.sh && chmod +rwx shsh.sh
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

### Try/Catch
```sh
try
  echo "attempting risky operation"
  might_fail
  echo "success"
catch
  echo "caught error with exit code: $error"
end
```

Try without catch (silently ignore errors):
```sh
try
  might_fail
  might_also_fail
end
echo "continues regardless"
```

Nested try/catch:
```sh
try
  try
    inner_operation
  catch
    echo "inner failed: $error"
  end
  outer_operation
catch
  echo "outer failed: $error"
end
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

## Strings

### Testing
```sh
str_starts "hello world" "hello"   # returns 0 (true)
str_ends "file.txt" ".txt"         # returns 0 (true)
str_contains "hello" "ell"         # returns 0 (true)
```

### Extraction
```sh
str_after "path/to/file" "/"       # R="to/file" (after first)
str_before "key=value" "="         # R="key" (before first)
str_after_last "a/b/c" "/"         # R="c" (after last)
str_before_last "a.b.c" "."        # R="a.b" (before last)
```

Returns non-zero if delimiter not found.

### Trimming
```sh
str_ltrim "  hello"                # R="hello"
str_rtrim "hello  "                # R="hello"
str_trim "  hello  "               # R="hello"
str_indent "  hello"               # R="  " (leading whitespace)
```

### Example: Path parsing
```sh
path="/home/user/file.txt"
str_after_last "$path" "/"; filename="$R"   # file.txt
str_before_last "$path" "/"; dirname="$R"   # /home/user
str_after_last "$filename" "."; ext="$R"    # txt
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
