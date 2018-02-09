package cdr;
#it is an abstract class enclosing the basic operation and field of cdr

use lib qw(../lib ../fetcher);
use conf;
use util;
use Date;

 
use strict;




#constuctor
#every cdr must have six field:
#row: the position in excel file
#phone: the caller
#day: the day of cdr
#start:　start time only accept standard format
#end: end tile
#sts: status
sub new{         
	my $class = shift;
	if (scalar @_ eq 0) {return bless({},$class);}
	
	#every cdr will have the six field
	my ($row,$phone,$day,$start,$end,$sts) = @_;
	

	
	#if the basic fiesd is empty return emp inidcating to ignore the entry
	return EMP			if (!$row);
	return EMP			if (!$phone);
	return EMP			if (!$day);
	return EMP			if (!$start);
	return EMP			if (!$end);
	
	$day =~ s/[\s-]//g;
	$start =~ s/[\s:-]//g;
	$end =~ s/[\s:-]//g;
	#format cheking goes here
	return PHONE_ERR 	if (!($phone =~ m/^\d+-{0,1}\s*\d+$/));
	return DAY_ERR		if (!(($day =~ m/^\s*\d{8}$/)||($day =~ m/^\s*\d{4}-\d{2}-\d{2}$/)));
	return START_ERR	if (!($start =~ m/^\s*(\d{4}[-\s]{0,1}\d{2}[-\s]{0,1}\d{2}\s{0,1}){0,1}\d{2}[:\s]{0,1}\d{2}[:\s]{0,1}\d{2}$/)); 
	return END_ERR		if (!($end   =~ m/^\s*(\d{4}[-\s]{0,1}\d{2}[-\s]{0,1}\d{2}\s{0,1}){0,1}\d{2}[:\s]{0,1}\d{2}[:\s]{0,1}\d{2}$/)); 
	
	
	#chomp the space in phone and time
	$phone =~ s/^(86|\d+-|010)//g;
	$start = new Date($start);
	$end = new Date($end);
	

	#the hash map
	my $ref={
		row			=> $row,
		phone		=> $phone,
		day			=> $day,
		start		=> $start, 
		end			=> $end, 
		sts			=> $sts
	};
	

	#bless and return
	bless($ref, $class);
	return $ref;
}
    
	
#factory method
sub make_cdr {}


#set the factory
sub setfac{
	my $this = shift;
	my $fac = shift;
	$this->{fac} = $fac;
}

#set the fether
sub setfech{
	my $this = shift;
	my $fech = shift;
	$this->{fech} = $fech;
}
	
	
#compare the basic field
#return 0 for unmatch cdr and set status to BAD indicating sub-class to pass the cdr
sub _comp {}

#the default function, use fetcher to fech arguments, use factory to construct the cdr for compare
sub validate {
	my $this = shift;
	
	my $fac		= $this->{fac};
	my $fech	= $this->{fech};

	#check in two days
	foreach my $delta (0,1) {
		my $day = new Date($this->{day});
		$day->add(24*60*60*$delta);
		$day = $day->toStr();          
		$day =~ s/000000$//;
		
		p_log("Validate in $day");
		
		#fetch in a specified day
		#use fetcher to fech
		my $re = $fech->fetch($this,$day);
		#p_log(@$re);
		return DBERRO     if ($re == DBERRO);
		return SQLERRO    if ($re == SQLERRO);
		return TRKERRO    if ($re == TRKERRO);
		
		$this->{sts} = BAD;                   #set status
		#如果是按DDN收费的集团统付APN,需要将用户手机号换成集团号码进行验证,并在验证结束后换回,以作比对
		$this->{phone} = $this->{msisdn} if($this->{msisdn});
		#validate cdr
		foreach (@$re) {
			#generate cdr from db
			my @args = @$_;		
			p_log("@args");
			#use factory to create cdr for comparing
			my $dbcdr = $fac->make_cdr(@args);
			
			p_log('dbcdr: '.$dbcdr);
			#compare to cdr list
			last if ($this->_comp($dbcdr)); 
		}
		
		#if match one, break
		if ($this->{sts} ne BAD) {
			p_log("Validate OK");
			last;
		}
		
	}
	return 0;
}
 

sub toStr{
	my $this = shift;
	my $str = $this->{row}.": ".$this->{sts};
	return $str;
}




1;