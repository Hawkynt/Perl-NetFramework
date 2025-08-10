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
    
    like($dt->ToString(), qr/12\/25\/2023 2:30:45 PM/, 'Default ToString format');
    like($dt->ToString('d'), qr/12\/25\/2023/, 'Date format');
    like($dt->ToString('T'), qr/2:30:45 PM/, 'Time format');
    like($dt->ToString('t'), qr/2:30 PM/, 'Short time format');
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

sub test_datetime_dayofweek_dayofyear {
    # Test DayOfWeek and DayOfYear
    my $dt = System::DateTime->new(2023, 7, 4); # Tuesday July 4th, 2023
    
    my $dayOfWeek = $dt->DayOfWeek();
    ok(defined($dayOfWeek), 'DayOfWeek returns value');
    ok($dayOfWeek >= 0 && $dayOfWeek <= 6, 'DayOfWeek is valid range');
    
    my $dayOfYear = $dt->DayOfYear();
    is($dayOfYear, 185, 'DayOfYear for July 4th is correct'); # July 4th is 185th day
    
    # Test for leap year
    my $leap_dt = System::DateTime->new(2020, 3, 1); # Leap year
    my $leap_day_of_year = $leap_dt->DayOfYear();
    is($leap_day_of_year, 61, 'DayOfYear in leap year is correct'); # March 1st in leap year
    
    # Test January 1st
    my $jan1 = System::DateTime->new(2023, 1, 1);
    is($jan1->DayOfYear(), 1, 'January 1st is day 1 of year');
    
    # Test December 31st non-leap year
    my $dec31 = System::DateTime->new(2023, 12, 31);
    is($dec31->DayOfYear(), 365, 'December 31st is day 365 in non-leap year');
    
    # Test December 31st leap year
    my $dec31_leap = System::DateTime->new(2020, 12, 31);
    is($dec31_leap->DayOfYear(), 366, 'December 31st is day 366 in leap year');
}

sub test_datetime_comprehensive_formatting {
    my $dt = System::DateTime->new(2023, 12, 25, 14, 30, 45, 123);
    
    # Test all standard format specifiers
    like($dt->ToString('d'), qr/12\/25\/2023/, 'Short date format (d)');
    like($dt->ToString('D'), qr/Monday, December 25, 2023/, 'Long date format (D)');
    like($dt->ToString('f'), qr/Monday, December 25, 2023 2:30 PM/, 'Full date short time (f)');
    like($dt->ToString('F'), qr/Monday, December 25, 2023 2:30:45 PM/, 'Full date long time (F)');
    like($dt->ToString('g'), qr/12\/25\/2023 2:30 PM/, 'General short time (g)');
    like($dt->ToString('G'), qr/12\/25\/2023 2:30:45 PM/, 'General long time (G)');
    like($dt->ToString('m'), qr/December 25/, 'Month day pattern (m)');
    like($dt->ToString('M'), qr/December 25/, 'Month day pattern (M)');
    like($dt->ToString('o'), qr/2023-12-25T14:30:45\.123/, 'Round-trip format (o)');
    like($dt->ToString('O'), qr/2023-12-25T14:30:45\.123/, 'Round-trip format (O)');
    like($dt->ToString('r'), qr/Mon, 25 Dec 2023 14:30:45 GMT/, 'RFC1123 format (r)');
    like($dt->ToString('R'), qr/Mon, 25 Dec 2023 14:30:45 GMT/, 'RFC1123 format (R)');
    like($dt->ToString('s'), qr/2023-12-25T14:30:45/, 'Sortable format (s)');
    like($dt->ToString('t'), qr/2:30 PM/, 'Short time format (t)');
    like($dt->ToString('T'), qr/2:30:45 PM/, 'Long time format (T)');
    like($dt->ToString('u'), qr/2023-12-25 14:30:45Z/, 'Universal sortable (u)');
    like($dt->ToString('U'), qr/Monday, December 25, 2023 2:30:45 PM/, 'Universal full (U)');
    like($dt->ToString('y'), qr/December, 2023/, 'Year month pattern (y)');
    like($dt->ToString('Y'), qr/December, 2023/, 'Year month pattern (Y)');
}

