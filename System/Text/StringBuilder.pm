package System::Text::StringBuilder; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::String;
  require System::Int32;
  
  # StringBuilder - mutable string for efficient string building operations
  
  sub new {
    my ($class, $value, $capacity) = @_;
    
    my $this = bless {
      _buffer => [],
      _capacity => 16,  # Default capacity
      _maxCapacity => 2147483647,  # Int32.MaxValue
    }, ref($class) || $class || __PACKAGE__;
    
    # Handle capacity parameter
    if (defined($capacity)) {
      my $cap = ref($capacity) ? $capacity->Value() : $capacity;
      throw(System::ArgumentOutOfRangeException->new('capacity', 'capacity must be positive'))
        if $cap < 0;
      throw(System::ArgumentOutOfRangeException->new('capacity', 'capacity exceeds maximum'))
        if $cap > $this->{_maxCapacity};
      $this->{_capacity} = $cap;
    }
    
    # Handle initial value
    if (defined($value)) {
      my $str = ref($value) && $value->isa('System::String') ? $value->ToString() : $value;
      throw(System::ArgumentException->new('value must be a string'))
        unless defined($str);
      
      my @chars = split //, $str;
      $this->{_buffer} = \@chars;
      
      # Ensure capacity is at least the length of the initial value
      if (@chars > $this->{_capacity}) {
        $this->{_capacity} = @chars * 2;  # Double for growth
      }
    }
    
    return $this;
  }
  
  # Properties
  sub Length {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return scalar(@{$this->{_buffer}});
  }
  
  sub Capacity {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      my $cap = ref($value) ? $value->Value() : $value;
      throw(System::ArgumentOutOfRangeException->new('capacity', 'capacity must be positive'))
        if $cap < 0;
      throw(System::ArgumentOutOfRangeException->new('capacity', 'capacity exceeds maximum'))
        if $cap > $this->{_maxCapacity};
      throw(System::ArgumentOutOfRangeException->new('capacity', 'capacity cannot be less than length'))
        if $cap < $this->Length();
      
      $this->{_capacity} = $cap;
      return $this;
    }
    
    return $this->{_capacity};
  }
  
  sub MaxCapacity {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_maxCapacity};
  }
  
  # Indexer
  sub get_Item {
    my ($this, $index) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $idx = ref($index) ? $index->Value() : $index;
    throw(System::ArgumentOutOfRangeException->new('index'))
      if $idx < 0 || $idx >= $this->Length();
    
    return $this->{_buffer}->[$idx];
  }
  
  sub set_Item {
    my ($this, $index, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $idx = ref($index) ? $index->Value() : $index;
    throw(System::ArgumentOutOfRangeException->new('index'))
      if $idx < 0 || $idx >= $this->Length();
    
    $this->{_buffer}->[$idx] = $value;
  }
  
  # Core append methods
  sub Append {
    my ($this, $value, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return $this unless defined($value);
    
    my $str;
    if (ref($value) && $value->isa('System::String')) {
      $str = $value->ToString();
    } elsif (ref($value) && $value->can('ToString')) {
      $str = $value->ToString();
    } else {
      $str = "$value";
    }
    
    # Handle count parameter for repeated appends
    if (defined($count)) {
      my $repeatCount = ref($count) ? $count->Value() : $count;
      throw(System::ArgumentOutOfRangeException->new('count'))
        if $repeatCount < 0;
      
      $str = $str x $repeatCount;
    }
    
    $this->_EnsureCapacity($this->Length() + length($str));
    
    my @chars = split //, $str;
    push @{$this->{_buffer}}, @chars;
    
    return $this;
  }
  
  sub AppendChar {
    my ($this, $value, $repeatCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('value')) unless defined($value);
    
    $repeatCount //= 1;
    my $count = ref($repeatCount) ? $repeatCount->Value() : $repeatCount;
    throw(System::ArgumentOutOfRangeException->new('repeatCount'))
      if $count < 0;
    
    return $this if $count == 0;
    
    $this->_EnsureCapacity($this->Length() + $count);
    
    for (1..$count) {
      push @{$this->{_buffer}}, $value;
    }
    
    return $this;
  }
  
  sub AppendLine {
    my ($this, $value) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($value)) {
      $this->Append($value);
    }
    
    return $this->Append("\n");
  }
  
  sub AppendFormat {
    my ($this, $format, @args) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('format')) unless defined($format);
    
    # Simple format implementation - replace {0}, {1}, etc.
    my $formatStr = ref($format) && $format->isa('System::String') ? $format->ToString() : $format;
    
    for my $i (0..$#args) {
      my $arg = $args[$i];
      my $argStr = ref($arg) && $arg->can('ToString') ? $arg->ToString() : "$arg";
      $formatStr =~ s/\{$i\}/$argStr/g;
    }
    
    return $this->Append($formatStr);
  }
  
  # Insert methods
  sub Insert {
    my ($this, $index, $value, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $idx = ref($index) ? $index->Value() : $index;
    throw(System::ArgumentOutOfRangeException->new('index'))
      if $idx < 0 || $idx > $this->Length();
    
    return $this unless defined($value);
    
    my $str;
    if (ref($value) && $value->isa('System::String')) {
      $str = $value->ToString();
    } elsif (ref($value) && $value->can('ToString')) {
      $str = $value->ToString();
    } else {
      $str = "$value";
    }
    
    # Handle count parameter
    if (defined($count)) {
      my $repeatCount = ref($count) ? $count->Value() : $count;
      throw(System::ArgumentOutOfRangeException->new('count'))
        if $repeatCount < 0;
      
      $str = $str x $repeatCount;
    }
    
    $this->_EnsureCapacity($this->Length() + length($str));
    
    my @chars = split //, $str;
    splice @{$this->{_buffer}}, $idx, 0, @chars;
    
    return $this;
  }
  
  # Remove methods
  sub Remove {
    my ($this, $startIndex, $length) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $start = ref($startIndex) ? $startIndex->Value() : $startIndex;
    my $len = ref($length) ? $length->Value() : $length;
    
    throw(System::ArgumentOutOfRangeException->new('startIndex'))
      if $start < 0;
    throw(System::ArgumentOutOfRangeException->new('length'))
      if $len < 0;
    throw(System::ArgumentOutOfRangeException->new('startIndex'))
      if $start + $len > $this->Length();
    
    splice @{$this->{_buffer}}, $start, $len;
    
    return $this;
  }
  
  sub Clear {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $this->{_buffer} = [];
    return $this;
  }
  
  # Replace methods
  sub Replace {
    my ($this, $oldValue, $newValue, $startIndex, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('oldValue')) unless defined($oldValue);
    
    my $oldStr = ref($oldValue) && $oldValue->isa('System::String') ? $oldValue->ToString() : $oldValue;
    my $newStr = defined($newValue) ? 
      (ref($newValue) && $newValue->isa('System::String') ? $newValue->ToString() : $newValue) : '';
    
    throw(System::ArgumentException->new('oldValue cannot be empty'))
      if length($oldStr) == 0;
    
    # Convert buffer to string for replacement
    my $str = join('', @{$this->{_buffer}});
    
    if (defined($startIndex) && defined($count)) {
      my $start = ref($startIndex) ? $startIndex->Value() : $startIndex;
      my $cnt = ref($count) ? $count->Value() : $count;
      
      throw(System::ArgumentOutOfRangeException->new('startIndex'))
        if $start < 0 || $start > length($str);
      throw(System::ArgumentOutOfRangeException->new('count'))
        if $cnt < 0 || $start + $cnt > length($str);
      
      # Replace only in specified range
      my $beforeRange = substr($str, 0, $start);
      my $range = substr($str, $start, $cnt);
      my $afterRange = substr($str, $start + $cnt);
      
      $range =~ s/\Q$oldStr\E/$newStr/g;
      $str = $beforeRange . $range . $afterRange;
    } else {
      # Replace throughout entire string
      $str =~ s/\Q$oldStr\E/$newStr/g;
    }
    
    $this->{_buffer} = [split //, $str];
    
    return $this;
  }
  
  sub ReplaceChar {
    my ($this, $oldChar, $newChar, $startIndex, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('oldChar')) unless defined($oldChar);
    throw(System::ArgumentNullException->new('newChar')) unless defined($newChar);
    
    my $start = defined($startIndex) ? (ref($startIndex) ? $startIndex->Value() : $startIndex) : 0;
    my $cnt = defined($count) ? (ref($count) ? $count->Value() : $count) : $this->Length() - $start;
    
    throw(System::ArgumentOutOfRangeException->new('startIndex'))
      if $start < 0 || $start > $this->Length();
    throw(System::ArgumentOutOfRangeException->new('count'))
      if $cnt < 0 || $start + $cnt > $this->Length();
    
    for my $i ($start..($start + $cnt - 1)) {
      if ($this->{_buffer}->[$i] eq $oldChar) {
        $this->{_buffer}->[$i] = $newChar;
      }
    }
    
    return $this;
  }
  
  # String conversion
  sub ToString {
    my ($this, $startIndex, $length) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (defined($startIndex) && defined($length)) {
      my $start = ref($startIndex) ? $startIndex->Value() : $startIndex;
      my $len = ref($length) ? $length->Value() : $length;
      
      throw(System::ArgumentOutOfRangeException->new('startIndex'))
        if $start < 0 || $start > $this->Length();
      throw(System::ArgumentOutOfRangeException->new('length'))
        if $len < 0 || $start + $len > $this->Length();
      
      return join('', @{$this->{_buffer}}[$start..($start + $len - 1)]);
    }
    
    return join('', @{$this->{_buffer}});
  }
  
  # Utility methods
  sub EnsureCapacity {
    my ($this, $capacity) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('capacity'))
      unless defined($capacity);
    
    my $cap = ref($capacity) ? $capacity->Value() : $capacity;
    throw(System::ArgumentOutOfRangeException->new('capacity'))
      if $cap < 0;
    
    if ($cap > $this->{_capacity}) {
      $this->_EnsureCapacity($cap);
    }
    
    return $this->{_capacity};
  }
  
  # Private helper methods
  sub _EnsureCapacity {
    my ($this, $minCapacity) = @_;
    
    if ($minCapacity > $this->{_capacity}) {
      my $newCapacity = $this->{_capacity} * 2;
      $newCapacity = $minCapacity if $newCapacity < $minCapacity;
      $newCapacity = $this->{_maxCapacity} if $newCapacity > $this->{_maxCapacity};
      
      throw(System::OutOfMemoryException->new())
        if $newCapacity < $minCapacity;
      
      $this->{_capacity} = $newCapacity;
    }
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return false unless defined($other);
    return false unless ref($other) && $other->isa('System::Text::StringBuilder');
    
    return $this->ToString() eq $other->ToString();
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Simple hash based on string content
    my $str = $this->ToString();
    my $hash = 0;
    for my $char (split //, $str) {
      $hash = ($hash * 31 + ord($char)) & 0x7FFFFFFF;
    }
    return $hash;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;