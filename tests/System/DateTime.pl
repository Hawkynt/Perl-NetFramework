#!/usr/bin/perl
use strict;
use warnings;
use lib '../../';
use Test::More;
use System;
use System::DateTime;

BEGIN {
    use_ok('System::DateTime');
}

sub test_datetime_creation {
    my $dt = System::DateTime->new(2023, 12, 25, 14, 30, 45, 123);
    isa_ok($dt, 'System::DateTime', 'DateTime creation');
    
    is($dt->Year(), 2023, 'Year property');
    is($dt->Month(), 12, 'Month property');
    is($dt->Day(), 25, 'Day property');
    is($dt->Hour(), 14, 'Hour property');
    is($dt->Minute(), 30, 'Minute property');
    is($dt->Second(), 45, 'Second property');
    is($dt->Millisecond(), 123, 'Millisecond property');
}

sub test_datetime_defaults {
    my $dt = System::DateTime->new(2023, 12, 25);
    is($dt->Hour(), 0, 'Default hour is 0');
    is($dt->Minute(), 0, 'Default minute is 0');
    is($dt->Second(), 0, 'Default second is 0');
    is($dt->Millisecond(), 0, 'Default millisecond is 0');
}

sub test_datetime_validation {
    eval { System::DateTime->new(0, 1, 1); };
    ok($@, 'Year validation - too small');
    
    eval { System::DateTime->new(10000, 1, 1); };
    ok($@, 'Year validation - too large');
    
    eval { System::DateTime->new(2023, 0, 1); };
    ok($@, 'Month validation - too small');
    
    eval { System::DateTime->new(2023, 13, 1); };
    ok($@, 'Month validation - too large');
    
    eval { System::DateTime->new(2023, 1, 0); };
    ok($@, 'Day validation - too small');
    
    eval { System::DateTime->new(2023, 2, 30); };
    ok($@, 'Day validation - February 30th');
    
    eval { System::DateTime->new(2023, 1, 1, 24, 0, 0); };
    ok($@, 'Hour validation - too large');
    
    eval { System::DateTime->new(2023, 1, 1, 0, 60, 0); };
    ok($@, 'Minute validation - too large');
    
    eval { System::DateTime->new(2023, 1, 1, 0, 0, 60); };
    ok($@, 'Second validation - too large');
}

sub test_leap_year {
    my $dt2020 = System::DateTime->new(2020, 2, 29); # Leap year
    is($dt2020->Day(), 29, 'Leap year February 29th');
    
    eval { System::DateTime->new(2021, 2, 29); }; # Not leap year
    ok($@, 'Non-leap year February 29th validation');
}

sub test_datetime_properties {
    my $dt = System::DateTime->new(2023, 7, 15, 10, 30, 45);
    
    my $date = $dt->Date();
    is($date->Year(), 2023, 'Date property year');
    is($date->Month(), 7, 'Date property month');
    is($date->Day(), 15, 'Date property day');
    is($date->Hour(), 0, 'Date property hour is 0');
    
    my $timeOfDay = $dt->TimeOfDay();
    isa_ok($timeOfDay, 'System::TimeSpan', 'TimeOfDay returns TimeSpan');
    is($timeOfDay->Hours(), 10, 'TimeOfDay hours');
    is($timeOfDay->Minutes(), 30, 'TimeOfDay minutes');
    is($timeOfDay->Seconds(), 45, 'TimeOfDay seconds');
}

sub test_datetime_arithmetic {
    my $dt = System::DateTime->new(2023, 1, 15, 12, 0, 0);
    
    my $dt_plus_days = $dt->AddDays(10);
    is($dt_plus_days->Day(), 25, 'AddDays works');
    
    my $dt_plus_hours = $dt->AddHours(6);
    is($dt_plus_hours->Hour(), 18, 'AddHours works');
    
    my $dt_plus_minutes = $dt->AddMinutes(30);
    is($dt_plus_minutes->Minute(), 30, 'AddMinutes works');
    
    my $dt_plus_seconds = $dt->AddSeconds(45);
    is($dt_plus_seconds->Second(), 45, 'AddSeconds works');
}

sub test_datetime_subtraction {
    my $dt1 = System::DateTime->new(2023, 1, 15, 12, 0, 0);
    my $dt2 = System::DateTime->new(2023, 1, 10, 12, 0, 0);
    
    my $diff = $dt1->Subtract($dt2);
    isa_ok($diff, 'System::TimeSpan', 'DateTime subtraction returns TimeSpan');
    is($diff->Days(), 5, 'DateTime difference is 5 days');
    
    my $timespan = System::TimeSpan->FromHours(6);
    my $dt_minus_span = $dt1->Subtract($timespan);
    isa_ok($dt_minus_span, 'System::DateTime', 'DateTime - TimeSpan returns DateTime');
    is($dt_minus_span->Hour(), 6, 'Subtract TimeSpan works');
}

