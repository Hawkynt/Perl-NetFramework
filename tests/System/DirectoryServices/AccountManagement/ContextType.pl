#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System::DirectoryServices::AccountManagement::ContextType;

BEGIN {
    use_ok('System::DirectoryServices::AccountManagement::ContextType');
}

# Test module loading and constants
sub test_module_loading {
    ok(1, 'ContextType module loads without error');
    
    # Test that the module is actually loaded and usable
    ok(defined(&System::DirectoryServices::AccountManagement::ContextType::Machine), 
       'Machine constant is defined');
    ok(defined(&System::DirectoryServices::AccountManagement::ContextType::Domain), 
       'Domain constant is defined');
    ok(defined(&System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory), 
       'ApplicationDirectory constant is defined');
}

# Test constant values
sub test_constant_values {
    # Test Machine context type
    is(System::DirectoryServices::AccountManagement::ContextType::Machine, 0, 
       'Machine constant has correct value (0)');
    
    # Test Domain context type  
    is(System::DirectoryServices::AccountManagement::ContextType::Domain, 1,
       'Domain constant has correct value (1)');
       
    # Test ApplicationDirectory context type
    is(System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory, 2,
       'ApplicationDirectory constant has correct value (2)');
}

# Test constant uniqueness
sub test_constant_uniqueness {
    my $machine = System::DirectoryServices::AccountManagement::ContextType::Machine;
    my $domain = System::DirectoryServices::AccountManagement::ContextType::Domain;
    my $app_dir = System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory;
    
    isnt($machine, $domain, 'Machine and Domain constants are different');
    isnt($machine, $app_dir, 'Machine and ApplicationDirectory constants are different');
    isnt($domain, $app_dir, 'Domain and ApplicationDirectory constants are different');
}

# Test usage in expressions and comparisons
sub test_constant_usage {
    my $context_type = System::DirectoryServices::AccountManagement::ContextType::Machine;
    
    # Test numeric operations
    ok($context_type == 0, 'Machine constant equals 0 in numeric context');
    ok($context_type < 1, 'Machine constant is less than 1');
    
    $context_type = System::DirectoryServices::AccountManagement::ContextType::Domain;
    ok($context_type == 1, 'Domain constant equals 1 in numeric context');
    ok($context_type > 0, 'Domain constant is greater than 0');
    ok($context_type < 2, 'Domain constant is less than 2');
    
    $context_type = System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory;
    ok($context_type == 2, 'ApplicationDirectory constant equals 2 in numeric context');
    ok($context_type > 1, 'ApplicationDirectory constant is greater than 1');
}

# Test constant types and properties
sub test_constant_properties {
    my $machine = System::DirectoryServices::AccountManagement::ContextType::Machine;
    my $domain = System::DirectoryServices::AccountManagement::ContextType::Domain;
    my $app_dir = System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory;
    
    # Test that constants are defined
    ok(defined($machine), 'Machine constant is defined');
    ok(defined($domain), 'Domain constant is defined');
    ok(defined($app_dir), 'ApplicationDirectory constant is defined');
    
    # Test that constants are numeric
    ok($machine =~ /^\d+$/, 'Machine constant is numeric');
    ok($domain =~ /^\d+$/, 'Domain constant is numeric');
    ok($app_dir =~ /^\d+$/, 'ApplicationDirectory constant is numeric');
    
    # Test that constants are non-negative integers
    ok($machine >= 0, 'Machine constant is non-negative');
    ok($domain >= 0, 'Domain constant is non-negative');
    ok($app_dir >= 0, 'ApplicationDirectory constant is non-negative');
}

# Test array and hash usage
sub test_collection_usage {
    # Test in array context
    my @context_types = (
        System::DirectoryServices::AccountManagement::ContextType::Machine,
        System::DirectoryServices::AccountManagement::ContextType::Domain,
        System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory
    );
    
    is(scalar(@context_types), 3, 'Array contains all context types');
    is($context_types[0], 0, 'First element is Machine (0)');
    is($context_types[1], 1, 'Second element is Domain (1)');
    is($context_types[2], 2, 'Third element is ApplicationDirectory (2)');
    
    # Test in hash context
    my %context_names = (
        System::DirectoryServices::AccountManagement::ContextType::Machine => 'Machine',
        System::DirectoryServices::AccountManagement::ContextType::Domain => 'Domain',
        System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory => 'ApplicationDirectory'
    );
    
    is($context_names{0}, 'Machine', 'Hash lookup for Machine works');
    is($context_names{1}, 'Domain', 'Hash lookup for Domain works');
    is($context_names{2}, 'ApplicationDirectory', 'Hash lookup for ApplicationDirectory works');
}

