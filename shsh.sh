#!/bin/sh
VERSION="0.12.0"

TOOLKIT='
_shsh_sq=$(printf "\\047")
_shsh_dq=$(printf "\\042")

_shsh_check_name() {
  case "$1" in
    "" | *[!a-zA-Z0-9_]*)
      printf "shsh error: invalid name/key \"%s\"\n" "$1" >&2
      return 1
      ;;
  esac
}

_shsh_check_int() {
  case "$1" in
    "" | *[!0-9]*)
      printf "shsh error: invalid integer \"%s\"\n" "$1" >&2
      return 1
      ;;
  esac
}

array_set() {
  _shsh_check_name "$1" || return 1
  _shsh_check_int "$2" || return 1
  eval "__shsh_${1}_$2=\"\$3\""
  eval "[ $2 -ge \${__shsh_${1}_n:-0} ]" && eval "__shsh_${1}_n=$(($2 + 1))"
}

array_get() {
  case "$1" in "" | *[!a-zA-Z0-9_]*) return 1 ;; esac
  case "$2" in "" | *[!0-9]*) return 1 ;; esac
  eval "R=\"\${__shsh_${1}_$2}\"; [ -n \"\${__shsh_${1}_$2+x}\" ]"
}

array_len() {
  _shsh_check_name "$1" || return 1
  eval "R=\"\${__shsh_${1}_n:-0}\""
}

array_add() {
  _shsh_check_name "$1" || return 1
  eval "_aa_idx=\${__shsh_${1}_n:-0}"
  eval "__shsh_${1}_$_aa_idx=\"\$2\"; __shsh_${1}_n=$((_aa_idx + 1))"
}

array_for() {
  _shsh_check_name "$1" || return 1
  _af_d=${_af_d:--1}; _af_d=$((_af_d + 1))
  eval "_af_len_$_af_d=\"\${__shsh_${1}_n:-0}\""
  eval "_af_i_$_af_d=0"
  while eval "[ \$_af_i_$_af_d -lt \$_af_len_$_af_d ]"; do
    eval "_af_idx=\$_af_i_$_af_d"
    eval "R=\"\${__shsh_${1}_$_af_idx}\""
    "$2" || { _af_d=$((_af_d - 1)); return 0; }
    eval "_af_i_$_af_d=\$((\$_af_i_$_af_d + 1))"
  done
  _af_d=$((_af_d - 1))
}

array_clear() {
  _shsh_check_name "$1" || return 1
  eval "_ac_len=\"\${__shsh_${1}_n:-0}\""
  _ac_i=0
  while [ "$_ac_i" -lt "$_ac_len" ]; do
    eval "unset __shsh_${1}_$_ac_i"
    _ac_i=$((_ac_i + 1))
  done
  eval "__shsh_${1}_n=0"
}

array_unset() {
  _shsh_check_name "$1" || return 1
  _shsh_check_int "$2" || return 1
  eval "unset __shsh_${1}_$2"
}

array_remove() {
  _shsh_check_name "$1" || return 1
  _shsh_check_int "$2" || return 1
  eval "_ar_len=\"\${__shsh_${1}_n:-0}\""
  [ "$2" -ge "$_ar_len" ] && return 1
  _ar_i=$2
  while [ "$((_ar_i + 1))" -lt "$_ar_len" ]; do
    eval "__shsh_${1}_$_ar_i=\"\${__shsh_${1}_$((_ar_i + 1))}\""
    _ar_i=$((_ar_i + 1))
  done
  eval "unset __shsh_${1}_$((_ar_len - 1))"
  eval "__shsh_${1}_n=$((_ar_len - 1))"
}

array_delete() { array_remove "$@"; }

map_set() {
  _shsh_check_name "$1" || return 1
  _shsh_check_name "$2" || return 1
  eval "__shsh_map_${1}_${2}=\"\$3\""
}

map_get() {
  _shsh_check_name "$1" || return 1
  _shsh_check_name "$2" || return 1
  eval "R=\"\${__shsh_map_${1}_${2}}\""
}

map_has() {
  _shsh_check_name "$1" || return 1
  _shsh_check_name "$2" || return 1
  eval "_mh_val=\"\${__shsh_map_${1}_${2}+x}\""
  [ -n "$_mh_val" ]
}