sub test_datetime_custom_formatting {
    my $dt = System::DateTime->new(2023, 7, 4, 9, 5, 3, 7); # July 4, 2023 9:05:03.007 AM
    
    # Test custom format specifiers - single letters are standard formats in .NET
    is($dt->ToString('yyyy'), '2023', 'Custom format yyyy');
    is($dt->ToString('yy'), '23', 'Custom format yy');
    like($dt->ToString('y'), qr/July, 2023/, 'Standard format y (year/month)');
    is($dt->ToString('MMMM'), 'July', 'Custom format MMMM');
    is($dt->ToString('MMM'), 'Jul', 'Custom format MMM');
    is($dt->ToString('MM'), '07', 'Custom format MM');
    like($dt->ToString('M'), qr/July 04/, 'Standard format M (month/day)');
    is($dt->ToString('dddd'), 'Tuesday', 'Custom format dddd');
    is($dt->ToString('ddd'), 'Tue', 'Custom format ddd');
    is($dt->ToString('dd'), '04', 'Custom format dd');
    like($dt->ToString('d'), qr/07\/04\/2023/, 'Standard format d (short date)');
    is($dt->ToString('HH'), '09', 'Custom format HH');
    like($dt->ToString('H'), qr/9/, 'Custom format H gets fallback');
    is($dt->ToString('hh'), '09', 'Custom format hh');
    like($dt->ToString('h'), qr/9/, 'Custom format h gets fallback');
    is($dt->ToString('mm'), '05', 'Custom format mm');
    like($dt->ToString('m'), qr/July 04/, 'Standard format m (month/day)');
    is($dt->ToString('ss'), '03', 'Custom format ss');
    like($dt->ToString('s'), qr/2023-07-04T/, 'Standard format s (sortable)');
    is($dt->ToString('fff'), '007', 'Custom format fff');
    is($dt->ToString('ff'), '00', 'Custom format ff');
    like($dt->ToString('f'), qr/Tuesday, July 04, 2023 9:05 AM/, 'Standard format f (full short time)');
    is($dt->ToString('tt'), 'AM', 'Custom format tt');
    like($dt->ToString('t'), qr/9:05 AM/, 'Standard format t (short time)');
    
    # Test combined custom formats
    is($dt->ToString('yyyy-MM-dd'), '2023-07-04', 'Custom combined format');
    is($dt->ToString('MMM d, yyyy'), 'Jul 4, 2023', 'Custom date format');
    is($dt->ToString('h:mm:ss tt'), '9:05:03 AM', 'Custom time format');
}

sub test_datetime_parsing_comprehensive {
    # Test various parsing formats
    my $dt1 = System::DateTime->Parse('12/25/2023');
    is($dt1->Year(), 2023, 'Parse MM/dd/yyyy format');
    is($dt1->Month(), 12, 'Parse MM/dd/yyyy month');
    is($dt1->Day(), 25, 'Parse MM/dd/yyyy day');
    
    my $dt2 = System::DateTime->Parse('2023-12-25T14:30:45.123');
    is($dt2->Millisecond(), 123, 'Parse ISO format with milliseconds');
    
    my $dt3 = System::DateTime->Parse('2023-12-25 14:30:45');
    is($dt3->Hour(), 14, 'Parse without AM/PM format');
    
    # Test ParseExact with different formats
    my $dt4 = System::DateTime->ParseExact('2023-12-25', 'yyyy-MM-dd');
    is($dt4->Year(), 2023, 'ParseExact yyyy-MM-dd');
    
    my $dt5 = System::DateTime->ParseExact('12/25/2023', 'MM/dd/yyyy');
    is($dt5->Month(), 12, 'ParseExact MM/dd/yyyy');
    
    my $dt6 = System::DateTime->ParseExact('25/12/2023', 'dd/MM/yyyy');
    is($dt6->Day(), 25, 'ParseExact dd/MM/yyyy');
    
    my $dt7 = System::DateTime->ParseExact('2023-12-25 14:30:45', 'yyyy-MM-dd HH:mm:ss');
    is($dt7->Hour(), 14, 'ParseExact with time');
    
    # Test parsing errors
    eval { System::DateTime->ParseExact('invalid', 'yyyy-MM-dd'); };
    ok($@, 'ParseExact throws on format mismatch');
    
    eval { System::DateTime->ParseExact('2023-02-30', 'yyyy-MM-dd'); };
    ok($@, 'ParseExact throws on invalid date');
}

sub test_datetime_tryparse_comprehensive {
    my $result;
    
    # Test TryParseExact with various formats
    ok(System::DateTime->TryParseExact('2023-12-25', 'yyyy-MM-dd', undef, undef, \$result), 
       'TryParseExact valid format');
    is($result->Year(), 2023, 'TryParseExact result year');
    
    ok(!System::DateTime->TryParseExact('invalid', 'yyyy-MM-dd', undef, undef, \$result),
       'TryParseExact invalid format returns false');
    ok(!defined($result), 'TryParseExact sets result to undef on failure');
    
    ok(!System::DateTime->TryParseExact('2023-02-30', 'yyyy-MM-dd', undef, undef, \$result),
       'TryParseExact invalid date returns false');
    
    # Test with different successful formats
    ok(System::DateTime->TryParseExact('12/25/2023', 'MM/dd/yyyy', undef, undef, \$result),
       'TryParseExact MM/dd/yyyy format');
    is($result->Month(), 12, 'TryParseExact MM/dd/yyyy month');
    
    ok(System::DateTime->TryParseExact('25/12/2023', 'dd/MM/yyyy', undef, undef, \$result),
       'TryParseExact dd/MM/yyyy format');
    is($result->Day(), 25, 'TryParseExact dd/MM/yyyy day');
}

