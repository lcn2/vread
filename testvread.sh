#!/bin/bash
#
# testvread.sh - test vread.sh
#
# usage:
#	testvread.sh [-v] path-to-vread.sh
#
#	NOTE: See USAGE variable below for details
#
# stdout:
#	validated input or empty line
#
# exit code:
#	0	all tests passed
#	!= 0	usage error or some test failed
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

# setup
#
export VERSION="4.1.1-20200217"
export V_FLAG=
export VREAD=
export EXIT_BADTEST=1
export EXIT_MISSING=2
export EXIT_USAGE=3
export EXIT_NOTAFILE=4
export EXIT_NOTEXECUTABLE=5
export PROG="$0"
export USAGE="usage:

$PROG [-h] [-v] path-to-vread

    -h		output usage message and exit $EXIT_USAGE
    -v		verbose mode for debugging

    path-to-vread	path to the vread to test

Version: $VERSION"

# parse args
#
while getopts :hvoem:t: flag; do

    # validate flag
    #
    case "$flag" in
    h)  echo "$USAGE" 1>&2
	echo # empty stdout to indicate error
	exit "$EXIT_USAGE" # exit 3
	;;
    v)  V_FLAG="true"
	;;
    \?) echo "$PROG: invalid option: -$OPTARG" 1>&2
	echo "$USAGE" 1>&2
	echo # empty stdout to indicate error
	exit "$EXIT_USAGE" # exit 3
	;;
    :)  echo "$PROG: option -$OPTARG requires an argument" 1>&2
	echo "$USAGE" 1>&2
	echo # empty stdout to indicate error
	exit "$EXIT_USAGE" # exit 3
	;;
    *)  echo "$PROG: unexpected return from getopts: $flag" 1>&2
	echo "$USAGE" 1>&2
	echo # empty stdout to indicate error
	exit "$EXIT_USAGE" # exit 3
	;;
esac
done
shift $(( OPTIND - 1 ));
#
# parse the 2 or 3 option args
#
case "$#" in
1) VREAD="$1"
   ;;
*)  echo "$PROG: must have 1 arg" 1>&2
    echo "$USAGE" 1>&2
    exit "$EXIT_USAGE" # exit 3
    ;;
esac
#
# We cannot not assume that . is in the path,
# so prepend ./ if the path starts with a filename.
#
if [[ $VREAD =~ ^[^./] ]]; then
    VREAD="./$VREAD"
fi

# verify that vread exists and is executable
#
if [[ ! -e $VREAD ]]; then
    echo "$PROG: FATAL: cannot find vread executable: $VREAD" 1>&2
    exit "$EXIT_MISSING" # exit 2
elif [[ ! -f $VREAD ]]; then
    echo "$PROG: FATAL: vread executable not a file: $VREAD" 1>&2
    exit "$EXIT_NOTAFILE" # exit 4
elif [[ ! -x $VREAD ]]; then
    echo "$PROG: FATAL: vread executable not executable: $VREAD" 1>&2
    exit "$EXIT_NOTEXECUTABLE" # exit 5
fi
if [[ -n $V_FLAG ]]; then
    echo "$PROG: debug: vread executable: $VREAD" 1>&2
fi