map_delete() {
  _shsh_check_name "$1" || return 1
  _shsh_check_name "$2" || return 1
  eval "unset __shsh_map_${1}_${2}"
}

file_read() {
  R=""
  while IFS= read -r _fr_line || [ -n "$_fr_line" ]; do
    R="$R${R:+
}$_fr_line"
  done < "$1"
}

file_write() { printf "%s\n" "$2" > "$1"; }
file_append() { printf "%s\n" "$2" >> "$1"; }

file_lines() {
  _shsh_check_name "$2" || return 1
  eval "__shsh_${2}_n=0"
  while IFS= read -r _fl_line || [ -n "$_fl_line" ]; do
    array_add "$2" "$_fl_line"
  done < "$1"
}

file_each() {
  _fe_i=0
  while IFS= read -r R || [ -n "$R" ]; do
    "$2"
    _fe_i=$((_fe_i + 1))
  done < "$1"
}

file_exists() { [ -f "$1" ]; }
dir_exists() { [ -d "$1" ]; }

tokenize() {
  _tk_in_dq=0 _tk_in_sq=0 _tk_escape=0
  _tk_input="$1" _tk_out="$2" _tk_char="" _tk_token=""
  _shsh_check_name "$_tk_out" || return 1
  eval "__shsh_${_tk_out}_n=0"
  
  while [ -n "$_tk_input" ]; do
    _tk_char="${_tk_input%"${_tk_input#?}"}"
    _tk_input="${_tk_input#?}"
    
    if [ "$_tk_escape" -eq 1 ]; then
      _tk_token="$_tk_token$_tk_char"
      _tk_escape=0
      continue
    fi
    
    if [ "$_tk_char" = "\\" ] && [ "$_tk_in_sq" -eq 0 ]; then
      _tk_escape=1
      _tk_token="$_tk_token$_tk_char"
      continue
    fi
    
    if [ "$_tk_char" = "$_shsh_dq" ] && [ "$_tk_in_sq" -eq 0 ]; then
      [ "$_tk_in_dq" -eq 1 ] && _tk_in_dq=0 || _tk_in_dq=1
      _tk_token="$_tk_token$_tk_char"
      continue
    fi
    
    if [ "$_tk_char" = "$_shsh_sq" ] && [ "$_tk_in_dq" -eq 0 ]; then
      [ "$_tk_in_sq" -eq 1 ] && _tk_in_sq=0 || _tk_in_sq=1
      _tk_token="$_tk_token$_tk_char"
      continue
    fi

    if [ "$_tk_in_dq" -eq 1 ] || [ "$_tk_in_sq" -eq 1 ]; then
      _tk_token="$_tk_token$_tk_char"
      continue
    fi

    case "$_tk_char" in
      "(" | ")")
        [ -n "$_tk_token" ] && { array_add "$_tk_out" "$_tk_token"; _tk_token=""; }
        array_add "$_tk_out" "$_tk_char"
        ;;
      " " | "	")
        [ -n "$_tk_token" ] && { array_add "$_tk_out" "$_tk_token"; _tk_token=""; }
        ;;
      *)
        _tk_token="$_tk_token$_tk_char"
        ;;
    esac
  done
  [ -n "$_tk_token" ] && array_add "$_tk_out" "$_tk_token"
}

