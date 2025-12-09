#
# Self-hosting shell transpiler with a beautifully simple high level syntax for POSIX shells.
# 
# Apache-2.0 License - Dawn Larsson
# https://github.com/dawnlarsson/shsh

VERSION="0.38.0"

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

  # Cleanup
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

  # Cleanup Loop (Stride 1)
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

  # Cleanup Loop (Stride 1)
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

  # Cleanup Loop (Stride 1)
  while eval "[ \$_mk_i -lt \$_mk_len ]"; do
    eval "_mk_key=\"\${__shsh_mapkeys_${1}_$_mk_i}\""
    eval "_mk_exists=\"\${__shsh_map_${1}_${_mk_key}+x}\""
    if [ -n "$_mk_exists" ]; then
      # Inline append
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

  # Cleanup
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
    _o0="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"

    _b1=$(( (_v1 >> 24) & 0xff )); _b2=$(( (_v1 >> 16) & 0xff ))
    _b3=$(( (_v1 >> 8) & 0xff )); _b4=$(( _v1 & 0xff ))
    _o1="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"

    _b1=$(( (_v2 >> 24) & 0xff )); _b2=$(( (_v2 >> 16) & 0xff ))
    _b3=$(( (_v2 >> 8) & 0xff )); _b4=$(( _v2 & 0xff ))
    _o2="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"

    _b1=$(( (_v3 >> 24) & 0xff )); _b2=$(( (_v3 >> 16) & 0xff ))
    _b3=$(( (_v3 >> 8) & 0xff )); _b4=$(( _v3 & 0xff ))
    _o3="\\$(( (_b1>>6)&7 ))$(( (_b1>>3)&7 ))$(( _b1&7 ))\\$(( (_b2>>6)&7 ))$(( (_b2>>3)&7 ))$(( _b2&7 ))\\$(( (_b3>>6)&7 ))$(( (_b3>>3)&7 ))$(( _b3&7 ))\\$(( (_b4>>6)&7 ))$(( (_b4>>3)&7 ))$(( _b4&7 ))"

    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) _b32_buf="$_b32_buf$_o0$_o1$_o2$_o3" ;;
      *)
         _b32_buf="$_b32_buf$_o0$_o1$_o2$_o3" 
         ;;
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
    _b128_hi="0x$(printf "%.16s" "$_b128_s")"
    _b128_lo="0x${_b128_s#????????????????}"
    case "$ENDIAN" in
      big|Big|BIG|BE|be|1) bit_64 "$_b128_hi"; bit_64 "$_b128_lo" ;;
      *)                   bit_64 "$_b128_lo"; bit_64 "$_b128_hi" ;;
    esac
  done
}

