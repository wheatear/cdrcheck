package zycdr;
use lib qw(../lib ../fetcher);
use Date;
use conf;
use cdr;
use util;
use voicefetcher;
use zyfetcher;
use rnccdr;

#mark for parse excel
use constant MARK			=> 'ÖĞ¼ÌÈººÅ';

#inherited from cdr class
@ISA = qw(cdr);

use strict;

#constructor
sub new{         
	my $class = shift;
	if (scalar @_ eq 0) {return bless({},$class);}
	
	my ($row,$tid,$phone,$opp,$day,$start,$end,$sts) = @_;
	p_log("$row,$tid,$phone,$opp,$day,$start,$end,$sts");
 
	#trunc the day
	$day=~s/-//g;
	
	#construct the parent part
	my $ref = new cdr($row,$phone,$day,$start,$end,$sts);
	return $ref if (   $ref == PHONE_ERR 
					|| $ref == START_ERR
					|| $ref == END_ERR
					|| $ref == DAY_ERR
					|| $ref == EMP
					);
	
	
	#construct its own part
	
	#check format
	return OPP_ERR   if (!($opp   =~ m/^(\d*-{0,1}\d*)/));
	
	#chomp the space in opp
	$opp   =~ s/^(86|\d+-|010)//g;
	
	$ref->{opp} = $opp;
	$ref->{tid} = $tid;
	
	#bless and return
	bless($ref, $class);
	return $ref;
}
  
sub make_cdr{
	my $this = shift;
	my @args = @_;
	return new zycdr(@args);
} 

#validate  
sub validate {
	my $this = shift;
	my $fetcher = new zyfetcher();		#A fetcher pass as argument
	p_log("Validate: ".$this->toStr());
	
	#set fetcher
	$this->setfech($fetcher);
	#set factory
	$this->setfac($this);
	
	#call parent's validate
	my $re = $this->SUPER::validate();
	
	#errno check
	return $re if ($re ne 0);
	
	#revalidate
	if ($this->{sts} eq BAD) {
		p_log("Revalidate");
		#set factory(a rnc cdr)
		$this->setfac(new rnccdr());
		$re = $this->SUPER::validate();
		#errno check
		return $re if ($re ne 0);
	}
	return 0;
}


#for printf
sub toStr{
	my $this = shift;
	my $str = sprintf "%s|" x 8, 
	$this->{row}, $this->{tid},$this->{phone},$this->{opp},$this->{day},
	substr($this->{start}->toStr(),8,6),substr($this->{end}->toStr(),8,6),$this->{sts};
	return $str;
}
  
#compare
sub _comp {
	my $this = shift;
	my $other = shift;
	
	my $sts;
	
	#basic compare rule: phone_number, start_time,end_time
	(return 0) if ($this->{start}->diff($other->{start})>maxdiff);
	(return 0) if ($this->{end}->diff($other->{end})>maxdiff);
	
	#after passing basic compare, check whether some little differences
	($sts .= '[start time:'.substr($other->{start}->toStr(),8,6).']')	if ($this->{start}->diff($other->{start}) > 0);
	($sts .= '[end time:'.substr($other->{end}->toStr(),8,6).']')		if ($this->{end}->diff($other->{end}) > 0);
	
	$this->{sts} = $other->{sts};
	
	return 1;
}
 

1;