#*
#  This file sets up (when source'd) the bash completion for common
#  programs from cod-tools.
#
#  The completion is based on the command line options, listed by issuing
#  a program with '--help' option.
#
#**
function _cod_tools_completion
{
    case "${COMP_WORDS[COMP_CWORD]}" in
        -*)
            COMPREPLY=( $(compgen -W "$($1 --help \
                    | grep -P '^\s*-' \
                    | perl -lpe 's/^\s+//; s/\s*,\s*/\n/g' \
                    | awk '{print $1}' \
                    | sort )" -- ${COMP_WORDS[COMP_CWORD]}) )
            # Always add a space after each command
            for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
                COMPREPLY[$i]="${COMPREPLY[$i]} "
            done
            ;;
        *)
            COMPREPLY=()
    esac
}
complete -o nospace -o default -F _cod_tools_completion cif_cod_check
complete -o nospace -o default -F _cod_tools_completion cif_cod_deposit
complete -o nospace -o default -F _cod_tools_completion cif_fix_values
complete -o nospace -o default -F _cod_tools_completion cif_filter
complete -o nospace -o default -F _cod_tools_completion cif_mark_disorder
complete -o nospace -o default -F _cod_tools_completion cif_molecule
complete -o nospace -o default -F _cod_tools_completion cif_tcod_tree
complete -o nospace -o default -F _cod_tools_completion cif_values
