package System::Random; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Int32;
  require System::Double;
  
  # Random - represents a pseudo-random number generator
  
  sub new {
    my ($class, $seed) = @_;
    
    my $this = bless {
      _seed => undef,
      _rng_state => undef,
    }, ref($class) || $class || __PACKAGE__;
    
    if (defined($seed)) {
      throw(System::ArgumentException->new('seed must be an integer'))
        if ref($seed) && !$seed->isa('System::Int32');
      
      my $seedValue = ref($seed) ? $seed->Value() : $seed;
      $this->{_seed} = $seedValue;
    } else {
      # Use current time as seed
      $this->{_seed} = time() ^ $$;  # XOR with process ID for more randomness
    }
    
    # Initialize our own Linear Congruential Generator state
    $this->{_rng_state} = $this->{_seed} % 2147483647;
    $this->{_rng_state} = 1 if $this->{_rng_state} <= 0; # Ensure positive
    
    return $this;
  }
  
  # Internal method to generate next random number using LCG
  sub _NextRandom {
    my ($this) = @_;
    # Linear Congruential Generator: (a * x + c) mod m
    # Using same constants as .NET Framework
    $this->{_rng_state} = (1103515245 * $this->{_rng_state} + 12345) % 2147483647;
    return $this->{_rng_state};
  }

  # Generate random integer
  sub Next {
    my ($this, $minValue, $maxValue) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!defined($minValue) && !defined($maxValue)) {
      # Next() - return non-negative integer
      return $this->_NextRandom() % 2147483647;
    } elsif (!defined($maxValue)) {
      # Next(maxValue) - return integer from 0 to maxValue-1
      my $max = ref($minValue) ? $minValue->Value() : $minValue;
      throw(System::ArgumentOutOfRangeException->new('maxValue', 'maxValue must be positive'))
        if $max <= 0;
      
      return $this->_NextRandom() % $max;
    } else {
      # Next(minValue, maxValue) - return integer from minValue to maxValue-1
      my $min = ref($minValue) ? $minValue->Value() : $minValue;
      my $max = ref($maxValue) ? $maxValue->Value() : $maxValue;
      
      throw(System::ArgumentOutOfRangeException->new('minValue'))
        if $min > $max;
      
      return $min + int(($this->_NextRandom() / 2147483647.0) * ($max - $min));
    }
  }
  
  # Generate random double between 0.0 and 1.0
  sub NextDouble {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return ($this->_NextRandom() / 2147483647.0);
  }
  
  # Fill byte array with random bytes
  sub NextBytes {
    my ($this, $buffer) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    
    if (ref($buffer) eq 'ARRAY') {
      # Fill array with random bytes
      for my $i (0..$#$buffer) {
        $buffer->[$i] = int(($this->_NextRandom() / 2147483647.0) * 256);
      }
    } elsif (ref($buffer) && $buffer->isa('System::Array')) {
      # Handle System::Array
      my $length = $buffer->Length();
      for my $i (0..$length-1) {
        $buffer->SetValue(int(($this->_NextRandom() / 2147483647.0) * 256), $i);
      }
    } else {
      throw(System::ArgumentException->new('buffer must be an array'));
    }
  }
  
  # Static shared instance
  my $_shared;
  
  sub Shared {
    my ($class) = @_;
    $_shared //= $class->new();
    return $_shared;
  }
  
  # Advanced random number generation methods
  sub NextInt64 {
    my ($this, $minValue, $maxValue) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!defined($minValue) && !defined($maxValue)) {
      # Generate full range Int64
      my $high = int(($this->_NextRandom() / 2147483647.0) * 4294967296);  # 2^32
      my $low = int(($this->_NextRandom() / 2147483647.0) * 4294967296);
      return ($high << 32) | $low;
    } elsif (!defined($maxValue)) {
      # NextInt64(maxValue)
      my $max = ref($minValue) ? $minValue->Value() : $minValue;
      throw(System::ArgumentOutOfRangeException->new('maxValue'))
        if $max <= 0;
      
      return $this->_NextRandom() % $max;
    } else {
      # NextInt64(minValue, maxValue)
      my $min = ref($minValue) ? $minValue->Value() : $minValue;
      my $max = ref($maxValue) ? $maxValue->Value() : $maxValue;
      
      throw(System::ArgumentOutOfRangeException->new('minValue'))
        if $min > $max;
      
      return $min + int(($this->_NextRandom() / 2147483647.0) * ($max - $min));
    }
  }
  
  sub NextSingle {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return ($this->_NextRandom() / 2147483647.0);  # Returns float between 0.0 and 1.0
  }
  
  # Generate random boolean
  sub NextBoolean {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return ($this->_NextRandom() / 2147483647.0) < 0.5 ? false : true;
  }
  
  # Generate random string
  sub NextString {
    my ($this, $length, $charset) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('length'))
      if defined($length) && $length < 0;
    
    $length //= 10;
    $charset //= 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    
    my $result = '';
    my $charsetLength = length($charset);
    
    for my $i (1..$length) {
      $result .= substr($charset, int(($this->_NextRandom() / 2147483647.0) * $charsetLength), 1);
    }
    
    return $result;
  }
  
  # Gaussian/normal distribution
  my $_hasSpare = false;
  my $_spare = 0;
  
  sub NextGaussian {
    my ($this, $mean, $stdDev) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $mean //= 0.0;
    $stdDev //= 1.0;
    
    if ($_hasSpare) {
      $_hasSpare = false;
      return $_spare * $stdDev + $mean;
    }
    
    $_hasSpare = true;
    
    my $u;
    do { $u = ($this->_NextRandom() / 2147483647.0); } while ($u == 0);  # Converting [0,1) to (0,1)
    my $v = ($this->_NextRandom() / 2147483647.0);
    
    my $mag = $stdDev * sqrt(-2.0 * log($u));
    $_spare = $mag * cos(2.0 * 3.14159265359 * $v);
    
    return $mag * sin(2.0 * 3.14159265359 * $v) + $mean;
  }
  
  # Sample from array
  sub Sample {
    my ($this, $array) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('array')) unless defined($array);
    
    my $length;
    if (ref($array) eq 'ARRAY') {
      $length = scalar(@$array);
      return $array->[int(($this->_NextRandom() / 2147483647.0) * $length)] if $length > 0;
    } elsif (ref($array) && $array->isa('System::Array')) {
      $length = $array->Length();
      return $array->GetValue(int(($this->_NextRandom() / 2147483647.0) * $length)) if $length > 0;
    }
    
    throw(System::ArgumentException->new('array must be non-empty'));
  }
  
  # Shuffle array in place
  sub Shuffle {
    my ($this, $array) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('array')) unless defined($array);
    
    if (ref($array) eq 'ARRAY') {
      # Fisher-Yates shuffle
      for my $i (reverse 1..$#$array) {
        my $j = int(($this->_NextRandom() / 2147483647.0) * ($i + 1));
        ($array->[$i], $array->[$j]) = ($array->[$j], $array->[$i]);
      }
    } elsif (ref($array) && $array->isa('System::Array')) {
      # Handle System::Array
      my $length = $array->Length();
      for my $i (reverse 1..($length-1)) {
        my $j = int(($this->_NextRandom() / 2147483647.0) * ($i + 1));
        my $temp = $array->GetValue($i);
        $array->SetValue($array->GetValue($j), $i);
        $array->SetValue($temp, $j);
      }
    } else {
      throw(System::ArgumentException->new('array must be an array'));
    }
  }
  
  # Reset seed
  sub SetSeed {
    my ($this, $seed) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('seed')) unless defined($seed);
    
    my $seedValue = ref($seed) ? $seed->Value() : $seed;
    $this->{_seed} = $seedValue;
    $this->{_rng_state} = $seedValue % 2147483647;
    $this->{_rng_state} = 1 if $this->{_rng_state} <= 0; # Ensure positive
  }
  
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return "System.Random (Seed: $this->{_seed})";
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;