package rnccdr;
use lib qw(../lib ../fetcher);

use util;
use conf;
use cdr;
use Date;
use voicefetcher;

#inherited from cdr class
@ISA = qw(cdr);

use strict;

#constructor
sub new{
	my $class = shift;
	
	if (scalar @_ eq 0) {return bless({},$class);}
	
	my ($row,$no,$type,$type1,$phone,$opp,$third,$day,$start,$end,$chu,$sts) = @_;
	
	#trunc the day
	$day=~s/-//g;
	#consturct the start time
	$start = ($start)? $day.$start: undef;
	$end = ($end)? $day.$end: undef;
	
	#construct the parent part
	my $ref = new cdr($row,$phone,$day,$start,$end,$sts);
	
	return $ref  if ($ref==PHONE_ERR 
					|| $ref==START_ERR 
					|| $ref==END_ERR
					||$ref==EMP
					||$ref==DAY_ERR
					);
	
	
	#construct its own part
	
	#check format
	return OPP_ERR			if ((!($opp =~ m/^(\d+-{0,1}\s*\d+)$/))&&$opp);
	return THIRD_ERR		if ((!($third =~ m/^(\d+-{0,1}\d+)$/))&&$third);
	
#	#	add by wxt 20170412
#	$durStart = new Date($start);
#	$durStart->add(-10);
#	$durEnd = new Date($start);
#	$durEnd->add(10);
	
	#chomp the space in field
	$opp   =~ s/^(86|\d+-|17951|010)//g;
	$third =~ s/^(86|\d+-)//g;
	
	$ref->{no}		=	$no;
	$ref->{opp}		=	$opp;
	$ref->{type}	=	$type;
	$ref->{type1}	=	$type1;
	$ref->{third}	=	$third;
	$ref->{chu}		=	$chu;
	
	#bless and return
	bless($ref, $class);
	return $ref;
}
 
sub make_cdr{
	my $this = shift;
	my @args = @_;
	return new rnccdr(@args);
} 

#for printf
sub toStr{
	my $this = shift;
	my $str = sprintf "%s|" x 12, 
	$this->{row}, $this->{no},$this->{type},$this->{type1},$this->{phone},
	$this->{opp}, $this->{third},$this->{day}, 
	substr($this->{start}->toStr(),8,6),substr($this->{end}->toStr(),8,6),
	$this->{chu},$this->{sts};
	return $str;
}
 
#define the voice cdr validation rule  
sub validate {
	my $this = shift;
	my $fetcher = new voicefetcher();		#A fetcher pass as argument
	p_log("Validate: ".$this->toStr());
	
	#check if local cdr
	my $local = $fetcher->check_local($this);
		p_log("Find $local record");
		return DBERRO     if ($local == DBERRO);
		return SQLERRO    if ($local == SQLERRO);
	
	#not local
	if (!$local) {
		p_log("Need 173");
		#validate in 173
		my $checkresult =  remote('D',$this->{phone},$this->{day},$this->{start}->toStr());
		p_log($checkresult);
		if (!(defined $checkresult)) {
			$this->{sts} = FAIL;
		}
		elsif ($checkresult == 1) {
			$this->{sts} = 'OK';
		}
		elsif ($checkresult == 0){
			$this->{sts} = BAD;
		}
		return 0;
	}


	#set fetcher
	$this->setfech($fetcher);
	#set factory
	$this->setfac($this);
	
	#call parent's validate
	my $re = $this->SUPER::validate();
	
	#errno check
	return $re if ($re ne 0);
	
	return 0;
}

#compare
sub _comp {
	my $this = shift;
	my $other = shift;
	
	my $sts = 'OK';
	
	#basic compare rule: phone_number, start_time,end_time
	(return 0) if ($this->{start}->diff($other->{start})>maxdiff);
	(return 0) if ($this->{end}->diff($other->{end})>maxdiff);
	
	#after passing basic compare, check whether some little differences
	($sts .= '[start time:'.substr($other->{start}->toStr(),8,6).']')	if ($this->{start}->diff($other->{start}) > 0);
	($sts .= '[end time:'.substr($other->{end}->toStr(),8,6).']')		if ($this->{end}->diff($other->{end}) > 0);
	
	$this->{sts} = $sts;
	
	return 1;
}


 

1;