# vread

Read from stdin and validate the input.


# To install

```sh
make test
sudo make install
```


# Examples

```
REMOTE_URL=$(./vread -e -o sane_url 'Enter the URL of the remote server')
status="$?"
if [[ $status -ne 0 || -z $REMOTE_URL ]]; then
# ... error processing or exit
fi

HOST_NAME=$(./vread -e hostname 'Enter the hostname:' 'Invalid syntax for a hostname')
status="$?"
if [[ $status -ne 0 || -z $HOST_NAME ]]; then
# ... error processing or exit
fi

PASSWORD=$(./vread -s -r 'Confirm password:' sane_password 'Enter password:' 'Invalid password or input did not match')
status="$?"
if [[ $status -ne 0 || -z $PASSWORD ]]; then
# ... error processing or exit
fi
```


# Usage

```
/usr/local/bin/vread [-h] [-v] [-V] [-b] [-c] [-o] [-e] [-r repeat_prompt] [-s] [-m maxlen] [-t timeout] type prompt [errmsg]

    -h			Output usage message and exit 3
    -v			Verbose mode for debugging
    -V			print verison and exit

    -b			Do not print a blank after the promt (def: print a space after prompt and repeat_prompt)
    -c			Canonicalize the result
    -o			Prompt once, exit 1 if invalid input
    -e			Enable READLINE editing mode

    -r repeat_prompt	Prompt to issue to verify entry (def: do ask again)
    -s			Silent mode (useful for password entry) (def: echo characters)

    -m maxlen		Maximum chars for input (def: 4096)
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

    1	invalid input and -o given
    2	interrupt

    3	usage or command line error
    4	input was too long
    5	timeout on input and -t timeout given
    6	used -r repeat_prompt and 2nd input did not match
    7	empty input line and not cr type
    8	some other read error occurred

Version: 4.7.1 2025-03-23
```


# Reporting Security Issues

To report a security issue, please visit "[Reporting Security Issues](https://github.com/lcn2/vread/security/policy)".