sub test_datetime_null_reference {
    my $null_dt;
    
    # Test all methods throw on null reference
    eval { $null_dt->Year(); };
    ok($@, 'Year throws on null reference');
    
    eval { $null_dt->Month(); };
    ok($@, 'Month throws on null reference');
    
    eval { $null_dt->Day(); };
    ok($@, 'Day throws on null reference');
    
    eval { $null_dt->Hour(); };
    ok($@, 'Hour throws on null reference');
    
    eval { $null_dt->Minute(); };
    ok($@, 'Minute throws on null reference');
    
    eval { $null_dt->Second(); };
    ok($@, 'Second throws on null reference');
    
    eval { $null_dt->Millisecond(); };
    ok($@, 'Millisecond throws on null reference');
    
    eval { $null_dt->Ticks(); };
    ok($@, 'Ticks throws on null reference');
    
    eval { $null_dt->Date(); };
    ok($@, 'Date throws on null reference');
    
    eval { $null_dt->TimeOfDay(); };
    ok($@, 'TimeOfDay throws on null reference');
    
    eval { $null_dt->DayOfWeek(); };
    ok($@, 'DayOfWeek throws on null reference');
    
    eval { $null_dt->DayOfYear(); };
    ok($@, 'DayOfYear throws on null reference');
    
    eval { $null_dt->ToString(); };
    ok($@, 'ToString throws on null reference');
    
    eval { $null_dt->CompareTo(System::DateTime->Now()); };
    ok($@, 'CompareTo throws on null reference');
    
    eval { $null_dt->Equals(System::DateTime->Now()); };
    ok($@, 'Equals throws on null reference');
    
    eval { $null_dt->Add(System::TimeSpan->FromHours(1)); };
    ok($@, 'Add throws on null reference');
    
    eval { $null_dt->AddDays(1); };
    ok($@, 'AddDays throws on null reference');
    
    eval { $null_dt->Subtract(System::DateTime->Now()); };
    ok($@, 'Subtract throws on null reference');
}

sub test_datetime_argument_validation {
    my $dt = System::DateTime->new(2023, 12, 25);
    
    # Test Add with null argument
    eval { $dt->Add(undef); };
    ok($@, 'Add throws on null TimeSpan');
    
    # Test Subtract with null argument
    eval { $dt->Subtract(undef); };
    ok($@, 'Subtract throws on null argument');
    
    # Test Subtract with invalid type
    eval { $dt->Subtract("invalid"); };
    ok($@, 'Subtract throws on invalid argument type');
    
    # Test CompareTo with wrong type
    eval { $dt->CompareTo("invalid"); };
    ok($@, 'CompareTo throws on wrong type');
    
    # Test FromTicks with invalid values
    eval { System::DateTime->FromTicks(-1); };
    ok($@, 'FromTicks throws on negative ticks');
    
    eval { System::DateTime->FromTicks(9999999999999999999); };
    ok($@, 'FromTicks throws on too large ticks');
    
    # Test parsing with null arguments
    eval { System::DateTime->Parse(undef); };
    ok($@, 'Parse throws on null string');
    
    eval { System::DateTime->ParseExact(undef, 'yyyy-MM-dd'); };
    ok($@, 'ParseExact throws on null string');
    
    eval { System::DateTime->ParseExact('2023-12-25', undef); };
    ok($@, 'ParseExact throws on null format');
    
    eval { System::DateTime->TryParse('2023-12-25', undef); };
    ok($@, 'TryParse throws on null result reference');
    
    eval { System::DateTime->TryParseExact('2023-12-25', undef, undef, undef, \my $result); };
    ok($@, 'TryParseExact throws on null format');
    
    eval { System::DateTime->TryParseExact('2023-12-25', 'yyyy-MM-dd', undef, undef, undef); };
    ok($@, 'TryParseExact throws on null result reference');
}

