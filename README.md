# shsh

Self-hosting shell transpiler with a beautifully simple high level syntax for POSIX shells.

Passing 618 tests.

Write expressive shell scripts that compile to portable POSIX sh.

```sh
# shsh syntax
if $count > 0
  result = str_before "$input" ":"
  echo "Found: $result"
end

# compiles to POSIX sh
if [ "$count" -gt "0" ]; then
  str_before "$input" ":"; result="$R"
  echo "Found: $result"
fi
```

## Features

- **Clean Syntax** — `if`/`elif`/`else`/`end`, `switch`/`case`/`default`/`end`, `try`/`catch`/`end`
- **Comparisons** — `==`, `!=`, `<`, `>`, `<=`, `>=` for strings and numbers
- **Arithmetic** — `i++`, `i--`, `i += 5`, `i -= 3`, `i *= 2`, `i /= 4`, `i %= 3`
- **Assignment Capture** — `result = str_before "$s" ":"` captures function results
- **Single-line Forms** — `if $x > 0: echo "yes"`, `while $i < 10: i++`
- **Try/Catch** — Error handling with automatic propagation
- **Arrays** — Dynamic arrays with iteration support
- **Maps** — Key-value stores with enumeration
- **Strings** — Pattern matching, splitting, trimming
- **Files** — Reading, writing, line iteration
- **Binary Output** — Raw byte writing for binary file generation
- **Tokenizer** — Built-in s-expression parser
- **Standalone Emit** — Generate dependency-free scripts with automatic tree-shaking
- **Self-hosting** — shsh is written in shsh

## Install

```sh
curl -fsSL https://sh.dawn.day | sh
```

Or manually:
```sh
curl -o /usr/local/bin/shsh https://raw.githubusercontent.com/dawnlarsson/shsh/main/shsh.sh
chmod +x /usr/local/bin/shsh
```

## Quick Start

Create `hello.shsh`:
```sh
#!/usr/bin/env shsh

name="world"
if "$1" != ""
  name="$1"
end

echo "Hello, $name!"
```

Run it:
```sh
shsh hello.shsh          # Hello, world!
shsh hello.shsh Alice    # Hello, Alice!
```

Generate standalone POSIX script:
```sh
shsh build hello.shsh > hello.sh
chmod +x hello.sh
./hello.sh               # runs without shsh installed
```

## Usage

```sh
shsh script.shsh            # run script
shsh build script.shsh      # emit standalone POSIX script (tree-shaken)
shsh build_full script.shsh # emit standalone with full runtime
shsh raw script.shsh        # transform only
shsh -                      # read from stdin
shsh install                # install to system
shsh uninstall              # remove from system
shsh update                 # update from github
shsh version
```

if shsh doesn't receive any of the arguments above or a file path, it's assumed
the rest of the arguments is an inline script. If the result is in `$R`, it's printed automatically.
```sh
$ shsh echo "this is an inline script"
this is an inline script

$ shsh file_hash README.md
b45208b09b3d702a6606920bdc60f85786b3127c92451b1d5ced88b11bfeb408

$ shsh file_exists README.md && echo yes!
yes!
```

---

# Syntax Reference

## Conditionals

### Multi-line
```sh
if $x < 10
  echo "small"
elif $x < 100
  echo "medium"
else
  echo "large"
end
```

### Single-line
```sh
if $x < 10: echo "small"
elif $x < 100: echo "medium"
else: echo "large"
```

### Comparison Operators

| Operator | Meaning |
|----------|---------|
| `==` | equal |
| `!=` | not equal |
| `<` | less than |
| `>` | greater than |
| `<=` | less or equal |
| `>=` | greater or equal |

Works with both strings and numbers:
```sh
if "$name" == "alice": echo "hi alice"
if $count > 0: echo "has items"
if $version >= 2: echo "v2 or later"
```

### Boolean Expressions

Variables are truthy if non-empty:
```sh
if $enabled
  echo "feature is on"
end

if ! $disabled
  echo "not disabled"
end
```

### Chained Conditions

