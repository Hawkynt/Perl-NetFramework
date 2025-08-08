package System::Text::UTF32Encoding; {
  use base 'System::Text::Encoding';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Text::Encoding;
  
  # UTF-32 encoding implementation
  
  sub new {
    my ($class, $bigEndian, $byteOrderMark, $throwOnInvalidCharacters) = @_;
    
    my $this = $class->SUPER::new(12000); # UTF-32 code page
    $this->{_isReadOnly} = true;
    $this->{_bigEndian} = $bigEndian // false;
    $this->{_byteOrderMark} = $byteOrderMark // false;
    $this->{_throwOnInvalidCharacters} = $throwOnInvalidCharacters // false;
    
    return $this;
  }
  
  sub EncodingName {
    my ($this) = @_;
    return $this->{_bigEndian} ? "UTF-32BE" : "UTF-32LE";
  }
  
  sub WebName {
    my ($this) = @_;
    return $this->{_bigEndian} ? "utf-32be" : "utf-32le";
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
    
    # UTF-32 is 4 bytes per character
    return $count * 4;
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
    throw(System::ArgumentException->new('Invalid byte index/count')) if $byteIndex + ($charCount * 4) > @$bytes;
    
    my $bytesEncoded = 0;
    my $currentByteIndex = $byteIndex;
    
    for my $i ($charIndex..$charIndex+$charCount-1) {
      my $char = $chars->[$i];
      my $codePoint = ord($char);
      
      if ($this->{_bigEndian}) {
        # Big-endian byte order
        $bytes->[$currentByteIndex++] = ($codePoint >> 24) & 0xFF;
        $bytes->[$currentByteIndex++] = ($codePoint >> 16) & 0xFF;
        $bytes->[$currentByteIndex++] = ($codePoint >> 8) & 0xFF;
        $bytes->[$currentByteIndex++] = $codePoint & 0xFF;
      } else {
        # Little-endian byte order
        $bytes->[$currentByteIndex++] = $codePoint & 0xFF;
        $bytes->[$currentByteIndex++] = ($codePoint >> 8) & 0xFF;
        $bytes->[$currentByteIndex++] = ($codePoint >> 16) & 0xFF;
        $bytes->[$currentByteIndex++] = ($codePoint >> 24) & 0xFF;
      }
      
      $bytesEncoded += 4;
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
    
    # UTF-32 requires multiple of 4 bytes
    if ($count % 4 != 0) {
      if ($this->{_throwOnInvalidCharacters}) {
        throw(System::ArgumentException->new('Byte count must be multiple of 4 for UTF-32'));
      }
      $count -= ($count % 4); # Truncate to multiple of 4
    }
    
    # UTF-32 is 4 bytes per character
    return $count / 4;
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
    
    # UTF-32 requires multiple of 4 bytes
    if ($byteCount % 4 != 0) {
      if ($this->{_throwOnInvalidCharacters}) {
        throw(System::ArgumentException->new('Byte count must be multiple of 4 for UTF-32'));
      }
      $byteCount -= ($byteCount % 4); # Truncate to multiple of 4
    }
    
    my $charsDecoded = 0;
    my $charCount = $byteCount / 4;
    
    throw(System::ArgumentException->new('Invalid char index/count')) if $charIndex + $charCount > @$chars;
    
    for my $i (0..$charCount-1) {
      my $byte1 = $bytes->[$byteIndex + ($i * 4)];
      my $byte2 = $bytes->[$byteIndex + ($i * 4) + 1];
      my $byte3 = $bytes->[$byteIndex + ($i * 4) + 2];
      my $byte4 = $bytes->[$byteIndex + ($i * 4) + 3];
      
      my $codePoint;
      if ($this->{_bigEndian}) {
        # Big-endian byte order
        $codePoint = ($byte1 << 24) | ($byte2 << 16) | ($byte3 << 8) | $byte4;
      } else {
        # Little-endian byte order
        $codePoint = ($byte4 << 24) | ($byte3 << 16) | ($byte2 << 8) | $byte1;
      }
      
      # Validate code point range
      if ($codePoint > 0x10FFFF || ($codePoint >= 0xD800 && $codePoint <= 0xDFFF)) {
        if ($this->{_throwOnInvalidCharacters}) {
          throw(System::ArgumentException->new("Invalid Unicode code point: $codePoint"));
        }
        $codePoint = 0xFFFD; # Unicode replacement character
      }
      
      # For simplicity, keep within BMP range
      $chars->[$charIndex + $i] = chr($codePoint & 0xFFFF);
      $charsDecoded++;
    }
    
    return $charsDecoded;
  }
  
  sub GetMaxByteCount {
    my ($this, $charCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('charCount')) if $charCount < 0;
    
    # UTF-32 is 4 bytes per character
    return $charCount * 4;
  }
  
  sub GetMaxCharCount {
    my ($this, $byteCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('byteCount')) if $byteCount < 0;
    
    # UTF-32 is 4 bytes per character
    return $byteCount / 4;
  }
  
  # Preamble property (Byte Order Mark)
  sub GetPreamble {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_byteOrderMark}) {
      require System::Array;
      if ($this->{_bigEndian}) {
        return System::Array->new(0x00, 0x00, 0xFE, 0xFF); # Big-endian BOM
      } else {
        return System::Array->new(0xFF, 0xFE, 0x00, 0x00); # Little-endian BOM
      }
    } else {
      require System::Array;
      return System::Array->new(); # Empty array
    }
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;