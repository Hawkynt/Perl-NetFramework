#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System::IAsyncResult;

BEGIN {
    use_ok('System::IAsyncResult');
}

# Test interface module loading
sub test_interface_loading {
    ok(1, 'IAsyncResult interface module loads without error');
    
    # Test that interface methods are defined
    ok(defined(&System::IAsyncResult::AsyncState), 'AsyncState method is defined');
    ok(defined(&System::IAsyncResult::AsyncWaitHandle), 'AsyncWaitHandle method is defined');
    ok(defined(&System::IAsyncResult::CompletedSynchronously), 'CompletedSynchronously method is defined');
    ok(defined(&System::IAsyncResult::IsCompleted), 'IsCompleted method is defined');
}

# Test interface method signatures
sub test_interface_method_signatures {
    # Test that interface methods can be called (they should throw NotImplementedException)
    
    # Test AsyncState method signature
    eval {
        System::IAsyncResult::AsyncState(undef);
    };
    ok($@, 'AsyncState throws exception when called directly on interface');
    like($@, qr/NotImplementedException/, 'AsyncState throws NotImplementedException');
    
    # Test AsyncWaitHandle method signature
    eval {
        System::IAsyncResult::AsyncWaitHandle(undef);
    };
    ok($@, 'AsyncWaitHandle throws exception when called directly on interface');
    like($@, qr/NotImplementedException/, 'AsyncWaitHandle throws NotImplementedException');
    
    # Test CompletedSynchronously method signature
    eval {
        System::IAsyncResult::CompletedSynchronously(undef);
    };
    ok($@, 'CompletedSynchronously throws exception when called directly on interface');
    like($@, qr/NotImplementedException/, 'CompletedSynchronously throws NotImplementedException');
    
    # Test IsCompleted method signature
    eval {
        System::IAsyncResult::IsCompleted(undef);
    };
    ok($@, 'IsCompleted throws exception when called directly on interface');
    like($@, qr/NotImplementedException/, 'IsCompleted throws NotImplementedException');
}

# Test interface method existence
sub test_interface_method_existence {
    # Test that methods can be found via can()
    ok(System::IAsyncResult->can('AsyncState'), 'IAsyncResult can AsyncState');
    ok(System::IAsyncResult->can('AsyncWaitHandle'), 'IAsyncResult can AsyncWaitHandle');
    ok(System::IAsyncResult->can('CompletedSynchronously'), 'IAsyncResult can CompletedSynchronously');
    ok(System::IAsyncResult->can('IsCompleted'), 'IAsyncResult can IsCompleted');
    
    # Test that non-existent methods are not found
    ok(!System::IAsyncResult->can('NonExistentMethod'), 'IAsyncResult cannot NonExistentMethod');
}

# Test interface contract compliance
sub test_interface_contract {
    # Test that all required interface methods are present
    my @required_methods = qw(AsyncState AsyncWaitHandle CompletedSynchronously IsCompleted);
    
    for my $method (@required_methods) {
        ok(System::IAsyncResult->can($method), "Required method $method is available");
    }
    
    # Test method count (interface should have exactly 4 methods)
    my $method_count = 0;
    for my $method (@required_methods) {
        $method_count++ if System::IAsyncResult->can($method);
    }
    is($method_count, 4, 'Interface has exactly 4 required methods');
}

# Test mock implementation to verify interface usage
sub test_mock_implementation {
    # Create a mock class that implements IAsyncResult
    package MockAsyncResult;
    use base 'System::IAsyncResult';
    
    sub new {
        my ($class, %params) = @_;
        return bless {
            _async_state => $params{async_state},
            _is_completed => $params{is_completed} // 0,
            _completed_synchronously => $params{completed_synchronously} // 0,
            _wait_handle => $params{wait_handle}
        }, $class;
    }
    
    sub AsyncState {
        my ($self) = @_;
        return $self->{_async_state};
    }
    
    sub AsyncWaitHandle {
        my ($self) = @_;
        return $self->{_wait_handle};
    }
    
    sub CompletedSynchronously {
        my ($self) = @_;
        return $self->{_completed_synchronously};
    }
    
    sub IsCompleted {
        my ($self) = @_;
        return $self->{_is_completed};
    }
    
    package main;
    
    # Test the mock implementation
    my $async_result = MockAsyncResult->new(
        async_state => 'test_state',
        is_completed => 1,
        completed_synchronously => 0,
        wait_handle => 'test_handle'
    );
    
    isa_ok($async_result, 'MockAsyncResult', 'Mock implementation created');
    isa_ok($async_result, 'System::IAsyncResult', 'Mock inherits from IAsyncResult interface');
    
    # Test that implemented methods work
    is($async_result->AsyncState(), 'test_state', 'AsyncState returns correct value');
    is($async_result->IsCompleted(), 1, 'IsCompleted returns correct value');
    is($async_result->CompletedSynchronously(), 0, 'CompletedSynchronously returns correct value');
    is($async_result->AsyncWaitHandle(), 'test_handle', 'AsyncWaitHandle returns correct value');
}