file_hash() {
  path="$1"

  if ! file_exists "$path"; then
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

transform_statement() {
  _ts_stmt="$1"
  str_ltrim "$_ts_stmt"; _ts_stmt="$R"
  case $_ts_stmt in
  *"++")
    str_before "$_ts_stmt" "++"; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        R="${_ts_var}=\$((${_ts_var} + 1))"
      ;;
    esac
    ;;
  *"--")
    str_before "$_ts_stmt" "--"; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        R="${_ts_var}=\$((${_ts_var} - 1))"
      ;;
    esac
    ;;
  *" += "*)
    str_before "$_ts_stmt" " += "; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        str_after "$_ts_stmt" " += "; _ts_val="$R"
        R="${_ts_var}=\$((${_ts_var} + ${_ts_val}))"
      ;;
    esac
    ;;
  *" -= "*)
    str_before "$_ts_stmt" " -= "; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        str_after "$_ts_stmt" " -= "; _ts_val="$R"
        R="${_ts_var}=\$((${_ts_var} - ${_ts_val}))"
      ;;
    esac
    ;;
  *" *= "*)
    str_before "$_ts_stmt" " *= "; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        str_after "$_ts_stmt" " *= "; _ts_val="$R"
        R="${_ts_var}=\$((${_ts_var} * ${_ts_val}))"
      ;;
    esac
    ;;
  *" /= "*)
    str_before "$_ts_stmt" " /= "; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        str_after "$_ts_stmt" " /= "; _ts_val="$R"
        R="${_ts_var}=\$((${_ts_var} / ${_ts_val}))"
      ;;
    esac
    ;;
  *" %= "*)
    str_before "$_ts_stmt" " %= "; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        str_after "$_ts_stmt" " %= "; _ts_val="$R"
        R="${_ts_var}=\$((${_ts_var} % ${_ts_val}))"
      ;;
    esac
    ;;
  *" = "*)
    str_before "$_ts_stmt" " = "; _ts_var="$R"
    case $_ts_var in
      *[!a-zA-Z0-9_]*|"")
        R="$_ts_stmt"
        ;;
      *)
        str_after "$_ts_stmt" " = "; _ts_call="$R"
        case $_ts_call in
        '"'*|"'"*|'$'*|""|*'='*)
          R="$_ts_stmt"
          ;;
        *)
          R="${_ts_call}; ${_ts_var}=\"\$R\""
          ;;
        esac
      ;;
    esac
    ;;
  *)
    R="$_ts_stmt"
    ;;
  esac
}

transform_semicolon_parts() {
  _tsp_line="$1"
  _tsp_out=""
  _tsp_sep=""
  
  while str_contains "$_tsp_line" "; "; do
    str_before "$_tsp_line" "; "; _tsp_part="$R"
    str_after "$_tsp_line" "; "; _tsp_line="$R"
    transform_statement "$_tsp_part"
    _tsp_out="$_tsp_out$_tsp_sep$R"
    _tsp_sep="; "
  done
  
  transform_statement "$_tsp_line"
  _tsp_out="$_tsp_out$_tsp_sep$R"
  R="$_tsp_out"
}

emit_with_try_check() {
  str_indent "$1"; _ewtc_indent="$R"
  str_ltrim "$1"; _ewtc_stmt="$R"
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

parse_comparison() {
  _pc_cond="$1"
  _ec_op="" _ec_shell_op="" _ec_left="" _ec_right=""
  
  case $_pc_cond in
  *" == "*)
    str_before "$_pc_cond" " == "; _ec_left="$R"
    str_after "$_pc_cond" " == "; _ec_right="$R"
    _ec_op="==" _ec_shell_op="="
    ;;
  *" != "*)
    str_before "$_pc_cond" " != "; _ec_left="$R"
    str_after "$_pc_cond" " != "; _ec_right="$R"
    _ec_op="!=" _ec_shell_op="!="
    ;;
  *" <= "*)
    str_before "$_pc_cond" " <= "; _ec_left="$R"
    str_after "$_pc_cond" " <= "; _ec_right="$R"
    _ec_op="<=" _ec_shell_op="-le"
    ;;
  *" >= "*)
    str_before "$_pc_cond" " >= "; _ec_left="$R"
    str_after "$_pc_cond" " >= "; _ec_right="$R"
    _ec_op=">=" _ec_shell_op="-ge"
    ;;
  *" < "*)
    str_before "$_pc_cond" " < "; _ec_left="$R"
    str_after "$_pc_cond" " < "; _ec_right="$R"
    _ec_op="<" _ec_shell_op="-lt"
    ;;
  *" > "*)
    str_before "$_pc_cond" " > "; _ec_left="$R"
    str_after "$_pc_cond" " > "; _ec_right="$R"
    _ec_op=">" _ec_shell_op="-gt"
    ;;
  *)
    return 1
    ;;
  esac
}

strip_outer_quotes() {
  _soq_val="$1"
  case $_soq_val in
  '"'*'"')
    _soq_val="${_soq_val#\"}"
    R="${_soq_val%\"}"
    ;;
  "'"*"'")
    _soq_val="${_soq_val#\'}"
    R="${_soq_val%\'}"
    ;;
  *)
    R="$_soq_val"
    ;;
  esac
}

