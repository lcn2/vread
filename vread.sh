#!/bin/bash
#
# vread.sh - read from stdin and validate the input
#
# usage:
#	NOTE: See USAGE variable below for details of the command line
#
# stdout:
#	validated input or empty line
#
# exit code:
#	0	all is OK and input is printed to stdout as a non-empty line + newline
#	!= 0	bad input, error, or interrupt, or invalid format, or mismatch, etc.
#		newline is printed to stdout
#
#	NOTE: See USAGE variable below for details
#	NOTE: See USAGE variable below for details of the exit codes
#
#####
#
# By: Landon Curt Noll, 2004-2015, 2019, 2020.
#     http://www.isthe.com/chongo
#
# This work is licensed under the Creative Commons
# Attribution-ShareAlike 4.0 International License.
# To view a copy of this license, visit
# http://creativecommons.org/licenses/by-sa/4.0/.
#
# This means you are free to:
#
# Share — copy and redistribute the material in any medium or format
#
# Adapt — remix, transform, and build upon the material for any purpose,
# even commercially.
#
# The licensor cannot revoke these freedoms as long as you follow the license terms.
#
# Under the following terms:
#
# Attribution — You must give appropriate credit, provide a link to
# the license, and indicate if changes were made. You may do so in any
# reasonable manner, but not in any way that suggests the licensor endorses
# you or your use.
#
# ShareAlike — If you remix, transform, or build upon the material, you
# must distribute your contributions under the same license as the original.
#
# No additional restrictions — You may not apply legal terms or
# technological measures that legally restrict others from doing anything
# the license permits.
#
# Share and enjoy! :-)

# setup
#
export VERSION="4.6-20200528"
export V_FLAG=
export B_FLAG=
export C_FLAG=
export TYPE=
export PROMPT=
export ERRMSG=
export O_FLAG=
export E_FLAG=
export S_FLAG=
export REPEAT_PROMPT=
export MAXLEN="4096"
export TIMEOUT=
export EXIT_BADFORMAT="1"
export EXIT_INTERRUPT="2"
export EXIT_USAGE="3"
export EXIT_TOOLONG="4"
export EXIT_TIMEOUT="5"
export EXIT_MISMATCH="6"
export EXIT_EMPTY="7"
export EXIT_READERR="8"
export ANSWER SECOND_ANSWER INPUT CANONICAL_INPUT
export PROG="$0"
export USAGE="usage:

$PROG [-h] [-v] [-b] [-c] [-o] [-e] [-r repeat_prompt] [-s] [-m maxlen] [-t timeout] type prompt [errmsg]

    -h			Output usage message and exit $EXIT_USAGE
    -v			Verbose mode for debugging

    -b			Do not print a blank after the promt (def: print a space after prompt and repeat_prompt)
    -c			Canonicalize the result
    -o			Prompt once, exit $EXIT_BADFORMAT if invalid input
    -e			Enable READLINE editing mode

    -r repeat_prompt	Prompt to issue to verify entry (def: do ask again)
    -s			Silent mode (useful for password entry) (def: echo characters)

    -m maxlen		Maximum chars for input (def: $MAXLEN)
    -t timeout		Failure if not a complete line in timeout secs (def: forever)

    type		Type of input to validate, must be one of:

	natint			Integer > 0
	posint			Integer >= 0
	int			Any integer

	natreal			Any real number > 0
	posreal			Any real number >= 0
	real			Any real number

	string			Any non-empty single line string, trailing newline removed
	yorn			One of: y or n or Y or N or Yes or No or YES or NO
				    if -c, canonical rewrite: y n
	cde			One of: c or C or d or D or e or E
				    if -c, canonical rewrite: c d e
	ds			One of: d or D or s or S
				    if -c, canonical rewrite: d s
	ab			One of: a or A or b or B
				    if -c, canonical rewrite: a b
	fh			One of: f or F or h or H
				    if -c, canonical rewrite: f h
	gd			One of: g or G or d or D
				    if -c, canonical rewrite: g d
	v4v6			One of: v4 or V4 or v6 or V6
				    if -c, canonical rewrite: v4 v6
	123			One of: 1 or 2 or 3
				    if -c, canonical rewrite: 1 2 3
	012			One of: 0 or 1 or 2
				    if -c, canonical rewrite: 0 1 2

	cr			Just press return, and then return a single space
				    output is changed to: a single space

	ip4addr			IPv4 address
	ip6addr			IPv6 address
	ipaddr			IPv4 or IPv6 address

	v4cidr			0 to 32
	v6cidr			0 to 128

	v4netmask		IPv4 netmask 0.0.0.0 thru 255.255.255.255

	port			UDP or TCP port number (1-65535)

	hostname		Hostname valid under RFC-952 and RFC-1123
	hostoripv4		Hostname valid under RFC-952 and RFC-1123 or IPv4 address
	hostorip		Hostname valid under RFC-952 and RFC-1123 or IPv4 address or IPv6 address

	interface		Interface name: eth followed by a digit or single letter

	sane_filename		Filename (not a path) excluding characters that are likely to cause problems
	insane_filename		Filename (not a path) - NOT RECOMMENDED

	sane_path		Poth of sane_filenames excludung path components that are likely to cause problems
	insane_path		Poth of insane_filenames - NOT RECOMMENDED

	sane_username		Valid and sane username
	insane_username		Any non-empty username string - NOT RECOMMENDED

	sane_password		Valid and sane password
	insane_possword		Any non-empty password string - NOT RECOMMENDED

	sane_url		Valid and sane URL

	trans_mode_0		One of: ftp sftp scp   plus Caps and ALL CAPS
				    if -c, canonical rewrite: ftp sftp scp
	trans_mode_1		One of: sftp scp ftp http file   plus Caps and ALL CAPS
				    if -c, canonical rewrite: sftp scp ftp http file
	trans_mode_2		One of: http https   plus Caps and ALL CAPS
				    if -c, canonical rewrite: http https

    prompt		Input prompt to print, without a trailing newline, followed by a space

    errmsg		Optional error message to print if input is invalid

