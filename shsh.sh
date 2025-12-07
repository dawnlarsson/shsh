#
#       shsh - shell in shell
#       Shell without the hieroglyphics
VERSION="0.26.0"

# __RUNTIME_START__
_shsh_sq=$(printf "\047")
_shsh_dq=$(printf "\042")

_shsh_sane() { case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; case "$2" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; }

_shsh_check_name() { case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; }
_shsh_check_int() { case "$1" in ""|*[!0-9]*) return 1;; esac; }
str_starts() { case "$1" in "$2"*);; *) return 1;; esac; }
str_ends() { case "$1" in *"$2");; *) return 1;; esac; }
str_contains() { case "$1" in *"$2"*);; *) return 1;; esac; }
str_after() { R="${1#*"$2"}"; [ "$R" != "$1" ]; }
str_before() { R="${1%%"$2"*}"; [ "$R" != "$1" ]; }
str_after_last() { R="${1##*"$2"}"; [ "$R" != "$1" ]; }
str_before_last() { R="${1%"$2"*}"; [ "$R" != "$1" ]; }
str_ltrim() { R="${1#"${1%%[![:space:]]*}"}"; }
str_rtrim() { R="${1%"${1##*[![:space:]]}"}"; }
str_trim() { R="${1#"${1%%[![:space:]]*}"}"; R="${R%"${R##*[![:space:]]}"}"; }
str_indent() { R="${1%%[![:space:]]*}"; }

default() { _shsh_check_name "$1" || return 1; eval "[ -z \"\${$1}\" ] && $1=\"\$2\""; }
default_unset() { _shsh_check_name "$1" || return 1; eval "[ -z \"\${$1+x}\" ] && $1=\"\$2\""; }

array_set() { case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; _shsh_check_int "$2" || return 1; eval "__shsh_${1}_$2=\"\$3\"; [ $2 -ge \${__shsh_${1}_n:-0} ] && __shsh_${1}_n=$(($2 + 1))"; }
array_get() { case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; case "$2" in ""|*[!0-9]*) return 1;; esac; eval "R=\"\${__shsh_${1}_$2}\"; [ -n \"\${__shsh_${1}_$2+x}\" ]"; }
array_len() { _shsh_check_name "$1" || return 1; eval "R=\"\${__shsh_${1}_n:-0}\""; }

array_add() {
  _shsh_check_name "$1" || return 1
  eval "_aa_idx=\${__shsh_${1}_n:-0}"
  eval "__shsh_${1}_$_aa_idx=\"\$2\"; __shsh_${1}_n=$((_aa_idx + 1))"
}

array_for() {
  case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac;
  _af_d=${_af_d:--1}; _af_d=$((_af_d + 1))
  eval "_af_len_$_af_d=\"\${__shsh_${1}_n:-0}\"; _af_i_$_af_d=0"
  while eval "[ \$_af_i_$_af_d -lt \$_af_len_$_af_d ]"; do
    eval "_af_idx=\$_af_i_$_af_d"
    eval "R=\"\${__shsh_${1}_$_af_idx}\""
    "$2" || { _af_d=$((_af_d - 1)); return 0; }
    eval "_af_i_$_af_d=\$((\$_af_i_$_af_d + 1))"
  done
  _af_d=$((_af_d - 1))
}

# leaks, but fast and lazy
array_clear() { _shsh_check_name "$1" || return 1; eval "__shsh_${1}_n=0"; }
array_clear_full() {
  _shsh_check_name "$1" || return 1
  eval "_ac_len=\"\${__shsh_${1}_n:-0}\""
  _ac_i=0
  while [ "$_ac_i" -lt "$_ac_len" ]; do
    eval "unset __shsh_${1}_$_ac_i"
    _ac_i=$((_ac_i + 1))
  done
  eval "__shsh_${1}_n=0"
}

array_unset() { _shsh_check_name "$1" || return 1; _shsh_check_int "$2" || return 1; eval "unset __shsh_${1}_$2"; }

array_remove() {
  _shsh_sane "$1" "$2" || return 1;
  eval "_ar_len=\"\${__shsh_${1}_n:-0}\""
  [ "$2" -ge "$_ar_len" ] && return 1
  _ar_i=$2
  while [ "$((_ar_i + 1))" -lt "$_ar_len" ]; do
    eval "__shsh_${1}_$_ar_i=\"\${__shsh_${1}_$((_ar_i + 1))}\""
    _ar_i=$((_ar_i + 1))
  done
  eval "unset __shsh_${1}_$((_ar_len - 1)); __shsh_${1}_n=$((_ar_len - 1))"
}

array_delete() { array_remove "$@"; }

map_set() {
  _shsh_sane "$1" "$2" || return 1
  eval "__shsh_map_${1}_${2}=\"\$3\"; _mset_exists=\"\${__shsh_map_${1}_${2}__exists}\""
  if [ -z "$_mset_exists" ]; then
    eval "__shsh_map_${1}_${2}__exists=1; _mset_idx=\${__shsh_mapkeys_${1}_n:-0}"
    eval "__shsh_mapkeys_${1}_$_mset_idx=\"$2\"; __shsh_mapkeys_${1}_n=$((_mset_idx + 1))"
  fi
}
map_keys() {
  _shsh_sane "$1" "$2" || return 1;
  eval "__shsh_${2}_n=0; _mk_len=\"\${__shsh_mapkeys_${1}_n:-0}\""
  _mk_i=0
  while [ "$_mk_i" -lt "$_mk_len" ]; do
    eval "_mk_key=\"\${__shsh_mapkeys_${1}_$_mk_i}\""
    eval "_mk_exists=\"\${__shsh_map_${1}_${_mk_key}+x}\""
    [ -n "$_mk_exists" ] && array_add "$2" "$_mk_key"
    _mk_i=$((_mk_i + 1))
  done
}

map_for() {
  _shsh_check_name "$1" || return 1
  _mf_d=${_mf_d:--1}; _mf_d=$((_mf_d + 1))
  eval "_mf_len_$_mf_d=\"\${__shsh_mapkeys_${1}_n:-0}\"; _mf_i_$_mf_d=0"
  while eval "[ \$_mf_i_$_mf_d -lt \$_mf_len_$_mf_d ]"; do
    eval "_mf_idx=\$_mf_i_$_mf_d"
    eval "_mf_key=\"\${__shsh_mapkeys_${1}_$_mf_idx}\""
    eval "_mf_exists=\"\${__shsh_map_${1}_${_mf_key}+x}\""
    if [ -n "$_mf_exists" ]; then
      eval "R=\"\${__shsh_map_${1}_${_mf_key}}\""
      K="$_mf_key"
      "$2" || { _mf_d=$((_mf_d - 1)); return 0; }
    fi
    eval "_mf_i_$_mf_d=\$((\$_mf_i_$_mf_d + 1))"
  done
  _mf_d=$((_mf_d - 1))
}

map_clear() {
  _shsh_check_name "$1" || return 1
  eval "_mc_len=\"\${__shsh_mapkeys_${1}_n:-0}\""
  _mc_i=0
  while [ "$_mc_i" -lt "$_mc_len" ]; do
    eval "_mc_key=\"\${__shsh_mapkeys_${1}_$_mc_i}\""
    eval "unset __shsh_map_${1}_${_mc_key}"
    eval "unset __shsh_map_${1}_${_mc_key}__exists"
    eval "unset __shsh_mapkeys_${1}_$_mc_i"
    _mc_i=$((_mc_i + 1))
  done
  eval "__shsh_mapkeys_${1}_n=0"
}

map_get() { _shsh_sane "$1" "$2" || return 1; eval "R=\"\${__shsh_map_${1}_${2}}\""; }
map_has() { _shsh_sane "$1" "$2" || return 1; eval "[ -n \"\${__shsh_map_${1}_${2}+x}\" ]"; }
map_delete() { _shsh_sane "$1" "$2" || return 1; eval "unset __shsh_map_${1}_${2}"; }

file_read() {
  R=""
  while IFS= read -r _fr_line || [ -n "$_fr_line" ]; do
    R="$R${R:+
}$_fr_line"
  done < "$1"
}

file_write() { printf "$2\n" > "$1"; }
file_append() { printf "$2\n" >> "$1"; }
file_exists() { [ -f "$1" ]; }
dir_exists() { [ -d "$1" ]; }

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
      " " | "")
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
  case "$1" in
    *"$_shsh_dq"*|*"$_shsh_sq"*)
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

