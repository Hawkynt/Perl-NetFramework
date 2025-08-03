### <summary>
### This is a scope guard, that makes sure, that a certain call gets executed when a scope ends.
### </summary>
package CSharp::_ScopeGuard; {
  ### <summary>
  ### Constructor.
  ### </summary>
  ### <param name="preCall">An action that gets executed upon scope construction</param>
  ### <param name="postCall">An action that gets executed when the scope ends</param>
  sub new($$$){
    my($class,$preCall,$postCall)=@_;
    $preCall->() if(defined($preCall));
    bless([$postCall],__PACKAGE__);
  }
  
  sub DESTROY($){
    my($this)=@_;
    $this->[0]->() if(defined($this->[0]));
  }
};

package CSharp; {
  use strict;
  use warnings;

  use Exporter;
  use base 'Exporter';
  our @EXPORT=qw(true false null try catch finally throw switch case default);

  use System::Resources;
  
  # standard constants, which are keywords in C#
  use constant {
    true  => 1,
    false => 0,
    null  => undef
  };

  # magic refs that are used upon try/catch/finally and switch/cae/default construction
  use constant {
    _SWITCH_MAGIC_CASE=>"CSharp::_Switch::Case",
    _SWITCH_MAGIC_DEFAULT=>"CSharp::_Switch::Default",
    _TRYCATCH_MAGIC_CATCH=>"CSharp::_TryCatchFinally::Catch",
    _TRYCATCH_MAGIC_FINALLY=>"CSharp::_TryCatchFinally::Finally",
    _TX_SCALAR_BLOCK=>"<Scalar>",
    _TX_SWITCH=>"Switch/Case/Default",
    _TX_TRYCATCH=>"Try/Catch/Finally",
  };
  
  #region switch implementation
  # example usage
  #   switch 15,
  #     case 1,sub{
  #       print "1\n";
  #     },
  #     case 15,sub{
  #       print "15\n";
  #     },
  #     default {
  #       print "default\n";
  #     }
  #   ;
  sub switch($$){
    my($value,$block)=@_;
    while(defined($block)){
      my $ref=ref($block)||_TX_SCALAR_BLOCK;
      if($ref eq _SWITCH_MAGIC_DEFAULT){
        $block->[0]->($value);
        last;
      }elsif($ref eq _SWITCH_MAGIC_CASE){
        require System::Object;
        if(System::Object::Equals($value,$block->[0],false)){
          $block->[1]->($value);
          last;
        }
        
        # get next case/default block
        $block=$block->[2];
      }else{
        require System::Exceptions;
        throw(System::ArgumentException->new(sprintf(System::Resources::EX_WRONG_REF,$ref,_TX_SWITCH)));
      }
    }
  }

  sub case($&;$){
    bless(\@_,_SWITCH_MAGIC_CASE);
  }

  sub default(&){
    bless(\@_,_SWITCH_MAGIC_DEFAULT);
  }
  #endregion
  
  #region Try/Catch/Finally implementation
  sub try(&$){
    my($call,@blocks)=@_;

    # for returning values to caller
    my $isWantingArray=wantarray;
    my @results;
    
    my @catches;
    my @finallies;
    
    # add blocks to catches/finallies lists
    while(scalar(@blocks)>0){
      
      my $block=shift(@blocks);
      my $ref=ref($block)||_TX_SCALAR_BLOCK;
      
      if($ref eq _TRYCATCH_MAGIC_CATCH){
        push(@catches,shift(@{$block}));
      }elsif($ref eq _TRYCATCH_MAGIC_FINALLY){
        push(@finallies,shift(@{$block}));
      }else{
        require System::Exceptions;
        throw(System::ArgumentException->new(sprintf(System::Resources::EX_WRONG_REF,$ref,_TX_TRYCATCH)));
      }
      
      push(@blocks,@{$block})if(scalar(@{$block})>0);
    }
    
    # add default catch block if missing to allow bubble-up of exceptions
    push(@catches,sub{die($_[0]);}) unless(scalar(@catches)>0);


    # save previous error for later and prepare vars
    my $oldError=$@;
    my $tryError;
    my $tryFailed=false;
    my $catchError;
    my $catchFailed=false;
    
    {

      # prepare scope guard, in case we really fail hard (ie thread/process abort)
      my $scopeGuard=CSharp::_ScopeGuard->new(undef,sub{
        while(scalar(@finallies)>0){
          my $call=shift(@finallies);
          eval{$call->($tryError);};
        }
      });
          
      #region execute try
      {
        local $@;
        $tryFailed=not eval{
          $@=$oldError;
          local $SIG{'__DIE__'}; 
          
          if($isWantingArray){
            @results=$call->();
          }else{
            $results[0]=$call->();
          }
          true;
        };
        $tryError=$@;
      };
      #endregion
      
      
      #region execute catches
      if($tryFailed){
        local $@;
        $catchFailed=not eval{
          foreach my $call(@catches){
            $@=$tryError;
            local $SIG{'__DIE__'};
            
            my @catchResults;
            if($isWantingArray){
              @catchResults=$call->($tryError);
              @results=@catchResults if(@catchResults);
            }else{
              $catchResults[0]=$call->($tryError);
              $results[0]=$catchResults[0] if($catchResults[0]);
            }
            
          }
          true;
        };
        $catchError=$@;
      }
      #endregion
      
      # execute finallies gracefully
      while(scalar(@finallies)>0){
        my $call=shift(@finallies);
        $call->($tryError);
      }
      
      # any outstanding finally would be called here because the scope ends and the scope-guard executes them
    };
    
    # re-throw from catch if needed
    die($catchError)if($catchFailed);
    
    # restore previous errors
    $@=$oldError;
    
    # return values if any
    return($isWantingArray?@results:$results[0]);
  }
  
  sub catch(&;$){
    bless(\@_,_TRYCATCH_MAGIC_CATCH);
  }

  sub finally(&){
    bless(\@_,_TRYCATCH_MAGIC_FINALLY);
  }

  my $_lastThrown=null;
  
  ### <summary>
  ### Throws an exception
  ### </summary>
  ### <param name="exceptionObject">The exception to throw; defaults to the last thrown exception when none is given</param>
  sub throw(;$) {
    my($exceptionObject)=@_;
    
    # for re-throwing last exception
    $exceptionObject=$_lastThrown unless(defined($exceptionObject));
    
    $exceptionObject=System::ArgumentException->new('exceptionObject') unless (UNIVERSAL::isa($exceptionObject,'System::Exception'));
    
    # prevent overwriting an existing stack trace
    $exceptionObject->GetStackTrace() unless($exceptionObject->HasStackTrace);
    
    # remember to rethrow
    $_lastThrown=$exceptionObject;
    
    die($exceptionObject);
  }

  #endregion

  
  sub _ToString($;$$) {
    my($object,$format,$padding)=@_;
    my $result;
    if(defined($object)){
      if(ref($object)) {
        $result=$object->can("ToString")?$object->ToString($format):"";
      }elsif(!defined($format)){
        $result=$object;
      }else{
        require Scalar::Util;
        $result=Scalar::Util::looks_like_number($object)?System::Decimal->new($object)->ToString($format):System::String->new($object)->ToString($format);
      }
    } else {
      $result="";
    }
    
    return($result) unless(defined($padding));
    
    if($padding<0) {
      
      # left align
      return(substr($result.(' ' x (-$padding)),0,-$padding));
    } else {
    
      # right align
      return(substr((' ' x $padding).$result,-$padding));
    }
    
  }

  sub _compare($$) {
    my($a,$b)=@_;
    return($a cmp $b) if (ref($a) || ref($b));
    require Scalar::Util;
    return($a<=>$b) if (Scalar::Util::looks_like_number($a) && Scalar::Util::looks_like_number($b));
    return($a cmp $b);
  }

  sub _add($$) {
    my($a,$b)=@_;
    return($a) unless(defined($b));
    return($b) unless(defined($a));
    return($a+$b) if (ref($a) || ref($b));
    require Scalar::Util;
    return($a+$b) if (Scalar::Util::looks_like_number($a) && Scalar::Util::looks_like_number($b));
    return($a.$b);
  }

  sub _ShortenPackageName($){
    my($package)=@_;
    return unless($package);
    my($shortName)=$package=~m/([^:]+)$/;
    return unless($shortName && ($shortName ne $package));
    _PackageAlsoKnownAs($package,$shortName);
  }

  sub _PackageAlsoKnownAs($$){
    my($package,$newName)=@_;
    return unless($package);
    return unless($newName && ($newName ne $package));
    $newName.="::";
    $package.="::";
    no strict "refs";
    *{$newName}=*{$package};
    use strict "refs";
  }

};

1;