is() {
  # Fast path: no quotes means safe word splitting
  case "$1" in
    *"$_shsh_dq"*|*"$_shsh_sq"*)
      # Quotes present - need careful parsing
      _is_in="$1" _is_dq=0 _is_sq=0 _is_esc=0 _is_p=0
      _is_op="" _is_op_at=-1 _is_op_len=0
      while [ -n "$_is_in" ]; do
        _is_c="${_is_in%"${_is_in#?}"}"
        _is_in="${_is_in#?}"
        if [ "$_is_esc" -eq 1 ]; then _is_esc=0; _is_p=$((_is_p+1)); continue; fi
        [ "$_is_c" = "\\" ] && [ "$_is_sq" -eq 0 ] && { _is_esc=1; _is_p=$((_is_p+1)); continue; }
        [ "$_is_c" = "$_shsh_dq" ] && [ "$_is_sq" -eq 0 ] && { [ "$_is_dq" -eq 1 ] && _is_dq=0 || _is_dq=1; _is_p=$((_is_p+1)); continue; }
        [ "$_is_c" = "$_shsh_sq" ] && [ "$_is_dq" -eq 0 ] && { [ "$_is_sq" -eq 1 ] && _is_sq=0 || _is_sq=1; _is_p=$((_is_p+1)); continue; }
        if [ "$_is_dq" -eq 0 ] && [ "$_is_sq" -eq 0 ] && [ "$_is_c" = " " ]; then
          _is_ahead="$_is_c$_is_in"
          case "$_is_ahead" in
            " == "*) _is_op="==" _is_op_at=$_is_p _is_op_len=2; break;;
            " != "*) _is_op="!=" _is_op_at=$_is_p _is_op_len=2; break;;
            " <= "*) _is_op="<=" _is_op_at=$_is_p _is_op_len=2; break;;
            " >= "*) _is_op=">=" _is_op_at=$_is_p _is_op_len=2; break;;
            " < "*)  _is_op="<"  _is_op_at=$_is_p _is_op_len=1; break;;
            " > "*)  _is_op=">"  _is_op_at=$_is_p _is_op_len=1; break;;
          esac
        fi
        _is_p=$((_is_p+1))
      done
      [ "$_is_op_at" -lt 0 ] && { [ -n "$1" ]; return $?; }
      _is_left="" _is_right="" _is_i=0 _is_tmp="$1"
      while [ "$_is_i" -lt "$_is_op_at" ]; do
        _is_left="$_is_left${_is_tmp%"${_is_tmp#?}"}"
        _is_tmp="${_is_tmp#?}"; _is_i=$((_is_i+1))
      done
      _is_i=0; _is_skip=$((_is_op_len + 2))
      while [ "$_is_i" -lt "$_is_skip" ]; do _is_tmp="${_is_tmp#?}"; _is_i=$((_is_i+1)); done
      _is_right="$_is_tmp"
      case "$_is_left" in "$_shsh_dq"*"$_shsh_dq") _is_left="${_is_left#?}"; _is_left="${_is_left%?}";; esac
      case "$_is_right" in "$_shsh_dq"*"$_shsh_dq") _is_right="${_is_right#?}"; _is_right="${_is_right%?}";; esac
      case "$_is_left" in "$_shsh_sq"*"$_shsh_sq") _is_left="${_is_left#?}"; _is_left="${_is_left%?}";; esac
      case "$_is_right" in "$_shsh_sq"*"$_shsh_sq") _is_right="${_is_right#?}"; _is_right="${_is_right%?}";; esac
      case "$_is_op" in
        "==") [ "$_is_left" = "$_is_right" ];;
        "!=") [ "$_is_left" != "$_is_right" ];;
        "<=") [ "$_is_left" -le "$_is_right" ] 2>/dev/null;;
        "<")  [ "$_is_left" -lt "$_is_right" ] 2>/dev/null;;
        ">=") [ "$_is_left" -ge "$_is_right" ] 2>/dev/null;;
        ">")  [ "$_is_left" -gt "$_is_right" ] 2>/dev/null;;
      esac
      ;;
    *)
      # Fast path: word splitting
      case "$1" in *"*"*|*"?"*|*"["*) set -f; set -- $1; set +f;; *) set -- $1;; esac
      case "$2" in
        "<=") [ "$1" -le "$3" ] 2>/dev/null;;
        "<")  [ "$1" -lt "$3" ] 2>/dev/null;;
        ">=") [ "$1" -ge "$3" ] 2>/dev/null;;
        ">")  [ "$1" -gt "$3" ] 2>/dev/null;;
        "==") [ "$1" = "$3" ];;
        "!=") [ "$1" != "$3" ];;
        *)    [ -n "$1" ];;
      esac
      ;;
  esac
}
'

TOOLKIT="$TOOLKIT"'
ENDIAN=${ENDIAN:-0}

_is_int() { case "$1" in ""|*[!0-9]*) case "$1" in 0x*|0X*) return 0;; *) return 1;; esac ;; *) return 0;; esac; }

