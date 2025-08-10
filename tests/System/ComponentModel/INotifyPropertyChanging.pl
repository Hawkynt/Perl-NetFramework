#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More tests => 35;

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import required modules
require System::ComponentModel::INotifyPropertyChanging;
require System::ComponentModel::PropertyChangingEventArgs;
require System::ComponentModel::CancelEventArgs;
require System::Exceptions;

# Test 1-5: Interface definition and contract
{
    can_ok('System::ComponentModel::INotifyPropertyChanging', 'PropertyChanging');
    
    # Test that interface method throws NotImplementedException
    eval {
        System::ComponentModel::INotifyPropertyChanging->PropertyChanging();
    };
    like($@, qr/NotImplementedException/, 'PropertyChanging interface method throws NotImplementedException');
}

# Test 6-15: Mock implementation of the interface with cancellation support
{
    package TestNotifyPropertyChanging;
    use base 'System::ComponentModel::INotifyPropertyChanging';
    require System::Event;
    require System::ComponentModel::PropertyChangingEventArgs;
    
    sub new {
        my $class = shift;
        my $self = bless {
            _propertyChanging => System::Event->new(),
            _name => 'DefaultName',
            _value => 0,
            _readOnly => false,
        }, $class;
        return $self;
    }
    
    sub PropertyChanging {
        my ($this, $handler) = @_;
        throw(System::NullReferenceException->new()) unless defined($this);
        
        if (defined($handler)) {
            return $this->{_propertyChanging}->AddHandler($handler);
        }
        return $this->{_propertyChanging};
    }
    
    sub OnPropertyChanging {
        my ($this, $propertyName) = @_;
        my $args = System::ComponentModel::PropertyChangingEventArgs->new($propertyName);
        if ($this->{_propertyChanging}->HasHandlers()) {
            $this->{_propertyChanging}->Invoke($this, $args);
        }
        return !$args->Cancel();  # Return false if cancelled
    }
    
    sub Name {
        my ($this, $value) = @_;
        if (defined($value)) {
            if ($this->{_name} ne $value) {
                # Notify before change - can be cancelled
                return unless $this->OnPropertyChanging('Name');
                $this->{_name} = $value;
            }
            return;
        }
        return $this->{_name};
    }
    
    sub Value {
        my ($this, $value) = @_;
        if (defined($value)) {
            if ($this->{_value} != $value) {
                # Notify before change - can be cancelled
                return unless $this->OnPropertyChanging('Value');
                $this->{_value} = $value;
            }
            return;
        }
        return $this->{_value};
    }
    
    sub ReadOnly {
        my ($this, $value) = @_;
        if (defined($value)) {
            $this->{_readOnly} = $value ? true : false;
            return;
        }
        return $this->{_readOnly};
    }
    
    package main;
    
    # Test the mock implementation
    my $obj = TestNotifyPropertyChanging->new();
    isa_ok($obj, 'System::ComponentModel::INotifyPropertyChanging', 'Mock object implements interface');
    isa_ok($obj, 'TestNotifyPropertyChanging', 'Mock object has correct type');
    can_ok($obj, 'PropertyChanging');
    can_ok($obj, 'Name');
    can_ok($obj, 'Value');
    
    # Test that PropertyChanging returns an Event object
    my $event = $obj->PropertyChanging();
    ok(defined($event), 'PropertyChanging returns defined event object');
    can_ok($event, 'AddHandler');
    can_ok($event, 'HasHandlers');
    can_ok($event, 'Invoke');
}