format_test_operand() {
  _fto_val="$1"
  case $_fto_val in
  '"'*'"')
    R="$_fto_val"
    ;;
  "'"*"'")
    R="$_fto_val"
    ;;
  '$'*)
    R="\"$_fto_val\""
    ;;
  *)
    R="\"$_fto_val\""
    ;;
  esac
}

is_simple_var() {
  _isv_cond="$1"
  case $_isv_cond in
  '${'*'}')
    _isv_inner="${_isv_cond#\$\{}"
    _isv_inner="${_isv_inner%\}}"
    case $_isv_inner in
      ""|*[!a-zA-Z0-9_]*)
        return 1
        ;;
      *)
        return 0
      ;;
    esac
    ;;
  '$'[0-9])
    return 0
    ;;
  '$'[a-zA-Z_]*)
    _isv_inner="${_isv_cond#\$}"
    case $_isv_inner in
      *[!a-zA-Z0-9_]*)
        return 1
        ;;
      *)
        return 0
      ;;
    esac
    ;;
  *)
    return 1
    ;;
  esac
}

emit_condition() {
  keyword="$1" condition="$2" indent="$3" suffix="$4"
  
  if is_comparison "$condition"; then
    parse_comparison "$condition"
    format_test_operand "$_ec_left"; _emit_left="$R"
    format_test_operand "$_ec_right"; _emit_right="$R"
    printf '%s\n' "${indent}${keyword} [ ${_emit_left} ${_ec_shell_op} ${_emit_right} ]${suffix}"
  elif is_simple_var "$condition"; then
    printf '%s\n' "${indent}${keyword} [ -n \"${condition}\" ]${suffix}"
  elif str_starts "$condition" "! "; then
    str_after "$condition" "! "; _ec_negated="$R"
    if is_simple_var "$_ec_negated"; then
      printf '%s\n' "${indent}${keyword} [ -z \"${_ec_negated}\" ]${suffix}"
    else
      printf '%s\n' "${indent}${keyword} ${condition}${suffix}"
    fi
  else
    printf '%s\n' "${indent}${keyword} ${condition}${suffix}"
  fi
}

nonempty() {
  if [ "$1" = "" ]; then
    return 1
  else
    return 0
  fi
}

emit_inline_statement() {
  inline_indent="$1"
  inline_statement="$2"
  if [ "$inline_statement" = "" ]; then
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
  elif str_starts "$inline_statement" "while "; then
    str_after "$inline_statement" "while "; inline_rest="$R"
    if str_contains "$inline_rest" "$COLON_SPACE"; then
      str_before "$inline_rest" "$COLON_SPACE"; inline_condition="$R"
      str_after "$inline_rest" "$COLON_SPACE"; inline_body="$R"
      str_ltrim "$inline_body"; inline_body="$R"
      emit_condition "while" "$inline_condition" "$inline_indent" "$SEMICOLON_DO"
      emit_with_try_check "${inline_indent}  ${inline_body}"
      printf "${inline_indent}done\n"
      if in_try_block; then
        current_try_depth
        printf "${inline_indent}[ \"\$_shsh_brk_$R\" -eq 1 ] && break\n"
      fi
      return
    fi
  fi

  emit_with_try_check "${inline_indent}${inline_statement}"
}

