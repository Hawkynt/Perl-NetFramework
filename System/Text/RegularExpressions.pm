package System::Text::RegularExpressions; {
  use strict;
  use warnings;
  use CSharp;
  
  # Forward declare classes
  our @EXPORT_OK = qw(Regex Match Group Capture MatchCollection GroupCollection CaptureCollection);
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Regex class
package System::Text::RegularExpressions::Regex; {
  use base 'System::Object';
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::String;
  require System::Array;
  
  sub new {
    my ($class, $pattern, $options) = @_;
    
    my $this = bless {
      _pattern => $pattern,
      _options => $options // 0,
      _compiled => undef,
    }, ref($class) || $class || __PACKAGE__;
    
    throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    
    # Store the pattern as a string
    $this->{_patternString} = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";
    
    # Pre-compile the regex for efficiency
    eval {
      my $flags = "";
      # Add case insensitive flag if needed (would need to check options)
      # For now, keep it simple
      $this->{_compiled} = qr/$this->{_patternString}/;
    };
    
    if ($@) {
      throw(System::ArgumentException->new("Invalid regular expression pattern: $this->{_patternString}"));
    }
    
    return $this;
  }
  
  # Static methods
  sub IsMatch {
    my ($class_or_self, $input, $pattern) = @_;
    
    if (ref($class_or_self)) {
      # Instance method
      my $self = $class_or_self;
      $pattern = $self->{_patternString};
      # $input is already the input parameter
    } else {
      # Static method - parameters are: (class, input, pattern)
      # $input and $pattern are already correct
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }
    
    throw(System::ArgumentNullException->new('input')) unless defined($input);
    
    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";
    
    return $inputStr =~ /$patternStr/ ? true : false;
  }
  
  sub Match {
    my ($class_or_self, $input, $pattern, $startIndex) = @_;
    
    if (ref($class_or_self)) {
      # Instance method: $regex->Match(input, startIndex)
      my $self = $class_or_self;
      $startIndex = $pattern; # Second param becomes startIndex
      $pattern = $self->{_patternString};
    } else {
      # Static method: Regex->Match(input, pattern, startIndex)
      # Parameters are already correct
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }
    
    throw(System::ArgumentNullException->new('input')) unless defined($input);
    
    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";
    
    $startIndex //= 0;
    my $start = ref($startIndex) ? $startIndex->Value() : $startIndex;
    
    # Extract substring from start index
    my $searchStr = $start > 0 ? substr($inputStr, $start) : $inputStr;
    
    if ($searchStr =~ /($patternStr)/) {
      my $matchValue = $1;
      my $matchIndex = $start + $-[0];
      my $matchLength = length($matchValue);
      
      return System::Text::RegularExpressions::Match->new(
        $matchValue, $matchIndex, $matchLength, true, $inputStr, $patternStr
      );
    } else {
      return System::Text::RegularExpressions::Match->new(
        "", -1, 0, false, $inputStr, $patternStr
      );
    }
  }
  
  sub Matches {
    my ($class_or_self, $input, $pattern) = @_;
    
    if (ref($class_or_self)) {
      # Instance method: $regex->Matches(input)
      my $self = $class_or_self;
      $pattern = $self->{_patternString};
      # $input is already correct
    } else {
      # Static method: Regex->Matches(input, pattern)
      # Parameters are already correct
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }
    
    throw(System::ArgumentNullException->new('input')) unless defined($input);
    
    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";
    
    my @matches = ();
    
    # Find all matches
    while ($inputStr =~ /($patternStr)/g) {
      my $matchValue = $1;
      my $matchIndex = $-[0];
      my $matchLength = length($matchValue);
      
      push @matches, System::Text::RegularExpressions::Match->new(
        $matchValue, $matchIndex, $matchLength, true, $inputStr, $patternStr
      );
    }
    
    return System::Text::RegularExpressions::MatchCollection->new(\@matches);
  }
  
  sub Replace {
    my ($class_or_self, $input, $replacement, $pattern) = @_;
    
    if (ref($class_or_self)) {
      # Instance method: $regex->Replace(input, replacement)
      my $self = $class_or_self;
      $pattern = $self->{_patternString};
      # $input and $replacement are already correct
    } else {
      # Static method: Regex->Replace(input, pattern, replacement)
      # Need to shift parameters: input=$input, pattern=$replacement, replacement=$pattern
      my $temp = $replacement;
      $replacement = $pattern;
      $pattern = $temp;
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }
    
    throw(System::ArgumentNullException->new('input')) unless defined($input);
    throw(System::ArgumentNullException->new('replacement')) unless defined($replacement);
    
    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $replacementStr = ref($replacement) && $replacement->can('ToString') ? $replacement->ToString() : "$replacement";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";
    
    my $result = $inputStr;
    $result =~ s/$patternStr/$replacementStr/g;
    
    require System::String;
    return System::String->new($result);
  }
  
  sub Split {
    my ($class_or_self, $input, $pattern) = @_;
    
    if (ref($class_or_self)) {
      # Instance method: $regex->Split(input)
      my $self = $class_or_self;
      $pattern = $self->{_patternString};
      # $input is already correct
    } else {
      # Static method: Regex->Split(input, pattern)
      # Parameters are already correct
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }
    
    throw(System::ArgumentNullException->new('input')) unless defined($input);
    
    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";
    
    my @parts = split(/$patternStr/, $inputStr);
    
    # Handle empty string case - should return array with one empty string
    if (@parts == 0 && $inputStr eq '') {
      @parts = ('');
    }
    
    # Convert to System::String objects
    my @stringParts = map { System::String->new($_) } @parts;
    
    require System::Array;
    return System::Array->new(@stringParts);
  }
  
  # Properties
  sub Options {
    my ($this) = @_;
    return $this->{_options};
  }
  
  sub ToString {
    my ($this) = @_;
    return $this->{_patternString};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Match class
package System::Text::RegularExpressions::Match; {
  use base 'System::Object';
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::String;
  
  sub new {
    my ($class, $value, $index, $length, $success, $input, $pattern) = @_;
    
    return bless {
      _value => $value // "",
      _index => $index // -1,
      _length => $length // 0,
      _success => $success // false,
      _input => $input // "",
      _pattern => $pattern // "",
      _groups => undef,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Success {
    my ($this) = @_;
    return $this->{_success};
  }
  
  sub Value {
    my ($this) = @_;
    return $this->{_value};
  }
  
  sub Index {
    my ($this) = @_;
    return $this->{_index};
  }
  
  sub Length {
    my ($this) = @_;
    return $this->{_length};
  }
  
  sub Groups {
    my ($this) = @_;
    
    if (!defined($this->{_groups})) {
      # Create a basic group collection
      # For simplicity, just create a collection with the main match
      my @groups = (
        System::Text::RegularExpressions::Group->new($this->{_value}, $this->{_index}, $this->{_length}, $this->{_success})
      );
      $this->{_groups} = System::Text::RegularExpressions::GroupCollection->new(\@groups);
    }
    
    return $this->{_groups};
  }
  
  sub ToString {
    my ($this) = @_;
    return $this->{_value};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# Group class
package System::Text::RegularExpressions::Group; {
  use base 'System::Object';
  use strict;
  use warnings;
  use CSharp;
  
  sub new {
    my ($class, $value, $index, $length, $success) = @_;
    
    return bless {
      _value => $value // "",
      _index => $index // -1,
      _length => $length // 0,
      _success => $success // false,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub Success {
    my ($this) = @_;
    return $this->{_success};
  }
  
  sub Value {
    my ($this) = @_;
    return $this->{_value};
  }
  
  sub Index {
    my ($this) = @_;
    return $this->{_index};
  }
  
  sub Length {
    my ($this) = @_;
    return $this->{_length};
  }
  
  sub ToString {
    my ($this) = @_;
    return $this->{_value};
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# MatchCollection class
package System::Text::RegularExpressions::MatchCollection; {
  use base 'System::Object';
  use strict;
  use warnings;
  use CSharp;
  
  sub new {
    my ($class, $matches) = @_;
    
    return bless {
      _matches => $matches // [],
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties and methods
  sub Count {
    my ($this) = @_;
    return scalar(@{$this->{_matches}});
  }
  
  sub Item {
    my ($this, $index) = @_;
    my $idx = ref($index) ? $index->Value() : $index;
    
    throw(System::ArgumentOutOfRangeException->new('index'))
      if $idx < 0 || $idx >= $this->Count();
    
    return $this->{_matches}->[$idx];
  }
  
  # Indexer alias
  sub get_Item { shift->Item(@_); }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# GroupCollection class
package System::Text::RegularExpressions::GroupCollection; {
  use base 'System::Object';
  use strict;
  use warnings;
  use CSharp;
  
  sub new {
    my ($class, $groups) = @_;
    
    return bless {
      _groups => $groups // [],
      _groupsByName => {},
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties and methods
  sub Count {
    my ($this) = @_;
    return scalar(@{$this->{_groups}});
  }
  
  sub Item {
    my ($this, $index) = @_;
    
    if (ref($index) || $index =~ /^\d+$/) {
      # Numeric index
      my $idx = ref($index) ? $index->Value() : $index;
      throw(System::ArgumentOutOfRangeException->new('index'))
        if $idx < 0 || $idx >= $this->Count();
      
      return $this->{_groups}->[$idx];
    } else {
      # Named index
      return $this->{_groupsByName}->{$index} // 
        System::Text::RegularExpressions::Group->new("", -1, 0, false);
    }
  }
  
  # Indexer alias
  sub get_Item { shift->Item(@_); }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;