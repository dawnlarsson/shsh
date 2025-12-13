
if [ -z "$_SHSH_DASH" ]; then
  if command -v dash >/dev/null 2>&1; then
    export _SHSH_DASH=1
    exec dash "$0" "$@"
  fi
fi

VERSION="0.56.0"

# __RUNTIME_START__
_shsh_sq="'"
_shsh_dq='"'

_shsh_sane() { case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; case "$2" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; }

_shsh_check_name() { case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; }
_shsh_check_int() { case "$1" in ""|*[!0-9]*) return 1;; esac; }
str_starts() { case "$1" in "$2"*);; *) return 1;; esac; }
str_ends() { case "$1" in *"$2");; *) return 1;; esac; }
str_contains() { case "$1" in *"$2"*);; *) return 1;; esac; }
str_after() { R=${1#*"$2"}; [ "$R" != "$1" ]; }
str_before() { R=${1%%"$2"*}; [ "$R" != "$1" ]; }
str_after_last() { R=${1##*"$2"}; [ "$R" != "$1" ]; }
str_before_last() { R=${1%"$2"*}; [ "$R" != "$1" ]; }
str_ltrim() { R=${1#"${1%%[![:space:]]*}"}; }
str_rtrim() { R=${1%"${1##*[![:space:]]}"}; }
str_trim() { R=${1#"${1%%[![:space:]]*}"}; R=${R%"${R##*[![:space:]]}"}; }
str_indent() { R=${1%%[![:space:]]*}; }
str_split_indent() { R=${1%%[![:space:]]*}; R2=${1#"$R"}; }

scan() {
  _sc_in=$1
  _sc_pat=$2

  while :; do
    case $_sc_pat in
      '') return 0 ;;
    esac

    _sc_lit=${_sc_pat%%\%*}
    if [ -n "$_sc_lit" ]; then
      case $_sc_in in
        "$_sc_lit"*)
          _sc_in=${_sc_in#"$_sc_lit"}
          _sc_pat=${_sc_pat#"$_sc_lit"}
          ;;
        *) return 1 ;;
      esac
      [ -n "$_sc_pat" ] || return 0
    fi

    case $_sc_pat in
      %*) _sc_pat=${_sc_pat#\%} ;;
      *)  return 1 ;;
    esac

    _sc_var=${_sc_pat%%[!A-Za-z0-9_]*}
    case $_sc_var in
      ''|[!A-Za-z_]* ) return 1 ;;
    esac
    _sc_pat=${_sc_pat#"$_sc_var"}

    if [ -z "$_sc_pat" ]; then
      eval "$_sc_var=\"\$_sc_in\""
      return 0
    fi

    _sc_next_lit=${_sc_pat%%\%*}

    if [ -z "$_sc_next_lit" ]; then
      eval "$_sc_var=\"\""
      continue
    fi

    _sc_val=${_sc_in%%"$_sc_next_lit"*}
    [ "$_sc_val" = "$_sc_in" ] && return 1

    eval "$_sc_var=\"\$_sc_val\""

    _sc_in=${_sc_in#*"$_sc_next_lit"}
    _sc_pat=${_sc_pat#"$_sc_next_lit"}
  done
}

_in_quotes() {
  _iq_q="$1"
  while :; do
    case "$_iq_q" in *'"'*|*"'"*) ;; *) return 1 ;; esac
    _iq_p="${_iq_q%%\'*}"
    case "$_iq_p" in
      *'"'*) _iq_q="${_iq_q#*'"'}"; case "$_iq_q" in *'"'*) _iq_q="${_iq_q#*'"'}" ;; *) return 0 ;; esac ;;
      *) _iq_q="${_iq_q#*\'}"; case "$_iq_q" in *\'*) _iq_q="${_iq_q#*\'}" ;; *) return 0 ;; esac ;;
    esac
  done
}

default() { _shsh_check_name "$1" || return 1; eval "[ -z \"\${$1}\" ] && $1=\"\$2\""; }
default_unset() { _shsh_check_name "$1" || return 1; eval "[ -z \"\${$1+x}\" ] && $1=\"\$2\""; }

array_set() {
  case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac
  case "$2" in ""|*[!0-9]*) return 1;; esac
  eval "__shsh_${1}_$2=\"\$3\"; [ $2 -ge \${__shsh_${1}_n:-0} ] && __shsh_${1}_n=$(($2 + 1))"
}
array_get() { case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac; case "$2" in ""|*[!0-9]*) return 1;; esac; eval "R=\"\${__shsh_${1}_$2}\"; [ -n \"\${__shsh_${1}_$2+x}\" ]"; }
array_len() { _shsh_check_name "$1" || return 1; eval "R=\"\${__shsh_${1}_n:-0}\""; }

array_add() {
  _shsh_check_name "$1" || return 1
  eval "_aa_idx=\${__shsh_${1}_n:-0}"
  eval "__shsh_${1}_$_aa_idx=\"\$2\"; __shsh_${1}_n=$((_aa_idx + 1))"
}

array_for() {
  case "$1" in ""|*[!a-zA-Z0-9_]*) return 1;; esac
  _af_d=${_af_d:--1}; _af_d=$((_af_d + 1))
  eval "_af_len_$_af_d=\"\${__shsh_${1}_n:-0}\"; _af_i_$_af_d=0"

  while eval "[ \$(( \$_af_i_$_af_d + 4 )) -le \$_af_len_$_af_d ]"; do
    eval "_idx=\$_af_i_$_af_d"
    eval "R0=\"\${__shsh_${1}_$((_idx))}\"; \
          R1=\"\${__shsh_${1}_$((_idx+1))}\"; \
          R2=\"\${__shsh_${1}_$((_idx+2))}\"; \
          R3=\"\${__shsh_${1}_$((_idx+3))}\""

    R="$R0"; "$2" || { _af_d=$((_af_d - 1)); return 0; }
    R="$R1"; "$2" || { _af_d=$((_af_d - 1)); return 0; }
    R="$R2"; "$2" || { _af_d=$((_af_d - 1)); return 0; }
    R="$R3"; "$2" || { _af_d=$((_af_d - 1)); return 0; }

    eval "_af_i_$_af_d=\$((\$_af_i_$_af_d + 4))"
  done

  while eval "[ \$_af_i_$_af_d -lt \$_af_len_$_af_d ]"; do
    eval "_af_idx=\$_af_i_$_af_d"
    eval "R=\"\${__shsh_${1}_$_af_idx}\""
    "$2" || { _af_d=$((_af_d - 1)); return 0; }
    eval "_af_i_$_af_d=\$((\$_af_i_$_af_d + 1))"
  done
  _af_d=$((_af_d - 1))
}

array_clear() { _shsh_check_name "$1" || return 1; eval "__shsh_${1}_n=0"; }
array_clear_full() {
  _shsh_check_name "$1" || return 1
  eval "_ac_len=\"\${__shsh_${1}_n:-0}\""
  _ac_i=0

  while [ $((_ac_i + 4)) -le "$_ac_len" ]; do
    eval "unset __shsh_${1}_$((_ac_i)) \
                 __shsh_${1}_$((_ac_i+1)) \
                 __shsh_${1}_$((_ac_i+2)) \
                 __shsh_${1}_$((_ac_i+3))"
    _ac_i=$((_ac_i + 4))
  done

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

  while [ $((_ar_i + 4)) -lt "$_ar_len" ]; do
    eval "_idx=$_ar_i"

    eval "__shsh_${1}_$((_idx))=\"\${__shsh_${1}_$((_idx+1))}\"; \
          __shsh_${1}_$((_idx+1))=\"\${__shsh_${1}_$((_idx+2))}\"; \
          __shsh_${1}_$((_idx+2))=\"\${__shsh_${1}_$((_idx+3))}\"; \
          __shsh_${1}_$((_idx+3))=\"\${__shsh_${1}_$((_idx+4))}\""

    _ar_i=$((_ar_i + 4))
  done

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
  _shsh_sane "$1" "$2" || return 1

  eval "_mk_len=\"\${__shsh_mapkeys_${1}_n:-0}\""
  _mk_i=0

  eval "_out_idx=\"\${__shsh_${2}_n:-0}\""

  while eval "[ \$(( \$_mk_i + 4 )) -le \$_mk_len ]"; do
    eval "_idx=\$_mk_i"

    eval "K0=\"\${__shsh_mapkeys_${1}_$((_idx))}\"; \
          K1=\"\${__shsh_mapkeys_${1}_$((_idx+1))}\"; \
          K2=\"\${__shsh_mapkeys_${1}_$((_idx+2))}\"; \
          K3=\"\${__shsh_mapkeys_${1}_$((_idx+3))}\""

    eval "X0=\"\${__shsh_map_${1}_${K0}+x}\"; \
          X1=\"\${__shsh_map_${1}_${K1}+x}\"; \
          X2=\"\${__shsh_map_${1}_${K2}+x}\"; \
          X3=\"\${__shsh_map_${1}_${K3}+x}\""

    [ -n "$X0" ] && { eval "__shsh_${2}_$_out_idx=\"\$K0\""; _out_idx=$((_out_idx + 1)); }
    [ -n "$X1" ] && { eval "__shsh_${2}_$_out_idx=\"\$K1\""; _out_idx=$((_out_idx + 1)); }
    [ -n "$X2" ] && { eval "__shsh_${2}_$_out_idx=\"\$K2\""; _out_idx=$((_out_idx + 1)); }
    [ -n "$X3" ] && { eval "__shsh_${2}_$_out_idx=\"\$K3\""; _out_idx=$((_out_idx + 1)); }

    eval "_mk_i=\$((\$_mk_i + 4))"
  done

  while eval "[ \$_mk_i -lt \$_mk_len ]"; do
    eval "_mk_key=\"\${__shsh_mapkeys_${1}_$_mk_i}\""
    eval "_mk_exists=\"\${__shsh_map_${1}_${_mk_key}+x}\""
    if [ -n "$_mk_exists" ]; then
      eval "__shsh_${2}_$_out_idx=\"\$_mk_key\""
      _out_idx=$((_out_idx + 1))
    fi
    _mk_i=$((_mk_i + 1))
  done

  eval "__shsh_${2}_n=$_out_idx"
}

map_for() {
  _shsh_check_name "$1" || return 1
  _mf_d=${_mf_d:--1}; _mf_d=$((_mf_d + 1))
  eval "_mf_len_$_mf_d=\"\${__shsh_mapkeys_${1}_n:-0}\"; _mf_i_$_mf_d=0"

  while eval "[ \$(( \$_mf_i_$_mf_d + 4 )) -le \$_mf_len_$_mf_d ]"; do
    eval "_idx=\$_mf_i_$_mf_d"

    eval "K0=\"\${__shsh_mapkeys_${1}_$((_idx))}\"; \
          K1=\"\${__shsh_mapkeys_${1}_$((_idx+1))}\"; \
          K2=\"\${__shsh_mapkeys_${1}_$((_idx+2))}\"; \
          K3=\"\${__shsh_mapkeys_${1}_$((_idx+3))}\""

    eval "V0=\"\${__shsh_map_${1}_${K0}}\"; X0=\"\${__shsh_map_${1}_${K0}+x}\"; \
          V1=\"\${__shsh_map_${1}_${K1}}\"; X1=\"\${__shsh_map_${1}_${K1}+x}\"; \
          V2=\"\${__shsh_map_${1}_${K2}}\"; X2=\"\${__shsh_map_${1}_${K2}+x}\"; \
          V3=\"\${__shsh_map_${1}_${K3}}\"; X3=\"\${__shsh_map_${1}_${K3}+x}\""

    if [ -n "$X0" ]; then R="$V0"; K="$K0"; "$2" || { _mf_d=$((_mf_d - 1)); return 0; }; fi
    if [ -n "$X1" ]; then R="$V1"; K="$K1"; "$2" || { _mf_d=$((_mf_d - 1)); return 0; }; fi
    if [ -n "$X2" ]; then R="$V2"; K="$K2"; "$2" || { _mf_d=$((_mf_d - 1)); return 0; }; fi
    if [ -n "$X3" ]; then R="$V3"; K="$K3"; "$2" || { _mf_d=$((_mf_d - 1)); return 0; }; fi

    eval "_mf_i_$_mf_d=\$((\$_mf_i_$_mf_d + 4))"
  done

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

file_write() { printf '%s\n' "$2" > "$1"; }
file_append() { printf '%s\n' "$2" >> "$1"; }
file_exists() { [ -f "$1" ]; }
dir_exists() { [ -d "$1" ]; }
file_executable() { [ -x "$1" ]; }
path_writable() { [ -w "$1" ]; }

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
    if [ "$_tk_escape" -eq 0 ]; then
      _tk_chunk=""
      if [ "$_tk_in_sq" -eq 1 ]; then
        _tk_chunk="${_tk_input%%\'*}"
      elif [ "$_tk_in_dq" -eq 1 ]; then
        _tk_chunk="${_tk_input%%[\"\\]*}"
      else
        _tk_chunk="${_tk_input%%[ \(\)\"\'\\]*}"
      fi

      if [ -n "$_tk_chunk" ]; then
         if [ "$_tk_chunk" != "$_tk_input" ]; then
           _tk_token="$_tk_token$_tk_chunk"
           _tk_input="${_tk_input#$_tk_chunk}"
           continue
         elif [ "$_tk_in_sq" -eq 1 ] || [ "$_tk_in_dq" -eq 1 ]; then
            _tk_token="$_tk_token$_tk_chunk"
            _tk_input=""
            continue
         else
             _tk_token="$_tk_token$_tk_chunk"
             _tk_input=""
             continue
         fi
      fi
    fi

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
        [ -n "$_tk_token" ] && {
            eval "_aa_idx=\${__shsh_${_tk_out}_n:-0}"
            eval "__shsh_${_tk_out}_$_aa_idx=\"\$_tk_token\"; __shsh_${_tk_out}_n=$((_aa_idx + 1))"
            _tk_token=""; 
        }
        eval "_aa_idx=\${__shsh_${_tk_out}_n:-0}"
        eval "__shsh_${_tk_out}_$_aa_idx=\"\$_tk_char\"; __shsh_${_tk_out}_n=$((_aa_idx + 1))"
        ;;
      " " | "	")
        [ -n "$_tk_token" ] && { 
            eval "_aa_idx=\${__shsh_${_tk_out}_n:-0}"
            eval "__shsh_${_tk_out}_$_aa_idx=\"\$_tk_token\"; __shsh_${_tk_out}_n=$((_aa_idx + 1))"
            _tk_token=""; 
        }
        ;;
      *)
        _tk_token="$_tk_token$_tk_char"
        ;;
    esac
  done
  [ -n "$_tk_token" ] && array_add "$_tk_out" "$_tk_token"
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
  while [ $# -ge 4 ]; do
    _v0=$((${1%,})); _v1=$((${2%,})); _v2=$((${3%,})); _v3=$((${4%,}))

    _b1=$(( (_v0 >> 24) & 0xff )); _b2=$(( (_v0 >> 16) & 0xff ))
    _b3=$(( (_v0 >> 8) & 0xff )); _b4=$(( _v0 & 0xff ))
    _o0_be="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"
    _o0_le="\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))"

    _b1=$(( (_v1 >> 24) & 0xff )); _b2=$(( (_v1 >> 16) & 0xff ))
    _b3=$(( (_v1 >> 8) & 0xff )); _b4=$(( _v1 & 0xff ))
    _o1_be="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"
    _o1_le="\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))"

    _b1=$(( (_v2 >> 24) & 0xff )); _b2=$(( (_v2 >> 16) & 0xff ))
    _b3=$(( (_v2 >> 8) & 0xff )); _b4=$(( _v2 & 0xff ))
    _o2_be="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"
    _o2_le="\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))"

    _b1=$(( (_v3 >> 24) & 0xff )); _b2=$(( (_v3 >> 16) & 0xff ))
    _b3=$(( (_v3 >> 8) & 0xff )); _b4=$(( _v3 & 0xff ))
    _o3_be="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"
    _o3_le="\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))"

    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) _b32_buf="$_b32_buf$_o0_be$_o1_be$_o2_be$_o3_be" ;;
      *)                   _b32_buf="$_b32_buf$_o0_le$_o1_le$_o2_le$_o3_le" ;;
    esac
    shift 4
  done

  for _b32_arg in "$@"; do
    _b32_v=$((${_b32_arg%,}))
    _b1=$(( (_b32_v >> 24) & 0xff )); _b2=$(( (_b32_v >> 16) & 0xff ))
    _b3=$(( (_b32_v >> 8) & 0xff )); _b4=$(( _b32_v & 0xff ))
    _o1="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))"; _o2="\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))"
    _o3="\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))"; _o4="\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"
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
    _h3=$(( (_b64_h >> 8) & 0xff )); _h4=$(( _b64_h & 0xff ))
    _l1=$(( (_b64_l >> 24) & 0xff )); _l2=$(( (_b64_l >> 16) & 0xff ))
    _l3=$(( (_b64_l >> 8) & 0xff )); _l4=$(( _b64_l & 0xff ))
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
    _b128_a="0x$(printf "%.8s" "$_b128_s")"
    _b128_b="0x$(printf "%.8s" "${_b128_s#????????}")"
    _b128_c="0x$(printf "%.8s" "${_b128_s#????????????????}")"
    _b128_d="0x${_b128_s#????????????????????????}"
    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) bit_32 "$_b128_a" "$_b128_b" "$_b128_c" "$_b128_d" ;;
      *)                   bit_32 "$_b128_d" "$_b128_c" "$_b128_b" "$_b128_a" ;;
    esac
  done
}

file_hash() {
  path="$1"

  if ! [ -f "$path" ]; then
    return 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    out=$(sha256sum "$path" 2>/dev/null) || return 1
    R=$(echo "$out" | awk '{print $1}')
    return 0
  fi

  if command -v shasum >/dev/null 2>&1; then
    out=$(shasum -a 256 "$path" 2>/dev/null) || return 1
    R=$(echo "$out" | awk '{print $1}')
    return 0
  fi

  if command -v md5sum >/dev/null 2>&1; then
    out=$(md5sum "$path" 2>/dev/null) || return 1
    R=$(echo "$out" | awk '{print $1}')
    return 0
  fi

  if command -v cksum >/dev/null 2>&1; then
    out=$(cksum "$path" 2>/dev/null) || return 1
    R=$(echo "$out" | awk '{print $1}')
    return 0
  fi

  return 1
}

if [ -z "$_shsh_tmp_counter" ]; then
  _shsh_tmp_counter=0
fi

tmp_file() {
  base="$TMPDIR"
  if [ -z "$base" ]; then
    base="/tmp"
  fi

  while true; do
    _shsh_tmp_counter=$((_shsh_tmp_counter + 1))
    name="shsh_$$_${_shsh_tmp_counter}.tmp"
    path="$base/$name"

    if ! [ -f "$path" ]; then
      : > "$path" || return 1
      R="$path"
      return 0
    fi
  done
}

tmp_dir() {
  base="$TMPDIR"
  if [ -z "$base" ]; then
    base="/tmp"
  fi

  while true; do
    _shsh_tmp_counter=$((_shsh_tmp_counter + 1))
    name="shsh_$$_${_shsh_tmp_counter}.d"
    path="$base/$name"

    if mkdir "$path" 2>/dev/null; then
      R="$path"
      return 0
    fi
  done
}

_shsh_test_pass=0
_shsh_test_fail=0
_shsh_test_name=""

test_start() {
  _shsh_test_name="$1"
}

test_end() {
  if [ "$_shsh_test_fail" -gt 0 ]; then
    printf '\n%s passed, %s failed\n' "$_shsh_test_pass" "$_shsh_test_fail"
    exit 1
  else
    printf '\n%s passed\n' "$_shsh_test_pass"
  fi
}

test_pass() {
  printf '✓ %s\n' "$_shsh_test_name"
  _shsh_test_pass=$((_shsh_test_pass + 1))
}

test_fail() {
  printf '✗ %s: %s\n' "$_shsh_test_name" "$1"
  _shsh_test_fail=$((_shsh_test_fail + 1))
}

test_equals() {
  if [ "$1" = "$2" ]; then
    test_pass
  else
    test_fail "expected '$2', got '$1'"
  fi
}

test_not_equals() {
  if [ "$1" != "$2" ]; then
    test_pass
  else
    test_fail "expected not '$2', got '$1'"
  fi
}

test_true() {
  if [ "$1" = "1" ] || [ "$1" = "true" ]; then
    test_pass
  else
    test_fail "expected true, got '$1'"
  fi
}

test_false() {
  if [ "$1" = "0" ] || [ "$1" = "false" ] || [ -z "$1" ]; then
    test_pass
  else
    test_fail "expected false, got '$1'"
  fi
}

test_ok() {
  if [ "$1" -eq 0 ]; then
    test_pass
  else
    test_fail "expected exit code 0, got '$1'"
  fi
}

test_err() {
  if [ "$1" -ne 0 ]; then
    test_pass
  else
    test_fail "expected non-zero exit code, got 0"
  fi
}

test_contains() {
  case "$1" in
    *"$2"*) test_pass ;;
    *) test_fail "'$1' does not contain '$2'" ;;
  esac
}