# Test 16-25: Event subscription and notification
{
    my $obj = TestNotifyPropertyChanging->new();
    my $event_count = 0;
    my $last_property_name = '';
    my $last_sender = undef;
    
    # Subscribe to PropertyChanging event
    my $handler = sub {
        my ($sender, $e) = @_;
        $event_count++;
        $last_sender = $sender;
        $last_property_name = $e->PropertyName() if $e;
    };
    
    $obj->PropertyChanging($handler);
    
    # Test property changing notification
    is($obj->Name(), 'DefaultName', 'Initial Name value correct');
    is($event_count, 0, 'No events fired initially');
    
    $obj->Name('NewName');
    is($event_count, 1, 'Event fired before Name change');
    is($last_property_name, 'Name', 'Correct property name in event args');
    is($last_sender, $obj, 'Correct sender in event');
    is($obj->Name(), 'NewName', 'Name value updated after event');
    
    # Test no event fired for same value
    $obj->Name('NewName');
    is($event_count, 1, 'No event fired for same value');
    
    # Test Value property changing
    $obj->Value(42);
    is($event_count, 2, 'Event fired before Value change');
    is($last_property_name, 'Value', 'Correct property name for Value');
    is($obj->Value(), 42, 'Value updated correctly');
}

# Test 26-30: Cancellation scenarios
{
    my $obj = TestNotifyPropertyChanging->new();
    my $cancel_count = 0;
    
    # Handler that cancels certain changes
    my $cancelling_handler = sub {
        my ($sender, $e) = @_;
        $cancel_count++;
        
        # Cancel changes to "CancelThis" value
        if (defined($e) && defined($e->PropertyName())) {
            if ($e->PropertyName() eq 'Name' && $cancel_count > 1) {
                $e->Cancel(true);
            }
        }
    };
    
    $obj->PropertyChanging($cancelling_handler);
    
    # First change should succeed
    $obj->Name('FirstChange');
    is($cancel_count, 1, 'First change fired event');
    is($obj->Name(), 'FirstChange', 'First change succeeded');
    
    # Second change should be cancelled
    $obj->Name('CancelThis');
    is($cancel_count, 2, 'Second change fired event');
    is($obj->Name(), 'FirstChange', 'Second change was cancelled - value unchanged');
}

# Test 31-35: Multiple subscribers and edge cases
{
    my $obj = TestNotifyPropertyChanging->new();
    my $event_count_1 = 0;
    my $event_count_2 = 0;
    my $cancelled_by_first = false;
    
    # Multiple event handlers - first one cancels
    my $handler1 = sub {
        my ($sender, $e) = @_;
        $event_count_1++;
        if ($event_count_1 == 2) {  # Cancel on second call
            $e->Cancel(true);
            $cancelled_by_first = true;
        }
    };
    
    my $handler2 = sub {
        my ($sender, $e) = @_;
        $event_count_2++;
    };
    
    $obj->PropertyChanging($handler1);
    $obj->PropertyChanging($handler2);
    
    # First change - should succeed
    $obj->Name('MultiSubscriber1');
    is($event_count_1, 1, 'First handler called for first change');
    is($event_count_2, 1, 'Second handler called for first change');
    is($obj->Name(), 'MultiSubscriber1', 'First change succeeded');
    
    # Second change - should be cancelled by first handler
    $obj->Name('MultiSubscriber2');
    is($event_count_1, 2, 'First handler called for second change');
    is($event_count_2, 2, 'Second handler called for second change');
    ok($cancelled_by_first, 'First handler cancelled the change');
    is($obj->Name(), 'MultiSubscriber1', 'Second change was cancelled');
    
    # Test PropertyChangingEventArgs with null property name
    my $null_event_count = 0;
    my $null_property_name = 'NOT_NULL';
    
    my $null_handler = sub {
        my ($sender, $e) = @_;
        $null_event_count++;
        $null_property_name = $e->PropertyName() if $e;
    };
    
    my $test_obj = TestNotifyPropertyChanging->new();
    $test_obj->PropertyChanging($null_handler);
    $test_obj->OnPropertyChanging(undef);  # Simulate all properties changing
    
    is($null_event_count, 1, 'Event fired for null property name');
    ok(!defined($null_property_name), 'Property name is null for all properties changing');
    
    # Test exception on null object
    eval {
        my $null_obj = undef;
        $null_obj->PropertyChanging($handler1);
    };
    like($@, qr/NullReferenceException/, 'PropertyChanging throws NullReferenceException on null object');
}

done_testing();