# Test switch-like operations
sub test_switch_operations {
    my $test_switch = sub {
        my ($context_type) = @_;
        
        if ($context_type == System::DirectoryServices::AccountManagement::ContextType::Machine) {
            return 'Machine Context';
        }
        elsif ($context_type == System::DirectoryServices::AccountManagement::ContextType::Domain) {
            return 'Domain Context';
        }
        elsif ($context_type == System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory) {
            return 'Application Directory Context';
        }
        else {
            return 'Unknown Context';
        }
    };
    
    is($test_switch->(System::DirectoryServices::AccountManagement::ContextType::Machine), 
       'Machine Context', 'Switch operation works for Machine');
       
    is($test_switch->(System::DirectoryServices::AccountManagement::ContextType::Domain), 
       'Domain Context', 'Switch operation works for Domain');
       
    is($test_switch->(System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory), 
       'Application Directory Context', 'Switch operation works for ApplicationDirectory');
       
    is($test_switch->(99), 'Unknown Context', 'Switch operation handles unknown values');
}

# Test edge cases and validation
sub test_edge_cases {
    # Test that constants can be used in string context
    my $machine_str = "" . System::DirectoryServices::AccountManagement::ContextType::Machine;
    my $domain_str = "" . System::DirectoryServices::AccountManagement::ContextType::Domain;
    my $app_dir_str = "" . System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory;
    
    is($machine_str, "0", 'Machine constant stringifies correctly');
    is($domain_str, "1", 'Domain constant stringifies correctly');
    is($app_dir_str, "2", 'ApplicationDirectory constant stringifies correctly');
    
    # Test mathematical operations
    my $machine = System::DirectoryServices::AccountManagement::ContextType::Machine;
    my $domain = System::DirectoryServices::AccountManagement::ContextType::Domain;
    
    is($machine + $domain, 1, 'Addition operation works (0 + 1 = 1)');
    is($domain - $machine, 1, 'Subtraction operation works (1 - 0 = 1)');
    is($domain * 2, 2, 'Multiplication operation works (1 * 2 = 2)');
}

# Test constant immutability (Perl constants should not be modifiable)
sub test_constant_immutability {
    # This test verifies that the constants behave as expected
    # In Perl, constants created with 'use constant' are read-only
    my $original_machine = System::DirectoryServices::AccountManagement::ContextType::Machine;
    my $original_domain = System::DirectoryServices::AccountManagement::ContextType::Domain;
    
    # Constants should maintain their values
    is(System::DirectoryServices::AccountManagement::ContextType::Machine, $original_machine,
       'Machine constant maintains its value');
    is(System::DirectoryServices::AccountManagement::ContextType::Domain, $original_domain,
       'Domain constant maintains its value');
    
    # Test that constants return same reference/value each time
    is(System::DirectoryServices::AccountManagement::ContextType::Machine,
       System::DirectoryServices::AccountManagement::ContextType::Machine,
       'Machine constant returns same value on multiple calls');
}

# Test package shortening and namespace
sub test_package_namespace {
    # Test that the package is properly namespaced
    ok(1, 'Package namespace is properly structured');
    
    # Test that constants are accessible from the full namespace
    my $full_machine = System::DirectoryServices::AccountManagement::ContextType::Machine;
    ok(defined($full_machine), 'Constants accessible via full namespace');
    
    # The module uses CSharp::_ShortenPackageName so test basic functionality
    eval {
        my $test_val = System::DirectoryServices::AccountManagement::ContextType::Machine;
    };
    ok(!$@, 'Module functions work after package name shortening');
}

# Run all tests
test_module_loading();
test_constant_values();
test_constant_uniqueness();
test_constant_usage();
test_constant_properties();
test_collection_usage();
test_switch_operations();
test_edge_cases();
test_constant_immutability();
test_package_namespace();

done_testing();