test_starts() {
  case "$1" in
    "$2"*) test_pass ;;
    *) test_fail "'$1' does not start with '$2'" ;;
  esac
}

test_ends() {
  case "$1" in
    *"$2") test_pass ;;
    *) test_fail "'$1' does not end with '$2'" ;;
  esac
}

test_file_exists() {
  if [ -f "$1" ]; then
    test_pass
  else
    test_fail "file '$1' does not exist"
  fi
}

test_dir_exists() {
  if [ -d "$1" ]; then
    test_pass
  else
    test_fail "directory '$1' does not exist"
  fi
}
# __RUNTIME_END__

block_stack=""
single_line_if_active=0
single_line_if_indent=""
test_block_name=""

push() { block_stack="$block_stack$1"; }
pop()  { block_stack="${block_stack%?}"; }
peek() { R="${block_stack#"${block_stack%?}"}"; }
switch_mark_used() { block_stack="${block_stack%?}S"; }
switch_mark_closed() { block_stack="${block_stack%?}s"; }

_is_simple_stmt() {
  case $1 in
  "if "*|"while "*|"for "*|"switch "*|"try"|"test "*)return 1;;
  esac
  return 0
}

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

emit_try_break() {
  if in_try_block; then
    current_try_depth
    printf '%s[ "$_shsh_brk_%s" -eq 1 ] && break\n' "$1" "$R"
  fi
}

