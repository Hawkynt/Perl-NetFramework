#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Add parent directory to lib path
use FindBin qw($RealBin);
use lib "$RealBin/../../..";

require System::String;

# Test plan: comprehensive tests for new String methods
plan tests => 26;

# Test 1-8: PadLeft
{
  my $str = System::String->new('Hello');
  
  # Basic left padding with default space
  my $padded = $str->PadLeft(10);
  is("$padded", '     Hello', 'PadLeft with default space character');
  
  # Custom padding character
  my $padded_star = $str->PadLeft(10, '*');
  is("$padded_star", '*****Hello', 'PadLeft with custom character');
  
  # Padding width less than string length (should return original)
  my $no_pad = $str->PadLeft(3);
  is("$no_pad", 'Hello', 'PadLeft with width less than string length');
  
  # Padding width equal to string length (should return original)
  my $equal_pad = $str->PadLeft(5);
  is("$equal_pad", 'Hello', 'PadLeft with width equal to string length');
  
  # Multi-character padding (should use only first character)
  my $multi_pad = $str->PadLeft(8, 'ABC');
  is("$multi_pad", 'AAAHello', 'PadLeft with multi-character string uses first char only');
  
  # Empty string padding
  my $empty = System::String->new('');
  my $empty_pad = $empty->PadLeft(5);
  is("$empty_pad", '     ', 'PadLeft with empty string');
  
  # Zero width padding
  my $zero_pad = $str->PadLeft(0);
  is("$zero_pad", 'Hello', 'PadLeft with zero width');
  
  # Large padding
  my $large_pad = $str->PadLeft(15, '-');
  is("$large_pad", '----------Hello', 'PadLeft with large width');
}

# Test 9-16: PadRight  
{
  my $str = System::String->new('World');
  
  # Basic right padding with default space
  my $padded = $str->PadRight(10);
  is("$padded", 'World     ', 'PadRight with default space character');
  
  # Custom padding character
  my $padded_star = $str->PadRight(10, '*');
  is("$padded_star", 'World*****', 'PadRight with custom character');
  
  # Padding width less than string length (should return original)
  my $no_pad = $str->PadRight(3);
  is("$no_pad", 'World', 'PadRight with width less than string length');
  
  # Padding width equal to string length (should return original)
  my $equal_pad = $str->PadRight(5);
  is("$equal_pad", 'World', 'PadRight with width equal to string length');
  
  # Multi-character padding (should use only first character)
  my $multi_pad = $str->PadRight(8, 'XYZ');
  is("$multi_pad", 'WorldXXX', 'PadRight with multi-character string uses first char only');
  
  # Empty string padding
  my $empty = System::String->new('');
  my $empty_pad = $empty->PadRight(5);
  is("$empty_pad", '     ', 'PadRight with empty string');
  
  # Zero width padding
  my $zero_pad = $str->PadRight(0);
  is("$zero_pad", 'World', 'PadRight with zero width');
  
  # Large padding
  my $large_pad = $str->PadRight(15, '+');
  is("$large_pad", 'World++++++++++', 'PadRight with large width');
}

# Test 17-25: Remove
{
  my $str = System::String->new('Hello World!');
  
  # Remove from index to end
  my $removed1 = $str->Remove(5);
  is("$removed1", 'Hello', 'Remove from index to end');
  
  # Remove specific count from index
  my $removed2 = $str->Remove(6, 5);
  is("$removed2", 'Hello !', 'Remove specific count from index');
  
  # Remove from beginning
  my $removed3 = $str->Remove(0, 6);
  is("$removed3", 'World!', 'Remove from beginning');
  
  # Remove from end
  my $removed4 = $str->Remove(11, 1);
  is("$removed4", 'Hello World', 'Remove from end');
  
  # Remove middle portion
  my $removed5 = $str->Remove(5, 1);
  is("$removed5", 'HelloWorld!', 'Remove middle portion');
  
  # Remove zero characters
  my $removed6 = $str->Remove(5, 0);
  is("$removed6", 'Hello World!', 'Remove zero characters (no change)');
  
  # ArgumentOutOfRangeException tests
  eval { $str->Remove(-1); };
  ok($@, 'Remove with negative index throws exception');
  
  eval { $str->Remove(15); };
  ok($@, 'Remove with index beyond string throws exception');
  
  eval { $str->Remove(5, -1); };
  ok($@, 'Remove with negative count throws exception');
  
  eval { $str->Remove(5, 10); };
  ok($@, 'Remove with count beyond string throws exception');
}

done_testing();