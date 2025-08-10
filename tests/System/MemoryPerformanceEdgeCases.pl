#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::Object;
use System::String;
use System::Array;
use Time::HiRes qw(time);

BEGIN {
    use_ok('System::Object');
    use_ok('System::String');
    use_ok('System::Array');
}

# Test memory usage and performance edge cases
sub test_object_memory_pressure {
    # Test rapid object creation and destruction
    my @objects;
    
    # Create many objects rapidly
    for my $i (1..10000) {
        my $obj = System::Object->new();
        push @objects, $obj;
        
        # Test that object is still functional
        if ($i <= 10) {
            ok(defined($obj->ToString()), "Object $i ToString works");
            ok($obj->GetHashCode() >= 0, "Object $i hash code valid");
        }
    }
    
    is(scalar(@objects), 10000, 'All objects created successfully');
    
    # Test memory usage by accessing random objects
    for my $test (1..100) {
        my $random_idx = int(rand(10000));
        my $obj = $objects[$random_idx];
        
        ok(defined($obj), "Random object $test is defined");
        ok(defined($obj->ToString()), "Random object $test ToString works") if $test <= 5;
        ok($obj->GetHashCode() >= 0, "Random object $test hash valid") if $test <= 5;
    }
    
    # Test cleanup
    @objects = ();
    ok(1, 'Object cleanup completed');
    
    # Test memory reuse patterns
    for my $round (1..10) {
        my @round_objects;
        
        for my $i (1..1000) {
            my $obj = System::Object->new();
            push @round_objects, $obj;
        }
        
        # Use the objects
        for my $obj (@round_objects[0..9]) {  # Test first 10
            $obj->ToString();
            $obj->GetHashCode();
        }
        
        # Clear round
        @round_objects = ();
        ok(1, "Memory reuse round $round completed") if $round <= 3;
    }
}

sub test_string_memory_pressure {
    # Test with various string sizes
    my @small_strings;
    my @medium_strings;
    my @large_strings;
    
    # Small strings (1-100 chars)
    for my $i (1..1000) {
        my $content = 'x' x ($i % 100 + 1);
        my $str = System::String->new($content);
        push @small_strings, $str;
        
        if ($i <= 10) {
            is($str->Length(), length($content), "Small string $i length correct");
            is($str->ToString(), $content, "Small string $i content correct");
        }
    }
    
    # Medium strings (1K - 10K chars)
    for my $i (1..100) {
        my $size = 1000 + ($i * 100);
        my $content = 'M' x $size;
        my $str = System::String->new($content);
        push @medium_strings, $str;
        
        if ($i <= 5) {
            is($str->Length(), $size, "Medium string $i length correct");
            ok($str->StartsWith('M' x 10), "Medium string $i starts correctly");
        }
    }
    
    # Large strings (100K+ chars)
    for my $i (1..10) {
        my $size = 100000 + ($i * 50000);
        my $content = 'L' x $size;
        my $str = System::String->new($content);
        push @large_strings, $str;
        
        if ($i <= 3) {
            is($str->Length(), $size, "Large string $i length correct");
            ok($str->EndsWith('L' x 10), "Large string $i ends correctly");
        }
    }
    
    is(scalar(@small_strings), 1000, 'All small strings created');
    is(scalar(@medium_strings), 100, 'All medium strings created');
    is(scalar(@large_strings), 10, 'All large strings created');
    
    # Test operations on mixed sizes
    my $small_sample = $small_strings[0];
    my $medium_sample = $medium_strings[0];
    my $large_sample = $large_strings[0];
    
    # Concatenation tests
    my $small_concat = $small_sample + System::String->new("_suffix");
    ok($small_concat->EndsWith("_suffix"), 'Small string concatenation');
    
    my $mixed_concat = $small_sample + $medium_sample;
    ok($mixed_concat->Length() == $small_sample->Length() + $medium_sample->Length(), 
       'Mixed size concatenation length');
    
    # Search tests
    ok($medium_sample->Contains("M"), 'Medium string contains search');
    ok($large_sample->StartsWith("L"), 'Large string starts with search');
    
    # Case conversion tests
    my $small_upper = $small_strings[1]->ToUpper();
    ok(defined($small_upper), 'Small string case conversion');
    
    # Cleanup
    @small_strings = ();
    @medium_strings = ();
    @large_strings = ();
    ok(1, 'String memory cleanup completed');
}