Combine multiple conditions with `&&` (and) or `||` (or):
```sh
if $x > 0 && $x < 100
  echo "x is between 0 and 100"
end

if "$mode" == "dev" || "$mode" == "test"
  echo "non-production mode"
end

if $enabled && "$name" != ""
  echo "enabled with name"
end
```

Works with single-line syntax too:
```sh
if $a == 1 && $b == 2: echo "both match"
```

### Shell Tests

Use standard shell commands for file tests:
```sh
if [ -f "$file" ]
  echo "file exists"
end

if command -v git >/dev/null
  echo "git is installed"
end
```

---

## Switch/Case

### Multi-line
```sh
switch $command
case start
  start_server
case stop
  stop_server
case restart
  stop_server
  start_server
case status|info
  show_status
default
  echo "Unknown command: $command"
  exit 1
end
```

### Single-line
```sh
switch $opt
case -h|--help: show_help
case -v|--version: show_version
case -q|--quiet: quiet=1
default: echo "Unknown option"
end
```

### Pattern Matching

Case patterns support shell glob syntax:
```sh
switch $file
case *.txt: handle_text
case *.jpg|*.png: handle_image
case test_*: run_test
default: handle_other
end
```

---

## Loops

### While Loop
```sh
i=0
while $i < 10
  echo $i
  i++
done
```

### Single-line While
```sh
while $i < 10: i++
```

### For Loop
```sh
for file in *.txt
  echo "Processing: $file"
done

for i in 1 2 3 4 5
  echo $i
done
```

---

## Try/Catch

Handle errors gracefully:
```sh
try
  cd "$directory"
  rm -rf temp/
  process_files
catch
  echo "Error occurred (exit code: $error)"
  cleanup
end
```

### Silent Error Handling

Ignore errors without catching:
```sh
try
  might_fail
  might_also_fail
end
echo "continues regardless of errors"
```

### Nested Try/Catch
```sh
try
  try
    risky_inner_operation
  catch
    echo "Inner failed: $error"
    fallback_operation
  end
  outer_operation
catch
  echo "Outer failed: $error"
end
```

---

## Testing

Write tests using the `test` block syntax:

```sh
test "my feature works" {
  result="hello"
  test_equals "$result" "hello"
}

test "math is correct" {
  sum=$((2 + 2))
  test_equals "$sum" "4"
}
```

### Test Assertions

```sh
test_equals "$actual" "$expected"       # pass if equal
test_not_equals "$actual" "$unexpected" # pass if not equal
test_true "$value"                      # pass if value is "true" or "1"
test_false "$value"                     # pass if value is "false" or "0"
test_ok                                 # pass if last command succeeded ($? == 0)
test_err                                # pass if last command failed ($? != 0)
```

### String Assertions

```sh
test_contains "$haystack" "$needle"     # pass if haystack contains needle
test_starts "$string" "$prefix"         # pass if string starts with prefix
test_ends "$string" "$suffix"           # pass if string ends with suffix
```

### File Assertions

```sh
test_file_exists "/path/to/file"        # pass if regular file exists
test_dir_exists "/path/to/dir"          # pass if directory exists
```

### Manual Pass/Fail

```sh
test_pass                               # explicitly pass
test_fail                               # explicitly fail
```

### Example: Testing a Function

```sh
add() {
  R=$(($1 + $2))
}

test "add positive numbers" {
  add 2 3
  test_equals "$R" "5"
}

test "add negative numbers" {
  add -5 3
  test_equals "$R" "-2"
}

test "add zero" {
  add 0 0
  test_equals "$R" "0"
}
```

---

## Arithmetic

### Increment/Decrement
```sh
i++          # i = i + 1
i--          # i = i - 1
```

### Compound Assignment
```sh
i += 5       # i = i + 5
i -= 3       # i = i - 3
i *= 2       # i = i * 2
i /= 4       # i = i / 4
i %= 3       # i = i % 3
```

### In Expressions
```sh
count=0
while $count < 100
  count++
done

sum=0
for n in 1 2 3 4 5
  sum += $n
done
echo "Sum: $sum"   # 15
```

