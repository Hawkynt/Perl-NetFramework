#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../..";

require System::DateTime;

# Test plan: comprehensive tests for advanced DateTime parsing and formatting
plan tests => 51;

# ============================================================================
# Advanced Formatting Tests
# ============================================================================

# Test standard format strings
{
  my $dt = System::DateTime->new(2023, 12, 25, 14, 30, 45, 123);
  
  # Short date pattern
  is($dt->ToString('d'), '12/25/2023', 'Short date format (d)');
  
  # General date/time patterns
  like($dt->ToString('g'), qr/12\/25\/2023 \d{1,2}:\d{2} (AM|PM)/, 'General short time format (g)');
  like($dt->ToString('G'), qr/12\/25\/2023 \d{1,2}:\d{2}:\d{2} (AM|PM)/, 'General long time format (G)');
  
  # ISO 8601 / Round-trip format
  is($dt->ToString('o'), '2023-12-25T14:30:45.1230000', 'Round-trip format (o)');
  is($dt->ToString('s'), '2023-12-25T14:30:45', 'Sortable format (s)');
  
  # RFC1123 format  
  like($dt->ToString('r'), qr/Mon, 25 Dec 2023 14:30:45 GMT/, 'RFC1123 format (r)');
  
  # Time patterns
  like($dt->ToString('t'), qr/\d{1,2}:\d{2} (AM|PM)/, 'Short time format (t)');
  like($dt->ToString('T'), qr/\d{1,2}:\d{2}:\d{2} (AM|PM)/, 'Long time format (T)');
  
  # Universal patterns
  is($dt->ToString('u'), '2023-12-25 14:30:45Z', 'Universal sortable format (u)');
  
  # Month and year patterns
  like($dt->ToString('M'), qr/December \d{2}/, 'Month day pattern (M)');
  like($dt->ToString('Y'), qr/December, 2023/, 'Year month pattern (Y)');
}

# Test custom format strings
{
  my $dt = System::DateTime->new(2023, 12, 25, 14, 30, 45, 123);
  
  # Custom date formats
  is($dt->ToString('yyyy-MM-dd'), '2023-12-25', 'Custom format: yyyy-MM-dd');
  is($dt->ToString('MM/dd/yyyy'), '12/25/2023', 'Custom format: MM/dd/yyyy');
  is($dt->ToString('dd-MMM-yyyy'), '25-Dec-2023', 'Custom format: dd-MMM-yyyy');
  
  # Custom time formats
  is($dt->ToString('HH:mm:ss'), '14:30:45', 'Custom format: HH:mm:ss');
  is($dt->ToString('h:mm tt'), '2:30 PM', 'Custom format: h:mm tt');
  is($dt->ToString('hh:mm:ss tt'), '02:30:45 PM', 'Custom format: hh:mm:ss tt');
  
  # Custom date/time combinations
  is($dt->ToString('yyyy-MM-dd HH:mm:ss'), '2023-12-25 14:30:45', 'Custom format: yyyy-MM-dd HH:mm:ss');
  is($dt->ToString('dddd, MMMM dd, yyyy'), 'Monday, December 25, 2023', 'Custom format: dddd, MMMM dd, yyyy');
  
  # Milliseconds
  is($dt->ToString('yyyy-MM-dd HH:mm:ss.fff'), '2023-12-25 14:30:45.123', 'Custom format with milliseconds');
}

# ============================================================================
# Advanced Parsing Tests  
# ============================================================================

# Test flexible parsing (Parse method)
{
  # ISO 8601 formats
  my $dt1 = System::DateTime->Parse('2023-12-25T14:30:45');
  is($dt1->Year(), 2023, 'Parse ISO 8601: year');
  is($dt1->Month(), 12, 'Parse ISO 8601: month');
  is($dt1->Day(), 25, 'Parse ISO 8601: day');
  is($dt1->Hour(), 14, 'Parse ISO 8601: hour');
  is($dt1->Minute(), 30, 'Parse ISO 8601: minute');
  is($dt1->Second(), 45, 'Parse ISO 8601: second');
  
  # ISO 8601 with milliseconds
  my $dt2 = System::DateTime->Parse('2023-12-25T14:30:45.123');
  is($dt2->Millisecond(), 123, 'Parse ISO 8601 with milliseconds');
  
  # Date with time (space separator)
  my $dt3 = System::DateTime->Parse('2023-12-25 14:30:45');
  is($dt3->Hour(), 14, 'Parse date/time with space separator');
  
  # US format with time
  my $dt4 = System::DateTime->Parse('12/25/2023 14:30:45');
  is($dt4->Month(), 12, 'Parse US format with time: month');
  is($dt4->Day(), 25, 'Parse US format with time: day');
  is($dt4->Year(), 2023, 'Parse US format with time: year');
  
  # Date only formats
  my $dt5 = System::DateTime->Parse('2023-12-25');
  is($dt5->Hour(), 0, 'Parse date only: default hour is 0');
  is($dt5->Minute(), 0, 'Parse date only: default minute is 0');
  
  my $dt6 = System::DateTime->Parse('12/25/2023');
  is($dt6->Month(), 12, 'Parse US date only: month');
  is($dt6->Day(), 25, 'Parse US date only: day');
  
  # AM/PM formats
  my $dt7 = System::DateTime->Parse('2023-12-25 2:30:45 PM');
  is($dt7->Hour(), 14, 'Parse with PM: converts to 24-hour format');
  
  my $dt8 = System::DateTime->Parse('2023-12-25 2:30:45 AM');
  is($dt8->Hour(), 2, 'Parse with AM: keeps hour as-is');
  
  my $dt9 = System::DateTime->Parse('2023-12-25 12:30:45 AM');
  is($dt9->Hour(), 0, 'Parse 12 AM: converts to 0');
}

# Test TryParse method
{
  my $result;
  
  # Valid date string
  ok(System::DateTime->TryParse('2023-12-25 14:30:45', \$result), 'TryParse: valid string returns true');
  ok(defined($result), 'TryParse: result is defined for valid string');
  is($result->Year(), 2023, 'TryParse: correct year parsed');
  
  # Invalid date string
  ok(!System::DateTime->TryParse('invalid-date', \$result), 'TryParse: invalid string returns false');
  ok(!defined($result), 'TryParse: result is undefined for invalid string');
}

# Test ParseExact method
{
  # Exact format parsing
  my $dt1 = System::DateTime->ParseExact('2023-12-25', 'yyyy-MM-dd');
  is($dt1->Year(), 2023, 'ParseExact: year from yyyy-MM-dd');
  is($dt1->Month(), 12, 'ParseExact: month from yyyy-MM-dd');
  is($dt1->Day(), 25, 'ParseExact: day from yyyy-MM-dd');
  
  # Different exact format
  eval {
    my $dt2 = System::DateTime->ParseExact('25/12/2023', 'dd/MM/yyyy');
    is($dt2->Day(), 25, 'ParseExact: day from dd/MM/yyyy');
    is($dt2->Month(), 12, 'ParseExact: month from dd/MM/yyyy');
  };
}

# Test TryParseExact method  
{
  my $result;
  
  # Valid format
  ok(System::DateTime->TryParseExact('2023-12-25', 'yyyy-MM-dd', undef, undef, \$result), 
     'TryParseExact: valid format returns true');
  ok(defined($result), 'TryParseExact: result defined for valid format');
  
  # Invalid format 
  ok(!System::DateTime->TryParseExact('2023-12-25', 'MM/dd/yyyy', undef, undef, \$result), 
     'TryParseExact: mismatched format returns false');
}

done_testing();