_transform_arith() {
  _ta_stmt="$1"

  _ta_suffix="" _ta_delta=""
  case $_ta_stmt in
  *"++")_ta_suffix="++"; _ta_delta="+ 1";;
  *"--")_ta_suffix="--"; _ta_delta="- 1";;
  esac
  if [ -n "$_ta_suffix" ]; then
    _ta_var="${_ta_stmt%"$_ta_suffix"}"
    case $_ta_var in
    ""|*[!a-zA-Z0-9_]*)return 1;;
    esac
    R="${_ta_var}=\$((${_ta_var} ${_ta_delta}))"
    return 0
  fi

  _ta_op="" _ta_shell_op=""
  case $_ta_stmt in
  *" += "*)_ta_op=" += "; _ta_shell_op="+";;
  *" -= "*)_ta_op=" -= "; _ta_shell_op="-";;
  *" *= "*)_ta_op=" *= "; _ta_shell_op="*";;
  *" /= "*)_ta_op=" /= "; _ta_shell_op="/";;
  *" %= "*)_ta_op=" %= "; _ta_shell_op="%";;
  *)return 1;;
  esac

  _ta_var="${_ta_stmt%%"$_ta_op"*}"
  case $_ta_var in
  ""|*[!a-zA-Z0-9_]*)return 1;;
  esac
  _ta_val="${_ta_stmt#*"$_ta_op"}"
  R="${_ta_var}=\$((${_ta_var} ${_ta_shell_op} ${_ta_val}))"
  return 0
}

transform_statement() {
  _ts_stmt="${1#"${1%%[![:space:]]*}"}"

  if _transform_arith "$_ts_stmt"; then
    return
  fi

  case $_ts_stmt in
  *" = "*)
    _ts_var="${_ts_stmt%%" = "*}"
    case $_ts_var in
    *[!a-zA-Z0-9_]*|"")
      R="$_ts_stmt"
      ;;
    *)
      _ts_call="${_ts_stmt#*" = "}"
      case $_ts_call in
      '"'*|"'"*|'$'*|""|*'='*)
        R="$_ts_stmt"
        ;;
      *)R="${_ts_call}; ${_ts_var}=\$R";;
      esac
    ;;esac
    ;;
  *)R="$_ts_stmt";;
  esac
}

