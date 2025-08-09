package System::Linq::OfTypeIterator; {
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
    while($this->{_enumerator}->MoveNext()) {
      my $current=$this->{_enumerator}->Current;
      
      # Check if current item is of target type
      my $isTargetType = 0;
      if (defined($current) && ref($current)) {
        $isTargetType = $current->isa($this->{_targetType});
      } elsif (!ref($current) && $this->{_targetType} eq 'SCALAR') {
        $isTargetType = 1;
      }
      
      if ($isTargetType) {
        $this->{_current}=$current;
        return(true);
      }
    }
    $this->{_current}=null;
    return(false);
  }

  sub Current($) {
    my($this)=@_;
    return($this->{_current});
  }
};
  
package System::Linq::OfTypeCollection; {
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
    return(new System::Linq::OfTypeIterator($this->{_collection}->GetEnumerator(),$this->{_targetType}));
  }
};

1;