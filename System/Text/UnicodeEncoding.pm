package System::Text::UnicodeEncoding; {
  use base 'System::Text::Encoding';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Text::Encoding;
  
  # Unicode (UTF-16) encoding implementation
  
  sub new {
    my ($class, $bigEndian, $byteOrderMark, $throwOnInvalidBytes) = @_;
    
    my $this = $class->SUPER::new(1200); # UTF-16 code page
    $this->{_isReadOnly} = true;
    $this->{_bigEndian} = $bigEndian // false;
    $this->{_byteOrderMark} = $byteOrderMark // false;
    $this->{_throwOnInvalidBytes} = $throwOnInvalidBytes // false;
    
    return $this;
  }
  
  sub EncodingName {
    my ($this) = @_;
    return $this->{_bigEndian} ? "UTF-16BE" : "UTF-16LE";
  }
  
  sub WebName {
    my ($this) = @_;
    return $this->{_bigEndian} ? "utf-16be" : "utf-16le";
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
    
    # UTF-16 is 2 bytes per character (simplified - not handling surrogates)
    return $count * 2;
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
    throw(System::ArgumentException->new('Invalid byte index/count')) if $byteIndex + ($charCount * 2) > @$bytes;
    
    my $bytesEncoded = 0;
    my $currentByteIndex = $byteIndex;
    
    for my $i ($charIndex..$charIndex+$charCount-1) {
      my $char = $chars->[$i];
      my $codePoint = ord($char);
      
      if ($this->{_bigEndian}) {
        # Big-endian byte order
        $bytes->[$currentByteIndex++] = ($codePoint >> 8) & 0xFF;
        $bytes->[$currentByteIndex++] = $codePoint & 0xFF;
      } else {
        # Little-endian byte order
        $bytes->[$currentByteIndex++] = $codePoint & 0xFF;
        $bytes->[$currentByteIndex++] = ($codePoint >> 8) & 0xFF;
      }
      
      $bytesEncoded += 2;
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
    
    # UTF-16 requires even number of bytes
    if ($count % 2 != 0) {
      if ($this->{_throwOnInvalidBytes}) {
        throw(System::ArgumentException->new('Byte count must be even for UTF-16'));
      }
      $count--; # Truncate to even number
    }
    
    # UTF-16 is 2 bytes per character (simplified)
    return $count / 2;
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
    
    # UTF-16 requires even number of bytes
    if ($byteCount % 2 != 0) {
      if ($this->{_throwOnInvalidBytes}) {
        throw(System::ArgumentException->new('Byte count must be even for UTF-16'));
      }
      $byteCount--; # Truncate to even number
    }
    
    my $charsDecoded = 0;
    my $charCount = $byteCount / 2;
    
    throw(System::ArgumentException->new('Invalid char index/count')) if $charIndex + $charCount > @$chars;
    
    for my $i (0..$charCount-1) {
      my $byte1 = $bytes->[$byteIndex + ($i * 2)];
      my $byte2 = $bytes->[$byteIndex + ($i * 2) + 1];
      
      my $codePoint;
      if ($this->{_bigEndian}) {
        # Big-endian byte order
        $codePoint = ($byte1 << 8) | $byte2;
      } else {
        # Little-endian byte order
        $codePoint = ($byte2 << 8) | $byte1;
      }
      
      $chars->[$charIndex + $i] = chr($codePoint);
      $charsDecoded++;
    }
    
    return $charsDecoded;
  }
  
  sub GetMaxByteCount {
    my ($this, $charCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('charCount')) if $charCount < 0;
    
    # UTF-16 is 2 bytes per character
    return $charCount * 2;
  }
  
  sub GetMaxCharCount {
    my ($this, $byteCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('byteCount')) if $byteCount < 0;
    
    # UTF-16 is 2 bytes per character
    return $byteCount / 2;
  }
  
  # Preamble property (Byte Order Mark)
  sub GetPreamble {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_byteOrderMark}) {
      require System::Array;
      if ($this->{_bigEndian}) {
        return System::Array->new(0xFE, 0xFF); # Big-endian BOM
      } else {
        return System::Array->new(0xFF, 0xFE); # Little-endian BOM
      }
    } else {
      require System::Array;
      return System::Array->new(); # Empty array
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;