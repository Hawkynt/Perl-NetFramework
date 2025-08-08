package System::Uri; {
  use base 'System::Object';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  require System::String;
  
  # Uri - provides an object representation of a uniform resource identifier (URI)
  
  # UriKind enumeration
  use constant RelativeOrAbsolute => 0;
  use constant Absolute => 1;
  use constant Relative => 2;
  
  # UriComponents enumeration
  use constant UriScheme => 0x1;
  use constant UriUserInfo => 0x2;
  use constant UriHost => 0x4;
  use constant UriPort => 0x8;
  use constant UriPath => 0x10;
  use constant UriQuery => 0x20;
  use constant UriFragment => 0x40;
  
  sub new {
    my ($class, $uriString, $uriKind) = @_;
    throw(System::ArgumentNullException->new('uriString')) unless defined($uriString);
    
    $uriKind //= RelativeOrAbsolute;
    
    my $this = bless {
      _original_string => $uriString,
      _uri_kind => $uriKind,
      _scheme => undef,
      _user_info => undef,
      _host => undef,
      _port => -1,
      _path => undef,
      _query => undef,
      _fragment => undef,
      _is_absolute => 0,
      _is_file => 0,
      _is_unc => 0,
      _is_loopback => 0,
    }, ref($class) || $class || __PACKAGE__;
    
    $this->_ParseUri($uriString, $uriKind);
    return $this;
  }
  
  # Parse the URI string
  sub _ParseUri {
    my ($this, $uriString, $uriKind) = @_;
    
    # Remove leading/trailing whitespace
    $uriString =~ s/^\s+|\s+$//g;
    
    # Check for absolute URI (contains scheme)
    if ($uriString =~ m{^([a-zA-Z][a-zA-Z0-9+.-]*):}) {
      $this->{_is_absolute} = 1;
      $this->{_scheme} = lc($1);
      
      # Throw error if expecting relative URI
      throw(System::UriFormatException->new('Absolute URI when expecting relative'))
        if $uriKind == Relative;
      
      # Parse absolute URI
      $this->_ParseAbsoluteUri($uriString);
    } else {
      # Relative URI
      throw(System::UriFormatException->new('Relative URI when expecting absolute'))
        if $uriKind == Absolute;
      
      $this->{_is_absolute} = 0;
      $this->_ParseRelativeUri($uriString);
    }
  }
  
  # Parse absolute URI
  sub _ParseAbsoluteUri {
    my ($this, $uriString) = @_;
    
    # Pattern: scheme://[userinfo@]host[:port][/path][?query][#fragment]
    if ($uriString =~ m{^([a-zA-Z][a-zA-Z0-9+.-]*):(?://([^/?#]*))?([^?#]*)(?:\?([^#]*))?(?:#(.*))?$}) {
      $this->{_scheme} = lc($1);
      my $authority = $2;
      $this->{_path} = $3 // '';
      $this->{_query} = $4;
      $this->{_fragment} = $5;
      
      # Parse authority (userinfo@host:port)
      if (defined($authority)) {
        if ($authority eq '' || $authority =~ /^(?:([^@]+)@)?(\[[^\]]+\]|[^:]*?)(?::(\d+))?$/) {
          my ($userinfo, $host, $port) = ($1, $2, $3);
          $this->{_user_info} = $userinfo;
          $host //= '';
          # Remove brackets from IPv6 addresses
          $host =~ s/^\[|\]$//g if $host =~ /^\[.*\]$/;
          $this->{_host} = lc($host);
          if (defined($port) && $port ne '') {
            # Only parse as port if it contains only digits
            if ($port =~ /^\d+$/) {
              $this->{_port} = int($port);
            } else {
              # Not a valid port number, use default
              $this->{_port} = $this->_GetDefaultPort($this->{_scheme});
            }
          } else {
            $this->{_port} = $this->_GetDefaultPort($this->{_scheme});
          }
        } else {
          throw(System::UriFormatException->new('Invalid URI authority format'));
        }
      }
      
      # Set special flags
      $this->{_is_file} = ($this->{_scheme} eq 'file');
      $this->{_is_unc} = ($this->{_is_file} && $this->{_host} && $this->{_host} ne 'localhost');
      $this->{_is_loopback} = ($this->{_host} && ($this->{_host} eq 'localhost' || 
                                                   $this->{_host} eq '127.0.0.1' ||
                                                   $this->{_host} eq '::1'));
      
      # Normalize path
      $this->{_path} = $this->_NormalizePath($this->{_path});
      
    } else {
      throw(System::UriFormatException->new('Invalid URI format'));
    }
  }
  
  # Parse relative URI
  sub _ParseRelativeUri {
    my ($this, $uriString) = @_;
    
    # Pattern: [path][?query][#fragment]
    if ($uriString =~ m{^([^?#]*)(?:\?([^#]*))?(?:#(.*))?$}) {
      $this->{_path} = $this->_NormalizePath($1 // '');
      $this->{_query} = $2;
      $this->{_fragment} = $3;
    } else {
      throw(System::UriFormatException->new('Invalid relative URI format'));
    }
  }
  
  # Get default port for scheme
  sub _GetDefaultPort {
    my ($this, $scheme) = @_;
    
    my %default_ports = (
      'http' => 80,
      'https' => 443,
      'ftp' => 21,
      'ftps' => 990,
      'ssh' => 22,
      'telnet' => 23,
      'smtp' => 25,
      'dns' => 53,
      'pop3' => 110,
      'imap' => 143,
      'ldap' => 389,
      'ldaps' => 636,
    );
    
    return $default_ports{$scheme} // -1;
  }
  
  # Normalize path (remove . and .. components)
  sub _NormalizePath {
    my ($this, $path) = @_;
    return '' unless defined($path);
    
    # Split path into components
    my @components = split('/', $path);
    my @normalized = ();
    
    for my $component (@components) {
      if ($component eq '.' || $component eq '') {
        # Skip current directory references and empty components (except first)
        next unless @normalized == 0 && $component eq '';
      } elsif ($component eq '..') {
        # Parent directory - pop last component if possible
        if (@normalized > 0 && $normalized[-1] ne '..') {
          pop @normalized;
        } elsif (!$this->{_is_absolute}) {
          # For relative paths, keep .. components
          push @normalized, $component;
        }
      } else {
        push @normalized, $component;
      }
    }
    
    # Rejoin components
    my $result = join('/', @normalized);
    
    # Preserve leading slash for absolute paths
    $result = '/' . $result if $path =~ m{^/} && $result !~ m{^/};
    
    return $result;
  }
  
  # Properties
  sub OriginalString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_original_string};
  }
  
  sub AbsoluteUri {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::InvalidOperationException->new('Not an absolute URI')) unless $this->{_is_absolute};
    
    return $this->ToString();
  }
  
  sub Scheme {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_scheme};
  }
  
  sub Host {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_host} // '';
  }
  
  sub Port {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_port};
  }
  
  sub AbsolutePath {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    throw(System::InvalidOperationException->new('Not an absolute URI')) unless $this->{_is_absolute};
    return $this->{_path} // '/';
  }
  
  sub PathAndQuery {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $result = $this->{_path} // '';
    if (defined($this->{_query})) {
      $result .= '?' . $this->{_query};
    }
    return $result;
  }
  
  sub Query {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return defined($this->{_query}) ? '?' . $this->{_query} : '';
  }
  
  sub Fragment {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return defined($this->{_fragment}) ? '#' . $this->{_fragment} : '';
  }
  
  sub UserInfo {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_user_info} // '';
  }
  
  sub Authority {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return '' unless $this->{_is_absolute};
    
    my $result = '';
    $result .= $this->{_user_info} . '@' if $this->{_user_info};
    $result .= $this->{_host} if $this->{_host};
    
    # Include port if not default
    my $default_port = $this->_GetDefaultPort($this->{_scheme});
    if ($this->{_port} != -1 && $this->{_port} != $default_port) {
      $result .= ':' . $this->{_port};
    }
    
    return $result;
  }
  
  sub IsAbsoluteUri {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_is_absolute} ? 1 : 0;
  }
  
  sub IsFile {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_is_file} ? 1 : 0;
  }
  
  sub IsUnc {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_is_unc} ? 1 : 0;
  }
  
  sub IsLoopback {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return $this->{_is_loopback} ? 1 : 0;
  }
  
  sub LocalPath {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if ($this->{_is_file}) {
      my $path = $this->{_path} // '';
      # Convert forward slashes to backslashes on Windows
      if ($^O =~ /win/i) {
        $path =~ s{/}{\\}g;
      }
      return $path;
    }
    
    return $this->{_path} // '';
  }
  
  sub Segments {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $path = $this->{_path} // '';
    return [''] unless $path;
    
    my @segments = split('/', $path);
    
    # Add trailing slashes to all but last segment
    for my $i (0 .. $#segments - 1) {
      $segments[$i] .= '/' if $segments[$i];
    }
    
    return \@segments;
  }
  
  # Methods
  sub ToString {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    if (!$this->{_is_absolute}) {
      return $this->{_original_string};
    }
    
    my $result = $this->{_scheme} . ':';
    
    # Add authority
    if ($this->{_host}) {
      $result .= '//';
      $result .= $this->Authority();
    }
    
    # Add path
    $result .= $this->{_path} // '';
    
    # Add query
    if (defined($this->{_query})) {
      $result .= '?' . $this->{_query};
    }
    
    # Add fragment
    if (defined($this->{_fragment})) {
      $result .= '#' . $this->{_fragment};
    }
    
    return $result;
  }
  
  sub Equals {
    my ($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return 0 unless defined($other) && $other->isa('System::Uri');
    
    return $this->ToString() eq $other->ToString();
  }
  
  sub GetHashCode {
    my ($this) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    return unpack("%32C*", $this->ToString());
  }
  
  sub GetComponents {
    my ($this, $components, $format) = @_;
    throw(System::NullReferenceException->new()) unless defined($this);
    
    my $result = '';
    
    if ($components & UriScheme) {
      $result .= $this->{_scheme} . ':' if $this->{_scheme};
    }
    
    if ($components & UriUserInfo) {
      $result .= $this->{_user_info} . '@' if $this->{_user_info};
    }
    
    if ($components & UriHost) {
      $result .= $this->{_host} if $this->{_host};
    }
    
    if ($components & UriPort) {
      if ($this->{_port} != -1) {
        my $default_port = $this->_GetDefaultPort($this->{_scheme});
        if ($this->{_port} != $default_port) {
          $result .= ':' . $this->{_port};
        }
      }
    }
    
    if ($components & UriPath) {
      $result .= $this->{_path} if $this->{_path};
    }
    
    if ($components & UriQuery) {
      $result .= '?' . $this->{_query} if defined($this->{_query});
    }
    
    if ($components & UriFragment) {
      $result .= '#' . $this->{_fragment} if defined($this->{_fragment});
    }
    
    return $result;
  }
  
  # Static methods
  sub IsWellFormedUriString {
    my ($class, $uriString, $uriKind) = @_;
    return 0 unless defined($uriString);
    
    eval {
      my $uri = System::Uri->new($uriString, $uriKind);
    };
    
    return $@ ? 0 : 1;
  }
  
  sub TryCreate {
    my ($class, $uriString, $uriKind, $resultRef) = @_;
    
    eval {
      my $uri = System::Uri->new($uriString, $uriKind);
      $$resultRef = $uri if defined($resultRef);
    };
    
    if ($@) {
      $$resultRef = undef if defined($resultRef);
      return 0;
    }
    
    return 1;
  }
  
  sub Compare {
    my ($class, $uri1, $uri2, $components, $format, $comparisonType) = @_;
    
    return 0 if !defined($uri1) && !defined($uri2);
    return -1 if !defined($uri1);
    return 1 if !defined($uri2);
    
    my $str1 = $uri1->GetComponents($components, $format);
    my $str2 = $uri2->GetComponents($components, $format);
    
    return $str1 cmp $str2;
  }
  
  sub EscapeDataString {
    my ($class, $stringToEscape) = @_;
    throw(System::ArgumentNullException->new('stringToEscape')) unless defined($stringToEscape);
    
    # Simple percent-encoding for reserved characters
    $stringToEscape =~ s/([^A-Za-z0-9._~-])/sprintf("%%%02X", ord($1))/ge;
    return $stringToEscape;
  }
  
  sub UnescapeDataString {
    my ($class, $stringToUnescape) = @_;
    throw(System::ArgumentNullException->new('stringToUnescape')) unless defined($stringToUnescape);
    
    # Decode percent-encoded characters
    $stringToUnescape =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $stringToUnescape;
  }
  
  BEGIN { CSharp::_ShortenPackageName(__PACKAGE__); }
};

1;