#!/usr/bin/perl
use strict;
use warnings;
use lib '../../../';
use Test::More;

# Define constants
use constant true => 1;
use constant false => 0;

# Import LINQ classes
use System::Linq;
use System::Array;

# Helper: turn a System::Array into a native perl list for easy assertions.
sub to_list {
    my($array)=@_;
    my @result;
    for(my $i=0;$i<$array->Length();++$i) {
        push(@result,$array->Get($i));
    }
    return(@result);
}

sub test_orderbydescending_numeric {
    my $arr=System::Array->new(3,1,4,1,5,9,2,6);
    my @sorted=to_list($arr->OrderByDescending(sub{$_[0]})->ToArray());
    is_deeply(\@sorted,[9,6,5,4,3,2,1,1],'OrderByDescending sorts numerics high to low');
}

sub test_orderby_string {
    my $arr=System::Array->new('banana','apple','cherry');
    my @sorted=to_list($arr->OrderBy(sub{$_[0]})->ToArray());
    is_deeply(\@sorted,['apple','banana','cherry'],'OrderBy sorts strings ascending');
}

sub test_orderbydescending_string {
    my $arr=System::Array->new('banana','apple','cherry');
    my @sorted=to_list($arr->OrderByDescending(sub{$_[0]})->ToArray());
    is_deeply(\@sorted,['cherry','banana','apple'],'OrderByDescending sorts strings descending');
}

sub test_orderby_thenby {
    # Two records share the primary key (age); ThenBy on name breaks the tie.
    my $people=System::Array->new(
        {name=>'Charlie',age=>30},
        {name=>'Alice',age=>25},
        {name=>'Bob',age=>30},
        {name=>'Dave',age=>25},
    );
    my @sorted=to_list(
        $people
            ->OrderBy(sub{$_[0]->{age}})
            ->ThenBy(sub{$_[0]->{name}})
            ->ToArray()
    );
    my @names=map {$_->{name}} @sorted;
    is_deeply(\@names,['Alice','Dave','Bob','Charlie'],'OrderBy age then ThenBy name');
}

sub test_orderby_thenbydescending {
    my $people=System::Array->new(
        {name=>'Charlie',age=>30},
        {name=>'Alice',age=>25},
        {name=>'Bob',age=>30},
        {name=>'Dave',age=>25},
    );
    my @sorted=to_list(
        $people
            ->OrderBy(sub{$_[0]->{age}})
            ->ThenByDescending(sub{$_[0]->{name}})
            ->ToArray()
    );
    my @names=map {$_->{name}} @sorted;
    is_deeply(\@names,['Dave','Alice','Charlie','Bob'],'OrderBy age then ThenByDescending name');
}

sub test_orderbydescending_thenby {
    my $people=System::Array->new(
        {name=>'Charlie',age=>30},
        {name=>'Alice',age=>25},
        {name=>'Bob',age=>30},
        {name=>'Dave',age=>25},
    );
    my @sorted=to_list(
        $people
            ->OrderByDescending(sub{$_[0]->{age}})
            ->ThenBy(sub{$_[0]->{name}})
            ->ToArray()
    );
    my @names=map {$_->{name}} @sorted;
    is_deeply(\@names,['Bob','Charlie','Alice','Dave'],'OrderByDescending age then ThenBy name');
}

sub test_thenby_thenby_three_levels {
    # Three sort levels: primary group, secondary group, then value.
    my $items=System::Array->new(
        {a=>1,b=>2,c=>3},
        {a=>1,b=>2,c=>1},
        {a=>1,b=>1,c=>5},
        {a=>2,b=>1,c=>1},
    );
    my @sorted=to_list(
        $items
            ->OrderBy(sub{$_[0]->{a}})
            ->ThenBy(sub{$_[0]->{b}})
            ->ThenBy(sub{$_[0]->{c}})
            ->ToArray()
    );
    my @keys=map {"$_->{a}$_->{b}$_->{c}"} @sorted;
    is_deeply(\@keys,['115','121','123','211'],'Three chained sort levels');
}

sub test_stability {
    # Equal primary keys must preserve original (input) relative order.
    my $items=System::Array->new(
        {key=>1,tag=>'first'},
        {key=>1,tag=>'second'},
        {key=>1,tag=>'third'},
        {key=>0,tag=>'zero'},
    );
    my @sorted=to_list($items->OrderBy(sub{$_[0]->{key}})->ToArray());
    my @tags=map {$_->{tag}} @sorted;
    is_deeply(\@tags,['zero','first','second','third'],'OrderBy is stable for equal keys');
}

sub test_stability_thenby {
    # Equal across both criteria keeps input order at the deepest level.
    my $items=System::Array->new(
        {a=>1,b=>1,id=>'x'},
        {a=>1,b=>1,id=>'y'},
        {a=>1,b=>1,id=>'z'},
    );
    my @sorted=to_list(
        $items
            ->OrderBy(sub{$_[0]->{a}})
            ->ThenBy(sub{$_[0]->{b}})
            ->ToArray()
    );
    my @ids=map {$_->{id}} @sorted;
    is_deeply(\@ids,['x','y','z'],'ThenBy keeps input order when all keys equal');
}

sub test_empty_sequence {
    my $arr=System::Array->new();
    my @sorted=to_list($arr->OrderBy(sub{$_[0]})->ThenBy(sub{$_[0]})->ToArray());
    is(scalar(@sorted),0,'Ordering an empty sequence yields empty');
}

sub test_single_element {
    my $arr=System::Array->new(42);
    my @sorted=to_list($arr->OrderByDescending(sub{$_[0]})->ThenBy(sub{$_[0]})->ToArray());
    is_deeply(\@sorted,[42],'Ordering a single element yields that element');
}

sub test_thenby_without_orderby_throws {
    my $arr=System::Array->new(3,1,2);
    eval {
        $arr->ThenBy(sub{$_[0]});
    };
    ok($@,'ThenBy on a non-ordered enumerable throws');
    isa_ok($@,'System::InvalidOperationException','ThenBy throws InvalidOperationException');
}

sub test_thenbydescending_without_orderby_throws {
    my $arr=System::Array->new(3,1,2);
    eval {
        $arr->ThenByDescending(sub{$_[0]});
    };
    ok($@,'ThenByDescending on a non-ordered enumerable throws');
    isa_ok($@,'System::InvalidOperationException','ThenByDescending throws InvalidOperationException');
}

sub test_default_selector {
    # OrderBy/ThenBy with no selector should sort by the element itself.
    my $arr=System::Array->new(5,3,8,1);
    my @sorted=to_list($arr->OrderBy()->ToArray());
    is_deeply(\@sorted,[1,3,5,8],'OrderBy with default selector sorts by element');
}

test_orderbydescending_numeric();
test_orderby_string();
test_orderbydescending_string();
test_orderby_thenby();
test_orderby_thenbydescending();
test_orderbydescending_thenby();
test_thenby_thenby_three_levels();
test_stability();
test_stability_thenby();
test_empty_sequence();
test_single_element();
test_thenby_without_orderby_throws();
test_thenbydescending_without_orderby_throws();
test_default_selector();

done_testing();
