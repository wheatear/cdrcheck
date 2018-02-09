package gprscdrfac;

#the concreate voice cdr factory
use lib qw(../cdr ../lib);
use util;
use conf;


use cdr;
use gprscdr;

@ISA = qw(cdrfac);


use strict;


#virtual function return a cdr reference
sub make_cdr {
my $this = shift;
my @args = @_;
return  new gprscdr(@_);
}



1;