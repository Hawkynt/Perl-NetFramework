package System::Text::RegularExpressions; {
  use strict;
  use warnings;
  use CSharp;

  # Forward declare classes
  our @EXPORT_OK = qw(Regex Match Group Capture MatchCollection GroupCollection CaptureCollection);

  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

# RegexOptions constants (values match .NET System.Text.RegularExpressions.RegexOptions)
package System::Text::RegularExpressions::RegexOptions; {
  use strict;
  use warnings;
  use constant {
    None                    => 0,
    IgnoreCase              => 1,
    Multiline               => 2,
    ExplicitCapture         => 4,
    Compiled                => 8,
    Singleline              => 16,
    IgnorePatternWhitespace => 32,
    RightToLeft             => 64,
    ECMAScript              => 256,
    CultureInvariant        => 512,
  };

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

    throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);

    my $optValue = ref($options) && $options->can('Value') ? $options->Value() : (defined($options) ? $options : 0);

    my $this = bless {
      _pattern => $pattern,
      _options => $optValue,
      _compiled => undef,
    }, ref($class) || $class || __PACKAGE__;

    # Store the pattern as a string
    $this->{_patternString} = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";

    # Pre-compile the regex for efficiency / validation
    eval {
      $this->{_compiled} = _CompilePattern($this->{_patternString}, $optValue);
    };

    if ($@) {
      throw(System::ArgumentException->new("Invalid regular expression pattern: $this->{_patternString}"));
    }

    return $this;
  }

  # Translate a .NET-style pattern into a 5.8-safe pattern.
  # Rewrites named groups (?<name>...) and (?'name'...) into plain capturing
  # groups (...), recording a name -> group-number mapping. Leaves
  # non-capturing groups (?:...), lookarounds (?=...)(?!...)(?<=...)(?<!...)
  # and other (?...) constructs untouched while still counting capture groups
  # so that numbering stays correct.
  # Returns ($translatedPattern, \%nameToNumber).
  sub _TranslatePattern {
    my ($pattern) = @_;

    my $out = '';
    my %nameToNumber;
    my $groupNum = 0;
    my $len = length($pattern);
    my $i = 0;

    while ($i < $len) {
      my $ch = substr($pattern, $i, 1);

      # Escaped character: copy the backslash and the next char verbatim
      if ($ch eq '\\') {
        $out .= $ch;
        if ($i + 1 < $len) {
          $out .= substr($pattern, $i + 1, 1);
          $i += 2;
        } else {
          $i += 1;
        }
        next;
      }

      # Character class [...]: copy verbatim (parens inside are literal)
      if ($ch eq '[') {
        $out .= $ch;
        $i += 1;
        # Optional leading ^ and ] as literal
        if ($i < $len && substr($pattern, $i, 1) eq '^') {
          $out .= '^';
          $i += 1;
        }
        if ($i < $len && substr($pattern, $i, 1) eq ']') {
          $out .= ']';
          $i += 1;
        }
        while ($i < $len) {
          my $c = substr($pattern, $i, 1);
          if ($c eq '\\') {
            $out .= $c;
            if ($i + 1 < $len) {
              $out .= substr($pattern, $i + 1, 1);
              $i += 2;
            } else {
              $i += 1;
            }
            next;
          }
          $out .= $c;
          $i += 1;
          last if $c eq ']';
        }
        next;
      }

      if ($ch eq '(') {
        # Look at what follows the '('
        my $next = ($i + 1 < $len) ? substr($pattern, $i + 1, 1) : '';

        if ($next eq '?') {
          my $third = ($i + 2 < $len) ? substr($pattern, $i + 2, 1) : '';

          # Named group: (?<name>...) or (?'name'...)
          # Must NOT be a lookbehind (?<= or (?<!
          if ($third eq '<' && substr($pattern, $i + 3, 1) ne '=' && substr($pattern, $i + 3, 1) ne '!') {
            my $close = index($pattern, '>', $i + 3);
            if ($close >= 0) {
              my $name = substr($pattern, $i + 3, $close - ($i + 3));
              $groupNum++;
              $nameToNumber{$name} = $groupNum unless exists $nameToNumber{$name};
              $out .= '(';
              $i = $close + 1;
              next;
            }
          } elsif ($third eq "'") {
            my $close = index($pattern, "'", $i + 3);
            if ($close >= 0) {
              my $name = substr($pattern, $i + 3, $close - ($i + 3));
              $groupNum++;
              $nameToNumber{$name} = $groupNum unless exists $nameToNumber{$name};
              $out .= '(';
              $i = $close + 1;
              next;
            }
          }

          # Any other (?...) construct: non-capturing group, lookaround,
          # modifiers, atomic group, comment, etc. Copy verbatim, do NOT
          # increment the capture-group counter.
          $out .= '(';
          $i += 1;
          next;
        }

        # Plain capturing group
        $groupNum++;
        $out .= '(';
        $i += 1;
        next;
      }

      # Default: copy character
      $out .= $ch;
      $i += 1;
    }

    return ($out, \%nameToNumber, $groupNum);
  }

  # Build the embedded-modifier prefix for the given RegexOptions value.
  # Returns a string like "(?msi-x:" ... no, we instead return the flag letters
  # to embed via (?flags) so that they apply to the whole pattern. 5.8-safe.
  sub _OptionFlags {
    my ($options) = @_;
    $options = 0 unless defined($options);
    my $on = '';
    $on .= 'i' if ($options & System::Text::RegularExpressions::RegexOptions::IgnoreCase());
    $on .= 'm' if ($options & System::Text::RegularExpressions::RegexOptions::Multiline());
    $on .= 's' if ($options & System::Text::RegularExpressions::RegexOptions::Singleline());
    $on .= 'x' if ($options & System::Text::RegularExpressions::RegexOptions::IgnorePatternWhitespace());
    return $on;
  }

  # Compile a .NET pattern into a perl qr// honoring options.
  # Returns a hashref { qr => <compiled>, names => \%nameToNumber, count => N }.
  sub _CompilePattern {
    my ($patternStr, $options) = @_;

    my ($translated, $names, $count) = _TranslatePattern($patternStr);

    my $flags = _OptionFlags($options);
    my $compiled;
    if (length($flags)) {
      # Embed flags so they govern the whole (already translated) pattern.
      $compiled = qr/(?$flags:$translated)/;
    } else {
      $compiled = qr/$translated/;
    }

    return {
      qr    => $compiled,
      names => $names,
      count => $count,
    };
  }

  # Resolve the compiled-info hashref for either an instance (cached) or a
  # one-off static call.
  sub _ResolveCompiled {
    my ($self, $patternStr, $options) = @_;
    if (defined($self) && ref($self) && defined($self->{_compiled})) {
      return $self->{_compiled};
    }
    return _CompilePattern($patternStr, $options);
  }

  # Build a Match object from a successful match against $inputStr.
  # Expects @minus (@-) and @plus (@+) captured immediately after the match,
  # plus the offset that was applied to $searchStr.
  sub _BuildMatch {
    my ($inputStr, $patternStr, $names, $minus, $plus, $offset) = @_;

    my @groups;
    my $n = scalar(@$minus) - 1;
    for my $gi (0 .. $n) {
      if (defined($minus->[$gi]) && defined($plus->[$gi])) {
        my $gStart = $offset + $minus->[$gi];
        my $gLen = $plus->[$gi] - $minus->[$gi];
        my $gVal = substr($inputStr, $gStart, $gLen);
        push @groups, System::Text::RegularExpressions::Group->new($gVal, $gStart, $gLen, true);
      } else {
        # Group did not participate in the match.
        push @groups, System::Text::RegularExpressions::Group->new("", -1, 0, false);
      }
    }

    my $value = $groups[0]->Value();
    my $index = $groups[0]->Index();
    my $length = $groups[0]->Length();

    my $match = System::Text::RegularExpressions::Match->new(
      $value, $index, $length, true, $inputStr, $patternStr
    );
    $match->_SetGroups(\@groups, $names);
    return $match;
  }
  
  # Static methods
  sub IsMatch {
    my ($class_or_self, $input, $pattern, $options) = @_;

    my $self;
    if (ref($class_or_self)) {
      # Instance method: $regex->IsMatch(input)
      $self = $class_or_self;
      $pattern = $self->{_patternString};
      $options = $self->{_options};
    } else {
      # Static method: Regex->IsMatch(input, pattern, options)
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }

    throw(System::ArgumentNullException->new('input')) unless defined($input);

    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";

    my $info = _ResolveCompiled($self, $patternStr, $options);
    my $qr = $info->{qr};

    return $inputStr =~ /$qr/ ? true : false;
  }

  sub Match {
    my ($class_or_self, $input, $pattern, $startIndex) = @_;

    my $self;
    my $options;
    if (ref($class_or_self)) {
      # Instance method: $regex->Match(input, startIndex)
      $self = $class_or_self;
      $startIndex = $pattern; # Second param becomes startIndex
      $pattern = $self->{_patternString};
      $options = $self->{_options};
    } else {
      # Static method: Regex->Match(input, pattern, startIndex)
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }

    throw(System::ArgumentNullException->new('input')) unless defined($input);

    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";

    $startIndex = 0 unless defined($startIndex);
    my $start = ref($startIndex) ? $startIndex->Value() : $startIndex;

    my $info = _ResolveCompiled($self, $patternStr, $options);
    my $qr = $info->{qr};
    my $names = $info->{names};

    # Extract substring from start index
    my $searchStr = $start > 0 ? substr($inputStr, $start) : $inputStr;

    if ($searchStr =~ /$qr/) {
      my @minus = @-;
      my @plus = @+;
      return _BuildMatch($inputStr, $patternStr, $names, \@minus, \@plus, $start);
    } else {
      return System::Text::RegularExpressions::Match->new(
        "", -1, 0, false, $inputStr, $patternStr
      );
    }
  }

  sub Matches {
    my ($class_or_self, $input, $pattern, $options) = @_;

    my $self;
    if (ref($class_or_self)) {
      # Instance method: $regex->Matches(input)
      $self = $class_or_self;
      $pattern = $self->{_patternString};
      $options = $self->{_options};
    } else {
      # Static method: Regex->Matches(input, pattern, options)
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }

    throw(System::ArgumentNullException->new('input')) unless defined($input);

    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";

    my $info = _ResolveCompiled($self, $patternStr, $options);
    my $qr = $info->{qr};
    my $names = $info->{names};

    my @matches = ();

    # Find all matches (offset is 0 since we scan the whole input)
    while ($inputStr =~ /$qr/g) {
      my @minus = @-;
      my @plus = @+;
      push @matches, _BuildMatch($inputStr, $patternStr, $names, \@minus, \@plus, 0);
      # Guard against zero-width infinite loops
      pos($inputStr) = $plus[0] + 1 if defined($plus[0]) && $plus[0] == $minus[0];
    }

    return System::Text::RegularExpressions::MatchCollection->new(\@matches);
  }

  sub Replace {
    my ($class_or_self, $input, $replacement, $pattern, $options) = @_;

    my $self;
    if (ref($class_or_self)) {
      # Instance method: $regex->Replace(input, replacement)
      $self = $class_or_self;
      $pattern = $self->{_patternString};
      $options = $self->{_options};
    } else {
      # Static method: Regex->Replace(input, pattern, replacement, options)
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

    my $info = _ResolveCompiled($self, $patternStr, $options);
    my $qr = $info->{qr};

    # Translate .NET substitution syntax $1, ${name}, $& into perl equivalents.
    my $names = $info->{names};
    my $result = $inputStr;
    my $ngroups = $info->{count};
    # Snapshot the capture variables ($&, $1..$N) at the top of the block,
    # BEFORE the inner substitutions in _ExpandReplacement clobber them.
    $result =~ s{$qr}{
      my $whole = defined($&) ? $& : '';
      my @caps;
      $caps[0] = $whole;
      no strict 'refs';
      for my $gi (1 .. $ngroups) {
        $caps[$gi] = defined(${$gi}) ? ${$gi} : undef;
      }
      use strict 'refs';
      _ExpandReplacement($replacementStr, $names, $whole, \@caps);
    }ge;

    require System::String;
    return System::String->new($result);
  }

  # Expand a .NET-style replacement string against the current match captures.
  # Called from within an s///e, so we snapshot the capture group values via
  # @{^CAPTURE}-free, 5.8-safe means: copy $1..$N and $& before running any
  # inner substitutions (which would clobber the match variables).
  sub _ExpandReplacement {
    my ($replacementStr, $names, $whole, $caps) = @_;
    my $out = $replacementStr;

    # ${name} -> named or numbered group value
    $out =~ s/\$\{(\w+)\}/_GroupValue($1, $names, $caps)/ge;
    # $1..$N -> numbered group value
    $out =~ s/\$(\d+)/_GroupValue($1, $names, $caps)/ge;
    # $& -> whole match
    $out =~ s/\$&/defined($whole) ? $whole : ''/ge;

    return $out;
  }

  sub _GroupValue {
    my ($name, $names, $caps) = @_;
    my $num;
    if ($name =~ /^\d+$/) {
      $num = $name;
    } elsif (defined($names) && exists $names->{$name}) {
      $num = $names->{$name};
    } else {
      return '';
    }
    # $caps is 1-based: $caps->[1] is $1.
    return (defined($caps->[$num]) ? $caps->[$num] : '');
  }

  sub Split {
    my ($class_or_self, $input, $pattern, $options) = @_;

    my $self;
    if (ref($class_or_self)) {
      # Instance method: $regex->Split(input)
      $self = $class_or_self;
      $pattern = $self->{_patternString};
      $options = $self->{_options};
    } else {
      # Static method: Regex->Split(input, pattern, options)
      throw(System::ArgumentNullException->new('pattern')) unless defined($pattern);
    }

    throw(System::ArgumentNullException->new('input')) unless defined($input);

    my $inputStr = ref($input) && $input->can('ToString') ? $input->ToString() : "$input";
    my $patternStr = ref($pattern) && $pattern->can('ToString') ? $pattern->ToString() : "$pattern";

    my $info = _ResolveCompiled($self, $patternStr, $options);
    my $qr = $info->{qr};

    my @parts = split(/$qr/, $inputStr);
    
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
      _value => defined($value) ? $value : (""),
      _index => defined($index) ? $index : (-1),
      _length => defined($length) ? $length : (0),
      _success => defined($success) ? $success : (false),
      _input => defined($input) ? $input : (""),
      _pattern => defined($pattern) ? $pattern : (""),
      _groups => undef,
      _groupList => undef,
      _names => undef,
    }, ref($class) || $class || __PACKAGE__;
  }

  # Internal: store the full list of Group objects plus the name->number map.
  sub _SetGroups {
    my ($this, $groupList, $names) = @_;
    $this->{_groupList} = $groupList;
    $this->{_names} = $names;
    $this->{_groups} = undef; # force rebuild of GroupCollection
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
      my $groupList;
      if (defined($this->{_groupList})) {
        $groupList = $this->{_groupList};
      } else {
        # Fall back to a collection containing only the whole match (group 0).
        $groupList = [
          System::Text::RegularExpressions::Group->new($this->{_value}, $this->{_index}, $this->{_length}, $this->{_success})
        ];
      }
      $this->{_groups} = System::Text::RegularExpressions::GroupCollection->new($groupList, $this->{_names});
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
      _value => defined($value) ? $value : (""),
      _index => defined($index) ? $index : (-1),
      _length => defined($length) ? $length : (0),
      _success => defined($success) ? $success : (false),
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
      _matches => defined($matches) ? $matches : ([]),
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
    my ($class, $groups, $names) = @_;

    my $groupList = defined($groups) ? $groups : [];
    my %byName;
    if (defined($names)) {
      # $names maps name -> 1-based group number (same as positional index).
      for my $name (keys %$names) {
        my $num = $names->{$name};
        $byName{$name} = $groupList->[$num] if defined($groupList->[$num]);
      }
    }

    return bless {
      _groups => $groupList,
      _groupsByName => \%byName,
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
      return defined($this->{_groupsByName}->{$index})
        ? $this->{_groupsByName}->{$index}
        : System::Text::RegularExpressions::Group->new("", -1, 0, false);
    }
  }
  
  # Indexer alias
  sub get_Item { shift->Item(@_); }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;