---

## Assignment Capture

Capture results from functions that set `$R`:
```sh
# Instead of:
str_before "$path" "/"; dir="$R"

# Write:
dir = str_before "$path" "/"
```

The transpiler converts `var = func args` to `func args; var="$R"`.

### Examples
```sh
# String extraction
filename = str_after_last "$path" "/"
extension = str_after_last "$filename" "."
basename = str_before_last "$filename" "."

# Chained operations
input="  hello world  "
trimmed = str_trim "$input"
first_word = str_before "$trimmed" " "

# Array operations
array_get items 0
first = str_trim "$R"    # mixed style also works
```

### When It Doesn't Apply

Regular assignment syntax passes through unchanged:
```sh
x="literal"          # normal assignment
y=$variable          # variable assignment
z=$(command)         # command substitution
path="/usr/bin"      # string with special chars
```

---

## Arrays

### Creating and Modifying
```sh
# Add elements
array_add fruits "apple"
array_add fruits "banana"
array_add fruits "cherry"

# Get element (result in $R)
array_get fruits 0           # R="apple"
array_get fruits 2           # R="cherry"

# Set element at index
array_set fruits 1 "blueberry"

# Get length
array_len fruits             # R=3
```

### Using Results
```sh
array_get fruits 0
echo "First fruit: $R"

# Or with assignment capture:
first = array_get fruits 0
echo "First fruit: $first"
```

### Removing Elements
```sh
array_delete fruits 1        # remove index 1, shift remaining down
array_remove fruits 1        # same as array_delete
array_unset fruits 1         # remove index 1, leave hole (sparse)
array_clear fruits           # remove all elements (fast, keeps storage)
array_clear_full fruits      # remove all and free storage
```

### Iteration
```sh
print_fruit() {
  echo "Fruit: $R"
}
array_for fruits print_fruit
```

Output:
```
Fruit: apple
Fruit: blueberry
Fruit: cherry
```

### Early Exit

Return non-zero from callback to stop iteration:
```sh
find_banana() {
  if "$R" == "banana"
    echo "Found it!"
    return 1    # stop iteration
  end
  return 0      # continue
}
array_for fruits find_banana
```

### Building Arrays from Data
```sh
# From file lines
file_lines /etc/hosts hosts_arr

# From command output
while IFS= read -r line; do
  array_add lines "$line"
done < "$file"
```

---

## Maps

### Creating and Accessing
```sh
# Set values
map_set config "host" "localhost"
map_set config "port" "8080"
map_set config "debug" "true"

# Get value (result in $R)
map_get config "host"        # R="localhost"

# Check existence
if map_has config "debug"
  echo "Debug mode configured"
end

# Delete key
map_delete config "debug"

# Clear all
map_clear config
```

**Note:** Keys must contain only alphanumeric characters and underscores.

### Iteration

Iterate over entries (K=key, R=value):
```sh
print_config() {
  echo "$K = $R"
}
map_for config print_config
```

Output:
```
host = localhost
port = 8080
```

### Get Keys as Array
```sh
map_keys config keys_arr
array_for keys_arr print_key
```

### Example: Configuration File
```sh
# Parse simple key=value config
parse_config() {
  while IFS= read -r line || [ -n "$line" ]; do
    if str_contains "$line" "="
      key = str_before "$line" "="
      value = str_after "$line" "="
      map_set config "$key" "$value"
    end
  done < "$1"
}

parse_config "app.conf"
map_get config "database_url"
echo "Database: $R"
```

---

## Strings

### Testing
```sh
str_starts "hello world" "hello"    # returns 0 (true)
str_ends "file.txt" ".txt"          # returns 0 (true)
str_contains "hello" "ell"          # returns 0 (true)
```

Use in conditionals:
```sh
if str_starts "$url" "https://"
  echo "Secure URL"
end

if str_ends "$file" ".sh"
  echo "Shell script"
end
```

### Extraction

