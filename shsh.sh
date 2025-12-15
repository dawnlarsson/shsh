
VERSION="0.1.0"
DEBUG=1

_index=0        # line number
_indent=0       # indent level
_line=""        # content after indent
_word=""        # first word
_rest=""        # rest of line after first word

dbg_print() {
  printf '%4d  ' $_index

  i=0
  while [ "$i" -lt "$_indent" ]; do
    case $((i % 7)) in
    0)printf '\033[38;5;17m░░\033[0m';;
    1)printf '\033[38;5;23m░░\033[0m';;
    2)printf '\033[38;5;22m░░\033[0m';;
    3)printf '\033[38;5;58m░░\033[0m';;
    4)printf '\033[38;5;94m░░\033[0m';;
    5)printf '\033[38;5;53m░░\033[0m';;
    6)printf '\033[38;5;236m░░\033[0m';;
    esac
    i=$((i + 1))
  done

  case $_word in
  "if"|"elif"|"else"|"while"|"for"|"switch"|"case"|"default"|"end"|"return"|"break"|"continue")
    printf '\033[38;5;33m%s\033[0m' "$_word"
    ;;
  "#"*)
    printf '\033[38;5;240m%s %s\033[0m' "$_word" "$_rest"
    _rest=""
    ;;
  *"="*)
    printf '\033[38;5;37m%s\033[0m' "$_word"
    ;;
  *)
    printf '%s' "$_word"
  ;;esac

  if [ -n "$_rest" ]; then
    printf ' %s' "$_rest"
  fi
  printf '\n'
}

compile() {
  _index=0
  while IFS= read -r _line || [ -n "$_line" ]; do
    _index=$((_index + 1))
    _tabs="${_line%%[!	]*}"
    _indent=${#_tabs}

    _line="${_line#"$_tabs"}"
    _word="${_line%% *}"
    _rest="${_line#"$_word"}"
    _rest="${_rest# }"

    if [ "$DEBUG" = 1 ]; then
      dbg_print
    fi
  done
}

compile < "$1"
