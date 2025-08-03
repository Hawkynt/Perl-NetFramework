requires 'perl', '5.010001';

# Core dependencies
requires 'strict';
requires 'warnings';
requires 'Exporter';
requires 'Scalar::Util';
requires 'Carp';
requires 'POSIX';
requires 'Time::HiRes';
requires 'File::Spec';
requires 'File::Basename';
requires 'File::Find';
requires 'Filter::Simple';

# Optional GUI dependencies
recommends 'Tk';
recommends 'Image::Xbm';

# Test dependencies
on 'test' => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Exception';
    requires 'File::Temp';
    requires 'Term::ANSIColor';
    requires 'Getopt::Long';
};

# Development dependencies
on 'develop' => sub {
    requires 'Perl::Critic';
    requires 'Perl::Tidy';
    requires 'Pod::Coverage::TrustPod';
    requires 'Test::Pod';
    requires 'Test::Pod::Coverage';
};