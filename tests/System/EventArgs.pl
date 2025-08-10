#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use Carp qw(confess);

# Import System classes
use System;
use System::Object;
use System::EventArgs;
use System::Exceptions;
use CSharp;

BEGIN {
    use_ok('System::EventArgs');
}

# Test basic EventArgs creation
sub test_eventargs_creation {
    # Test basic constructor
    my $args = System::EventArgs->new();
    isa_ok($args, 'System::EventArgs', 'EventArgs created successfully');
    isa_ok($args, 'System::Object', 'EventArgs inherits from System::Object');
    ok(defined($args), 'EventArgs is defined');
    
    # Test multiple instances are different objects
    my $args2 = System::EventArgs->new();
    isa_ok($args2, 'System::EventArgs', 'Second EventArgs created');
    isnt($args, $args2, 'Different EventArgs instances are not identical');
}

sub test_eventargs_empty_instance {
    # Test Empty static property/method
    my $empty1 = System::EventArgs->Empty();
    isa_ok($empty1, 'System::EventArgs', 'Empty returns EventArgs instance');
    ok(defined($empty1), 'Empty instance is defined');
    
    # Test Empty returns same instance (singleton pattern)
    my $empty2 = System::EventArgs->Empty();
    is($empty1, $empty2, 'Empty returns same instance (singleton)');
    
    # Test Empty instance multiple calls
    for my $i (1..5) {
        my $empty = System::EventArgs->Empty();
        is($empty, $empty1, "Empty call $i returns same instance");
    }
    
    # Test Empty instance is different from regular instances
    my $regular = System::EventArgs->new();
    isnt($empty1, $regular, 'Empty instance is different from regular instance');
    
    # But both should be same type
    isa_ok($empty1, 'System::EventArgs', 'Empty instance is EventArgs type');
    isa_ok($regular, 'System::EventArgs', 'Regular instance is EventArgs type');
}

sub test_eventargs_inheritance {
    # Test that EventArgs inherits from Object
    my $args = System::EventArgs->new();
    
    # Test inheritance chain
    isa_ok($args, 'System::Object', 'EventArgs inherits from System::Object');
    
    # Test Object methods are available
    ok($args->can('ToString'), 'EventArgs has ToString method from Object');
    ok($args->can('GetType'), 'EventArgs has GetType method from Object');
    ok($args->can('GetHashCode'), 'EventArgs has GetHashCode method from Object');
    ok($args->can('Equals'), 'EventArgs has Equals method from Object');
    ok($args->can('Is'), 'EventArgs has Is method from Object');
    ok($args->can('As'), 'EventArgs has As method from Object');
    
    # Test GetType returns correct type
    is($args->GetType(), 'System::EventArgs', 'GetType returns correct EventArgs type');
    
    # Test Empty instance inheritance
    my $empty = System::EventArgs->Empty();
    isa_ok($empty, 'System::Object', 'Empty EventArgs inherits from System::Object');
    is($empty->GetType(), 'System::EventArgs', 'Empty instance GetType returns EventArgs');
}

sub test_eventargs_object_methods {
    my $args = System::EventArgs->new();
    
    # Test ToString method
    my $str = $args->ToString();
    ok(defined($str), 'ToString returns defined value');
    like($str, qr/System::EventArgs/, 'ToString contains class name');
    
    # Test ToString consistency
    is($args->ToString(), $args->ToString(), 'ToString is consistent');
    
    # Test GetHashCode
    my $hash = $args->GetHashCode();
    ok(defined($hash), 'GetHashCode returns defined value');
    ok($hash >= 0, 'Hash code is non-negative');
    is($args->GetHashCode(), $hash, 'GetHashCode is consistent for same object');
    
    # Test different EventArgs have different hash codes
    my $args2 = System::EventArgs->new();
    my $hash2 = $args2->GetHashCode();
    isnt($hash, $hash2, 'Different EventArgs instances have different hash codes');
    
    # Test Equals
    ok($args->Equals($args), 'EventArgs equals itself');
    ok(!$args->Equals($args2), 'Different EventArgs instances are not equal');
    ok(!$args->Equals(undef), 'EventArgs does not equal undef');
    ok(!$args->Equals("string"), 'EventArgs does not equal string');
    
    # Test Empty instance object methods
    my $empty = System::EventArgs->Empty();
    ok(defined($empty->ToString()), 'Empty instance ToString works');
    ok(defined($empty->GetHashCode()), 'Empty instance GetHashCode works');
    ok($empty->Equals($empty), 'Empty instance equals itself');
    
    # Test Empty instance consistency
    my $empty2 = System::EventArgs->Empty();
    ok($empty->Equals($empty2), 'Empty instances are equal');
    is($empty->GetHashCode(), $empty2->GetHashCode(), 'Empty instances have same hash code');
}

