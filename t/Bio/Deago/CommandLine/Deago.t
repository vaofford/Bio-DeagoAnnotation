#!/usr/bin/env perl

use Moose;
use Cwd qw(abs_path getcwd); 

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';
with 'ConfigTestHelper';

$ENV{PATH} = join(':', ("$ENV{PATH}", abs_path('../bin')));

BEGIN {
    use Test::Most;
    use_ok('Bio::Deago::CommandLine::Deago');
}

my $script_name = 'Bio::Deago::CommandLine::Deago';
system('touch empty_file');

my $output_directory = make_output_directory();
die "Output directory path unsafe" if ( !defined($output_directory) || $output_directory eq "" || $output_directory !~ m/deago_test_output/ );

build_default_config_file( 'expected_default_deago.config', $output_directory );
build_mart_config_file( 'expected_mart_deago.config', $output_directory );
build_go_config_file( 'expected_go_deago.config', $output_directory );

my $build_config_params = "--build_config -t t/data/example_targets.tsv -c t/data/example_counts -r $output_directory";
my $go_config_params = "--config_file expected_go_deago.config";
build_star_delimited_annotation_file();

my %scripts_and_expected_files = (
    '--config_file expected_default_deago.config' => [ ['deago_markdown.Rmd','deago_markdown.html'] ],
    "$build_config_params --config_file $output_directory/new_deago.config" => [ ["$output_directory/new_deago.config",'deago_markdown.Rmd','deago_markdown.html'] ], 
    "$build_config_params --convert_annotation -a t/data/example_mart_annotation.tsv"	=> [ ['deago.config', 't/data/example_mart_annotation_deago.tsv','deago_markdown.Rmd','deago_markdown.html'], 
                                                                                             ['expected_mart_deago.config', 't/data/example_deago_annotation.tsv'] ],		
    "$go_config_params"   => [ ['expected_go_deago.config', 'deago_markdown.Rmd','deago_markdown.html'], ['expected_go_deago.config'] ],                                                                                         
    "--config_file expected_default_deago.config --markdown_file $output_directory/deago_markdown.out.Rmd --html_file $output_directory/deago_markdown.out.html" 	=> [ ["$output_directory/deago_markdown.out.Rmd","$output_directory/deago_markdown.out.html"] ],
    "$build_config_params --convert_annotation -a t/data/example_mart_annotation.tsv --annotation_delim '**'" => [ ['deago.config', 't/data/example_mart_annotation_deago.tsv','deago_markdown.Rmd','deago_markdown.html'] ], 
    "$build_config_params -o $output_directory" => [ ["$output_directory/deago.config","$output_directory/deago_markdown.Rmd","$output_directory/deago_markdown.html"], ['expected_default_deago.config'] ],
    '-h' => [ ['empty_file'], ['t/data/empty_file'] ],
);

stdout_should_have( $script_name, '',                           'Error: You need to provide or build a configuration file' );
stdout_should_have( $script_name, '--config_file badConfig',    'Error: Configuration file does not exist' );
stdout_should_have( $script_name, '--build_config',             'Error: You need to provide both a counts directory and targets file or a valid configuration file' );
stdout_should_have( $script_name, '--convert_annotation',       'Error: --convert_annotation requires --build_config' );
stdout_should_have( $script_name, '--config_file expected_default_deago.config 0',      'Error: You need to remove trailing arguements' );
stdout_should_have( $script_name, '--config_file expected_default_deago.config -o BAD', 'Error: Output directory doesn\'t exist' );
stdout_should_have( $script_name, "$build_config_params --go_levels BAD", 		        'Error: go_levels must be either BP, MF or all' );
stdout_should_have( $script_name, "$build_config_params --count_type BAD",              'Error: count_type must be either featurecounts or expression' );
stdout_should_have( $script_name, "$build_config_params --markdown_file empty_file", 	'Error: Cannot generate markdown file as markdown file already exists' );
stdout_should_have( $script_name, "$build_config_params --html_file empty_file",        'Error: Cannot generate html file as html file already exists' );
stdout_should_have( $script_name, "$build_config_params --config_file BAD/PATH",        'Error: Cannot build configuration file as destination directory doesn\'t exist' );
stdout_should_have( $script_name, "$build_config_params --config_file empty_file",      'Error: Cannot build configuration file as configuration file already exists' );
stdout_should_have( $script_name, "$build_config_params --convert_annotation",          'Error: Cannot convert annotation file as no annotation file given' );
stdout_should_have( $script_name, "$build_config_params --convert_annotation -a BAD",   'Error: Cannot convert annotation file as annotation file does not exist' );

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

unlink( 'expected_default_deago.config' );
unlink( 'expected_mart_deago.config' );
unlink( 'star_delimited_annotation.txt' );
unlink( 't/data/example_mart_annotation_deago.tsv' );
unlink( 'empty_file' );

print join(' ', uc("You will need to manually remove the test output directory:"), $output_directory, "\n") if ( defined($output_directory) && -d $output_directory && $output_directory =~ m/deago_test_output/ );

done_testing();
