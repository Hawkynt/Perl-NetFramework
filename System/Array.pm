package System::Array; {
  use base 'System::Object','System::Collections::IEnumerable';
  
  use strict;
  use warnings;
  use CSharp;
  require System::Exceptions;

  sub new {
    my $class=shift(@_);
    my $this=[];
    push(@{$this},@_);
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

  sub IndexOf($$) {
    my($this,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    for (my $i=0;$i<scalar(@{$this});++$i) {
      return $i if (System::Object::Equals($this->[$i],$value,true));
    }
    return -1;
  }

  sub LastIndexOf($$) {
    my($this,$value)=@_;
    throw(System::NullReferenceException->new()) unless(defined($this));
    for (my $i=scalar(@{$this})-1;$i>=0;--$i) {
      return $i if (System::Object::Equals($this->[$i],$value,true));
    }
    return -1;
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