transform_line() {
  line="$1"
  str_ltrim "$line"; stripped="$R"
  str_indent "$line"; indent="$R"
  
  if [ "$single_line_if_active" = "1" ]; then
    continues_single_line=0
    if [ "$indent" = "$single_line_if_indent" ]; then
      if str_starts "$stripped" "elif "; then
        continues_single_line=1
      fi
      if str_starts "$stripped" "else"; then
        continues_single_line=1
      fi
    fi
    
    if [ "$continues_single_line" = "1" ]; then
      converts_to_multiline=0
      if str_starts "$stripped" "elif "; then
        if ! str_contains "$stripped" "$COLON_SPACE"; then
          converts_to_multiline=1
        fi
      fi
      if [ "$stripped" = "else" ]; then
        converts_to_multiline=1
      fi
      
      if [ "$converts_to_multiline" = "1" ]; then
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
    if [ "$single_line_if_active" = "1" ]; then
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
    if [ "$R" = "t" ]; then
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
    if [ "$R" = "s" ]; then
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
          if [ "$maybe_statement" != "" ]; then
            is_single_line=1
          fi
        else
          if [ "$maybe_statement" != "" ]; then
            is_single_line=1
          fi
        fi
        
        if [ "$is_single_line" = "1" ]; then
          printf '%s\n' "${indent}${maybe_pattern})"
          emit_inline_statement "${indent}  " "$maybe_statement"
        else
          if str_ends "$rest" ":"; then
            str_before_last "$rest" ":"
            rest="$R"
          fi
          printf '%s\n' "${indent}${rest})"
        fi
      else
        if str_ends "$rest" ":"; then
          str_before_last "$rest" ":"
          rest="$R"
        fi
        printf '%s\n' "${indent}${rest})"
      fi
    else
      printf '%s\n' "$line"
    fi
  
    ;;
  "default:"*)
    peek
    if [ "$R" = "s" ]; then
      if ! switch_is_first; then
        printf "${indent}  ;;\n"
      fi
      switch_set_not_first
      str_after "$stripped" "default:"; statement="$R"
      str_ltrim "$statement"; statement="$R"
      printf "${indent}*)\n"
      if [ "$statement" != "" ]; then
        emit_inline_statement "${indent}  " "$statement"
      fi
    else
      printf '%s\n' "$line"
    fi
  
    ;;
  "default")
    peek
    if [ "$R" = "s" ]; then
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
    if [ "$R" = "s" ]; then
      printf "${indent}  ;;\n"
      printf "${indent}esac\n"
      switch_pop_first
      pop
    elif [ "$R" = "i" ]; then
      printf "${indent}fi\n"
      pop
    elif [ "$R" = "c" ]; then
      printf "${indent}fi\n"
      try_depth_dec
      pop
    elif [ "$R" = "t" ]; then
      printf "${indent}_shsh_brk_$try_depth=1; done\n"
      try_depth_dec
      pop
    fi
  
    ;;
  *"++")
    if str_contains "$stripped" "; "; then
      transform_semicolon_parts "$stripped"
      printf '%s\n' "${indent}$R"
    else
      str_before "$stripped" "++"; variable="$R"
      case $variable in
        *[!a-zA-Z0-9_]*|"")
          printf '%s\n' "$line"
          ;;
        *)
          printf '%s\n' "${indent}${variable}=\$((${variable} + 1))"
        ;;
      esac
    fi
  
    ;;
  *"--")
    if str_contains "$stripped" "; "; then
      transform_semicolon_parts "$stripped"
      printf '%s\n' "${indent}$R"
    else
      str_before "$stripped" "--"; variable="$R"
      case $variable in
        *[!a-zA-Z0-9_]*|"")
          printf '%s\n' "$line"
          ;;
        *)
          printf '%s\n' "${indent}${variable}=\$((${variable} - 1))"
        ;;
      esac
    fi
  
    ;;
  *" += "*)
    if str_contains "$stripped" "; "; then
      transform_semicolon_parts "$stripped"
      printf '%s\n' "${indent}$R"
    else
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
    fi
  
    ;;
  *" -= "*)
    if str_contains "$stripped" "; "; then
      transform_semicolon_parts "$stripped"
      printf '%s\n' "${indent}$R"
    else
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
    fi
  
    ;;
  *" *= "*)
    if str_contains "$stripped" "; "; then
      transform_semicolon_parts "$stripped"
      printf '%s\n' "${indent}$R"
    else
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
    fi
  
    ;;
  *" /= "*)
    if str_contains "$stripped" "; "; then
      transform_semicolon_parts "$stripped"
      printf '%s\n' "${indent}$R"
    else
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
    fi
  
    ;;
  *" %= "*)
    if str_contains "$stripped" "; "; then
      transform_semicolon_parts "$stripped"
      printf '%s\n' "${indent}$R"
    else
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
    fi
  
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
  
  while IFS= read -r current_line || nonempty "$current_line"; do
    transform_line "$current_line"
  done
  
  if [ "$single_line_if_active" = "1" ]; then
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
  _ers_all_fns="" _ers_in_rt=0 _ers_cur_fn="" _ers_cur_body=""
  while IFS= read -r _ers_line || nonempty "$_ers_line"; do
    if str_starts "$_ers_line" "# __RUNTIME_START__"; then
      _ers_in_rt=1; continue
    fi
    if str_starts "$_ers_line" "# __RUNTIME_END__"; then
      break
    fi
    if [ "$_ers_in_rt" = "0" ]; then
      continue
    fi
    case "$_ers_line" in
    *"() {"*"}")
      str_before "$_ers_line" "()"; _ers_cur_fn="$R"
      str_ltrim "$_ers_cur_fn"; _ers_cur_fn="$R"
      _ers_all_fns="$_ers_all_fns $_ers_cur_fn"
      str_after "$_ers_line" "() { "; _ers_cur_body="$R"
      str_before "$_ers_cur_body" " }"; _ers_cur_body="$R"
      eval "_rt_body_$_ers_cur_fn=\"\$_ers_cur_body\""
      _ers_cur_fn=""
      ;;
    *"() {"*)
      str_before "$_ers_line" "()"; _ers_cur_fn="$R"
      str_ltrim "$_ers_cur_fn"; _ers_cur_fn="$R"
      _ers_all_fns="$_ers_all_fns $_ers_cur_fn"
      _ers_cur_body=""
      ;;
    "}")
        eval "_rt_body_$_ers_cur_fn=\"\$_ers_cur_body\""
      _ers_cur_fn=""
      ;;
    *)
      if [ "$_ers_cur_fn" != "" ]; then
        _ers_cur_body="$_ers_cur_body $_ers_line"
      fi
      ;;
    esac
  done < "$0"
  
  for _ers_fn in $_ers_all_fns; do
    eval "_ers_body=\"\$_rt_body_$_ers_fn\""
    _ers_deps=""
    for _ers_other in $_ers_all_fns; do
      if [ "$_ers_fn" != "$_ers_other" ]; then
        case "$_ers_body" in
        *"$_ers_other"*)
          _ers_deps="$_ers_deps $_ers_other"
          ;;
        esac
      fi
    done
    eval "_rt_deps_$_ers_fn=\"\$_ers_deps\""
  done
  
  _rt_needed=" "
  for _ers_fn in $_ers_all_fns; do
    case "$_ers_source" in
    *"$_ers_fn"*)
      _rt_need_fn "$_ers_fn"
      ;;
    esac
  done
  
  _ers_combined="$_ers_source"
  for _ers_fn in $_ers_all_fns; do
    case "$_rt_needed" in
    *" $_ers_fn "*)
      eval "_ers_combined=\"\$_ers_combined \$_rt_body_$_ers_fn\""
      ;;
    esac
  done
  
  _ers_emit=0 _ers_skip=0 _ers_in_func=0
  while IFS= read -r _ers_line || nonempty "$_ers_line"; do
    case $_ers_emit in
    0)
      if str_starts "$_ers_line" "# __RUNTIME_START__"; then
        _ers_emit=1
      fi
      ;;
    1)
      if str_starts "$_ers_line" "# __RUNTIME_END__"; then
        _ers_emit=2
      else
        case "$_ers_line" in
        *"() {"*"}")
          str_before "$_ers_line" "()"; _ers_fn="$R"
          str_ltrim "$_ers_fn"; _ers_fn="$R"
          case "$_rt_needed" in
          *" $_ers_fn "*)
            printf '%s\n' "$_ers_line"
            ;;
          esac
          ;;
        *"() {"*)
          str_before "$_ers_line" "()"; _ers_fn="$R"
          str_ltrim "$_ers_fn"; _ers_fn="$R"
          case "$_rt_needed" in
          *" $_ers_fn "*)
            _ers_skip=0
            _ers_in_func=1
            printf '%s\n' "$_ers_line"
            ;;
          *)
            _ers_skip=1
            _ers_in_func=0
            ;;
          esac
          ;;
        "}")
          if [ "$_ers_skip" = "0" ]; then
            printf '%s\n' "$_ers_line"
          fi
          _ers_skip=0
          _ers_in_func=0
          ;;
        "")
          if [ "$_ers_skip" = "0 && $_ers_in_func == 1" ]; then
            printf "\n"
          fi
          ;;
        *"="*)
          if [ "$_ers_in_func" = "0" ]; then
            str_before "$_ers_line" "="; _ers_varname="$R"
            case "$_ers_combined" in
            *'$'"$_ers_varname"*|*'$'"{$_ers_varname"*)
              printf '%s\n' "$_ers_line"
              ;;
            esac
          elif [ "$_ers_skip" = "0" ]; then
            printf '%s\n' "$_ers_line"
          fi
          ;;
        *)
          if [ "$_ers_skip" = "0" ]; then
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
  while IFS= read -r _er_line || nonempty "$_er_line"; do
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
}