ENDIAN=${ENDIAN:-0}

_is_int() { case "$1" in ""|*[!0-9]*) case "$1" in 0x*|0X*) return 0;; *) return 1;; esac ;; *) return 0;; esac; }

bit_8() {
  for _b8_arg in "$@"; do
    _b8_arg="${_b8_arg%,}"
    case "$_b8_arg" in
      "$_shsh_dq"*"$_shsh_dq")
        _b8_str="${_b8_arg#"$_shsh_dq"}"
        printf "%s" "${_b8_str%"$_shsh_dq"}"
        ;;
      *)
        if _is_int "$_b8_arg"; then
          _b8_v=$((${_b8_arg}))
          printf "%b" "\\$(( (_b8_v >> 6) & 7 ))$(( (_b8_v >> 3) & 7 ))$(( _b8_v & 7 ))"
        else
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
    _b16_hi=$(( (_b16_v >> 8) & 0xff ))
    _b16_lo=$(( _b16_v & 0xff ))
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
    _b1=$(( (_b32_v >> 24) & 0xff ))
    _b2=$(( (_b32_v >> 16) & 0xff ))
    _b3=$(( (_b32_v >> 8) & 0xff ))
    _b4=$(( _b32_v & 0xff ))
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
    _b64_h=$(( _b64_v >> 32 ))
    _b64_l=$(( _b64_v & 0xFFFFFFFF ))
    _h1=$(( (_b64_h >> 24) & 0xff )); _h2=$(( (_b64_h >> 16) & 0xff ))
    _h3=$(( (_b64_h >> 8) & 0xff ));  _h4=$(( _b64_h & 0xff ))
    _l1=$(( (_b64_l >> 24) & 0xff )); _l2=$(( (_b64_l >> 16) & 0xff ))
    _l3=$(( (_b64_l >> 8) & 0xff ));  _l4=$(( _b64_l & 0xff ))
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
# __RUNTIME_END__