bit_8() {
  for _b8_arg in "$@"; do
    _b8_arg="${_b8_arg%,}"
    case "$_b8_arg" in
      "$_shsh_dq"*"$_shsh_dq")
        # Quoted string: print literal
        _b8_str="${_b8_arg#"$_shsh_dq"}"
        printf "%s" "${_b8_str%"$_shsh_dq"}"
        ;;
      *)
        if _is_int "$_b8_arg"; then
          # Number: calc octal digits manually (fast) and print via %b
          _b8_v=$((${_b8_arg}))
          # Construct \ooo sequence: (v>>6)&7, (v>>3)&7, v&7
          printf "%b" "\\$(( (_b8_v >> 6) & 7 ))$(( (_b8_v >> 3) & 7 ))$(( _b8_v & 7 ))"
        else
          # Raw non-numeric token: print literal
          printf "%s" "$_b8_arg"
        fi
        ;;
    esac
  done
}

bit_16() {
  _b16_buf=""
  for _b16_arg in "$@"; do
    _b16_v=$((${_b16_arg%,}))
    # Extract bytes
    _b16_hi=$(( (_b16_v >> 8) & 0xff ))
    _b16_lo=$(( _b16_v & 0xff ))
    
    # Pre-calc octal strings
    _o_hi="\\$(( (_b16_hi >> 6) & 7 ))$(( (_b16_hi >> 3) & 7 ))$(( _b16_hi & 7 ))"
    _o_lo="\\$(( (_b16_lo >> 6) & 7 ))$(( (_b16_lo >> 3) & 7 ))$(( _b16_lo & 7 ))"

    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) _b16_buf="$_b16_buf$_o_hi$_o_lo" ;;
      *)                   _b16_buf="$_b16_buf$_o_lo$_o_hi" ;;
    esac
  done
  [ -n "$_b16_buf" ] && printf "%b" "$_b16_buf"
}

bit_32() {
  _b32_buf=""
  for _b32_arg in "$@"; do
    _b32_v=$((${_b32_arg%,}))
    # Extract 4 bytes
    _b1=$(( (_b32_v >> 24) & 0xff ))
    _b2=$(( (_b32_v >> 16) & 0xff ))
    _b3=$(( (_b32_v >> 8) & 0xff ))
    _b4=$(( _b32_v & 0xff ))

    # Convert to octal escapes
    _o1="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))"
    _o2="\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))"
    _o3="\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))"
    _o4="\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"

    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) _b32_buf="$_b32_buf$_o1$_o2$_o3$_o4" ;;
      *)                   _b32_buf="$_b32_buf$_o4$_o3$_o2$_o1" ;;
    esac
  done
  [ -n "$_b32_buf" ] && printf "%b" "$_b32_buf"
}

bit_64() {
  _b64_buf=""
  for _b64_arg in "$@"; do
    _b64_v=$((${_b64_arg%,}))
    # Split into 32-bit halves for safety
    _b64_h=$(( _b64_v >> 32 ))
    _b64_l=$(( _b64_v & 0xFFFFFFFF ))

    # Extract bytes from High
    _h1=$(( (_b64_h >> 24) & 0xff )); _h2=$(( (_b64_h >> 16) & 0xff ))
    _h3=$(( (_b64_h >> 8) & 0xff ));  _h4=$(( _b64_h & 0xff ))
    
    # Extract bytes from Low
    _l1=$(( (_b64_l >> 24) & 0xff )); _l2=$(( (_b64_l >> 16) & 0xff ))
    _l3=$(( (_b64_l >> 8) & 0xff ));  _l4=$(( _b64_l & 0xff ))

    # Octal conversion
    _oh1="\\$(( (_h1>>6)&7 ))$(( (_h1>>3)&7 ))$(( _h1&7 ))"
    _oh2="\\$(( (_h2>>6)&7 ))$(( (_h2>>3)&7 ))$(( _h2&7 ))"
    _oh3="\\$(( (_h3>>6)&7 ))$(( (_h3>>3)&7 ))$(( _h3&7 ))"
    _oh4="\\$(( (_h4>>6)&7 ))$(( (_h4>>3)&7 ))$(( _h4&7 ))"
    
    _ol1="\\$(( (_l1>>6)&7 ))$(( (_l1>>3)&7 ))$(( _l1&7 ))"
    _ol2="\\$(( (_l2>>6)&7 ))$(( (_l2>>3)&7 ))$(( _l2&7 ))"
    _ol3="\\$(( (_l3>>6)&7 ))$(( (_l3>>3)&7 ))$(( _l3&7 ))"
    _ol4="\\$(( (_l4>>6)&7 ))$(( (_l4>>3)&7 ))$(( _l4&7 ))"

    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) _b64_buf="$_b64_buf$_oh1$_oh2$_oh3$_oh4$_ol1$_ol2$_ol3$_ol4" ;;
      *)                   _b64_buf="$_b64_buf$_ol4$_ol3$_ol2$_ol1$_oh4$_oh3$_oh2$_oh1" ;;
    esac
  done
  [ -n "$_b64_buf" ] && printf "%b" "$_b64_buf"
}

