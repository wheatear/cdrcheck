package cdrfac;
#abstract factory

use lib qw(../cdr ../lib);
use cdr;
use util;
use conf;


use strict;

#an abstract factory 
sub new{         
my $class = shift;
my $ref={};
bless($ref, $class);
return $ref;
}


#virtual function return a cdr reference
sub make_cdr {}



1;