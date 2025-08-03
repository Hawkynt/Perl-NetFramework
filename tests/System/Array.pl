#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Array');
}

sub test_array_creation {
    my $arr = System::Array->new(1, 2, 3);
    isa_ok($arr, 'System::Array', 'Array creation');
    is($arr->Length(), 3, 'Array length');
}

sub test_array_access {
    my $arr = System::Array->new("a", "b", "c");
    is($arr->Get(0), "a", 'Get first element');
    is($arr->Get(2), "c", 'Get last element');
    
    $arr->Set(1, "modified");
    is($arr->Get(1), "modified", 'Set and get modified element');
}

sub test_array_enumeration {
    my $arr = System::Array->new(1, 2, 3);
    my $enumerator = $arr->GetEnumerator();
    
    my @values;
    while ($enumerator->MoveNext()) {
        push @values, $enumerator->Current();
    }
    
    is_deeply(\@values, [1, 2, 3], 'Array enumeration works');
}

sub test_array_linq {
    my $arr = System::Array->new(1, 2, 3, 4, 5);
    
    my $evens = $arr->Where(sub { $_[0] % 2 == 0 })->ToArray();
    is($evens->Length(), 2, 'Where filter returns correct count');
    is($evens->Get(0), 2, 'First even number');
    is($evens->Get(1), 4, 'Second even number');
    
    my $doubled = $arr->Select(sub { $_[0] * 2 })->ToArray();
    is($doubled->Length(), 5, 'Select returns same count');
    is($doubled->Get(0), 2, 'First doubled value');
    is($doubled->Get(4), 10, 'Last doubled value');
}

sub test_array_contains {
    my $arr = System::Array->new("apple", "banana", "cherry");
    ok($arr->Contains("banana"), 'Array contains existing element');
    ok(!$arr->Contains("grape"), 'Array does not contain non-existing element');
}

sub test_array_indexOf {
    my $arr = System::Array->new("x", "y", "z");
    is($arr->IndexOf("y"), 1, 'IndexOf returns correct position');
    is($arr->IndexOf("missing"), -1, 'IndexOf returns -1 for missing element');
}

test_array_creation();
test_array_access();
test_array_enumeration();
test_array_linq();
test_array_contains();
test_array_indexOf();

done_testing();