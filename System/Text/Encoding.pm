package System::Text::Encoding; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # Abstract base class for character encodings
  
  sub new {
    my ($class, $codePage, $encoderFallback, $decoderFallback) = @_;
    
    return bless {
      _codePage => $codePage // 0,
      _encoderFallback => $encoderFallback,
      _decoderFallback => $decoderFallback,
      _isReadOnly => false,
    }, ref($class) || $class || __PACKAGE__;
  }
  
  # Properties
  sub CodePage {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_codePage};
  }
  
  sub EncodingName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return "Unknown";  # Override in derived classes
  }
  
  sub WebName {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return lc($this->EncodingName());  # Default implementation
  }
  
  sub IsReadOnly {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_isReadOnly};
  }
  
  # Abstract methods - must be implemented by derived classes
  sub GetByteCount {
    my ($this, $chars, $index, $count) = @_;
    throw(System::NotImplementedException->new('GetByteCount must be implemented by derived class'));
  }
  
  sub GetBytes {
    my ($this, $chars, $charIndex, $charCount, $bytes, $byteIndex) = @_;
    throw(System::NotImplementedException->new('GetBytes must be implemented by derived class'));
  }
  
  sub GetCharCount {
    my ($this, $bytes, $index, $count) = @_;
    throw(System::NotImplementedException->new('GetCharCount must be implemented by derived class'));
  }
  
  sub GetChars {
    my ($this, $bytes, $byteIndex, $byteCount, $chars, $charIndex) = @_;
    throw(System::NotImplementedException->new('GetChars must be implemented by derived class'));
  }
  
  sub GetMaxByteCount {
    my ($this, $charCount) = @_;
    throw(System::NotImplementedException->new('GetMaxByteCount must be implemented by derived class'));
  }
  
  sub GetMaxCharCount {
    my ($this, $byteCount) = @_;
    throw(System::NotImplementedException->new('GetMaxCharCount must be implemented by derived class'));
  }
  
  # Convenience methods with default implementations
  sub GetBytesFromString {
    my ($this, $s) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('s')) unless defined($s);
    
    # Convert string to character array
    my @chars = split //, (ref($s) && $s->can('ToString')) ? $s->ToString() : "$s";
    
    # Get byte count
    my $byteCount = $this->GetByteCount(\@chars, 0, scalar(@chars));
    
    # Allocate byte array and encode
    my @bytes = (0) x $byteCount;
    $this->GetBytes(\@chars, 0, scalar(@chars), \@bytes, 0);
    
    require System::Array;
    return System::Array->new(@bytes);
  }
  
  sub GetStringFromBytes {
    my ($this, $bytes, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('bytes')) unless defined($bytes);
    
    $index //= 0;
    $count //= (ref($bytes) eq 'ARRAY' ? @$bytes : $bytes->Length()) - $index;
    
    # Convert System::Array to array if needed
    my @byteArray;
    if (ref($bytes) eq 'ARRAY') {
      @byteArray = @$bytes;
    } else {
      @byteArray = ();
      for my $i (0..$bytes->Length()-1) {
        push @byteArray, $bytes->GetValue($i);
      }
    }
    
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid index/count')) if $index + $count > @byteArray;
    
    # Get character count
    my @relevantBytes = @byteArray[$index..$index+$count-1];
    my $charCount = $this->GetCharCount(\@relevantBytes, 0, $count);
    
    # Allocate character array and decode
    my @chars = ('') x $charCount;
    $this->GetChars(\@relevantBytes, 0, $count, \@chars, 0);
    
    require System::String;
    return System::String->new(join('', @chars));
  }
  
  # Static methods for getting standard encodings
  my $_ascii;
  my $_utf8;
  my $_unicode;
  my $_utf32;
  my $_default;
  
  sub ASCII {
    require System::Text::ASCIIEncoding;
    $_ascii //= System::Text::ASCIIEncoding->new();
    return $_ascii;
  }
  
  sub UTF8 {
    require System::Text::UTF8Encoding;
    $_utf8 //= System::Text::UTF8Encoding->new();
    return $_utf8;
  }
  
  sub Unicode {
    require System::Text::UnicodeEncoding;
    $_unicode //= System::Text::UnicodeEncoding->new();
    return $_unicode;
  }
  
  sub UTF32 {
    require System::Text::UTF32Encoding;
    $_utf32 //= System::Text::UTF32Encoding->new();
    return $_utf32;
  }
  
  sub Default {
    require System::Text::UTF8Encoding;
    $_default //= System::Text::UTF8Encoding->new();  # Default to UTF-8
    return $_default;
  }
  
  # Get encoding by name or code page
  sub GetEncoding {
    my ($class, $nameOrCodePage) = @_;
    throw(System::ArgumentNullException->new('nameOrCodePage')) unless defined($nameOrCodePage);
    
    if ($nameOrCodePage =~ /^\d+$/) {
      # Code page number
      my $codePage = $nameOrCodePage;
      if ($codePage == 65001) { return $class->UTF8(); }
      elsif ($codePage == 1200) { return $class->Unicode(); }
      elsif ($codePage == 12000) { return $class->UTF32(); }
      elsif ($codePage == 20127) { return $class->ASCII(); }
      else {
        throw(System::ArgumentException->new("Code page $codePage not supported"));
      }
    } else {
      # Encoding name
      my $name = lc($nameOrCodePage);
      if ($name eq 'utf-8' || $name eq 'utf8') { return $class->UTF8(); }
      elsif ($name eq 'unicode' || $name eq 'utf-16' || $name eq 'utf16') { return $class->Unicode(); }
      elsif ($name eq 'utf-32' || $name eq 'utf32') { return $class->UTF32(); }
      elsif ($name eq 'ascii' || $name eq 'us-ascii') { return $class->ASCII(); }
      else {
        throw(System::ArgumentException->new("Encoding '$nameOrCodePage' not supported"));
      }
    }
  }
  
  # Equals implementation
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return false unless defined($other);
    return false unless $other->isa('System::Text::Encoding');
    
    return ($this->CodePage() == $other->CodePage());
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->CodePage();
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;