package System::Convert; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::String;
  require System::Globalization::CultureInfo;
  
  # Convert - provides type conversion functionality
  
  # Static methods only - this class cannot be instantiated
  sub new {
    throw(System::InvalidOperationException->new('Convert class cannot be instantiated'));
  }

  # Boolean conversions
  sub ToBoolean {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      # Scalar value
      if ($value =~ /^(true|false)$/i) {
        return lc($value) eq 'true' ? 1 : 0;
      } elsif ($value =~ /^[+-]?\d*\.?\d*$/) {
        return $value != 0 ? 1 : 0;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Boolean"));
  }

  # Byte conversions  
  sub ToByte {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        throw(System::OverflowException->new("Value was either too large or too small for a Byte"))
          if $num < 0 || $num > 255;
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Byte"));
  }

  # SByte conversions
  sub ToSByte {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        throw(System::OverflowException->new("Value was either too large or too small for a SByte"))
          if $num < -128 || $num > 127;
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to SByte"));
  }

  # Int16 conversions
  sub ToInt16 {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        throw(System::OverflowException->new("Value was either too large or too small for a Int16"))
          if $num < -32768 || $num > 32767;
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Int16"));
  }

  # UInt16 conversions
  sub ToUInt16 {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        throw(System::OverflowException->new("Value was either too large or too small for a UInt16"))
          if $num < 0 || $num > 65535;
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to UInt16"));
  }

  # Int32 conversions
  sub ToInt32 {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        throw(System::OverflowException->new("Value was either too large or too small for a Int32"))
          if $num < -2147483648 || $num > 2147483647;
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Int32"));
  }

  # UInt32 conversions
  sub ToUInt32 {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        throw(System::OverflowException->new("Value was either too large or too small for a UInt32"))
          if $num < 0 || $num > 4294967295;
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to UInt32"));
  }

  # Int64 conversions
  sub ToInt64 {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        # For 64-bit, we'll use Perl's native integer handling
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Int64"));
  }

  # UInt64 conversions
  sub ToUInt64 {
    my ($class, $value, $provider) = @_;
    
    return 0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        my $num = int($value);
        throw(System::OverflowException->new("Value was either too large or too small for a UInt64"))
          if $num < 0;
        return $num;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to UInt64"));
  }

  # Single conversions
  sub ToSingle {
    my ($class, $value, $provider) = @_;
    
    return 0.0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*([eE][+-]?\d+)?$/) {
        return 0.0 + $value;  # Numeric conversion
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Single"));
  }

  # Double conversions
  sub ToDouble {
    my ($class, $value, $provider) = @_;
    
    return 0.0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*([eE][+-]?\d+)?$/) {
        return 0.0 + $value;  # Numeric conversion
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Double"));
  }

  # Decimal conversions
  sub ToDecimal {
    my ($class, $value, $provider) = @_;
    
    return 0.0 unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      if ($value =~ /^[+-]?\d*\.?\d*$/) {
        return 0.0 + $value;  # Numeric conversion
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Decimal"));
  }

  # DateTime conversions
  sub ToDateTime {
    my ($class, $value, $provider) = @_;
    
    throw(System::ArgumentNullException->new('value')) unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      $value = "$value";  # String overload
    }
    
    if (!ref($value)) {
      # Try to parse as DateTime string
      require System::DateTime;
      return System::DateTime->Parse($value);
    }
    
    throw(System::FormatException->new("Unable to cast object to DateTime"));
  }

  # String conversions
  sub ToString {
    my ($class, $value, $provider) = @_;
    
    return System::String->new('') unless defined($value);
    
    if (ref($value) && $value->can('ToString')) {
      return System::String->new($value->ToString());
    }
    
    return System::String->new("$value");
  }

  # Char conversions
  sub ToChar {
    my ($class, $value, $provider) = @_;
    
    throw(System::ArgumentNullException->new('value')) unless defined($value);
    
    if (ref($value) && $value->isa('System::String')) {
      my $str = "$value";
      throw(System::FormatException->new("String must be exactly one character long"))
        unless length($str) == 1;
      return substr($str, 0, 1);
    }
    
    if (!ref($value)) {
      if ($value =~ /^\d+$/) {
        # Convert from numeric value to character
        return chr($value);
      } elsif (length($value) == 1) {
        return $value;
      }
    }
    
    throw(System::FormatException->new("Unable to cast object to Char"));
  }

  # Base conversion methods
  sub ToBase64String {
    my ($class, $inArray, $offset, $length) = @_;
    throw(System::ArgumentNullException->new('inArray')) unless defined($inArray);
    
    $offset //= 0;
    $length //= @$inArray - $offset if ref($inArray) eq 'ARRAY';
    
    throw(System::ArgumentOutOfRangeException->new('offset')) if $offset < 0;
    throw(System::ArgumentOutOfRangeException->new('length')) if $length < 0;
    
    my @bytes;
    if (ref($inArray) eq 'ARRAY') {
      @bytes = @{$inArray}[$offset .. ($offset + $length - 1)];
    } else {
      throw(System::ArgumentException->new('inArray must be byte array'));
    }
    
    # Simple base64 encoding
    require MIME::Base64;
    my $data = pack('C*', @bytes);
    return System::String->new(MIME::Base64::encode_base64($data, ''));
  }
  
  sub FromBase64String {
    my ($class, $s) = @_;
    throw(System::ArgumentNullException->new('s')) unless defined($s);
    
    if (ref($s) && $s->isa('System::String')) {
      $s = "$s";  # String overload
    }
    
    require MIME::Base64;
    my $data = MIME::Base64::decode_base64($s);
    my @bytes = unpack('C*', $data);
    
    return \@bytes;
  }

  # Hexadecimal conversion methods
  sub ToHexString {
    my ($class, $value) = @_;
    
    if (!defined($value)) {
      return System::String->new('');
    }
    
    if (ref($value) eq 'ARRAY') {
      # Array of bytes
      return System::String->new(uc(join('', map { sprintf('%02X', $_) } @$value)));
    } elsif (!ref($value) && $value =~ /^\d+$/) {
      # Numeric value
      return System::String->new(uc(sprintf('%X', $value)));
    }
    
    throw(System::FormatException->new("Unable to convert to hex string"));
  }
  
  sub FromHexString {
    my ($class, $s) = @_;
    throw(System::ArgumentNullException->new('s')) unless defined($s);
    
    if (ref($s) && $s->isa('System::String')) {
      $s = "$s";  # String overload
    }
    
    throw(System::FormatException->new("Invalid hex string"))
      unless $s =~ /^[0-9a-fA-F]*$/;
    
    # Ensure even length
    $s = "0$s" if length($s) % 2;
    
    my @bytes;
    for (my $i = 0; $i < length($s); $i += 2) {
      push @bytes, hex(substr($s, $i, 2));
    }
    
    return \@bytes;
  }

  # Type checking methods
  sub IsDBNull {
    my ($class, $value) = @_;
    # In Perl, we'll consider undef as DBNull
    return !defined($value) ? 1 : 0;
  }
  
  sub GetTypeCode {
    my ($class, $value) = @_;
    
    return 'Empty' unless defined($value);
    
    if (ref($value)) {
      if ($value->isa('System::String')) {
        return 'String';
      } elsif ($value->isa('System::DateTime')) {
        return 'DateTime';
      } elsif ($value->isa('System::Decimal')) {
        return 'Decimal';
      }
      return 'Object';
    } else {
      # Scalar - try to determine type
      if ($value =~ /^[+-]?\d+$/) {
        return 'Int32';  # Default integer type
      } elsif ($value =~ /^[+-]?\d*\.\d*$/) {
        return 'Double';  # Default floating point type
      } elsif ($value =~ /^(true|false)$/i) {
        return 'Boolean';
      } elsif (length($value) == 1) {
        return 'Char';
      }
      return 'String';  # Default for other scalars
    }
  }

  # Change type method
  sub ChangeType {
    my ($class, $value, $conversionType, $provider) = @_;
    throw(System::ArgumentNullException->new('conversionType')) unless defined($conversionType);
    
    return undef unless defined($value);
    
    # Map type names to conversion methods
    my %converters = (
      'Boolean' => sub { $class->ToBoolean($value, $provider) },
      'Byte' => sub { $class->ToByte($value, $provider) },
      'SByte' => sub { $class->ToSByte($value, $provider) },
      'Int16' => sub { $class->ToInt16($value, $provider) },
      'UInt16' => sub { $class->ToUInt16($value, $provider) },
      'Int32' => sub { $class->ToInt32($value, $provider) },
      'UInt32' => sub { $class->ToUInt32($value, $provider) },
      'Int64' => sub { $class->ToInt64($value, $provider) },
      'UInt64' => sub { $class->ToUInt64($value, $provider) },
      'Single' => sub { $class->ToSingle($value, $provider) },
      'Double' => sub { $class->ToDouble($value, $provider) },
      'Decimal' => sub { $class->ToDecimal($value, $provider) },
      'DateTime' => sub { $class->ToDateTime($value, $provider) },
      'String' => sub { $class->ToString($value, $provider) },
      'Char' => sub { $class->ToChar($value, $provider) },
    );
    
    if (exists($converters{$conversionType})) {
      return $converters{$conversionType}->();
    }
    
    throw(System::InvalidCastException->new("Cannot convert to type: $conversionType"));
  }

  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;