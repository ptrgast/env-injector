# Parse the options

my %options = getOptions();

if (exists $options{"h"} || !exists $options{"i"} || !exists $options{"b"} || !exists $options{"e"}) {
    help();
    exit;
}

my $inputFile = $options{"i"};
my $beginningTag = $options{"b"};
my $endingTag = $options{"e"};

my $objectName = "window.env";
if (exists $options{"n"}) {
    $objectName = $options{"n"};
}

my @variables = getVariables();

# Generate the injection

$env = generateEnvObject(\@variables, $objectName);

# Parse the input document

my $inputDocument = readDocument($inputFile);
my $outputDocument = inject($inputDocument, $beginningTag, $endingTag, $env);

# Replace the input file with the resulting document

writeDocument($inputFile, $outputDocument);

sub getOptions
{
    my %options;
    my $regex = qr/-(\w+)(=(.*))?/p;

    foreach (@ARGV) {
        my $argument = $_;
        if (rindex($argument, "-", 0) == 0) {
            # Found an option. Parse it.
            if ($argument =~ /$regex/) {
                my $key = $1;
                my $value = $3;
                $options{$key} = $value;
            }
        }
    }

    return %options;
}

sub getVariables
{
    my @variables;

    foreach (@ARGV) {
        my $argument = $_;
        if (rindex($argument, "-", 0) != 0) {
            push @variables, $argument;
        }
    }

    return @variables;
}

sub generateEnvObject
{
    my @variables = @{$_[0]};
    my $objectName = @_[1];

    my @serializedVariables;

    foreach (@variables) {
        # Read the variable & escape double quotes 
        my $key = $_;
        my $value = $ENV{$_};
        $value =~ s/\"/\\"/g; 

        # Serialize the variable
        push @serializedVariables, "$key: \"$value\"";
    }

    my $env = "$objectName = {".join(", ", @serializedVariables)."}";

    return $env;
}

sub readDocument
{
    my $inputFile = @_[0];

    open my $handle, '<', $inputFile or die "Failed to open \"$inputFile\"!";
    read $handle, my $document, -s $handle;
    close $handle;

    return $document;
}

sub writeDocument
{
    my $outputFile = @_[0];
    my $document = @_[1];

    open my $handle, '>', $outputFile or die "Failed to open \"$outputFile\"!";
    print $handle $document;
    close $handle;
}

sub inject
{
    $document = @_[0];
    $beginningTag = @_[1];
    $endingTag = @_[2];
    $injection = @_[3];

    # Create the RegEx pattern
    my $pattern = $beginningTag.'((?!'.$endingTag.').|\n)*'.$endingTag;
    my $regex = qr@$pattern@p;

    # Create the output
    if (!($document =~ /$regex/)) {  
       die "Failed to match the replacement pattern!\n";
    }
    return "${^PREMATCH}${beginningTag}${injection}${endingTag}${^POSTMATCH}";
}

sub help 
{
    print "This command injects enviroment variables to an HTML document. ";
    print "For the injection a beginning and an ending tag must be provided. It could be anything that makes sense, even an HTML tag. ";
    print "Notice that only the first matching pair of tags will be used for the injection. The rest will be ignored.\n\n";
    print "WARNING: This command will replace the input file!\n";
    print "\n";
    print "Usage:\n";
    print "\tperl $0 OPTIONS [var_1] [var_2] ... [var_N]\n\n";
    print "\t-i (required)\tThe input document.\n";
    print "\t-b (required)\tThe beginning tag.\n";
    print "\t-e (required)\tThe ending tag.\n";
    print "\t-n\t\tThe name of the generated object.\n";
    print "\t-h\t\tPrints this help message.\n";
    print "\tvarN:\t\tThe name of the environment variable you want to include to the output.\n\n";
    print "Example:\n";
    print "\tperl $0 -i=index.html -b=\"<script data-type='env'>\" -e=\"</script>\" VUE_APP_VAR1 VUE_APP_VAR2\n\n";
}