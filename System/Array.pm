package System::Array; {
  use base 'System::Object','System::Collections::IEnumerable';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;

  sub new {
    my $class=shift(@_);
    my $this=[];
    # accept a single unblessed array reference as initializer list besides a flat list
    push(@{$this},(@_==1 && ref($_[0]) eq 'ARRAY')?@{$_[0]}:@_);
    bless $this,ref($class)||$class||__PACKAGE__;
    return ($this);
  }

  sub Length($) {
    my ($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(scalar(@{$this}));
  }

  sub Clear($) {
    my ($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    splice(@{$this},0,Length($this));
  }

  sub GetValue($$) {
    my ($this,$index)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::IndexOutOfBoundsException->new($index)) if ($index<0 || $this->Length <= $index);
    return($this->[$index]);
  }

  sub Get($$) {
    my ($this,$index)=@_;
    return $this->GetValue($index);
  }

  sub Set($$$) {
    my ($this,$index,$value)=@_;
    return $this->SetValue($value,$index);
  }

  sub SetValue($$$) {
    my ($this,$value,$index)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::IndexOutOfBoundsException->new($index)) if ($index<0 || $this->Length <= $index);
    $this->[$index]=$value;
  }

  sub GetEnumerator($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    return(System::_SZArrayEnumerator->new($this));
  }

  # Returns a flavor code for a plain (non-ref) scalar so we can keep
  # .NET-like type-aware comparison: 'I'=integer, 'F'=float, 'S'=string.
  sub _ScalarFlavor {
    my($value)=@_;
    require B;
    my $sv=B::svref_2object(\$value);
    my $flags=$sv->FLAGS;
    return('S') if($flags & B::SVf_POK());
    return('F') if($flags & B::SVf_NOK());
    return('I') if($flags & B::SVf_IOK());
    return('S');
  }

  # Type-aware element comparison for IndexOf/LastIndexOf/Contains.
  sub _ElementEquals {
    my($element,$value)=@_;

    # both undef => equal; exactly one undef => not equal
    return(true) if(!defined($element) && !defined($value));
    return(false) if(!defined($element) || !defined($value));

    require Scalar::Util;
    my $eb=Scalar::Util::blessed($element);
    my $vb=Scalar::Util::blessed($value);

    # both blessed objects => use Equals (value/reference semantics)
    if($eb && $vb){
      return(true) if(Scalar::Util::refaddr($element)==Scalar::Util::refaddr($value));
      if($element->can('Equals')){
        my $r=eval{$element->Equals($value)};
        return($r?true:false) unless($@);
      }
      if($value->can('Equals')){
        my $r=eval{$value->Equals($element)};
        return($r?true:false) unless($@);
      }
      return(false);
    }

    # exactly one blessed => not equal (a System::String('0') must not match 0)
    return(false) if($eb || $vb);

    # both are unblessed refs => reference identity
    if(ref($element) && ref($value)){
      return(Scalar::Util::refaddr($element)==Scalar::Util::refaddr($value)?true:false);
    }
    return(false) if(ref($element) || ref($value));

    # both plain scalars => compare within same flavor (int/float/string)
    my $ef=_ScalarFlavor($element);
    my $vf=_ScalarFlavor($value);
    return(false) unless($ef eq $vf);
    if($ef eq 'S'){
      return($element eq $value?true:false);
    }
    return($element==$value?true:false);
  }

  sub IndexOf($$) {
    my($this,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    for (my $i=0;$i<scalar(@{$this});++$i) {
      return $i if (_ElementEquals($this->[$i],$value));
    }
    return -1;
  }

  sub LastIndexOf($$) {
    my($this,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    for (my $i=scalar(@{$this})-1;$i>=0;--$i) {
      return $i if (_ElementEquals($this->[$i],$value));
    }
    return -1;
  }

  sub Contains($$) {
    my($this,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    for (my $i=0;$i<scalar(@{$this});++$i) {
      return(true) if (_ElementEquals($this->[$i],$value));
    }
    return(false);
  }
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
  
};
    
package System::_SZArrayEnumerator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;
  
  use CSharp;
  use System::Exceptions;
  
  sub new {
    my $class=shift(@_);
    my ($array)=@_;
    bless {
      _array=>$array,
      _index=>-1,
      _endIndex=>$array->Length,
      _current=>null,
    },ref($class)||$class;
  }

  sub MoveNext($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    if($this->{_index}<$this->{_endIndex}) {
      $this->{_index}++;
      my $result=$this->{_index}<$this->{_endIndex}?true:false;
      if($result){
        $this->{_current}=$this->{_array}->GetValue($this->{_index});
      }else{
        $this->{_current}=null;
      }
      return($result);
    }
    return false();
  }

  sub Reset($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    $this->{_index}=-1;
    $this->{_endIndex}=$this->{_array}->Length;
    $this->{_current}=null;
  }

  sub Current($) {
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    throw(System::InvalidOperationException->new('Current','Enumeration not started')) if ($this->{_index} < 0);
    throw(System::InvalidOperationException->new('Current','Enumeration already ended')) if ($this->{_index} >= $this->{_endIndex});
    return($this->{_current});
  }

  sub Dispose($){
    my($this)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    $this->{_current}=null;
    $this->{_array}=null;
  }

};

1;