_oac_fail() { R=$_oac_stmt; return 1; }
_oac_check_name() { case $1 in ""|*[!a-zA-Z0-9_]*) return 1;; esac; }
_oac_check_int() { case $1 in ""|*[!0-9]*) return 1;; esac; }
_oac_unquote() {
  case $1 in
  '"'*'"')R=${1#\"}; R=${R%\"};;
  "'"*"'")R=${1#\'}; R=${R%\'};;
  *)return 1;;
  esac
}
_oac_extract_var() {
  case $1 in
  '"$'*'"')R=${1#\"\$}; R=${R%\"}; _oac_check_name "$R";;
  '$'[a-zA-Z_]*)R=${1#\$}; _oac_check_name "$R";;
  *)return 1;;
  esac
}
_oac_parse_1arg() {
  R=${_oac_stmt#*"$1 "}; [ "$R" != "$_oac_stmt" ]; _oac_arg1=$R
}
_oac_parse_2args() {
  R=${_oac_stmt#*"$1 "}; [ "$R" != "$_oac_stmt" ]; _oac_rest=$R
  R=${_oac_rest%%" "*}; [ "$R" != "$_oac_rest" ]; _oac_arg1=$R
  R=${_oac_rest#*" "}; [ "$R" != "$_oac_rest" ]; _oac_arg2=$R
}
_oac_parse_3args() {
  R=${_oac_stmt#*"$1 "}; [ "$R" != "$_oac_stmt" ]; _oac_rest=$R
  R=${_oac_rest%%" "*}; [ "$R" != "$_oac_rest" ]; _oac_arg1=$R
  R=${_oac_rest#*" "}; [ "$R" != "$_oac_rest" ]; _oac_rest=$R
  R=${_oac_rest%%" "*}; [ "$R" != "$_oac_rest" ]; _oac_arg2=$R
  R=${_oac_rest#*" "}; [ "$R" != "$_oac_rest" ]; _oac_arg3=$R
}

optimize_static() {
  _oac_stmt="$1"
  case $_oac_stmt in
  "array_get "*)
    _oac_parse_2args "array_get"
    _oac_name="$_oac_arg1"; _oac_idx="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    _oac_check_int "$_oac_idx" || _oac_fail || return 1
    R="R=\${__shsh_${_oac_name}_${_oac_idx}}; [ \"\${__shsh_${_oac_name}_${_oac_idx}+x}\" ]"
    return 0
    ;;
  "map_get "*)
    _oac_parse_2args "map_get"
    _oac_name="$_oac_arg1"
    _oac_unquote "$_oac_arg2" && _oac_key="$R" || _oac_key="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    _oac_check_name "$_oac_key" || _oac_fail || return 1
    R="R=\${__shsh_map_${_oac_name}_${_oac_key}}"
    return 0
    ;;
  "map_has "*)
    _oac_parse_2args "map_has"
    _oac_name="$_oac_arg1"
    _oac_unquote "$_oac_arg2" && _oac_key="$R" || _oac_key="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    _oac_check_name "$_oac_key" || _oac_fail || return 1
    R="[ \"\${__shsh_map_${_oac_name}_${_oac_key}+x}\" ]"
    return 0
    ;;
  "array_len "*)
    _oac_parse_1arg "array_len"
    _oac_name="$_oac_arg1"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    R="R=\${__shsh_${_oac_name}_n:-0}"
    return 0
    ;;
  "array_set "*)
    _oac_parse_3args "array_set"
    _oac_name="$_oac_arg1"; _oac_idx="$_oac_arg2"; _oac_val="$_oac_arg3"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    _oac_check_int "$_oac_idx" || _oac_fail || return 1
    R="__shsh_${_oac_name}_${_oac_idx}=${_oac_val}; [ ${_oac_idx} -ge \${__shsh_${_oac_name}_n:-0} ] && __shsh_${_oac_name}_n=\$((${_oac_idx} + 1))"
    return 0
    ;;
  "map_set "*)
    _oac_parse_3args "map_set"
    _oac_name="$_oac_arg1"; _oac_val="$_oac_arg3"
    _oac_unquote "$_oac_arg2" && _oac_key="$R" || _oac_key="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    _oac_check_name "$_oac_key" || _oac_fail || return 1
    R="__shsh_map_${_oac_name}_${_oac_key}=${_oac_val}; [ \"\${__shsh_map_${_oac_name}_${_oac_key}__exists}\" ] || { __shsh_map_${_oac_name}_${_oac_key}__exists=1; _ms_i=\${__shsh_mapkeys_${_oac_name}_n:-0}; eval \"__shsh_mapkeys_${_oac_name}_\$_ms_i=\\\"${_oac_key}\\\"\"; __shsh_mapkeys_${_oac_name}_n=\$((_ms_i + 1)); }"
    return 0
    ;;
  "map_delete "*)
    _oac_parse_2args "map_delete"
    _oac_name="$_oac_arg1"
    _oac_unquote "$_oac_arg2" && _oac_key="$R" || _oac_key="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    _oac_check_name "$_oac_key" || _oac_fail || return 1
    R="unset __shsh_map_${_oac_name}_${_oac_key}"
    return 0
    ;;
  "array_clear "*)
    _oac_parse_1arg "array_clear"
    _oac_name="$_oac_arg1"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    R="__shsh_${_oac_name}_n=0"
    return 0
    ;;
  "array_add "*)
    _oac_parse_2args "array_add"
    _oac_name="$_oac_arg1"; _oac_val="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    if _oac_unquote "$_oac_val"; then
      case $R in
      *'"'*|*"'"*|*'\\'*)_oac_fail; return 1;;
      esac
      _oac_val="$R"
    fi
    R="_aa_i=\${__shsh_${_oac_name}_n:-0}; eval \"__shsh_${_oac_name}_\$_aa_i=\\\"${_oac_val}\\\"\"; __shsh_${_oac_name}_n=\$((_aa_i + 1))"
    return 0
    ;;
  "str_before "*)
    _oac_parse_2args "str_before"
    _oac_unquote "$_oac_arg2" || _oac_fail || return 1; _oac_delim="$R"
    case $_oac_delim in
    '"'|"'")_oac_fail; return 1;;
    esac
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}%%\"${_oac_delim}\"*}; [ \"\$R\" != \"\$${_oac_varname}\" ]"
    return 0
    ;;
  "str_before_last "*)
    _oac_parse_2args "str_before_last"
    _oac_unquote "$_oac_arg2" || _oac_fail || return 1; _oac_delim="$R"
    case $_oac_delim in
    '"'|"'")_oac_fail; return 1;;
    esac
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}%\"${_oac_delim}\"*}; [ \"\$R\" != \"\$${_oac_varname}\" ]"
    return 0
    ;;
  "str_after "*)
    _oac_parse_2args "str_after"
    _oac_unquote "$_oac_arg2" || _oac_fail || return 1; _oac_delim="$R"
    case $_oac_delim in
    '"'|"'")_oac_fail; return 1;;
    esac
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}#*\"${_oac_delim}\"}; [ \"\$R\" != \"\$${_oac_varname}\" ]"
    return 0
    ;;
  "str_after_last "*)
    _oac_parse_2args "str_after_last"
    _oac_unquote "$_oac_arg2" || _oac_fail || return 1; _oac_delim="$R"
    case $_oac_delim in
    '"'|"'")_oac_fail; return 1;;
    esac
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}##*\"${_oac_delim}\"}; [ \"\$R\" != \"\$${_oac_varname}\" ]"
    return 0
    ;;
  "str_contains "*)
    _oac_parse_2args "str_contains"
    _oac_unquote "$_oac_arg2" || _oac_fail || return 1; _oac_delim="$R"
    case $_oac_delim in
    '"'|"'")_oac_fail; return 1;;
    esac
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="case \"\$${_oac_varname}\" in *\"${_oac_delim}\"*) ;; *) false;; esac"
    return 0
    ;;
  "str_starts "*)
    _oac_parse_2args "str_starts"
    _oac_unquote "$_oac_arg2" || _oac_fail || return 1; _oac_delim="$R"
    case $_oac_delim in
    '"'|"'")_oac_fail; return 1;;
    esac
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="case \"\$${_oac_varname}\" in \"${_oac_delim}\"*) ;; *) false;; esac"
    return 0
    ;;
  "str_ends "*)
    _oac_parse_2args "str_ends"
    _oac_unquote "$_oac_arg2" || _oac_fail || return 1; _oac_delim="$R"
    case $_oac_delim in
    '"'|"'")_oac_fail; return 1;;
    esac
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="case \"\$${_oac_varname}\" in *\"${_oac_delim}\") ;; *) false;; esac"
    return 0
    ;;
  "str_trim "*)
    _oac_parse_1arg "str_trim"
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}#\"\${${_oac_varname}%%[![:space:]]*}\"}; R=\${R%\"\${R##*[![:space:]]}\"}"
    return 0
    ;;
  "str_ltrim "*)
    _oac_parse_1arg "str_ltrim"
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}#\"\${${_oac_varname}%%[![:space:]]*}\"}"
    return 0
    ;;
  "str_rtrim "*)
    _oac_parse_1arg "str_rtrim"
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}%\"\${${_oac_varname}##*[![:space:]]}\"}"
    return 0
    ;;
  "str_indent "*)
    _oac_parse_1arg "str_indent"
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}%%[![:space:]]*}"
    return 0
    ;;
  "str_split_indent "*)
    _oac_parse_1arg "str_split_indent"
    _oac_extract_var "$_oac_arg1" || _oac_fail || return 1; _oac_varname="$R"
    R="R=\${${_oac_varname}%%[![:space:]]*}; R2=\${${_oac_varname}#\"\$R\"}"
    return 0
    ;;
  "file_exists "*)
    _oac_parse_1arg "file_exists"
    _oac_path="$_oac_arg1"
    R="[ -f ${_oac_path} ]"
    return 0
    ;;
  "dir_exists "*)
    _oac_parse_1arg "dir_exists"
    _oac_path="$_oac_arg1"
    R="[ -d ${_oac_path} ]"
    return 0
    ;;
  "file_executable "*)
    _oac_parse_1arg "file_executable"
    _oac_path="$_oac_arg1"
    R="[ -x ${_oac_path} ]"
    return 0
    ;;
  "path_writable "*)
    _oac_parse_1arg "path_writable"
    _oac_path="$_oac_arg1"
    R="[ -w ${_oac_path} ]"
    return 0
    ;;
  "default "*)
    _oac_parse_2args "default"
    _oac_name="$_oac_arg1"; _oac_val="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    R="[ -z \"\${${_oac_name}}\" ] && ${_oac_name}=${_oac_val}"
    return 0
    ;;
  "default_unset "*)
    _oac_parse_2args "default_unset"
    _oac_name="$_oac_arg1"; _oac_val="$_oac_arg2"
    _oac_check_name "$_oac_name" || _oac_fail || return 1
    R="[ -z \"\${${_oac_name}+x}\" ] && ${_oac_name}=${_oac_val}"
    return 0
    ;;
  *)R="$_oac_stmt"; return 1;;
  esac
}