All extraction functions set `$R` and return non-zero if delimiter not found:
```sh
str_before "user@host" "@"          # R="user"
str_after "user@host" "@"           # R="host"
str_before_last "a.b.c" "."         # R="a.b"
str_after_last "a.b.c" "."          # R="c"
```

### Trimming
```sh
str_ltrim "  hello"                 # R="hello"
str_rtrim "hello  "                 # R="hello"
str_trim "  hello  "                # R="hello"
str_indent "    code"               # R="    " (leading whitespace only)
```

### Example: Path Parsing
```sh
path="/home/user/documents/report.pdf"

dirname = str_before_last "$path" "/"
filename = str_after_last "$path" "/"
basename = str_before_last "$filename" "."
extension = str_after_last "$filename" "."

echo "Directory: $dirname"      # /home/user/documents
echo "Filename: $filename"      # report.pdf
echo "Basename: $basename"      # report
echo "Extension: $extension"    # pdf
```

### Example: URL Parsing
```sh
url="https://example.com:8080/path/to/page?query=1"

protocol = str_before "$url" "://"
rest = str_after "$url" "://"
host_port = str_before "$rest" "/"
path_query = str_after "$rest" "/"

if str_contains "$host_port" ":"
  host = str_before "$host_port" ":"
  port = str_after "$host_port" ":"
else
  host="$host_port"
  port="80"
end

echo "Host: $host, Port: $port"   # Host: example.com, Port: 8080
```

---

## Files

### Reading and Writing
```sh
file_read /etc/hostname              # R=contents (preserves newlines)
file_write /tmp/out.txt "content"    # write (overwrites)
file_append /tmp/out.txt "more"      # append
file_hash /somefile.txt              # file hash
```

### File Tests
```sh
file_exists /tmp/file.txt            # true if regular file exists
dir_exists /tmp                      # true if directory exists
file_executable /usr/bin/sh          # true if executable
path_writable /tmp                   # true if writable
```

### Line Processing
```sh
# Load all lines into array
file_lines /etc/hosts lines
array_len lines
echo "File has $R lines"

# Process each line with callback
process_line() {
  echo "Line: $R"
}
file_each /etc/hosts process_line
```

### Example: Log Processing
```sh
count_errors() {
  errors=0
  check_line() {
    if str_contains "$R" "ERROR"
      errors=$((errors + 1))
    end
  }
  file_each "$1" check_line
  echo "Found $errors errors"
}

count_errors /var/log/app.log
```

---

## Defaults

Set variables only when needed:
```sh
default host "localhost"       # set if empty string or unset
default_unset port "8080"      # set only if completely unset
```

Difference:
```sh
value=""
default value "fallback"       # value becomes "fallback"
default_unset value "fallback" # value stays "" (empty but set)
```

### Example: Configuration with Defaults
```sh
# Allow environment overrides
default DATABASE_HOST "localhost"
default DATABASE_PORT "5432"
default DATABASE_NAME "myapp"

connection="$DATABASE_HOST:$DATABASE_PORT/$DATABASE_NAME"
```

---

## Tokenizer

Parse s-expressions and quoted strings:
```sh
tokenize "(add (mul 2 3) 4)" tokens

array_len tokens                # R=8
array_get tokens 0              # R="("
array_get tokens 1              # R="add"
array_get tokens 2              # R="("
array_get tokens 3              # R="mul"
```

Handles:
- Parentheses as separate tokens
- Quoted strings (preserves quotes)
- Whitespace separation
- Nested structures

### Example: Simple Expression Evaluator
```sh
tokenize "$expr" tokens

array_get tokens 0
if "$R" == "("
  array_get tokens 1
  op="$R"
  # ... evaluate based on operator
end
```

---

## Binary Output

