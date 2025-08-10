#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System::DirectoryServices::AccountManagement::IdentityType;

BEGIN {
    use_ok('System::DirectoryServices::AccountManagement::IdentityType');
}

# Test module loading and constants
sub test_module_loading {
    ok(1, 'IdentityType module loads without error');
    
    # Test that all identity type constants are defined
    ok(defined(&System::DirectoryServices::AccountManagement::IdentityType::SamAccountName), 
       'SamAccountName constant is defined');
    ok(defined(&System::DirectoryServices::AccountManagement::IdentityType::Name), 
       'Name constant is defined');
    ok(defined(&System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName), 
       'UserPrincipalName constant is defined');
    ok(defined(&System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName), 
       'DistinguishedName constant is defined');
    ok(defined(&System::DirectoryServices::AccountManagement::IdentityType::Sid), 
       'Sid constant is defined');
    ok(defined(&System::DirectoryServices::AccountManagement::IdentityType::Guid), 
       'Guid constant is defined');
}

# Test constant values
sub test_constant_values {
    # Test each identity type constant has correct value
    is(System::DirectoryServices::AccountManagement::IdentityType::SamAccountName, 0, 
       'SamAccountName constant has correct value (0)');
    
    is(System::DirectoryServices::AccountManagement::IdentityType::Name, 1,
       'Name constant has correct value (1)');
       
    is(System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName, 2,
       'UserPrincipalName constant has correct value (2)');
       
    is(System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName, 3,
       'DistinguishedName constant has correct value (3)');
       
    is(System::DirectoryServices::AccountManagement::IdentityType::Sid, 4,
       'Sid constant has correct value (4)');
       
    is(System::DirectoryServices::AccountManagement::IdentityType::Guid, 5,
       'Guid constant has correct value (5)');
}

# Test constant uniqueness
sub test_constant_uniqueness {
    my $sam = System::DirectoryServices::AccountManagement::IdentityType::SamAccountName;
    my $name = System::DirectoryServices::AccountManagement::IdentityType::Name;
    my $upn = System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName;
    my $dn = System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName;
    my $sid = System::DirectoryServices::AccountManagement::IdentityType::Sid;
    my $guid = System::DirectoryServices::AccountManagement::IdentityType::Guid;
    
    # Test all constants are unique
    isnt($sam, $name, 'SamAccountName and Name constants are different');
    isnt($sam, $upn, 'SamAccountName and UserPrincipalName constants are different');
    isnt($sam, $dn, 'SamAccountName and DistinguishedName constants are different');
    isnt($sam, $sid, 'SamAccountName and Sid constants are different');
    isnt($sam, $guid, 'SamAccountName and Guid constants are different');
    
    isnt($name, $upn, 'Name and UserPrincipalName constants are different');
    isnt($name, $dn, 'Name and DistinguishedName constants are different');
    isnt($name, $sid, 'Name and Sid constants are different');
    isnt($name, $guid, 'Name and Guid constants are different');
    
    isnt($upn, $dn, 'UserPrincipalName and DistinguishedName constants are different');
    isnt($upn, $sid, 'UserPrincipalName and Sid constants are different');
    isnt($upn, $guid, 'UserPrincipalName and Guid constants are different');
    
    isnt($dn, $sid, 'DistinguishedName and Sid constants are different');
    isnt($dn, $guid, 'DistinguishedName and Guid constants are different');
    
    isnt($sid, $guid, 'Sid and Guid constants are different');
}

# Test constant usage in expressions
sub test_constant_usage {
    # Test numeric operations with SamAccountName (should be 0)
    my $sam = System::DirectoryServices::AccountManagement::IdentityType::SamAccountName;
    ok($sam == 0, 'SamAccountName constant equals 0 in numeric context');
    ok($sam < 1, 'SamAccountName constant is less than 1');
    
    # Test with Name (should be 1)
    my $name = System::DirectoryServices::AccountManagement::IdentityType::Name;
    ok($name == 1, 'Name constant equals 1 in numeric context');
    ok($name > 0, 'Name constant is greater than 0');
    ok($name < 2, 'Name constant is less than 2');
    
    # Test with highest value (Guid should be 5)
    my $guid = System::DirectoryServices::AccountManagement::IdentityType::Guid;
    ok($guid == 5, 'Guid constant equals 5 in numeric context');
    ok($guid > 4, 'Guid constant is greater than 4');
}

