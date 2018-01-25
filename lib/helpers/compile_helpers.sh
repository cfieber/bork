# helpers related to the "compile" operation

is_compiling () {
  [ $operation = "compile" ] && return 0 || return 1
}

# multiline, keeps list of compiled types
bag init compiled_types

# TODO: test
# interface for the compiled_type multiline
compiled_type_push () {
  bag push compiled_types "$1"
}
# TODO: test
# interface for the compiled_type multiline
compiled_type_exists () {
  exists=$(bag find compiled_types "^$1\$")
  [ -n "$exists" ]
  return $?
}

# if compiling, echoes a function that contains the given assertion
# include_assertion_for_compiling $assertion_type $file_path
# - $assertion_type: key for the assertion
# - $file_path: absolute/relative path to the file
#
# returns immediately with 0 if not compiling
include_assertion () {
  if ! is_compiling; then return 0; fi
  if compiled_type_exists $1; then return 0; fi
  compiled_type_push $1
  echo "# $2"
  echo "type_$1 () {"
  cat $2 | strip_blanks | awk '{print "  " $0}'
  echo "}"
}

compile_file () {
    cat $1 | while read line; do
        first_token=$(str_get_field "$line" 1)
        case $first_token in
            ok)
                type=$(str_get_field "$line" 2)
                fn=$(_lookup_type $type)
                if [ -z "$fn" ]; then
                    echo "type $type not found, can't proceed" 1>&2
                    exit 1
                fi
                include_assertion $type $fn
                compile_cmd=$(echo "$line" | sed -E "s|ok $type ||")
                . $fn compile $compile_cmd
                echo "$line"
                ;;
            register|include) eval "$line" ;;
            *) echo "$line" ;;
        esac
    done
}
