package System::Tuple; {
  use base "System::Object";
  
  use strict;
  use warnings;

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

  sub Create(@) {
    return(System::Tuple->new(@_));
  }

  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};

1;