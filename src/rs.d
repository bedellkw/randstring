/++
++ This application is for generating pseudo-random strings. It can be compiled as a console application or a library.
TODO:
++   Add support for non-ascii unicode characters - maybe
++   Use a reputable cryptographic library for PRNG
++   Consider making this betterC-compatible
++   Improve unittesting
++/

module rs;

/+
    This application is for generating random strings.
+/

enum specialChars = "!@#$%^&*()[]'`\",.<>{};:-=+_"d;
enum helpText = `Generates a random string.`;

//this is used to improve maintainability
string PopulateTypeString(string l, string u)
{
    return
    "for(size_t i = 0; i < min" ~ u ~ "; ++i)" ~
    "{
        s = openSlots.choice();" ~
        "generated[s] = " ~ l ~ ".choice();" ~
        "openSlotsIndex = openSlots.countUntil(s);" ~
        "openSlots =
            openSlots.length == 1 ? [] :
            openSlots.length == 2 && openSlotsIndex == 0 ? [openSlots[1]] :
            openSlots.length == 2 && openSlotsIndex == 1 ? [openSlots[0]] :
            openSlotsIndex == 0 ? openSlots [1 .. $] :
            openSlotsIndex == openSlots.length - 1 ? openSlots[0 .. $ - 1] :
            openSlots[0 .. openSlotsIndex] ~ openSlots[openSlotsIndex + 1 .. $];" ~
    "}";
}

/++
+  This function validates the options passed to it and sets unset (== -1) options based on the other options are are provided.+
+
+  Returns:
+  A string with zero length when no errors are encountered. Otherwise returns an error message.
++/
//check that options are valid:
string validateOptions
(
    ref long stringLength,
    ref long minAlpha,
    ref long maxAlpha,
    ref long minLower,
    ref long maxLower,
    ref long minUpper,
    ref long maxUpper,
    ref long minNumeric,
    ref long maxNumeric,
    ref long minSpecial,
    ref long maxSpecial,
    ref long minWhitespace,
    ref long maxWhitespace
)
{
    if (maxAlpha != -1 && (minLower > -1 ? minLower : 0) + (minUpper > -1 ? minUpper : 0) > maxAlpha)
    {
        return "Invalid alphabetic character options detected.";
    }

    //normalize min/max alpha with min/max upper and lower values
    //minAlpha
    if (minAlpha != -1 && (minLower > -1 ? minLower : 0) + (minUpper > -1 ? minUpper : 0) > minAlpha)
    {
        minAlpha = minLower + minUpper;
    }

    if (maxAlpha != -1 && (maxLower > -1 ? maxLower : 0) + (maxUpper > -1 ? maxUpper : 0) > maxAlpha)
    {
        return "Invalid alphabetic character options detected.";
    }

    //maxAlpha
    if (maxAlpha == -1)
    {
        if (maxLower > 0 && maxUpper > 0)
        {
            maxAlpha = maxLower + maxUpper;
        }
        else if (maxLower > 0)
        {
            maxAlpha = maxLower;
        }
        else if (maxUpper > 0)
        {
            maxAlpha = maxUpper;
        }
    }

    //set string length or check validity if it is set by user
    if (stringLength == -1)
    {
        stringLength = (minAlpha > -1 ? minAlpha : 0) +
                        (minNumeric > -1 ? minNumeric : 0) +
                        (minSpecial > -1 ? minSpecial : 0) +
                        (minWhitespace > -1 ? minWhitespace : 0);

        stringLength = stringLength >= 10 ? stringLength : 10;
    }
    else
    {
        if
        (
            (minAlpha > -1 ? minAlpha : 0) +
            (minNumeric > -1 ? minNumeric : 0) +
            (minSpecial > -1 ? minSpecial : 0) +
            (minWhitespace > -1 ? minWhitespace : 0)
                >
            stringLength
        )
        {
            return "Invalid length and minimum combinations.";
        }
    }

    //set unset maximum values to stringLength
    static foreach(s; ["maxAlpha", "maxLower", "maxUpper", "maxNumeric", "maxWhitespace", "maxSpecial"])
    {
        mixin("if (" ~ s ~ " == -1) {" ~ s ~ " = stringLength;}");
    }

    if
    (
        minLower > maxLower ||
        minUpper > maxUpper ||
        minAlpha > maxAlpha ||
        minWhitespace > maxWhitespace ||
        minSpecial > maxSpecial ||
        minNumeric > maxNumeric
    )
    {
        return "Invalid length and minimum combinations.";
    }

    return "";
}