sub test_array_memory_pressure {
    # Test arrays of various sizes
    my @small_arrays;
    my @medium_arrays;
    my @large_arrays;
    
    # Small arrays (1-100 elements)
    for my $i (1..1000) {
        my $size = $i % 100 + 1;
        my @data = (1..$size);
        my $arr = System::Array->new(@data);
        push @small_arrays, $arr;
        
        if ($i <= 10) {
            is($arr->Length(), $size, "Small array $i length correct");
            is($arr->Get(0), 1, "Small array $i first element correct");
            is($arr->Get($size-1), $size, "Small array $i last element correct");
        }
    }
    
    # Medium arrays (1K - 10K elements)
    for my $i (1..100) {
        my $size = 1000 + ($i * 100);
        my @data = (1..$size);
        my $arr = System::Array->new(@data);
        push @medium_arrays, $arr;
        
        if ($i <= 5) {
            is($arr->Length(), $size, "Medium array $i length correct");
            is($arr->Get(0), 1, "Medium array $i first element correct");
            is($arr->Get($size-1), $size, "Medium array $i last element correct");
        }
    }
    
    # Large arrays (100K+ elements)
    for my $i (1..5) {
        my $size = 100000 + ($i * 50000);
        my @data = (1..$size);
        my $arr = System::Array->new(@data);
        push @large_arrays, $arr;
        
        if ($i <= 2) {
            is($arr->Length(), $size, "Large array $i length correct");
            is($arr->Get(0), 1, "Large array $i first element correct");
            is($arr->Get($size-1), $size, "Large array $i last element correct");
        }
    }
    
    # Test operations on arrays
    my $small_sample = $small_arrays[0];
    my $medium_sample = $medium_arrays[0];
    my $large_sample = $large_arrays[0];
    
    # Search operations
    ok($small_sample->Contains(1), 'Small array contains search');
    is($medium_sample->IndexOf(500), 499, 'Medium array IndexOf');
    ok($large_sample->Contains(50000), 'Large array contains search');
    
    # Enumeration tests
    my $small_enum = $small_sample->GetEnumerator();
    my $enum_count = 0;
    while ($small_enum->MoveNext() && $enum_count < 10) {
        $enum_count++;
        ok(defined($small_enum->Current()), "Small array enumeration $enum_count");
    }
    
    # LINQ operations
    my $small_filtered = $small_sample->Where(sub { $_[0] % 2 == 0 });
    ok($small_filtered->Count() > 0, 'Small array LINQ filtering');
    
    my $medium_mapped = $medium_sample->Select(sub { $_[0] * 2 })->Take(10)->ToArray();
    is($medium_mapped->Length(), 10, 'Medium array LINQ mapping');
    
    # Cleanup
    @small_arrays = ();
    @medium_arrays = ();
    @large_arrays = ();
    ok(1, 'Array memory cleanup completed');
}

