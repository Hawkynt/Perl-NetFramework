package System::Guid; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::String;
  
  # Guid - globally unique identifier implementation
  
  # Static empty Guid instance
  my $_empty;
  
  sub new {
    my ($class, @args) = @_;
    
    my $this = bless {
      _bytes => undef,
      _string => undef,
    }, ref($class) || $class || __PACKAGE__;
    
    if (@args == 0) {
      # Default constructor - creates Empty guid
      $this->{_bytes} = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    } elsif (@args == 1) {
      my $arg = $args[0];
      if (ref($arg) eq 'ARRAY') {
        # From byte array
        throw(System::ArgumentException->new('bytes must be 16 bytes long'))
          unless @$arg == 16;
        $this->{_bytes} = [@$arg];
      } elsif (defined($arg) && !ref($arg)) {
        # From string
        $this->_ParseFromString($arg);
      } else {
        throw(System::ArgumentException->new('Invalid argument to Guid constructor'));
      }
    } elsif (@args == 11) {
      # From 11 separate values (int, short, short, byte * 8)
      my ($a, $b, $c, $d, $e, $f, $g, $h, $i, $j, $k) = @args;
      
      # Convert to bytes (little-endian for first 3 parts)
      $this->{_bytes} = [
        $a & 0xFF, ($a >> 8) & 0xFF, ($a >> 16) & 0xFF, ($a >> 24) & 0xFF,
        $b & 0xFF, ($b >> 8) & 0xFF,
        $c & 0xFF, ($c >> 8) & 0xFF,
        $d, $e, $f, $g, $h, $i, $j, $k
      ];
    } else {
      throw(System::ArgumentException->new('Invalid number of arguments to Guid constructor'));
    }
    
    return $this;
  }
  
  # Properties
  sub Empty {
    my ($class) = @_;
    $_empty //= System::Guid->new();
    return $_empty;
  }
  
  # Methods
  sub ToString {
    my ($this, $format) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    $format //= 'D';
    
    my $bytes = $this->{_bytes};
    
    # Convert bytes to hex string based on standard GUID byte layout
    # Bytes 0-3: Data1 (32-bit, little-endian)
    # Bytes 4-5: Data2 (16-bit, little-endian) 
    # Bytes 6-7: Data3 (16-bit, little-endian)
    # Bytes 8-15: Data4 (8 bytes, big-endian)
    
    my $hex_string = sprintf(
      '%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x',
      $bytes->[3], $bytes->[2], $bytes->[1], $bytes->[0],  # Data1 (reversed)
      $bytes->[5], $bytes->[4],                            # Data2 (reversed)
      $bytes->[7], $bytes->[6],                            # Data3 (reversed)  
      $bytes->[8], $bytes->[9],                            # Data4[0-1]
      $bytes->[10], $bytes->[11], $bytes->[12], $bytes->[13], $bytes->[14], $bytes->[15] # Data4[2-7]
    );
    
    if ($format eq 'D' || $format eq 'd') {
      # Default format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
      return uc($hex_string);
    } elsif ($format eq 'N' || $format eq 'n') {
      # No hyphens: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
      $hex_string =~ s/-//g;
      return uc($hex_string);
    } elsif ($format eq 'B' || $format eq 'b') {
      # Braces: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
      return '{' . uc($hex_string) . '}';
    } elsif ($format eq 'P' || $format eq 'p') {
      # Parentheses: (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
      return '(' . uc($hex_string) . ')';
    } elsif ($format eq 'X' || $format eq 'x') {
      # Array format: {0x00000000,0x0000,0x0000,{0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00}}
      my $data1 = sprintf('0x%02X%02X%02X%02X', $bytes->[3], $bytes->[2], $bytes->[1], $bytes->[0]);
      my $data2 = sprintf('0x%02X%02X', $bytes->[5], $bytes->[4]);
      my $data3 = sprintf('0x%02X%02X', $bytes->[7], $bytes->[6]);
      my $data4 = join(',', map { sprintf('0x%02X', $_) } @{$bytes}[8..15]);
      return "{$data1,$data2,$data3,{$data4}}";
    } else {
      throw(System::FormatException->new("Invalid Guid format: $format"));
    }
  }
  
  sub ToByteArray {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return [@{$this->{_bytes}}];  # Return copy
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return false unless defined($other) && $other->isa('System::Guid');
    
    my $thisBytes = $this->{_bytes};
    my $otherBytes = $other->{_bytes};
    
    for my $i (0..15) {
      return false if $thisBytes->[$i] != $otherBytes->[$i];
    }
    
    return true;
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $bytes = $this->{_bytes};
    # Use first 4 bytes as hash
    return ($bytes->[0] << 24) | ($bytes->[1] << 16) | ($bytes->[2] << 8) | $bytes->[3];
  }
  
  sub CompareTo {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    return 1 unless defined($other);
    throw(System::ArgumentException->new('other must be a Guid'))
      unless $other->isa('System::Guid');
    
    my $thisBytes = $this->{_bytes};
    my $otherBytes = $other->{_bytes};
    
    for my $i (0..15) {
      my $cmp = $thisBytes->[$i] <=> $otherBytes->[$i];
      return $cmp if $cmp != 0;
    }
    
    return 0;
  }
  
  # Static methods
  sub NewGuid {
    my ($class) = @_;
    
    # Generate random bytes
    my @bytes;
    for (0..15) {
      push @bytes, int(rand(256));
    }
    
    # Set version bits (version 4 - random)
    $bytes[7] = ($bytes[7] & 0x0F) | 0x40;
    
    # Set variant bits (RFC 4122)
    $bytes[8] = ($bytes[8] & 0x3F) | 0x80;
    
    return System::Guid->new(\@bytes);
  }
  
  sub Parse {
    my ($class, $input) = @_;
    throw(System::ArgumentNullException->new('input')) unless defined($input);
    
    my $guid = System::Guid->new();
    $guid->_ParseFromString($input);
    return $guid;
  }
  
  sub TryParse {
    my ($class, $input, $resultRef) = @_;
    
    eval {
      my $result = $class->Parse($input);
      $$resultRef = $result if defined($resultRef);
      return true;
    };
    
    if ($@) {
      $$resultRef = undef if defined($resultRef);
      return false;
    }
    
    return true;
  }
  
  sub ParseExact {
    my ($class, $input, $format) = @_;
    throw(System::ArgumentNullException->new('input')) unless defined($input);
    throw(System::ArgumentNullException->new('format')) unless defined($format);
    
    # Validate format
    throw(System::FormatException->new('Invalid format specifier')) 
      unless $format =~ /^[DdNnBbPpXx]$/;
    
    # Parse the guid
    my $guid = $class->Parse($input);
    
    # Validate that input matches the expected format
    my $expected = $guid->ToString($format);
    throw(System::FormatException->new('Input string does not match expected format'))
      unless uc($input) eq uc($expected);
    
    return $guid;
  }
  
  sub TryParseExact {
    my ($class, $input, $format, $resultRef) = @_;
    
    eval {
      my $result = $class->ParseExact($input, $format);
      $$resultRef = $result if defined($resultRef);
      return true;
    };
    
    if ($@) {
      $$resultRef = undef if defined($resultRef);
      return false;
    }
    
    return true;
  }
  
  # Internal helper methods
  sub _ParseFromString {
    my ($this, $input) = @_;
    
    # Remove braces, parentheses, and hyphens for parsing
    my $cleaned = $input;
    $cleaned =~ s/[{}()-]//g;
    
    # Should have exactly 32 hex characters
    unless ($cleaned =~ /^[0-9a-fA-F]{32}$/) {
      throw(System::FormatException->new("Input string was not in a correct format"));
    }
    
    # Parse hex string to create standard GUID byte layout
    # Input format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    # Split into: Data1(8) Data2(4) Data3(4) Data4(16)
    
    my $data1 = substr($cleaned, 0, 8);   # First 8 hex chars
    my $data2 = substr($cleaned, 8, 4);   # Next 4 hex chars  
    my $data3 = substr($cleaned, 12, 4);  # Next 4 hex chars
    my $data4 = substr($cleaned, 16, 16); # Last 16 hex chars
    
    # Convert to bytes with proper endianness
    my @bytes = (
      # Data1 - 32-bit little-endian
      hex(substr($data1, 6, 2)), hex(substr($data1, 4, 2)), 
      hex(substr($data1, 2, 2)), hex(substr($data1, 0, 2)),
      # Data2 - 16-bit little-endian  
      hex(substr($data2, 2, 2)), hex(substr($data2, 0, 2)),
      # Data3 - 16-bit little-endian
      hex(substr($data3, 2, 2)), hex(substr($data3, 0, 2)),
      # Data4 - 8 bytes big-endian
      hex(substr($data4, 0, 2)), hex(substr($data4, 2, 2)),
      hex(substr($data4, 4, 2)), hex(substr($data4, 6, 2)),
      hex(substr($data4, 8, 2)), hex(substr($data4, 10, 2)),
      hex(substr($data4, 12, 2)), hex(substr($data4, 14, 2))
    );
    
    $this->{_bytes} = \@bytes;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;