sub test_datetime_comparison {
    my $dt1 = System::DateTime->new(2023, 1, 15);
    my $dt2 = System::DateTime->new(2023, 1, 15);
    my $dt3 = System::DateTime->new(2023, 1, 16);
    
    ok($dt1->Equals($dt2), 'Equal DateTimes');
    ok(!$dt1->Equals($dt3), 'Unequal DateTimes');
    
    is($dt1->CompareTo($dt2), 0, 'CompareTo equal');
    ok($dt1->CompareTo($dt3) < 0, 'CompareTo less than');
    ok($dt3->CompareTo($dt1) > 0, 'CompareTo greater than');
}

sub test_datetime_formatting {
    my $dt = System::DateTime->new(2023, 12, 25, 14, 30, 45);
    
    like($dt->ToString(), qr/2023-12-25 14:30:45/, 'Default ToString format');
    like($dt->ToString('d'), qr/2023-12-25/, 'Date format');
    like($dt->ToString('T'), qr/14:30:45/, 'Time format');
    like($dt->ToString('t'), qr/14:30/, 'Short time format');
}

sub test_datetime_parsing {
    my $dt = System::DateTime->Parse('2023-12-25 14:30:45');
    isa_ok($dt, 'System::DateTime', 'Parse returns DateTime');
    is($dt->Year(), 2023, 'Parsed year');
    is($dt->Month(), 12, 'Parsed month');
    is($dt->Day(), 25, 'Parsed day');
    is($dt->Hour(), 14, 'Parsed hour');
    is($dt->Minute(), 30, 'Parsed minute');
    is($dt->Second(), 45, 'Parsed second');
    
    my $dt_date_only = System::DateTime->Parse('2023-12-25');
    is($dt_date_only->Hour(), 0, 'Date-only parse has 0 hour');
    
    eval { System::DateTime->Parse('invalid date'); };
    ok($@, 'Parse throws on invalid format');
}

sub test_datetime_tryparse {
    my $result;
    
    ok(System::DateTime->TryParse('2023-12-25', \$result), 'TryParse valid date returns true');
    isa_ok($result, 'System::DateTime', 'TryParse sets result');
    
    ok(!System::DateTime->TryParse('invalid', \$result), 'TryParse invalid date returns false');
    ok(!defined($result), 'TryParse sets result to undef on failure');
}

sub test_datetime_static {
    my $now = System::DateTime->Now();
    isa_ok($now, 'System::DateTime', 'Now returns DateTime');
    
    my $today = System::DateTime->Today();
    isa_ok($today, 'System::DateTime', 'Today returns DateTime');
    is($today->Hour(), 0, 'Today has 0 hour');
    is($today->Minute(), 0, 'Today has 0 minute');
    is($today->Second(), 0, 'Today has 0 second');
    
    my $utcNow = System::DateTime->UtcNow();
    isa_ok($utcNow, 'System::DateTime', 'UtcNow returns DateTime');
}

sub test_datetime_ticks {
    my $dt = System::DateTime->new(2023, 1, 1, 0, 0, 0);
    my $ticks = $dt->Ticks();
    ok($ticks > 0, 'Ticks returns positive value');
    
    my $dt_from_ticks = System::DateTime->FromTicks($ticks);
    isa_ok($dt_from_ticks, 'System::DateTime', 'FromTicks returns DateTime');
    ok($dt_from_ticks->Equals($dt), 'FromTicks roundtrip works');
}

sub test_datetime_unix_time {
    my $unixTime = time();
    my $dt = System::DateTime->FromUnixTime($unixTime);
    isa_ok($dt, 'System::DateTime', 'FromUnixTime returns DateTime');
    
    # Check that the time is reasonable (within current year)
    my $currentYear = (localtime())[5] + 1900;
    is($dt->Year(), $currentYear, 'FromUnixTime has correct year');
}

# Run all tests
test_datetime_creation();
test_datetime_defaults();
test_datetime_validation();
test_leap_year();
test_datetime_properties();
test_datetime_arithmetic();
test_datetime_subtraction();
test_datetime_comparison();
test_datetime_formatting();
test_datetime_parsing();
test_datetime_tryparse();
test_datetime_static();
test_datetime_ticks();
test_datetime_unix_time();

done_testing();