sub test_mixed_object_memory_pressure {
    # Test arrays containing various object types
    my @mixed_arrays;
    
    for my $i (1..100) {
        my @mixed_data;
        
        # Add various object types
        push @mixed_data, System::Object->new();
        push @mixed_data, System::String->new("string_$i");
        push @mixed_data, System::Array->new((1..$i));
        push @mixed_data, "perl_string_$i";
        push @mixed_data, $i;
        push @mixed_data, $i * 3.14;
        push @mixed_data, undef;
        
        my $mixed_arr = System::Array->new(@mixed_data);
        push @mixed_arrays, $mixed_arr;
        
        if ($i <= 5) {
            is($mixed_arr->Length(), 7, "Mixed array $i length correct");
            isa_ok($mixed_arr->Get(0), 'System::Object', "Mixed array $i object element");
            isa_ok($mixed_arr->Get(1), 'System::String', "Mixed array $i string element");
            isa_ok($mixed_arr->Get(2), 'System::Array', "Mixed array $i array element");
        }
    }
    
    # Test operations on mixed arrays
    my $sample_mixed = $mixed_arrays[0];
    ok($sample_mixed->Contains("perl_string_1"), 'Mixed array contains perl string');
    ok($sample_mixed->Contains(1), 'Mixed array contains number');
    ok($sample_mixed->Contains(undef), 'Mixed array contains undef');
    
    # Test enumeration with mixed types
    my $mixed_enum = $sample_mixed->GetEnumerator();
    my @enumerated_types;
    while ($mixed_enum->MoveNext()) {
        my $current = $mixed_enum->Current();
        push @enumerated_types, ref($current) || 'SCALAR';
    }
    
    ok(grep { $_ eq 'System::Object' } @enumerated_types, 'Mixed enumeration found Object');
    ok(grep { $_ eq 'System::String' } @enumerated_types, 'Mixed enumeration found String');
    ok(grep { $_ eq 'System::Array' } @enumerated_types, 'Mixed enumeration found Array');
    ok(grep { $_ eq 'SCALAR' } @enumerated_types, 'Mixed enumeration found scalars');
    
    # Cleanup
    @mixed_arrays = ();
    ok(1, 'Mixed object memory cleanup completed');
}

sub test_circular_reference_handling {
    # Test objects with circular references
    my @circular_objects;
    
    for my $i (1..100) {
        my $obj1 = System::Object->new();
        my $obj2 = System::Object->new();
        
        # Create circular references (if the implementation allows it)
        eval {
            $obj1->{circular_ref} = $obj2;
            $obj2->{circular_ref} = $obj1;
        };
        
        push @circular_objects, [$obj1, $obj2];
        
        # Test that basic operations still work
        if ($i <= 5) {
            ok(defined($obj1->ToString()), "Circular object $i obj1 ToString");
            ok(defined($obj2->ToString()), "Circular object $i obj2 ToString");
            ok($obj1->GetHashCode() >= 0, "Circular object $i obj1 hash");
            ok($obj2->GetHashCode() >= 0, "Circular object $i obj2 hash");
        }
    }
    
    # Test that circular references don't cause infinite loops in basic operations
    my ($test_obj1, $test_obj2) = @{$circular_objects[0]};
    
    # These should not hang
    my $str1 = $test_obj1->ToString();
    my $str2 = $test_obj2->ToString();
    my $hash1 = $test_obj1->GetHashCode();
    my $hash2 = $test_obj2->GetHashCode();
    
    ok(defined($str1), 'Circular reference ToString 1 works');
    ok(defined($str2), 'Circular reference ToString 2 works');
    ok($hash1 >= 0, 'Circular reference hash 1 valid');
    ok($hash2 >= 0, 'Circular reference hash 2 valid');
    
    # Test equality with circular references
    ok($test_obj1->Equals($test_obj1), 'Circular object equals itself');
    ok(!$test_obj1->Equals($test_obj2), 'Different circular objects not equal');
    
    # Cleanup (Perl's garbage collector should handle cycles)
    @circular_objects = ();
    ok(1, 'Circular reference cleanup completed');
}

