#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More tests => 30;

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import required modules
require System::ComponentModel::PropertyChangingEventArgs;
require System::ComponentModel::CancelEventArgs;
require System::String;
require System::Exceptions;

# Test 1-5: Basic construction and inheritance
{
    my $args = System::ComponentModel::PropertyChangingEventArgs->new('TestProperty');
    isa_ok($args, 'System::ComponentModel::PropertyChangingEventArgs', 'PropertyChangingEventArgs construction');
    isa_ok($args, 'System::ComponentModel::CancelEventArgs', 'PropertyChangingEventArgs inherits from CancelEventArgs');
    isa_ok($args, 'System::EventArgs', 'PropertyChangingEventArgs inherits from EventArgs');
    can_ok($args, 'PropertyName');
    can_ok($args, 'Cancel');
}

# Test 6-10: Property name handling
{
    # Test with regular string
    my $args1 = System::ComponentModel::PropertyChangingEventArgs->new('StringProperty');
    is($args1->PropertyName(), 'StringProperty', 'Regular string property name');
    ok(!$args1->Cancel(), 'Cancel defaults to false');
    
    # Test with empty string
    my $args2 = System::ComponentModel::PropertyChangingEventArgs->new('');
    is($args2->PropertyName(), '', 'Empty string property name');
    
    # Test with null/undef (indicates all properties changing)
    my $args3 = System::ComponentModel::PropertyChangingEventArgs->new(undef);
    ok(!defined($args3->PropertyName()), 'Null property name for all properties changing');
    
    # Test with System::String object
    my $string_obj = System::String->new('SystemStringProperty');
    my $args4 = System::ComponentModel::PropertyChangingEventArgs->new($string_obj);
    is($args4->PropertyName(), $string_obj, 'System::String property name accepted');
}

# Test 11-15: Cancel functionality inherited from CancelEventArgs
{
    my $args = System::ComponentModel::PropertyChangingEventArgs->new('CancelTest');
    
    # Test default cancel state
    ok(!$args->Cancel(), 'Cancel defaults to false');
    is($args->PropertyName(), 'CancelTest', 'PropertyName preserved');
    
    # Test setting cancel to true
    $args->Cancel(true);
    ok($args->Cancel(), 'Cancel set to true');
    is($args->PropertyName(), 'CancelTest', 'PropertyName still accessible after cancel');
    
    # Test setting cancel back to false
    $args->Cancel(false);
    ok(!$args->Cancel(), 'Cancel set back to false');
}

# Test 16-20: PropertyName getter behavior
{
    # Test PropertyName is read-only
    my $args = System::ComponentModel::PropertyChangingEventArgs->new('ReadOnlyTest');
    is($args->PropertyName(), 'ReadOnlyTest', 'PropertyName getter works');
    
    # Test multiple calls return same value
    my $name1 = $args->PropertyName();
    my $name2 = $args->PropertyName();
    is($name1, $name2, 'PropertyName returns consistent value');
    
    # Test with special characters in property name
    my $special_args = System::ComponentModel::PropertyChangingEventArgs->new('Property.With.Dots');
    is($special_args->PropertyName(), 'Property.With.Dots', 'Property name with special characters');
    
    my $unicode_args = System::ComponentModel::PropertyChangingEventArgs->new('PropertyWithUnicode_测试');
    is($unicode_args->PropertyName(), 'PropertyWithUnicode_测试', 'Property name with Unicode characters');
}

# Test 21-25: Exception handling
{
    # Test null reference exception on undefined object
    eval {
        my $null_args = undef;
        $null_args->PropertyName();
    };
    like($@, qr/NullReferenceException/, 'PropertyName throws NullReferenceException on null object');
    
    eval {
        my $null_args = undef;
        $null_args->Cancel();
    };
    like($@, qr/NullReferenceException/, 'Cancel getter throws NullReferenceException on null object');
    
    eval {
        my $null_args = undef;
        $null_args->Cancel(true);
    };
    like($@, qr/NullReferenceException/, 'Cancel setter throws NullReferenceException on null object');
    
    # Test invalid property name type
    eval {
        my $args = System::ComponentModel::PropertyChangingEventArgs->new(['array_ref']);
    };
    like($@, qr/ArgumentException/, 'Constructor throws ArgumentException for array reference');
    
    # Test invalid cancel value
    my $args = System::ComponentModel::PropertyChangingEventArgs->new('TestProperty');
    eval {
        $args->Cancel('invalid_boolean');
    };
    like($@, qr/ArgumentException/, 'Cancel setter throws ArgumentException for invalid boolean');
}

# Test 26-30: Common usage scenarios and cancellation patterns
{
    # Simulate property changing event with cancellation
    my $change_attempts = 0;
    my $cancelled_changes = 0;
    my $successful_changes = 0;
    
    my $simulate_property_changing = sub {
        my ($property_name, $should_cancel) = @_;
        my $args = System::ComponentModel::PropertyChangingEventArgs->new($property_name);
        $change_attempts++;
        
        # Simulate event handler that might cancel
        if ($should_cancel) {
            $args->Cancel(true);
            $cancelled_changes++;
        } else {
            $successful_changes++;
        }
        
        return $args;
    };
    
    # Test various scenarios
    my $result1 = $simulate_property_changing->('Name', false);
    ok(!$result1->Cancel(), 'First change not cancelled');
    is($result1->PropertyName(), 'Name', 'Property name preserved');
    
    my $result2 = $simulate_property_changing->('Value', true);
    ok($result2->Cancel(), 'Second change cancelled');
    is($result2->PropertyName(), 'Value', 'Property name preserved even when cancelled');
    
    my $result3 = $simulate_property_changing->(undef, false);
    ok(!$result3->Cancel(), 'All properties change not cancelled');
    ok(!defined($result3->PropertyName()), 'Null property name handled correctly');
    
    is($change_attempts, 3, 'All change attempts recorded');
    is($cancelled_changes, 1, 'Correct number of cancelled changes');
    is($successful_changes, 2, 'Correct number of successful changes');
    
    # Test cancellation state persistence
    my $persistent_args = System::ComponentModel::PropertyChangingEventArgs->new('PersistentTest');
    $persistent_args->Cancel(true);
    
    # Pass through a subroutine
    my $check_cancellation = sub {
        my ($event_args) = @_;
        return $event_args->Cancel();
    };
    
    my $is_cancelled = $check_cancellation->($persistent_args);
    ok($is_cancelled, 'Cancellation state preserved through subroutine call');
}

done_testing();