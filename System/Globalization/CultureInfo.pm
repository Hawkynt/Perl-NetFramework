package System::Globalization::CultureInfo; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::String;
  
  # CultureInfo - represents culture-specific information for formatting and parsing
  
  # Static culture instances
  my $_invariantCulture;
  my $_currentCulture;
  my $_currentUICulture;
  
  sub new {
    my ($class, $name) = @_;
    
    # Default to invariant culture if no name provided
    $name //= '';
    
    throw(System::ArgumentException->new('name cannot be null'))
      unless defined($name);
    
    my $this = bless {
      _name => $name,
      _displayName => '',
      _englishName => '',
      _nativeName => '',
      _twoLetterISOLanguageName => '',
      _threeLetterISOLanguageName => '',
      _isNeutral => 0,
      _numberFormat => undef,
      _dateTimeFormat => undef,
    }, ref($class) || $class || __PACKAGE__;
    
    # Initialize culture-specific data
    $this->_InitializeCulture();
    
    return $this;
  }
  
  # Properties
  sub Name {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_name};
  }
  
  sub DisplayName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_displayName};
  }
  
  sub EnglishName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_englishName};
  }
  
  sub NativeName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_nativeName};
  }
  
  sub TwoLetterISOLanguageName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_twoLetterISOLanguageName};
  }
  
  sub ThreeLetterISOLanguageName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_threeLetterISOLanguageName};
  }
  
  sub IsNeutralCulture {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_isNeutral};
  }
  
  sub NumberFormat {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_numberFormat};
  }
  
  # Static properties
  sub InvariantCulture {
    my ($class) = @_;
    $_invariantCulture //= System::Globalization::CultureInfo->new('');
    return $_invariantCulture;
  }
  
  sub CurrentCulture {
    my ($class, $value) = @_;
    
    if (defined($value)) {
      # Setter
      throw(System::ArgumentNullException->new('value')) unless defined($value);
      throw(System::ArgumentException->new('value must be a CultureInfo'))
        unless $value->isa('System::Globalization::CultureInfo');
      $_currentCulture = $value;
      return;
    }
    
    # Getter - return current culture or default to invariant
    $_currentCulture //= System::Globalization::CultureInfo->InvariantCulture();
    return $_currentCulture;
  }
  
  sub CurrentUICulture {
    my ($class, $value) = @_;
    
    if (defined($value)) {
      # Setter
      throw(System::ArgumentNullException->new('value')) unless defined($value);
      throw(System::ArgumentException->new('value must be a CultureInfo'))
        unless $value->isa('System::Globalization::CultureInfo');
      $_currentUICulture = $value;
      return;
    }
    
    # Getter - return current UI culture or default to current culture
    $_currentUICulture //= System::Globalization::CultureInfo->CurrentCulture();
    return $_currentUICulture;
  }
  
  # Culture-specific formatting methods
  sub GetNumberDecimalSeparator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    # Return appropriate decimal separator based on culture
    my $name = $this->{_name};
    
    # European cultures that use comma as decimal separator
    return ',' if $name =~ /^(de|fr|es|it|pt|nl|sv|da|no|fi|pl|cs|sk|hu|ro|bg|hr|sl|et|lv|lt|ru|uk|be)/i;
    
    # Default to period for invariant and English-based cultures
    return '.';
  }
  
  sub GetNumberGroupSeparator {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $name = $this->{_name};
    my $decimalSep = $this->GetNumberDecimalSeparator();
    
    # If decimal separator is comma, use period or space for thousands
    if ($decimalSep eq ',') {
      return ' ' if $name =~ /^(fr|ru|uk|be)/i;  # French and Slavic use space
      return '.';  # Most European use period
    }
    
    # Default comma for English-based cultures
    return ',';
  }
  
  sub GetCurrencySymbol {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $name = $this->{_name};
    
    # Common currency symbols by culture
    return '€' if $name =~ /^(de|fr|es|it|pt|nl|fi|at|be|ie|lu|mt|cy|sk|si|ee|lv|lt)/i;
    return '£' if $name =~ /^en-GB/i;
    return '¥' if $name =~ /^(ja|zh)/i;
    return '₽' if $name =~ /^ru/i;
    return 'kr' if $name =~ /^(sv|da|no)/i;
    return 'zł' if $name =~ /^pl/i;
    
    # Default to dollar
    return '$';
  }
  
  # Methods
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_name} || 'Invariant Language (Invariant Country)';
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return false unless defined($other) && $other->isa('System::Globalization::CultureInfo');
    return $this->{_name} eq $other->{_name};
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return unpack("%32C*", $this->{_name} || '');
  }
  
  # Internal initialization
  sub _InitializeCulture {
    my ($this) = @_;
    
    my $name = $this->{_name};
    
    if ($name eq '' || $name eq 'iv') {
      # Invariant culture
      $this->{_displayName} = 'Invariant Language (Invariant Country)';
      $this->{_englishName} = 'Invariant Language (Invariant Country)';
      $this->{_nativeName} = 'Invariant Language (Invariant Country)';
      $this->{_twoLetterISOLanguageName} = 'iv';
      $this->{_threeLetterISOLanguageName} = 'ivl';
      $this->{_isNeutral} = false;
    }
    elsif ($name =~ /^en(-US)?$/i) {
      # English (United States) - default
      $this->{_displayName} = 'English (United States)';
      $this->{_englishName} = 'English (United States)';
      $this->{_nativeName} = 'English (United States)';
      $this->{_twoLetterISOLanguageName} = 'en';
      $this->{_threeLetterISOLanguageName} = 'eng';
      $this->{_isNeutral} = false;
    }
    elsif ($name =~ /^en-GB$/i) {
      # English (United Kingdom)
      $this->{_displayName} = 'English (United Kingdom)';
      $this->{_englishName} = 'English (United Kingdom)';
      $this->{_nativeName} = 'English (United Kingdom)';
      $this->{_twoLetterISOLanguageName} = 'en';
      $this->{_threeLetterISOLanguageName} = 'eng';
      $this->{_isNeutral} = false;
    }
    elsif ($name =~ /^de(-DE)?$/i) {
      # German (Germany)
      $this->{_displayName} = 'German (Germany)';
      $this->{_englishName} = 'German (Germany)';
      $this->{_nativeName} = 'Deutsch (Deutschland)';
      $this->{_twoLetterISOLanguageName} = 'de';
      $this->{_threeLetterISOLanguageName} = 'deu';
      $this->{_isNeutral} = false;
    }
    elsif ($name =~ /^fr(-FR)?$/i) {
      # French (France)
      $this->{_displayName} = 'French (France)';
      $this->{_englishName} = 'French (France)';
      $this->{_nativeName} = 'Français (France)';
      $this->{_twoLetterISOLanguageName} = 'fr';
      $this->{_threeLetterISOLanguageName} = 'fra';
      $this->{_isNeutral} = false;
    }
    else {
      # Generic/unknown culture
      $this->{_displayName} = $name;
      $this->{_englishName} = $name;
      $this->{_nativeName} = $name;
      
      # Extract language code
      if ($name =~ /^([a-z]{2})/i) {
        $this->{_twoLetterISOLanguageName} = lc($1);
        $this->{_threeLetterISOLanguageName} = lc($1) . 'x';
      } else {
        $this->{_twoLetterISOLanguageName} = 'un';
        $this->{_threeLetterISOLanguageName} = 'unk';
      }
      
      $this->{_isNeutral} = ($name !~ /-/);
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;