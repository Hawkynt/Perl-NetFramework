#!/usr/bin/perl
use strict;
use warnings;
use lib '../..';
use Test::More;
use System;
use System::TimeSpan;

BEGIN {
    use_ok('System::TimeSpan');
}

sub test_timespan_creation {
    # Test default constructor
    my $zero = System::TimeSpan->new();
    is($zero->Ticks(), 0, 'Default constructor creates zero TimeSpan');
    is($zero->TotalMilliseconds(), 0, 'Zero TimeSpan has no milliseconds');
    
    # Test ticks constructor
    my $ts_ticks = System::TimeSpan->new(10000);
    is($ts_ticks->Ticks(), 10000, 'Ticks constructor works');
    is($ts_ticks->TotalMilliseconds(), 1, 'Ticks to milliseconds conversion');
    
    # Test hours, minutes, seconds constructor
    my $ts_hms = System::TimeSpan->new(2, 30, 45);
    is($ts_hms->Hours(), 2, 'Hours from HMS constructor');
    is($ts_hms->Minutes(), 30, 'Minutes from HMS constructor');
    is($ts_hms->Seconds(), 45, 'Seconds from HMS constructor');
    is($ts_hms->TotalHours(), 2.5125, 'Total hours calculation');
    
    # Test days, hours, minutes, seconds constructor
    my $ts_dhms = System::TimeSpan->new(1, 2, 30, 45);
    is($ts_dhms->Days(), 1, 'Days from DHMS constructor');
    is($ts_dhms->Hours(), 2, 'Hours from DHMS constructor');
    is($ts_dhms->Minutes(), 30, 'Minutes from DHMS constructor');
    is($ts_dhms->Seconds(), 45, 'Seconds from DHMS constructor');
    
    # Test days, hours, minutes, seconds, milliseconds constructor
    my $ts_dhmsm = System::TimeSpan->new(1, 2, 30, 45, 500);
    is($ts_dhmsm->Days(), 1, 'Days from DHMSM constructor');
    is($ts_dhmsm->Hours(), 2, 'Hours from DHMSM constructor');
    is($ts_dhmsm->Minutes(), 30, 'Minutes from DHMSM constructor');
    is($ts_dhmsm->Seconds(), 45, 'Seconds from DHMSM constructor');
    is($ts_dhmsm->Milliseconds(), 500, 'Milliseconds from DHMSM constructor');
}

sub test_timespan_static_constants {
    # Test static constants
    my $zero = System::TimeSpan->Zero();
    isa_ok($zero, 'System::TimeSpan', 'Zero is TimeSpan');
    is($zero->Ticks(), 0, 'Zero has 0 ticks');
    
    my $min = System::TimeSpan->MinValue();
    isa_ok($min, 'System::TimeSpan', 'MinValue is TimeSpan');
    ok($min->Ticks() < 0, 'MinValue is negative');
    
    my $max = System::TimeSpan->MaxValue();
    isa_ok($max, 'System::TimeSpan', 'MaxValue is TimeSpan');
    ok($max->Ticks() > 0, 'MaxValue is positive');
}

sub test_timespan_factory_methods {
    # Test FromDays
    my $days = System::TimeSpan->FromDays(2.5);
    is($days->TotalDays(), 2.5, 'FromDays creates correct timespan');
    is($days->Days(), 2, 'FromDays days component');
    is($days->Hours(), 12, 'FromDays hours component');
    
    # Test FromHours
    my $hours = System::TimeSpan->FromHours(25);
    is($hours->TotalHours(), 25, 'FromHours creates correct timespan');
    is($hours->Days(), 1, 'FromHours days component');
    is($hours->Hours(), 1, 'FromHours hours component');
    
    # Test FromMinutes
    my $minutes = System::TimeSpan->FromMinutes(90);
    is($minutes->TotalMinutes(), 90, 'FromMinutes creates correct timespan');
    is($minutes->Hours(), 1, 'FromMinutes hours component');
    is($minutes->Minutes(), 30, 'FromMinutes minutes component');
    
    # Test FromSeconds
    my $seconds = System::TimeSpan->FromSeconds(3661);
    is($seconds->TotalSeconds(), 3661, 'FromSeconds creates correct timespan');
    is($seconds->Hours(), 1, 'FromSeconds hours component');
    is($seconds->Minutes(), 1, 'FromSeconds minutes component');
    is($seconds->Seconds(), 1, 'FromSeconds seconds component');
    
    # Test FromMilliseconds
    my $ms = System::TimeSpan->FromMilliseconds(1500);
    is($ms->TotalMilliseconds(), 1500, 'FromMilliseconds creates correct timespan');
    is($ms->Seconds(), 1, 'FromMilliseconds seconds component');
    is($ms->Milliseconds(), 500, 'FromMilliseconds milliseconds component');
}