block_stack=""
single_line_if_active=0
single_line_if_indent=""

COLON_SPACE=":"
COLON_SPACE="$COLON_SPACE "

SEMICOLON_THEN=";"
SEMICOLON_THEN="$SEMICOLON_THEN then"
SEMICOLON_DO=";"
SEMICOLON_DO="$SEMICOLON_DO do"

push() { block_stack="$block_stack$1"; }
pop()  { block_stack="${block_stack%?}"; }
peek() { R="${block_stack#"${block_stack%?}"}"; }

switch_first_case_stack=""
switch_push_first() { switch_first_case_stack="${switch_first_case_stack}1"; }
switch_pop_first()  { switch_first_case_stack="${switch_first_case_stack%?}"; }
switch_is_first()   { str_ends "$switch_first_case_stack" "1"; }
switch_set_not_first() { switch_first_case_stack="${switch_first_case_stack%?}0"; }

try_depth=0
try_depth_inc() { try_depth=$((try_depth + 1)); }
try_depth_dec() { try_depth=$((try_depth - 1)); }

in_try_block() {
  case "$block_stack" in
    *t*) return 0 ;;
    *) return 1 ;;
  esac
}

current_try_depth() {
  _ctd_s="$block_stack" _ctd_n=0
  while [ -n "$_ctd_s" ]; do
    case "$_ctd_s" in
      t*) _ctd_n=$((_ctd_n + 1)) ;;
    esac
    _ctd_s="${_ctd_s#?}"
  done
  R=$_ctd_n
}

emit_with_try_check() {
  if in_try_block; then
    current_try_depth
    printf '%s || { _shsh_err_%s=$?; _shsh_brk_%s=1; break; }\n' "$1" "$R" "$R"
  else
    printf '%s\n' "$1"
  fi
}

is_comparison() {
  case $1 in
  *" <= "*|*" < "*|*" >= "*|*" > "*|*" == "*|*" != "*)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}

escape_quotes() {
  _eq_in="$1" _eq_out=""
  while str_contains "$_eq_in" '"'; do
    str_before "$_eq_in" '"'; _eq_out="$_eq_out$R\\\""
    str_after "$_eq_in" '"'; _eq_in="$R"
  done
  R="$_eq_out$_eq_in"
}