bit_128() {
  for _b128_arg in "$@"; do
    _b128_s="${_b128_arg%,}"
    case "$_b128_s" in 0x*|0X*) _b128_s="${_b128_s#??}";; esac
    while [ ${#_b128_s} -lt 32 ]; do _b128_s="0$_b128_s"; done
    _b128_hi="0x$(printf "%.16s" "$_b128_s")"
    _b128_lo="0x${_b128_s#????????????????}"
    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) bit_64 "$_b128_hi"; bit_64 "$_b128_lo" ;;
      *)                   bit_64 "$_b128_lo"; bit_64 "$_b128_hi" ;;
    esac
  done
}
'

_tl_escape() {
  _te_in="$1" _te_out=""
  while [ -n "$_te_in" ]; do
    case "$_te_in" in
      '"'*) _te_out="$_te_out\\\""; _te_in="${_te_in#?}" ;;
      *'"'*) _te_out="$_te_out${_te_in%%'"'*}\\\""; _te_in="${_te_in#*'"'}" ;;
      *) _te_out="$_te_out$_te_in"; _te_in="" ;;
    esac
  done
}

transform_line() {
  _tl_line="$1"
  _tl_stripped="${_tl_line#"${_tl_line%%[![:space:]]*}"}"
  _tl_indent="${_tl_line%%"$_tl_stripped"}"
  
  case "$_tl_stripped" in
    "if "*)
      case "$_tl_stripped" in
        *";"*) printf '%s\n' "$_tl_line" ;;
        *" <= "*|*" < "*|*" >= "*|*" > "*|*" == "*|*" != "*)
          _tl_expr="${_tl_stripped#if }"
          _tl_escape "$_tl_expr"
          printf '%s\n' "${_tl_indent}if is \"$_te_out\"; then"
          ;;
        *) printf '%s\n' "${_tl_indent}${_tl_stripped}; then" ;;
      esac
      _t_if_depth=$((_t_if_depth + 1))
      ;;
    "elif "*)
      case "$_tl_stripped" in
        *";"*) printf '%s\n' "$_tl_line" ;;
        *" <= "*|*" < "*|*" >= "*|*" > "*|*" == "*|*" != "*)
          _tl_expr="${_tl_stripped#elif }"
          _tl_escape "$_tl_expr"
          printf '%s\n' "${_tl_indent}elif is \"$_te_out\"; then"
          ;;
        *) printf '%s\n' "${_tl_indent}${_tl_stripped}; then" ;;
      esac
      ;;
    "else") printf '%s\n' "${_tl_indent}else" ;;
    "while "*)
      case "$_tl_stripped" in
        *";"*) printf '%s\n' "$_tl_line" ;;
        *" <= "*|*" < "*|*" >= "*|*" > "*|*" == "*|*" != "*)
          _tl_expr="${_tl_stripped#while }"
          _tl_escape "$_tl_expr"
          printf '%s\n' "${_tl_indent}while is \"$_te_out\"; do"
          ;;
        *) printf '%s\n' "${_tl_indent}${_tl_stripped}; do" ;;
      esac
      ;;
    "for "*)
      case "$_tl_stripped" in
        *";"*) printf '%s\n' "$_tl_line" ;;
        *) printf '%s\n' "${_tl_indent}${_tl_stripped}; do" ;;
      esac
      ;;
    "done") printf '%s\n' "${_tl_indent}done" ;;
    "switch "*)
      _tl_expr="${_tl_stripped#switch }"
      printf '%s\n' "${_tl_indent}case $_tl_expr in"
      _t_sw_depth=$((_t_sw_depth + 1))
      eval "_t_sw_first_$_t_sw_depth=1"
      ;;
    "case "*)
      if [ "$_t_sw_depth" -gt 0 ]; then
        _tl_pattern="${_tl_stripped#case }"
        eval "_t_first=\$_t_sw_first_$_t_sw_depth"
        [ "$_t_first" = "1" ] || printf '%s\n' "${_tl_indent};;"
        printf '%s\n' "${_tl_indent}${_tl_pattern})"
        eval "_t_sw_first_$_t_sw_depth=0"
      else
        printf '%s\n' "$_tl_line"
      fi
      ;;
    "default")
      if [ "$_t_sw_depth" -gt 0 ]; then
        eval "_t_first=\$_t_sw_first_$_t_sw_depth"
        [ "$_t_first" = "1" ] || printf '%s\n' "${_tl_indent};;"
        printf '%s\n' "${_tl_indent}*)"
        eval "_t_sw_first_$_t_sw_depth=0"
      else
        printf '%s\n' "$_tl_line"
      fi
      ;;
    "end")
      if [ "$_t_sw_depth" -gt 0 ]; then
        printf '%s\n' "${_tl_indent};;"
        printf '%s\n' "${_tl_indent}esac"
        _t_sw_depth=$((_t_sw_depth - 1))
      else
        printf '%s\n' "${_tl_indent}fi"
        _t_if_depth=$((_t_if_depth - 1))
      fi
      ;;
    *) printf '%s\n' "$_tl_line" ;;
  esac
}