sub test_eventargs_type_checking {
    my $args = System::EventArgs->new();
    
    # Test Is method
    ok($args->Is('System::EventArgs'), 'EventArgs Is System::EventArgs');
    ok($args->Is('System::Object'), 'EventArgs Is System::Object (inheritance)');
    ok(!$args->Is('System::String'), 'EventArgs is not System::String');
    ok(!$args->Is('System::Exception'), 'EventArgs is not System::Exception');
    
    # Test As method
    my $as_args = $args->As('System::EventArgs');
    is($as_args, $args, 'As EventArgs returns same object');
    
    my $as_obj = $args->As('System::Object');
    is($as_obj, $args, 'As Object returns same object');
    
    my $as_str = $args->As('System::String');
    ok(!defined($as_str), 'As String returns undef for incompatible type');
    
    # Test Empty instance type checking
    my $empty = System::EventArgs->Empty();
    ok($empty->Is('System::EventArgs'), 'Empty instance Is System::EventArgs');
    ok($empty->Is('System::Object'), 'Empty instance Is System::Object');
    
    my $empty_as_args = $empty->As('System::EventArgs');
    is($empty_as_args, $empty, 'Empty As EventArgs returns same instance');
}

sub test_eventargs_with_events {
    # Test EventArgs usage with events (basic integration test)
    my $event_fired = 0;
    my $received_args = undef;
    
    # Simulate an event handler that receives EventArgs
    my $handler = sub {
        my ($sender, $args) = @_;
        $event_fired++;
        $received_args = $args;
    };
    
    # Test with regular EventArgs
    my $args = System::EventArgs->new();
    $handler->("sender", $args);
    
    is($event_fired, 1, 'Event handler called');
    is($received_args, $args, 'Event handler received EventArgs correctly');
    isa_ok($received_args, 'System::EventArgs', 'Received args is EventArgs type');
    
    # Test with Empty EventArgs
    $event_fired = 0;
    $received_args = undef;
    
    my $empty_args = System::EventArgs->Empty();
    $handler->("sender", $empty_args);
    
    is($event_fired, 1, 'Event handler called with Empty args');
    is($received_args, $empty_args, 'Event handler received Empty EventArgs correctly');
    isa_ok($received_args, 'System::EventArgs', 'Received Empty args is EventArgs type');
}

sub test_eventargs_derived_classes {
    # Test creating a derived EventArgs class
    package CustomEventArgs;
    use base 'System::EventArgs';
    
    sub new {
        my ($class, $data) = @_;
        my $this = $class->SUPER::new();
        $this->{Data} = $data;
        return $this;
    }
    
    sub GetData {
        my ($this) = @_;
        return $this->{Data};
    }
    
    package main;
    
    # Test custom EventArgs
    my $custom = CustomEventArgs->new("test_data");
    isa_ok($custom, 'CustomEventArgs', 'Custom EventArgs created');
    isa_ok($custom, 'System::EventArgs', 'Custom EventArgs inherits from EventArgs');
    isa_ok($custom, 'System::Object', 'Custom EventArgs inherits from Object');
    
    # Test custom functionality
    is($custom->GetData(), "test_data", 'Custom EventArgs data property works');
    
    # Test inheritance methods still work
    ok(defined($custom->ToString()), 'Custom EventArgs ToString works');
    ok(defined($custom->GetHashCode()), 'Custom EventArgs GetHashCode works');
    ok($custom->Equals($custom), 'Custom EventArgs equals itself');
    
    # Test type checking
    ok($custom->Is('CustomEventArgs'), 'Custom EventArgs Is CustomEventArgs');
    ok($custom->Is('System::EventArgs'), 'Custom EventArgs Is System::EventArgs');
    ok($custom->Is('System::Object'), 'Custom EventArgs Is System::Object');
    
    # Test usage with events
    my $custom_received = undef;
    my $custom_handler = sub {
        my ($sender, $args) = @_;
        $custom_received = $args;
    };
    
    $custom_handler->("sender", $custom);
    is($custom_received, $custom, 'Custom EventArgs works with event handlers');
    is($custom_received->GetData(), "test_data", 'Custom data preserved through event');
}