emit_condition() {
  keyword="$1" condition="$2" indent="$3" suffix="$4"
  if is_comparison "$condition"; then
    escape_quotes "$condition"
    printf '%s\n' "${indent}${keyword} is \"$R\"${suffix}"
  else
    printf '%s\n' "${indent}${keyword} ${condition}${suffix}"
  fi
}

emit_inline_statement() {
  inline_indent="$1"
  inline_statement="$2"
  if is "\"$inline_statement\" == \"\""; then
    return
  fi

  str_ltrim "$inline_statement"; inline_statement="$R"

  if str_starts "$inline_statement" "if "; then
    str_after "$inline_statement" "if "; inline_rest="$R"
    if str_contains "$inline_rest" "$COLON_SPACE"; then
      str_before "$inline_rest" "$COLON_SPACE"; inline_condition="$R"
      str_after "$inline_rest" "$COLON_SPACE"; inline_body="$R"
      str_ltrim "$inline_body"; inline_body="$R"
      emit_condition "if" "$inline_condition" "$inline_indent" "$SEMICOLON_THEN"
      emit_with_try_check "${inline_indent}  ${inline_body}"
      single_line_if_active=1
      single_line_if_indent="$inline_indent"
      return
    fi
  fi

  emit_with_try_check "${inline_indent}${inline_statement}"
}