///This is the function that actually generates the string. It does not do much input validation.
dstring randString
(
    long stringLength,
    long minAlpha,
    long maxAlpha,
    long minLower,
    long maxLower,
    long minUpper,
    long maxUpper,
    long minNumeric,
    long maxNumeric,
    long minSpecial,
    long maxSpecial,
    long minWhitespace,
    long maxWhitespace,
    dstring charPool
)
{
    import std.ascii : digits, lowercase, uppercase, whitespace;
    import std.random : choice;
    import std.algorithm : filter, countUntil, canFind;
    import std.conv : to;
    import std.array : array;
    import std.range : iota;

    dchar[] generated;

    dstring lower;
    dstring upper;
    dstring numeric;
    dstring special;
    dstring whitespaceChars;

    if (charPool.length == 0)
    {
        lower = (maxLower > 0 && maxAlpha > 0) ? lowercase.to!dstring : ""d;
        upper = (maxUpper > 0 && maxAlpha > 0) ? uppercase.to!dstring : ""d;
        numeric = maxNumeric > 0 ? digits.to!dstring : ""d;
        special = maxSpecial > 0 ? "!@#$%^&*()[]'`\",.<>{};:-=+_"d : ""d;
        whitespaceChars = maxWhitespace > 0 ? whitespace.to!dstring : ""d;

        charPool = lower ~ upper ~ numeric ~ special ~ whitespaceChars;
    }
    else
    {
        lower = charPool.filter!(a => canFind(lowercase, a)).array;
        upper = charPool.filter!(a => canFind(uppercase, a)).array;
        numeric = charPool.filter!(a => canFind(digits, a)).array;
        special = charPool.filter!(a => canFind(specialChars, a)).array;
        whitespaceChars = charPool.filter!(a => canFind(whitespace, a)).array;

        if (minLower > 0 && !lower.length)
        {
            throw new Exception("Can't fulfill lowercase character minimum when no lowercase characters are provided.");
        }
        if (minUpper > 0 && !upper.length)
        {
            throw new Exception("Can't fulfill uppercase character minimum when no uppercase characters are provided.");
        }
        if (minNumeric > 0 && !numeric.length)
        {
            throw new Exception("Can't fulfill numeric character minimum when no numeric characters are provided.");
        }
        if (minSpecial > 0 && !special.length)
        {
            throw new Exception("Can't fulfill special character minimum when no special characters are provided.");
        }
        if (minWhitespace > 0 && !whitespaceChars.length)
        {
            throw new Exception("Can't fulfill whitespace character minimum when no whitespace characters are provided.");
        }
    }

    size_t specialCount;
    size_t lowerCount;
    size_t upperCount;
    size_t whiteCount;
    size_t numericCount;

    long[] openSlots = iota(0, stringLength).array;

    generated.length = stringLength;
    long s;
    long openSlotsIndex;

    //populate the generated string to meet character type minimum requirements
    mixin(PopulateTypeString("lower", "Lower"));
    mixin(PopulateTypeString("upper", "Upper"));

    for(size_t i = 0; i < minAlpha - (minLower + minUpper); ++i)
    {
        s = openSlots.choice();
        generated[s] = (lower ~ upper).choice();
        openSlotsIndex = openSlots.countUntil(s);
        openSlots =
            openSlots.length == 1 ? [] :
            openSlots.length == 2 && openSlotsIndex == 0 ? [openSlots[1]] :
            openSlots.length == 2 && openSlotsIndex == 1 ? [openSlots[0]] :
            openSlotsIndex == 0 ? openSlots [1 .. $] :
            openSlotsIndex == openSlots.length - 1 ? openSlots[0 .. $ - 1] :
            openSlots[0 .. openSlotsIndex] ~ openSlots[openSlotsIndex + 1 .. $];
    }

    mixin(PopulateTypeString("numeric", "Numeric"));
    mixin(PopulateTypeString("special", "Special"));
    mixin(PopulateTypeString("whitespaceChars", "Whitespace"));

    //fill in the rest of the characters
    while (openSlots.length)
    {
        s = openSlots.choice();
        generated[s] = charPool.choice();
        openSlotsIndex = openSlots.countUntil(s);
        openSlots =
            openSlots.length == 1 ? [] :
            openSlots.length == 2 && openSlotsIndex == 0 ? [openSlots[1]] :
            openSlots.length == 2 && openSlotsIndex == 1 ? [openSlots[0]] :
            openSlotsIndex == 0 ? openSlots [1 .. $] :
            openSlotsIndex == openSlots.length - 1 ? openSlots[0 .. $ - 1] :
            openSlots[0 .. openSlotsIndex] ~ openSlots[openSlotsIndex + 1 .. $];
    }

    return generated.to!dstring;
}


