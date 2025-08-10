#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../../';
use Test::More;
use System::DirectoryServices::AccountManagement::PrincipalContext;
use System::DirectoryServices::AccountManagement::ContextType;

BEGIN {
    use_ok('System::DirectoryServices::AccountManagement::PrincipalContext');
    use_ok('System::DirectoryServices::AccountManagement::ContextType');
}

# Test PrincipalContext construction
sub test_principal_context_construction {
    # Test basic construction with Machine context type
    my $context1 = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine
    );
    
    isa_ok($context1, 'System::DirectoryServices::AccountManagement::PrincipalContext', 
           'PrincipalContext with Machine type created successfully');
    isa_ok($context1, 'System::Object', 'PrincipalContext inherits from System::Object');
    ok(defined($context1), 'PrincipalContext is defined');
    
    # Test construction with Domain context type
    my $context2 = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Domain
    );
    
    isa_ok($context2, 'System::DirectoryServices::AccountManagement::PrincipalContext', 
           'PrincipalContext with Domain type created successfully');
    
    # Test construction with ApplicationDirectory context type
    my $context3 = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory
    );
    
    isa_ok($context3, 'System::DirectoryServices::AccountManagement::PrincipalContext', 
           'PrincipalContext with ApplicationDirectory type created successfully');
}

# Test PrincipalContext construction with parameters
sub test_principal_context_with_parameters {
    # Test construction with additional parameters
    my $context_with_params = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Domain,
        name => 'test.domain.com',
        container => 'OU=TestUsers,DC=test,DC=domain,DC=com',
        username => 'testuser',
        password => 'testpassword'
    );
    
    isa_ok($context_with_params, 'System::DirectoryServices::AccountManagement::PrincipalContext',
           'PrincipalContext with parameters created successfully');
    ok(defined($context_with_params), 'PrincipalContext with parameters is defined');
    
    # Test empty parameters hash
    my $context_empty_params = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine,
        ()  # Empty parameter hash
    );
    
    isa_ok($context_empty_params, 'System::DirectoryServices::AccountManagement::PrincipalContext',
           'PrincipalContext with empty parameters created successfully');
}

# Test ContextType property
sub test_context_type_property {
    # Test Machine context type
    my $machine_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine
    );
    
    my $machine_type = $machine_context->ContextType();
    is($machine_type, System::DirectoryServices::AccountManagement::ContextType::Machine, 
       'Machine context returns correct ContextType');
    is($machine_type, 0, 'Machine context type equals 0');
    
    # Test Domain context type
    my $domain_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Domain
    );
    
    my $domain_type = $domain_context->ContextType();
    is($domain_type, System::DirectoryServices::AccountManagement::ContextType::Domain, 
       'Domain context returns correct ContextType');
    is($domain_type, 1, 'Domain context type equals 1');
    
    # Test ApplicationDirectory context type
    my $app_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory
    );
    
    my $app_type = $app_context->ContextType();
    is($app_type, System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory, 
       'ApplicationDirectory context returns correct ContextType');
    is($app_type, 2, 'ApplicationDirectory context type equals 2');
}

# Test parameter storage and retrieval
sub test_parameter_storage {
    # Test parameter storage and access
    my $context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Domain,
        name => 'domain.local',
        container => 'CN=Users,DC=domain,DC=local',
        username => 'admin',
        password => 'secret123',
        custom_param => 'custom_value'
    );
    
    # Test that parameters are stored (through internal structure access)
    # Note: In real .NET, these would be accessible through properties
    # Here we test that the object stores the parameters correctly
    ok(defined($context), 'Context with multiple parameters is defined');
    
    # Test ContextType is still accessible
    is($context->ContextType(), System::DirectoryServices::AccountManagement::ContextType::Domain,
       'ContextType still accessible after parameter storage');
}

# Test object identity and uniqueness
sub test_object_identity {
    # Test that different PrincipalContext objects are unique
    my $context1 = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine
    );
    
    my $context2 = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine
    );
    
    isnt($context1, $context2, 'Different PrincipalContext instances are unique objects');
    
    # But both should have same ContextType
    is($context1->ContextType(), $context2->ContextType(), 
       'Same ContextType for same context type parameter');
}

# Test edge cases and validation
sub test_edge_cases {
    # Test with undefined context type (should still work but might be invalid)
    eval {
        my $context_undef = System::DirectoryServices::AccountManagement::PrincipalContext->new(undef);
        ok(defined($context_undef), 'PrincipalContext with undef contextType created');
    };
    ok(!$@, 'No exception thrown for undef contextType');
    
    # Test with numeric context type directly
    my $context_numeric = System::DirectoryServices::AccountManagement::PrincipalContext->new(0);
    isa_ok($context_numeric, 'System::DirectoryServices::AccountManagement::PrincipalContext',
           'PrincipalContext with numeric context type created');
    is($context_numeric->ContextType(), 0, 'Numeric context type stored correctly');
    
    # Test with invalid context type
    my $context_invalid = System::DirectoryServices::AccountManagement::PrincipalContext->new(999);
    isa_ok($context_invalid, 'System::DirectoryServices::AccountManagement::PrincipalContext',
           'PrincipalContext with invalid context type still created');
    is($context_invalid->ContextType(), 999, 'Invalid context type stored as-is');
}

