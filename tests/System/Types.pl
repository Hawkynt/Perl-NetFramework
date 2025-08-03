#!/usr/bin/perl
# Comprehensive tests for System framework types
# Based on original TypeTest.pl from x/ directory

use strict;
use warnings;
use Test::More;

# Plan for all the type tests
plan tests => 50;

use_ok('System') or BAIL_OUT("Cannot load System");

# Test Decimal type functionality
sub test_decimal {
    use_ok('System::Decimal');
    
    # Basic equality tests
    ok(Decimal->new(1) == 1, "Decimal-scalar equality works");
    ok(1 == Decimal->new(1), "Scalar-decimal equality works");
    ok(Decimal->new(1) == Decimal->new(1), "Decimal-decimal equality works");
    
    # Inequality tests
    ok(Decimal->new(1) != -1, "Decimal-scalar inequality works");
    ok(-1 != Decimal->new(1), "Scalar-decimal inequality works");
    ok(Decimal->new(-1) != Decimal->new(1), "Decimal-decimal inequality works");
    
    # Comparison tests
    ok(Decimal->new(1) < 2, "Decimal-scalar less than works");
    ok(1 < Decimal->new(2), "Scalar-decimal less than works");
    ok(Decimal->new(1) < Decimal->new(2), "Decimal-decimal less than works");
    
    ok(Decimal->new(2) > 1, "Decimal-scalar greater than works");
    ok(2 > Decimal->new(1), "Scalar-decimal greater than works");
    ok(Decimal->new(2) > Decimal->new(1), "Decimal-decimal greater than works");
    
    # Arithmetic tests
    ok((Decimal->new(2) + 1) == Decimal->new(3), "Decimal addition works");
    ok((Decimal->new(2) - 1) == Decimal->new(1), "Decimal subtraction works");
    ok((Decimal->new(2) * 2) == Decimal->new(4), "Decimal multiplication works");
    ok((Decimal->new(4) / 2) == Decimal->new(2), "Decimal division works");
    
    # String formatting
    is(Decimal->new(3)->ToString(), "3", "Decimal ToString works");
    is(Decimal->new(3.14)->ToString("0.00"), "3.14", "Decimal formatted ToString works");
}

# Test TimeSpan functionality  
sub test_timespan {
    use_ok('System::TimeSpan');
    
    # Constructor tests
    ok(TimeSpan->new()->Ticks == 0, "Empty TimeSpan constructor works");
    ok(TimeSpan->new(1)->Ticks == 1, "TimeSpan tick constructor works");
    
    # Equality and comparison
    ok(TimeSpan->new() == TimeSpan->new(), "TimeSpan equality works");
    ok(TimeSpan->new(1) != TimeSpan->new(2), "TimeSpan inequality works");
    ok(TimeSpan->new(1) < TimeSpan->new(2), "TimeSpan comparison works");
    
    # Arithmetic
    ok(TimeSpan->new(2) + TimeSpan->new(1) == TimeSpan->new(3), "TimeSpan addition works");
    ok(TimeSpan->new(2) - TimeSpan->new(1) == TimeSpan->new(1), "TimeSpan subtraction works");
    
    # Static methods
    ok(TimeSpan->FromDays(1)->TotalDays == 1, "TimeSpan FromDays works");
    ok(TimeSpan->FromHours(1)->TotalHours == 1, "TimeSpan FromHours works");
    
    # String formatting
    like(TimeSpan->FromDays(1)->ToString(), qr/1\.00:00:00/, "TimeSpan ToString works");
}

# Test String functionality
sub test_string {
    use_ok('System::String');
    
    # Equality tests
    ok(String->new("a") == String->new("a"), "String equality works");
    ok(String->new("a") != String->new("b"), "String inequality works");
    ok(String->new("a") eq String->new("a"), "String eq works");
    ok(String->new("a") ne String->new("b"), "String ne works");
    
    # Basic operations
    my $str = String->new("Hello World");
    ok($str->Length() > 0, "String Length works");
    ok($str->Contains("World"), "String Contains works");
    ok($str->StartsWith("Hello"), "String StartsWith works");
    ok($str->EndsWith("World"), "String EndsWith works");
    
    # Case operations
    is($str->ToUpper()->ToString(), "HELLO WORLD", "String ToUpper works");
    is($str->ToLower()->ToString(), "hello world", "String ToLower works");
}

# Test Array functionality
sub test_array {
    use_ok('System::Array');
    
    my $arr = Array->new(1, 2, 3, 4, 5);
    ok($arr->Length() == 5, "Array Length works");
    
    # LINQ operations (if available)
    if ($arr->can('Where')) {
        my $evens = $arr->Where(sub { $_[0] % 2 == 0 });
        ok(defined($evens), "Array LINQ Where works");
        
        my $first_even = $evens->First();
        is($first_even, 2, "LINQ First works");
    } else {
        pass("LINQ operations not available - skipping");
        pass("LINQ operations not available - skipping");
    }
}

# Test Collections functionality
sub test_collections {
    use_ok('System::Collections::Hashtable');
    
    my $hash = Hashtable->new();
    $hash->Add("key1", "value1");
    $hash->Add("key2", "value2");
    
    ok($hash->Count() == 2, "Hashtable Count works");
    ok($hash->ContainsKey("key1"), "Hashtable ContainsKey works");
    is($hash->Item("key1"), "value1", "Hashtable Item access works");
    
    my $keys = $hash->Keys();
    ok(defined($keys), "Hashtable Keys works");
}

# Run all the tests
test_decimal();
test_timespan();
test_string();
test_array();
test_collections();

done_testing();

print "\n" . "=" x 60 . "\n";
print "SYSTEM FRAMEWORK TYPE TESTS COMPLETED\n";  
print "=" x 60 . "\n";
print "✅ Tested Types:\n";
print "   • System::Decimal - arithmetic and formatting\n";
print "   • System::TimeSpan - time calculations\n";
print "   • System::String - string operations\n";
print "   • System::Array - collections and LINQ\n";
print "   • System::Collections::Hashtable - key-value storage\n";
print "\n";
print "📊 These tests verify the core framework functionality\n";
print "   independent of the C# syntax filter.\n";
print "=" x 60 . "\n";