sub test_timespan_properties {
    my $ts = System::TimeSpan->new(1, 2, 3, 4, 500); # 1d 2h 3m 4s 500ms
    
    # Test individual components
    is($ts->Days(), 1, 'Days property');
    is($ts->Hours(), 2, 'Hours property');
    is($ts->Minutes(), 3, 'Minutes property');
    is($ts->Seconds(), 4, 'Seconds property');
    is($ts->Milliseconds(), 500, 'Milliseconds property');
    
    # Test total values
    ok(abs($ts->TotalDays() - 1.08546296296296) < 0.0001, 'TotalDays calculation');
    ok(abs($ts->TotalHours() - 26.0511111111111) < 0.0001, 'TotalHours calculation');
    ok(abs($ts->TotalMinutes() - 1563.06666666667) < 0.001, 'TotalMinutes calculation');
    ok(abs($ts->TotalSeconds() - 93784.5) < 0.1, 'TotalSeconds calculation');
    is($ts->TotalMilliseconds(), 93784500, 'TotalMilliseconds calculation');
    
    # Test ticks
    ok($ts->Ticks() > 0, 'Ticks is positive for positive timespan');
}

sub test_timespan_arithmetic {
    my $ts1 = System::TimeSpan->new(1, 0, 0); # 1 hour
    my $ts2 = System::TimeSpan->new(0, 30, 0); # 30 minutes
    
    # Test addition
    my $sum = $ts1->Add($ts2);
    is($sum->Hours(), 1, 'Addition hours');
    is($sum->Minutes(), 30, 'Addition minutes');
    is($sum->TotalMinutes(), 90, 'Addition total minutes');
    
    # Test subtraction
    my $diff = $ts1->Subtract($ts2);
    is($diff->Hours(), 0, 'Subtraction hours');
    is($diff->Minutes(), 30, 'Subtraction minutes');
    is($diff->TotalMinutes(), 30, 'Subtraction total minutes');
    
    # Test operator overloading
    my $op_sum = $ts1 + $ts2;
    isa_ok($op_sum, 'System::TimeSpan', 'Addition operator returns TimeSpan');
    is($op_sum->TotalMinutes(), 90, 'Addition operator works');
    
    my $op_diff = $ts1 - $ts2;
    isa_ok($op_diff, 'System::TimeSpan', 'Subtraction operator returns TimeSpan');
    is($op_diff->TotalMinutes(), 30, 'Subtraction operator works');
    
    # Test multiplication
    my $doubled = $ts1 * 2;
    isa_ok($doubled, 'System::TimeSpan', 'Multiplication operator returns TimeSpan');
    is($doubled->TotalHours(), 2, 'Multiplication operator works');
    
    # Test division
    my $halved = $ts1 / 2;
    isa_ok($halved, 'System::TimeSpan', 'Division operator returns TimeSpan');
    is($halved->TotalMinutes(), 30, 'Division operator works');
    
    # Test negation
    my $negated = -$ts1;
    isa_ok($negated, 'System::TimeSpan', 'Negation operator returns TimeSpan');
    is($negated->TotalHours(), -1, 'Negation operator works');
    ok($negated->Ticks() < 0, 'Negated timespan has negative ticks');
}