# test for valid input
#
valid_input_test() {
    # parse args
    #
    if [[ $# -ne 2 ]]; then
	echo "$PROG: usage: valid_input_test input type" 1>&2
	echo "$PROG: ERROR: found $# args" 1>&2
	exit 2
    fi
    INPUT="$1"
    TYPE="$2"

    # give input to vread once
    #
    if [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: valid_input_test $*" 1>&2
    fi
    ANSWER=$(echo "$INPUT" | "$VREAD" -e -o "$TYPE" prompt)
    status="$?"
    if [[ $TYPE = cr && $ANSWER = ' ' ]]; then
	ANSWER=''
    fi

    # check for unexpected vread error
    #
    if [[ $status -ne 0 ]]; then
	echo "$PROG: ERROR: FAIL: valid_input_test $*" 1>&2
	echo "$PROG: ERROR: non-zero exit status: $status" 1>&2
	exit "$EXIT_BADTEST" # exit 1
    elif [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: pass" 1>&2
    fi
}

# test for input for limited length
#
valid_length_input_test() {
    # parse args
    #
    if [[ $# -ne 3 ]]; then
	echo "$PROG: usage: valid_length_input_test type maxlen" 1>&2
	echo "$PROG: ERROR: found $# args" 1>&2
	exit 2
    fi
    INPUT="$1"
    TYPE="$2"
    MAXLEN="$3"

    # give input to vread once
    #
    if [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: valid_length_input_test $*" 1>&2
    fi
    ANSWER=$(echo "$INPUT" | "$VREAD" -e -o -m "$MAXLEN" "$TYPE" prompt 2>/dev/null)
    status="$?"
    if [[ $TYPE = cr && $ANSWER = ' ' ]]; then
	ANSWER=''
    fi

    # check for unexpected vread error
    #
    if [[ $status -ne 0 ]]; then
	echo "$PROG: ERROR: FAIL: valid_length_input_test $*" 1>&2
	echo "$PROG: ERROR: non-zero exit status: $status" 1>&2
	exit "$EXIT_BADTEST" # exit 1
    elif [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: pass" 1>&2
    fi
}

# test for invalid input
#
invalid_input_test() {
    # parse args
    #
    if [[ $# -ne 3 ]]; then
	echo "$PROG: usage: invalid_input_test type expected_exitcode" 1>&2
	echo "$PROG: ERROR: found $# args" 1>&2
	exit 2
    fi
    INPUT="$1"
    TYPE="$2"
    EXPECTED_CODE="$3"

    # give input to vread once
    #
    if [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: invalid_input_test $*" 1>&2
    fi
    ANSWER=$(echo "$INPUT" | "$VREAD" -e -o "$TYPE" prompt)
    status="$?"

    # check for unexpected vread error
    #
    if [[ $status -eq 0 ]]; then
	echo "$PROG: ERROR: FAIL: invalid_input_test $*" 1>&2
	echo "$PROG: ERROR: test failed to fail" 1>&2
	exit "$EXIT_BADTEST" # exit 1
    elif [[ $status -ne $EXPECTED_CODE ]]; then
	echo "$PROG: ERROR: FAIL: invalid_input_test $*" 1>&2
	echo "$PROG: ERROR: expected test to exit: $EXPECTED_CODE found: $status" 1>&2
	exit "$EXIT_BADTEST" # exit 1
    elif [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: pass" 1>&2
    fi
}

# test for input too long for limited length
#
invalid_length_input_test() {
    # parse args
    #
    if [[ $# -ne 4 ]]; then
	echo "$PROG: usage: invalid_length_input_test type expected_exitcode maxlen" 1>&2
	echo "$PROG: ERROR: found $# args" 1>&2
	exit 2
    fi
    INPUT="$1"
    TYPE="$2"
    EXPECTED_CODE="$3"
    MAXLEN="$4"

    # give input to vread once
    #
    if [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: invalid_length_input_test $*" 1>&2
    fi
    ANSWER=$(echo "$INPUT" | "$VREAD" -e -o -m "$MAXLEN" "$TYPE" prompt 2>/dev/null)
    status="$?"
    if [[ $TYPE = cr && $ANSWER = ' ' ]]; then
	ANSWER=''
    fi

    # check for unexpected vread error
    #
    if [[ $status -eq 0 ]]; then
	echo "$PROG: ERROR: FAIL: invalid_length_input_test $*" 1>&2
	echo "$PROG: ERROR: test failed to fail" 1>&2
	exit "$EXIT_BADTEST" # exit 1
    elif [[ $status -ne $EXPECTED_CODE ]]; then
	echo "$PROG: ERROR: FAIL: invalid_length_input_test $*" 1>&2
	echo "$PROG: ERROR: expected test to exit: $EXPECTED_CODE found: $status" 1>&2
	exit "$EXIT_BADTEST" # exit 1
    elif [[ -n $V_FLAG ]]; then
	echo "$PROG: debug: pass" 1>&2
    fi
}

# perform tests - exit on first failure
#
valid_input_test '1' natint
valid_input_test '10' natint
valid_input_test '100' natint
valid_input_test '32788' natint
valid_input_test '1234567890' natint
invalid_input_test '0' natint 1
invalid_input_test '000' natint 1
invalid_input_test '-1' natint 1
invalid_input_test '-134' natint 1
invalid_input_test 'abc' natint 1
invalid_input_test '1abc' natint 1
invalid_input_test 'abc1' natint 1
invalid_input_test '' natint 7
invalid_input_test '0.' natint 1
invalid_input_test '0.000' natint 1
invalid_input_test '-0.0' natint 1
invalid_input_test '-.000' natint 1
invalid_input_test '1.' natint 1
invalid_input_test '1.234' natint 1
invalid_input_test '.23' natint 1
invalid_input_test '-1.' natint 1
invalid_input_test '-1.234' natint 1
invalid_input_test '-.234' natint 1
#
valid_input_test '1' posint
valid_input_test '10' posint
valid_input_test '100' posint
valid_input_test '0' posint
valid_input_test '000' posint
valid_input_test '32788' posint
valid_input_test '1234567890' posint
invalid_input_test '-1' posint 1
invalid_input_test '-134' posint 1
invalid_input_test 'abc' posint 1
invalid_input_test '1abc' posint 1
invalid_input_test 'abc1' posint 1
invalid_input_test '' posint 7
invalid_input_test '0.' posint 1
invalid_input_test '0.000' posint 1
invalid_input_test '-0.0' posint 1
invalid_input_test '-.000' posint 1
invalid_input_test '1.' posint 1
invalid_input_test '1.234' posint 1
invalid_input_test '.23' posint 1
invalid_input_test '-1.' posint 1
invalid_input_test '-1.234' posint 1
invalid_input_test '-.234' posint 1
#
valid_input_test '1' int
valid_input_test '10' int
valid_input_test '100' int
valid_input_test '0' int
valid_input_test '000' int
valid_input_test '32788' int
valid_input_test '1234567890' int
valid_input_test '-1' int
valid_input_test '-134' int
invalid_input_test 'abc' int 1
invalid_input_test '1abc' int 1
invalid_input_test 'abc1' int 1
invalid_input_test '' int 7
invalid_input_test '0.' int 1
invalid_input_test '0.000' int 1
invalid_input_test '-0.0' int 1
invalid_input_test '-.000' int 1
invalid_input_test '1.' int 1
invalid_input_test '1.234' int 1
invalid_input_test '.23' int 1
invalid_input_test '-1.' int 1
invalid_input_test '-1.234' int 1
invalid_input_test '-.234' int 1
#
valid_input_test '1' natreal
valid_input_test '10' natreal
valid_input_test '100' natreal
valid_input_test '32788' natreal
valid_input_test '1234567890' natreal
invalid_input_test '0' natreal 1
invalid_input_test '000' natreal 1
invalid_input_test '-1' natreal 1
invalid_input_test '-134' natreal 1
invalid_input_test 'abc' natreal 1
invalid_input_test '1abc' natreal 1
invalid_input_test 'abc1' natreal 1
invalid_input_test '' natreal 7
invalid_input_test '0.000' natreal 1
invalid_input_test '-0.0' natreal 1
invalid_input_test '-.000' natreal 1
valid_input_test '1.' natreal
valid_input_test '1.234' natreal
valid_input_test '.23' natreal
invalid_input_test '-1.' natreal 1
invalid_input_test '-1.234' natreal 1
invalid_input_test '-.234' natreal 1
#
valid_input_test '1' posreal
valid_input_test '10' posreal
valid_input_test '100' posreal
valid_input_test '0' posreal
valid_input_test '000' posreal
valid_input_test '32788' posreal
valid_input_test '1234567890' posreal
invalid_input_test '-1' posreal 1
invalid_input_test '-134' posreal 1
invalid_input_test 'abc' posreal 1
invalid_input_test '1abc' posreal 1
invalid_input_test 'abc1' posreal 1
invalid_input_test '' posreal 7
valid_input_test '1.' posreal
valid_input_test '1.234' posreal
valid_input_test '.23' posreal
invalid_input_test '-1.' posreal 1
invalid_input_test '-1.234' posreal 1
invalid_input_test '-.234' posreal 1
#
valid_input_test '1' real
valid_input_test '10' real
valid_input_test '100' real
valid_input_test '0' real
valid_input_test '000' real
valid_input_test '32788' real
valid_input_test '1234567890' real
valid_input_test '-1' real
valid_input_test '-134' real
invalid_input_test 'abc' real 1
invalid_input_test '1abc' real 1
invalid_input_test 'abc1' real 1
invalid_input_test '' real 7
valid_input_test '1.' real
valid_input_test '1.234' real
valid_input_test '.23' real
valid_input_test '-1.' real
valid_input_test '-1.234' real
valid_input_test '-.234' real
#
valid_input_test '1' string
valid_input_test '10' string
valid_input_test '100' string
valid_input_test '0' string
valid_input_test '000' string
valid_input_test '32788' string
valid_input_test '1234567890' string
valid_input_test '-1' string
valid_input_test '-134' string
valid_input_test 'abc' string
valid_input_test '1abc' string
valid_input_test 'abc1' string
invalid_input_test '' string 7
valid_input_test '1.' string
valid_input_test '1.234' string
valid_input_test '.23' string
valid_input_test '-1.' string
valid_input_test '-1.234' string
valid_input_test '-.234' string
#
valid_length_input_test abcdef string 6
valid_length_input_test abcdef string 7
invalid_length_input_test abcdef string 4 5
#
valid_input_test 'y' yorn
valid_input_test 'Y' yorn
valid_input_test 'n' yorn
valid_input_test 'N' yorn
valid_input_test 'yes' yorn
valid_input_test 'Yes' yorn
valid_input_test 'YES' yorn
valid_input_test 'no' yorn
valid_input_test 'No' yorn
valid_input_test 'NO' yorn
invalid_input_test 'c' yorn 1
invalid_input_test 'C' yorn 1
invalid_input_test 'd' yorn 1
invalid_input_test 'D' yorn 1
invalid_input_test 'e' yorn 1
invalid_input_test 'E' yorn 1
invalid_input_test 's' yorn 1
invalid_input_test 'S' yorn 1
invalid_input_test 'a' yorn 1
invalid_input_test 'A' yorn 1
invalid_input_test 'b' yorn 1
invalid_input_test 'B' yorn 1
invalid_input_test 'f' yorn 1
invalid_input_test 'F' yorn 1
invalid_input_test 'h' yorn 1
invalid_input_test 'H' yorn 1
invalid_input_test '0' yorn 1
invalid_input_test '1' yorn 1
invalid_input_test '2' yorn 1
invalid_input_test '3' yorn 1
invalid_input_test '4' yorn 1
invalid_input_test '5' yorn 1
invalid_input_test 'abc' yorn 1
invalid_input_test '1abc' yorn 1
invalid_input_test 'abc1' yorn 1
invalid_input_test 'v4' yorn 1
invalid_input_test 'V4' yorn 1
invalid_input_test 'v5' yorn 1
invalid_input_test 'V5' yorn 1
invalid_input_test 'v6' yorn 1
invalid_input_test 'V6' yorn 1
invalid_input_test '' yorn 7
#
invalid_input_test 'y' cde 1
invalid_input_test 'Y' cde 1
invalid_input_test 'n' cde 1
invalid_input_test 'N' cde 1
invalid_input_test 'yes' cde 1
invalid_input_test 'Yes' cde 1
invalid_input_test 'YES' cde 1
invalid_input_test 'no' cde 1
invalid_input_test 'No' cde 1
invalid_input_test 'NO' cde 1
valid_input_test 'c' cde
valid_input_test 'C' cde
valid_input_test 'd' cde
valid_input_test 'D' cde
valid_input_test 'e' cde
valid_input_test 'E' cde
invalid_input_test 's' cde 1
invalid_input_test 'S' cde 1
invalid_input_test 'a' cde 1
invalid_input_test 'A' cde 1
invalid_input_test 'b' cde 1
invalid_input_test 'B' cde 1
invalid_input_test 'f' cde 1
invalid_input_test 'F' cde 1
invalid_input_test 'h' cde 1
invalid_input_test 'H' cde 1
invalid_input_test '0' cde 1
invalid_input_test '1' cde 1
invalid_input_test '2' cde 1
invalid_input_test '3' cde 1
invalid_input_test '4' cde 1
invalid_input_test '5' cde 1
invalid_input_test 'abc' cde 1
invalid_input_test '1abc' cde 1
invalid_input_test 'abc1' cde 1
invalid_input_test 'v4' cde 1
invalid_input_test 'V4' cde 1
invalid_input_test 'v5' cde 1
invalid_input_test 'V5' cde 1
invalid_input_test 'v6' cde 1
invalid_input_test 'V6' cde 1
invalid_input_test '' cde 7
#
invalid_input_test 'y' ds 1
invalid_input_test 'Y' ds 1
invalid_input_test 'n' ds 1
invalid_input_test 'N' ds 1
invalid_input_test 'yes' ds 1
invalid_input_test 'Yes' ds 1
invalid_input_test 'YES' ds 1
invalid_input_test 'no' ds 1
invalid_input_test 'No' ds 1
invalid_input_test 'NO' ds 1
invalid_input_test 'c' ds 1
invalid_input_test 'C' ds 1
valid_input_test 'd' ds
valid_input_test 'D' ds
invalid_input_test 'e' ds 1
invalid_input_test 'E' ds 1
valid_input_test 's' ds
valid_input_test 'S' ds
invalid_input_test 'a' ds 1
invalid_input_test 'A' ds 1
invalid_input_test 'b' ds 1
invalid_input_test 'B' ds 1
invalid_input_test 'f' ds 1
invalid_input_test 'F' ds 1
invalid_input_test 'h' ds 1
invalid_input_test 'H' ds 1
invalid_input_test '0' ds 1
invalid_input_test '1' ds 1
invalid_input_test '2' ds 1
invalid_input_test '3' ds 1
invalid_input_test '4' ds 1
invalid_input_test '5' ds 1
invalid_input_test 'abc' ds 1
invalid_input_test '1abc' ds 1
invalid_input_test 'abc1' ds 1
invalid_input_test 'v4' ds 1
invalid_input_test 'V4' ds 1
invalid_input_test 'v5' ds 1
invalid_input_test 'V5' ds 1
invalid_input_test 'v6' ds 1
invalid_input_test 'V6' ds 1
invalid_input_test '' ds 7
#
invalid_input_test 'y' ab 1
invalid_input_test 'Y' ab 1
invalid_input_test 'n' ab 1
invalid_input_test 'N' ab 1
invalid_input_test 'yes' ab 1
invalid_input_test 'Yes' ab 1
invalid_input_test 'YES' ab 1
invalid_input_test 'no' ab 1
invalid_input_test 'No' ab 1
invalid_input_test 'NO' ab 1
invalid_input_test 'c' ab 1
invalid_input_test 'C' ab 1
invalid_input_test 'd' ab 1
invalid_input_test 'D' ab 1
invalid_input_test 'e' ab 1
invalid_input_test 'E' ab 1
invalid_input_test 's' ab 1
invalid_input_test 'S' ab 1
valid_input_test 'a' ab
valid_input_test 'A' ab
valid_input_test 'b' ab
valid_input_test 'B' ab
invalid_input_test 'f' ab 1
invalid_input_test 'F' ab 1
invalid_input_test 'h' ab 1
invalid_input_test 'H' ab 1
invalid_input_test '0' ab 1
invalid_input_test '1' ab 1
invalid_input_test '2' ab 1
invalid_input_test '3' ab 1
invalid_input_test '4' ab 1
invalid_input_test '5' ab 1
invalid_input_test 'abc' ab 1
invalid_input_test '1abc' ab 1
invalid_input_test 'abc1' ab 1
invalid_input_test 'v4' ab 1
invalid_input_test 'V4' ab 1
invalid_input_test 'v5' ab 1
invalid_input_test 'V5' ab 1
invalid_input_test 'v6' ab 1
invalid_input_test 'V6' ab 1
invalid_input_test '' ab 7
#
invalid_input_test 'y' fh 1
invalid_input_test 'Y' fh 1
invalid_input_test 'n' fh 1
invalid_input_test 'N' fh 1
invalid_input_test 'yes' fh 1
invalid_input_test 'Yes' fh 1
invalid_input_test 'YES' fh 1
invalid_input_test 'no' fh 1
invalid_input_test 'No' fh 1
invalid_input_test 'NO' fh 1
invalid_input_test 'c' fh 1
invalid_input_test 'C' fh 1
invalid_input_test 'd' fh 1
invalid_input_test 'D' fh 1
invalid_input_test 'e' fh 1
invalid_input_test 'E' fh 1
invalid_input_test 's' fh 1
invalid_input_test 'S' fh 1
invalid_input_test 'a' fh 1
invalid_input_test 'A' fh 1
invalid_input_test 'b' fh 1
invalid_input_test 'B' fh 1
valid_input_test 'f' fh
valid_input_test 'F' fh
valid_input_test 'h' fh
valid_input_test 'H' fh
invalid_input_test '0' fh 1
invalid_input_test '1' fh 1
invalid_input_test '2' fh 1
invalid_input_test '3' fh 1
invalid_input_test '4' fh 1
invalid_input_test '5' fh 1
invalid_input_test 'abc' fh 1
invalid_input_test '1abc' fh 1
invalid_input_test 'abc1' fh 1
invalid_input_test 'v4' fh 1
invalid_input_test 'V4' fh 1
invalid_input_test 'v5' fh 1
invalid_input_test 'V5' fh 1
invalid_input_test 'v6' fh 1
invalid_input_test 'V6' fh 1
invalid_input_test '' fh 7
#
invalid_input_test 'y' v4v6 1
invalid_input_test 'Y' v4v6 1
invalid_input_test 'n' v4v6 1
invalid_input_test 'N' v4v6 1
invalid_input_test 'yes' v4v6 1
invalid_input_test 'Yes' v4v6 1
invalid_input_test 'YES' v4v6 1
invalid_input_test 'no' v4v6 1
invalid_input_test 'No' v4v6 1
invalid_input_test 'NO' v4v6 1
invalid_input_test 'c' v4v6 1
invalid_input_test 'C' v4v6 1
invalid_input_test 'd' v4v6 1
invalid_input_test 'D' v4v6 1
invalid_input_test 'e' v4v6 1
invalid_input_test 'E' v4v6 1
invalid_input_test 's' v4v6 1
invalid_input_test 'S' v4v6 1
invalid_input_test 'a' v4v6 1
invalid_input_test 'A' v4v6 1
invalid_input_test 'b' v4v6 1
invalid_input_test 'B' v4v6 1
invalid_input_test 'f' v4v6 1
invalid_input_test 'F' v4v6 1
invalid_input_test 'h' v4v6 1
invalid_input_test 'H' v4v6 1
invalid_input_test '0' v4v6 1
invalid_input_test '1' v4v6 1
invalid_input_test '2' v4v6 1
invalid_input_test '3' v4v6 1
invalid_input_test '4' v4v6 1
invalid_input_test '5' v4v6 1
invalid_input_test 'abc' v4v6 1
invalid_input_test '1abc' v4v6 1
invalid_input_test 'abc1' v4v6 1
valid_input_test 'v4' v4v6
valid_input_test 'V4' v4v6
invalid_input_test 'v5' v4v6 1
invalid_input_test 'V5' v4v6 1
valid_input_test 'v6' v4v6
valid_input_test 'V6' v4v6
invalid_input_test '' v4v6 7
#
invalid_input_test 'y' 123 1
invalid_input_test 'Y' 123 1
invalid_input_test 'n' 123 1
invalid_input_test 'N' 123 1
invalid_input_test 'yes' 123 1
invalid_input_test 'Yes' 123 1
invalid_input_test 'YES' 123 1
invalid_input_test 'no' 123 1
invalid_input_test 'No' 123 1
invalid_input_test 'NO' 123 1
invalid_input_test 'c' 123 1
invalid_input_test 'C' 123 1
invalid_input_test 'd' 123 1
invalid_input_test 'D' 123 1
invalid_input_test 'e' 123 1
invalid_input_test 'E' 123 1
invalid_input_test 's' 123 1
invalid_input_test 'S' 123 1
invalid_input_test 'a' 123 1
invalid_input_test 'A' 123 1
invalid_input_test 'b' 123 1
invalid_input_test 'B' 123 1
invalid_input_test 'f' 123 1
invalid_input_test 'F' 123 1
invalid_input_test 'h' 123 1
invalid_input_test 'H' 123 1
invalid_input_test '0' 123 1
valid_input_test '1' 123
valid_input_test '2' 123
valid_input_test '3' 123
invalid_input_test '4' 123 1
invalid_input_test '5' 123 1
invalid_input_test 'abc' 123 1
invalid_input_test '1abc' 123 1
invalid_input_test 'abc1' 123 1
invalid_input_test 'v4' 123 1
invalid_input_test 'V4' 123 1
invalid_input_test 'v5' 123 1
invalid_input_test 'V5' 123 1
invalid_input_test 'v6' 123 1
invalid_input_test 'V6' 123 1
invalid_input_test '' 123 7
#
invalid_input_test 'y' 012 1
invalid_input_test 'Y' 012 1
invalid_input_test 'n' 012 1
invalid_input_test 'N' 012 1
invalid_input_test 'yes' 012 1
invalid_input_test 'Yes' 012 1
invalid_input_test 'YES' 012 1
invalid_input_test 'no' 012 1
invalid_input_test 'No' 012 1
invalid_input_test 'NO' 012 1
invalid_input_test 'c' 012 1
invalid_input_test 'C' 012 1
invalid_input_test 'd' 012 1
invalid_input_test 'D' 012 1
invalid_input_test 'e' 012 1
invalid_input_test 'E' 012 1
invalid_input_test 's' 012 1
invalid_input_test 'S' 012 1
invalid_input_test 'a' 012 1
invalid_input_test 'A' 012 1
invalid_input_test 'b' 012 1
invalid_input_test 'B' 012 1
invalid_input_test 'f' 012 1
invalid_input_test 'F' 012 1
invalid_input_test 'h' 012 1
invalid_input_test 'H' 012 1
valid_input_test '0' 012
valid_input_test '1' 012
valid_input_test '2' 012
invalid_input_test '3' 012 1
invalid_input_test '4' 012 1
invalid_input_test '5' 012 1
invalid_input_test 'abc' 012 1
invalid_input_test '1abc' 012 1
invalid_input_test 'abc1' 012 1
invalid_input_test 'v4' 012 1
invalid_input_test 'V4' 012 1
invalid_input_test 'v5' 012 1
invalid_input_test 'V5' 012 1
invalid_input_test 'v6' 012 1
invalid_input_test 'V6' 012 1
invalid_input_test '' 012 7
#
invalid_input_test 'y' cr 1
invalid_input_test 'Y' cr 1
invalid_input_test 'n' cr 1
invalid_input_test 'N' cr 1
invalid_input_test 'yes' cr 1
invalid_input_test 'Yes' cr 1
invalid_input_test 'YES' cr 1
invalid_input_test 'no' cr 1
invalid_input_test 'No' cr 1
invalid_input_test 'NO' cr 1
invalid_input_test 'c' cr 1
invalid_input_test 'C' cr 1
invalid_input_test 'd' cr 1
invalid_input_test 'D' cr 1
invalid_input_test 'e' cr 1
invalid_input_test 'E' cr 1
invalid_input_test 's' cr 1
invalid_input_test 'S' cr 1
invalid_input_test 'a' cr 1
invalid_input_test 'A' cr 1
invalid_input_test 'b' cr 1
invalid_input_test 'B' cr 1
invalid_input_test 'f' cr 1
invalid_input_test 'F' cr 1
invalid_input_test 'h' cr 1
invalid_input_test 'H' cr 1
invalid_input_test '0' cr 1
invalid_input_test '1' cr 1
invalid_input_test '2' cr 1
invalid_input_test '3' cr 1
invalid_input_test '4' cr 1
invalid_input_test '5' cr 1
invalid_input_test 'abc' cr 1
invalid_input_test '1abc' cr 1
invalid_input_test 'abc1' cr 1
invalid_input_test 'v4' cr 1
invalid_input_test 'V4' cr 1
invalid_input_test 'v5' cr 1
invalid_input_test 'V5' cr 1
invalid_input_test 'v6' cr 1
invalid_input_test 'V6' cr 1
valid_input_test '' cr
#
valid_input_test '0.0.0.0' ip4addr
valid_input_test '1.1.1.1' ip4addr
valid_input_test '8.8.8.8' ip4addr
valid_input_test '127.0.0.1' ip4addr
valid_input_test '192.168.45.235' ip4addr
valid_input_test '209.51.188.20' ip4addr
valid_input_test '255.255.255.255' ip4addr
invalid_input_test '1.2' ip4addr 1
invalid_input_test '1.2.3' ip4addr 1
invalid_input_test '1.0.0.0.0' ip4addr 1
invalid_input_test '260.168.45.235' ip4addr 1
invalid_input_test '192.999.45.235' ip4addr 1
invalid_input_test '192.168.450.235' ip4addr 1
invalid_input_test '192.168.450.2350' ip4addr 1
invalid_input_test '192.168.-45.235' ip4addr 1
invalid_input_test '192.168.45.' ip4addr 1
invalid_input_test '192.168,45.235' ip4addr 1
invalid_input_test '192.168..235' ip4addr 1
invalid_input_test 'abc' ip4addr 1
invalid_input_test '1abc' ip4addr 1
invalid_input_test 'abc1' ip4addr 1
invalid_input_test '1:2:3:4:5:6:7:8' ip4addr 1
invalid_input_test '1::' ip4addr 1
invalid_input_test '1:2:3:4:5:6:7::' ip4addr 1
invalid_input_test '1::8' ip4addr 1
invalid_input_test '1:2:3:4:5:6::8' ip4addr 1
invalid_input_test '1::7:8' ip4addr 1
invalid_input_test '1:2:3:4:5::7:8' ip4addr 1
invalid_input_test '1:2:3:4:5::8' ip4addr 1
invalid_input_test '1::6:7:8' ip4addr 1
invalid_input_test '1:2:3:4::6:7:8' ip4addr 1
invalid_input_test '1:2:3:4::8' ip4addr 1
invalid_input_test '1::5:6:7:8' ip4addr 1
invalid_input_test '1:2:3::5:6:7:8' ip4addr 1
invalid_input_test '1:2:3::8' ip4addr 1
invalid_input_test '1::3:4:5:6:7:8' ip4addr 1
invalid_input_test '1::3:4:5:6:7:8' ip4addr 1
invalid_input_test '1::8' ip4addr 1
invalid_input_test '::2:3:4:5:6:7:8' ip4addr 1
invalid_input_test '::8' ip4addr 1
invalid_input_test '::' ip4addr 1
invalid_input_test 'fe80::7:8%eth0' ip4addr 1
invalid_input_test 'fe80::7:8%1' ip4addr 1
invalid_input_test '::255.255.255.255' ip4addr 1
invalid_input_test '::ffff:255.255.255.255' ip4addr 1
invalid_input_test '::ffff:0:255.255.255.255' ip4addr 1
invalid_input_test '2001:db8:3:4::192.0.2.33' ip4addr 1
invalid_input_test '64:ff9b::192.0.2.33' ip4addr 1
invalid_input_test '::ffff:10.0.0.1' ip4addr 1
invalid_input_test '::ffff:1.2.3.4' ip4addr 1
invalid_input_test '::ffff:0.0.0.0' ip4addr 1
invalid_input_test '1:2:3:4:5:6:77:88' ip4addr 1
invalid_input_test '::ffff:255.255.255.255' ip4addr 1
invalid_input_test 'fe08::7:8' ip4addr 1
invalid_input_test 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' ip4addr 1
invalid_input_test '1:2:3:4:5:6:7:8:9' ip4addr 1
invalid_input_test '1:2:3:4:5:6::7:8' ip4addr 1
invalid_input_test ':1:2:3:4:5:6:7:8' ip4addr 1
invalid_input_test '1:2:3:4:5:6:7:8:' ip4addr 1
invalid_input_test '::1:2:3:4:5:6:7:8' ip4addr 1
invalid_input_test '1:2:3:4:5:6:7:8::' ip4addr 1
invalid_input_test '1:2:3:4:5:6:7:88888' ip4addr 1
invalid_input_test '2001:db8:3:4:5::192.0.2.33' ip4addr 1
invalid_input_test 'fe08::7:8%' ip4addr 1
invalid_input_test 'fe08::7:8i' ip4addr 1
invalid_input_test 'fe08::7:8interface' ip4addr 1
#
invalid_input_test '0.0.0.0' ip6addr 1
invalid_input_test '1.1.1.1' ip6addr 1
invalid_input_test '8.8.8.8' ip6addr 1
invalid_input_test '127.0.0.1' ip6addr 1
invalid_input_test '192.168.45.235' ip6addr 1
invalid_input_test '209.51.188.20' ip6addr 1
invalid_input_test '255.255.255.255' ip6addr 1
invalid_input_test '1.2' ip6addr 1
invalid_input_test '1.2.3' ip6addr 1
invalid_input_test '1.0.0.0.0' ip6addr 1
invalid_input_test '260.168.45.235' ip6addr 1
invalid_input_test '192.999.45.235' ip6addr 1
invalid_input_test '192.168.450.235' ip6addr 1
invalid_input_test '192.168.450.2350' ip6addr 1
invalid_input_test '192.168.-45.235' ip6addr 1
invalid_input_test '192.168.45.' ip6addr 1
invalid_input_test '192.168,45.235' ip6addr 1
invalid_input_test '192.168..235' ip6addr 1
invalid_input_test 'abc' ip6addr 1
invalid_input_test '1abc' ip6addr 1
invalid_input_test 'abc1' ip6addr 1
valid_input_test '1:2:3:4:5:6:7:8' ip6addr
valid_input_test '1::' ip6addr
valid_input_test '1:2:3:4:5:6:7::' ip6addr
valid_input_test '1::8' ip6addr
valid_input_test '1:2:3:4:5:6::8' ip6addr
valid_input_test '1::7:8' ip6addr
valid_input_test '1:2:3:4:5::7:8' ip6addr
valid_input_test '1:2:3:4:5::8' ip6addr
valid_input_test '1::6:7:8' ip6addr
valid_input_test '1:2:3:4::6:7:8' ip6addr
valid_input_test '1:2:3:4::8' ip6addr
valid_input_test '1::5:6:7:8' ip6addr
valid_input_test '1:2:3::5:6:7:8' ip6addr
valid_input_test '1:2:3::8' ip6addr
valid_input_test '1::3:4:5:6:7:8' ip6addr
valid_input_test '1::3:4:5:6:7:8' ip6addr
valid_input_test '1::8' ip6addr
valid_input_test '::2:3:4:5:6:7:8' ip6addr
valid_input_test '::8' ip6addr
valid_input_test '::' ip6addr
valid_input_test 'fe80::7:8%eth0' ip6addr
valid_input_test 'fe80::7:8%1' ip6addr
valid_input_test '::255.255.255.255' ip6addr
valid_input_test '::ffff:255.255.255.255' ip6addr
valid_input_test '::ffff:0:255.255.255.255' ip6addr
valid_input_test '2001:db8:3:4::192.0.2.33' ip6addr
valid_input_test '64:ff9b::192.0.2.33' ip6addr
valid_input_test '::ffff:10.0.0.1' ip6addr
valid_input_test '::ffff:1.2.3.4' ip6addr
valid_input_test '::ffff:0.0.0.0' ip6addr
valid_input_test '1:2:3:4:5:6:77:88' ip6addr
valid_input_test '::ffff:255.255.255.255' ip6addr
valid_input_test 'fe08::7:8' ip6addr
valid_input_test 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' ip6addr
invalid_input_test '1:2:3:4:5:6:7:8:9' ip6addr 1
invalid_input_test '1:2:3:4:5:6::7:8' ip6addr 1
invalid_input_test ':1:2:3:4:5:6:7:8' ip6addr 1
invalid_input_test '1:2:3:4:5:6:7:8:' ip6addr 1
invalid_input_test '::1:2:3:4:5:6:7:8' ip6addr 1
invalid_input_test '1:2:3:4:5:6:7:8::' ip6addr 1
invalid_input_test '1:2:3:4:5:6:7:88888' ip6addr 1
invalid_input_test '2001:db8:3:4:5::192.0.2.33' ip6addr 1
invalid_input_test 'fe08::7:8%' ip6addr 1
invalid_input_test 'fe08::7:8i' ip6addr 1
invalid_input_test 'fe08::7:8interface' ip6addr 1
#
valid_input_test '0.0.0.0' ipaddr
valid_input_test '1.1.1.1' ipaddr
valid_input_test '8.8.8.8' ipaddr
valid_input_test '127.0.0.1' ipaddr
valid_input_test '192.168.45.235' ipaddr
valid_input_test '209.51.188.20' ipaddr
valid_input_test '255.255.255.255' ipaddr
invalid_input_test '1.2' ipaddr 1
invalid_input_test '1.2.3' ipaddr 1
invalid_input_test '1.0.0.0.0' ipaddr 1
invalid_input_test '260.168.45.235' ipaddr 1
invalid_input_test '192.999.45.235' ipaddr 1
invalid_input_test '192.168.450.235' ipaddr 1
invalid_input_test '192.168.450.2350' ipaddr 1
invalid_input_test '192.168.-45.235' ipaddr 1
invalid_input_test '192.168.45.' ipaddr 1
invalid_input_test '192.168,45.235' ipaddr 1
invalid_input_test '192.168..235' ipaddr 1
invalid_input_test 'abc' ipaddr 1
invalid_input_test '1abc' ipaddr 1
invalid_input_test 'abc1' ipaddr 1
valid_input_test '1:2:3:4:5:6:7:8' ipaddr
valid_input_test '1::' ipaddr
valid_input_test '1:2:3:4:5:6:7::' ipaddr
valid_input_test '1::8' ipaddr
valid_input_test '1:2:3:4:5:6::8' ipaddr
valid_input_test '1::7:8' ipaddr
valid_input_test '1:2:3:4:5::7:8' ipaddr
valid_input_test '1:2:3:4:5::8' ipaddr
valid_input_test '1::6:7:8' ipaddr
valid_input_test '1:2:3:4::6:7:8' ipaddr
valid_input_test '1:2:3:4::8' ipaddr
valid_input_test '1::5:6:7:8' ipaddr
valid_input_test '1:2:3::5:6:7:8' ipaddr
valid_input_test '1:2:3::8' ipaddr
valid_input_test '1::3:4:5:6:7:8' ipaddr
valid_input_test '1::3:4:5:6:7:8' ipaddr
valid_input_test '1::8' ipaddr
valid_input_test '::2:3:4:5:6:7:8' ipaddr
valid_input_test '::8' ipaddr
valid_input_test '::' ipaddr
valid_input_test 'fe80::7:8%eth0' ipaddr
valid_input_test 'fe80::7:8%1' ipaddr
valid_input_test '::255.255.255.255' ipaddr
valid_input_test '::ffff:255.255.255.255' ipaddr
valid_input_test '::ffff:0:255.255.255.255' ipaddr
valid_input_test '2001:db8:3:4::192.0.2.33' ipaddr
valid_input_test '64:ff9b::192.0.2.33' ipaddr
valid_input_test '::ffff:10.0.0.1' ipaddr
valid_input_test '::ffff:1.2.3.4' ipaddr
valid_input_test '::ffff:0.0.0.0' ipaddr
valid_input_test '1:2:3:4:5:6:77:88' ipaddr
valid_input_test '::ffff:255.255.255.255' ipaddr
valid_input_test 'fe08::7:8' ipaddr
valid_input_test 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' ipaddr
invalid_input_test '1:2:3:4:5:6:7:8:9' ipaddr 1
invalid_input_test '1:2:3:4:5:6::7:8' ipaddr 1
invalid_input_test ':1:2:3:4:5:6:7:8' ipaddr 1
invalid_input_test '1:2:3:4:5:6:7:8:' ipaddr 1
invalid_input_test '::1:2:3:4:5:6:7:8' ipaddr 1
invalid_input_test '1:2:3:4:5:6:7:8::' ipaddr 1
invalid_input_test '1:2:3:4:5:6:7:88888' ipaddr 1
invalid_input_test '2001:db8:3:4:5::192.0.2.33' ipaddr 1
invalid_input_test 'fe08::7:8%' ipaddr 1
invalid_input_test 'fe08::7:8i' ipaddr 1
invalid_input_test 'fe08::7:8interface' ipaddr 1
#
valid_input_test '0' port
valid_input_test '1' port
valid_input_test '12' port
valid_input_test '123' port
valid_input_test '1234' port
valid_input_test '12345' port
valid_input_test '23456' port
valid_input_test '34567' port
valid_input_test '45678' port
valid_input_test '56780' port
valid_input_test '65432' port
valid_input_test '65529' port
valid_input_test '65530' port
valid_input_test '65535' port
invalid_input_test '-1' port 1
invalid_input_test '-12' port 1
invalid_input_test '65536' port 1
invalid_input_test '100000' port 1
#
valid_input_test '0' v4prefix
valid_input_test '1' v4prefix
valid_input_test '12' v4prefix
valid_input_test '23' v4prefix
valid_input_test '32' v4prefix
invalid_input_test '-1' v4prefix 1
invalid_input_test '-12' v4prefix 1
invalid_input_test '33' v4prefix 1
invalid_input_test '120' v4prefix 1
#
valid_input_test '0' v6prefix
valid_input_test '1' v6prefix
valid_input_test '12' v6prefix
valid_input_test '23' v6prefix
valid_input_test '32' v6prefix
valid_input_test '64' v6prefix
valid_input_test '100' v6prefix
valid_input_test '127' v6prefix
valid_input_test '128' v6prefix
invalid_input_test '-1' v6prefix 1
invalid_input_test '-12' v6prefix 1
invalid_input_test '-128' v6prefix 1
invalid_input_test '129' v6prefix 1
invalid_input_test '255' v6prefix 1
invalid_input_test '1023' v6prefix 1
#
invalid_input_test '1:2:3:4:5:6:7:8' hostname 1
invalid_input_test "-.~_!$&'()*+,;=:%40:80%2f::::::@example.com" hostname 1
invalid_input_test '-a.b.co' hostname 1
invalid_input_test '☺.damowmow.com' hostname 1
invalid_input_test '✪df.ws' hostname 1
invalid_input_test '-error-.invalid' hostname 1
invalid_input_test '-exampe.com' hostname 1
invalid_input_test '??' hostname 1
invalid_input_test '?' hostname 1
invalid_input_test '..' hostname 1
invalid_input_test '.' hostname 1
invalid_input_test '#' hostname 1
invalid_input_test '##' hostname 1
invalid_input_test '' hostname 7
invalid_input_test 'prep.-ai.mit.edu' hostname 1
invalid_input_test ' should fail' hostname 1
invalid_input_test 'this shouldfail.com' hostname 1
invalid_input_test '➡.ws' hostname 1
invalid_input_test '.www.foo.bar.' hostname 1
invalid_input_test '.www.foo.bar' hostname 1
invalid_input_test 'www.foo.bar.' hostname 1
invalid_input_test 'مثال.إختبار' hostname 1
invalid_input_test '例子.测试' hostname 1
valid_input_test '1234' hostname
valid_input_test '1337.net' hostname
valid_input_test '142.42.1.1' hostname
valid_input_test '1abc' hostname
valid_input_test '223.255.255.254' hostname
valid_input_test '3628126748' hostname
valid_input_test '3com.com' hostname
valid_input_test 'abc1' hostname
valid_input_test 'a.b--c.de' hostname
valid_input_test 'a.b-c.de' hostname
valid_input_test 'abc' hostname
valid_input_test 'a.b-.co' hostname
valid_input_test 'cisco.com' hostname
valid_input_test 'code.google.com' hostname
valid_input_test 'exampe.com' hostname
valid_input_test 'example.com' hostname
valid_input_test 'foo.bar.com' hostname
valid_input_test 'foo.bar' hostname
valid_input_test 'foo.com' hostname
valid_input_test 'j.mp' hostname
valid_input_test 'localhost' hostname
valid_input_test 'pacini.cisco.com' hostname
valid_input_test 'prep.ai.mit.edu' hostname
valid_input_test 'test-host.exampe.com' hostname
valid_input_test 'test' hostname
valid_input_test 'www.example.com' hostname
#
invalid_input_test '1:2:3:4:5:6:77:88' hostoripv4 1
invalid_input_test '1:2:3:4:5:6:7:88888' hostoripv4 1
invalid_input_test '1:2:3:4:5:6:7:8:9' hostoripv4 1
invalid_input_test '::1:2:3:4:5:6:7:8' hostoripv4 1
invalid_input_test ':1:2:3:4:5:6:7:8' hostoripv4 1
invalid_input_test '1:2:3:4:5:6:7:8' hostoripv4 1
invalid_input_test '1:2:3:4:5:6::7:8' hostoripv4 1
invalid_input_test '1:2:3:4:5:6:7:8' hostoripv4 1
invalid_input_test '1:2:3:4:5:6:7:8:' hostoripv4 1
invalid_input_test '1:2:3:4:5:6:7:8::' hostoripv4 1
invalid_input_test '1:2:3:4:5:6:7::' hostoripv4 1
invalid_input_test '1:2:3:4:5:6::8' hostoripv4 1
invalid_input_test '1:2:3:4:5::7:8' hostoripv4 1
invalid_input_test '1:2:3:4:5::8' hostoripv4 1
invalid_input_test '1:2:3:4::6:7:8' hostoripv4 1
invalid_input_test '1:2:3:4::8' hostoripv4 1
invalid_input_test '1:2:3::5:6:7:8' hostoripv4 1
invalid_input_test '1:2:3::8' hostoripv4 1
invalid_input_test '1::3:4:5:6:7:8' hostoripv4 1
invalid_input_test '1::5:6:7:8' hostoripv4 1
invalid_input_test '1::6:7:8' hostoripv4 1
invalid_input_test '1::7:8' hostoripv4 1
invalid_input_test '1::8' hostoripv4 1
invalid_input_test '192.168..235' hostoripv4 1
invalid_input_test '192.168,45.235' hostoripv4 1
invalid_input_test '192.168.-45.235' hostoripv4 1
invalid_input_test '192.168.45.' hostoripv4 1
invalid_input_test '1::' hostoripv4 1
invalid_input_test '2001:db8:3:4::192.0.2.33' hostoripv4 1
invalid_input_test '2001:db8:3:4:5::192.0.2.33' hostoripv4 1
invalid_input_test '::2:3:4:5:6:7:8' hostoripv4 1
invalid_input_test '::255.255.255.255' hostoripv4 1
invalid_input_test "-.~_!$&'()*+,;=:%40:80%2f::::::@example.com" hostoripv4 1
invalid_input_test '64:ff9b::192.0.2.33' hostoripv4 1
invalid_input_test '::8' hostoripv4 1
invalid_input_test '-a.b.co' hostoripv4 1
invalid_input_test '☺.damowmow.com' hostoripv4 1
invalid_input_test '✪df.ws' hostoripv4 1
invalid_input_test '-error-.invalid' hostoripv4 1
invalid_input_test '-exampe.com' hostoripv4 1
invalid_input_test '-exampe.com' hostoripv4 1
invalid_input_test 'fe08::7:8' hostoripv4 1
invalid_input_test 'fe08::7:8%' hostoripv4 1
invalid_input_test 'fe08::7:8i' hostoripv4 1
invalid_input_test 'fe08::7:8interface' hostoripv4 1
invalid_input_test 'fe80::7:8%1' hostoripv4 1
invalid_input_test 'fe80::7:8%eth0' hostoripv4 1
invalid_input_test '::ffff:0.0.0.0' hostoripv4 1
invalid_input_test '::ffff:0:255.255.255.255' hostoripv4 1
invalid_input_test '::ffff:10.0.0.1' hostoripv4 1
invalid_input_test '::ffff:1.2.3.4' hostoripv4 1
invalid_input_test '::ffff:255.255.255.255' hostoripv4 1
invalid_input_test 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' hostoripv4 1
invalid_input_test '::' hostoripv4 1
invalid_input_test '??' hostoripv4 1
invalid_input_test '?' hostoripv4 1
invalid_input_test '..' hostoripv4 1
invalid_input_test '.' hostoripv4 1
invalid_input_test '#' hostoripv4 1
invalid_input_test '##' hostoripv4 1
invalid_input_test '' hostoripv4 7
invalid_input_test 'prep.-ai.mit.edu' hostoripv4 1
invalid_input_test 'prep.-ai.mit.edu' hostoripv4 1
invalid_input_test ' should fail' hostoripv4 1
invalid_input_test 'this shouldfail.com' hostoripv4 1
invalid_input_test '➡.ws' hostoripv4 1
invalid_input_test '.www.foo.bar.' hostoripv4 1
invalid_input_test '.www.foo.bar' hostoripv4 1
invalid_input_test 'www.foo.bar.' hostoripv4 1
invalid_input_test 'مثال.إختبار' hostoripv4 1
invalid_input_test '例子.测试' hostoripv4 1
valid_input_test '0.0.0.0' hostoripv4
valid_input_test '1.0.0.0.0' hostoripv4
valid_input_test '1.1.1.1' hostoripv4
valid_input_test '1234' hostoripv4
valid_input_test '1.2.3' hostoripv4
valid_input_test '127.0.0.1' hostoripv4
valid_input_test '1.2' hostoripv4
valid_input_test '1337.net' hostoripv4
valid_input_test '142.42.1.1' hostoripv4
valid_input_test '192.168.450.2350' hostoripv4
valid_input_test '192.168.450.235' hostoripv4
valid_input_test '192.168.45.235' hostoripv4
valid_input_test '192.999.45.235' hostoripv4
valid_input_test '1abc' hostoripv4
valid_input_test '1abc' hostoripv4
valid_input_test '209.51.188.20' hostoripv4
valid_input_test '223.255.255.254' hostoripv4
valid_input_test '255.255.255.255' hostoripv4
valid_input_test '260.168.45.235' hostoripv4
valid_input_test '3628126748' hostoripv4
valid_input_test '3com.com' hostoripv4
valid_input_test '3com.com' hostoripv4
valid_input_test '8.8.8.8' hostoripv4
valid_input_test 'abc1' hostoripv4
valid_input_test 'abc1' hostoripv4
valid_input_test 'a.b--c.de' hostoripv4
valid_input_test 'a.b-c.de' hostoripv4
valid_input_test 'abc' hostoripv4
valid_input_test 'abc' hostoripv4
valid_input_test 'a.b-.co' hostoripv4
valid_input_test 'cisco.com' hostoripv4
valid_input_test 'cisco.com' hostoripv4
valid_input_test 'code.google.com' hostoripv4
valid_input_test 'exampe.com' hostoripv4
valid_input_test 'exampe.com' hostoripv4
valid_input_test 'example.com' hostoripv4
valid_input_test 'foo.bar.com' hostoripv4
valid_input_test 'foo.bar' hostoripv4
valid_input_test 'foo.com' hostoripv4
valid_input_test 'j.mp' hostoripv4
valid_input_test 'localhost' hostoripv4
valid_input_test 'localhost' hostoripv4
valid_input_test 'pacini.cisco.com' hostoripv4
valid_input_test 'pacini.cisco.com' hostoripv4
valid_input_test 'prep.ai.mit.edu' hostoripv4
valid_input_test 'prep.ai.mit.edu' hostoripv4
valid_input_test 'test-host.exampe.com' hostoripv4
valid_input_test 'test-host.exampe.com' hostoripv4
valid_input_test 'test' hostoripv4
valid_input_test 'www.example.com' hostoripv4
#
invalid_input_test '1:2:3:4:5:6:7:88888' hostorip 1
invalid_input_test '1:2:3:4:5:6:7:8:9' hostorip 1
invalid_input_test '::1:2:3:4:5:6:7:8' hostorip 1
invalid_input_test ':1:2:3:4:5:6:7:8' hostorip 1
invalid_input_test '1:2:3:4:5:6::7:8' hostorip 1
invalid_input_test '1:2:3:4:5:6:7:8:' hostorip 1
invalid_input_test '1:2:3:4:5:6:7:8::' hostorip 1
invalid_input_test '192.168..235' hostorip 1
invalid_input_test '192.168,45.235' hostorip 1
invalid_input_test '192.168.-45.235' hostorip 1
invalid_input_test '192.168.45.' hostorip 1
invalid_input_test '2001:db8:3:4:5::192.0.2.33' hostorip 1
invalid_input_test "-.~_!$&'()*+,;=:%40:80%2f::::::@example.com" hostorip 1
invalid_input_test '-a.b.co' hostorip 1
invalid_input_test '☺.damowmow.com' hostorip 1
invalid_input_test '✪df.ws' hostorip 1
invalid_input_test '-error-.invalid' hostorip 1
invalid_input_test '-exampe.com' hostorip 1
invalid_input_test '-exampe.com' hostorip 1
invalid_input_test 'fe08::7:8%' hostorip 1
invalid_input_test 'fe08::7:8i' hostorip 1
invalid_input_test 'fe08::7:8interface' hostorip 1
invalid_input_test '??' hostorip 1
invalid_input_test '?' hostorip 1
invalid_input_test '..' hostorip 1
invalid_input_test '.' hostorip 1
invalid_input_test '#' hostorip 1
invalid_input_test '##' hostorip 1
invalid_input_test '' hostorip 7
invalid_input_test 'prep.-ai.mit.edu' hostorip 1
invalid_input_test 'prep.-ai.mit.edu' hostorip 1
invalid_input_test ' should fail' hostorip 1
invalid_input_test 'this shouldfail.com' hostorip 1
invalid_input_test '➡.ws' hostorip 1
invalid_input_test '.www.foo.bar.' hostorip 1
invalid_input_test '.www.foo.bar' hostorip 1
invalid_input_test 'www.foo.bar.' hostorip 1
invalid_input_test 'مثال.إختبار' hostorip 1
invalid_input_test '例子.测试' hostorip 1
valid_input_test '0.0.0.0' hostorip
valid_input_test '1.0.0.0.0' hostorip
valid_input_test '1.1.1.1' hostorip
valid_input_test '1:2:3:4:5:6:77:88' hostorip
valid_input_test '1:2:3:4:5:6:7:8' hostorip
valid_input_test '1:2:3:4:5:6:7:8' hostorip
valid_input_test '1:2:3:4:5:6:7::' hostorip
valid_input_test '1:2:3:4:5:6::8' hostorip
valid_input_test '1:2:3:4:5::7:8' hostorip
valid_input_test '1:2:3:4:5::8' hostorip
valid_input_test '1:2:3:4::6:7:8' hostorip
valid_input_test '1:2:3:4::8' hostorip
valid_input_test '1234' hostorip
valid_input_test '1:2:3::5:6:7:8' hostorip
valid_input_test '1:2:3::8' hostorip
valid_input_test '1.2.3' hostorip
valid_input_test '127.0.0.1' hostorip
valid_input_test '1.2' hostorip
valid_input_test '1337.net' hostorip
valid_input_test '1::3:4:5:6:7:8' hostorip
valid_input_test '142.42.1.1' hostorip
valid_input_test '1::5:6:7:8' hostorip
valid_input_test '1::6:7:8' hostorip
valid_input_test '1::7:8' hostorip
valid_input_test '1::8' hostorip
valid_input_test '192.168.450.2350' hostorip
valid_input_test '192.168.450.235' hostorip
valid_input_test '192.168.45.235' hostorip
valid_input_test '192.999.45.235' hostorip
valid_input_test '1abc' hostorip
valid_input_test '1abc' hostorip
valid_input_test '1::' hostorip
valid_input_test '2001:db8:3:4::192.0.2.33' hostorip
valid_input_test '209.51.188.20' hostorip
valid_input_test '223.255.255.254' hostorip
valid_input_test '::2:3:4:5:6:7:8' hostorip
valid_input_test '::255.255.255.255' hostorip
valid_input_test '255.255.255.255' hostorip
valid_input_test '260.168.45.235' hostorip
valid_input_test '3628126748' hostorip
valid_input_test '3com.com' hostorip
valid_input_test '3com.com' hostorip
valid_input_test '64:ff9b::192.0.2.33' hostorip
valid_input_test '8.8.8.8' hostorip
valid_input_test '::8' hostorip
valid_input_test 'abc1' hostorip
valid_input_test 'abc1' hostorip
valid_input_test 'a.b--c.de' hostorip
valid_input_test 'a.b-c.de' hostorip
valid_input_test 'abc' hostorip
valid_input_test 'abc' hostorip
valid_input_test 'a.b-.co' hostorip
valid_input_test 'cisco.com' hostorip
valid_input_test 'cisco.com' hostorip
valid_input_test 'code.google.com' hostorip
valid_input_test 'exampe.com' hostorip
valid_input_test 'exampe.com' hostorip
valid_input_test 'example.com' hostorip
valid_input_test 'fe08::7:8' hostorip
valid_input_test 'fe80::7:8%1' hostorip
valid_input_test 'fe80::7:8%eth0' hostorip
valid_input_test '::ffff:0.0.0.0' hostorip
valid_input_test '::ffff:0:255.255.255.255' hostorip
valid_input_test '::ffff:10.0.0.1' hostorip
valid_input_test '::ffff:1.2.3.4' hostorip
valid_input_test '::ffff:255.255.255.255' hostorip
valid_input_test 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff' hostorip
valid_input_test 'foo.bar.com' hostorip
valid_input_test 'foo.bar' hostorip
valid_input_test 'foo.com' hostorip
valid_input_test '::' hostorip
valid_input_test 'j.mp' hostorip
valid_input_test 'localhost' hostorip
valid_input_test 'localhost' hostorip
valid_input_test 'pacini.cisco.com' hostorip
valid_input_test 'pacini.cisco.com' hostorip
valid_input_test 'prep.ai.mit.edu' hostorip
valid_input_test 'prep.ai.mit.edu' hostorip
valid_input_test 'test-host.exampe.com' hostorip
valid_input_test 'test-host.exampe.com' hostorip
valid_input_test 'test' hostorip
valid_input_test 'www.example.com' hostorip
#
valid_input_test 'eth0' interface
valid_input_test 'eth1' interface
valid_input_test 'eth2' interface
valid_input_test 'eth9' interface
valid_input_test 'etha' interface
valid_input_test 'ethz' interface
invalid_input_test 'eth10' interface 1
invalid_input_test 'ether' interface 1
invalid_input_test 'ext0' interface 1
invalid_input_test 'eth-1' interface 1
invalid_input_test 'eth' interface 1
invalid_input_test 'eth.' interface 1
invalid_input_test 'eth?' interface 1
invalid_input_test 'eth*' interface 1
#
valid_input_test 'a' sane_filename
valid_input_test 'abc' sane_filename
valid_input_test '1abc' sane_filename
valid_input_test 'abc1' sane_filename
valid_input_test 'curds_n_whey.txt' sane_filename
valid_input_test 'a.b.c' sane_filename
invalid_input_test "foo\$bar" sane_filename 1
invalid_input_test '~root' sane_filename 1
invalid_input_test 'foo bar' sane_filename 1
invalid_input_test 'foo*bar' sane_filename 1
invalid_input_test 'foo?bar' sane_filename 1
invalid_input_test 'foo:bar' sane_filename 1
invalid_input_test '!foobar' sane_filename 1
invalid_input_test '*foo' sane_filename 1
invalid_input_test '*' sane_filename 1
invalid_input_test '?foo' sane_filename 1
invalid_input_test '*' sane_filename 1
invalid_input_test '-a.b.c' sane_filename 1
invalid_input_test '+a.b.c' sane_filename 1
invalid_input_test '.hide' sane_filename 1
invalid_input_test '/a.b.c' sane_filename 1
invalid_input_test '/a/b/c' sane_filename 1
invalid_input_test '/a/b/c/' sane_filename 1
invalid_input_test 'a/b/c' sane_filename 1
invalid_input_test 'a/b/c/' sane_filename 1
invalid_input_test './a/b/c' sane_filename 1
invalid_input_test './a/b/c/' sane_filename 1
invalid_input_test '/' sane_filename 1
invalid_input_test './' sane_filename 1
invalid_input_test '../' sane_filename 1
invalid_input_test '../../foo' sane_filename 1
invalid_input_test '.' sane_filename 1
invalid_input_test '..' sane_filename 1
#
valid_input_test 'a' insane_filename
valid_input_test 'abc' insane_filename
valid_input_test '1abc' insane_filename
valid_input_test 'abc1' insane_filename
valid_input_test 'curds_n_whey.txt' insane_filename
valid_input_test 'a.b.c' insane_filename
valid_input_test "foo\$bar" insane_filename
valid_input_test '~root' insane_filename
valid_input_test 'foo bar' insane_filename
valid_input_test 'foo*bar' insane_filename
valid_input_test 'foo?bar' insane_filename
valid_input_test 'foo:bar' insane_filename
valid_input_test '!foobar' insane_filename
valid_input_test '*foo' insane_filename
valid_input_test '*' insane_filename
valid_input_test '?foo' insane_filename
valid_input_test '*' insane_filename
valid_input_test '-a.b.c' insane_filename
valid_input_test '+a.b.c' insane_filename
valid_input_test '.hide' insane_filename
invalid_input_test '/a.b.c' insane_filename 1
invalid_input_test '/a/b/c' insane_filename 1
invalid_input_test '/a/b/c/' insane_filename 1
invalid_input_test 'a/b/c' insane_filename 1
invalid_input_test 'a/b/c/' insane_filename 1
invalid_input_test './a/b/c' insane_filename 1
invalid_input_test './a/b/c/' insane_filename 1
invalid_input_test '/' insane_filename 1
invalid_input_test './' insane_filename 1
invalid_input_test '../' insane_filename 1
invalid_input_test '../../foo' insane_filename 1
valid_input_test '.' insane_filename
valid_input_test '..' insane_filename
#
valid_input_test 'a' sane_path
valid_input_test 'abc' sane_path
valid_input_test '1abc' sane_path
valid_input_test 'abc1' sane_path
valid_input_test 'curds_n_whey.txt' sane_path
valid_input_test 'a.b.c' sane_path
invalid_input_test "foo\$bar" sane_path 1
invalid_input_test '~root' sane_path 1
invalid_input_test 'foo bar' sane_path 1
invalid_input_test 'foo*bar' sane_path 1
invalid_input_test 'foo?bar' sane_path 1
invalid_input_test 'foo:bar' sane_path 1
invalid_input_test '!foobar' sane_path 1
invalid_input_test '*foo' sane_path 1
invalid_input_test '*' sane_path 1
invalid_input_test '?foo' sane_path 1
invalid_input_test '*' sane_path 1
invalid_input_test '-a.b.c' sane_path 1
invalid_input_test '+a.b.c' sane_path 1
invalid_input_test '.hide' sane_path 1
valid_input_test '/a.b.c' sane_path
valid_input_test '/a/b/c' sane_path
valid_input_test '/a/b/c/' sane_path
valid_input_test 'a/b/c' sane_path
valid_input_test 'a/b/c/' sane_path
valid_input_test './a/b/c' sane_path
valid_input_test './a/b/c/' sane_path
invalid_input_test '/' sane_path 1
valid_input_test './' sane_path
invalid_input_test '../' sane_path 1
invalid_input_test '../../foo' sane_path 1
invalid_input_test '.' sane_path 1
invalid_input_test '..' sane_path 1
#
valid_input_test 'a' insane_path
valid_input_test 'abc' insane_path
valid_input_test '1abc' insane_path
valid_input_test 'abc1' insane_path
valid_input_test 'curds_n_whey.txt' insane_path
valid_input_test 'a.b.c' insane_path
valid_input_test "foo\$bar" insane_path
valid_input_test '~root' insane_path
valid_input_test 'foo bar' insane_path
valid_input_test 'foo*bar' insane_path
valid_input_test 'foo?bar' insane_path
valid_input_test 'foo:bar' insane_path
valid_input_test '!foobar' insane_path
valid_input_test '*foo' insane_path
valid_input_test '*' insane_path
valid_input_test '?foo' insane_path
valid_input_test '*' insane_path
valid_input_test '-a.b.c' insane_path
valid_input_test '+a.b.c' insane_path
valid_input_test '.hide' insane_path
valid_input_test '/a.b.c' insane_path
valid_input_test '/a/b/c' insane_path
valid_input_test '/a/b/c/' insane_path
valid_input_test 'a/b/c' insane_path
valid_input_test 'a/b/c/' insane_path
valid_input_test './a/b/c' insane_path
valid_input_test './a/b/c/' insane_path
valid_input_test '/' insane_path
valid_input_test './' insane_path
valid_input_test '../' insane_path
valid_input_test '../../foo' insane_path
valid_input_test '.' insane_path
valid_input_test '..' insane_path
#
valid_input_test 'a' sane_username
valid_input_test 'chongo' sane_username
valid_input_test 'user123' sane_username
valid_input_test 'user-123' sane_username
valid_input_test 'user_123' sane_username
valid_input_test 'user.123' sane_username
valid_input_test 'user123.' sane_username
valid_input_test 'user123_' sane_username
valid_input_test 'user123-' sane_username
valid_input_test 'abcdefghijklmnopqrstuvwxyz' sane_username
valid_input_test 'abcdefghijklmnopqrstuvwxyz012345' sane_username
invalid_input_test 'abcdefghijklmnopqrstuvwxyz0123456' sane_username 1
invalid_input_test '55' sane_username 1
invalid_input_test '-root' sane_username 1
invalid_input_test '_user-user' sane_username 1
#
valid_input_test 'a' sane_password
valid_input_test 'chongo' sane_password
valid_input_test 'user123' sane_password
valid_input_test 'user-123' sane_password
valid_input_test 'user_123' sane_password
valid_input_test 'user.123' sane_password
valid_input_test 'user123.' sane_password
valid_input_test 'user123_' sane_password
valid_input_test 'user123-' sane_password
valid_input_test 'abcdefghijklmnopqrstuvwxyz' sane_password
valid_input_test 'abcdefghijklmnopqrstuvwxyz012345' sane_password
invalid_input_test 'abcdefghijklmnopqrstuvwxyz0123456' sane_password 1
valid_input_test '55' sane_password
valid_input_test '-root' sane_password
valid_input_test '_user-user' sane_password
invalid_input_test 'pass:word' sane_password 1
invalid_input_test 'pass/word' sane_password 1
invalid_input_test 'pass@word' sane_password 1
invalid_input_test 'pass#word' sane_password 1
invalid_input_test 'password?' sane_password 1
invalid_input_test '_user%user' sane_password 1
#
valid_input_test 'http://foo.com' sane_url
valid_input_test 'http://142.42.1.1' sane_url
valid_input_test 'http://[1:2:3:4:5:6:7:8]' sane_url
invalid_input_test 'http://✪df.ws' sane_url 1
valid_input_test 'http://foo.com:8080' sane_url
valid_input_test 'http://142.42.1.1:8080' sane_url
valid_input_test 'http://[1:2:3:4:5:6:7:8]:8080' sane_url
valid_input_test 'http://foo.com/blah_blah' sane_url
valid_input_test 'http://foo.com/blah/blah' sane_url
valid_input_test 'http://142.42.1.1/blah_blah' sane_url
valid_input_test 'http://142.42.1.1/blah/blah' sane_url
valid_input_test 'http://[1:2:3:4:5:6:7:8]/blah_blah' sane_url
valid_input_test 'http://[1:2:3:4:5:6:7:8]/blah/blah' sane_url
valid_input_test 'http://142.42.1.1:23209/blah/blah' sane_url
valid_input_test 'http://foo.com:23209/blah/blah' sane_url
invalid_input_test 'http://✪df.ws/123' sane_url 1
valid_input_test 'http://[1:2:3:4:5:6:7:8]:23209/blah/blah' sane_url
valid_input_test 'http://foo.bar.com/blah_blah/' sane_url
valid_input_test 'http://foo.bar.com/blah/blah/' sane_url
valid_input_test 'http://foo.com/blah_blah_(wikipedia)' sane_url
valid_input_test 'http://foo.com/blah_blah_(wikipedia)_(again)' sane_url
valid_input_test 'http://www.example.com/wpstyle/?p=364' sane_url
valid_input_test 'https://www.example.com/foo/?bar=baz&inga=42&quux' sane_url
valid_input_test 'http://userid@example.com' sane_url
valid_input_test 'http://userid@example.com/' sane_url
valid_input_test 'http://userid@example.com/foo' sane_url
valid_input_test 'http://userid@example.com/foo/' sane_url
valid_input_test 'http://userid@example.com/foo/blah?p=fizzbin' sane_url
valid_input_test 'http://userid@example.com:23209/foo' sane_url
valid_input_test 'http://userid:password@example.com' sane_url
valid_input_test 'http://userid:password@example.com/' sane_url
valid_input_test 'http://userid:password@example.com/path' sane_url
valid_input_test 'http://userid:password@example.com:8080' sane_url
valid_input_test 'http://userid:password@example.com:8080/' sane_url
valid_input_test 'http://userid@example.com/' sane_url
valid_input_test 'http://userid@example.com/path' sane_url
valid_input_test 'http://userid@example.com:8080' sane_url
valid_input_test 'http://userid@example.com:8080/' sane_url
valid_input_test 'http://userid@example.com:8080/path' sane_url
invalid_input_test 'http://➡.ws/䨹' sane_url 1
invalid_input_test 'http://⌘.ws' sane_url 1
invalid_input_test 'http://⌘.ws/' sane_url 1
valid_input_test 'http://foo.com/blah_(wikipedia)#cite-1' sane_url
valid_input_test 'http://foo.com/blah_(wikipedia)_blah#cite-1' sane_url
valid_input_test 'http://foo.com/unicode_(✪)_in_parens' sane_url
valid_input_test 'http://foo.com/(something)?after=parens' sane_url
invalid_input_test 'http://☺.damowmow.com/' sane_url 1
valid_input_test 'http://code.google.com/events/#&product=browser' sane_url
valid_input_test 'http://j.mp' sane_url
valid_input_test 'ftp://foo.bar/baz' sane_url
valid_input_test 'http://foo.bar/?q=Test%20URL-encoded%20stuff' sane_url
invalid_input_test 'http://مثال.إختبار' sane_url 1
invalid_input_test 'http://例子.测试' sane_url 1
invalid_input_test "http://-.~_!$&'()*+,;=:%40:80%2f::::::@example.com" sane_url 1
valid_input_test 'http://1337.net' sane_url
valid_input_test 'http://a.b-c.de' sane_url
valid_input_test 'http://223.255.255.254' sane_url
invalid_input_test 'http://' sane_url 1
invalid_input_test 'http://.' sane_url 1
invalid_input_test 'http://..' sane_url 1
invalid_input_test 'http://../' sane_url 1
invalid_input_test 'http://?' sane_url 1
invalid_input_test 'http://??' sane_url 1
invalid_input_test 'http://??/' sane_url 1
invalid_input_test 'http://#' sane_url 1
invalid_input_test 'http://##' sane_url 1
invalid_input_test 'http://##/' sane_url 1
invalid_input_test 'http://foo.bar?q=Spaces should be encoded' sane_url 1
invalid_input_test '//' sane_url 1
invalid_input_test '//a' sane_url 1
invalid_input_test '///a' sane_url 1
invalid_input_test '///' sane_url 1
invalid_input_test 'http:///a' sane_url 1
invalid_input_test 'foo.com' sane_url 1
valid_input_test 'rdar://1234' sane_url
valid_input_test 'h://test' sane_url
invalid_input_test 'http:// shouldfail.com' sane_url 1
invalid_input_test ':// should fail' sane_url 1
invalid_input_test 'http://foo.bar/foo(bar)baz quux' sane_url 1
valid_input_test 'ftp://foo.bar/' sane_url
invalid_input_test 'http://-error-.invalid/' sane_url 1
valid_input_test 'http://a.b--c.de/' sane_url
invalid_input_test 'http://-a.b.co' sane_url 1
valid_input_test 'http://a.b-.co' sane_url
valid_input_test 'http://3628126748' sane_url
invalid_input_test 'http://.www.foo.bar/' sane_url 1
invalid_input_test 'http://www.foo.bar./' sane_url 1
invalid_input_test 'http://.www.foo.bar./' sane_url 1
#
valid_input_test 'file' trans_mode_0
valid_input_test 'http' trans_mode_0
valid_input_test 'https' trans_mode_0
valid_input_test 'ftp' trans_mode_0
invalid_input_test 'scp' trans_mode_0 1
invalid_input_test 'sftp' trans_mode_0 1
valid_input_test 'File' trans_mode_0
valid_input_test 'Http' trans_mode_0
valid_input_test 'Https' trans_mode_0
valid_input_test 'Ftp' trans_mode_0
invalid_input_test 'Scp' trans_mode_0 1
invalid_input_test 'Sftp' trans_mode_0 1
valid_input_test 'FILE' trans_mode_0
valid_input_test 'HTTP' trans_mode_0
valid_input_test 'HTTPS' trans_mode_0
valid_input_test 'FTP' trans_mode_0
invalid_input_test 'SCP' trans_mode_0 1
invalid_input_test 'SFTP' trans_mode_0 1
invalid_input_test '' trans_mode_0 7
invalid_input_test 'filer' trans_mode_0 1
invalid_input_test 'httpr' trans_mode_0 1
invalid_input_test 'httpsr' trans_mode_0 1
invalid_input_test 'ftpr' trans_mode_0 1
invalid_input_test 'FIle' trans_mode_0 1
invalid_input_test 'HTtp' trans_mode_0 1
invalid_input_test 'HTtps' trans_mode_0 1
invalid_input_test 'FTp' trans_mode_0 1
invalid_input_test '123' trans_mode_0 1
invalid_input_test '+' trans_mode_0 1
#
invalid_input_test 'file' trans_mode_1 1
invalid_input_test 'http' trans_mode_1 1
invalid_input_test 'https' trans_mode_1 1
valid_input_test 'ftp' trans_mode_1
valid_input_test 'scp' trans_mode_1
valid_input_test 'sftp' trans_mode_1
invalid_input_test 'File' trans_mode_1 1
invalid_input_test 'Http' trans_mode_1 1
invalid_input_test 'Https' trans_mode_1 1
valid_input_test 'Ftp' trans_mode_1
valid_input_test 'Scp' trans_mode_1
valid_input_test 'Sftp' trans_mode_1
invalid_input_test 'FILE' trans_mode_1 1
invalid_input_test 'HTTP' trans_mode_1 1
invalid_input_test 'HTTPS' trans_mode_1 1
valid_input_test 'FTP' trans_mode_1
valid_input_test 'SCP' trans_mode_1
valid_input_test 'SFTP' trans_mode_1
invalid_input_test '' trans_mode_1 7
invalid_input_test 'filer' trans_mode_1 1
invalid_input_test 'httpr' trans_mode_1 1
invalid_input_test 'httpsr' trans_mode_1 1
invalid_input_test 'ftpr' trans_mode_1 1
invalid_input_test 'FIle' trans_mode_1 1
invalid_input_test 'HTtp' trans_mode_1 1
invalid_input_test 'HTtps' trans_mode_1 1
invalid_input_test 'FTp' trans_mode_1 1
invalid_input_test '123' trans_mode_1 1
invalid_input_test '+' trans_mode_1 1

# All Done!!! -- Jessica Noll, Age 2
#
exit 0
