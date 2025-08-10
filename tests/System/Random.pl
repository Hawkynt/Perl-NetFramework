#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::Random;
use System::Int32;

BEGIN {
    use_ok('System::Random');
}

sub test_random_creation {
    # Test default constructor
    my $rnd1 = System::Random->new();
    isa_ok($rnd1, 'System::Random', 'Default constructor creates Random object');
    ok(defined($rnd1), 'Random object is defined');
    
    # Test constructor with seed
    my $rnd2 = System::Random->new(42);
    isa_ok($rnd2, 'System::Random', 'Seeded constructor creates Random object');
    
    # Test constructor with Int32 seed
    my $int32_seed = System::Int32->new(123);
    my $rnd3 = System::Random->new($int32_seed);
    isa_ok($rnd3, 'System::Random', 'Constructor with Int32 seed works');
    
    # Test ToString contains seed info
    like($rnd2->ToString(), qr/42/, 'ToString includes seed information');
    
    # Test negative seed
    my $rnd4 = System::Random->new(-100);
    isa_ok($rnd4, 'System::Random', 'Negative seed constructor works');
}

sub test_random_next_basic {
    my $rnd = System::Random->new(42);
    
    # Test Next() - basic version
    for (1..10) {
        my $val = $rnd->Next();
        ok($val >= 0, "Next() returns non-negative value: $val");
        ok($val < 2147483647, "Next() returns value less than Int32.MaxValue: $val");
        ok($val == int($val), "Next() returns integer value: $val");
    }
    
    # Test reproducibility with same seed
    my $rnd_a = System::Random->new(100);
    my $rnd_b = System::Random->new(100);
    
    my @seq_a = map { $rnd_a->Next() } (1..5);
    my @seq_b = map { $rnd_b->Next() } (1..5);
    
    for my $i (0..4) {
        is($seq_a[$i], $seq_b[$i], "Same seed produces same sequence at position $i");
    }
}

sub test_random_next_with_max {
    my $rnd = System::Random->new(42);
    
    # Test Next(max) with various values
    for my $max (1, 10, 100, 1000, 50000) {
        for (1..10) {
            my $val = $rnd->Next($max);
            ok($val >= 0, "Next($max) returns non-negative: $val");
            ok($val < $max, "Next($max) returns value less than max: $val < $max");
            ok($val == int($val), "Next($max) returns integer: $val");
        }
    }
    
    # Test edge case: max = 1
    for (1..5) {
        my $val = $rnd->Next(1);
        is($val, 0, 'Next(1) always returns 0');
    }
    
    # Test error condition: negative max
    eval { $rnd->Next(-1); };
    ok($@, 'Next() with negative max throws exception');
}

sub test_random_next_with_range {
    my $rnd = System::Random->new(42);
    
    # Test Next(min, max) with various ranges
    my @ranges = ([0, 10], [5, 15], [-10, 10], [100, 200], [-50, -25]);
    
    for my $range (@ranges) {
        my ($min, $max) = @$range;
        for (1..10) {
            my $val = $rnd->Next($min, $max);
            ok($val >= $min, "Next($min, $max) returns value >= min: $val >= $min");
            ok($val < $max, "Next($min, $max) returns value < max: $val < $max");
            ok($val == int($val), "Next($min, $max) returns integer: $val");
        }
    }
    
    # Test edge case: min = max - 1
    for (1..5) {
        my $val = $rnd->Next(5, 6);
        is($val, 5, 'Next(5, 6) always returns 5');
    }
    
    # Test error condition: min >= max
    eval { $rnd->Next(10, 5); };
    ok($@, 'Next() with min >= max throws exception');
}

sub test_random_nextDouble {
    my $rnd = System::Random->new(42);
    
    # Test NextDouble basic properties
    for (1..20) {
        my $val = $rnd->NextDouble();
        ok($val >= 0.0, "NextDouble returns non-negative: $val");
        ok($val < 1.0, "NextDouble returns value less than 1.0: $val");
        ok($val != int($val), "NextDouble returns fractional value: $val") unless $val == 0;
    }
    
    # Test precision - should not always return same values
    my @values = map { $rnd->NextDouble() } (1..50);
    my %unique = map { $_ => 1 } @values;
    ok(keys(%unique) > 30, 'NextDouble generates diverse values');
    
    # Test reproducibility
    my $rnd_a = System::Random->new(200);
    my $rnd_b = System::Random->new(200);
    
    for (1..5) {
        my $val_a = $rnd_a->NextDouble();
        my $val_b = $rnd_b->NextDouble();
        is($val_a, $val_b, "NextDouble with same seed produces same values");
    }
}

sub test_random_nextSingle {
    my $rnd = System::Random->new(42);
    
    # Test NextSingle basic properties (should behave like NextDouble for our implementation)
    for (1..10) {
        my $val = $rnd->NextSingle();
        ok($val >= 0.0, "NextSingle returns non-negative: $val");
        ok($val < 1.0, "NextSingle returns value less than 1.0: $val");
    }
}