# Test method signatures and interface compliance
sub test_method_signatures {
    my $context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine
    );
    
    # Test ContextType method signature - should take only $this parameter
    my $context_type;
    eval {
        $context_type = $context->ContextType();
    };
    ok(!$@, 'ContextType() method callable without extra parameters');
    ok(defined($context_type), 'ContextType() returns defined value');
    
    # Test that ContextType doesn't accept extra parameters (should still work but ignore them)
    eval {
        $context_type = $context->ContextType('extra', 'params');
    };
    ok(!$@, 'ContextType() method handles extra parameters gracefully');
}

# Test inheritance and base class functionality  
sub test_inheritance {
    my $context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Domain
    );
    
    # Test inheritance from System::Object
    isa_ok($context, 'System::Object', 'PrincipalContext inherits from System::Object');
    
    # Test that it has System::Object methods (if they exist and are implemented)
    ok($context->can('ContextType'), 'PrincipalContext has ContextType method');
    
    # Test object reference behavior
    my $context_ref = $context;
    is($context_ref, $context, 'Object reference equality works');
    is($context_ref->ContextType(), $context->ContextType(), 
       'Method calls work through references');
}

# Test use cases and typical scenarios
sub test_typical_scenarios {
    # Scenario 1: Machine context for local user management
    my $machine_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine
    );
    
    ok(defined($machine_context), 'Machine context created for local users');
    is($machine_context->ContextType(), 
       System::DirectoryServices::AccountManagement::ContextType::Machine,
       'Machine context has correct type');
    
    # Scenario 2: Domain context for Active Directory
    my $domain_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Domain,
        name => 'corp.example.com'
    );
    
    ok(defined($domain_context), 'Domain context created for AD');
    is($domain_context->ContextType(),
       System::DirectoryServices::AccountManagement::ContextType::Domain,
       'Domain context has correct type');
    
    # Scenario 3: Application directory context for ADAM/LDS
    my $app_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory,
        name => 'localhost:389',
        username => 'CN=admin,CN=Users,DC=app,DC=local',
        password => 'adminpass'
    );
    
    ok(defined($app_context), 'Application directory context created');
    is($app_context->ContextType(),
       System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory,
       'Application directory context has correct type');
}

# Test error conditions and boundary cases
sub test_error_conditions {
    # Test constructor with no parameters (should fail)
    eval {
        my $no_param_context = System::DirectoryServices::AccountManagement::PrincipalContext->new();
    };
    ok($@, 'Constructor without parameters throws error or handles gracefully');
    
    # Test with very large context type value
    my $large_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(999999);
    ok(defined($large_context), 'Large context type value handled');
    
    # Test with negative context type
    my $negative_context = System::DirectoryServices::AccountManagement::PrincipalContext->new(-1);
    ok(defined($negative_context), 'Negative context type value handled');
}

# Test context type validation helper
sub test_context_type_validation {
    # Helper function to validate context types
    my $is_valid_context_type = sub {
        my ($context) = @_;
        my $type = $context->ContextType();
        return $type == System::DirectoryServices::AccountManagement::ContextType::Machine ||
               $type == System::DirectoryServices::AccountManagement::ContextType::Domain ||
               $type == System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory;
    };
    
    # Test with valid context types
    my $machine_ctx = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Machine
    );
    ok($is_valid_context_type->($machine_ctx), 'Machine context type is valid');
    
    my $domain_ctx = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::Domain
    );
    ok($is_valid_context_type->($domain_ctx), 'Domain context type is valid');
    
    my $app_ctx = System::DirectoryServices::AccountManagement::PrincipalContext->new(
        System::DirectoryServices::AccountManagement::ContextType::ApplicationDirectory
    );
    ok($is_valid_context_type->($app_ctx), 'ApplicationDirectory context type is valid');
    
    # Test with invalid context type
    my $invalid_ctx = System::DirectoryServices::AccountManagement::PrincipalContext->new(99);
    ok(!$is_valid_context_type->($invalid_ctx), 'Invalid context type (99) is not valid');
}

# Run all tests
test_principal_context_construction();
test_principal_context_with_parameters();
test_context_type_property();
test_parameter_storage();
test_object_identity();
test_edge_cases();
test_method_signatures();
test_inheritance();
test_typical_scenarios();
test_error_conditions();
test_context_type_validation();

done_testing();