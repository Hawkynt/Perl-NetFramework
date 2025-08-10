#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More tests => 30;

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import required modules
require System::ComponentModel::ProgressChangedEventArgs;
require System::Exceptions;

# Test 1-5: Basic construction and inheritance
{
    my $args = System::ComponentModel::ProgressChangedEventArgs->new(50, 'user_state');
    isa_ok($args, 'System::ComponentModel::ProgressChangedEventArgs', 'ProgressChangedEventArgs construction');
    isa_ok($args, 'System::EventArgs', 'ProgressChangedEventArgs inherits from EventArgs');
    can_ok($args, 'ProgressPercentage');
    can_ok($args, 'UserState');
    is($args->ProgressPercentage(), 50, 'ProgressPercentage set correctly');
}

# Test 6-10: ProgressPercentage property validation
{
    # Test valid percentage values
    my $args1 = System::ComponentModel::ProgressChangedEventArgs->new(0, undef);
    is($args1->ProgressPercentage(), 0, 'Minimum valid progress percentage (0)');
    
    my $args2 = System::ComponentModel::ProgressChangedEventArgs->new(100, undef);
    is($args2->ProgressPercentage(), 100, 'Maximum valid progress percentage (100)');
    
    my $args3 = System::ComponentModel::ProgressChangedEventArgs->new(50, undef);
    is($args3->ProgressPercentage(), 50, 'Mid-range progress percentage');
    
    # Test default value when undef/null provided
    my $args4 = System::ComponentModel::ProgressChangedEventArgs->new(undef, undef);
    is($args4->ProgressPercentage(), 0, 'Progress percentage defaults to 0 when undefined');
}

# Test 11-15: ProgressPercentage range validation and exceptions
{
    # Test negative percentage throws exception
    eval {
        my $args = System::ComponentModel::ProgressChangedEventArgs->new(-1, undef);
    };
    like($@, qr/ArgumentOutOfRangeException/, 'Negative progress percentage throws ArgumentOutOfRangeException');
    
    # Test percentage over 100 throws exception
    eval {
        my $args = System::ComponentModel::ProgressChangedEventArgs->new(101, undef);
    };
    like($@, qr/ArgumentOutOfRangeException/, 'Progress percentage over 100 throws ArgumentOutOfRangeException');
    
    # Test large negative value
    eval {
        my $args = System::ComponentModel::ProgressChangedEventArgs->new(-999, undef);
    };
    like($@, qr/ArgumentOutOfRangeException/, 'Large negative progress percentage throws exception');
    
    # Test large positive value
    eval {
        my $args = System::ComponentModel::ProgressChangedEventArgs->new(999, undef);
    };
    like($@, qr/ArgumentOutOfRangeException/, 'Large positive progress percentage throws exception');
}

# Test 16-20: UserState property handling
{
    # Test with string user state
    my $args1 = System::ComponentModel::ProgressChangedEventArgs->new(25, 'downloading_file.txt');
    is($args1->UserState(), 'downloading_file.txt', 'String user state preserved');
    
    # Test with numeric user state
    my $args2 = System::ComponentModel::ProgressChangedEventArgs->new(75, 42);
    is($args2->UserState(), 42, 'Numeric user state preserved');
    
    # Test with object user state
    my $object_state = { file => 'data.zip', size => 1024, downloaded => 256 };
    my $args3 = System::ComponentModel::ProgressChangedEventArgs->new(25, $object_state);
    is_deeply($args3->UserState(), $object_state, 'Object user state preserved');
    
    # Test with array user state
    my $array_state = ['file1.txt', 'file2.txt', 'file3.txt'];
    my $args4 = System::ComponentModel::ProgressChangedEventArgs->new(33, $array_state);
    is_deeply($args4->UserState(), $array_state, 'Array user state preserved');
    
    # Test with null user state
    my $args5 = System::ComponentModel::ProgressChangedEventArgs->new(90, undef);
    ok(!defined($args5->UserState()), 'Null user state handled correctly');
}

# Test 21-25: Property getter behavior and consistency
{
    my $args = System::ComponentModel::ProgressChangedEventArgs->new(67, 'persistent_state');
    
    # Test multiple calls return same values
    my $progress1 = $args->ProgressPercentage();
    my $progress2 = $args->ProgressPercentage();
    is($progress1, $progress2, 'ProgressPercentage returns consistent value');
    
    my $state1 = $args->UserState();
    my $state2 = $args->UserState();
    is($state1, $state2, 'UserState returns consistent value');
    
    # Test values remain unchanged
    is($args->ProgressPercentage(), 67, 'ProgressPercentage value unchanged');
    is($args->UserState(), 'persistent_state', 'UserState value unchanged');
}

# Test 26-30: Null reference exceptions and usage scenarios
{
    # Test null reference exception on undefined object
    eval {
        my $null_args = undef;
        $null_args->ProgressPercentage();
    };
    like($@, qr/NullReferenceException/, 'ProgressPercentage throws NullReferenceException on null object');
    
    eval {
        my $null_args = undef;
        $null_args->UserState();
    };
    like($@, qr/NullReferenceException/, 'UserState throws NullReferenceException on null object');
    
    # Test typical progress reporting scenario
    my @progress_events = ();
    
    my $simulate_progress_event = sub {
        my ($percentage, $message) = @_;
        my $args = System::ComponentModel::ProgressChangedEventArgs->new($percentage, $message);
        push @progress_events, {
            percentage => $args->ProgressPercentage(),
            message => $args->UserState(),
            timestamp => time()
        };
        return $args;
    };
    
    # Simulate file download progress
    $simulate_progress_event->(0, 'Starting download...');
    $simulate_progress_event->(25, 'Downloaded 250KB of 1MB');
    $simulate_progress_event->(50, 'Downloaded 500KB of 1MB');
    $simulate_progress_event->(75, 'Downloaded 750KB of 1MB');
    $simulate_progress_event->(100, 'Download complete');
    
    is(scalar(@progress_events), 5, 'All progress events recorded');
    is($progress_events[0]->{percentage}, 0, 'First progress event correct');
    is($progress_events[4]->{percentage}, 100, 'Last progress event correct');
    is($progress_events[2]->{message}, 'Downloaded 500KB of 1MB', 'Middle progress message correct');
    
    # Test edge case with complex user state
    my $complex_state = {
        operation_type => 'file_transfer',
        total_files => 10,
        current_file => 3,
        current_file_progress => 67,
        overall_progress => 23
    };
    
    my $complex_args = System::ComponentModel::ProgressChangedEventArgs->new(23, $complex_state);
    is_deeply($complex_args->UserState(), $complex_state, 'Complex user state preserved in progress event');
}

done_testing();