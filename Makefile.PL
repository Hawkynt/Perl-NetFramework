use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Perl::NetFramework',
    AUTHOR           => 'Hawkynt',
    VERSION_FROM     => 'lib/System.pm',
    ABSTRACT         => 'A comprehensive clone of the .NET Framework Base Class Library (BCL) implemented in pure Perl',
    LICENSE          => 'lgpl_3_0',
    MIN_PERL_VERSION => '5.010001',
    
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    
    PREREQ_PM => {
        'strict'        => '0',
        'warnings'      => '0',
        'Exporter'      => '0',
        'Scalar::Util'  => '0',
        'Carp'          => '0',
        'POSIX'         => '0',
        'Time::HiRes'   => '0',
        'File::Spec'    => '0',
        'File::Basename' => '0',
        'File::Find'    => '0',
        'Filter::Simple' => '0',
    },
    
    BUILD_REQUIRES => {
        'Test::More'     => '0.88',
        'Test::Exception' => '0',
        'File::Temp'     => '0',
    },
    
    RECOMMENDS => {
        'Tk'           => '0',      # For GUI MessageBox functionality
        'Image::Xbm'   => '0',      # For MessageBox icons
        'Term::ANSIColor' => '0',   # For colored test output
    },
    
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            homepage   => 'https://github.com/Hawkynt/Perl-NetFramework',
            repository => {
                type => 'git',
                url  => 'https://github.com/Hawkynt/Perl-NetFramework.git',
                web  => 'https://github.com/Hawkynt/Perl-NetFramework',
            },
            bugtracker => {
                web => 'https://github.com/Hawkynt/Perl-NetFramework/issues',
            },
        },
        keywords => ['dotnet', 'framework', 'csharp', 'bcl', 'linq', 'oop'],
        x_contributors => [
            'Hawkynt',
        ],
    },
    
    test => {
        TESTS => 'tests/*.pl tests/*/*.pl tests/*/*/*.pl',
    },
    
    clean => {
        FILES => 'Perl-NetFramework-*',
    },
    
    # Custom test target that uses our test runner
    postamble => '
test_runner:
	cd tests && perl run_tests.pl

test_verbose:
	cd tests && perl run_tests.pl --verbose

.PHONY: test_runner test_verbose
',
);

# Create lib directory structure for CPAN compatibility
sub MY::postamble {
    return <<'MAKE_FRAG';

# Create lib directory structure for CPAN distribution
create_lib_structure:
	$(MKPATH) lib
	$(CP) System.pm lib/
	$(CP) CSharp.pm lib/
	$(MKPATH) lib/Filter
	$(CP) Filter/CSharp.pm lib/Filter/
	$(MKPATH) lib/System
	$(CP) -r System/* lib/System/

# Clean up lib directory
clean_lib:
	$(RM_RF) lib

# Custom test using our test runner
test_runner:
	cd tests && $(PERL) run_tests.pl

test_verbose:
	cd tests && $(PERL) run_tests.pl --verbose

# Override standard test to use both
test :: test_runner

# Add to clean target
clean :: clean_lib

.PHONY: create_lib_structure clean_lib test_runner test_verbose

MAKE_FRAG
}