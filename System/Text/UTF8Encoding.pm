package System::Text::UTF8Encoding; {
  use base 'System::Text::Encoding';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::Text::Encoding;
  
  # UTF-8 encoding implementation
  
  sub new {
    my ($class, $encoderShouldEmitUTF8Identifier, $throwOnInvalidBytes) = @_;
    
    my $this = $class->SUPER::new(65001); # UTF-8 code page
    $this->{_isReadOnly} = true;
    $this->{_emitUTF8Identifier} = $encoderShouldEmitUTF8Identifier // false;
    $this->{_throwOnInvalidBytes} = $throwOnInvalidBytes // false;
    
    return $this;
  }
  
  sub EncodingName {
    my ($this) = @_;
    return "UTF-8";
  }
  
  sub WebName {
    my ($this) = @_;
    return "utf-8";
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
    
    my $byteCount = 0;
    
    for my $i ($index..$index+$count-1) {
      my $char = $chars->[$i];
      my $codePoint = ord($char);
      
      if ($codePoint <= 0x7F) {
        # 1 byte (ASCII)
        $byteCount += 1;
      } elsif ($codePoint <= 0x7FF) {
        # 2 bytes
        $byteCount += 2;
      } elsif ($codePoint <= 0xFFFF) {
        # 3 bytes
        $byteCount += 3;
      } else {
        # 4 bytes (should not happen with basic Unicode, but for completeness)
        $byteCount += 4;
      }
    }
    
    return $byteCount;
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
    
    my $bytesEncoded = 0;
    my $currentByteIndex = $byteIndex;
    
    for my $i ($charIndex..$charIndex+$charCount-1) {
      my $char = $chars->[$i];
      my $codePoint = ord($char);
      
      if ($codePoint <= 0x7F) {
        # 1 byte (ASCII)
        throw(System::ArgumentException->new('Buffer too small')) if $currentByteIndex >= @$bytes;
        $bytes->[$currentByteIndex++] = $codePoint;
        $bytesEncoded += 1;
      } elsif ($codePoint <= 0x7FF) {
        # 2 bytes
        throw(System::ArgumentException->new('Buffer too small')) if $currentByteIndex + 1 >= @$bytes;
        $bytes->[$currentByteIndex++] = 0xC0 | ($codePoint >> 6);
        $bytes->[$currentByteIndex++] = 0x80 | ($codePoint & 0x3F);
        $bytesEncoded += 2;
      } elsif ($codePoint <= 0xFFFF) {
        # 3 bytes
        throw(System::ArgumentException->new('Buffer too small')) if $currentByteIndex + 2 >= @$bytes;
        $bytes->[$currentByteIndex++] = 0xE0 | ($codePoint >> 12);
        $bytes->[$currentByteIndex++] = 0x80 | (($codePoint >> 6) & 0x3F);
        $bytes->[$currentByteIndex++] = 0x80 | ($codePoint & 0x3F);
        $bytesEncoded += 3;
      } else {
        # 4 bytes (for extended Unicode)
        throw(System::ArgumentException->new('Buffer too small')) if $currentByteIndex + 3 >= @$bytes;
        $bytes->[$currentByteIndex++] = 0xF0 | ($codePoint >> 18);
        $bytes->[$currentByteIndex++] = 0x80 | (($codePoint >> 12) & 0x3F);
        $bytes->[$currentByteIndex++] = 0x80 | (($codePoint >> 6) & 0x3F);
        $bytes->[$currentByteIndex++] = 0x80 | ($codePoint & 0x3F);
        $bytesEncoded += 4;
      }
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
    
    my $charCount = 0;
    my $i = $index;
    
    while ($i < $index + $count) {
      my $byte = $bytes->[$i];
      
      if (($byte & 0x80) == 0) {
        # 1-byte character (ASCII)
        $i += 1;
      } elsif (($byte & 0xE0) == 0xC0) {
        # 2-byte character
        $i += 2;
      } elsif (($byte & 0xF0) == 0xE0) {
        # 3-byte character
        $i += 3;
      } elsif (($byte & 0xF8) == 0xF0) {
        # 4-byte character
        $i += 4;
      } else {
        # Invalid UTF-8 byte
        if ($this->{_throwOnInvalidBytes}) {
          throw(System::ArgumentException->new('Invalid UTF-8 byte sequence'));
        }
        $i += 1; # Skip invalid byte
      }
      
      $charCount++;
    }
    
    return $charCount;
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
    
    my $charsDecoded = 0;
    my $i = $byteIndex;
    my $currentCharIndex = $charIndex;
    
    while ($i < $byteIndex + $byteCount) {
      my $byte = $bytes->[$i];
      my $codePoint;
      
      if (($byte & 0x80) == 0) {
        # 1-byte character (ASCII)
        $codePoint = $byte;
        $i += 1;
      } elsif (($byte & 0xE0) == 0xC0) {
        # 2-byte character
        if ($i + 1 >= $byteIndex + $byteCount) {
          # Incomplete sequence
          $codePoint = ord('?');
          $i += 1;
        } else {
          my $byte2 = $bytes->[$i + 1];
          $codePoint = (($byte & 0x1F) << 6) | ($byte2 & 0x3F);
          $i += 2;
        }
      } elsif (($byte & 0xF0) == 0xE0) {
        # 3-byte character
        if ($i + 2 >= $byteIndex + $byteCount) {
          # Incomplete sequence
          $codePoint = ord('?');
          $i += 1;
        } else {
          my $byte2 = $bytes->[$i + 1];
          my $byte3 = $bytes->[$i + 2];
          $codePoint = (($byte & 0x0F) << 12) | (($byte2 & 0x3F) << 6) | ($byte3 & 0x3F);
          $i += 3;
        }
      } elsif (($byte & 0xF8) == 0xF0) {
        # 4-byte character
        if ($i + 3 >= $byteIndex + $byteCount) {
          # Incomplete sequence
          $codePoint = ord('?');
          $i += 1;
        } else {
          my $byte2 = $bytes->[$i + 1];
          my $byte3 = $bytes->[$i + 2];
          my $byte4 = $bytes->[$i + 3];
          $codePoint = (($byte & 0x07) << 18) | (($byte2 & 0x3F) << 12) | (($byte3 & 0x3F) << 6) | ($byte4 & 0x3F);
          $i += 4;
        }
      } else {
        # Invalid UTF-8 byte
        if ($this->{_throwOnInvalidBytes}) {
          throw(System::ArgumentException->new('Invalid UTF-8 byte sequence'));
        }
        $codePoint = ord('?');
        $i += 1;
      }
      
      throw(System::ArgumentException->new('Char buffer too small')) if $currentCharIndex >= @$chars;
      $chars->[$currentCharIndex++] = chr($codePoint & 0xFFFF); # Keep within Unicode BMP for simplicity
      $charsDecoded++;
    }
    
    return $charsDecoded;
  }
  
  sub GetMaxByteCount {
    my ($this, $charCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('charCount')) if $charCount < 0;
    
    # UTF-8 can use up to 4 bytes per character in worst case
    return $charCount * 4;
  }
  
  sub GetMaxCharCount {
    my ($this, $byteCount) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::ArgumentOutOfRangeException->new('byteCount')) if $byteCount < 0;
    
    # UTF-8 minimum is 1 byte per character, so max chars = byte count
    return $byteCount;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;