package System::Math; {
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;
  
  # Mathematical constants
  use constant E => 2.71828182845904523536;
  use constant PI => 3.14159265358979323846;
  use constant Tau => 6.28318530717958647692; # 2 * PI

  sub Abs($){
    my($value)=@_;
    return(abs($value));
  }
  
  sub Acos($){
    my($value)=@_;
    return(atan2(sqrt(1-$value*$value),$value));
  }
  
  sub Asin($){
    my($value)=@_;
    return(atan2($value, sqrt(1-$value*$value)));
  }
  
  sub Atan($){
    my($value)=@_;
    return(atan2($value,1));
  }
  
  sub Atan2($$){
    my($y,$x)=@_;
    return(atan2($y,$x));
  }
  
  sub Ceiling($){
    my($value)=@_;
    require POSIX;
    return(POSIX::ceil($value));
  }
  
  sub Cos($){
    my($value)=@_;
    return(cos($value));
  }
  
  sub Cosh($){
    my($value)=@_;
    return(0.5*(exp($value)+exp(-$value)));
  }
  
  sub Exp($){
    my($value)=@_;
    return(exp($value));
  }
  
  sub Floor($){
    my($value)=@_;
    require POSIX;
    return(POSIX::floor($value));
  }
  
  sub Log($;$){
    my($value,$base)=@_;
    return(defined($base)?log($value)/log($base):log($value));
  }
  
  sub Log10($){
    my($value)=@_;
    return(log($value)/log(10));
  }
  
  sub Max($$){
    my($a,$b)=@_;
    return($a>$b?$a:$b);
  }
  
  sub Min($$){
    my($a,$b)=@_;
    return($a<$b?$a:$b);
  }
  
  sub Pow($$){
    my($value,$power)=@_;
    return($value**$power);
  }
  
  sub Round($;$){
    my($value,$digits)=@_;
    return(int($value+0.5)) unless defined($digits);
    my $factor=10**$digits;
    return(int($value*$factor+0.5)/$factor);
  }
  
  sub Sign($){
    my($value)=@_;
    return($value<0?-1:$value>0?1:0);
  }
  
  sub Sin($){
    my($value)=@_;
    return(sin($value));
  }
  
  sub Sinh($){
    my($value)=@_;
    return(0.5*(exp($value)-exp(-$value)));
  }
  
  sub Sqrt($){
    my($value)=@_;
    return(sqrt($value));
  }
  
  sub Tan($){
    my($value)=@_;
    return(sin($value)/cos($value));
  }
  
  sub Tanh($){
    my($value)=@_;
    my $a=exp($value);
    my $b=exp(-$value);
    return(($a-$b)/($a+$b));
  }
  
  sub Truncate($){
    my($value)=@_;
    return($value<0?Ceiling($value):Floor($value));
  }
  
  # Additional .NET Math methods
  sub Acosh($) {
    my($value) = @_;
    throw(System::ArgumentOutOfRangeException->new('value')) if $value < 1;
    return log($value + sqrt($value * $value - 1));
  }
  
  sub Asinh($) {
    my($value) = @_;
    return log($value + sqrt($value * $value + 1));
  }
  
  sub Atanh($) {
    my($value) = @_;
    throw(System::ArgumentOutOfRangeException->new('value')) if abs($value) >= 1;
    return 0.5 * log((1 + $value) / (1 - $value));
  }
  
  sub BigMul($$) {
    my($a, $b) = @_;
    return $a * $b;  # In Perl, this naturally handles big integers
  }
  
  sub Clamp($$$) {
    my($value, $min, $max) = @_;
    throw(System::ArgumentException->new('min cannot be greater than max')) if $min > $max;
    return $value < $min ? $min : ($value > $max ? $max : $value);
  }
  
  sub CopySign($$) {
    my($magnitude, $sign) = @_;
    my $sign_val = Sign($sign);
    return $sign_val == 0 ? abs($magnitude) : abs($magnitude) * $sign_val;
  }
  
  sub DivRem($$$) {
    my($dividend, $divisor, $remainder_ref) = @_;
    throw(System::DivideByZeroException->new()) if $divisor == 0;
    my $quotient = int($dividend / $divisor);
    $$remainder_ref = $dividend - ($quotient * $divisor);
    return $quotient;
  }
  
  sub FusedMultiplyAdd($$$) {
    my($x, $y, $z) = @_;
    return ($x * $y) + $z;  # Simplified - real FMA would be more precise
  }
  
  sub IEEERemainder($$) {
    my($x, $y) = @_;
    throw(System::DivideByZeroException->new()) if $y == 0;
    my $quotient = $x / $y;
    my $rounded_quotient = Round($quotient);
    return $x - ($y * $rounded_quotient);
  }
  
  sub Log2($) {
    my($value) = @_;
    throw(System::ArgumentOutOfRangeException->new('value')) if $value <= 0;
    return log($value) / log(2);
  }
  
  sub MaxMagnitude($$) {
    my($x, $y) = @_;
    my $abs_x = abs($x);
    my $abs_y = abs($y);
    return $abs_x > $abs_y ? $x : ($abs_y > $abs_x ? $y : ($x > $y ? $x : $y));
  }
  
  sub MinMagnitude($$) {
    my($x, $y) = @_;
    my $abs_x = abs($x);
    my $abs_y = abs($y);
    return $abs_x < $abs_y ? $x : ($abs_y < $abs_x ? $y : ($x < $y ? $x : $y));
  }
  
  sub ScaleB($$) {
    my($x, $n) = @_;
    return $x * (2 ** $n);
  }
  
  # Degree/Radian conversion helpers
  sub DegreesToRadians($) {
    my($degrees) = @_;
    return $degrees * PI / 180;
  }
  
  sub RadiansToDegrees($) {
    my($radians) = @_;
    return $radians * 180 / PI;
  }
  
  # Special value checking
  sub IsFinite($) {
    my($value) = @_;
    return !IsInfinity($value) && !IsNaN($value);
  }
  
  sub IsInfinity($) {
    my($value) = @_;
    return ($value eq 'inf' || $value eq '-inf' || $value == 9**9**9 || $value == -9**9**9);
  }
  
  sub IsNaN($) {
    my($value) = @_;
    return ($value ne $value);  # NaN != NaN
  }
  
  sub IsNegativeInfinity($) {
    my($value) = @_;
    return ($value eq '-inf' || $value == -9**9**9);
  }
  
  sub IsPositiveInfinity($) {
    my($value) = @_;
    return ($value eq 'inf' || $value == 9**9**9);
  }
  
  sub IsNormal($) {
    my($value) = @_;
    return IsFinite($value) && $value != 0;
  }
  
  sub IsSubnormal($) {
    my($value) = @_;
    # Simplified - in real implementation would check for denormalized numbers
    return IsFinite($value) && abs($value) < 1e-300;
  }
  
  # Additional rounding methods
  sub RoundToEven($$) {
    my($value, $digits) = @_;
    $digits //= 0;
    my $factor = 10 ** $digits;
    my $scaled = $value * $factor;
    my $integral = int($scaled);
    my $fractional = $scaled - $integral;
    
    if (abs($fractional) == 0.5) {
      # Round to even (banker's rounding)
      return ($integral % 2 == 0 ? $integral : $integral + Sign($fractional)) / $factor;
    } else {
      return Round($value, $digits);
    }
  }
  
  # Utility methods
  sub Factorial($) {
    my($n) = @_;
    throw(System::ArgumentOutOfRangeException->new('n')) if $n < 0;
    return 1 if $n <= 1;
    my $result = 1;
    for my $i (2..$n) {
      $result *= $i;
    }
    return $result;
  }
  
  sub GCD($$) {
    my($a, $b) = @_;
    $a = abs($a);
    $b = abs($b);
    while ($b != 0) {
      my $temp = $b;
      $b = $a % $b;
      $a = $temp;
    }
    return $a;
  }
  
  sub LCM($$) {
    my($a, $b) = @_;
    return abs($a * $b) / GCD($a, $b);
  }
  
  # Hyperbolic functions (additional)
  sub Sech($) {
    my($value) = @_;
    return 1 / Cosh($value);
  }
  
  sub Csch($) {
    my($value) = @_;
    throw(System::DivideByZeroException->new()) if $value == 0;
    return 1 / Sinh($value);
  }
  
  sub Coth($) {
    my($value) = @_;
    throw(System::DivideByZeroException->new()) if $value == 0;
    return Cosh($value) / Sinh($value);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
}
1;