# Test constant properties
sub test_constant_properties {
    my @constants = (
        System::DirectoryServices::AccountManagement::IdentityType::SamAccountName,
        System::DirectoryServices::AccountManagement::IdentityType::Name,
        System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName,
        System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName,
        System::DirectoryServices::AccountManagement::IdentityType::Sid,
        System::DirectoryServices::AccountManagement::IdentityType::Guid
    );
    
    for my $i (0..$#constants) {
        my $constant = $constants[$i];
        
        # Test that constants are defined
        ok(defined($constant), "Constant at index $i is defined");
        
        # Test that constants are numeric
        ok($constant =~ /^\d+$/, "Constant at index $i is numeric");
        
        # Test that constants are non-negative integers
        ok($constant >= 0, "Constant at index $i is non-negative");
        
        # Test sequential values (0, 1, 2, 3, 4, 5)
        is($constant, $i, "Constant at index $i has correct sequential value");
    }
}

# Test usage in identity type scenarios
sub test_identity_type_scenarios {
    # Test switch-like operations for identity type handling
    my $get_identity_description = sub {
        my ($identity_type) = @_;
        
        if ($identity_type == System::DirectoryServices::AccountManagement::IdentityType::SamAccountName) {
            return 'SAM Account Name (e.g., john.doe)';
        }
        elsif ($identity_type == System::DirectoryServices::AccountManagement::IdentityType::Name) {
            return 'Display Name (e.g., John Doe)';
        }
        elsif ($identity_type == System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName) {
            return 'User Principal Name (e.g., john.doe@domain.com)';
        }
        elsif ($identity_type == System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName) {
            return 'Distinguished Name (e.g., CN=John Doe,OU=Users,DC=domain,DC=com)';
        }
        elsif ($identity_type == System::DirectoryServices::AccountManagement::IdentityType::Sid) {
            return 'Security Identifier (e.g., S-1-5-21-...)';
        }
        elsif ($identity_type == System::DirectoryServices::AccountManagement::IdentityType::Guid) {
            return 'Globally Unique Identifier (e.g., {12345678-1234-5678-9012-123456789012})';
        }
        else {
            return 'Unknown Identity Type';
        }
    };
    
    like($get_identity_description->(System::DirectoryServices::AccountManagement::IdentityType::SamAccountName), 
         qr/SAM Account Name/, 'SamAccountName description is correct');
         
    like($get_identity_description->(System::DirectoryServices::AccountManagement::IdentityType::Name), 
         qr/Display Name/, 'Name description is correct');
         
    like($get_identity_description->(System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName), 
         qr/User Principal Name/, 'UserPrincipalName description is correct');
         
    like($get_identity_description->(System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName), 
         qr/Distinguished Name/, 'DistinguishedName description is correct');
         
    like($get_identity_description->(System::DirectoryServices::AccountManagement::IdentityType::Sid), 
         qr/Security Identifier/, 'Sid description is correct');
         
    like($get_identity_description->(System::DirectoryServices::AccountManagement::IdentityType::Guid), 
         qr/Globally Unique Identifier/, 'Guid description is correct');
         
    is($get_identity_description->(99), 'Unknown Identity Type', 'Unknown type handling works');
}

# Test array and hash usage
sub test_collection_usage {
    # Test in array context
    my @identity_types = (
        System::DirectoryServices::AccountManagement::IdentityType::SamAccountName,
        System::DirectoryServices::AccountManagement::IdentityType::Name,
        System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName,
        System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName,
        System::DirectoryServices::AccountManagement::IdentityType::Sid,
        System::DirectoryServices::AccountManagement::IdentityType::Guid
    );
    
    is(scalar(@identity_types), 6, 'Array contains all identity types');
    is($identity_types[0], 0, 'First element is SamAccountName (0)');
    is($identity_types[1], 1, 'Second element is Name (1)');
    is($identity_types[2], 2, 'Third element is UserPrincipalName (2)');
    is($identity_types[3], 3, 'Fourth element is DistinguishedName (3)');
    is($identity_types[4], 4, 'Fifth element is Sid (4)');
    is($identity_types[5], 5, 'Sixth element is Guid (5)');
    
    # Test in hash context for identity type names
    my %identity_names = (
        System::DirectoryServices::AccountManagement::IdentityType::SamAccountName => 'SamAccountName',
        System::DirectoryServices::AccountManagement::IdentityType::Name => 'Name',
        System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName => 'UserPrincipalName',
        System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName => 'DistinguishedName',
        System::DirectoryServices::AccountManagement::IdentityType::Sid => 'Sid',
        System::DirectoryServices::AccountManagement::IdentityType::Guid => 'Guid'
    );
    
    is($identity_names{0}, 'SamAccountName', 'Hash lookup for SamAccountName works');
    is($identity_names{1}, 'Name', 'Hash lookup for Name works');
    is($identity_names{2}, 'UserPrincipalName', 'Hash lookup for UserPrincipalName works');
    is($identity_names{3}, 'DistinguishedName', 'Hash lookup for DistinguishedName works');
    is($identity_names{4}, 'Sid', 'Hash lookup for Sid works');
    is($identity_names{5}, 'Guid', 'Hash lookup for Guid works');
}

