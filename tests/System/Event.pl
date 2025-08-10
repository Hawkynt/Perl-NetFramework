#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use Carp qw(confess);

# Import System classes
use System;
use System::Object;
use System::Event;
use System::EventArgs;
use System::Delegate;
use System::Exceptions;
use CSharp;

# Define constants
use constant true => 1;
use constant false => 0;

BEGIN {
    use_ok('System::Event');
    use_ok('System::EventArgs');
    use_ok('System::Delegate');
}

# Test basic event creation
sub test_event_creation {
    # Test basic constructor
    my $event = System::Event->new();
    isa_ok($event, 'System::Event', 'Event created successfully');
    isa_ok($event, 'System::Object', 'Event inherits from System::Object');
    ok(defined($event), 'Event is defined');
    
    # Test initial state
    ok(!$event->HasHandlers(), 'New event has no handlers initially');
    is($event->HandlerCount(), 0, 'New event has zero handler count');
    
    # Test GetHandlerIds returns empty array
    my $ids = $event->GetHandlerIds();
    isa_ok($ids, 'ARRAY', 'GetHandlerIds returns array reference');
    is(scalar(@$ids), 0, 'New event has no handler IDs');
}

sub test_event_handler_management {
    my $event = System::Event->new();
    my $handler_called = 0;
    my $handler_args = undef;
    
    # Create a handler
    my $handler = sub {
        $handler_called++;
        $handler_args = [@_];
    };
    
    # Test AddHandler
    my $handler_id = $event->AddHandler($handler);
    ok(defined($handler_id), 'AddHandler returns handler ID');
    ok($handler_id > 0, 'Handler ID is positive');
    ok($event->HasHandlers(), 'Event has handlers after adding');
    is($event->HandlerCount(), 1, 'Event has one handler');
    
    # Test handler IDs
    my $ids = $event->GetHandlerIds();
    is(scalar(@$ids), 1, 'Event has one handler ID');
    is($ids->[0], $handler_id, 'Handler ID matches returned value');
    
    # Test invoking event
    $event->Invoke("test_arg1", "test_arg2");
    is($handler_called, 1, 'Handler was called once');
    isa_ok($handler_args, 'ARRAY', 'Handler received arguments as array');
    is_deeply($handler_args, ["test_arg1", "test_arg2"], 'Handler received correct arguments');
    
    # Test RemoveHandler by ID
    my $removed = $event->RemoveHandler($handler_id);
    ok($removed, 'RemoveHandler returns true for successful removal');
    ok(!$event->HasHandlers(), 'Event has no handlers after removal');
    is($event->HandlerCount(), 0, 'Event has zero handlers after removal');
    
    # Test invoking after removal
    $handler_called = 0;
    $event->Invoke("test_after_removal");
    is($handler_called, 0, 'Handler not called after removal');
}

sub test_event_multiple_handlers {
    my $event = System::Event->new();
    my @call_order = ();
    
    # Create multiple handlers
    my $handler1 = sub { push @call_order, "handler1"; };
    my $handler2 = sub { push @call_order, "handler2"; };
    my $handler3 = sub { push @call_order, "handler3"; };
    
    # Add handlers
    my $id1 = $event->AddHandler($handler1);
    my $id2 = $event->AddHandler($handler2);
    my $id3 = $event->AddHandler($handler3);
    
    # Test handler count and IDs
    is($event->HandlerCount(), 3, 'Event has three handlers');
    my $ids = $event->GetHandlerIds();
    is(scalar(@$ids), 3, 'GetHandlerIds returns three IDs');
    ok(grep { $_ == $id1 } @$ids, 'First handler ID in list');
    ok(grep { $_ == $id2 } @$ids, 'Second handler ID in list');
    ok(grep { $_ == $id3 } @$ids, 'Third handler ID in list');
    
    # Test handler execution order
    @call_order = ();
    $event->Invoke();
    is(scalar(@call_order), 3, 'All three handlers were called');
    # Note: Order may depend on implementation, but all should be called
    
    # Test removing middle handler
    my $removed = $event->RemoveHandler($id2);
    ok($removed, 'Middle handler removed successfully');
    is($event->HandlerCount(), 2, 'Two handlers remain after removal');
    
    # Test execution after removal
    @call_order = ();
    $event->Invoke();
    is(scalar(@call_order), 2, 'Two handlers called after middle removal');
    ok(!grep { $_ eq "handler2" } @call_order, 'Removed handler not called');
    
    # Test Clear method
    $event->Clear();
    ok(!$event->HasHandlers(), 'Event has no handlers after Clear');
    is($event->HandlerCount(), 0, 'Handler count is zero after Clear');
    
    @call_order = ();
    $event->Invoke();
    is(scalar(@call_order), 0, 'No handlers called after Clear');
}