case $1 in
  raw)
    if [ "$2" = "" ]; then
      transform
    elif [ "$2" = "-" ]; then
      transform
    else
      transform < "$2"
    fi
    ;;
  build)
    if [ "$2" = "" ]; then
      _es_code="$(transform)"
      emit_runtime_stripped "$_es_code"
      printf "$_es_code\n"
    else
      _es_code="$(transform < "$2")"
      emit_runtime_stripped "$_es_code"
      printf "$_es_code\n"
    fi
    ;;
  build_full)
    emit_runtime
    if [ "$2" = "" ]; then
      transform
    else
      transform < "$2"
    fi
    ;;
  version)
    printf "shsh $VERSION\n"
    ;;
  -)
    eval "$(transform)"
    ;;
  -*)
    info
    ;;
  "")
    info
    ;;
  install)
    _install_dest=""
    _install_needs_path=0
    
    for _try_dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
      case ":$PATH:" in
        *":$_try_dir:"*)
          if path_writable "$_try_dir"; then
            _install_dest="$_try_dir/shsh"
            break
          elif [ "$_try_dir" = "/usr/local/bin" ]; then
            _install_dest="$_try_dir/shsh"
            break
          fi
        ;;
      esac
    done

    if [ "$_install_dest" = "" ]; then
      mkdir -p "$HOME/.local/bin" || { printf "error: cannot create %s\n" "$HOME/.local/bin" >&2; exit 1; }
      _install_dest="$HOME/.local/bin/shsh"
      _install_needs_path=1
    fi

    _install_dir=$(dirname "$_install_dest")
    
    if ! dir_exists "$_install_dir"; then
      mkdir -p "$_install_dir" 2>/dev/null || sudo mkdir -p "$_install_dir"
    fi
    
    if cp "$0" "$_install_dest" 2>/dev/null && chmod +x "$_install_dest" 2>/dev/null; then
      printf "installed: %s\n" "$_install_dest"
    else
      printf "installing to %s (requires sudo)...\n" "$_install_dest"
      sudo cp "$0" "$_install_dest" && sudo chmod +x "$_install_dest"
      sudo chown "$USER" "$_install_dest"
      printf "installed: %s\n" "$_install_dest"
    fi
    
    if [ "$_install_needs_path" = "1" ]; then
      _shell_rc=""
      _path_export='export PATH="$HOME/.local/bin:$PATH"'
      
      case $SHELL in
        */bash)
          if file_exists "$HOME/.bash_profile"; then
            _shell_rc="$HOME/.bash_profile"
          elif file_exists "$HOME/.bash_login"; then
            _shell_rc="$HOME/.bash_login"
          else
            _shell_rc="$HOME/.bashrc"
          fi
          ;;
        */zsh)
          _shell_rc="$HOME/.zshrc"
          ;;
        */fish)
          _shell_rc="$HOME/.config/fish/config.fish"
          _path_export='set -gx PATH $HOME/.local/bin $PATH'
          ;;
        *)
          _shell_rc="$HOME/.profile"
        ;;
      esac
      
      _already_configured=0
      if file_exists "$_shell_rc"; then
        if grep -qE '(\.local/bin|HOME/.local/bin)' "$_shell_rc" 2>/dev/null; then
          _already_configured=1
        fi
      fi
      
      if [ "$_already_configured" = "0" ]; then
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
    else
      printf "\nshsh is ready to use!\n"
    fi
    ;;
  uninstall)
    _found=0
    for loc in /usr/local/bin/shsh "$HOME/.local/bin/shsh" "$HOME/bin/shsh"; do
      if file_exists "$loc"; then
        _found=1
        if path_writable "$(dirname "$loc")"; then
          rm "$loc" && printf "removed: %s\n" "$loc"
        else
          printf "removing %s (requires sudo)...\n" "$loc"
          sudo rm "$loc" && printf "removed: %s\n" "$loc"
        fi
      fi
    done
    if [ "$_found" = "0" ]; then
      printf "shsh not found in standard locations\n"
    fi
    ;;
  update)
    _url="https://raw.githubusercontent.com/dawnlarsson/shsh/main/shsh.sh"
    _old_ver="$VERSION"
    _dest=""

    for _try_loc in "/usr/local/bin/shsh" "$HOME/.local/bin/shsh" "$HOME/bin/shsh"; do
      if file_executable "$_try_loc"; then
        _dest="$_try_loc"
        break
      fi
    done
    
    if [ "$_dest" = "" ]; then
      for _try_dir in "$HOME/.local/bin" "$HOME/bin" "/usr/local/bin"; do
        case ":$PATH:" in
          *":$_try_dir:"*)
            if [ "path_writable "$_try_dir" || "$_try_dir"" = "/usr/local/bin" ]; then
              mkdir -p "$_try_dir" 2>/dev/null || true
              _dest="$_try_dir/shsh"
              break
            fi
          ;;
        esac
      done
      
      if [ "$_dest" = "" ]; then
        mkdir -p "$HOME/.local/bin"
        _dest="$HOME/.local/bin/shsh"
      fi
    fi

    _dest_dir=$(dirname "$_dest")

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
    
    if [ "$_download_ok" = "0" ]; then
      rm -f "$_tmp"
      printf "error: download failed\n" >&2
      exit 1
    fi
    
    if mv "$_tmp" "$_dest" 2>/dev/null && chmod +x "$_dest" 2>/dev/null; then
      printf "updated: %s\n" "$_dest"
    else
      printf "installing to %s (requires sudo)...\n" "$_dest"
      sudo mv "$_tmp" "$_dest" && sudo chmod +x "$_dest"
      sudo chown "$USER" "$_dest"
      printf "updated: %s\n" "$_dest"
    fi
    
    _new_ver=$("$_dest" -v 2>/dev/null | sed 's/shsh //')
    if [ "$_new_ver" = "$_old_ver" ]; then
      printf "version: %s (already up to date)\n" "$_old_ver"
    else
      printf "version: %s -> %s\n" "$_old_ver" "$_new_ver"
    fi
    ;;
  *)
    if file_exists "$1"; then
      run_file "$@"
    else
      eval "$(printf '%s\n' "$*" | transform)"
    fi
  ;;
esac