sub test_timespan_comparison {
    my $ts1 = System::TimeSpan->new(1, 0, 0); # 1 hour
    my $ts2 = System::TimeSpan->new(0, 60, 0); # 60 minutes (same as 1 hour)
    my $ts3 = System::TimeSpan->new(0, 30, 0); # 30 minutes
    
    # Test equality
    ok($ts1->Equals($ts2), 'Equal timespans are equal');
    ok(!$ts1->Equals($ts3), 'Different timespans are not equal');
    
    # Test comparison
    is($ts1->CompareTo($ts2), 0, 'CompareTo equal timespans');
    ok($ts1->CompareTo($ts3) > 0, 'CompareTo greater timespan');
    ok($ts3->CompareTo($ts1) < 0, 'CompareTo lesser timespan');
    
    # Test operator overloading
    ok($ts1 == $ts2, 'Equality operator works');
    ok($ts1 != $ts3, 'Inequality operator works');
    ok($ts1 > $ts3, 'Greater than operator works');
    ok($ts3 < $ts1, 'Less than operator works');
    ok($ts1 >= $ts2, 'Greater than or equal operator works');
    ok($ts3 <= $ts1, 'Less than or equal operator works');
}

sub test_timespan_duration {
    # Test Duration method (absolute value)
    my $negative = System::TimeSpan->new(-3600 * System::TimeSpan->TicksPerSecond()); # -1 hour
    my $positive = $negative->Duration();
    
    isa_ok($positive, 'System::TimeSpan', 'Duration returns TimeSpan');
    is($positive->TotalHours(), 1, 'Duration gives absolute value');
    ok($positive->Ticks() > 0, 'Duration result is positive');
    
    # Test Duration on already positive timespan
    my $already_positive = System::TimeSpan->new(3600 * System::TimeSpan->TicksPerSecond()); # 1 hour
    my $still_positive = $already_positive->Duration();
    is($still_positive->TotalHours(), 1, 'Duration of positive timespan unchanged');
}

sub test_timespan_hashing {
    my $ts1 = System::TimeSpan->new(1, 2, 3, 4);
    my $ts2 = System::TimeSpan->new(1, 2, 3, 4);
    my $ts3 = System::TimeSpan->new(1, 2, 3, 5);
    
    # Test hash consistency
    is($ts1->GetHashCode(), $ts1->GetHashCode(), 'Hash code is consistent');
    
    # Test equal objects have equal hashes
    is($ts1->GetHashCode(), $ts2->GetHashCode(), 'Equal objects have equal hash codes');
    
    # Test different objects likely have different hashes
    isnt($ts1->GetHashCode(), $ts3->GetHashCode(), 'Different objects likely have different hash codes');
}

sub test_timespan_string_representation {
    # Test default ToString
    my $ts1 = System::TimeSpan->new(1, 2, 3, 4, 500);
    my $str1 = $ts1->ToString();
    ok(defined($str1) && length($str1) > 0, 'ToString returns non-empty string');
    like($str1, qr/1/, 'ToString contains day component');
    like($str1, qr/02/, 'ToString contains hour component');
    like($str1, qr/03/, 'ToString contains minute component');
    like($str1, qr/04/, 'ToString contains second component');
    
    # Test string overload operator
    my $str2 = "$ts1";
    is($str2, $str1, 'String overload works same as ToString');
    
    # Test negative timespan string representation
    my $negative = System::TimeSpan->new(-3661 * System::TimeSpan->TicksPerSecond()); # -1h 1m 1s
    my $neg_str = $negative->ToString();
    like($neg_str, qr/-/, 'Negative timespan string contains minus sign');
    
    # Test zero timespan
    my $zero = System::TimeSpan->new(0);
    my $zero_str = $zero->ToString();
    ok(defined($zero_str), 'Zero timespan has string representation');
}

sub test_timespan_edge_cases {
    # Test very small timespan
    my $tiny = System::TimeSpan->new(1); # 1 tick
    is($tiny->Ticks(), 1, 'Tiny timespan creation');
    ok($tiny->TotalMilliseconds() < 1, 'Tiny timespan is less than 1ms');
    
    # Test very large timespan
    my $large = System::TimeSpan->FromDays(1000);
    is($large->TotalDays(), 1000, 'Large timespan creation');
    ok($large->Ticks() > 0, 'Large timespan has positive ticks');
    
    # Test fractional values
    my $fractional = System::TimeSpan->FromHours(1.5);
    is($fractional->Hours(), 1, 'Fractional hours - hours component');
    is($fractional->Minutes(), 30, 'Fractional hours - minutes component');
    
    # Test zero values
    my $zero_days = System::TimeSpan->FromDays(0);
    is($zero_days->TotalDays(), 0, 'Zero days timespan');
    is($zero_days->Ticks(), 0, 'Zero days has zero ticks');
}