Write raw bytes for binary file generation:
```sh
# Write bytes (decimal, hex, or string)
bit_8 0x7f 0x45 0x4c 0x46       # ELF magic number
bit_8 "Hello"                    # string as bytes
bit_8 65 66 67                   # decimal (ABC)

# Multi-byte values (little-endian by default)
bit_16 0x1234                    # 2 bytes: 34 12
bit_32 0xAABBCCDD                # 4 bytes: DD CC BB AA
bit_64 0x1122334455667788        # 8 bytes
bit_128 0x00112233...            # 16 bytes (pass as hex string)

# Big-endian
ENDIAN=big bit_32 0xAABBCCDD     # 4 bytes: AA BB CC DD
```

### Example: Create Binary File
```sh
{
  bit_8 0x7f "ELF"               # ELF magic
  bit_8 2 1 1 0                  # 64-bit, little-endian, version, OS
  bit_8 0 0 0 0 0 0 0 0          # padding
  bit_16 2                       # executable
  bit_16 0x3e                    # x86-64
} > program.bin
```

---

## Standalone Scripts

Generate portable POSIX scripts that run without shsh:

```sh
shsh -e script.shsh > standalone.sh
chmod +x standalone.sh
./standalone.sh    # works on any POSIX system
```

### Tree Shaking

The `-e` flag automatically includes only the runtime functions your script uses:
```sh
# If your script only uses str_before and array_add,
# only those functions are included in the output
shsh -e minimal.shsh > minimal.sh
```

### Full Runtime

Include the complete runtime (useful for dynamic usage):
```sh
shsh -E script.shsh > full.sh
```

---

## Building shsh

shsh is self-hosting (written in shsh):

```sh
# Rebuild from source
./shsh.sh raw shsh.shsh > _shsh.sh && mv _shsh.sh shsh.sh && chmod +rwx shsh.sh

# Run tests
./shsh.sh repo/test.sh
```

---

## Examples

### Command-Line Tool
```sh
#!/usr/bin/env shsh

show_help() {
  echo "Usage: mytool [options] <file>"
  echo "  -h, --help     Show help"
  echo "  -v, --verbose  Verbose output"
  echo "  -o FILE        Output file"
}

verbose=0
output=""

while [ $# -gt 0 ]
  switch $1
  case -h|--help
    show_help
    exit 0
  case -v|--verbose
    verbose=1
  case -o
    shift
    output="$1"
  case -*
    echo "Unknown option: $1"
    exit 1
  default
    input="$1"
  end
  shift
done

if "$input" == ""
  echo "Error: no input file"
  exit 1
end

if $verbose == 1
  echo "Processing: $input"
end

# ... process file
```

### Configuration Parser
```sh
#!/usr/bin/env shsh

load_config() {
  if ! file_exists "$1"
    echo "Config not found: $1"
    return 1
  end
  
  parse_line() {
    # Skip comments and empty lines
    if str_starts "$R" "#": return 0
    trimmed = str_trim "$R"
    if "$trimmed" == "": return 0
    
    # Parse key=value
    if str_contains "$trimmed" "="
      key = str_before "$trimmed" "="
      value = str_after "$trimmed" "="
      map_set config "$key" "$value"
    end
  }
  
  file_each "$1" parse_line
}

load_config "app.conf"

# Use with defaults
map_get config "port"
default R "8080"
port="$R"

echo "Running on port $port"
```

### Simple HTTP Response Parser
```sh
#!/usr/bin/env shsh

parse_headers() {
  # First line is status
  status = str_before "$1" "\n"
  rest = str_after "$1" "\n"
  
  # Parse status code
  code = str_after "$status" " "
  code = str_before "$code" " "
  
  echo "Status code: $code"
  
  # Parse headers until empty line
  while str_contains "$rest" ": "
    line = str_before "$rest" "\n"
    if "$line" == "": break
    
    header = str_before "$line" ": "
    value = str_after "$line" ": "
    map_set headers "$header" "$value"
    
    rest = str_after "$rest" "\n"
  done
}

# Example usage
response="HTTP/1.1 200 OK
Content-Type: text/html
Content-Length: 1234

<html>..."

parse_headers "$response"
map_get headers "Content_Type"  # Note: headers normalized to valid key names
```

---

## License
Logos, Branding, Trademarks - Copyright Dawn Larsson 2022

Repository: Apache-2.0 license