transform_semicolon_parts() {
  _tsp_line="$1"
  _tsp_out=""
  _tsp_sep=""

  while :; do
    case $_tsp_line in
    *"; "*)
      ;;
    *)break;;
    esac
    _tsp_part="${_tsp_line%%; *}"
    _tsp_line="${_tsp_line#*"; "}"
    if ! optimize_static "$_tsp_part"; then
      transform_statement "$_tsp_part"
    fi
    _tsp_out="$_tsp_out$_tsp_sep$R"
    _tsp_sep="; "
  done

  if ! optimize_static "$_tsp_line"; then
    transform_statement "$_tsp_line"
  fi
  _tsp_out="$_tsp_out$_tsp_sep$R"
  R="$_tsp_out"
}

_parse_colon_syntax() {
  case $1 in
  *": "*)
    ;;
  *)return 1;;
  esac
  _pcs_search="$1" _pcs_prefix=""
  while :; do
    case $_pcs_search in
    *": "*)
      ;;
    *)break;;
    esac
    _pcs_cond="$_pcs_prefix${_pcs_search%%": "*}"
    _pcs_after="${_pcs_search#*": "}"
    if ! _in_quotes "$_pcs_cond"; then
      case $_pcs_after in
      '"'*|"'"*)
        ;;
      *)
        _pcs_body="$_pcs_after"; return 0
      ;;esac
    fi
    _pcs_prefix="$_pcs_cond: "; _pcs_search="$_pcs_after"
  done
  return 1
}

_strip_inline_end() {
  _has_inline_end=0
  case $_pcs_body in
  *"; end")
    _pcs_body="${_pcs_body%"; end"}"
    _has_inline_end=1
  ;;esac
}

emit_with_try_check() {
  R=${1%%[![:space:]]*}; R2=${1#"$R"}; _ewtc_indent="$R"; _ewtc_stmt="$R2"
  if [ -z "$_ewtc_stmt" ]; then
    printf '\n'
    return
  fi
  case $_ewtc_stmt in
  "{"|"}"|*"() {")
    printf '%s\n' "$1"
    return
  ;;esac
  transform_semicolon_parts "$_ewtc_stmt"
  _ewtc_transformed="${_ewtc_indent}$R"
  if in_try_block; then
    current_try_depth
    printf '%s || { _shsh_err_%s=$?; _shsh_brk_%s=1; break; }\n' "$_ewtc_transformed" "$R" "$R"
  else
    printf '%s\n' "$_ewtc_transformed"
  fi
}

is_comparison() {
  case $1 in
  *" <= "*|*" < "*|*" >= "*|*" > "*|*" == "*|*" != "*)return 0;;
  *)return 1;;
  esac
}

escape_quotes() {
  _eq_in="$1" _eq_out=""
  while :; do
    case $_eq_in in
    *'"'*)
      ;;
    *)break;;
    esac
    _eq_out="$_eq_out${_eq_in%%\"*}\\\""
    _eq_in="${_eq_in#*\"}"
  done
  R="$_eq_out$_eq_in"
}

parse_comparison() {
  _pc_cond="$1"
  _ec_op="" _ec_shell_op="" _ec_left="" _ec_right=""

  case $_pc_cond in
  *" == "*)
    _ec_left="${_pc_cond%%" == "*}"; _ec_right="${_pc_cond#*" == "}"
    _ec_op="==" _ec_shell_op="="
    ;;
  *" != "*)
    _ec_left="${_pc_cond%%" != "*}"; _ec_right="${_pc_cond#*" != "}"
    _ec_op="!=" _ec_shell_op="!="
    ;;
  *" <= "*)
    _ec_left="${_pc_cond%%" <= "*}"; _ec_right="${_pc_cond#*" <= "}"
    _ec_op="<=" _ec_shell_op="-le"
    ;;
  *" >= "*)
    _ec_left="${_pc_cond%%" >= "*}"; _ec_right="${_pc_cond#*" >= "}"
    _ec_op=">=" _ec_shell_op="-ge"
    ;;
  *" < "*)
    _ec_left="${_pc_cond%%" < "*}"; _ec_right="${_pc_cond#*" < "}"
    _ec_op="<" _ec_shell_op="-lt"
    ;;
  *" > "*)
    _ec_left="${_pc_cond%%" > "*}"; _ec_right="${_pc_cond#*" > "}"
    _ec_op=">" _ec_shell_op="-gt"
    ;;
  *)
    return 1
  ;;esac
}

strip_outer_quotes() {
  _soq_val="$1"
  case $_soq_val in
  '"'*'"')_soq_val="${_soq_val#\"}"; R="${_soq_val%\"}";;
  "'"*"'")_soq_val="${_soq_val#\'}"; R="${_soq_val%\'}";;
  *)R="$_soq_val";;
  esac
}

format_test_operand() {
  _fto_val="$1"
  case $_fto_val in
  '"'*'"')R="$_fto_val";;
  "'"*"'")R="$_fto_val";;
  '$'*)R="\"$_fto_val\"";;
  *[!a-zA-Z0-9_.-]*|"")R="\"$_fto_val\"";;
  *)R="$_fto_val";;
  esac
}

is_simple_var() {
  _isv_cond="$1"
  case $_isv_cond in
  '${'*'}')
    _isv_inner="${_isv_cond#\$\{}"
    _isv_inner="${_isv_inner%\}}"
    case $_isv_inner in
      ""|*[!a-zA-Z0-9_]*)return 1;;
      *)return 0;;
    esac
    ;;
  '$'[0-9])return 0;;
  '$'[a-zA-Z_]*)
    _isv_inner="${_isv_cond#\$}"
    case $_isv_inner in
      *[!a-zA-Z0-9_]*)return 1;;
      *)return 0;;
    esac
    ;;
  *)return 1;;
  esac
}

emit_single_condition() {
  _esc_cond="$1"
  if is_comparison "$_esc_cond"; then
    parse_comparison "$_esc_cond"
    strip_outer_quotes "$_ec_right"; _esc_right_unquoted="$R"
    strip_outer_quotes "$_ec_left"; _esc_left_unquoted="$R"
    if [ -z "$_esc_right_unquoted" ]; then
      if is_simple_var "$_esc_left_unquoted"; then
        if [ "$_ec_shell_op" = "=" ]; then
          R="[ -z \"${_esc_left_unquoted}\" ]"
          return
        elif [ "$_ec_shell_op" = "!=" ]; then
          R="[ -n \"${_esc_left_unquoted}\" ]"
          return
        fi
      fi
    fi
    format_test_operand "$_ec_left"; _emit_left="$R"
    format_test_operand "$_ec_right"; _emit_right="$R"
    R="[ ${_emit_left} ${_ec_shell_op} ${_emit_right} ]"
  else
    case $_esc_cond in
    "nonempty "*)
      _esc_target="${_esc_cond#"nonempty "}"
      format_test_operand "$_esc_target"; _emit_target="$R"
      R="[ -n ${_emit_target} ]"
      ;;
    "! "*)
      _esc_negated="${_esc_cond#"! "}"
      if is_simple_var "$_esc_negated"; then
        R="[ -z \"${_esc_negated}\" ]"
      elif optimize_static "$_esc_negated"; then
        R="! $R"
      else
        R="$_esc_cond"
      fi
      ;;
    *)
      if is_simple_var "$_esc_cond"; then
        R="[ -n \"${_esc_cond}\" ]"
      elif optimize_static "$_esc_cond"; then
        return
      else
        R="$_esc_cond"
      fi
    ;;esac
  fi
}

emit_condition() {
  keyword="$1" condition="$2" indent="$3" suffix="$4"

  case $condition in
  *" && "*|*" || "*)
    _emc_result="" _emc_rest="$condition" _emc_first=1 _emc_prev_op=""
    while [ -n "$_emc_rest" ]; do
      _emc_op=""
      _emc_and_len=999999
      _emc_or_len=999999
      case $_emc_rest in
      *" && "*)
        _emc_and_pos="${_emc_rest%% && *}"
        _emc_and_len="${#_emc_and_pos}"
      ;;esac
      case $_emc_rest in
      *" || "*)
        _emc_or_pos="${_emc_rest%% || *}"
        _emc_or_len="${#_emc_or_pos}"
      ;;esac

      if [ "$_emc_and_len" -lt "$_emc_or_len" ]; then
        _emc_part="${_emc_rest%%" && "*}"
        _emc_rest="${_emc_rest#*" && "}"
        _emc_op=" && "
      elif [ "$_emc_or_len" -lt 999999 ]; then
        _emc_part="${_emc_rest%%" || "*}"
        _emc_rest="${_emc_rest#*" || "}"
        _emc_op=" || "
      else
        _emc_part="$_emc_rest"
        _emc_rest=""
      fi

      emit_single_condition "$_emc_part"
      if [ "$_emc_first" = "1" ]; then
        _emc_result="$R"
        _emc_first=0
      else
        _emc_result="$_emc_result$_emc_prev_op$R"
      fi
      _emc_prev_op="$_emc_op"
    done
    printf '%s\n' "${_emit_prefix}${indent}${keyword} ${_emc_result}${suffix}"
    ;;
  *)
    emit_single_condition "$condition"
    printf '%s\n' "${_emit_prefix}${indent}${keyword} ${R}${suffix}"
  ;;esac
  _emit_prefix=""
}