sub test_datetime_edge_cases {
    # Test boundary dates
    my $min_dt = System::DateTime->new(1, 1, 1);
    is($min_dt->Year(), 1, 'Minimum year works');
    is($min_dt->Month(), 1, 'Minimum month works');
    is($min_dt->Day(), 1, 'Minimum day works');
    
    my $max_dt = System::DateTime->new(9999, 12, 31, 23, 59, 59, 999);
    is($max_dt->Year(), 9999, 'Maximum year works');
    is($max_dt->Millisecond(), 999, 'Maximum millisecond works');
    
    # Test leap year edge cases
    my $leap_1600 = System::DateTime->new(1600, 2, 29); # Divisible by 400
    is($leap_1600->Day(), 29, 'Year 1600 is leap year');
    
    my $leap_2000 = System::DateTime->new(2000, 2, 29); # Divisible by 400
    is($leap_2000->Day(), 29, 'Year 2000 is leap year');
    
    eval { System::DateTime->new(1900, 2, 29); }; # Divisible by 100 but not 400
    ok($@, 'Year 1900 is not leap year');
    
    # Test month boundaries
    my $april30 = System::DateTime->new(2023, 4, 30);
    is($april30->Day(), 30, 'April has 30 days');
    
    eval { System::DateTime->new(2023, 4, 31); };
    ok($@, 'April does not have 31 days');
    
    my $march31 = System::DateTime->new(2023, 3, 31);
    is($march31->Day(), 31, 'March has 31 days');
}

sub test_datetime_arithmetic_comprehensive {
    my $dt = System::DateTime->new(2023, 6, 15, 12, 30, 45, 500);
    
    # Test AddMilliseconds
    my $dt_plus_ms = $dt->AddMilliseconds(250);
    is($dt_plus_ms->Millisecond(), 750, 'AddMilliseconds works');
    
    my $dt_plus_ms_overflow = $dt->AddMilliseconds(600);
    is($dt_plus_ms_overflow->Millisecond(), 100, 'AddMilliseconds with overflow');
    is($dt_plus_ms_overflow->Second(), 46, 'AddMilliseconds overflow increments second');
    
    # Test boundary arithmetic
    my $end_of_month = System::DateTime->new(2023, 1, 31, 23, 59, 59);
    my $next_month = $end_of_month->AddSeconds(1);
    is($next_month->Month(), 2, 'Adding seconds crosses month boundary');
    is($next_month->Day(), 1, 'Day resets to 1 in new month');
    
    my $end_of_year = System::DateTime->new(2023, 12, 31, 23, 59, 59);
    my $next_year = $end_of_year->AddSeconds(1);
    is($next_year->Year(), 2024, 'Adding seconds crosses year boundary');
    is($next_year->Month(), 1, 'Month resets to 1 in new year');
    
    # Test negative arithmetic
    my $dt_minus_days = $dt->AddDays(-10);
    is($dt_minus_days->Day(), 5, 'AddDays with negative value');
    
    my $beginning_of_month = System::DateTime->new(2023, 3, 1, 0, 0, 1);
    my $prev_month = $beginning_of_month->AddSeconds(-1);
    is($prev_month->Month(), 2, 'Subtracting seconds crosses month boundary backwards');
    is($prev_month->Day(), 28, 'Last day of February in non-leap year');
}

sub test_datetime_comparison_comprehensive {
    my $dt1 = System::DateTime->new(2023, 6, 15, 12, 30, 45);
    my $dt2 = System::DateTime->new(2023, 6, 15, 12, 30, 45);
    my $dt3 = System::DateTime->new(2023, 6, 15, 12, 30, 46); # One second later
    my $dt4 = System::DateTime->new(2023, 6, 15, 12, 30, 44); # One second earlier
    
    # Test exact equality
    ok($dt1->Equals($dt2), 'Exactly equal DateTimes');
    is($dt1->CompareTo($dt2), 0, 'CompareTo returns 0 for equal DateTimes');
    
    # Test comparison with millisecond precision
    my $dt_ms1 = System::DateTime->new(2023, 6, 15, 12, 30, 45, 100);
    my $dt_ms2 = System::DateTime->new(2023, 6, 15, 12, 30, 45, 200);
    
    ok(!$dt_ms1->Equals($dt_ms2), 'DateTimes different by milliseconds are not equal');
    ok($dt_ms1->CompareTo($dt_ms2) < 0, 'Earlier datetime compares as less than');
    ok($dt_ms2->CompareTo($dt_ms1) > 0, 'Later datetime compares as greater than');
    
    # Test CompareTo with null
    is($dt1->CompareTo(undef), 0, 'CompareTo null returns 0');
    
    # Test Equals with null and wrong type
    ok(!$dt1->Equals(undef), 'Equals null returns false');
    ok(!$dt1->Equals("not a datetime"), 'Equals wrong type returns false');
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
test_datetime_dayofweek_dayofyear();
test_datetime_comprehensive_formatting();
test_datetime_custom_formatting();
test_datetime_parsing_comprehensive();
test_datetime_tryparse_comprehensive();
test_datetime_null_reference();
test_datetime_argument_validation();
test_datetime_edge_cases();
test_datetime_arithmetic_comprehensive();
test_datetime_comparison_comprehensive();

done_testing();