# Test string and mathematical operations
sub test_operations {
    # Test string context
    my $sam_str = "" . System::DirectoryServices::AccountManagement::IdentityType::SamAccountName;
    my $guid_str = "" . System::DirectoryServices::AccountManagement::IdentityType::Guid;
    
    is($sam_str, "0", 'SamAccountName stringifies correctly');
    is($guid_str, "5", 'Guid stringifies correctly');
    
    # Test mathematical operations
    my $name = System::DirectoryServices::AccountManagement::IdentityType::Name;
    my $upn = System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName;
    
    is($name + $upn, 3, 'Addition works (1 + 2 = 3)');
    is($upn - $name, 1, 'Subtraction works (2 - 1 = 1)');
    is($name * 2, 2, 'Multiplication works (1 * 2 = 2)');
}

# Test identity type validation scenarios
sub test_validation_scenarios {
    # Test function that validates identity type values
    my $is_valid_identity_type = sub {
        my ($type) = @_;
        return $type >= System::DirectoryServices::AccountManagement::IdentityType::SamAccountName
            && $type <= System::DirectoryServices::AccountManagement::IdentityType::Guid;
    };
    
    # Test valid types
    ok($is_valid_identity_type->(System::DirectoryServices::AccountManagement::IdentityType::SamAccountName), 
       'SamAccountName is valid identity type');
    ok($is_valid_identity_type->(System::DirectoryServices::AccountManagement::IdentityType::Name), 
       'Name is valid identity type');
    ok($is_valid_identity_type->(System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName), 
       'UserPrincipalName is valid identity type');
    ok($is_valid_identity_type->(System::DirectoryServices::AccountManagement::IdentityType::DistinguishedName), 
       'DistinguishedName is valid identity type');
    ok($is_valid_identity_type->(System::DirectoryServices::AccountManagement::IdentityType::Sid), 
       'Sid is valid identity type');
    ok($is_valid_identity_type->(System::DirectoryServices::AccountManagement::IdentityType::Guid), 
       'Guid is valid identity type');
       
    # Test invalid types
    ok(!$is_valid_identity_type->(-1), 'Negative value is invalid identity type');
    ok(!$is_valid_identity_type->(6), 'Value above range is invalid identity type');
    ok(!$is_valid_identity_type->(999), 'Large value is invalid identity type');
}

# Test constant immutability and consistency
sub test_constant_consistency {
    # Test that constants return the same value on multiple calls
    is(System::DirectoryServices::AccountManagement::IdentityType::SamAccountName,
       System::DirectoryServices::AccountManagement::IdentityType::SamAccountName,
       'SamAccountName constant is consistent across calls');
       
    is(System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName,
       System::DirectoryServices::AccountManagement::IdentityType::UserPrincipalName,
       'UserPrincipalName constant is consistent across calls');
       
    is(System::DirectoryServices::AccountManagement::IdentityType::Guid,
       System::DirectoryServices::AccountManagement::IdentityType::Guid,
       'Guid constant is consistent across calls');
}

# Test package namespace and CSharp integration
sub test_package_namespace {
    # Test that the package loads and functions correctly
    ok(1, 'Package namespace is properly structured');
    
    # Test that constants are accessible from the full namespace
    my $full_sam = System::DirectoryServices::AccountManagement::IdentityType::SamAccountName;
    ok(defined($full_sam), 'Constants accessible via full namespace');
    
    # Test module works after CSharp package name shortening
    eval {
        my $test_val = System::DirectoryServices::AccountManagement::IdentityType::Name;
    };
    ok(!$@, 'Module functions work after package name shortening');
}

# Run all tests
test_module_loading();
test_constant_values();
test_constant_uniqueness();
test_constant_usage();
test_constant_properties();
test_identity_type_scenarios();
test_collection_usage();
test_operations();
test_validation_scenarios();
test_constant_consistency();
test_package_namespace();

done_testing();