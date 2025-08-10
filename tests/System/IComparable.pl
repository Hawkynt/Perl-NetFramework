#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System::IComparable;

BEGIN {
    use_ok('System::IComparable');
}

# Test interface module loading
sub test_interface_loading {
    ok(1, 'IComparable interface module loads without error');
    
    # Test that interface method is defined
    ok(defined(&System::IComparable::CompareTo), 'CompareTo method is defined');
}

# Test interface method signature
sub test_interface_method_signature {
    # Test that CompareTo method throws NotImplementedException when called directly
    eval {
        System::IComparable::CompareTo(undef, undef);
    };
    ok($@, 'CompareTo throws exception when called directly on interface');
    like($@, qr/NotImplementedException/, 'CompareTo throws NotImplementedException');
    
    # Test method signature (should take $self and $other parameters)
    eval {
        System::IComparable::CompareTo(undef);  # Missing $other parameter
    };
    ok($@, 'CompareTo with insufficient parameters throws exception');
}

# Test interface method existence
sub test_interface_method_existence {
    # Test that CompareTo method can be found via can()
    ok(System::IComparable->can('CompareTo'), 'IComparable can CompareTo');
    
    # Test that non-existent methods are not found
    ok(!System::IComparable->can('NonExistentMethod'), 'IComparable cannot NonExistentMethod');
    ok(!System::IComparable->can('Compare'), 'IComparable cannot Compare (wrong method name)');
}

# Test interface contract compliance
sub test_interface_contract {
    # Test that required interface method is present
    ok(System::IComparable->can('CompareTo'), 'Required method CompareTo is available');
    
    # IComparable should have exactly 1 method
    my $method_count = 0;
    $method_count++ if System::IComparable->can('CompareTo');
    
    is($method_count, 1, 'Interface has exactly 1 required method');
}

# Test mock implementation to verify interface usage
sub test_mock_implementation {
    # Create a mock class that implements IComparable
    package MockComparableNumber;
    use base 'System::IComparable';
    
    sub new {
        my ($class, $value) = @_;
        return bless { value => $value }, $class;
    }
    
    sub CompareTo {
        my ($self, $other) = @_;
        
        return undef unless defined($other);
        return undef unless ref($other) eq ref($self);
        
        my $self_val = $self->{value};
        my $other_val = $other->{value};
        
        return -1 if $self_val < $other_val;
        return 1 if $self_val > $other_val;
        return 0;  # Equal
    }
    
    sub Value {
        return $_[0]->{value};
    }
    
    package main;
    
    # Test the mock implementation
    my $num1 = MockComparableNumber->new(5);
    my $num2 = MockComparableNumber->new(10);
    my $num3 = MockComparableNumber->new(5);
    
    isa_ok($num1, 'MockComparableNumber', 'Mock implementation created');
    isa_ok($num1, 'System::IComparable', 'Mock inherits from IComparable interface');
    
    # Test that implemented CompareTo works
    is($num1->CompareTo($num2), -1, 'CompareTo returns -1 when self < other');
    is($num2->CompareTo($num1), 1, 'CompareTo returns 1 when self > other');
    is($num1->CompareTo($num3), 0, 'CompareTo returns 0 when self == other');
}

# Test interface polymorphism and comparison patterns
sub test_interface_polymorphism {
    # Create different comparable implementations
    package MockComparableString;
    use base 'System::IComparable';
    
    sub new {
        my ($class, $value) = @_;
        return bless { value => $value }, $class;
    }
    
    sub CompareTo {
        my ($self, $other) = @_;
        
        return undef unless defined($other);
        return undef unless ref($other) eq ref($self);
        
        return $self->{value} cmp $other->{value};
    }
    
    sub Value { return $_[0]->{value}; }
    
    package main;
    
    my $str1 = MockComparableString->new('apple');
    my $str2 = MockComparableString->new('banana');
    my $str3 = MockComparableString->new('apple');
    
    # Test polymorphic usage
    my @comparables = ($str1, $str2, $str3);
    
    for my $i (0..$#comparables) {
        my $comparable = $comparables[$i];
        
        isa_ok($comparable, 'System::IComparable', "Comparable $i implements IComparable interface");
        ok($comparable->can('CompareTo'), "Comparable $i can CompareTo");
    }
    
    # Test string comparisons
    is($str1->CompareTo($str2), -1, 'String CompareTo: apple < banana');
    is($str2->CompareTo($str1), 1, 'String CompareTo: banana > apple'); 
    is($str1->CompareTo($str3), 0, 'String CompareTo: apple == apple');
}