transform_line() {
  line="$1"
  str_ltrim "$line"; stripped="$R"
  str_indent "$line"; indent="$R"
  
  if is "$single_line_if_active == 1"; then
    continues_single_line=0
    if is "\"$indent\" == \"$single_line_if_indent\""; then
      if str_starts "$stripped" "elif "; then
        continues_single_line=1
      fi
      if str_starts "$stripped" "else"; then
        continues_single_line=1
      fi
    fi
    
    if is "$continues_single_line == 1"; then
      converts_to_multiline=0
      if str_starts "$stripped" "elif "; then
        if ! str_contains "$stripped" "$COLON_SPACE"; then
          converts_to_multiline=1
        fi
      fi
      if is "\"$stripped\" == \"else\""; then
        converts_to_multiline=1
      fi
      
      if is "$converts_to_multiline == 1"; then
        single_line_if_active=0
        push i
      fi
    else
      printf '%s\n' "${single_line_if_indent}fi"
      single_line_if_active=0
    fi
  fi
  
  case $stripped in
  
  "if "*)
    str_after "$stripped" "if "; rest="$R"
    if str_contains "$rest" "$COLON_SPACE"; then
      str_before "$rest" "$COLON_SPACE"; condition="$R"
      str_after "$rest" "$COLON_SPACE"; statement="$R"
      emit_condition "if" "$condition" "$indent" "$SEMICOLON_THEN"
      emit_with_try_check "${indent}  ${statement}"
      single_line_if_active=1
      single_line_if_indent="$indent"
    elif str_contains "$stripped" "$SEMICOLON_THEN"; then
      printf '%s\n' "$line"
      push i
    else
      emit_condition "if" "$rest" "$indent" "$SEMICOLON_THEN"
      push i
    fi
  
    ;;
  "elif "*)
    str_after "$stripped" "elif "; rest="$R"
    if str_contains "$rest" "$COLON_SPACE"; then
      str_before "$rest" "$COLON_SPACE"; condition="$R"
      str_after "$rest" "$COLON_SPACE"; statement="$R"
      emit_condition "elif" "$condition" "$indent" "$SEMICOLON_THEN"
      emit_with_try_check "${indent}  ${statement}"
    elif str_contains "$stripped" "$SEMICOLON_THEN"; then
      printf '%s\n' "$line"
    else
      emit_condition "elif" "$rest" "$indent" "$SEMICOLON_THEN"
    fi
  
    ;;
  "else:"*)
    str_after "$stripped" "else:"; statement="$R"
    str_ltrim "$statement"; statement="$R"
    printf "${indent}else\n"
    emit_with_try_check "${indent}  ${statement}"
    if is "$single_line_if_active == 1"; then
      printf "${indent}fi\n"
      single_line_if_active=0
    fi
  
    ;;
  "else")
    printf "${indent}else\n"
  
    ;;
  "while "*)
    str_after "$stripped" "while "; expression="$R"
    if str_contains "$expression" "$COLON_SPACE"; then
      str_before "$expression" "$COLON_SPACE"; condition="$R"
      str_after "$expression" "$COLON_SPACE"; statement="$R"
      emit_condition "while" "$condition" "$indent" "$SEMICOLON_DO"
      emit_with_try_check "${indent}  ${statement}"
      printf "${indent}done\n"
      if in_try_block; then
        current_try_depth
        printf "${indent}[ \"\$_shsh_brk_$R\" -eq 1 ] && break\n"
      fi
    elif str_contains "$stripped" "$SEMICOLON_DO"; then
      printf '%s\n' "$line"
    else
      emit_condition "while" "$expression" "$indent" "$SEMICOLON_DO"
    fi
  
    ;;
  "for "*)
    if str_contains "$stripped" "$SEMICOLON_DO"; then
      printf '%s\n' "$line"
    else
      printf "${indent}${stripped}; do\n"
    fi
  
    ;;
  "done")
    printf "${indent}done\n"
    if in_try_block; then
      current_try_depth
      printf "${indent}[ \"\$_shsh_brk_$R\" -eq 1 ] && break\n"
    fi
  
    ;;
  "try")
    try_depth_inc
    printf "${indent}_shsh_err_$try_depth=0; _shsh_brk_$try_depth=0; while [ \"\$_shsh_brk_$try_depth\" -eq 0 ]; do\n"
    push t
  
    ;;
  "catch")
    peek
    if is "\"$R\" == \"t\""; then
      printf "${indent}_shsh_brk_$try_depth=1; done\n${indent}if [ \"\$_shsh_err_$try_depth\" -ne 0 ]; then error=\$_shsh_err_$try_depth\n"
      pop
      push c
    else
      printf '%s\n' "$line"
    fi
  
    ;;
  "switch "*)
    str_after "$stripped" "switch "; expression="$R"
    printf "${indent}case $expression in\n"
    push s
    switch_push_first
  
    ;;
  "case "*)
    peek
    if is "\"$R\" == \"s\""; then
      str_after "$stripped" "case "; rest="$R"
      
      if ! switch_is_first; then
        printf "${indent}  ;;\n"
      fi
      switch_set_not_first
      
      if str_contains "$rest" "$COLON_SPACE"; then
        str_before "$rest" "$COLON_SPACE"; maybe_pattern="$R"
        str_after "$rest" "$COLON_SPACE"; maybe_statement="$R"
        str_ltrim "$maybe_statement"; maybe_statement="$R"
        
        is_single_line=0
        if ! str_contains "$maybe_pattern" '"' && ! str_contains "$maybe_pattern" "'"; then
          if is "\"$maybe_statement\" != \"\""; then
            is_single_line=1
          fi
        else
          if is "\"$maybe_statement\" != \"\""; then
            is_single_line=1
          fi
        fi
        
        if is "$is_single_line == 1"; then
          printf '%s\n' "${indent}${maybe_pattern})"
          emit_inline_statement "${indent}  " "$maybe_statement"
        else
          printf '%s\n' "${indent}${rest})"
        fi
      else
        printf '%s\n' "${indent}${rest})"
      fi
    else
      printf '%s\n' "$line"
    fi
  
    ;;
  "default:"*)
    peek
    if is "\"$R\" == \"s\""; then
      if ! switch_is_first; then
        printf "${indent}  ;;\n"
      fi
      switch_set_not_first
      str_after "$stripped" "default:"; statement="$R"
      str_ltrim "$statement"; statement="$R"
      printf "${indent}*)\n"
      if is "\"$statement\" != \"\""; then
        emit_inline_statement "${indent}  " "$statement"
      fi
    else
      printf '%s\n' "$line"
    fi
  
    ;;
  "default")
    peek
    if is "\"$R\" == \"s\""; then
      if ! switch_is_first; then
        printf "${indent}  ;;\n"
      fi
      switch_set_not_first
      printf "${indent}*)\n"
    else
      printf '%s\n' "$line"
    fi
  
    ;;
  "end")
    peek
    if is "\"$R\" == \"s\""; then
      printf "${indent}  ;;\n"
      printf "${indent}esac\n"
      switch_pop_first
      pop
    elif is "\"$R\" == \"i\""; then
      printf "${indent}fi\n"
      pop
    elif is "\"$R\" == \"c\""; then
      printf "${indent}fi\n"
      try_depth_dec
      pop
    elif is "\"$R\" == \"t\""; then
      printf "${indent}_shsh_brk_$try_depth=1; done\n"
      try_depth_dec
      pop
    fi
  
    ;;
  *"++")
    str_before "$stripped" "++"; variable="$R"
    case $variable in
      *[!a-zA-Z0-9_]*|"")
        printf '%s\n' "$line"
        ;;
      *)
        printf '%s\n' "${indent}${variable}=\$((${variable} + 1))"
      ;;
    esac
  
    ;;
  *"--")
    str_before "$stripped" "--"; variable="$R"
    case $variable in
      *[!a-zA-Z0-9_]*|"")
        printf '%s\n' "$line"
        ;;
      *)
        printf '%s\n' "${indent}${variable}=\$((${variable} - 1))"
      ;;
    esac
  
    ;;
  *" += "*)
    str_before "$stripped" " += "; variable="$R"
    case $variable in
      *[!a-zA-Z0-9_]*|"")
        printf '%s\n' "$line"
        ;;
      *)
        str_after "$stripped" " += "; value="$R"
        printf '%s\n' "${indent}${variable}=\$((${variable} + ${value}))"
      ;;
    esac
  
    ;;
  *" -= "*)
    str_before "$stripped" " -= "; variable="$R"
    case $variable in
      *[!a-zA-Z0-9_]*|"")
        printf '%s\n' "$line"
        ;;
      *)
        str_after "$stripped" " -= "; value="$R"
        printf '%s\n' "${indent}${variable}=\$((${variable} - ${value}))"
      ;;
    esac
  
    ;;
  *" *= "*)
    str_before "$stripped" " *= "; variable="$R"
    case $variable in
      *[!a-zA-Z0-9_]*|"")
        printf '%s\n' "$line"
        ;;
      *)
        str_after "$stripped" " *= "; value="$R"
        printf '%s\n' "${indent}${variable}=\$((${variable} * ${value}))"
      ;;
    esac
  
    ;;
  *" /= "*)
    str_before "$stripped" " /= "; variable="$R"
    case $variable in
      *[!a-zA-Z0-9_]*|"")
        printf '%s\n' "$line"
        ;;
      *)
        str_after "$stripped" " /= "; value="$R"
        printf '%s\n' "${indent}${variable}=\$((${variable} / ${value}))"
      ;;
    esac
  
    ;;
  *" %= "*)
    str_before "$stripped" " %= "; variable="$R"
    case $variable in
      *[!a-zA-Z0-9_]*|"")
        printf '%s\n' "$line"
        ;;
      *)
        str_after "$stripped" " %= "; value="$R"
        printf '%s\n' "${indent}${variable}=\$((${variable} % ${value}))"
      ;;
    esac
  
    ;;
  *)
    emit_with_try_check "$line"
  
    ;;
  esac
}