emit_inline_statement() {
  inline_indent="$1"
  inline_statement="$2"
  if [ -z "$inline_statement" ]; then
    return
  fi

  inline_statement="${inline_statement#"${inline_statement%%[![:space:]]*}"}"

  case $inline_statement in
  "if "*)
    inline_rest="${inline_statement#"if "}"
    case $inline_rest in
    *": "*)
      inline_condition="${inline_rest%%": "*}"
      inline_body="${inline_rest#*": "}"
      inline_body="${inline_body#"${inline_body%%[![:space:]]*}"}"
      emit_condition "if" "$inline_condition" "$inline_indent" "; then"
      emit_with_try_check "${inline_indent}  ${inline_body}"
      single_line_if_active=1
      single_line_if_indent="$inline_indent"
      return
    ;;esac
    ;;
  "while "*)
    inline_rest="${inline_statement#"while "}"
    case $inline_rest in
    *": "*)
      inline_condition="${inline_rest%%": "*}"
      inline_body="${inline_rest#*": "}"
      inline_body="${inline_body#"${inline_body%%[![:space:]]*}"}"
      emit_condition "while" "$inline_condition" "$inline_indent" "; do"
      emit_with_try_check "${inline_indent}  ${inline_body}"
      printf "${inline_indent}done\n"
      emit_try_break "$inline_indent"
      return
    ;;esac
  ;;esac

  emit_with_try_check "${inline_indent}${inline_statement}"
}

_handle_conditional() {
  _hc_kw="$1" _hc_rest="$2" _hc_indent="$3" _hc_suffix="$4" _hc_push="$5"

  if _parse_colon_syntax "$_hc_rest"; then
    _strip_inline_end
    emit_condition "$_hc_kw" "$_pcs_cond" "$_hc_indent" "; $_hc_suffix"
    emit_with_try_check "${_hc_indent}  ${_pcs_body}"
    if [ "$_hc_kw" = "while" ]; then
      printf "${_hc_indent}done\n"
      emit_try_break "$_hc_indent"
    elif [ "$_has_inline_end" = 1 ]; then
      printf "${_hc_indent}fi\n"
    elif [ "$_hc_kw" = "if" ]; then
      single_line_if_active=1
      single_line_if_indent="$_hc_indent"
    fi
  else
    case $_hc_rest in
    *"; $_hc_suffix"*)
      printf '%s\n' "${_hc_indent}${_hc_kw} ${_hc_rest}"
      if [ -n "$_hc_push" ]; then
        push "$_hc_push"
      fi
      if [ "$_hc_kw" = "while" ]; then
        push w
      fi
      ;;
    *)
      emit_condition "$_hc_kw" "$_hc_rest" "$_hc_indent" "; $_hc_suffix"
      if [ -n "$_hc_push" ]; then
        push "$_hc_push"
      fi
      if [ "$_hc_kw" = "while" ]; then
        push w
      fi
    ;;esac
  fi
}

_close_single_line_if() {
  if [ "$single_line_if_active" = 0 ]; then
    return 1
  fi
  _csli_indent="$1" _csli_stripped="$2"

  if [ "$_csli_indent" = "$single_line_if_indent" ]; then
    case $_csli_stripped in
    "elif "*)
      case $_csli_stripped in
      *": "*)
        ;;
      *)
        single_line_if_active=0
        push i
      ;;esac
      return 1
      ;;
    "else"*)
      if [ "$_csli_stripped" = "else" ]; then
        single_line_if_active=0
        push i
      fi
      return 1
    ;;esac
  fi

  printf '%s\n' "${single_line_if_indent}fi"
  single_line_if_active=0
  return 0
}

_try_semi_split() {
  _tss_pat="; $1 "
  case $stripped in
  *"$_tss_pat"*)
    ;;
  *)return 1;;
  esac
  R="${stripped%%"$_tss_pat"*}"; _tss_pre="$R"
  _in_quotes "$_tss_pre" && return 1
  R="${stripped#*"$_tss_pat"}"; _tss_rest="$1 $R"
  [ -n "$_tss_pre" ] && { transform_semicolon_parts "$_tss_pre"; printf '%s\n' "${indent}$R"; }
  transform_line "${indent}$_tss_rest"
}

_try_op_split() {
  [ -n "$_emit_prefix" ] && return 1
  _tos_pat=" $1 $2 "
  case $stripped in
  *"$_tos_pat"*)
    ;;
  *)return 1;;
  esac
  R="${stripped%%"$_tos_pat"*}"; _tos_pre="$R"
  _in_quotes "$_tos_pre" && return 1
  _emit_prefix="$_tos_pre $1 "
  R="${stripped#*"$_tos_pat"}"; stripped="$2 $R"
}

transform_line() {
  line="$1"
  R=${line%%[![:space:]]*}; R2=${line#"$R"}; indent="$R"; stripped="$R2"

  _close_single_line_if "$indent" "$stripped"

  case $stripped in
  "#"*)
    case $stripped in
    *"__RUNTIME_"*)
      printf '%s\n' "$line"
    ;;esac
    return
  ;;esac

  _try_semi_split while && return
  _try_semi_split if && return
  _try_semi_split for && return

  _emit_prefix=""
  _try_op_split "|" while || _try_op_split "|" if || _try_op_split "|" for || \
  _try_op_split "&&" if || _try_op_split "&&" while || _try_op_split "||" if

  case $stripped in
  "")
    peek
    case $R in
    s|S)return;;
    *)printf '\n';;
    esac
    ;;
  "#"*)printf '%s\n' "$line";;
  "end")
    peek
    case $R in
    s)printf "${indent}esac\n";;
    S)printf "${indent};;esac\n";;
    i)printf "${indent}fi\n";;
    f)printf "${indent}done\n";;
    w)printf "${indent}done\n"; emit_try_break "$indent";;
    c)printf "${indent}fi\n"; try_depth_dec;;
    t)printf "${indent}_shsh_brk_$try_depth=1; done\n"; try_depth_dec;;
    esac
    pop
    ;;
  "done")
    printf "${indent}done\n"
    emit_try_break "$indent"
    peek
    if [ "$R" = "f" ] || [ "$R" = "w" ]; then
      pop
    fi
    ;;
  "else")
    printf "${indent}else\n"
    ;;
  "elif "*)
    R=${stripped#*"elif "}; [ "$R" != "$stripped" ]
    _handle_conditional "elif" "$R" "$indent" "then" ""
    ;;
  "else:"*|"default:"*)
    if case "$stripped" in "else:"*) ;; *) false;; esac; then
      printf "${indent}else\n"
      R=${stripped#*":"}; [ "$R" != "$stripped" ]; R=${R#"${R%%[![:space:]]*}"}
      if [ -n "$R" ]; then
        emit_inline_statement "${indent}  " "$R"
      fi
    else
      peek
      if [ "$R" = "S" ]; then
        printf "${indent}  ;;\n"
      fi
      R=${stripped#*":"}; [ "$R" != "$stripped" ]; R=${R#"${R%%[![:space:]]*}"}; _default_body="$R"
      if [ -n "$_default_body" ]; then
        if _is_simple_stmt "$_default_body"; then
          transform_semicolon_parts "$_default_body"
          printf '%s\n' "${indent}*)$R;;"
          switch_mark_closed
        else
          switch_mark_used
          printf "${indent}*)\n"
          emit_inline_statement "${indent}  " "$_default_body"
        fi
      else
        switch_mark_used
        printf "${indent}*)\n"
      fi
    fi
    ;;
  "try")
    try_depth_inc
    printf "${indent}_shsh_err_$try_depth=0; _shsh_brk_$try_depth=0; while [ \"\$_shsh_brk_$try_depth\" -eq 0 ]; do\n"
    push t
    ;;
  "catch")
    peek
    if [ "$R" = "t" ]; then
      printf "${indent}_shsh_brk_$try_depth=1; done\n${indent}if [ \"\$_shsh_err_$try_depth\" -ne 0 ]; then error=\$_shsh_err_$try_depth\n"
      pop
      push c
    else
      printf '%s\n' "$line"
    fi
    ;;
  "if "*)
    R=${stripped#*"if "}; [ "$R" != "$stripped" ]
    _handle_conditional "if" "$R" "$indent" "then" "i"
    ;;
  "while "*)
    R=${stripped#*"while "}; [ "$R" != "$stripped" ]
    _handle_conditional "while" "$R" "$indent" "do" ""
    ;;
  "for "*)
    R=${stripped#*"for "}; [ "$R" != "$stripped" ]; _for_rest="$R"
    if case "$stripped" in *"; do"*) ;; *) false;; esac; then
      printf '%s\n' "$line"
    elif _parse_colon_syntax "$_for_rest"; then
      _strip_inline_end
      printf '%s\n' "${indent}for ${_pcs_cond}; do"
      emit_with_try_check "${indent}  ${_pcs_body}"
      printf "${indent}done\n"
      emit_try_break "$indent"
    else
      printf "${indent}${stripped}; do\n"
      push f
    fi
    ;;
  "switch "*)
    R=${stripped#*"switch "}; [ "$R" != "$stripped" ]
    printf "${indent}case $R in\n"
    push s
    ;;
  "case "*)
    peek
    case $R in
    s|S)
      if [ "$R" = "S" ]; then
        printf "${indent}  ;;\n"
      fi
      R=${stripped#*"case "}; [ "$R" != "$stripped" ]; _case_rest="$R"
      if _parse_colon_syntax "$_case_rest"; then
        if [ -n "$_pcs_body" ]; then
          if _is_simple_stmt "$_pcs_body"; then
            transform_semicolon_parts "$_pcs_body"
            printf '%s\n' "${indent}${_pcs_cond})$R;;"
            switch_mark_closed
          else
            switch_mark_used
            printf '%s\n' "${indent}${_pcs_cond})"
            emit_inline_statement "${indent}  " "$_pcs_body"
          fi
        else
          switch_mark_used
          _case_rest="${_case_rest%:}"
          printf '%s\n' "${indent}${_case_rest})"
        fi
      else
        switch_mark_used
        _case_rest="${_case_rest%:}"
        printf '%s\n' "${indent}${_case_rest})"
      fi
      ;;
    *)
      printf '%s\n' "$line"
    ;;esac
    ;;
  "default")
    peek
    case $R in
    s|S)
      if [ "$R" = "S" ]; then
        printf "${indent}  ;;\n"
      fi
      switch_mark_used
      printf "${indent}*)\n"
      ;;
    *)
      printf '%s\n' "$line"
    ;;esac
    ;;
  "test "*" {"*)
    R=${stripped#*"test "}; [ "$R" != "$stripped" ]
    R=${R%%" {"*}; [ "$R" != "$R" ]; _test_name="$R"
    _test_name="${_test_name#\"}"
    _test_name="${_test_name%\"}"
    _test_name="${_test_name#\'}"
    _test_name="${_test_name%\'}"
    printf "${indent}test_start '%s'\n" "$_test_name"
    push T
    ;;
  "}")
    peek
    if [ "$R" = "T" ]; then
      pop
      test_block_name=""
    else
      printf '%s\n' "$line"
    fi
    ;;
  *"++"*|*"--"*|*" += "*|*" -= "*|*" *= "*|*" /= "*|*" %= "*)
    transform_semicolon_parts "$stripped"
    printf '%s\n' "${indent}$R"
    ;;
  *)emit_with_try_check "$line";;
  esac
}