sub test_random_nextBoolean {
    my $rnd = System::Random->new(42);
    
    # Test NextBoolean returns only 0 or 1
    my %values;
    for (1..50) {
        my $val = $rnd->NextBoolean();
        ok($val == 0 || $val == 1, "NextBoolean returns 0 or 1: $val");
        $values{$val}++;
    }
    
    # Should have both values over 50 trials
    ok(exists $values{0}, 'NextBoolean produces 0 values');
    ok(exists $values{1}, 'NextBoolean produces 1 values');
}

sub test_random_nextBytes {
    my $rnd = System::Random->new(42);
    
    # Test with array reference
    my @buffer = (0) x 20;
    $rnd->NextBytes(\\@buffer);
    
    # Check values are in valid byte range
    for my $i (0..$#buffer) {
        my $byte = $buffer[$i];
        ok($byte >= 0 && $byte <= 255, "Buffer[$i] is valid byte: $byte");
    }
    
    # Check we don't get all zeros
    my $non_zero_count = grep { $_ != 0 } @buffer;
    ok($non_zero_count > 0, 'NextBytes produces non-zero values');
    
    # Test with different buffer sizes
    for my $size (1, 5, 17, 64, 100) {
        my @buf = (0) x $size;
        $rnd->NextBytes(\\@buf);
        is(scalar(@buf), $size, "NextBytes fills buffer of size $size");
    }
    
    # Test error conditions
    eval { $rnd->NextBytes(undef); };
    ok($@, 'NextBytes with undef buffer throws exception');
    
    eval { $rnd->NextBytes("not an array"); };
    ok($@, 'NextBytes with invalid buffer throws exception');
}

sub test_random_nextString {
    my $rnd = System::Random->new(42);
    
    # Test default NextString
    my $str1 = $rnd->NextString();
    is(length($str1), 10, 'Default NextString returns 10 characters');
    like($str1, qr/^[A-Za-z0-9]+$/, 'Default NextString uses alphanumeric charset');
    
    # Test NextString with specific length
    for my $len (1, 5, 8, 20, 100) {
        my $str = $rnd->NextString($len);
        is(length($str), $len, "NextString($len) returns correct length");
        like($str, qr/^[A-Za-z0-9]+$/, "NextString($len) uses alphanumeric charset");
    }
    
    # Test NextString with custom charset
    my $str2 = $rnd->NextString(10, "ABC123");
    is(length($str2), 10, 'NextString with custom charset returns correct length');
    like($str2, qr/^[ABC123]+$/, 'NextString uses custom charset correctly');
    
    # Test with single character charset
    my $str3 = $rnd->NextString(5, "X");
    is($str3, "XXXXX", 'NextString with single char charset works');
    
    # Test with empty length
    my $str4 = $rnd->NextString(0);
    is($str4, '', 'NextString(0) returns empty string');
    
    # Test reproducibility
    my $rnd_a = System::Random->new(300);
    my $rnd_b = System::Random->new(300);
    my $str_a = $rnd_a->NextString(15);
    my $str_b = $rnd_b->NextString(15);
    is($str_a, $str_b, 'NextString with same seed produces same result');
    
    # Test error condition
    eval { $rnd->NextString(-1); };
    ok($@, 'NextString with negative length throws exception');
}

sub test_random_sample {
    my $rnd = System::Random->new(42);
    
    # Test Sample with array
    my @test_array = (10, 20, 30, 40, 50);
    my %found_values;
    
    for (1..50) {
        my $sample = $rnd->Sample(\\@test_array);
        ok(grep { $_ == $sample } @test_array, "Sample returns element from array: $sample");
        $found_values{$sample}++;
    }
    
    # Should find all values over many samples
    ok(keys(%found_values) >= 3, 'Sample returns diverse values from array');
    
    # Test Sample with single element
    my @single = (42);
    for (1..5) {
        my $sample = $rnd->Sample(\\@single);
        is($sample, 42, 'Sample from single-element array returns that element');
    }
    
    # Test error conditions
    eval { $rnd->Sample(undef); };
    ok($@, 'Sample with undef array throws exception');
    
    eval { $rnd->Sample([]); };
    ok($@, 'Sample with empty array throws exception');
    
    eval { $rnd->Sample("not array"); };
    ok($@, 'Sample with non-array throws exception');
}

sub test_random_shuffle {
    my $rnd = System::Random->new(42);
    
    # Test Shuffle preserves all elements
    my @original = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    my @to_shuffle = @original;
    
    $rnd->Shuffle(\\@to_shuffle);
    
    # Check all original elements are present
    is(scalar(@to_shuffle), scalar(@original), 'Shuffle preserves array length');
    
    for my $orig (@original) {
        ok(grep { $_ == $orig } @to_shuffle, "Original element $orig still present after shuffle");
    }
    
    # Test shuffle actually changes order (run multiple times)
    my $changes = 0;
    for (1..10) {
        my @test = (1, 2, 3, 4, 5);
        my @original_test = @test;
        $rnd->Shuffle(\\@test);
        
        # Check if order changed
        my $same = 1;
        for my $i (0..$#test) {
            if ($test[$i] != $original_test[$i]) {
                $same = 0;
                last;
            }
        }
        $changes++ unless $same;
    }
    ok($changes > 0, 'Shuffle actually changes element order');
    
    # Test single element array
    my @single = (42);
    $rnd->Shuffle(\\@single);
    is($single[0], 42, 'Shuffle of single element preserves element');
    
    # Test empty array
    my @empty = ();
    $rnd->Shuffle(\\@empty);
    is(scalar(@empty), 0, 'Shuffle of empty array works');
}