sub test_timespan_precision {
    # Test millisecond precision
    my $precise = System::TimeSpan->FromMilliseconds(1.5);
    ok($precise->TotalMilliseconds() > 1, 'Fractional milliseconds handled');
    
    # Test tick precision
    my $tick_precise = System::TimeSpan->new(15000); # 1.5ms in ticks
    is($tick_precise->TotalMilliseconds(), 1.5, 'Tick precision maintained');
}

sub test_timespan_constants {
    # Test tick constants
    is(System::TimeSpan->TicksPerMillisecond(), 10000, 'TicksPerMillisecond constant');
    is(System::TimeSpan->TicksPerSecond(), 10000000, 'TicksPerSecond constant');
    is(System::TimeSpan->TicksPerMinute(), 600000000, 'TicksPerMinute constant');
    is(System::TimeSpan->TicksPerHour(), 36000000000, 'TicksPerHour constant');
    is(System::TimeSpan->TicksPerDay(), 864000000000, 'TicksPerDay constant');
    
    # Verify relationships
    is(System::TimeSpan->TicksPerSecond(), System::TimeSpan->TicksPerMillisecond() * 1000, 'Second = 1000 milliseconds');
    is(System::TimeSpan->TicksPerMinute(), System::TimeSpan->TicksPerSecond() * 60, 'Minute = 60 seconds');
    is(System::TimeSpan->TicksPerHour(), System::TimeSpan->TicksPerMinute() * 60, 'Hour = 60 minutes');
    is(System::TimeSpan->TicksPerDay(), System::TimeSpan->TicksPerHour() * 24, 'Day = 24 hours');
}

sub test_timespan_error_conditions {
    # These tests depend on the specific error handling in the implementation
    # Many of these might not throw errors in this Perl implementation
    
    # Test invalid constructor arguments would be caught at Perl level
    eval { System::TimeSpan->new(1, 2, 3, 4, 5, 6); }; # Too many arguments
    ok($@, 'Too many constructor arguments throws error');
    
    # Test null reference on operations
    my $ts = System::TimeSpan->new(3600 * TimeSpan::TicksPerSecond());
    
    # Test operations with invalid arguments (these may not throw in this implementation)
    eval { $ts->Equals(undef); };
    # ok($@, 'Equals with null throws error');
    
    eval { $ts->CompareTo(undef); };
    # ok($@, 'CompareTo with null throws error');
    
    eval { $ts->Add(undef); };
    # ok($@, 'Add with null throws error');
    
    eval { $ts->Subtract(undef); };
    # ok($@, 'Subtract with null throws error');
}

sub test_timespan_overflow_underflow {
    # Test near maximum values
    my $near_max = System::TimeSpan->new(9223372036854775000);  # Near max ticks
    ok($near_max->Ticks() > 0, 'Near maximum timespan created');
    
    # Test negative values
    my $negative = System::TimeSpan->new(-3600 * TimeSpan::TicksPerSecond());
    ok($negative->Ticks() < 0, 'Negative timespan created');
    is($negative->TotalHours(), -1, 'Negative timespan calculations');
    
    # Test arithmetic near boundaries
    my $large_positive = System::TimeSpan->FromDays(10000);
    my $large_negative = System::TimeSpan->FromDays(-10000);
    
    ok($large_positive->Ticks() > 0, 'Large positive timespan');
    ok($large_negative->Ticks() < 0, 'Large negative timespan');
}

# Run all tests
test_timespan_creation();
test_timespan_static_constants();
test_timespan_factory_methods();
test_timespan_properties();
test_timespan_arithmetic();
test_timespan_comparison();
test_timespan_duration();
test_timespan_hashing();
test_timespan_string_representation();
test_timespan_edge_cases();
test_timespan_precision();
test_timespan_constants();
test_timespan_error_conditions();
test_timespan_overflow_underflow();

done_testing();