package System::Text::ASCIIEncoding; {
  use base 'System::Text::Encoding';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Text::Encoding;
  
  # ASCII encoding implementation (7-bit)
  
  sub new {
    my ($class) = @_;
    
    my $this = $class->SUPER::new(20127); # ASCII code page
    $this->{_isReadOnly} = true;
    
    return $this;
  }
  
  sub EncodingName {
    my ($this) = @_;
    return "US-ASCII";
  }
  
  sub WebName {
    my ($this) = @_;
    return "us-ascii";
  }
  
  sub GetByteCount {
    my ($this, $chars, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('chars')) unless defined($chars);
    
    $index //= 0;
    $count //= @$chars - $index;
    
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid index/count')) if $index + $count > @$chars;
    
    # ASCII is 1 byte per character
    return $count;
  }
  
  sub GetBytes {
    my ($this, $chars, $charIndex, $charCount, $bytes, $byteIndex) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('chars')) unless defined($chars);
    throw(System::ArgumentNullException->new('bytes')) unless defined($bytes);
    
    $charIndex //= 0;
    $charCount //= @$chars - $charIndex;
    $byteIndex //= 0;
    
    throw(System::ArgumentOutOfRangeException->new('charIndex')) if $charIndex < 0;
    throw(System::ArgumentOutOfRangeException->new('charCount')) if $charCount < 0;
    throw(System::ArgumentOutOfRangeException->new('byteIndex')) if $byteIndex < 0;
    throw(System::ArgumentException->new('Invalid char index/count')) if $charIndex + $charCount > @$chars;
    throw(System::ArgumentException->new('Invalid byte index/count')) if $byteIndex + $charCount > @$bytes;
    
    my $bytesEncoded = 0;
    
    for my $i (0..$charCount-1) {
      my $char = $chars->[$charIndex + $i];
      my $codePoint = ord($char);
      
      if ($codePoint <= 127) {
        # Valid ASCII character
        $bytes->[$byteIndex + $i] = $codePoint;
      } else {
        # Non-ASCII character - use replacement character (?)
        $bytes->[$byteIndex + $i] = ord('?');
      }
      
      $bytesEncoded++;
    }
    
    return $bytesEncoded;
  }
  
  sub GetCharCount {
    my ($this, $bytes, $index, $count) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('bytes')) unless defined($bytes);
    
    $index //= 0;
    $count //= @$bytes - $index;
    
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0;
    throw(System::ArgumentOutOfRangeException->new('count')) if $count < 0;
    throw(System::ArgumentException->new('Invalid index/count')) if $index + $count > @$bytes;
    
    # ASCII is 1 character per byte
    return $count;
  }
  
  sub GetChars {
    my ($this, $bytes, $byteIndex, $byteCount, $chars, $charIndex) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentNullException->new('bytes')) unless defined($bytes);
    throw(System::ArgumentNullException->new('chars')) unless defined($chars);
    
    $byteIndex //= 0;
    $byteCount //= @$bytes - $byteIndex;
    $charIndex //= 0;
    
    throw(System::ArgumentOutOfRangeException->new('byteIndex')) if $byteIndex < 0;
    throw(System::ArgumentOutOfRangeException->new('byteCount')) if $byteCount < 0;
    throw(System::ArgumentOutOfRangeException->new('charIndex')) if $charIndex < 0;
    throw(System::ArgumentException->new('Invalid byte index/count')) if $byteIndex + $byteCount > @$bytes;
    throw(System::ArgumentException->new('Invalid char index/count')) if $charIndex + $byteCount > @$chars;
    
    my $charsDecoded = 0;
    
    for my $i (0..$byteCount-1) {
      my $byte = $bytes->[$byteIndex + $i];
      
      if ($byte <= 127) {
        # Valid ASCII byte
        $chars->[$charIndex + $i] = chr($byte);
      } else {
        # Invalid ASCII byte - use replacement character
        $chars->[$charIndex + $i] = '?';
      }
      
      $charsDecoded++;
    }
    
    return $charsDecoded;
  }
  
  sub GetMaxByteCount {
    my ($this, $charCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('charCount')) if $charCount < 0;
    
    # ASCII is always 1 byte per character
    return $charCount;
  }
  
  sub GetMaxCharCount {
    my ($this, $byteCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('byteCount')) if $byteCount < 0;
    
    # ASCII is always 1 character per byte
    return $byteCount;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;