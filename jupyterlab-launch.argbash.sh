#!/bin/bash

# Created by argbash-init v2.8.1
# ARG_OPTIONAL_SINGLE([port],[p],[Port of jupyter server],[8889])
# ARG_OPTIONAL_BOOLEAN([browser],[],[Open the notebook in a browser after startup.],[on])
# ARG_OPTIONAL_REPEATED([tunnel],[t],[<port on jupyter server>:<remote server address>:<port on remote server>\n  Tunnel to create, e.g., to connect to a remote database server.\n  Example: 3333:wikipathways-workspace:5432],[])
# ARG_POSITIONAL_DOUBLEDASH([])
# ARG_POSITIONAL_SINGLE([target],[When jupyter server is local, target defaults to pwd.\n  When jupyter server is remote, an ssh-style url is required, e.g.:\n   jupyterlab-launch nixos.gladstone.internal:code/jupyterlab-demo],[./])
# ARG_HELP([Connect to your jupyterlab server])
# ARGBASH_GO()
# needed because of Argbash --> m4_ignore([
### START OF CODE GENERATED BY Argbash v2.8.1 one line above ###
# Argbash is a bash code generator used to get arguments parsing right.
# Argbash is FREE SOFTWARE, see https://argbash.io for more info


die()
{
	local _ret=$2
	test -n "$_ret" || _ret=1
	test "$_PRINT_HELP" = yes && print_help >&2
	echo "$1" >&2
	exit ${_ret}
}


begins_with_short_option()
{
	local first_option all_short_options='pth'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

# THE DEFAULTS INITIALIZATION - POSITIONALS
_positionals=()
_arg_target="./"
# THE DEFAULTS INITIALIZATION - OPTIONALS
_arg_port="8889"
_arg_browser="on"
_arg_tunnel=()


print_help()
{
	printf '%s\n' "Connect to your jupyterlab server"
	printf 'Usage: %s [-p|--port <arg>] [--(no-)browser] [-t|--tunnel <arg>] [-h|--help] [--] [<target>]\n' "$0"
	printf '\t%s\n' "<target>: When jupyter server is local, target defaults to pwd.
		  When jupyter server is remote, an ssh-style url is required, e.g.:
		   jupyterlab-launch nixos.gladstone.internal:code/jupyterlab-demo (default: './')"
	printf '\t%s\n' "-p, --port: Port of jupyter server (default: '8889')"
	printf '\t%s\n' "--browser, --no-browser: Open the notebook in a browser after startup. (on by default)"
	printf '\t%s\n' "-t, --tunnel: <port on jupyter server>:<remote server address>:<port on remote server>
		  Tunnel to create, e.g., to connect to a remote database server.
		  Example: 3333:wikipathways-workspace:5432 (empty by default)"
	printf '\t%s\n' "-h, --help: Prints help"
}


parse_commandline()
{
	_positionals_count=0
	while test $# -gt 0
	do
		_key="$1"
		if test "$_key" = '--'
		then
			shift
			test $# -gt 0 || break
			_positionals+=("$@")
			_positionals_count=$((_positionals_count + $#))
			shift $(($# - 1))
			_last_positional="$1"
			break
		fi
		case "$_key" in
			-p|--port)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_port="$2"
				shift
				;;
			--port=*)
				_arg_port="${_key##--port=}"
				;;
			-p*)
				_arg_port="${_key##-p}"
				;;
			--no-browser|--browser)
				_arg_browser="on"
				test "${1:0:5}" = "--no-" && _arg_browser="off"
				;;
			-t|--tunnel)
				test $# -lt 2 && die "Missing value for the optional argument '$_key'." 1
				_arg_tunnel+=("$2")
				shift
				;;
			--tunnel=*)
				_arg_tunnel+=("${_key##--tunnel=}")
				;;
			-t*)
				_arg_tunnel+=("${_key##-t}")
				;;
			-h|--help)
				print_help
				exit 0
				;;
			-h*)
				print_help
				exit 0
				;;
			*)
				_last_positional="$1"
				_positionals+=("$_last_positional")
				_positionals_count=$((_positionals_count + 1))
				;;
		esac
		shift
	done
}


handle_passed_args_count()
{
	test "${_positionals_count}" -le 1 || _PRINT_HELP=yes die "FATAL ERROR: There were spurious positional arguments --- we expect between 0 and 1, but got ${_positionals_count} (the last one was: '${_last_positional}')." 1
}


assign_positional_args()
{
	local _positional_name _shift_for=$1
	_positional_names="_arg_target "

	shift "$_shift_for"
	for _positional_name in ${_positional_names}
	do
		test $# -gt 0 || break
		eval "$_positional_name=\${1}" || die "Error during argument parsing, possibly an Argbash bug." 1
		shift
	done
}

parse_commandline "$@"
handle_passed_args_count
assign_positional_args 1 "${_positionals[@]}"

# OTHER STUFF GENERATED BY Argbash

### END OF CODE GENERATED BY Argbash (sortof) ### ])
# [ <-- needed because of Argbash
# ] <-- needed because of Argbash
