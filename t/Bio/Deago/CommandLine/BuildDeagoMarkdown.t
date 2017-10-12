#!/usr/bin/env perl

use Moose;
use Data::Dumper;
use Cwd qw(abs_path getcwd); 

BEGIN { unshift( @INC, './lib' ) }
BEGIN { unshift( @INC, './t/lib' ) }
with 'TestHelper';
with 'ConfigTestHelper';

$ENV{PATH} = join(':', ("$ENV{PATH}", abs_path('../bin')));

BEGIN {
    use Test::Most;
    use_ok('Bio::Deago::CommandLine::BuildDeagoMarkdown');
}

my $script_name = 'Bio::Deago::CommandLine::BuildDeagoMarkdown';
system('touch empty_file');

my $results_directory = make_results_directory();
die "Resuls directory path unsafe" if ( !defined($results_directory) || $results_directory eq "" || $results_directory !~ m/deago_test_results/ );

build_default_config_file( 'expected_default_deago.config', $results_directory );
build_qc_config_file( 'expected_qc_deago.config', $results_directory );
build_go_config_file( 'expected_go_deago.config', $results_directory );

my %scripts_and_expected_files = (
      '-c expected_default_deago.config'																	=> [ ['deago_markdown.Rmd'] ],
      '-c expected_qc_deago.config'																				=> [ ['deago_markdown.Rmd'] ],
      '-c expected_go_deago.config'																				=> [ ['deago_markdown.Rmd'] ],
      '-c expected_default_deago.config -o deago_markdown.out.Rmd'				=> [ ['deago_markdown.out.Rmd'] ],
      '-c expected_default_deago.config -o deago_markdown.out.Rmd -d t'		=> [ ['t/deago_markdown.out.Rmd'] ],
      '-h' => [ ['empty_file'], ['t/data/empty_file'] ],
);

stdout_should_have( $script_name, '',																							'Error: You need to provide a configuration file' );
stdout_should_have( $script_name, '-o deago_markdown.Rmd -d .', 									'Error: You need to provide a configuration file' );
stdout_should_have( $script_name, '-c bad_config', 																'Error: Cannot find configuration file' );
stdout_should_have( $script_name, '-c expected_default_deago.config  -d badDir', 	'Error: Could not find output directory for markdown file' );

mock_execute_script_and_check_output( $script_name, \%scripts_and_expected_files );

unlink( 'expected_default_deago.config' );
unlink( 'expected_qc_deago.config' );
unlink( 'expected_go_deago.config' );
unlink( 'empty_file' );

done_testing();