transform() {
  _t_sw_depth=0 _t_if_depth=0
  while IFS= read -r _t_line || [ -n "$_t_line" ]; do
    transform_line "$_t_line"
  done
}

usage() {
  cat <<EOF
shsh v$VERSION

usage: shsh [command] [args...]

  <script>       run script
  -c 'code'      run inline code
  -e <script>    emit standalone POSIX
  -t [script]    transform (file or stdin)
  -              read from stdin
  install        install to system
  uninstall      remove from system
  version        show version
EOF
  exit 1
}

detect_shell_rc() {
  case "${SHELL:-/bin/sh}" in
    */zsh)  printf '%s\n' "$HOME/.zshrc" ;;
    */bash) [ -f "$HOME/.bash_profile" ] && printf '%s\n' "$HOME/.bash_profile" || printf '%s\n' "$HOME/.bashrc" ;;
    */fish) printf '%s\n' "$HOME/.config/fish/config.fish" ;;
    *)      printf '%s\n' "$HOME/.profile" ;;
  esac
}

do_install() {
  if [ -w /usr/local/bin ]; then
    dest=/usr/local/bin/shsh
  else
    mkdir -p "$HOME/.local/bin"
    dest="$HOME/.local/bin/shsh"
  fi
  cp "$0" "$dest" && chmod +x "$dest" && printf '%s\n' "installed: $dest"
  
  case ":$PATH:" in
    *":$(dirname "$dest"):"*) ;;
    *)
      rc=$(detect_shell_rc)
      grep -qF '.local/bin' "$rc" 2>/dev/null || {
        printf '%s\n' '# shsh' >> "$rc"
        printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc"
        printf '%s\n' "added PATH to $rc"
      }
      printf '%s\n' "run: exec \$SHELL"
      ;;
  esac
}

do_uninstall() {
  for loc in /usr/local/bin/shsh "$HOME/.local/bin/shsh"; do
    [ -f "$loc" ] && rm "$loc" && printf '%s\n' "removed: $loc"
  done
}

run_file() {
  eval "$TOOLKIT"
  eval "$(transform < "$1")"
}

run_code() {
  eval "$TOOLKIT"
  eval "$(printf '%s\n' "$1" | transform)"
}

[ $# -eq 0 ] && usage

case "$1" in
  -c)        run_code "$2" ;;
  -e)        printf '%s\n' "#!/bin/sh"; printf '%s\n' "$TOOLKIT"; transform < "$2" ;;
  -t)        [ -n "$2" ] && transform < "$2" || transform ;;
  -)         eval "$TOOLKIT"; eval "$(cat | transform)" ;;
  install)   do_install ;;
  uninstall) do_uninstall ;;
  version)   printf '%s\n' "shsh $VERSION" ;;
  -*)        usage ;;
  *)         run_file "$1" ;;
esac