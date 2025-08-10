#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../..";

require System::Uri;

# Test plan: comprehensive tests for Uri
plan tests => 65;

# Test 1-5: Constructor and basic properties
{
  my $uri = System::Uri->new('https://www.example.com');
  ok(defined($uri), 'Uri constructor with absolute URI');
  ok($uri->IsAbsoluteUri(), 'IsAbsoluteUri returns true for absolute URI');
  is($uri->Scheme(), 'https', 'Scheme parsed correctly');
  is($uri->Host(), 'www.example.com', 'Host parsed correctly');
  is($uri->Port(), 443, 'Default HTTPS port set correctly');
}

# Test 6-10: Absolute URI components
{
  my $uri = System::Uri->new('http://user:pass@example.com:8080/path/to/resource?query=value&foo=bar#section');
  
  is($uri->Scheme(), 'http', 'Complex URI scheme');
  is($uri->UserInfo(), 'user:pass', 'UserInfo parsed correctly');
  is($uri->Host(), 'example.com', 'Complex URI host');
  is($uri->Port(), 8080, 'Custom port parsed correctly');
  is($uri->AbsolutePath(), '/path/to/resource', 'Path parsed correctly');
}

# Test 11-15: Query and fragment
{
  my $uri = System::Uri->new('https://example.com/path?query=value&foo=bar#section');
  
  is($uri->Query(), '?query=value&foo=bar', 'Query parsed correctly');
  is($uri->Fragment(), '#section', 'Fragment parsed correctly');
  is($uri->PathAndQuery(), '/path?query=value&foo=bar', 'PathAndQuery combined correctly');
  
  my $noQueryUri = System::Uri->new('https://example.com/path');
  is($noQueryUri->Query(), '', 'Empty query when none present');
  is($noQueryUri->Fragment(), '', 'Empty fragment when none present');
}

# Test 16-20: Relative URIs
{
  my $relativeUri = System::Uri->new('path/to/resource?query=value#fragment', 2);  # Relative
  
  ok(!$relativeUri->IsAbsoluteUri(), 'Relative URI is not absolute');
  ok(!defined($relativeUri->Scheme()), 'Relative URI has no scheme');
  is($relativeUri->PathAndQuery(), 'path/to/resource?query=value', 'Relative URI path and query');
  is($relativeUri->Fragment(), '#fragment', 'Relative URI fragment');
  is($relativeUri->OriginalString(), 'path/to/resource?query=value#fragment', 'Original string preserved');
}

# Test 21-25: Special schemes and ports
{
  my $httpUri = System::Uri->new('http://example.com');
  is($httpUri->Port(), 80, 'HTTP default port');
  
  my $httpsUri = System::Uri->new('https://example.com');
  is($httpsUri->Port(), 443, 'HTTPS default port');
  
  my $ftpUri = System::Uri->new('ftp://example.com');
  is($ftpUri->Port(), 21, 'FTP default port');
  
  my $customUri = System::Uri->new('custom://example.com');
  is($customUri->Port(), -1, 'Unknown scheme has no default port');
  is($customUri->Scheme(), 'custom', 'Custom scheme parsed');
}

# Test 26-30: File URIs
{
  my $fileUri = System::Uri->new('file:///C:/path/to/file.txt');
  
  ok($fileUri->IsFile(), 'File URI detected');
  is($fileUri->Scheme(), 'file', 'File scheme');
  ok(!$fileUri->IsUnc(), 'Local file is not UNC');
  
  my $uncUri = System::Uri->new('file://server/share/file.txt');
  ok($uncUri->IsFile(), 'UNC file URI is file');
  ok($uncUri->IsUnc(), 'UNC file URI detected');
}

# Test 31-35: Loopback detection
{
  my $localhostUri = System::Uri->new('http://localhost/');
  ok($localhostUri->IsLoopback(), 'localhost is loopback');
  
  my $ipv4Uri = System::Uri->new('http://127.0.0.1/');
  ok($ipv4Uri->IsLoopback(), '127.0.0.1 is loopback');
  
  my $ipv6Uri = System::Uri->new('http://[::1]/');
  ok($ipv6Uri->IsLoopback(), '::1 is loopback');
  
  my $externalUri = System::Uri->new('http://example.com/');
  ok(!$externalUri->IsLoopback(), 'external host is not loopback');
  
  my $noHostUri = System::Uri->new('mailto:test@example.com');
  ok(!$noHostUri->IsLoopback(), 'URI without host is not loopback');
}

