package System::DateTime; {
  use base 'System::Object','System::IComparable','System::IEquatable';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::TimeSpan;
  use POSIX qw(mktime strftime);
  use Time::Local;

  # DateTime constants (ticks since January 1, 0001)
  use constant TicksPerMillisecond => 10000;
  use constant TicksPerSecond => 10000 * 1000;
  use constant TicksPerMinute => TicksPerSecond * 60;
  use constant TicksPerHour => TicksPerMinute * 60;
  use constant TicksPerDay => TicksPerHour * 24;
  
  # Unix epoch offset (January 1, 1970 vs January 1, 0001)
  use constant UnixEpochTicks => 621355968000000000;

  sub new {
    my ($class, $year, $month, $day, $hour, $minute, $second, $millisecond) = @_;
    
    # Default parameters
    $hour //= 0;
    $minute //= 0;
    $second //= 0;
    $millisecond //= 0;
    
    # Validate parameters
    throw(System::ArgumentOutOfRangeException->new('year')) 
      if ($year < 1 || $year > 9999);
    throw(System::ArgumentOutOfRangeException->new('month')) 
      if ($month < 1 || $month > 12);
    throw(System::ArgumentOutOfRangeException->new('day')) 
      if ($day < 1 || $day > _DaysInMonth($year, $month));
    throw(System::ArgumentOutOfRangeException->new('hour')) 
      if ($hour < 0 || $hour > 23);
    throw(System::ArgumentOutOfRangeException->new('minute')) 
      if ($minute < 0 || $minute > 59);
    throw(System::ArgumentOutOfRangeException->new('second')) 
      if ($second < 0 || $second > 59);
    throw(System::ArgumentOutOfRangeException->new('millisecond')) 
      if ($millisecond < 0 || $millisecond > 999);
    
    # Calculate ticks from components
    my $ticks = _DateToTicks($year, $month, $day) + 
                _TimeToTicks($hour, $minute, $second) +
                ($millisecond * TicksPerMillisecond);
    
    return bless {
      _ticks => $ticks
    }, ref($class) || $class || __PACKAGE__;
  }

  # Create DateTime from ticks
  sub FromTicks {
    my ($class, $ticks) = @_;
    throw(System::ArgumentOutOfRangeException->new('ticks')) 
      if ($ticks < 0 || $ticks > 3155378975999999999);

    return bless {
      _ticks => $ticks
    }, ref($class) || $class || __PACKAGE__;
  }

  # Create DateTime from Unix timestamp
  sub FromUnixTime {
    my ($class, $unixTime) = @_;
    my $ticks = ($unixTime * TicksPerSecond) + UnixEpochTicks;
    return $class->FromTicks($ticks);
  }

  # Properties
  sub Ticks {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_ticks};
  }

  sub Year {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my ($year, $month, $day) = _TicksToDate($this->{_ticks});
    return $year;
  }

  sub Month {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my ($year, $month, $day) = _TicksToDate($this->{_ticks});
    return $month;
  }

  sub Day {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my ($year, $month, $day) = _TicksToDate($this->{_ticks});
    return $day;
  }

  sub Hour {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return int(($this->{_ticks} / TicksPerHour) % 24);
  }

  sub Minute {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return int(($this->{_ticks} / TicksPerMinute) % 60);
  }

  sub Second {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return int(($this->{_ticks} / TicksPerSecond) % 60);
  }

  sub Millisecond {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return int(($this->{_ticks} / TicksPerMillisecond) % 1000);
  }

  sub Date {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my $dateTicks = $this->{_ticks} - ($this->{_ticks} % TicksPerDay);
    return System::DateTime->FromTicks($dateTicks);
  }

  sub TimeOfDay {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my $timeTicks = $this->{_ticks} % TicksPerDay;
    return System::TimeSpan->new($timeTicks);
  }

  sub DayOfWeek {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    # Sunday = 0, Monday = 1, etc.
    return int(($this->{_ticks} / TicksPerDay + 1) % 7);
  }

  sub DayOfYear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    my ($year, $month, $day) = _TicksToDate($this->{_ticks});
    return _DayOfYear($year, $month, $day);
  }

  # Static properties
  sub Now {
    my ($class) = @_;
    return $class->FromUnixTime(time());
  }

  sub Today {
    my ($class) = @_;
    return $class->Now()->Date();
  }

  sub UtcNow {
    my ($class) = @_;
    # For simplicity, same as Now (would need timezone handling in real implementation)
    return $class->Now();
  }

  # Arithmetic methods
  sub Add {
    my ($this, $timespan) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('timespan')) unless defined($timespan);
    
    my $newTicks = $this->{_ticks} + $timespan->Ticks();
    return System::DateTime->FromTicks($newTicks);
  }

  sub AddDays {
    my ($this, $days) = @_;
    return $this->Add(System::TimeSpan->FromDays($days));
  }

  sub AddHours {
    my ($this, $hours) = @_;
    return $this->Add(System::TimeSpan->FromHours($hours));
  }

  sub AddMinutes {
    my ($this, $minutes) = @_;
    return $this->Add(System::TimeSpan->FromMinutes($minutes));
  }

  sub AddSeconds {
    my ($this, $seconds) = @_;
    return $this->Add(System::TimeSpan->FromSeconds($seconds));
  }

  sub AddMilliseconds {
    my ($this, $milliseconds) = @_;
    return $this->Add(System::TimeSpan->FromMilliseconds($milliseconds));
  }

  sub Subtract {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('value')) unless defined($value);
    
    if ($value->isa('System::DateTime')) {
      # DateTime - DateTime = TimeSpan
      my $ticksDiff = $this->{_ticks} - $value->Ticks();
      return System::TimeSpan->new($ticksDiff);
    } elsif ($value->isa('System::TimeSpan')) {
      # DateTime - TimeSpan = DateTime
      my $newTicks = $this->{_ticks} - $value->Ticks();
      return System::DateTime->FromTicks($newTicks);
    } else {
      throw(System::ArgumentException->new('value must be DateTime or TimeSpan'));
    }
  }

  # Comparison methods
  sub CompareTo {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return 0 unless defined($other);
    throw(System::ArgumentException->new('other')) unless $other->isa('System::DateTime');
    
    return ($this->{_ticks} <=> $other->{_ticks});
  }

  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    return false unless $other->isa('System::DateTime');
    
    return ($this->{_ticks} == $other->{_ticks});
  }

  # String representation with advanced formatting
  sub ToString {
    my ($this, $format, $formatProvider) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $format //= 'G'; # General format as default
    
    return _FormatDateTime($this, $format, $formatProvider);
  }

  # Advanced parsing methods
  sub Parse {
    my ($class, $dateString, $formatProvider) = @_;
    throw(System::ArgumentNullException->new('dateString')) unless defined($dateString);
    
    return _ParseDateTime($dateString, undef, $formatProvider, 0);
  }

  sub ParseExact {
    my ($class, $dateString, $format, $formatProvider) = @_;
    throw(System::ArgumentNullException->new('dateString')) unless defined($dateString);
    throw(System::ArgumentNullException->new('format')) unless defined($format);
    
    return _ParseDateTime($dateString, $format, $formatProvider, 1);
  }

  sub TryParse {
    my ($class, $dateString, $resultRef, $formatProvider) = @_;
    throw(System::ArgumentNullException->new('resultRef')) unless defined($resultRef);
    
    eval {
      $$resultRef = _ParseDateTime($dateString, undef, $formatProvider, 0);
    };
    if ($@) {
      $$resultRef = undef;
      return false;
    }
    return true;
  }

  sub TryParseExact {
    my ($class, $dateString, $format, $formatProvider, $dateTimeStyles, $resultRef) = @_;
    throw(System::ArgumentNullException->new('resultRef')) unless defined($resultRef);
    throw(System::ArgumentNullException->new('format')) unless defined($format);
    
    eval {
      $$resultRef = _ParseDateTime($dateString, $format, $formatProvider, 1);
    };
    if ($@) {
      $$resultRef = undef;
      return false;
    }
    return true;
  }

  # Helper methods
  sub _IsLeapYear {
    my ($year) = @_;
    return (($year % 4 == 0 && $year % 100 != 0) || ($year % 400 == 0));
  }

  sub _DaysInMonth {
    my ($year, $month) = @_;
    my @daysInMonth = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    
    if ($month == 2 && _IsLeapYear($year)) {
      return 29;
    }
    return $daysInMonth[$month];
  }

  sub _DayOfYear {
    my ($year, $month, $day) = @_;
    my $dayOfYear = $day;
    for my $m (1..$month-1) {
      $dayOfYear += _DaysInMonth($year, $m);
    }
    return $dayOfYear;
  }

  sub _DateToTicks {
    my ($year, $month, $day) = @_;
    # Simplified calculation - would need more accurate calculation for full range
    my $totalDays = 0;
    
    # Add days for complete years
    for my $y (1..$year-1) {
      $totalDays += _IsLeapYear($y) ? 366 : 365;
    }
    
    # Add days for complete months in current year
    for my $m (1..$month-1) {
      $totalDays += _DaysInMonth($year, $m);
    }
    
    # Add days in current month
    $totalDays += $day - 1;
    
    return $totalDays * TicksPerDay;
  }

  sub _TimeToTicks {
    my ($hour, $minute, $second) = @_;
    return ($hour * TicksPerHour) + ($minute * TicksPerMinute) + ($second * TicksPerSecond);
  }

  sub _TicksToDate {
    my ($ticks) = @_;
    my $totalDays = int($ticks / TicksPerDay);
    
    # Find year
    my $year = 1;
    while (1) {
      my $daysInYear = _IsLeapYear($year) ? 366 : 365;
      if ($totalDays >= $daysInYear) {
        $totalDays -= $daysInYear;
        $year++;
      } else {
        last;
      }
    }
    
    # Find month and day
    my $month = 1;
    while ($month <= 12) {
      my $daysInMonth = _DaysInMonth($year, $month);
      if ($totalDays >= $daysInMonth) {
        $totalDays -= $daysInMonth;
        $month++;
      } else {
        last;
      }
    }
    
    my $day = $totalDays + 1;
    
    return ($year, $month, $day);
  }

  # Advanced formatting implementation
  sub _FormatDateTime {
    my ($dateTime, $format, $formatProvider) = @_;
    
    my ($year, $month, $day) = _TicksToDate($dateTime->{_ticks});
    my $hour = $dateTime->Hour();
    my $minute = $dateTime->Minute();
    my $second = $dateTime->Second();
    my $millisecond = $dateTime->Millisecond();
    my $dayOfWeek = $dateTime->DayOfWeek();
    
    # Standard format strings
    if (length($format) == 1) {
      return _FormatStandardDateTime($dateTime, $format, $year, $month, $day, $hour, $minute, $second, $millisecond, $dayOfWeek);
    }
    
    # Custom format strings
    return _FormatCustomDateTime($dateTime, $format, $year, $month, $day, $hour, $minute, $second, $millisecond, $dayOfWeek);
  }
  
  sub _FormatStandardDateTime {
    my ($dateTime, $format, $year, $month, $day, $hour, $minute, $second, $millisecond, $dayOfWeek) = @_;
    
    # Standard format specifiers
    if ($format eq 'd') {
      # Short date pattern: MM/dd/yyyy
      return sprintf("%02d/%02d/%04d", $month, $day, $year);
    } elsif ($format eq 'D') {
      # Long date pattern: dddd, MMMM dd, yyyy
      my $dayName = _GetDayName($dayOfWeek);
      my $monthName = _GetMonthName($month);
      return sprintf("%s, %s %02d, %04d", $dayName, $monthName, $day, $year);
    } elsif ($format eq 'f') {
      # Full date/time pattern (short time): dddd, MMMM dd, yyyy h:mm tt
      my $dayName = _GetDayName($dayOfWeek);
      my $monthName = _GetMonthName($month);
      my $ampm = $hour >= 12 ? 'PM' : 'AM';
      my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
      return sprintf("%s, %s %02d, %04d %d:%02d %s", $dayName, $monthName, $day, $year, $hour12, $minute, $ampm);
    } elsif ($format eq 'F') {
      # Full date/time pattern (long time): dddd, MMMM dd, yyyy h:mm:ss tt
      my $dayName = _GetDayName($dayOfWeek);
      my $monthName = _GetMonthName($month);
      my $ampm = $hour >= 12 ? 'PM' : 'AM';
      my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
      return sprintf("%s, %s %02d, %04d %d:%02d:%02d %s", $dayName, $monthName, $day, $year, $hour12, $minute, $second, $ampm);
    } elsif ($format eq 'g') {
      # General date/time pattern (short time): MM/dd/yyyy h:mm tt
      my $ampm = $hour >= 12 ? 'PM' : 'AM';
      my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
      return sprintf("%02d/%02d/%04d %d:%02d %s", $month, $day, $year, $hour12, $minute, $ampm);
    } elsif ($format eq 'G') {
      # General date/time pattern (long time): MM/dd/yyyy h:mm:ss tt
      my $ampm = $hour >= 12 ? 'PM' : 'AM';
      my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
      return sprintf("%02d/%02d/%04d %d:%02d:%02d %s", $month, $day, $year, $hour12, $minute, $second, $ampm);
    } elsif ($format eq 'm' || $format eq 'M') {
      # Month day pattern: MMMM dd
      my $monthName = _GetMonthName($month);
      return sprintf("%s %02d", $monthName, $day);
    } elsif ($format eq 'o' || $format eq 'O') {
      # Round-trip date/time pattern: yyyy-MM-ddTHH:mm:ss.fffffffK
      return sprintf("%04d-%02d-%02dT%02d:%02d:%02d.%03d0000", $year, $month, $day, $hour, $minute, $second, $millisecond);
    } elsif ($format eq 'r' || $format eq 'R') {
      # RFC1123 pattern: ddd, dd MMM yyyy HH:mm:ss GMT
      my $dayAbbrev = _GetDayAbbreviation($dayOfWeek);
      my $monthAbbrev = _GetMonthAbbreviation($month);
      return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT", $dayAbbrev, $day, $monthAbbrev, $year, $hour, $minute, $second);
    } elsif ($format eq 's') {
      # Sortable date/time pattern: yyyy-MM-ddTHH:mm:ss
      return sprintf("%04d-%02d-%02dT%02d:%02d:%02d", $year, $month, $day, $hour, $minute, $second);
    } elsif ($format eq 't') {
      # Short time pattern: h:mm tt
      my $ampm = $hour >= 12 ? 'PM' : 'AM';
      my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
      return sprintf("%d:%02d %s", $hour12, $minute, $ampm);
    } elsif ($format eq 'T') {
      # Long time pattern: h:mm:ss tt
      my $ampm = $hour >= 12 ? 'PM' : 'AM';
      my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
      return sprintf("%d:%02d:%02d %s", $hour12, $minute, $second, $ampm);
    } elsif ($format eq 'u') {
      # Universal sortable date/time pattern: yyyy-MM-dd HH:mm:ssZ
      return sprintf("%04d-%02d-%02d %02d:%02d:%02dZ", $year, $month, $day, $hour, $minute, $second);
    } elsif ($format eq 'U') {
      # Universal full date/time pattern: dddd, MMMM dd, yyyy h:mm:ss tt
      my $dayName = _GetDayName($dayOfWeek);
      my $monthName = _GetMonthName($month);
      my $ampm = $hour >= 12 ? 'PM' : 'AM';
      my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
      return sprintf("%s, %s %02d, %04d %d:%02d:%02d %s", $dayName, $monthName, $day, $year, $hour12, $minute, $second, $ampm);
    } elsif ($format eq 'y' || $format eq 'Y') {
      # Year month pattern: MMMM, yyyy
      my $monthName = _GetMonthName($month);
      return sprintf("%s, %04d", $monthName, $year);
    } else {
      # Default to general format
      return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $minute, $second);
    }
  }
  
  sub _FormatCustomDateTime {
    my ($dateTime, $format, $year, $month, $day, $hour, $minute, $second, $millisecond, $dayOfWeek) = @_;
    
    my $result = $format;
    
    # Use placeholder approach to avoid regex conflicts
    # Replace with unique placeholders first, then substitute values
    
    # Year placeholders
    $result =~ s/yyyy/\x{E000}/g;   # Private use area U+E000
    $result =~ s/yyy/\x{E001}/g;
    $result =~ s/yy/\x{E002}/g;
    $result =~ s/(?<!\x{E002})y(?!y)/\x{E003}/g;
    
    # Month placeholders
    $result =~ s/MMMM/\x{E004}/g;
    $result =~ s/MMM/\x{E005}/g;
    $result =~ s/MM/\x{E006}/g;
    $result =~ s/(?<!M)M(?!M)/\x{E007}/g;
    
    # Day placeholders  
    $result =~ s/dddd/\x{E008}/g;
    $result =~ s/ddd/\x{E009}/g;
    $result =~ s/dd/\x{E00A}/g;
    $result =~ s/(?<!d)d(?!d)/\x{E00B}/g;
    
    # Hour placeholders
    $result =~ s/HH/\x{E00C}/g;
    $result =~ s/(?<!H)H(?!H)/\x{E00D}/g;
    $result =~ s/hh/\x{E00E}/g;
    $result =~ s/(?<!h)h(?!h)/\x{E00F}/g;
    
    # Minute placeholders
    $result =~ s/mm/\x{E010}/g;
    $result =~ s/(?<!m)m(?!m)/\x{E011}/g;
    
    # Second placeholders
    $result =~ s/ss/\x{E012}/g;
    $result =~ s/(?<!s)s(?!s)/\x{E013}/g;
    
    # Millisecond placeholders
    $result =~ s/fff/\x{E014}/g;
    $result =~ s/ff(?!f)/\x{E015}/g;
    $result =~ s/(?<!f)f(?!f)/\x{E016}/g;
    
    # AM/PM placeholders
    $result =~ s/tt/\x{E017}/g;
    $result =~ s/(?<!t)t(?!t)/\x{E018}/g;
    
    # Now substitute the actual values
    my $hour12 = $hour == 0 ? 12 : ($hour > 12 ? $hour - 12 : $hour);
    my $ampm = $hour >= 12 ? 'PM' : 'AM';
    
    $result =~ s/\x{E000}/sprintf("%04d", $year)/ge;
    $result =~ s/\x{E001}/substr(sprintf("%04d", $year), 1)/ge;
    $result =~ s/\x{E002}/substr(sprintf("%04d", $year), -2)/ge;
    $result =~ s/\x{E003}/substr(sprintf("%04d", $year), -1)/ge;
    
    $result =~ s/\x{E004}/_GetMonthName($month)/ge;
    $result =~ s/\x{E005}/_GetMonthAbbreviation($month)/ge;
    $result =~ s/\x{E006}/sprintf("%02d", $month)/ge;
    $result =~ s/\x{E007}/$month/ge;
    
    $result =~ s/\x{E008}/_GetDayName($dayOfWeek)/ge;
    $result =~ s/\x{E009}/_GetDayAbbreviation($dayOfWeek)/ge;
    $result =~ s/\x{E00A}/sprintf("%02d", $day)/ge;
    $result =~ s/\x{E00B}/$day/ge;
    
    $result =~ s/\x{E00C}/sprintf("%02d", $hour)/ge;
    $result =~ s/\x{E00D}/$hour/ge;
    $result =~ s/\x{E00E}/sprintf("%02d", $hour12)/ge;
    $result =~ s/\x{E00F}/$hour12/ge;
    
    $result =~ s/\x{E010}/sprintf("%02d", $minute)/ge;
    $result =~ s/\x{E011}/$minute/ge;
    
    $result =~ s/\x{E012}/sprintf("%02d", $second)/ge;
    $result =~ s/\x{E013}/$second/ge;
    
    $result =~ s/\x{E014}/sprintf("%03d", $millisecond)/ge;
    $result =~ s/\x{E015}/sprintf("%02d", int($millisecond \/ 10))/ge;
    $result =~ s/\x{E016}/sprintf("%d", int($millisecond \/ 100))/ge;
    
    $result =~ s/\x{E017}/$ampm/g;
    $result =~ s/\x{E018}/substr($ampm, 0, 1)/ge;
    
    return $result;
  }
  
  # Advanced parsing implementation
  sub _ParseDateTime {
    my ($dateString, $format, $formatProvider, $exact) = @_;
    
    $dateString =~ s/^\s+|\s+$//g; # Trim whitespace
    
    if (!$exact) {
      # Try common formats for flexible parsing
      return _ParseFlexibleDateTime($dateString);
    } else {
      # Parse according to exact format
      return _ParseExactDateTime($dateString, $format);
    }
  }
  
  sub _ParseFlexibleDateTime {
    my ($dateString) = @_;
    
    # ISO 8601 format: 2023-12-25T14:30:45 or 2023-12-25T14:30:45.123
    if ($dateString =~ /^(\d{4})-(\d{1,2})-(\d{1,2})T(\d{1,2}):(\d{1,2}):(\d{1,2})(?:\.(\d{1,3}))?(?:Z|[+-]\d{2}:\d{2})?$/i) {
      my ($year, $month, $day, $hour, $minute, $second, $ms) = ($1, $2, $3, $4, $5, $6, $7 // 0);
      $ms = substr($ms . '000', 0, 3); # Pad to 3 digits
      return System::DateTime->new($year, $month, $day, $hour, $minute, $second, $ms);
    }
    
    # Date with time: 2023-12-25 14:30:45 or 12/25/2023 14:30:45
    if ($dateString =~ /^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})$/) {
      my ($year, $month, $day, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
      return System::DateTime->new($year, $month, $day, $hour, $minute, $second);
    }
    
    if ($dateString =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})$/) {
      my ($month, $day, $year, $hour, $minute, $second) = ($1, $2, $3, $4, $5, $6);
      return System::DateTime->new($year, $month, $day, $hour, $minute, $second);
    }
    
    # Date only: 2023-12-25 or 12/25/2023
    if ($dateString =~ /^(\d{4})-(\d{1,2})-(\d{1,2})$/) {
      my ($year, $month, $day) = ($1, $2, $3);
      return System::DateTime->new($year, $month, $day);
    }
    
    if ($dateString =~ /^(\d{1,2})\/(\d{1,2})\/(\d{4})$/) {
      my ($month, $day, $year) = ($1, $2, $3);
      return System::DateTime->new($year, $month, $day);
    }
    
    # With AM/PM
    if ($dateString =~ /^(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{1,2}):(\d{1,2})\s*(AM|PM)$/i) {
      my ($year, $month, $day, $hour, $minute, $second, $ampm) = ($1, $2, $3, $4, $5, $6, uc($7));
      $hour = 0 if ($hour == 12 && $ampm eq 'AM');
      $hour += 12 if ($hour != 12 && $ampm eq 'PM');
      return System::DateTime->new($year, $month, $day, $hour, $minute, $second);
    }
    
    throw(System::FormatException->new("Unable to parse '$dateString'"));
  }
  
  sub _ParseExactDateTime {
    my ($dateString, $format) = @_;
    
    # For now, handle some common exact formats directly
    if ($format eq 'yyyy-MM-dd') {
      if ($dateString =~ /^(\d{4})-(\d{2})-(\d{2})$/) {
        return System::DateTime->new($1, $2, $3);
      }
    } elsif ($format eq 'MM/dd/yyyy') {
      if ($dateString =~ /^(\d{2})\/(\d{2})\/(\d{4})$/) {
        return System::DateTime->new($3, $1, $2);
      }
    } elsif ($format eq 'dd/MM/yyyy') {
      if ($dateString =~ /^(\d{2})\/(\d{2})\/(\d{4})$/) {
        return System::DateTime->new($3, $2, $1);
      }
    } elsif ($format eq 'yyyy-MM-dd HH:mm:ss') {
      if ($dateString =~ /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) {
        return System::DateTime->new($1, $2, $3, $4, $5, $6);
      }
    }
    
    throw(System::FormatException->new("String was not recognized as a valid DateTime for format '$format'"));
  }
  
  sub _ConvertFormatToRegex {
    my ($format) = @_;
    
    my $pattern = $format;
    
    # Escape regex special characters first
    $pattern =~ s/([\[\]{}().*+?^$|\\])/\\$1/g;
    
    # Convert format specifiers to capture groups
    $pattern =~ s/yyyy/(\\\\d{4})/g;
    $pattern =~ s/yy/(\\\\d{2})/g;
    $pattern =~ s/MM/(\\\\d{1,2})/g;
    $pattern =~ s/dd/(\\\\d{1,2})/g;
    $pattern =~ s/HH/(\\\\d{1,2})/g;
    $pattern =~ s/mm/(\\\\d{1,2})/g;
    $pattern =~ s/ss/(\\\\d{1,2})/g;
    $pattern =~ s/fff/(\\\\d{1,3})/g;
    $pattern =~ s/tt/(AM|PM)/gi;
    
    return "^" . $pattern . "\$";
  }
  
  sub _CreateDateTimeFromCaptures {
    my ($format, @captures) = @_;
    
    # This would need to be more sophisticated to handle all format combinations
    # For now, assume yyyy-MM-dd HH:mm:ss format
    my ($year, $month, $day, $hour, $minute, $second) = @captures;
    
    $year //= 1;
    $month //= 1;
    $day //= 1;
    $hour //= 0;
    $minute //= 0;
    $second //= 0;
    
    return System::DateTime->new($year, $month, $day, $hour, $minute, $second);
  }
  
  # Culture-aware name methods
  sub _GetDayName {
    my ($dayOfWeek) = @_;
    my @dayNames = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
    return $dayNames[$dayOfWeek] // 'Sunday';
  }
  
  sub _GetDayAbbreviation {
    my ($dayOfWeek) = @_;
    my @dayAbbrevs = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
    return $dayAbbrevs[$dayOfWeek] // 'Sun';
  }
  
  sub _GetMonthName {
    my ($month) = @_;
    my @monthNames = ('', 'January', 'February', 'March', 'April', 'May', 'June',
                      'July', 'August', 'September', 'October', 'November', 'December');
    return $monthNames[$month] // 'January';
  }
  
  sub _GetMonthAbbreviation {
    my ($month) = @_;
    my @monthAbbrevs = ('', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    return $monthAbbrevs[$month] // 'Jan';
  }

  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;