NOTE: Leading whitespace and trailing is removed from input.

exit codes:

    0	valid input, input printed to stdout

    $EXIT_BADFORMAT	invalid input and -o given
    $EXIT_INTERRUPT	interrupt

    $EXIT_USAGE	usage or command line error
    $EXIT_TOOLONG	input was too long
    $EXIT_TIMEOUT	timeout on input and -t timeout given
    $EXIT_MISMATCH	used -r repeat_prompt and 2nd input did not match
    $EXIT_EMPTY	empty input line and not cr type
    $EXIT_READERR	some other read error occurred

Examples:

    REMOTE_URL=\$($PROG -e -o sane_url 'Enter the URL of the remote server')
    status=\"\$?\"
    if [[ \$status -ne 0 || -z \$REMOTE_URL ]]; then
	# ... error processing or exit
    fi

    HOST_NAME=\$($PROG -e hostname 'Enter the hostname:' 'Invalid syntax for a hostname')
    status=\"\$?\"
    if [[ \$status -ne 0 || -z \$HOST_NAME ]]; then
	# ... error processing or exit
    fi

    PASSWORD=\$($PROG -s -r 'Confirm password:' sane_password 'Enter password:' 'Invalid password or input did not match')
    status=\"\$?\"
    if [[ \$status -ne 0 || -z \$PASSWORD ]]; then
	# ... error processing or exit
    fi

Version: $VERSION"

# trap interrupts
#
#trap "printf '\n\ninterrupted\n\n' 1>&2; echo; exit $EXIT_INTERRUPT" 1 2 3 15	# exit 2
trap "printf '\n\ninterrupted\n\n' 1>&2; echo; exit 2" 1 2 3 15 # exit 2

# parse args
#
while getopts :hvbcoesr:m:t: flag; do

    # validate flag
    #
    case "$flag" in
    h)
        echo "$USAGE" 1>&2
        echo               # print empty stdout to indicate error
        exit "$EXIT_USAGE" # exit 3
        ;;
    b)
        B_FLAG="true"
        ;;
    c)
        C_FLAG="true"
        ;;
    v)
        V_FLAG="true"
        ;;
    o)
        O_FLAG="true"
        ;;
    e)
        E_FLAG="true"
        ;;
    s)
        S_FLAG="true"
        ;;
    r)
        REPEAT_PROMPT="$OPTARG"
        ;;
    m)
        MAXLEN="$OPTARG"
        if [[ ! $MAXLEN =~ ^[0-9]{1,}$ || $MAXLEN -le 0 ]]; then
            echo "$PROG: -m chars must be an integer > 0: $MAXLEN" 1>&2
            echo               # print empty stdout to indicate error
            exit "$EXIT_USAGE" # exit 3
        fi
        ;;
    t)
        TIMEOUT="$OPTARG"
        if [[ ! $TIMEOUT =~ ^[0-9]{1,}$ || $TIMEOUT -lt 0 ]]; then
            echo "$PROG: -t timeout must be an integer >= 0: $TIMEOUT" 1>&2
            echo               # print empty stdout to indicate error
            exit "$EXIT_USAGE" # exit 3
        fi
        ;;
    \?)
        echo "$PROG: invalid option: -$OPTARG" 1>&2
        echo "$USAGE" 1>&2
        echo               # print empty stdout to indicate error
        exit "$EXIT_USAGE" # exit 3
        ;;
    :)
        echo "$PROG: option -$OPTARG requires an argument" 1>&2
        echo "$USAGE" 1>&2
        echo               # print empty stdout to indicate error
        exit "$EXIT_USAGE" # exit 3
        ;;
    *)
        echo "$PROG: unexpected return from getopts: $flag" 1>&2
        echo "$USAGE" 1>&2
        echo               # print empty stdout to indicate error
        exit "$EXIT_USAGE" # exit 3
        ;;
    esac
done
shift $((OPTIND - 1))
#
# parse the 2 or 3 option args
#
case "$#" in
2)
    TYPE="$1"
    PROMPT="$2"
    ERRMSG=""
    ;;
3)
    TYPE="$1"
    PROMPT="$2"
    ERRMSG="$3"
    ;;
*)
    echo "$PROG: must have 2 or 3 args" 1>&2
    echo "$USAGE" 1>&2
    echo               # print empty stdout to indicate error
    exit "$EXIT_USAGE" # exit 3
    ;;
esac

# pre-validate type
#
case "$TYPE" in

natint) ;;
posint) ;;
int) ;;
natreal) ;;
posreal) ;;
real) ;;
string) ;;
yorn) ;;
cde) ;;
ds) ;;
ab) ;;
fh) ;;
gd) ;;
v4v6) ;;
123) ;;
012) ;;
cr) ;;
ip4addr) ;;
ip6addr) ;;
ipaddr) ;;
v4cidr) ;;
v6cidr) ;;
v4netmask) ;;
port) ;;
hostname) ;;
hostoripv4) ;;
hostorip) ;;
interface) ;;
sane_filename) ;;
insane_filename) ;;
sane_path) ;;
insane_path) ;;
sane_username) ;;
insane_username) ;;
sane_password) ;;
insane_password) ;;
sane_url) ;;
trans_mode_0) ;;
trans_mode_1) ;;
trans_mode_2) ;;