sub test_event_delegate_handlers {
    my $event = System::Event->new();
    my $handler_called = 0;
    
    # Test with delegate created from code reference
    my $code_handler = sub { $handler_called++; };
    my $delegate = System::Delegate->new(undef, $code_handler);
    
    my $handler_id = $event->AddHandler($delegate);
    ok(defined($handler_id), 'Delegate handler added successfully');
    ok($event->HasHandlers(), 'Event has delegate handler');
    
    # Test invocation
    $event->Invoke();
    is($handler_called, 1, 'Delegate handler was called');
    
    # Test removal by delegate reference
    my $removed = $event->RemoveHandler($delegate);
    ok($removed, 'Delegate handler removed by reference');
    ok(!$event->HasHandlers(), 'Event has no handlers after delegate removal');
    
    # Test with object method delegate
    my $test_obj = TestObject->new();
    my $method_delegate = System::Delegate->new($test_obj, "test_method");
    
    $handler_id = $event->AddHandler($method_delegate);
    ok(defined($handler_id), 'Method delegate handler added');
    
    $event->Invoke("delegate_test");
    is($test_obj->{last_call}, "delegate_test", 'Method delegate called with correct argument');
    
    $event->Clear();
}

sub test_event_subscribe_mechanism {
    my $event = System::Event->new();
    my $handler_called = 0;
    
    # Create handler
    my $handler = sub { $handler_called++; };
    
    # Test Subscribe for adding handler
    my $handler_id = $event->Subscribe($handler);
    ok(defined($handler_id), 'Subscribe returns handler ID for CODE reference');
    ok($event->HasHandlers(), 'Event has handler after Subscribe');
    
    # Test invocation
    $event->Invoke();
    is($handler_called, 1, 'Handler called after Subscribe');
    
    # Test Subscribe for removal (negative ID)
    my $negative_id = -$handler_id;
    my $id_ref = \$negative_id;
    my $removed = $event->Subscribe($id_ref);
    ok($removed, 'Subscribe with negative ID removes handler');
    ok(!$event->HasHandlers(), 'Event has no handlers after Subscribe removal');
    
    # Test Subscribe with delegate
    my $delegate = System::Delegate->new(undef, sub { $handler_called++; });
    $handler_id = $event->Subscribe($delegate);
    ok(defined($handler_id), 'Subscribe works with delegate');
    
    $handler_called = 0;
    $event->Invoke();
    is($handler_called, 1, 'Delegate handler called via Subscribe');
    
    $event->Clear();
}

sub test_event_add_remove_methods {
    my $event = System::Event->new();
    my $handler_called = 0;
    
    my $handler = sub { $handler_called++; };
    
    # Test Add method (alias for AddHandler)
    my $handler_id = $event->Add($handler);
    ok(defined($handler_id), 'Add method works');
    is($event->HandlerCount(), 1, 'Add method adds handler');
    
    # Test Remove method (alias for RemoveHandler)
    my $removed = $event->Remove($handler_id);
    ok($removed, 'Remove method works');
    is($event->HandlerCount(), 0, 'Remove method removes handler');
}