/++
+ Generate a pseudo-random string
+
++/
/++
+  Examples:
+  --------------------
+  rs --length 15 --minlower 4 --maxwhitespace 0 //generate a 15-character long string with at least 4 lowercase letters and no whitespace.
+  rs --minwhitespace 10 //generate a string of 10 whitespace characters. (string length defaults to 10 characters.)
+  rs --length 20 --chars ADOGCATBIRDTREE //generate a string of 20 characters pulled from the provided "chars" string
+  --------------------
+/
void main(string[] args)
{
    import std.getopt;
    import std.conv : to;
    import std.stdio : writeln;

    long stringLength = -1;
    long minAlpha = 0;
    long maxAlpha = -1;
    long minNumeric = 0;
    long maxNumeric = -1;
    long minLower = 0;
    long maxLower = -1;
    long minUpper = 0;
    long maxUpper = -1;
    long minWhitespace = 0;
    long maxWhitespace = -1;
    long minSpecial = 0;
    long maxSpecial = -1;
    string charPool;

    //get options
    auto helpInformation = getopt(
        args,
        "length", &stringLength,
        "minalpha", &minAlpha,
        "maxalpha", &maxAlpha,
        "minnumeric", &minNumeric,
        "maxnumeric", &maxNumeric,
        "minlower", &minLower,
        "maxlower", &maxLower,
        "minupper", &minUpper,
        "maxupper", &maxUpper,
        "minwhitespace", &minWhitespace,
        "maxwhitespace", &maxWhitespace,
        "minspecial", &minSpecial,
        "maxspecial", &maxSpecial,
        "chars", "A pool of characters to pull from. If a character pool is not provided one will be generated instead.", &charPool
    );

    string validationMessage = validateOptions
        (
            stringLength,
            minAlpha,
            maxAlpha,
            minLower,
            maxLower,
            minUpper,
            maxUpper,
            minNumeric,
            maxNumeric,
            minSpecial,
            maxSpecial,
            minWhitespace,
            maxWhitespace
        );

    if (helpInformation.helpWanted || validationMessage.length)
    {
        defaultGetoptPrinter(validationMessage, helpInformation.options);
        return;
    }

    writeln
    (
        randString
        (
            stringLength,
            minAlpha,
            maxAlpha,
            minLower,
            maxLower,
            minUpper,
            maxUpper,
            minNumeric,
            maxNumeric,
            minSpecial,
            maxSpecial,
            minWhitespace,
            maxWhitespace,
            charPool.to!dstring
        )
    );
}


unittest //this needs to do more tests
{
    import std.algorithm : count, canFind;
    import std.stdio;
    import std.ascii;

    long stringLength = 10;
    long minAlpha = 2;
    long maxAlpha = 10;
    long minLower = 2;
    long maxLower = 10;
    long minUpper = 2;
    long maxUpper = 10;
    long minNumeric = 2;
    long maxNumeric = 10;
    long minSpecial = 2;
    long maxSpecial = 10;
    long minWhitespace = 2;
    long maxWhitespace = 10;
    dstring charPool = ""d;

    long alphaCount;
    long lowerCount;
    long upperCount;
    long numericCount;
    long specialCount;
    long whitespaceCount;

    static foreach
    (
        s;
        [
            "stringLength",
            "minAlpha",
            "maxAlpha",
            "minLower",
            "maxLower",
            "minUpper",
            "maxUpper",
            "minNumeric",
            "maxNumeric",
            "minSpecial",
            "maxSpecial",
            "minWhitespace",
            "maxWhitespace",
            "charPool"
        ]
    )
    {
        mixin(`writefln!"` ~s~ `: %s"(` ~s~ `);`);
    }

    import std.meta : AliasSeq;
    auto argSeq = AliasSeq!(
        stringLength,
        minAlpha,
        maxAlpha,
        minLower,
        maxLower,
        minUpper,
        maxUpper,
        minNumeric,
        maxNumeric,
        minSpecial,
        maxSpecial,
        minWhitespace,
        maxWhitespace,
        charPool);

    writeln(validateOptions(argSeq[0 .. $ - 1]));

    dstring str = randString(argSeq);

    alphaCount = str.count!(a => canFind(uppercase ~ lowercase, a));
    lowerCount = str.count!(a => canFind(lowercase, a));
    upperCount = str.count!(a => canFind(uppercase, a));
    numericCount = str.count!(a => canFind(digits, a));
    specialCount = str.count!(a => canFind(specialChars, a));
    whitespaceCount = str.count!(a => canFind(whitespace, a));

    writefln!"\n%s\n"(str);
    writefln!"Actual string length: %s"(str.length);
    writefln!"alphaCount: %s"(alphaCount);
    writefln!"lowerCount: %s"(alphaCount);
    writefln!"upperCount: %s"(alphaCount);
    writefln!"numericCount: %s"(alphaCount);
    writefln!"specialCount: %s"(alphaCount);
    writefln!"whitespaceCount: %s"(alphaCount);

    assert(str.length == stringLength);
    assert(upperCount >= minUpper);
    assert(upperCount <= maxUpper);
    assert(lowerCount >= minLower);
    assert(lowerCount <= maxLower);
    assert(alphaCount >= minAlpha);
    assert(alphaCount <= maxAlpha);
    assert(numericCount >= minNumeric);
    assert(numericCount <= maxNumeric);
    assert(specialCount >= minSpecial);
    assert(specialCount <= maxSpecial);
    assert(numericCount >= minNumeric);
    assert(numericCount <= maxNumeric);
    assert(whitespaceCount >= minWhitespace);
    assert(whitespaceCount <= maxWhitespace);
}