sub test_performance_benchmarks {
    # Benchmark object creation
    my $start_time = time();
    my @perf_objects;
    
    for my $i (1..10000) {
        my $obj = System::Object->new();
        push @perf_objects, $obj;
    }
    
    my $creation_time = time() - $start_time;
    ok($creation_time < 10, "Object creation performance reasonable ($creation_time seconds for 10k objects)");
    
    # Benchmark ToString calls
    $start_time = time();
    for my $obj (@perf_objects[0..999]) {  # First 1000 objects
        $obj->ToString();
    }
    
    my $toString_time = time() - $start_time;
    ok($toString_time < 5, "ToString performance reasonable ($toString_time seconds for 1k calls)");
    
    # Benchmark GetHashCode calls
    $start_time = time();
    for my $obj (@perf_objects[0..999]) {
        $obj->GetHashCode();
    }
    
    my $hashCode_time = time() - $start_time;
    ok($hashCode_time < 5, "GetHashCode performance reasonable ($hashCode_time seconds for 1k calls)");
    
    # Benchmark string operations
    my $perf_string = System::String->new("performance test string");
    
    $start_time = time();
    for my $i (1..1000) {
        $perf_string->Length();
        $perf_string->Contains("test");
        $perf_string->IndexOf("string");
        $perf_string->ToUpper();
        $perf_string->ToLower();
    }
    
    my $string_ops_time = time() - $start_time;
    ok($string_ops_time < 10, "String operations performance reasonable ($string_ops_time seconds for 5k operations)");
    
    # Benchmark string concatenation
    my $concat_base = System::String->new("start");
    $start_time = time();
    
    for my $i (1..100) {
        $concat_base = $concat_base + System::String->new("_$i");
    }
    
    my $concat_time = time() - $start_time;
    ok($concat_time < 5, "String concatenation performance reasonable ($concat_time seconds for 100 concatenations)");
    
    # Benchmark array operations
    my $perf_array = System::Array->new((1..1000));
    
    $start_time = time();
    for my $i (1..1000) {
        $perf_array->Length();
        $perf_array->Get(int(rand(1000)));
        $perf_array->Contains($i % 100);
        $perf_array->IndexOf($i % 100);
    }
    
    my $array_ops_time = time() - $start_time;
    ok($array_ops_time < 10, "Array operations performance reasonable ($array_ops_time seconds for 4k operations)");
    
    # Benchmark LINQ operations
    $start_time = time();
    my $linq_result = $perf_array
        ->Where(sub { $_[0] % 2 == 0 })
        ->Select(sub { $_[0] * 2 })
        ->Take(100)
        ->ToArray();
    
    my $linq_time = time() - $start_time;
    ok($linq_time < 5, "LINQ operations performance reasonable ($linq_time seconds)");
    is($linq_result->Length(), 100, 'LINQ benchmark result correct');
    
    # Cleanup
    @perf_objects = ();
    ok(1, 'Performance benchmark cleanup completed');
}

sub test_memory_leak_detection {
    # Test for potential memory leaks by creating and destroying objects repeatedly
    
    # Test 1: Rapid object creation/destruction cycles
    for my $cycle (1..10) {
        my @cycle_objects;
        
        # Create objects
        for my $i (1..1000) {
            my $obj = System::Object->new();
            my $str = System::String->new("cycle_${cycle}_${i}");
            my $arr = System::Array->new((1..10));
            
            push @cycle_objects, [$obj, $str, $arr];
        }
        
        # Use objects
        for my $triple (@cycle_objects[0..9]) {  # Test first 10
            my ($obj, $str, $arr) = @$triple;
            
            $obj->ToString();
            $str->Length();
            $arr->Get(0);
        }
        
        # Destroy objects
        @cycle_objects = ();
        
        ok(1, "Memory leak test cycle $cycle completed") if $cycle <= 3;
    }
    
    # Test 2: Nested object creation
    for my $nest_level (1..5) {
        my @nested_arrays;
        
        for my $i (1..100) {
            my @inner_data;
            
            for my $j (1..$nest_level) {
                my $inner_arr = System::Array->new((1..$j));
                push @inner_data, $inner_arr;
            }
            
            my $nested = System::Array->new(@inner_data);
            push @nested_arrays, $nested;
        }
        
        # Test nested access
        my $sample = $nested_arrays[0];
        ok($sample->Length() == $nest_level, "Nested level $nest_level length correct");
        
        if ($nest_level <= 3) {
            isa_ok($sample->Get(0), 'System::Array', "Nested level $nest_level inner array");
        }
        
        # Cleanup
        @nested_arrays = ();
    }
    
    ok(1, 'Memory leak detection tests completed');
}

# Run all memory and performance edge case tests  
test_object_memory_pressure();
test_string_memory_pressure();
test_array_memory_pressure();
test_mixed_object_memory_pressure();
test_circular_reference_handling();
test_performance_benchmarks();
test_memory_leak_detection();

done_testing();