# Test 36-40: Authority and components
{
  my $uri = System::Uri->new('https://user@example.com:8443/path');
  
  is($uri->Authority(), 'user@example.com:8443', 'Authority with user and non-default port');
  
  my $defaultPortUri = System::Uri->new('https://example.com/path');
  is($defaultPortUri->Authority(), 'example.com', 'Authority excludes default port');
  
  my $noUserUri = System::Uri->new('https://example.com:9000/path');
  is($noUserUri->Authority(), 'example.com:9000', 'Authority without user info');
  
  my $components = $uri->GetComponents(0x4 | 0x8, 0);  # Host | Port
  is($components, 'example.com:8443', 'GetComponents for host and port');
  
  my $pathComponents = $uri->GetComponents(0x10 | 0x20, 0);  # Path | Query
  is($pathComponents, '/path', 'GetComponents for path');
}

# Test 41-45: Path normalization
{
  my $dotUri = System::Uri->new('http://example.com/path/./to/../resource');
  is($dotUri->AbsolutePath(), '/path/resource', 'Path normalization removes . and ..');
  
  my $doubleDotUri = System::Uri->new('http://example.com/a/b/../../c');
  is($doubleDotUri->AbsolutePath(), '/c', 'Multiple .. components handled');
  
  my $relativeDotUri = System::Uri->new('path/./to/../resource', 2);
  is($relativeDotUri->PathAndQuery(), 'path/resource', 'Relative path normalization');
  
  my $relativeDoubleDotUri = System::Uri->new('../path/to/resource', 2);
  is($relativeDoubleDotUri->PathAndQuery(), '../path/to/resource', 'Relative .. preserved');
  
  my $rootUri = System::Uri->new('http://example.com/../test');
  is($rootUri->AbsolutePath(), '/test', 'Root level .. handling');
}

# Test 46-50: ToString and Equals
{
  my $uri1 = System::Uri->new('https://example.com/path?query=value#fragment');
  my $reconstructed = $uri1->ToString();
  is($reconstructed, 'https://example.com/path?query=value#fragment', 'ToString reconstructs URI');
  
  my $uri2 = System::Uri->new($reconstructed);
  ok($uri1->Equals($uri2), 'Equal URIs compare equal');
  
  my $differentUri = System::Uri->new('https://example.com/different');
  ok(!$uri1->Equals($differentUri), 'Different URIs compare unequal');
  
  my $relativeUri = System::Uri->new('path/to/resource', 2);
  is($relativeUri->ToString(), 'path/to/resource', 'Relative URI ToString');
  
  my $hash1 = $uri1->GetHashCode();
  my $hash2 = $uri2->GetHashCode();
  is($hash1, $hash2, 'Equal URIs have same hash code');
}

# Test 51-55: Static methods
{
  ok(System::Uri->IsWellFormedUriString('https://example.com', 1), 
     'IsWellFormedUriString - valid absolute URI');
  
  ok(!System::Uri->IsWellFormedUriString('not a uri', 1),
     'IsWellFormedUriString - invalid URI');
  
  my $result;
  my $success = System::Uri->TryCreate('https://example.com', 1, \$result);
  ok($success, 'TryCreate succeeds for valid URI');
  ok(defined($result) && $result->isa('System::Uri'), 'TryCreate returns Uri object');
  
  $success = System::Uri->TryCreate('invalid uri', 1, \$result);
  ok(!$success, 'TryCreate fails for invalid URI');
}

# Test 56-60: Error conditions
{
  # Test invalid URI formats
  eval { System::Uri->new('not a uri', 1); };
  ok($@, 'Invalid absolute URI throws exception');
  ok($@ =~ /format/i, 'Exception mentions format');
  
  # Test wrong kind expectations  
  eval { System::Uri->new('https://example.com', 2); };
  ok($@, 'Absolute URI with Relative kind throws');
  
  eval { System::Uri->new('relative/path', 1); };
  ok($@, 'Relative URI with Absolute kind throws');
  
  # Test null argument
  eval { System::Uri->new(undef); };
  ok($@, 'Null URI string throws ArgumentNullException');
}

# Test 61-65: Escape and unescape
{
  my $original = 'hello world!@#$%^&*()';
  my $escaped = System::Uri->EscapeDataString($original);
  ok($escaped ne $original, 'EscapeDataString changes string');
  ok($escaped =~ /%/, 'EscapeDataString contains percent encoding');
  
  my $unescaped = System::Uri->UnescapeDataString($escaped);
  is($unescaped, $original, 'UnescapeDataString reverses escaping');
  
  my $simpleString = 'HelloWorld123';
  my $simpleEscaped = System::Uri->EscapeDataString($simpleString);
  is($simpleEscaped, $simpleString, 'Simple string unchanged by escaping');
  
  eval { System::Uri->EscapeDataString(undef); };
  ok($@, 'EscapeDataString throws on null input');
}

done_testing();