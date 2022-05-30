# randstring
Command line utility and library for generating pseudo-random strings.

This is written in the D programming language. To compile it go get a Dlang compiler from dlang.org and then use:

One of these for the command-line utility:
- `dmd rs.d`
- `ldc2 rs.d`
- `gdc ./rs.d -o rs`

Or one of these for the library:
- `dmd rs.d -lib`
- `ldc2 rs.d -lib`
- `gdc rs.d -shared -fPIC`

The command-line utility will check the provided arguments for validity and will sometimes infer values for options that are not provided by the user.

Command-line examples:
- `rs --length 15 --minlower 4 --maxwhitespace 0` //generate a 15-character long string with at least 4 lowercase letters and no whitespace.
- `rs --minwhitespace 10` //generate a string of 10 whitespace characters. (string length defaults to 10 characters.)