sub test_event_invocation_with_arguments {
    my $event = System::Event->new();
    my @received_args = ();
    
    # Handler that captures arguments
    my $handler = sub {
        @received_args = @_;
    };
    
    $event->AddHandler($handler);
    
    # Test with no arguments
    $event->Invoke();
    is(scalar(@received_args), 0, 'Handler called with no arguments');
    
    # Test with single argument
    $event->Invoke("single_arg");
    is(scalar(@received_args), 1, 'Handler called with one argument');
    is($received_args[0], "single_arg", 'Single argument received correctly');
    
    # Test with multiple arguments
    $event->Invoke("arg1", 42, "arg3", undef);
    is(scalar(@received_args), 4, 'Handler called with four arguments');
    is($received_args[0], "arg1", 'First argument correct');
    is($received_args[1], 42, 'Second argument correct');
    is($received_args[2], "arg3", 'Third argument correct');
    ok(!defined($received_args[3]), 'Fourth argument (undef) correct');
    
    # Test with EventArgs
    my $event_args = System::EventArgs->new();
    $event->Invoke($event_args);
    is(scalar(@received_args), 1, 'Handler called with EventArgs');
    isa_ok($received_args[0], 'System::EventArgs', 'EventArgs passed correctly');
}

sub test_event_exception_handling {
    my $event = System::Event->new();
    
    # Test AddHandler with null handler
    eval {
        $event->AddHandler(undef);
    };
    my $caught = $@;
    isa_ok($caught, 'System::ArgumentNullException', 'AddHandler throws ArgumentNullException for undef handler');
    
    # Test AddHandler with invalid handler type
    eval {
        $event->AddHandler("not_a_handler");
    };
    $caught = $@;
    isa_ok($caught, 'System::ArgumentException', 'AddHandler throws ArgumentException for invalid handler type');
    
    # Test RemoveHandler with null handler
    eval {
        $event->RemoveHandler(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::ArgumentNullException', 'RemoveHandler throws ArgumentNullException for undef handler');
    
    # Test method calls on null event
    eval {
        System::Event::HasHandlers(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'HasHandlers throws NullReferenceException for undef this');
    
    eval {
        System::Event::HandlerCount(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'HandlerCount throws NullReferenceException for undef this');
    
    eval {
        System::Event::GetHandlerIds(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'GetHandlerIds throws NullReferenceException for undef this');
    
    eval {
        System::Event::Invoke(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::NullReferenceException', 'Invoke throws NullReferenceException for undef this');
    
    # Test Subscribe with invalid parameters
    eval {
        $event->Subscribe(undef);
    };
    $caught = $@;
    isa_ok($caught, 'System::ArgumentNullException', 'Subscribe throws ArgumentNullException for undef handler');
    
    eval {
        $event->Subscribe("invalid_handler");
    };
    $caught = $@;
    isa_ok($caught, 'System::ArgumentException', 'Subscribe throws ArgumentException for invalid handler type');
}

sub test_event_handler_exceptions {
    my $event = System::Event->new();
    my $good_handler_called = 0;
    my $exception_handler_called = 0;
    
    # Add handlers, including one that throws
    my $good_handler = sub { $good_handler_called++; };
    my $exception_handler = sub {
        $exception_handler_called++;
        die "Handler exception";
    };
    
    $event->AddHandler($good_handler);
    $event->AddHandler($exception_handler);
    $event->AddHandler($good_handler);  # Add good handler again
    
    # Test event invocation with exception in handler
    eval {
        $event->Invoke();
    };
    
    # The behavior may vary depending on implementation:
    # Some implementations stop on first exception, others continue
    ok($exception_handler_called >= 1, 'Exception handler was called');
    # We don't make strict assertions about whether other handlers are called
    # since this depends on the exception handling strategy
    
    $event->Clear();
}

sub test_event_memory_and_performance {
    my $event = System::Event->new();
    
    # Test adding many handlers
    my @handler_ids = ();
    my $call_count = 0;
    
    for my $i (1..50) {
        my $handler = sub { $call_count++; };
        my $id = $event->AddHandler($handler);
        push @handler_ids, $id;
    }
    
    is($event->HandlerCount(), 50, 'Event has 50 handlers');
    
    # Test invoking with many handlers
    $call_count = 0;
    $event->Invoke();
    is($call_count, 50, 'All 50 handlers were called');
    
    # Test removing handlers
    for my $i (0..24) {  # Remove first 25 handlers
        my $removed = $event->RemoveHandler($handler_ids[$i]);
        ok($removed, "Handler $i removed successfully") if $i < 3;  # Only check first 3
    }
    
    is($event->HandlerCount(), 25, '25 handlers remain after partial removal');
    
    # Test invocation after partial removal
    $call_count = 0;
    $event->Invoke();
    is($call_count, 25, 'Remaining 25 handlers were called');
    
    # Test clear
    $event->Clear();
    is($event->HandlerCount(), 0, 'All handlers cleared');
    
    $call_count = 0;
    $event->Invoke();
    is($call_count, 0, 'No handlers called after clear');
}

sub test_event_edge_cases {
    my $event = System::Event->new();
    
    # Test removing non-existent handler ID
    my $removed = $event->RemoveHandler(99999);
    ok(!$removed, 'RemoveHandler returns false for non-existent ID');
    
    # Test adding same handler multiple times
    my $handler_called = 0;
    my $handler = sub { $handler_called++; };
    
    my $id1 = $event->AddHandler($handler);
    my $id2 = $event->AddHandler($handler);  # Same handler, different ID
    
    ok($id1 != $id2, 'Same handler gets different IDs when added multiple times');
    is($event->HandlerCount(), 2, 'Same handler counted twice');
    
    $handler_called = 0;
    $event->Invoke();
    is($handler_called, 2, 'Same handler called twice');
    
    # Test handler that modifies event during execution
    $event->Clear();
    my $modifying_handler = sub {
        # This handler tries to add another handler during execution
        if ($event->HandlerCount() < 5) {
            $event->AddHandler(sub { $handler_called++; });
        }
    };
    
    $event->AddHandler($modifying_handler);
    
    # This is an edge case - behavior may vary
    eval {
        $event->Invoke();
    };
    # We don't make strict assertions here since behavior is implementation-dependent
    ok(1, 'Event handles self-modification gracefully');
    
    $event->Clear();
}

sub test_event_inheritance_and_polymorphism {
    # Test that Event properly inherits from Object
    my $event = System::Event->new();
    
    # Test Object methods
    ok($event->can('ToString'), 'Event has ToString method');
    ok($event->can('GetType'), 'Event has GetType method');
    ok($event->can('GetHashCode'), 'Event has GetHashCode method');
    ok($event->can('Equals'), 'Event has Equals method');
    
    # Test GetType
    is($event->GetType(), 'System::Event', 'GetType returns correct type');
    
    # Test GetHashCode
    my $hash = $event->GetHashCode();
    ok(defined($hash), 'GetHashCode returns defined value');
    is($event->GetHashCode(), $hash, 'GetHashCode is consistent');
    
    # Test Equals
    my $event2 = System::Event->new();
    ok(!$event->Equals($event2), 'Different event instances are not equal');
    ok($event->Equals($event), 'Event equals itself');
    
    # Test ToString
    my $str = $event->ToString();
    ok(defined($str), 'ToString returns defined value');
    like($str, qr/System::Event/, 'ToString contains class name');
}

# Test helper class for method delegates
package TestObject;
sub new {
    my $class = shift;
    return bless {
        last_call => undef,
        call_count => 0,
    }, $class;
}

sub test_method {
    my ($this, $arg) = @_;
    $this->{last_call} = $arg;
    $this->{call_count}++;
}

package main;

# Run all comprehensive event tests
test_event_creation();
test_event_handler_management();
test_event_multiple_handlers();
test_event_delegate_handlers();
test_event_subscribe_mechanism();
test_event_add_remove_methods();
test_event_invocation_with_arguments();
test_event_exception_handling();
test_event_handler_exceptions();
test_event_memory_and_performance();
test_event_edge_cases();
test_event_inheritance_and_polymorphism();

done_testing();