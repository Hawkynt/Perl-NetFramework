package System::Tuple; {
  use base "System::Object";
  
  use strict;
  use warnings;
  use Scalar::Util qw(blessed);

  use CSharp;
  use System::Exceptions;

  sub new {
    my $class=shift(@_);
    bless { _items=>\@_ },ref($class)||$class;
  }

  sub Item1 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item1','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 1;
    return($this->{_items}->[0]);
  }

  sub Item2 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item2','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 2;
    return($this->{_items}->[1]);
  }

  sub Item3 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item3','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 3;
    return($this->{_items}->[2]);
  }

  sub Item4 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item4','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 4;
    return($this->{_items}->[3]);
  }

  sub Item5 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item5','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 5;
    return($this->{_items}->[4]);
  }
  
  sub Item6 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item6','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 6;
    return($this->{_items}->[5]);
  }
  
  sub Item7 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item7','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 7;
    return($this->{_items}->[6]);
  }
  
  sub Item8 () {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::InvalidOperationException->new('Item8','Too less elements in Tuple to perform the given operation')) if scalar(@{$this->{_items}}) < 8;
    return($this->{_items}->[7]);
  }
  
  # Additional properties and methods
  sub Count() {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    return scalar(@{$this->{_items}});
  }
  
  sub GetItem($) {
    my($this, $index) = @_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    throw(System::ArgumentOutOfRangeException->new('index')) if $index < 0 || $index >= $this->Count();
    return $this->{_items}->[$index];
  }
  
  # Equality and comparison
  sub Equals($) {
    my($this, $other) = @_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    return 0 unless defined($other) && ref($other) eq ref($this);
    
    my $count = $this->Count();
    return 0 unless $count == $other->Count();
    
    for my $i (0..$count-1) {
      my $item1 = $this->{_items}->[$i];
      my $item2 = $other->{_items}->[$i];
      
      # Handle null values
      if (!defined($item1) && !defined($item2)) {
        next;
      }
      if (!defined($item1) || !defined($item2)) {
        return 0;
      }
      
      # Use object Equals if available, otherwise use eq/==
      if (ref($item1) && blessed($item1) && $item1->can('Equals')) {
        return 0 unless $item1->Equals($item2);
      } else {
        return 0 unless $item1 eq $item2 || $item1 == $item2;
      }
    }
    return 1;
  }
  
  sub GetHashCode() {
    my($this) = @_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    
    my $hash = 17;
    for my $item (@{$this->{_items}}) {
      if (defined($item)) {
        if (ref($item) && blessed($item) && $item->can('GetHashCode')) {
          $hash = $hash * 31 + $item->GetHashCode();
        } else {
          # Simple hash for basic types
          $hash = $hash * 31 + length($item) + ord(substr($item . "\0", 0, 1));
        }
      } else {
        $hash = $hash * 31;
      }
    }
    return $hash;
  }
  
  sub ToString() {
    my($this) = @_;
    throw(System::NullReferenceException->new()) unless (defined($this));
    
    my @parts = ();
    for my $item (@{$this->{_items}}) {
      if (!defined($item)) {
        push @parts, '';
      } elsif (ref($item) && blessed($item) && $item->can('ToString')) {
        push @parts, $item->ToString();
      } else {
        push @parts, "$item";
      }
    }
    
    return '(' . join(', ', @parts) . ')';
  }

  sub Create(@) {
    return(System::Tuple->new(@_));
  }
  
  # Static factory methods for specific tuple sizes (more .NET-like)
  sub Create1($) {
    my($item1) = @_;
    return System::Tuple->new($item1);
  }
  
  sub Create2($$) {
    my($item1, $item2) = @_;
    return System::Tuple->new($item1, $item2);
  }
  
  sub Create3($$$) {
    my($item1, $item2, $item3) = @_;
    return System::Tuple->new($item1, $item2, $item3);
  }
  
  sub Create4($$$$) {
    my($item1, $item2, $item3, $item4) = @_;
    return System::Tuple->new($item1, $item2, $item3, $item4);
  }
  
  sub Create5($$$$$) {
    my($item1, $item2, $item3, $item4, $item5) = @_;
    return System::Tuple->new($item1, $item2, $item3, $item4, $item5);
  }
  
  sub Create6($$$$$$) {
    my($item1, $item2, $item3, $item4, $item5, $item6) = @_;
    return System::Tuple->new($item1, $item2, $item3, $item4, $item5, $item6);
  }
  
  sub Create7($$$$$$$) {
    my($item1, $item2, $item3, $item4, $item5, $item6, $item7) = @_;
    return System::Tuple->new($item1, $item2, $item3, $item4, $item5, $item6, $item7);
  }
  
  sub Create8($$$$$$$$) {
    my($item1, $item2, $item3, $item4, $item5, $item6, $item7, $item8) = @_;
    return System::Tuple->new($item1, $item2, $item3, $item4, $item5, $item6, $item7, $item8);
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;