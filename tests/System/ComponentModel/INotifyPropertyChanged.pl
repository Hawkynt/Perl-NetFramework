#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More tests => 30;

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import required modules
require System::ComponentModel::INotifyPropertyChanged;
require System::ComponentModel::PropertyChangedEventArgs;
require System::Exceptions;

# Test 1-5: Interface definition and contract
{
    can_ok('System::ComponentModel::INotifyPropertyChanged', 'PropertyChanged');
    
    # Test that interface method throws NotImplementedException
    eval {
        System::ComponentModel::INotifyPropertyChanged->PropertyChanged();
    };
    like($@, qr/NotImplementedException/, 'PropertyChanged interface method throws NotImplementedException');
}

# Test 6-15: Mock implementation of the interface
{
    package TestNotifyPropertyChanged;
    use base 'System::ComponentModel::INotifyPropertyChanged';
    require System::Event;
    require System::ComponentModel::PropertyChangedEventArgs;
    
    sub new {
        my $class = shift;
        my $self = bless {
            _propertyChanged => System::Event->new(),
            _name => 'DefaultName',
            _value => 0,
        }, $class;
        return $self;
    }
    
    sub PropertyChanged {
        my ($this, $handler) = @_;
        throw(System::NullReferenceException->new()) unless defined($this);
        
        if (defined($handler)) {
            return $this->{_propertyChanged}->AddHandler($handler);
        }
        return $this->{_propertyChanged};
    }
    
    sub OnPropertyChanged {
        my ($this, $propertyName) = @_;
        my $args = System::ComponentModel::PropertyChangedEventArgs->new($propertyName);
        if ($this->{_propertyChanged}->HasHandlers()) {
            $this->{_propertyChanged}->Invoke($this, $args);
        }
    }
    
    sub Name {
        my ($this, $value) = @_;
        if (defined($value)) {
            if ($this->{_name} ne $value) {
                $this->{_name} = $value;
                $this->OnPropertyChanged('Name');
            }
            return;
        }
        return $this->{_name};
    }
    
    sub Value {
        my ($this, $value) = @_;
        if (defined($value)) {
            if ($this->{_value} != $value) {
                $this->{_value} = $value;
                $this->OnPropertyChanged('Value');
            }
            return;
        }
        return $this->{_value};
    }
    
    package main;
    
    # Test the mock implementation
    my $obj = TestNotifyPropertyChanged->new();
    isa_ok($obj, 'System::ComponentModel::INotifyPropertyChanged', 'Mock object implements interface');
    isa_ok($obj, 'TestNotifyPropertyChanged', 'Mock object has correct type');
    can_ok($obj, 'PropertyChanged');
    can_ok($obj, 'Name');
    can_ok($obj, 'Value');
    
    # Test that PropertyChanged returns an Event object
    my $event = $obj->PropertyChanged();
    ok(defined($event), 'PropertyChanged returns defined event object');
    can_ok($event, 'AddHandler');
    can_ok($event, 'HasHandlers');
    can_ok($event, 'Invoke');
}

# Test 16-25: Event subscription and notification
{
    my $obj = TestNotifyPropertyChanged->new();
    my $event_count = 0;
    my $last_property_name = '';
    my $last_sender = undef;
    
    # Subscribe to PropertyChanged event
    my $handler = sub {
        my ($sender, $e) = @_;
        $event_count++;
        $last_sender = $sender;
        $last_property_name = $e->PropertyName() if $e;
    };
    
    $obj->PropertyChanged($handler);
    
    # Test property change notification
    is($obj->Name(), 'DefaultName', 'Initial Name value correct');
    is($event_count, 0, 'No events fired initially');
    
    $obj->Name('NewName');
    is($event_count, 1, 'Event fired after Name change');
    is($last_property_name, 'Name', 'Correct property name in event args');
    is($last_sender, $obj, 'Correct sender in event');
    is($obj->Name(), 'NewName', 'Name value updated correctly');
    
    # Test no event fired for same value
    $obj->Name('NewName');
    is($event_count, 1, 'No event fired for same value');
    
    # Test Value property change
    $obj->Value(42);
    is($event_count, 2, 'Event fired after Value change');
    is($last_property_name, 'Value', 'Correct property name for Value');
    is($obj->Value(), 42, 'Value updated correctly');
}

# Test 26-30: Multiple subscribers and edge cases
{
    my $obj = TestNotifyPropertyChanged->new();
    my $event_count_1 = 0;
    my $event_count_2 = 0;
    
    # Multiple event handlers
    my $handler1 = sub { $event_count_1++; };
    my $handler2 = sub { $event_count_2++; };
    
    $obj->PropertyChanged($handler1);
    $obj->PropertyChanged($handler2);
    
    $obj->Name('MultiSubscriber');
    is($event_count_1, 1, 'First handler called');
    is($event_count_2, 1, 'Second handler called');
    
    # Test PropertyChangedEventArgs with null property name
    my $null_event_count = 0;
    my $null_property_name = 'NOT_NULL';
    
    my $null_handler = sub {
        my ($sender, $e) = @_;
        $null_event_count++;
        $null_property_name = $e->PropertyName() if $e;
    };
    
    my $test_obj = TestNotifyPropertyChanged->new();
    $test_obj->PropertyChanged($null_handler);
    $test_obj->OnPropertyChanged(undef);  # Simulate all properties changed
    
    is($null_event_count, 1, 'Event fired for null property name');
    ok(!defined($null_property_name), 'Property name is null for all properties changed');
    
    # Test exception on null object
    eval {
        my $null_obj = undef;
        $null_obj->PropertyChanged($handler1);
    };
    like($@, qr/NullReferenceException/, 'PropertyChanged throws NullReferenceException on null object');
}

done_testing();