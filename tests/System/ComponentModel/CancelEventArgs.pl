#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More tests => 25;

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import required modules
require System::ComponentModel::CancelEventArgs;
require System::Exceptions;

# Test 1-5: Basic construction and default values
{
    my $args = System::ComponentModel::CancelEventArgs->new();
    isa_ok($args, 'System::ComponentModel::CancelEventArgs', 'Default construction creates CancelEventArgs');
    isa_ok($args, 'System::EventArgs', 'CancelEventArgs inherits from EventArgs');
    ok(!$args->Cancel(), 'Cancel defaults to false');
    can_ok($args, 'Cancel');
}

# Test 6-10: Construction with explicit cancel value
{
    my $args_false = System::ComponentModel::CancelEventArgs->new(false);
    ok(!$args_false->Cancel(), 'Construction with explicit false');
    
    my $args_true = System::ComponentModel::CancelEventArgs->new(true);
    ok($args_true->Cancel(), 'Construction with explicit true');
    
    my $args_zero = System::ComponentModel::CancelEventArgs->new(0);
    ok(!$args_zero->Cancel(), 'Construction with 0 evaluates to false');
    
    my $args_one = System::ComponentModel::CancelEventArgs->new(1);
    ok($args_one->Cancel(), 'Construction with 1 evaluates to true');
}

# Test 11-15: Cancel property getter and setter
{
    my $args = System::ComponentModel::CancelEventArgs->new();
    
    # Test setter with various values
    $args->Cancel(true);
    ok($args->Cancel(), 'Cancel setter with true');
    
    $args->Cancel(false);
    ok(!$args->Cancel(), 'Cancel setter with false');
    
    $args->Cancel(1);
    ok($args->Cancel(), 'Cancel setter with 1');
    
    $args->Cancel(0);
    ok(!$args->Cancel(), 'Cancel setter with 0');
    
    $args->Cancel('true');
    ok($args->Cancel(), 'Cancel setter with string "true"');
}

# Test 16-20: Exception handling for invalid inputs
{
    # Test invalid constructor argument
    eval {
        my $args = System::ComponentModel::CancelEventArgs->new('invalid');
    };
    like($@, qr/ArgumentException/, 'Constructor throws ArgumentException for invalid boolean');
    
    # Test invalid setter argument
    my $args = System::ComponentModel::CancelEventArgs->new();
    eval {
        $args->Cancel('invalid');
    };
    like($@, qr/ArgumentException/, 'Cancel setter throws ArgumentException for invalid boolean');
    
    # Test null reference on undefined object
    eval {
        my $null_args = undef;
        $null_args->Cancel();
    };
    like($@, qr/undefined value/, 'Cancel getter throws error on null object');
    
    eval {
        my $null_args = undef;
        $null_args->Cancel(true);
    };
    like($@, qr/undefined value/, 'Cancel setter throws error on null object');
}

# Test 21-25: Event usage scenarios and edge cases
{
    # Simulate typical event handler usage
    my $event_fired = 0;
    my $was_cancelled = 0;
    
    my $simulate_cancelable_event = sub {
        my $args = System::ComponentModel::CancelEventArgs->new();
        
        # Simulate event handler that might cancel
        $event_fired++;
        if ($event_fired == 2) {  # Cancel on second call
            $args->Cancel(true);
        }
        
        $was_cancelled = $args->Cancel();
        return $args;
    };
    
    # First call - should not be cancelled
    my $result1 = $simulate_cancelable_event->();
    ok($event_fired == 1, 'Event simulation called once');
    ok(!$was_cancelled, 'First event not cancelled');
    
    # Second call - should be cancelled
    my $result2 = $simulate_cancelable_event->();
    ok($event_fired == 2, 'Event simulation called twice');
    ok($was_cancelled, 'Second event cancelled');
    
    # Test that changes persist
    ok($result2->Cancel(), 'Cancel state persists in returned object');
}

done_testing();