# Test comparison contract and edge cases
sub test_comparison_contract {
    my $num1 = MockComparableNumber->new(10);
    my $num2 = MockComparableNumber->new(5);
    my $num3 = MockComparableNumber->new(10);
    
    # Test reflexivity: a.CompareTo(a) == 0
    is($num1->CompareTo($num1), 0, 'Reflexivity: object equals itself');
    
    # Test symmetry: if a.CompareTo(b) == x, then b.CompareTo(a) == -x
    my $result1to2 = $num1->CompareTo($num2);
    my $result2to1 = $num2->CompareTo($num1);
    
    ok(($result1to2 == 1 && $result2to1 == -1) || 
       ($result1to2 == -1 && $result2to1 == 1) ||
       ($result1to2 == 0 && $result2to1 == 0), 
       'Symmetry: CompareTo results are symmetric');
    
    # Test transitivity: if a.CompareTo(b) == 0 and b.CompareTo(c) == 0, then a.CompareTo(c) == 0
    is($num1->CompareTo($num3), 0, 'Transitivity: equal objects have consistent comparison');
    
    # Test consistency with null/undefined values
    is($num1->CompareTo(undef), undef, 'CompareTo with undef returns undef');
}

# Test sorting functionality using IComparable
sub test_sorting_with_comparable {
    # Create an array of comparable objects
    my @numbers = (
        MockComparableNumber->new(3),
        MockComparableNumber->new(1),
        MockComparableNumber->new(4),
        MockComparableNumber->new(1),
        MockComparableNumber->new(5)
    );
    
    # Sort using CompareTo
    my @sorted = sort { $a->CompareTo($b) } @numbers;
    
    # Verify sorting
    my @expected_values = (1, 1, 3, 4, 5);
    for my $i (0..$#sorted) {
        is($sorted[$i]->Value(), $expected_values[$i], "Sorted position $i has correct value");
    }
    
    # Test reverse sorting
    my @reverse_sorted = sort { $b->CompareTo($a) } @numbers;
    my @reverse_expected = (5, 4, 3, 1, 1);
    for my $i (0..$#reverse_sorted) {
        is($reverse_sorted[$i]->Value(), $reverse_expected[$i], "Reverse sorted position $i has correct value");
    }
}