transform() {
  block_stack=""
  single_line_if_active=0
  single_line_if_indent=""
  switch_first_case_stack=""
  try_depth=0
  
  while IFS= read -r current_line || [ -n "$current_line" ]; do
    transform_line "$current_line"
  done
  
  if is "$single_line_if_active == 1"; then
    printf "${single_line_if_indent}fi\n"
  fi
}

run_file() {
  script="$1"
  shift
  eval "$(transform < "$script")"
}

emit_runtime_stripped() {
  _ers_source="$1"
  
  # Phase 1: Extract all runtime functions and their bodies
  _ers_all_fns="" _ers_in_rt=0 _ers_cur_fn="" _ers_cur_body=""
  while IFS= read -r _ers_line || [ -n "$_ers_line" ]; do
    if str_starts "$_ers_line" "# __RUNTIME_START__"; then
      _ers_in_rt=1; continue
    fi
    if str_starts "$_ers_line" "# __RUNTIME_END__"; then
      break
    fi
    if is "$_ers_in_rt == 0"; then
      continue
    fi
    
    # Check for function start
    case "$_ers_line" in
    *"() {"*)
      str_before "$_ers_line" "()"; _ers_cur_fn="$R"
      str_ltrim "$_ers_cur_fn"; _ers_cur_fn="$R"
      _ers_all_fns="$_ers_all_fns $_ers_cur_fn"
      _ers_cur_body=""
      ;;
    "}")
      # Store the function body for dependency analysis
      eval "_rt_body_$_ers_cur_fn=\"\$_ers_cur_body\""
      _ers_cur_fn=""
      ;;
    *)
      if is "\"$_ers_cur_fn\" != \"\""; then
        _ers_cur_body="$_ers_cur_body $_ers_line"
      fi
      ;;
    esac
  done < "$0"
  
  # Phase 2: Build dependency map by checking which functions each body calls
  for _ers_fn in $_ers_all_fns; do
    eval "_ers_body=\"\$_rt_body_$_ers_fn\""
    _ers_deps=""
    for _ers_other in $_ers_all_fns; do
      if is "\"$_ers_fn\" != \"$_ers_other\""; then
        case "$_ers_body" in
        *"$_ers_other"*)
          _ers_deps="$_ers_deps $_ers_other"
          ;;
        esac
      fi
    done
    eval "_rt_deps_$_ers_fn=\"\$_ers_deps\""
  done
  
  # Phase 3: Check which functions the source uses
  _rt_needed=" is " # is() always needed for shsh conditionals
  for _ers_fn in $_ers_all_fns; do
    case "$_ers_source" in
    *"$_ers_fn"*)
      # Mark as needed and resolve dependencies recursively
      _rt_need_fn "$_ers_fn"
      ;;
    esac
  done
  
  # Phase 4: Emit only needed functions
  _ers_emit=0 _ers_skip=0
  while IFS= read -r _ers_line || [ -n "$_ers_line" ]; do
    case $_ers_emit in
    0)
      if str_starts "$_ers_line" "# __RUNTIME_START__"; then
        _ers_emit=1
        printf "$_ers_line\n"
      fi
      ;;
    1)
      if str_starts "$_ers_line" "# __RUNTIME_END__"; then
        printf "$_ers_line\n"
        _ers_emit=2
      else
        case "$_ers_line" in
        *"() {"*)
          str_before "$_ers_line" "()"; _ers_fn="$R"
          str_ltrim "$_ers_fn"; _ers_fn="$R"
          case "$_rt_needed" in
          *" $_ers_fn "*)
            _ers_skip=0
            printf "$_ers_line\n"
            ;;
          *)
            _ers_skip=1
            ;;
          esac
          ;;
        "}")
          if is "$_ers_skip == 0"; then
            printf "$_ers_line\n"
          fi
          _ers_skip=0
          ;;
        "")
          if is "$_ers_skip == 0"; then
            printf "\n"
          fi
          ;;
        *)
          if is "$_ers_skip == 0"; then
            printf '%s\n' "$_ers_line"
          fi
          ;;
        esac
      fi
      ;;
    esac
  done < "$0"
}