sub test_eventargs_edge_cases {
    # Test various edge cases
    
    # Test creating many EventArgs instances
    my @args_list = ();
    for my $i (1..100) {
        push @args_list, System::EventArgs->new();
    }
    
    # Verify all instances are valid and different
    for my $i (0..4) {  # Test first 5
        my $args = $args_list[$i];
        isa_ok($args, 'System::EventArgs', "EventArgs instance $i is valid");
        ok(defined($args->ToString()), "EventArgs instance $i ToString works");
        ok(defined($args->GetHashCode()), "EventArgs instance $i GetHashCode works");
    }
    
    # Test all instances are different
    for my $i (0..4) {
        for my $j ($i+1..9) {
            last if $j >= @args_list;
            isnt($args_list[$i], $args_list[$j], "EventArgs instances $i and $j are different") if ($i < 2 && $j < 4);
        }
    }
    
    # Test Empty instance consistency over time
    my $empty_initial = System::EventArgs->Empty();
    
    # Create many regular instances
    for (1..50) {
        System::EventArgs->new();
    }
    
    # Empty should still be the same
    my $empty_later = System::EventArgs->Empty();
    is($empty_initial, $empty_later, 'Empty instance remains consistent after creating other instances');
    
    # Test Empty instance after clearing reference
    undef $empty_initial;
    my $empty_after_undef = System::EventArgs->Empty();
    is($empty_later, $empty_after_undef, 'Empty instance survives reference clearing');
}

sub test_eventargs_memory_management {
    # Test memory management and cleanup
    my @refs = ();
    
    # Create and store references to many EventArgs
    for my $i (1..50) {
        my $args = System::EventArgs->new();
        push @refs, $args;
    }
    
    # Test all references are valid
    for my $i (0..2) {  # Test first 3
        my $args = $refs[$i];
        ok(defined($args), "Reference $i is defined");
        isa_ok($args, 'System::EventArgs', "Reference $i is EventArgs");
        ok(defined($args->GetHashCode()), "Reference $i GetHashCode works");
    }
    
    # Clear half the references
    for my $i (0..24) {
        $refs[$i] = undef;
    }
    
    # Test remaining references still work
    for my $i (25..27) {  # Test a few remaining
        my $args = $refs[$i];
        ok(defined($args), "Remaining reference $i is still defined");
        isa_ok($args, 'System::EventArgs', "Remaining reference $i is still EventArgs");
    }
    
    # Clear all references
    @refs = ();
    
    # Test Empty instance still works after cleanup
    my $empty = System::EventArgs->Empty();
    isa_ok($empty, 'System::EventArgs', 'Empty instance works after cleanup');
    ok(defined($empty->ToString()), 'Empty instance ToString works after cleanup');
    
    ok(1, 'Memory management test completed successfully');
}

sub test_eventargs_error_conditions {
    # Test various error conditions
    
    # EventArgs constructor should not fail with any reasonable input
    eval {
        my $args = System::EventArgs->new();
        ok(defined($args), 'Basic constructor succeeds');
    };
    ok(!$@, 'No exception thrown by basic constructor');
    
    # Empty method should not fail
    eval {
        my $empty = System::EventArgs->Empty();
        ok(defined($empty), 'Empty method succeeds');
    };
    ok(!$@, 'No exception thrown by Empty method');
    
    # Test inherited Object methods with edge cases
    my $args = System::EventArgs->new();
    
    eval {
        # These should not throw exceptions
        my $str = $args->ToString();
        my $hash = $args->GetHashCode();
        my $equals_self = $args->Equals($args);
        my $equals_null = $args->Equals(undef);
        my $is_args = $args->Is('System::EventArgs');
        my $as_args = $args->As('System::EventArgs');
    };
    ok(!$@, 'Object methods do not throw exceptions with normal usage');
    
    # Test potential issues with Empty singleton
    eval {
        my $empty1 = System::EventArgs->Empty();
        my $empty2 = System::EventArgs->Empty();
        
        # These operations should not break the singleton
        $empty1->ToString();
        $empty1->GetHashCode();
        $empty1->Equals($empty2);
    };
    ok(!$@, 'Empty singleton remains stable under normal operations');
}

# Run all comprehensive EventArgs tests
test_eventargs_creation();
test_eventargs_empty_instance();
test_eventargs_inheritance();
test_eventargs_object_methods();
test_eventargs_type_checking();
test_eventargs_with_events();
test_eventargs_derived_classes();
test_eventargs_edge_cases();
test_eventargs_memory_management();
test_eventargs_error_conditions();

done_testing();