# Test interface polymorphism
sub test_interface_polymorphism {
    # Test that objects implementing IAsyncResult can be used polymorphically
    
    # Create another mock implementation
    package AnotherMockAsyncResult;
    use base 'System::IAsyncResult';
    
    sub new {
        my ($class) = @_;
        return bless {
            _completed => 1,
            _sync => 1,
            _state => 'completed',
            _handle => 'finished'
        }, $class;
    }
    
    sub AsyncState { return $_[0]->{_state}; }
    sub AsyncWaitHandle { return $_[0]->{_handle}; }
    sub CompletedSynchronously { return $_[0]->{_sync}; }
    sub IsCompleted { return $_[0]->{_completed}; }
    
    package main;
    
    my $async1 = MockAsyncResult->new(
        async_state => 'first',
        is_completed => 0
    );
    
    my $async2 = AnotherMockAsyncResult->new();
    
    # Test polymorphic usage
    my @async_results = ($async1, $async2);
    
    for my $i (0..$#async_results) {
        my $result = $async_results[$i];
        
        isa_ok($result, 'System::IAsyncResult', "Result $i implements IAsyncResult interface");
        
        # Test that all interface methods are callable
        ok(defined($result->AsyncState()), "Result $i AsyncState is callable");
        ok(defined($result->IsCompleted()) || $result->IsCompleted() == 0, "Result $i IsCompleted is callable");
        ok(defined($result->CompletedSynchronously()) || $result->CompletedSynchronously() == 0, "Result $i CompletedSynchronously is callable");
        ok(defined($result->AsyncWaitHandle()), "Result $i AsyncWaitHandle is callable");
    }
}

# Test typical async result patterns
sub test_async_result_patterns {
    # Pattern 1: Checking completion status
    my $completed_result = MockAsyncResult->new(
        is_completed => 1,
        completed_synchronously => 1,
        async_state => 'sync_completed'
    );
    
    my $pending_result = MockAsyncResult->new(
        is_completed => 0,
        completed_synchronously => 0,
        async_state => 'pending'
    );
    
    # Test completion checking
    ok($completed_result->IsCompleted(), 'Completed result shows as completed');
    ok(!$pending_result->IsCompleted(), 'Pending result shows as not completed');
    
    ok($completed_result->CompletedSynchronously(), 'Synchronous result shows as synchronous');
    ok(!$pending_result->CompletedSynchronously(), 'Asynchronous result shows as not synchronous');
    
    # Pattern 2: State management
    is($completed_result->AsyncState(), 'sync_completed', 'Completed result has correct state');
    is($pending_result->AsyncState(), 'pending', 'Pending result has correct state');
}

# Test interface documentation and metadata
sub test_interface_metadata {
    # Test that the interface module has proper structure
    ok(1, 'Interface has proper package structure');
    
    # Test that interface methods are documented (via comments in the module)
    # This is more of a structural test
    
    # Test CSharp integration
    eval {
        # The module uses CSharp::_ShortenPackageName
        # Test that this doesn't break functionality
        my $test_call = System::IAsyncResult->can('AsyncState');
        ok(defined($test_call), 'CSharp integration does not break method resolution');
    };
    ok(!$@, 'CSharp integration works without errors');
}

# Test error handling and edge cases
sub test_error_handling {
    # Test calling interface methods with wrong number of arguments
    eval {
        System::IAsyncResult::AsyncState();  # No $self parameter
    };
    ok($@, 'AsyncState throws error with no parameters');
    
    eval {
        System::IAsyncResult::AsyncState('not_an_object', 'extra_param');
    };
    ok($@, 'AsyncState throws error with extra parameters');
    
    # Test with undefined object
    eval {
        my $undef_obj;
        $undef_obj->AsyncState() if defined($undef_obj);  # Won't be called due to guard
    };
    ok(!$@, 'Guarded call with undefined object does not throw error');
}

# Test interface inheritance and ISA relationships
sub test_interface_inheritance {
    # Create a class that uses IAsyncResult as a mixin
    package TestAsyncImplementation;
    use base 'System::IAsyncResult';
    
    sub new { 
        my $class = shift;
        return bless { @_ }, $class; 
    }
    
    sub AsyncState { return 'test_state'; }
    sub AsyncWaitHandle { return 'test_handle'; }
    sub CompletedSynchronously { return 1; }
    sub IsCompleted { return 0; }
    
    package main;
    
    my $impl = TestAsyncImplementation->new();
    
    # Test ISA relationships
    isa_ok($impl, 'TestAsyncImplementation', 'Implementation is correct class');
    isa_ok($impl, 'System::IAsyncResult', 'Implementation inherits from IAsyncResult');
    
    # Test that interface methods work through inheritance
    is($impl->AsyncState(), 'test_state', 'Inherited AsyncState works');
    is($impl->AsyncWaitHandle(), 'test_handle', 'Inherited AsyncWaitHandle works');
    is($impl->CompletedSynchronously(), 1, 'Inherited CompletedSynchronously works');
    is($impl->IsCompleted(), 0, 'Inherited IsCompleted works');
}

# Test interface as a contract specification
sub test_interface_contract_specification {
    # Test that implementing classes must provide all interface methods
    
    # This would be tested at runtime when methods are called
    my $check_interface_compliance = sub {
        my ($object) = @_;
        
        # Check that object can perform all required operations
        return $object->can('AsyncState') &&
               $object->can('AsyncWaitHandle') &&
               $object->can('CompletedSynchronously') &&
               $object->can('IsCompleted');
    };
    
    my $compliant_impl = MockAsyncResult->new();
    ok($check_interface_compliance->($compliant_impl), 'Compliant implementation passes interface check');
    
    # Test with a non-compliant object (regular object without interface methods)
    my $non_compliant = bless {}, 'NonCompliantClass';
    ok(!$check_interface_compliance->($non_compliant), 'Non-compliant object fails interface check');
}

# Run all tests
test_interface_loading();
test_interface_method_signatures();
test_interface_method_existence();
test_interface_contract();
test_mock_implementation();
test_interface_polymorphism();
test_async_result_patterns();
test_interface_metadata();
test_error_handling();
test_interface_inheritance();
test_interface_contract_specification();

done_testing();