_rt_need_fn() {
  case "$_rt_needed" in
  *" $1 "*)
    return
    ;;
  esac
  _rt_needed="$_rt_needed $1 "
  eval "_rnf_deps=\"\$_rt_deps_$1\""
  for _rnf_dep in $_rnf_deps; do
    _rt_need_fn "$_rnf_dep"
  done
}

emit_runtime() {
  _er_emit=0
  while IFS= read -r _er_line || [ -n "$_er_line" ]; do
    case $_er_emit in
    0)
      if str_starts "$_er_line" "# __RUNTIME_START__"; then
        _er_emit=1
        printf "$_er_line\n"
      fi
      ;;
    1)
      printf '%s\n' "$_er_line"
      if str_starts "$_er_line" "# __RUNTIME_END__"; then
        _er_emit=2
      fi
      ;;
    esac
  done < "$0"
}

info() {
    printf "shsh v$VERSION\n\n"
    printf "usage: shsh [command] [args...]\n\n"
    printf "  <script>       run script\n"
    printf "  -c 'code'      run inline code\n"
    printf "  -t [script]    transform (file or stdin)\n"
    printf "  -e [script]    emit standalone (stripped runtime)\n"
    printf "  -E [script]    emit standalone (full runtime)\n"
    printf "  -              read from stdin\n"
    printf "  install        install to system\n"
    printf "  uninstall      remove from system\n"
    printf "  update         update from github (sudo)\n"
    printf "  version        show version\n"
}