transform() {
  block_stack=""
  single_line_if_active=0
  single_line_if_indent=""
  try_depth=0
  test_block_name=""
  _has_tests=0

  while IFS= read -r current_line || [ -n "$current_line" ]; do
    transform_line "$current_line"
  done

  if [ "$single_line_if_active" = 1 ]; then
    printf "${single_line_if_indent}fi\n"
  fi
  if [ "$_has_tests" = 1 ]; then
    printf "test_end\n"
  fi
}

if [ -f "$1" ]; then
  script="$1"
  shift
  eval "$(transform < "$script")"
  exit
fi

_extract_fn_name() { str_before "$1" "()"; R=${R#"${R%%[![:space:]]*}"}; }

_rt_need_fn() {
  case $_rt_needed in
  *" $1 "*)return;;
  esac
  _rt_needed="$_rt_needed $1 "
  eval "_rnf_deps=\"\$_rt_deps_$1\""
  for _rnf_dep in $_rnf_deps; do
    _rt_need_fn "$_rnf_dep"
  done
}

emit_runtime_stripped() {
  _ers_source="$1"
  _ers_all_fns="" _ers_in_rt=0 _ers_cur_fn="" _ers_cur_body=""
  while IFS= read -r _ers_line || [ -n "$_ers_line" ]; do
    if case "$_ers_line" in "# __RUNTIME_START__"*) ;; *) false;; esac; then
      _ers_in_rt=1; continue
    fi
    if case "$_ers_line" in "# __RUNTIME_END__"*) ;; *) false;; esac; then
      break
    fi
    if [ "$_ers_in_rt" = 0 ]; then
      continue
    fi
    case $_ers_line in
    *"() {"*"}")
      _extract_fn_name "$_ers_line"; _ers_cur_fn="$R"
      _ers_all_fns="$_ers_all_fns $_ers_cur_fn"
      R=${_ers_line#*"() { "}; [ "$R" != "$_ers_line" ]; _ers_cur_body="$R"
      R=${_ers_cur_body%%" }"*}; [ "$R" != "$_ers_cur_body" ]; _ers_cur_body="$R"
      eval "_rt_body_$_ers_cur_fn=\"\$_ers_cur_body\""
      _ers_cur_fn=""
      ;;
    *"() {"*)
      _extract_fn_name "$_ers_line"; _ers_cur_fn="$R"
      _ers_all_fns="$_ers_all_fns $_ers_cur_fn"
      _ers_cur_body=""
      ;;
    "}")
        eval "_rt_body_$_ers_cur_fn=\"\$_ers_cur_body\""
      _ers_cur_fn=""
      ;;
    *)
      if [ -n "$_ers_cur_fn" ]; then
        _ers_cur_body="$_ers_cur_body $_ers_line"
      fi
    ;;esac
  done < "$0"

  for _ers_fn in $_ers_all_fns; do
    eval "_ers_body=\"\$_rt_body_$_ers_fn\""
    _ers_deps=""
    for _ers_other in $_ers_all_fns; do
      if [ "$_ers_fn" != "$_ers_other" ]; then
        case $_ers_body in
        *"$_ers_other"*)
          _ers_deps="$_ers_deps $_ers_other"
        ;;esac
      fi
    done
    eval "_rt_deps_$_ers_fn=\"\$_ers_deps\""
  done

  _rt_needed=" "
  for _ers_fn in $_ers_all_fns; do
    case $_ers_source in
    *"$_ers_fn"*)_rt_need_fn "$_ers_fn";;
    esac
  done

  _ers_combined=$_ers_source
  for _ers_fn in $_ers_all_fns; do
    case $_rt_needed in
    *" $_ers_fn "*)
      eval "_ers_combined=\"\$_ers_combined \$_rt_body_$_ers_fn\""
    ;;esac
  done

  _ers_emit=0 _ers_skip=0 _ers_in_func=0
  while IFS= read -r _ers_line || [ -n "$_ers_line" ]; do
    case $_ers_emit in
    0)
      if case "$_ers_line" in "# __RUNTIME_START__"*) ;; *) false;; esac; then
        _ers_emit=1
      fi
      ;;
    1)
      if case "$_ers_line" in "# __RUNTIME_END__"*) ;; *) false;; esac; then
        _ers_emit=2
      else
        case $_ers_line in
        *"() {"*"}")
          _extract_fn_name "$_ers_line"; _ers_fn="$R"
          case $_rt_needed in
          *" $_ers_fn "*)
            printf '%s\n' "$_ers_line"
          ;;esac
          ;;
        *"() {"*)
          _extract_fn_name "$_ers_line"; _ers_fn="$R"
          case $_rt_needed in
          *" $_ers_fn "*)
            _ers_skip=0
            _ers_in_func=1
            printf '%s\n' "$_ers_line"
            ;;
          *)
            _ers_skip=1
            _ers_in_func=0
          ;;esac
          ;;
        "}")
          if [ "$_ers_skip" = 0 ]; then
            printf '%s\n' "$_ers_line"
          fi
          _ers_skip=0
          _ers_in_func=0
          ;;
        "")
          if [ "$_ers_skip" = 0 ]; then
            if [ "$_ers_in_func" = 1 ]; then
              printf "\n"
            fi
          fi
          ;;
        *"="*)
          if [ "$_ers_in_func" = 0 ]; then
            R=${_ers_line%%"="*}; [ "$R" != "$_ers_line" ]; _ers_varname="$R"
            case $_ers_combined in
            *'$'"$_ers_varname"*|*'$'"{$_ers_varname"*)
              printf '%s\n' "$_ers_line"
            ;;esac
          elif [ "$_ers_skip" = 0 ]; then
            printf '%s\n' "$_ers_line"
          fi
          ;;
        *)
          if [ "$_ers_skip" = 0 ]; then
            if [ "$_ers_in_func" = 1 ]; then
              printf '%s\n' "$_ers_line"
            fi
          fi
        ;;esac
      fi
    ;;esac
  done < "$0"
}

