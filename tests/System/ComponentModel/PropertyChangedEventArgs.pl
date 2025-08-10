#!/usr/bin/perl

use strict;
use warnings;
use lib qw(. ./lib);
use Test::More tests => 25;

# Boolean constants
use constant true => 1;
use constant false => 0;

# Import required modules
require System::ComponentModel::PropertyChangedEventArgs;
require System::String;
require System::Exceptions;

# Test 1-5: Basic construction and inheritance
{
    my $args = System::ComponentModel::PropertyChangedEventArgs->new('TestProperty');
    isa_ok($args, 'System::ComponentModel::PropertyChangedEventArgs', 'PropertyChangedEventArgs construction');
    isa_ok($args, 'System::EventArgs', 'PropertyChangedEventArgs inherits from EventArgs');
    can_ok($args, 'PropertyName');
    is($args->PropertyName(), 'TestProperty', 'PropertyName set correctly in constructor');
}

# Test 6-10: Construction with different property name types
{
    # Test with regular string
    my $args1 = System::ComponentModel::PropertyChangedEventArgs->new('StringProperty');
    is($args1->PropertyName(), 'StringProperty', 'Regular string property name');
    
    # Test with empty string
    my $args2 = System::ComponentModel::PropertyChangedEventArgs->new('');
    is($args2->PropertyName(), '', 'Empty string property name');
    
    # Test with null/undef (indicates all properties changed)
    my $args3 = System::ComponentModel::PropertyChangedEventArgs->new(undef);
    ok(!defined($args3->PropertyName()), 'Null property name for all properties changed');
    
    # Test with System::String object
    my $string_obj = System::String->new('SystemStringProperty');
    my $args4 = System::ComponentModel::PropertyChangedEventArgs->new($string_obj);
    is($args4->PropertyName(), $string_obj, 'System::String property name accepted');
}

# Test 11-15: PropertyName getter behavior
{
    # Test PropertyName is read-only
    my $args = System::ComponentModel::PropertyChangedEventArgs->new('ReadOnlyTest');
    is($args->PropertyName(), 'ReadOnlyTest', 'PropertyName getter works');
    
    # Test multiple calls return same value
    my $name1 = $args->PropertyName();
    my $name2 = $args->PropertyName();
    is($name1, $name2, 'PropertyName returns consistent value');
    
    # Test with special characters in property name
    my $special_args = System::ComponentModel::PropertyChangedEventArgs->new('Property.With.Dots');
    is($special_args->PropertyName(), 'Property.With.Dots', 'Property name with special characters');
    
    my $unicode_args = System::ComponentModel::PropertyChangedEventArgs->new('PropertyWithUnicode_测试');
    is($unicode_args->PropertyName(), 'PropertyWithUnicode_测试', 'Property name with Unicode characters');
}

# Test 16-20: Exception handling
{
    # Test null reference exception on undefined object
    eval {
        my $null_args = undef;
        $null_args->PropertyName();
    };
    like($@, qr/NullReferenceException/, 'PropertyName throws NullReferenceException on null object');
    
    # Test invalid property name type (non-string, non-System::String)
    eval {
        my $args = System::ComponentModel::PropertyChangedEventArgs->new(['array_ref']);
    };
    like($@, qr/ArgumentException/, 'Constructor throws ArgumentException for array reference');
    
    eval {
        my $args = System::ComponentModel::PropertyChangedEventArgs->new({hash => 'ref'});
    };
    like($@, qr/ArgumentException/, 'Constructor throws ArgumentException for hash reference');
    
    # Test with numeric value (should work as string)
    my $numeric_args = System::ComponentModel::PropertyChangedEventArgs->new(123);
    is($numeric_args->PropertyName(), 123, 'Numeric property name converted to string');
}

# Test 21-25: Common usage scenarios and edge cases
{
    # Simulate typical PropertyChanged event scenario
    my @property_changes = ();
    
    my $simulate_property_change = sub {
        my ($property_name) = @_;
        my $args = System::ComponentModel::PropertyChangedEventArgs->new($property_name);
        push @property_changes, {
            property => $args->PropertyName(),
            timestamp => time()
        };
        return $args;
    };
    
    # Simulate various property changes
    $simulate_property_change->('Name');
    $simulate_property_change->('Value');
    $simulate_property_change->(undef);  # All properties
    $simulate_property_change->('Status');
    
    is(scalar(@property_changes), 4, 'All property change events recorded');
    is($property_changes[0]->{property}, 'Name', 'First property change recorded correctly');
    is($property_changes[1]->{property}, 'Value', 'Second property change recorded correctly');
    ok(!defined($property_changes[2]->{property}), 'Null property change recorded correctly');
    is($property_changes[3]->{property}, 'Status', 'Fourth property change recorded correctly');
    
    # Test PropertyName preservation across different contexts
    my $args = System::ComponentModel::PropertyChangedEventArgs->new('PersistentProperty');
    my $original_name = $args->PropertyName();
    
    # Pass through a subroutine
    my $pass_through = sub {
        my ($event_args) = @_;
        return $event_args->PropertyName();
    };
    
    my $passed_name = $pass_through->($args);
    is($passed_name, $original_name, 'Property name preserved through subroutine call');
}

done_testing();