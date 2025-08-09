package System::Linq::CastIterator; {
  use base 'System::Object','System::Collections::IEnumerator';

  use strict;
  use warnings;

  use CSharp;

  sub new($$$) {
    my $class=shift(@_);
    my ($enumerator, $targetType)=@_;
    bless {
      _enumerator=>$enumerator,
      _targetType=>$targetType,
      _current=>null
    },ref($class)||$class;
  }

  sub Dispose($){
    my($this)=@_;
    $this->{_enumerator}->Dispose();
    $this->{_enumerator}=null;
  }
  
  sub Reset($) {
    my($this)=@_;
    $this->{_enumerator}->Reset();
    $this->{_current}=null;
  }

  sub MoveNext($) {
    my($this)=@_;
    if($this->{_enumerator}->MoveNext()) {
      my $current=$this->{_enumerator}->Current;
      
      # Try to cast to target type - throw exception if cannot cast
      if (defined($current) && ref($current)) {
        if (!$current->isa($this->{_targetType})) {
          throw(System::InvalidCastException->new("Unable to cast object to type $this->{_targetType}"));
        }
      } elsif (!ref($current) && $this->{_targetType} ne 'SCALAR') {
        throw(System::InvalidCastException->new("Unable to cast scalar to type $this->{_targetType}"));
      }
      
      $this->{_current}=$current;
      return(true);
    }
    $this->{_current}=null;
    return(false);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};
  
package System::Linq::CastCollection; {
  use base 'System::Object','System::Collections::IEnumerable';

  sub new($$$) {
    my $class=shift(@_);
    my ($collection, $targetType)=@_;
    bless {
      _collection=>$collection,
      _targetType=>$targetType
    },ref($class)||$class;
  }

  sub GetEnumerator($) {
    my($this)=@_;
    return(new System::Linq::CastIterator($this->{_collection}->GetEnumerator(),$this->{_targetType}));
  }
};

1;