emit_runtime() {
  _er_emit=0
  while IFS= read -r _er_line || [ -n "$_er_line" ]; do
    case $_er_emit in
    0)
      if case "$_er_line" in "# __RUNTIME_START__"*) ;; *) false;; esac; then
        _er_emit=1
        printf "$_er_line\n"
      fi
      ;;
    1)
      printf '%s\n' "$_er_line"
      if case "$_er_line" in "# __RUNTIME_END__"*) ;; *) false;; esac; then
        _er_emit=2
      fi
    ;;esac
  done < "$0"
}

case $1 in
  raw)
    if [ -z "$2" ] || [ "$2" = "-" ]; then
      transform
    else
      transform < "$2"
    fi
    ;;
  build)
    printf '#!/bin/sh\n'
    printf 'if [ -z "$_SHSH_DASH" ] && command -v dash >/dev/null 2>&1; then export _SHSH_DASH=1; exec dash "$0" "$@"; fi\n'
    if [ -z "$2" ] || [ "$2" = "-" ]; then
      _es_code="$(transform)"
    else
      _es_code="$(transform < "$2")"
    fi
    emit_runtime_stripped "$_es_code"
    printf "$_es_code\n"
    ;;
  build_full)
    printf '#!/bin/sh\n'
    printf 'if [ -z "$_SHSH_DASH" ] && command -v dash >/dev/null 2>&1; then export _SHSH_DASH=1; exec dash "$0" "$@"; fi\n'
    emit_runtime
    if [ -z "$2" ]; then
      transform
    else
      transform < "$2"
    fi
    ;;
  -)
    eval "$(transform)"
    ;;
  version|install|update|uninstall|""|--*|-*)
    ;;
  *)
    R=""
    eval "$(printf '%s\n' "$*" | transform)"
    if [ -n "$R" ]; then
      printf '%s\n' "$R"
    fi
    exit
;;esac

case $1 in
  version)
    printf "shsh $VERSION\n"
    ;;
  ""|--*|-*)
    printf "shsh v$VERSION\n\n"
    printf "Self-hosting shell transpiler with a beautifully simple high level syntax for POSIX shells.\n"
    printf "By Dawn Larsson - Apache License 2.0 - https://github.com/dawnlarsson/shsh\n\n"
    printf "usage: shsh [command] [args...]\n\n"
    printf "  <script>               run script file or inline input directly\n"
    printf "  raw [script]           transform (file or stdin)\n"
    printf "  build [script]         emit standalone (stripped runtime)\n"
    printf "  build_full [script]    emit standalone (full runtime)\n"
    printf "  -                      read from stdin\n"
    printf "  install                install to system\n"
    printf "  uninstall              remove from system\n"
    printf "  update                 update from github (sudo)\n"
    printf "  version                show version\n"
    if [ "$_SHSH_FAST" = 0 ]; then
      printf "\n\033[1;33mWarning:\033[0m Install dash for 2-4x speedup (shsh will automatically use dash)\n"
    fi
    ;;
  install|update)
    _is_update=0
    if [ "$1" = "update" ]; then
      _is_update=1
    fi
    _url="https://raw.githubusercontent.com/dawnlarsson/shsh/main/shsh.sh"
    _old_ver="$VERSION"
    _dest=""
    _needs_path=0
    if [ "$_is_update" = 1 ]; then
      for _try_loc in "/usr/local/bin/shsh" "$HOME/.local/bin/shsh" "$HOME/bin/shsh"; do
        if [ -x "$_try_loc" ]; then
          _dest="$_try_loc"
          break
        fi
      done
    fi
    if [ -z "$_dest" ]; then
      for _try_dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
        case ":$PATH:" in
          *":$_try_dir:"*)
            if [ -w "$_try_dir" ]; then
              _dest="$_try_dir/shsh"
              break
            elif [ "$_try_dir" = "/usr/local/bin" ]; then
              _dest="$_try_dir/shsh"
              break
            fi
        ;;esac
      done

      if [ -z "$_dest" ]; then
        mkdir -p "$HOME/.local/bin" || { printf "error: cannot create %s\n" "$HOME/.local/bin" >&2; exit 1; }
        _dest="$HOME/.local/bin/shsh"
        _needs_path=1
      fi
    fi
    _dest_dir=$(dirname "$_dest")
    if ! [ -d "$_dest_dir" ]; then
      mkdir -p "$_dest_dir" 2>/dev/null || sudo mkdir -p "$_dest_dir"
    fi
    _src=""
    if [ "$_is_update" = 1 ]; then
      printf "downloading shsh from github...\n"
      _tmp=$(mktemp)
      _download_ok=0
      if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$_url" -o "$_tmp"; then
          _download_ok=1
        fi
      elif command -v wget >/dev/null 2>&1; then
        if wget -qO "$_tmp" "$_url"; then
          _download_ok=1
        fi
      else
        rm -f "$_tmp"
        printf "error: curl or wget required\n" >&2
        exit 1
      fi
      if [ "$_download_ok" = 0 ]; then
        rm -f "$_tmp"
        printf "error: download failed\n" >&2
        exit 1
      fi
      _src="$_tmp"
    else
      _src="$0"
    fi
    _verb="installed"
    _copy_cmd="cp"
    if [ "$_is_update" = 1 ]; then
      _verb="updated"
      _copy_cmd="mv"
    fi
    if $_copy_cmd "$_src" "$_dest" 2>/dev/null && chmod +x "$_dest" 2>/dev/null; then
      printf "%s: %s\n" "$_verb" "$_dest"
    else
      printf "installing to %s (requires sudo)...\n" "$_dest"
      sudo $_copy_cmd "$_src" "$_dest" && sudo chmod +x "$_dest"
      sudo chown "$USER" "$_dest"
      printf "%s: %s\n" "$_verb" "$_dest"
    fi
    if [ "$_is_update" = 1 ]; then
      _new_ver=$("$_dest" -v 2>/dev/null | sed 's/shsh //')
      if [ "$_new_ver" = "$_old_ver" ]; then
        printf "version: %s (already up to date)\n" "$_old_ver"
      else
        printf "version: %s -> %s\n" "$_old_ver" "$_new_ver"
      fi
    fi
    if [ "$_needs_path" = 1 ] && [ "$_is_update" = 0 ]; then
      _shell_rc=""
      _path_export='export PATH="$HOME/.local/bin:$PATH"'

      case $SHELL in
        */bash)
          if [ -f "$HOME/.bash_profile" ]; then
            _shell_rc="$HOME/.bash_profile"
          elif [ -f "$HOME/.bash_login" ]; then
            _shell_rc="$HOME/.bash_login"
          else
            _shell_rc="$HOME/.bashrc"
          fi
          ;;
        */zsh)_shell_rc="$HOME/.zshrc";;
        */fish)
          _shell_rc="$HOME/.config/fish/config.fish"
          _path_export='set -gx PATH $HOME/.local/bin $PATH'
          ;;
        *)_shell_rc="$HOME/.profile";;
      esac

      _already_configured=0
      if [ -f "$_shell_rc" ]; then
        if grep -qE '(\.local/bin|HOME/.local/bin)' "$_shell_rc" 2>/dev/null; then
          _already_configured=1
        fi
      fi

      if [ "$_already_configured" = 0 ]; then
        printf '\n# shsh - added by installer\n%s\n' "$_path_export" >> "$_shell_rc"
        printf "added PATH to %s\n" "$_shell_rc"
        printf "\n\033[1;33mIMPORTANT:\033[0m Run this to use shsh now:\n"
        printf "  \033[1mexec \$SHELL\033[0m\n"
        printf "Or open a new terminal.\n"
      else
        printf "PATH already configured in %s\n" "$_shell_rc"
        printf "\n\033[1;33mNOTE:\033[0m If shsh isn't found, run:\n"
        printf "  \033[1mexec \$SHELL\033[0m\n"
      fi
    elif [ "$_is_update" = 0 ]; then
      printf "\nshsh is ready to use!\n"
    fi
    ;;
  uninstall)
    _found=0
    for loc in /usr/local/bin/shsh "$HOME/.local/bin/shsh" "$HOME/bin/shsh"; do
      if [ -f "$loc" ]; then
        _found=1
        if [ -w "$(dirname "$loc")" ]; then
          rm "$loc" && printf "removed: %s\n" "$loc"
        else
          printf "removing %s (requires sudo)...\n" "$loc"
          sudo rm "$loc" && printf "removed: %s\n" "$loc"
        fi
      fi
    done
    if [ "$_found" = 0 ]; then
      printf "shsh not found in standard locations\n"
    fi
;;esac
