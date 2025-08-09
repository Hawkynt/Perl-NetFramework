#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;
use System;

BEGIN {
    use_ok('System::Linq');
}

sub test_linq_where {
    my $arr = System::Array->new(1, 2, 3, 4, 5, 6);
    my $evens = $arr->Where(sub { $_[0] % 2 == 0 })->ToArray();
    
    is($evens->Length(), 3, 'Where filters correctly');
    is($evens->Get(0), 2, 'First even number');
    is($evens->Get(1), 4, 'Second even number');
    is($evens->Get(2), 6, 'Third even number');
}

sub test_linq_select {
    my $arr = System::Array->new(1, 2, 3);
    my $doubled = $arr->Select(sub { $_[0] * 2 })->ToArray();
    
    is($doubled->Length(), 3, 'Select maintains count');
    is($doubled->Get(0), 2, 'First value doubled');
    is($doubled->Get(1), 4, 'Second value doubled');
    is($doubled->Get(2), 6, 'Third value doubled');
}

sub test_linq_chaining {
    my $arr = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    my $result = $arr
        ->Where(sub { $_[0] % 2 == 0 })
        ->Select(sub { $_[0] * 3 })
        ->Where(sub { $_[0] > 10 })
        ->ToArray();
    
    is($result->Length(), 4, 'Chained operations work');
    is($result->Get(0), 12, 'First result: 4*3=12');
    is($result->Get(1), 18, 'Second result: 6*3=18');
    is($result->Get(2), 24, 'Third result: 8*3=24');
    is($result->Get(3), 30, 'Fourth result: 10*3=30');
}

sub test_linq_first {
    my $arr = System::Array->new(10, 20, 30);
    is($arr->First(), 10, 'First returns first element');
    
    my $firstEven = $arr->First(sub { $_[0] % 20 == 0 });
    is($firstEven, 20, 'First with predicate finds correct element');
}

sub test_linq_last {
    my $arr = System::Array->new(10, 20, 30);
    is($arr->Last(), 30, 'Last returns last element');
    
    my $lastSmall = $arr->Last(sub { $_[0] < 25 });
    is($lastSmall, 20, 'Last with predicate finds correct element');
}

sub test_linq_any_all {
    my $arr = System::Array->new(2, 4, 6, 8);
    ok($arr->Any(), 'Any returns true for non-empty collection');
    ok($arr->Any(sub { $_[0] > 5 }), 'Any with predicate finds matching element');
    ok(!$arr->Any(sub { $_[0] % 2 == 1 }), 'Any with predicate returns false when no match');
    
    ok($arr->All(sub { $_[0] % 2 == 0 }), 'All returns true when all match');
    ok(!$arr->All(sub { $_[0] > 5 }), 'All returns false when not all match');
}

sub test_linq_count {
    my $arr = System::Array->new(1, 2, 3, 4, 5);
    is($arr->Count(), 5, 'Count returns total count');
    is($arr->Count(sub { $_[0] % 2 == 0 }), 2, 'Count with predicate returns filtered count');
}

sub test_linq_skip_take {
    my $arr = System::Array->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    my $skipped = $arr->Skip(3)->ToArray();
    is($skipped->Length(), 7, 'Skip removes correct number of elements');
    is($skipped->Get(0), 4, 'Skip starts from correct element');
    
    my $taken = $arr->Take(3)->ToArray();
    is($taken->Length(), 3, 'Take returns correct number of elements');
    is($taken->Get(2), 3, 'Take includes correct elements');
    
    my $middle = $arr->Skip(2)->Take(3)->ToArray();
    is($middle->Length(), 3, 'Skip and Take can be chained');
    is($middle->Get(0), 3, 'Chained Skip/Take starts correctly');
    is($middle->Get(2), 5, 'Chained Skip/Take ends correctly');
}

sub test_linq_orderby {
    my $arr = System::Array->new(3, 1, 4, 1, 5, 9, 2, 6);
    my $sorted = $arr->OrderBy(sub { $_[0] })->ToArray();
    
    is($sorted->Length(), 8, 'OrderBy maintains count');
    is($sorted->Get(0), 1, 'First element is smallest');
    is($sorted->Get(7), 9, 'Last element is largest');
    
    my $descending = $arr->OrderByDescending(sub { $_[0] })->ToArray();
    is($descending->Get(0), 9, 'OrderByDescending first element is largest');
    is($descending->Get(7), 1, 'OrderByDescending last element is smallest');
}

sub test_linq_distinct {
    my $arr = System::Array->new(1, 2, 2, 3, 3, 3, 4);
    my $unique = $arr->Distinct()->ToArray();
    
    is($unique->Length(), 4, 'Distinct removes duplicates');
    is($unique->Get(0), 1, 'Distinct preserves order');
    is($unique->Get(3), 4, 'Distinct includes all unique values');
}

test_linq_where();
test_linq_select();
test_linq_chaining();
test_linq_first();
test_linq_last();
test_linq_any_all();
test_linq_count();
test_linq_skip_take();
test_linq_orderby();
test_linq_distinct();

done_testing();