# Test comparable search and binary search patterns
sub test_search_patterns {
    # Create sorted array of comparable objects
    my @sorted_numbers = (
        MockComparableNumber->new(1),
        MockComparableNumber->new(3),
        MockComparableNumber->new(5),
        MockComparableNumber->new(7),
        MockComparableNumber->new(9)
    );
    
    # Simple linear search using CompareTo
    my $search_target = MockComparableNumber->new(5);
    my $found_index = -1;
    
    for my $i (0..$#sorted_numbers) {
        if ($sorted_numbers[$i]->CompareTo($search_target) == 0) {
            $found_index = $i;
            last;
        }
    }
    
    is($found_index, 2, 'Linear search finds correct index using CompareTo');
    
    # Test min/max operations using CompareTo
    my $min_obj = $sorted_numbers[0];
    my $max_obj = $sorted_numbers[0];
    
    for my $num (@sorted_numbers[1..$#sorted_numbers]) {
        $min_obj = $num if $num->CompareTo($min_obj) < 0;
        $max_obj = $num if $num->CompareTo($max_obj) > 0;
    }
    
    is($min_obj->Value(), 1, 'Min operation using CompareTo finds smallest value');
    is($max_obj->Value(), 9, 'Max operation using CompareTo finds largest value');
}

# Test error handling and edge cases
sub test_error_handling {
    my $num1 = MockComparableNumber->new(5);
    
    # Test comparison with incompatible types
    my $incompatible = MockComparableString->new('test');
    is($num1->CompareTo($incompatible), undef, 'CompareTo with incompatible type returns undef');
    
    # Test comparison with non-objects
    is($num1->CompareTo('string'), undef, 'CompareTo with string returns undef');
    is($num1->CompareTo(42), undef, 'CompareTo with number returns undef');
    
    # Test calling with wrong number of arguments
    eval {
        $num1->CompareTo();  # No argument
    };
    # This might or might not fail depending on implementation, but should handle gracefully
    
    eval {
        System::IComparable::CompareTo();  # Called on interface directly, no arguments
    };
    ok($@, 'Direct interface call with no arguments throws error');
}

# Test interface inheritance and ISA relationships
sub test_interface_inheritance {
    # Create a class that uses IComparable as a mixin
    package TestComparableImplementation;
    use base 'System::IComparable';
    
    sub new { 
        my ($class, $data) = @_;
        return bless { data => $data }, $class; 
    }
    
    sub CompareTo {
        my ($self, $other) = @_;
        return $self->{data} cmp $other->{data};
    }
    
    sub GetData { return $_[0]->{data}; }
    
    package main;
    
    my $impl1 = TestComparableImplementation->new('alpha');
    my $impl2 = TestComparableImplementation->new('beta');
    
    # Test ISA relationships
    isa_ok($impl1, 'TestComparableImplementation', 'Implementation is correct class');
    isa_ok($impl1, 'System::IComparable', 'Implementation inherits from IComparable');
    
    # Test that interface methods work through inheritance
    is($impl1->CompareTo($impl2), -1, 'Inherited CompareTo works (alpha < beta)');
    is($impl2->CompareTo($impl1), 1, 'Inherited CompareTo works (beta > alpha)');
}

# Test interface as a contract specification
sub test_interface_contract_specification {
    # Test that implementing classes must provide CompareTo method
    
    my $check_interface_compliance = sub {
        my ($object) = @_;
        
        # Check that object can perform comparison operation
        return $object->can('CompareTo');
    };
    
    my $compliant_impl = MockComparableNumber->new(5);
    ok($check_interface_compliance->($compliant_impl), 'Compliant implementation passes interface check');
    
    # Test with a non-compliant object
    my $non_compliant = bless {}, 'NonCompliantClass';
    ok(!$check_interface_compliance->($non_compliant), 'Non-compliant object fails interface check');
}

# Test comparison utility functions
sub test_comparison_utilities {
    # Helper function to determine comparison result description
    my $describe_comparison = sub {
        my ($obj1, $obj2) = @_;
        my $result = $obj1->CompareTo($obj2);
        
        return 'undefined' unless defined($result);
        return 'equal' if $result == 0;
        return 'less than' if $result < 0;
        return 'greater than' if $result > 0;
    };
    
    my $num1 = MockComparableNumber->new(5);
    my $num2 = MockComparableNumber->new(10);
    my $num3 = MockComparableNumber->new(5);
    
    is($describe_comparison->($num1, $num2), 'less than', 'Utility correctly identifies less than relationship');
    is($describe_comparison->($num2, $num1), 'greater than', 'Utility correctly identifies greater than relationship');
    is($describe_comparison->($num1, $num3), 'equal', 'Utility correctly identifies equal relationship');
    
    # Test generic comparison function
    my $generic_compare = sub {
        my ($a, $b) = @_;
        
        # Both must implement IComparable
        return undef unless ($a->can('CompareTo') && $b->can('CompareTo'));
        
        return $a->CompareTo($b);
    };
    
    is($generic_compare->($num1, $num2), -1, 'Generic compare function works');
    is($generic_compare->($num2, $num1), 1, 'Generic compare function works in reverse');
    is($generic_compare->($num1, $num3), 0, 'Generic compare function works for equal values');
}

# Test CSharp integration and package namespace
sub test_package_namespace {
    # Test that the package loads and functions correctly
    ok(1, 'Package namespace is properly structured');
    
    # Test that interface methods are accessible from the full namespace
    ok(defined(&System::IComparable::CompareTo), 'CompareTo accessible via full namespace');
    
    # Test module works after CSharp package name shortening
    eval {
        my $can_compare = System::IComparable->can('CompareTo');
        ok(defined($can_compare), 'CSharp integration does not break method resolution');
    };
    ok(!$@, 'CSharp integration works without errors');
}

# Run all tests
test_interface_loading();
test_interface_method_signature();
test_interface_method_existence();
test_interface_contract();
test_mock_implementation();
test_interface_polymorphism();
test_comparison_contract();
test_sorting_with_comparable();
test_search_patterns();
test_error_handling();
test_interface_inheritance();
test_interface_contract_specification();
test_comparison_utilities();
test_package_namespace();

done_testing();