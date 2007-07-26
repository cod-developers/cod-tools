use strict;
use warnings;
use SOptions;
use ShowStruct;
use CIFParse;

my @input_file;
my $output_file;
my $dict_file;
my $quiet = 0;
my $parser = new CIFParse;

@input_file = SOptions::getOptions ({
	"-o, --output" => \$output_file,
	"-D, --dictionary" => \$dict_file,
	"-v, --version" => showVersion;
	"-q, --quiet" => sub{ $quiet = 1; },
	"--no-quiet" => sub{ $quiet = 0; } }, @ARGV);

showRef(@input_file);
