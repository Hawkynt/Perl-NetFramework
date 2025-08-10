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
      _x => 0, _y => 0, _z => 0, _w => 0, # xorshift128+ state
    }, ref($class) || $class || __PACKAGE__;
    
    if (defined($seed)) {
      throw(System::ArgumentException->new('seed must be an integer'))
        if ref($seed) && !$seed->isa('System::Int32');
      
      my $seedValue = ref($seed) ? $seed->Value() : $seed;
      $this->{_seed} = $seedValue;
    } else {
      # Use current time and process info as seed
      $this->{_seed} = time() ^ ($$ << 16) ^ int(rand(2**31));
    }
    
    # Initialize xorshift128+ state 
    $this->_InitializeState($this->{_seed});
    
    return $this;
  }
  
  # Initialize xorshift128+ state - simple, high quality, portable
  sub _InitializeState {
    my ($this, $seed) = @_;
    
    # Use a simple LCG to generate initial state from seed
    my $s = $seed || 1;
    $s = 1 if $s == 0; # Avoid zero state
    
    # Generate 4 initial state values
    $s = ($s * 1103515245 + 12345) & 0x7FFFFFFF; $this->{_x} = $s;
    $s = ($s * 1103515245 + 12345) & 0x7FFFFFFF; $this->{_y} = $s;  
    $s = ($s * 1103515245 + 12345) & 0x7FFFFFFF; $this->{_z} = $s;
    $s = ($s * 1103515245 + 12345) & 0x7FFFFFFF; $this->{_w} = $s;
    
    # Ensure no zero state
    $this->{_w} = 1 if $this->{_w} == 0;
  }
  
  # xorshift128+ algorithm - fast, good quality, simple
  sub _NextRandom64 {
    my ($this) = @_;
    
    # xorshift128+ algorithm
    my $t = $this->{_x} ^ ($this->{_x} << 11);
    $this->{_x} = $this->{_y};
    $this->{_y} = $this->{_z};
    $this->{_z} = $this->{_w};
    $this->{_w} = ($this->{_w} ^ ($this->{_w} >> 19)) ^ ($t ^ ($t >> 8));
    
    # Use 32-bit values to create 64-bit-like result
    return ($this->{_z} << 32) + $this->{_w};
  }
  
  # Internal method to generate next random number (32-bit for .NET compatibility)
  sub _NextRandom {
    my ($this) = @_;
    # Use upper 32 bits of Xoshiro256++ output for best quality
    return ($this->_NextRandom64() >> 32) & 0x7FFFFFFF; # Keep positive for .NET compatibility
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
    
    # Use full 64-bit precision for better quality doubles
    # Use 53 bits of precision (IEEE 754 double mantissa size)
    my $random64 = $this->_NextRandom64();
    return ($random64 >> 11) / 9007199254740992.0; # 2^53
  }
  
  # Fill byte array with random bytes
  sub NextBytes {
    my ($this, $buffer) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('buffer')) unless defined($buffer);
    
    if (ref($buffer) eq 'ARRAY') {
      # Fill array with random bytes efficiently using 64-bit output
      my $i = 0;
      while ($i <= $#$buffer) {
        my $random64 = $this->_NextRandom64();
        # Extract 8 bytes from the 64-bit value
        for my $byte_idx (0..7) {
          last if $i > $#$buffer;
          $buffer->[$i] = ($random64 >> ($byte_idx * 8)) & 0xFF;
          $i++;
        }
      }
    } elsif (ref($buffer) && $buffer->isa('System::Array')) {
      # Handle System::Array
      my $length = $buffer->Length();
      my $i = 0;
      while ($i < $length) {
        my $random64 = $this->_NextRandom64();
        # Extract 8 bytes from the 64-bit value
        for my $byte_idx (0..7) {
          last if $i >= $length;
          $buffer->SetValue(($random64 >> ($byte_idx * 8)) & 0xFF, $i);
          $i++;
        }
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