case $1 in
  -c)
    eval "$(printf "$2\n" | transform)"
    ;;
  -t)
    if is "\"$2\" == \"\""; then
      transform
    else
      transform < "$2"
    fi
    ;;
  -e)
    if is "\"$2\" == \"\""; then
      _es_code="$(transform)"
      emit_runtime_stripped "$_es_code"
      printf "$_es_code\n"
    else
      _es_code="$(transform < "$2")"
      emit_runtime_stripped "$_es_code"
      printf "$_es_code\n"
    fi
    ;;
  -E)
    emit_runtime
    if is "\"$2\" == \"\""; then
      transform
    else
      transform < "$2"
    fi
    ;;
  -v)
    printf "shsh $VERSION\n"
    ;;
  version)
    printf "shsh $VERSION\n"
    ;;
  -)
    eval "$(transform)"
    ;;
  install)
    shell="$HOME/.profile"
    case $SHELL in
      */bash)
        if [ -f "$HOME/.bash_profile" ]; then
          shell="$HOME/.bash_profile"
        else
          shell="$HOME/.bashrc"
        fi
        ;;
      */zsh)
        shell="$HOME/.zshrc"
        ;;
      */fish)
        shell="$HOME/.config/fish/config.fish"
      ;;
    esac

    if [ -w /usr/local/bin ]; then
      dest=/usr/local/bin/shsh
    else
      mkdir -p "$HOME/.local/bin"
      dest="$HOME/.local/bin/shsh"
    fi

    cp "$0" "$dest" && chmod +x "$dest" && printf "installed: $dest\n"

    case ":$PATH:" in
      *":$(dirname "$dest"):"*)
        ;;
      *)
        grep -qF '.local/bin' "$shell" 2>/dev/null || {
          printf '# shsh\n' >> "$shell"
          printf 'export PATH="$HOME/.local/bin:$PATH"\n' >> "$shell"
          printf "added PATH to $shell\n"
        }
        printf "run: exec \$SHELL\n"
      ;;
    esac
    ;;
  uninstall)
    for loc in /usr/local/bin/shsh "$HOME/.local/bin/shsh"; do
      if [ -f "$loc" ]; then
        rm "$loc" && printf "removed: $loc\n"
      fi
    done
    ;;
  update)
    _url="https://raw.githubusercontent.com/dawnlarsson/shsh/main/shsh.sh"
    _dest="/usr/local/bin/shsh"
    _old_ver="$VERSION"
    printf "downloading shsh from github...\n"
    if command -v curl >/dev/null 2>&1; then
      _tmp=$(mktemp)
      if curl -fsSL "$_url" -o "$_tmp"; then
        sudo mv "$_tmp" "$_dest" && sudo chmod +x "$_dest" && printf "updated: $_dest\n"
      else
        rm -f "$_tmp"
        printf "error: download failed\n" >&2
        exit 1
      fi
    elif command -v wget >/dev/null 2>&1; then
      _tmp=$(mktemp)
      if wget -qO "$_tmp" "$_url"; then
        sudo mv "$_tmp" "$_dest" && sudo chmod +x "$_dest" && printf "updated: $_dest\n"
      else
        rm -f "$_tmp"
        printf "error: download failed\n" >&2
        exit 1
      fi
    else
      printf "error: curl or wget required\n" >&2
      exit 1
    fi
    _new_ver=$("$_dest" -v 2>/dev/null | sed 's/shsh //')
    if is "\"$_new_ver\" == \"$_old_ver\""; then
      printf "warning: version unchanged (%s) - update may have failed\n" "$_old_ver" >&2
    else
      printf "version: %s -> %s\n" "$_old_ver" "$_new_ver"
    fi
    ;;
  "")
    info
    ;;
  -*)
    info
    ;;
  *)
    run_file "$@"
  ;;
esac