*)
    if [[ -n $V_FLAG ]]; then
        echo "$PROG: unknown type: $TYPE" 1>&2
    fi
    echo               # print empty stdout to indicate error
    exit "$EXIT_USAGE" # exit 3
    ;;
esac

# IPv4 REGEX
#
# See:
#	https://stackoverflow.com/a/5284410
#	https://gist.github.com/syzdek/6086792
#
RE_IPV4="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"
export IPV4ADDR_REGEX='^'"$RE_IPV4"'$'

# IPv6 REGEX
#
# See:
#	https://stackoverflow.com/a/17871737
#	https://gist.github.com/syzdek/6086792
#
RE_IPV6="(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|"
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,7}:|"
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|"
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|"
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|"
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|"
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|"
RE_IPV6="${RE_IPV6}[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|"
RE_IPV6="${RE_IPV6}:((:[0-9a-fA-F]{1,4}){1,7}|"
RE_IPV6="${RE_IPV6}:)|"
RE_IPV6="${RE_IPV6}fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|"
RE_IPV6="${RE_IPV6}::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|"
RE_IPV6="${RE_IPV6}(2[0-4]|"
RE_IPV6="${RE_IPV6}1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|"
RE_IPV6="${RE_IPV6}(2[0-4]|"
RE_IPV6="${RE_IPV6}1{0,1}[0-9]){0,1}[0-9])|"
RE_IPV6="${RE_IPV6}([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|"
RE_IPV6="${RE_IPV6}(2[0-4]|"
RE_IPV6="${RE_IPV6}1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|"
RE_IPV6="${RE_IPV6}(2[0-4]|"
RE_IPV6="${RE_IPV6}1{0,1}[0-9]){0,1}[0-9]))"
export IPV6ADDR_REGEX='^'"$RE_IPV6"'$'

# port - UDP or TCP port number (1-65535)
#
RE_PORT="[0-9]{1,4}"
RE_PORT="${RE_PORT}|[0-5][0-9][0-9][0-9][0-9]"
RE_PORT="${RE_PORT}|6[0-4][0-9][0-9][0-9]"
RE_PORT="${RE_PORT}|65[0-4][0-9][0-9]"
RE_PORT="${RE_PORT}|655[0-2][0-9]"
RE_PORT="${RE_PORT}|6553[0-5]"
export PORT_REGEX='^('"$RE_PORT"')$'

# IPv4 CIDR 0 thru 32 REGEX
#
RE_IPV4CIDR="[0-9]"
RE_IPV4CIDR="${RE_IPV4CIDR}|[1-2][0-9]"
RE_IPV4CIDR="${RE_IPV4CIDR}|3[0-2]"
export IPV4CIDR_REGEX='^('"$RE_IPV4CIDR"')$'

# IPv6 CIDR 0 thru 128 REGEX
#
RE_IPV6CIDR="[0-9]"
RE_IPV6CIDR="${RE_IPV6CIDR}|[1-9][0-9]"
RE_IPV6CIDR="${RE_IPV6CIDR}|1[0-1][0-9]"
RE_IPV6CIDR="${RE_IPV6CIDR}|12[0-8]"
export IPV6CIDR_REGEX='^('"$RE_IPV6CIDR"')$'

# IPv4 netmask REGEX
#
RE_V4NETMASK="(254|252|248|240|224|192|128|0)\.0\.0\.0|"
RE_V4NETMASK="${RE_V4NETMASK}255\.(254|252|248|240|224|192|128|0)\.0\.0|"
RE_V4NETMASK="${RE_V4NETMASK}255\.255\.(254|252|248|240|224|192|128|0)\.0|"
RE_V4NETMASK="${RE_V4NETMASK}255\.255\.255\.(255|254|252|248|240|224|192|128|0)"
export V4NETMASK_REGEX='^('"$RE_V4NETMASK"')$'

# interface - eth followed by a digit or single letter
#
RE_INTERFACE="eth[0-9a-z]"
export INTERFACE_REGEX='^('"$RE_INTERFACE"')$'

# Hostname REGEX - may include domain
#
# See:
#	https://stackoverflow.com/a/3824105
#
RE_HOSTNAME="(([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?)([.]([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?))*)"
export HOSTNAME_REGEX='^'"$RE_HOSTNAME"'$'

# Insane Filename REGEX
#
# WARNING: Use of filenames that are insane as the
#	   potential to cause significant problems.
#
# Use Sane filename REGEX instead.
#
# NOTE: Filenames must be no longer than 255 characters.
#
RE_INSANE_FILENAME="[^/]+"
export INSANE_FILENAME_REGEX='^'"$RE_INSANE_FILENAME"'$'

# Sane filename REGEX
#
# We disallow dangerous characters, that while legal,
# has the potential to cause significant problems in filenames.
#
# We only allow filenames that contain:
#
#	0-9
#	A-Z
#	a-z
#	+,_.-
#
# AND that start with only:
#
#	0-9
#	A-Z
#	a-z
#
# NOTE: Filenames must be no longer than 255 characters.
#
RE_SANE_FILENAME="[0-9A-Za-z][0-9A-Za-z+,_.-]*"
export SANE_FILENAME_REGEX='^'"$RE_SANE_FILENAME"'$'

