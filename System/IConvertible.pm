package System::IConvertible; {
  use strict;
  use warnings;
  
  use CSharp;

  sub GetTypeCode($){throw NotImplementedException->new()}
  sub ToBoolean($;$){throw NotImplementedException->new()}
  sub ToByte($;$){throw NotImplementedException->new()}
  sub ToChar($;$){throw NotImplementedException->new()}
  sub ToDateTime($;$){throw NotImplementedException->new()}
  sub ToDecimal($;$){throw NotImplementedException->new()}
  sub ToDouble($;$){throw NotImplementedException->new()}
  sub ToInt16($;$){throw NotImplementedException->new()}
  sub ToInt32($;$){throw NotImplementedException->new()}
  sub ToInt64($;$){throw NotImplementedException->new()}
  sub ToSByte($;$){throw NotImplementedException->new()}
  sub ToSingle($;$){throw NotImplementedException->new()}
  sub ToString($;$){throw NotImplementedException->new()}
  sub ToType($$;$){throw NotImplementedException->new()}
  sub ToUInt16($;$){throw NotImplementedException->new()}
  sub ToUInt32($;$){throw NotImplementedException->new()}
  sub ToUInt64($;$){throw NotImplementedException->new()}
  
  BEGIN{CSharp::_ShortenPackageName(__PACKAGE__);}
}

1;