sub test_random_gaussian {
    my $rnd = System::Random->new(42);
    
    # Test basic NextGaussian
    for (1..10) {
        my $val = $rnd->NextGaussian();
        ok(defined($val), 'NextGaussian returns defined value');
        ok(abs($val) < 10, 'NextGaussian returns reasonable value'); # Most values should be within +/-10 for standard normal
    }
    
    # Test NextGaussian with mean and stddev
    for (1..10) {
        my $val = $rnd->NextGaussian(5.0, 2.0);
        ok(defined($val), 'NextGaussian(mean, stddev) returns defined value');
        # Most values should be reasonably close to mean=5
        ok(abs($val - 5.0) < 20, 'NextGaussian with mean/stddev returns reasonable value');
    }
    
    # Test statistical properties over many samples
    my @samples = map { $rnd->NextGaussian() } (1..1000);
    my $mean = 0;
    $mean += $_ for @samples;
    $mean /= @samples;
    
    ok(abs($mean) < 0.2, 'NextGaussian has approximately zero mean over many samples');
}

sub test_random_shared {
    # Test Shared static method
    my $shared1 = System::Random->Shared();
    my $shared2 = System::Random->Shared();
    
    is($shared1, $shared2, 'Shared() returns same instance');
    isa_ok($shared1, 'System::Random', 'Shared instance is Random object');
    
    # Test Shared instance works
    my $val1 = $shared1->Next();
    my $val2 = $shared2->Next();
    
    ok(defined($val1) && defined($val2), 'Shared instance generates values');
    isnt($val1, $val2, 'Shared instance generates different sequential values');
}

sub test_random_setSeed {
    my $rnd = System::Random->new(100);
    
    # Get first few values
    my @first_seq = map { $rnd->Next() } (1..3);
    
    # Reset seed and get values again
    $rnd->SetSeed(100);
    my @second_seq = map { $rnd->Next() } (1..3);
    
    for my $i (0..2) {
        is($first_seq[$i], $second_seq[$i], "SetSeed resets sequence correctly at position $i");
    }
    
    # Test SetSeed changes internal state
    like($rnd->ToString(), qr/100/, 'SetSeed updates ToString output');
    
    # Test SetSeed with different value
    $rnd->SetSeed(999);
    my $val = $rnd->Next();
    
    $rnd->SetSeed(999);
    my $val2 = $rnd->Next();
    
    is($val, $val2, 'SetSeed with same value produces same result');
}

sub test_random_edge_cases {
    # Test with zero seed
    my $rnd_zero = System::Random->new(0);
    my $val = $rnd_zero->Next();
    ok(defined($val), 'Random with zero seed works');
    
    # Test with maximum seed value
    my $rnd_max = System::Random->new(2147483647);
    my $val_max = $rnd_max->Next();
    ok(defined($val_max), 'Random with max seed works');
    
    # Test with minimum seed value
    my $rnd_min = System::Random->new(-2147483648);
    my $val_min = $rnd_min->Next();
    ok(defined($val_min), 'Random with min seed works');
    
    # Test multiple instances don't interfere
    my $rnd1 = System::Random->new(42);
    my $rnd2 = System::Random->new(42);
    
    my $val1_1 = $rnd1->Next();
    my $val2_1 = $rnd2->Next();
    my $val1_2 = $rnd1->Next();
    my $val2_2 = $rnd2->Next();
    
    is($val1_1, $val2_1, 'Same seed produces same first value');
    is($val1_2, $val2_2, 'Same seed produces same second value');
}

sub test_random_performance {
    my $rnd = System::Random->new(42);
    
    # Test that we can generate many random numbers quickly
    my $start_time = time();
    my @values = map { $rnd->Next() } (1..10000);
    my $end_time = time();
    
    is(scalar(@values), 10000, 'Generated 10000 random numbers');
    ok($end_time - $start_time < 5, 'Random number generation is reasonably fast');
    
    # Test uniqueness in large sample
    my %seen;
    my $duplicates = 0;
    for my $val (@values) {
        $duplicates++ if exists $seen{$val};
        $seen{$val}++;
    }
    
    # With a 32-bit range, we shouldn't see many duplicates in 10k samples
    ok($duplicates < 100, 'Random numbers show good distribution');
}

# Run all comprehensive tests
test_random_creation();
test_random_next_basic();
test_random_next_with_max();
test_random_next_with_range();
test_random_nextDouble();
test_random_nextSingle();
test_random_nextBoolean();
test_random_nextBytes();
test_random_nextString();
test_random_sample();
test_random_shuffle();
test_random_gaussian();
test_random_shared();
test_random_setSeed();
test_random_edge_cases();
test_random_performance();

done_testing();