# Sane path REGEX
#
# Paths may only contain same filename characters.
# Paths may not use .. as filename components.
# Paths may not use . as a filename component after starting with a ./ component.
# Paths must not be / alone.
# Paths must not be . alone.
# Paths may not contain more than one / in a row.
#
# NOTE: paths should not be longer than 255 characters.
#
RE_SANE_PATH="${RE_SANE_FILENAME}"
RE_SANE_PATH="${RE_SANE_PATH}|(/${RE_SANE_FILENAME})+/?"
RE_SANE_PATH="${RE_SANE_PATH}|(${RE_SANE_FILENAME}/)+(${RE_SANE_FILENAME})?"
RE_SANE_PATH="${RE_SANE_PATH}|\./(${RE_SANE_FILENAME}/)*(${RE_SANE_FILENAME})?"
export SANE_PATH_REGEX='^('"$RE_SANE_PATH"')$'

# Insane path REGEX
#
# WARNING: Use of path that are insane as the
#	   potential to cause significant problems.
#
# Use Sane path REGEX instead.
#
# NOTE: path must be no longer than 4096 characters.
#
RE_INSANE_PATH=".+"
export INSANE_PATH_REGEX='^'"$RE_INSANE_PATH"'$'

# Sane username
#
# While technically many charachers could be used in a username,
# some characters are not allowed in a URL or a password file.
#
# We limit the username length of 32 characters to conform
# to typrical Un*x username limits.
#
RE_SANE_USERNAME='[A-Za-z][A-Za-z0-9._-]{0,31}'
SANE_USERNAME_REGEX="^${RE_SANE_USERNAME}$"

# Sane password
#
# While technically almost any character is good in a password,
# some characters make it hard for those passwords to be used
# in things such as URLs, or to be passed as shell variables.
#
# We disallow these dangerious characters in a password:
#
#	[[:space:]]%:@/#?
#
# We limit the password length of 32 characters just to
# keep passwords from making a URL too long.
#
RE_SANE_PASSWORD='[^	 %:@/#?]{1,32}'
SANE_PASSWORD_REGEX="^${RE_SANE_PASSWORD}$"

# URL - Uniform Resource Locator
#
# Technically a URL is of the form:
#
#	scheme [: // [userinfo @] host [: port]] path [? quety] [# fragment]
#
# where [ .. ]] denotes something optional.
#
# We will insist that URLs contain a host so that a URL cannnot explicitly refer to a local file.
# We will not prevent the host from referring to the local host, or one of its many aliases.
# We will assume that the local host does not have a web server, or that web server is configured
# with a document root that resides in a suitable directory.
#
# We insist our path must not be empty, therefore the path must at least contain a /.
#
# Therefore our URL will be:
#
#	Scheme : // [Userinfo @] Host [: Port] / Path [? Query] [# Fragment]
#
# Scheme (usually http, https, ftp, file, etc.) is: (we make this manditory)
#
#	sequence of characters beginning with a letter,
#	   followed by any combination of letters, digits, plus (+), period (.), or hyphen (-)
#
# Userinfo is:
#
#	RE_SANE_USERNAME [: [RE_SANE_PASSWORD]]
#
# Host is:
#
#	RE_HOSTNAME or RE_IPV4 or '[' RE_IPV6 ']'	# <-- '[' and ']' are literal characters
#
# Port is:
#
#	RE_PORT
#
# Path is:
#
#	/ followed by zero of more of any chacters except: [[:space:]]%&@:#?
#
# Query is:
#
#	one or more characters excluding: [[:space:]]@:#
#
# Fragment is:
#
#	one or more characters excluding: [[:space:]]@:
#
RE_URL_SCHEME='([A-Za-z][A-Za-z0-9+.-]*)(://)'
RE_URL_USERINFO="((${RE_SANE_USERNAME})((:)(${RE_SANE_PASSWORD}))?@)?"
RE_URL_HOST="((${RE_HOSTNAME})|(${RE_IPV4})|(\[${RE_IPV6}\]))"
RE_URL_PORTNUM="(([:])(${RE_PORT}))?"
RE_URL_PATH='(/[^	 %@:#?]*)?'
RE_URL_QUERY='([?][^	 #]*)?'
RE_URL_FRAGMENT='(#[^	 ]*)?'
RE_URL="${RE_URL_SCHEME}${RE_URL_USERINFO}${RE_URL_HOST}${RE_URL_PORTNUM}${RE_URL_PATH}${RE_URL_QUERY}${RE_URL_FRAGMENT}"
export URL_REGEX="^($RE_URL)"'$'

# prompt - prompt for input
#
# usage:
#
#	prompt "a prompt string"
#
# This function calls the read function with care,
# and sets $INPUT to the input read, or clears $INPUT on error.
#
# The "prompt string" is printed, along with a space,
# before calling read.
#
# We read according to -e, -t timeput and -s as well.
#
# returns:
#	0	read sucessful
#	!= 0	read error
#		   $EXIT_CODE is set
#		   $INPUT is cleared
#
prompt() {

    # parse args
    #
    if [[ $# -ne 1 ]]; then
        echo "$PROG: prompt must have only one argument" 1>&2

        # clear answer
        INPUT=

        # set exit code to "too long"
        EXIT_CODE="$EXIT_USAGE" # exit 3

        # retry or fail if -o
        return "$EXIT_CODE"
    fi

    # Clear any previously supplied INPUT
    #
    INPUT=

    # Determine the read prompt
    #
    if [[ -n $B_FLAG ]]; then
        READ_PROMPT="$1"
    else
        READ_PROMPT="$1 "
    fi
    if [[ -n $V_FLAG ]]; then
        echo "$PROG: debug: prompt \"$READ_PROMPT\"" 1>&2
    fi

    # prompt and read input
    #
    # We use -r so that \ on input is treated as a literal
    # and to make it harder for system crackers to play games
    # with input such as making it multi-line, attempting to
    # escape critical characters, etc.
    #
    # The -e controls if we use READLINE facilities.
    #
    # The -t timeout can limit how long we wait for input.
    # If we timeout, then the read status will be > 128.
    #
    # The -s reads in silent mode. If input is coming from a terminal,
    # characters are not echoed.
    #
    if [[ -n $S_FLAG ]]; then
        if [[ -n $TIMEOUT ]]; then
            if [[ -n $E_FLAG ]]; then
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -e -t $TIMEOUT -n $NCHARS -p \"$READ_PROMPT\" -s INPUT" 1>&2
                fi
                read -r -e -t "$TIMEOUT" -n "$NCHARS" -p "$READ_PROMPT" -s INPUT
                status="$?"
            else
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -t $TIMEOUT -n $NCHARS -p \"$READ_PROMPT\" -s INPUT" 1>&2
                fi
                read -r -t "$TIMEOUT" -n "$NCHARS" -p "$READ_PROMPT" -s INPUT
                status="$?"
            fi
        else
            if [[ -n $E_FLAG ]]; then
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -e -n $NCHARS -p \"$READ_PROMPT\" -s INPUT" 1>&2
                fi
                read -r -e -n "$NCHARS" -p "$READ_PROMPT" -s INPUT
                status="$?"
            else
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -n $NCHARS -p \"$READ_PROMPT\" -s INPUT" 1>&2
                fi
                read -r -n "$NCHARS" -p "$READ_PROMPT" -s INPUT
                status="$?"
            fi
        fi
        # we need to force a newline to the tty because read -s surpressed the newline
        echo >/dev/tty
    else
        if [[ -n $TIMEOUT ]]; then
            if [[ -n $E_FLAG ]]; then
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -e -t $TIMEOUT -n $NCHARS -p \"$READ_PROMPT\" INPUT" 1>&2
                fi
                read -r -e -t "$TIMEOUT" -n "$NCHARS" -p "$READ_PROMPT" INPUT
                status="$?"
            else
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -t $TIMEOUT -n $NCHARS -p \"$READ_PROMPT\" INPUT" 1>&2
                fi
                read -r -t "$TIMEOUT" -n "$NCHARS" -p "$READ_PROMPT" INPUT
                status="$?"
            fi
        else
            if [[ -n $E_FLAG ]]; then
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -e -n $NCHARS -p \"$READ_PROMPT\" INPUT" 1>&2
                fi
                read -r -e -n "$NCHARS" -p "$READ_PROMPT" INPUT
                status="$?"
            else
                if [[ -n $V_FLAG ]]; then
                    echo "$PROG: debug: read -r -n $NCHARS -p \"$READ_PROMPT\" INPUT" 1>&2
                fi
                read -r -n "$NCHARS" -p "$READ_PROMPT" INPUT
                status="$?"
            fi
        fi
    fi

    # reject if input is too long
    #
    if [[ ${#INPUT} -gt $MAXLEN ]]; then
        # Input length exceeded MAXLEN, so the terminal is still on the prompt/input line,
        # so we print a newline on stderr to force any subsequent output (such
        # as another prompt or debug message) onto the beginning of the next line.
        #
        echo 1>&2
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: Warning: input length ${#INPUT} -ge maximum: $MAXLEN" 1>&2
        fi

        # clear answer
        INPUT=

        # set exit code to "too long"
        EXIT_CODE="$EXIT_TOOLONG" # exit 4

        # retry or fail if -o
        return "$EXIT_CODE"

    # reject if timeout
    #
    elif [[ -n $TIMEOUT && ($status -eq 142 || $status -eq 154) ]]; then
        if [[ -n $V_FLAG ]]; then
            echo 1>&2
            echo "$PROG: Warning: timeout, exceeded $TIMEOUT seconds" 1>&2
        fi

        # clear answer
        INPUT=

        # set exit code to "timeout"
        EXIT_CODE="$EXIT_TIMEOUT" # exit 5

        # retry or fail if -o
        return "$EXIT_CODE"

    # reject if read gets a signal
    #
    elif [[ $status -gt 128 && $status -le 192 ]]; then
        ((READ_SIGNAL = "$status" - 128))
        if [[ -n $V_FLAG ]]; then
            echo 1>&2
            echo "$PROG: Warning: read signal: $READ_SIGNAL exit code: $status" 1>&2
        fi

        # clear answer
        INPUT=

        # set exit code to "interrupt"
        EXIT_CODE="$EXIT_INTERRUPT" # exit 5

        # retry or fail if -o
        return "$EXIT_CODE"

    # reject on other read errors
    #
    elif [[ $status -ne 0 ]]; then
        if [[ -n $V_FLAG ]]; then
            echo 1>&2
            echo "$PROG: Warning: read error, exit status: $status" 1>&2
        fi

        # clear answer
        INPUT=

        # set exit code to "timeout"
        EXIT_CODE="$EXIT_READERR" # exit 8

        # retry or fail if -o
        return "$EXIT_CODE"

    # reject if empty input UNLESS TYPE of cr
    #
    elif [[ -z $INPUT && $TYPE != "cr" ]]; then
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: Warning: non-cr type input is empty" 1>&2
        fi

        # clear answer
        INPUT=

        # set exit code to "too long"
        EXIT_CODE="$EXIT_EMPTY" # exit 7

        # retry or fail if -o
        return "$EXIT_CODE"
    fi
    if [[ -n $V_FLAG ]]; then
        if [[ -z $INPUT ]]; then
            echo "$PROG: debug: raw input with trailing newline removed is an empty string" 1>&2
        else
            echo "$PROG: debug: raw input with trailing newline removed: $INPUT" 1>&2
        fi
    fi

    # All is well
    #
    return 0
}

# validate - validate according to $TYPE
#
# usage:
#	validate value
#
# This function will validate the value passed accoding to $TYPE.
#
#
# returns:
#	0	value is valid according to $TYPE
#		    The value $CANONICAL_INPUT may set to the
#		    canonicalized version of the value (used by -c flag).
#	!= 0	value is not valid according to $TYPE
#		   $EXIT_CODE is set
#
validate() {

    # parse args
    #
    local VALUE
    if [[ $# -ne 1 ]]; then
        echo "$PROG: validate must have only one argument" 1>&2

        # set exit code to "too long"
        EXIT_CODE="$EXIT_USAGE" # exit 3

        # retry or fail if -o
        return "$EXIT_CODE"
    fi
    VALUE="$1"
    if [[ -n $V_FLAG ]]; then
        echo "$PROG: debug: validate $VALUE" 1>&2
    fi

    # input has not been rejected out of hand, we now check for input type
    #
    # For each type, if the input ($VALUE) format is not valid, we will
    # clear the input and set the EXIT_CODE.
    #
    case "$TYPE" in

    natint)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any integer > 0" 1>&2
        fi
        if [[ ! $VALUE =~ ^[+]?[0-9]{1,}$ || $VALUE -le 0 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    posint)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: integer >= 0" 1>&2
        fi
        if [[ ! $VALUE =~ ^[+]?[0-9]{1,}$ || $VALUE -lt 0 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    int)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any integer" 1>&2
        fi
        if [[ ! $VALUE =~ ^[+-]?[0-9]{1,}$ ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    natreal)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any real number > 0" 1>&2
        fi
        if [[ $VALUE =~ ^$ || ! $VALUE =~ ^[+]?[0-9]*([.][0-9]*)?$ || $VALUE =~ ^0+([.]0*)?$ ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    posreal)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any real number >= 0" 1>&2
        fi
        if [[ $VALUE =~ ^$ || ! $VALUE =~ ^[+]?[0-9]*([.][0-9]*)?$ ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    real)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any real number" 1>&2
        fi
        if [[ $VALUE =~ ^$ || ! $VALUE =~ ^[+-]?[0-9]*([.][0-9]*)?$ ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    string)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any non-empty single line string, trailing newline removed" 1>&2
        fi
        if [[ -z $VALUE ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    yorn)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: y or n or Y or N or Yes or No or YES or NO" 1>&2
        fi
        case "$VALUE" in
        y | Y | yes | Yes | YES)
            CANONICAL_INPUT='y'
            ;;
        n | N | no | No | NO)
            CANONICAL_INPUT='n'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    cde)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: c or C or d or D or e or E" 1>&2
        fi
        case "$VALUE" in
        c | C)
            CANONICAL_INPUT='c'
            ;;
        d | D)
            CANONICAL_INPUT='d'
            ;;
        e | E)
            CANONICAL_INPUT='e'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    ds)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: d or D or s or S" 1>&2
        fi
        case "$VALUE" in
        d | D)
            CANONICAL_INPUT='d'
            ;;
        s | S)
            CANONICAL_INPUT='s'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    ab)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: a or A or b or B" 1>&2
        fi
        case "$VALUE" in
        a | A)
            CANONICAL_INPUT='a'
            ;;
        b | B)
            CANONICAL_INPUT='b'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    fh)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: f or F or h or H" 1>&2
        fi
        case "$VALUE" in
        f | F)
            CANONICAL_INPUT='f'
            ;;
        h | H)
            CANONICAL_INPUT='h'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    gd)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: g or G or d or D" 1>&2
        fi
        case "$VALUE" in
        g | G)
            CANONICAL_INPUT='g'
            ;;
        d | D)
            CANONICAL_INPUT='d'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    v4v6)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: v4 or V4 or v6 or V6" 1>&2
        fi
        case "$VALUE" in
        v4 | V4)
            CANONICAL_INPUT='v4'
            ;;
        v6 | V6)
            CANONICAL_INPUT='v6'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    123)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: 1 or 2 or 3" 1>&2
        fi
        case "$VALUE" in
        1)
            CANONICAL_INPUT='1'
            ;;
        2)
            CANONICAL_INPUT='2'
            ;;
        3)
            CANONICAL_INPUT='3'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    012)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: 0 or 1 or 2" 1>&2
        fi
        case "$VALUE" in
        0)
            CANONICAL_INPUT='0'
            ;;
        1)
            CANONICAL_INPUT='1'
            ;;
        2)
            CANONICAL_INPUT='2'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    cr)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: just press return" 1>&2
        fi
        if [[ -n $VALUE ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: expected just a return according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    ip4addr)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: IPv4 address" 1>&2
        fi
        if [[ ! $VALUE =~ $IPV4ADDR_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    ip6addr)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: IPv6 address" 1>&2
        fi
        if [[ ! $VALUE =~ $IPV6ADDR_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    v4cidr)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: IPv4 /CIDR" 1>&2
        fi
        if [[ ! $VALUE =~ $IPV4CIDR_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    v6cidr)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: IPv6 /CIDR" 1>&2
        fi
        if [[ ! $VALUE =~ $IPV6CIDR_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    v4netmask)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: IPv4 netmask" 1>&2
        fi
        if [[ ! $VALUE =~ $V4NETMASK_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    ipaddr)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: IPv4 or IPv6 address" 1>&2
        fi
        if [[ ! $VALUE =~ $IPV4ADDR_REGEX && ! $VALUE =~ $IPV6ADDR_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    port)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: UDP or TCP port number (1-65535)" 1>&2
        fi
        if [[ ! $VALUE =~ $PORT_REGEX || $VALUE -lt 0 || $VALUE -gt 65535 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    hostname)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: RFC-952 and RFC-1123 valid hostname" 1>&2
            if [[ $VALUE =~ $HOSTNAME_REGEX ]]; then
                echo "$PROG: debug: match debug" 1>&2
            else
                echo "$PROG: debug: no match debug" 1>&2
            fi
            i="1"
            n="${#BASH_REMATCH[*]}"
            echo "$PROG: debug: match count: $n" 1>&2
            echo "$PROG: debug: pattern[0]: ${BASH_REMATCH[0]}" 1>&2
            while [[ $i -lt $n ]]; do
                echo "$PROG: debug: pattern[$i]: ${BASH_REMATCH[$i]}" 1>&2
                ((i++))
            done
            echo "$PROG: debug: end match debug" 1>&2
            if [[ ${#VALUE} -gt 635 ]]; then
                echo "$PROG: debug: too long: ${#VALUE} -gt 635" 1>&2
            else
                echo "$PROG: debug: length OK: ${#VALUE} -le 635" 1>&2
            fi
        fi
        if [[ ! $VALUE =~ $HOSTNAME_REGEX || ${#VALUE} -gt 635 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    hostoripv4)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: RFC-952 and RFC-1123 valid hostname or IPv4 address" 1>&2
        fi
        if [[ ! $VALUE =~ $HOSTNAME_REGEX && ${#VALUE} -le 635 && ! $VALUE =~ $IPV4ADDR_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    hostorip)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: RFC-952 and RFC-1123 valid hostname or IPv4 address or IPv6 address" 1>&2
        fi
        if [[ ! $VALUE =~ $HOSTNAME_REGEX && ${#VALUE} -le 635 && ! \
            $VALUE =~ $IPV4ADDR_REGEX && ! $VALUE =~ $IPV6ADDR_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    interface)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: eth followed by a digit or single letter" 1>&2
        fi
        if [[ ! $VALUE =~ $INTERFACE_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    sane_filename)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: filename excluding unsafe filename characters" 1>&2
        fi
        if [[ ! $VALUE =~ $SANE_FILENAME_REGEX && ${#VALUE} -le 255 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    insane_filename)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: filename including unsafe filename characters" 1>&2
        fi
        if [[ ! $VALUE =~ $INSANE_FILENAME_REGEX && ${#VALUE} -le 255 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    sane_path)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: filename including unsafe filename characters" 1>&2
        fi
        if [[ ! $VALUE =~ $SANE_PATH_REGEX || ${#VALUE} -gt 255 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    insane_path)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: path including unsafe filename characters" 1>&2
        fi
        if [[ ! $VALUE =~ $INSANE_PATH_REGEX || ${#VALUE} -gt 4096 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    sane_username)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: username with only safe characters" 1>&2
        fi
        if [[ ! $VALUE =~ $SANE_USERNAME_REGEX || ${#VALUE} -gt 32 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    insane_username)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any non-empty single line username, trailing newline removed" 1>&2
        fi
        if [[ -z $VALUE ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    sane_password)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: password with only safe characters" 1>&2
        fi
        if [[ ! $VALUE =~ $SANE_PASSWORD_REGEX || ${#VALUE} -gt 32 ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    insane_password)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: any non-empty single line password, trailing newline removed" 1>&2
        fi
        if [[ -z $VALUE ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    sane_url)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: Uniform Resource Locator with sane restrictions" 1>&2
            if [[ $VALUE =~ $URL_REGEX ]]; then
                echo "$PROG: debug: match debug" 1>&2
            else
                echo "$PROG: debug: no match debug" 1>&2
            fi
            i="1"
            n="${#BASH_REMATCH[*]}"
            echo "$PROG: debug: match count: $n" 1>&2
            echo "$PROG: debug: pattern[0]: ${BASH_REMATCH[0]}" 1>&2
            while [[ $i -lt $n ]]; do
                echo "$PROG: debug: pattern[$i]: ${BASH_REMATCH[$i]}" 1>&2
                ((i++))
            done
            echo "$PROG: debug: end match debug" 1>&2
        fi
        if [[ ! $VALUE =~ $URL_REGEX ]]; then
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
        fi
        ;;

    trans_mode_0)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: ftp sftp scp   plus Caps and ALL CAPS" 1>&2
        fi
        case "$VALUE" in
        ftp | Ftp | FTP)
            CANONICAL_INPUT='ftp'
            ;;
        scp | Scp | SCP)
            CANONICAL_INPUT='scp'
            ;;
        sftp | Sftp | SFTP)
            CANONICAL_INPUT='sftp'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    trans_mode_1)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: sftp scp ftp http file   plus Caps and ALL CAPS" 1>&2
        fi
        case "$VALUE" in
        sftp | Sftp | SFTP)
            CANONICAL_INPUT='sftp'
            ;;
        scp | Scp | SCP)
            CANONICAL_INPUT='scp'
            ;;
        ftp | Ftp | FTP)
            CANONICAL_INPUT='ftp'
            ;;
        http | Http | HTTP)
            CANONICAL_INPUT='http'
            ;;
        file | File | FILE)
            CANONICAL_INPUT='file'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    trans_mode_2)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: debug: type $TYPE validation: http https   plus Caps and ALL CAPS" 1>&2
        fi
        case "$VALUE" in
        http | Http | HTTP)
            CANONICAL_INPUT='http'
            ;;
        https | Https | HTTPS)
            CANONICAL_INPUT='https'
            ;;
        *)
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: Warning: input format is not valid according to: $TYPE" 1>&2
            fi
            EXIT_CODE="$EXIT_BADFORMAT" # exit 1
            return "$EXIT_CODE"
            ;;
        esac
        ;;

    # should never get here
    *)
        if [[ -n $V_FLAG ]]; then
            echo "$PROG: unknown type: $TYPE" 1>&2
        fi
        echo # print empty stdout to indicate error
        # This exit is an exception to the normal case.
        # We normally would have checked the type when we
        # parsed arguments.  To avoid having two type checks,
        # we do a delayed usage check here and exit as if
        # the command line was invalid.
        exit "$EXIT_USAGE" # exit 3
        ;;

    esac

    # All is well
    #
    return 0
}

# We use NCHARS (MAXLEN+1) so that we can determine if the
# input reached the original -m maxlen and reject it.
# The shell will stop at maxlen+1 and we can reject
# the input as being too long.
#
export NCHARS
((NCHARS = MAXLEN + 1))

# Our ANSWER will be printed as a non-empty string to stdout,
# if valid, in which case we wille exit 0.  Otherwise we will
# print a empty line to stdout and exit non-zero.
#
export ANSWER=

# promit and read
#
# We will prompt and read input, validating input,
# and unless -o, repromt if input is invalid.
#
export RETRY="true"
export EXIT_CODE="0"
while [[ -n $RETRY ]]; do

    # If -o, we will not retry if input is invalid.
    #
    if [[ -n $O_FLAG ]]; then
        RETRY=
    fi

    # Clear any previous exit code
    #
    EXIT_CODE=0

    # Clear any previous input
    #
    INPUT=

    # prompt for input
    #
    prompt "$PROMPT"
    status="$?"
    if [[ $status -ne 0 ]]; then
        # prompt error, do not process $INPUT
        continue
    fi
    ANSWER="$INPUT"

    # Clear any previous canonical input
    #
    CANONICAL_INPUT=

    # validate input
    #
    validate "$ANSWER"
    status="$?"
    if [[ $status -ne 0 ]]; then
        # input validation error
        ANSWER=
        continue
    fi

    # If -c, the the answer is the canonical answer
    #
    if [[ -n $C_FLAG && -n $CANONICAL_INPUT ]]; then
        if [[ -n $V_FLAG ]]; then
            if [[ $ANSWER == "$CANONICAL_INPUT" ]]; then
                echo "$PROG: debug: input is canonical: $CANONICAL_INPUT" 1>&2
            else
                echo "$PROG: debug: input: $ANSWER changed to canonical: $CANONICAL_INPUT" 1>&2
            fi
        fi
        ANSWER="$CANONICAL_INPUT"
    fi

    # Assuming we have an answer, and if -r repeat_prompt,
    # then ask again with the repeat_prompt
    # and verify that the 2nd input is the same.
    #
    if [[ -n $REPEAT_PROMPT ]]; then

        # Clear any previous input
        #
        INPUT=

        # prompt again, with the -r repeat_prompt string
        #
        prompt "$REPEAT_PROMPT"
        status="$?"
        if [[ $status -ne 0 ]]; then
            # input validation error
            ANSWER=
            continue
        fi
        SECOND_ANSWER="$INPUT"

        # Clear any previous canonical input
        #
        CANONICAL_INPUT=

        # validate input
        #
        validate "$SECOND_ANSWER"
        status="$?"
        if [[ $status -ne 0 ]]; then
            # input validation error
            ANSWER=
            continue
        fi

        # If -c, the the second answer is the canonical answer
        #
        if [[ -n $C_FLAG && -n $CANONICAL_INPUT ]]; then
            if [[ -n $V_FLAG ]]; then
                if [[ $SECOND_ANSWER == "$CANONICAL_INPUT" ]]; then
                    echo "$PROG: debug: 2nd input is canonical: $CANONICAL_INPUT" 1>&2
                else
                    echo "$PROG: debug: 2nd input: $SECOND_ANSWER changed to canonical: $CANONICAL_INPUT" 1>&2
                fi
            fi
            SECOND_ANSWER="$CANONICAL_INPUT"
        fi

        # If -r repeat_prompt, second input must match
        #
        if [[ $ANSWER != "$SECOND_ANSWER" ]]; then
            # second input mismatch
            if [[ -n $V_FLAG ]]; then
                echo "$PROG: debug: 1st and 2nd inputs did not match" 1>&2
            fi
            EXIT_CODE="$EXIT_MISMATCH" # exit 6
            ANSWER=
            if [[ -n $ERRMSG ]]; then
                echo "$ERRMSG" 1>&2
            fi
            continue
        fi
    fi

    # Determine if we need to retry, and if we do,
    # if we need to issue an error message.
    #
    case "$TYPE" in
    cr)
        if [[ -z $ANSWER ]]; then
            # we do not need to retry
            RETRY=
        elif [[ -n $ERRMSG ]]; then
            echo "$ERRMSG" 1>&2
        fi
        ;;
    *)
        if [[ -n $ANSWER ]]; then
            # we do not need to retry
            RETRY=
        elif [[ -n $ERRMSG ]]; then
            echo "$ERRMSG" 1>&2
        fi
        ;;
    esac
done

# For cr TYPE, empty answer is returned as a space
#
if [[ $TYPE == cr && -z $ANSWER ]]; then
    ANSWER=' '
fi

# output the answer to stdout
#
# In the case of an error, this will be an empty line.
#
if [[ -n $V_FLAG && $EXIT_CODE -ne 0 ]]; then
    echo "$PROG: Warning: about to exit non-zero: $EXIT_CODE" 1>&2
fi
echo "$ANSWER"

# All Done!!! -- Jessica Noll, Age 2
#
# exit according to the exit code previously set
#
exit "$EXIT_CODE"
