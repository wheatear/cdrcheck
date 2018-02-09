package gprscdr;
use lib qw(../lib ../fetcher);
use Date;
use conf;
use util;
use cdr;
use gprsfetcher;


#inherited from cdr class
@ISA = qw(cdr);

#constructor
sub new{
	my $class = shift;
	
	if (scalar @_ eq 0) {return bless({},$class);}
	
	my ($row,$no,$phone,$imsi,$apn,$day,$start, $end, $gip,$sip,$cid,$up,$down,
	$sid1,$sid1_up,$sid1_down,$sid2,$sid2_up,$sid2_down,$sid3,$sid3_up,$sid3_down,
	$mns_type,$database_type) = @_;			#mns_type add in 20130806,database_type add in 20131212
	
	
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
	return NO_ERR			if (!($no =~ m/^\d+$/));
	return IMSI_ERR			if (!($imsi =~ m/^\d+$/));
	return GIP_ERR			if (!($gip =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s*$/));
	return SIP_ERR			if (!($sip =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\s*$/));
	$up=1					if (!($up =~ m/^\d+$/));
	$down=1					if (!($down =~ m/^\d+$/));
	
	#option
	return SID1_ERR			if ((!($sid1 =~ m/^\d+$/)) && $sid1);
	return SID1UP_ERR		if ((!($sid1_up =~ m/^\d+$/)) && $sid1_up);
	return SID1DOWN_ERR		if ((!($sid1_down =~ m/^\d+$/)) && $sid1_down);
	return SID2_ERR			if ((!($sid2 =~ m/^\d+$/)) && $sid2);
	return SID2UP_ERR		if ((!($sid2_up =~ m/^\d+$/)) && $sid2_up);
	return SID2DOWN_ERR		if ((!($sid2_down =~ m/^\d+$/)) && $sid2_down);
	return SID3_ERR			if ((!($sid3 =~ m/^\d+$/)) && $sid3);
	return SID3UP_ERR		if ((!($sid3_up =~ m/^\d+$/)) && $sid3_up);
	return SID3DOWN_ERR		if ((!($sid3_down =~ m/^\d+$/)) && $sid3_down);
	
	
	
	#its own field
	$ref->{row}			= $row;
	$ref->{no}			= $no;
	$ref->{imsi}		= $imsi;
	$ref->{apn}			= $apn;
	$ref->{gip}			= $gip;
	$ref->{sip}			= $sip;
	$ref->{cid}			= $cid;
	$ref->{up}			= $up;
	$ref->{down}		= $down;
	$ref->{sid1}		= $sid1; 
	$ref->{sid1_up}		= $sid1_up;
	$ref->{sid1_down}	= $sid1_down;
	$ref->{sid2}		= $sid2;
	$ref->{sid2_up}		= $sid2_up;
	$ref->{sid2_down}	= $sid2_down;
	$ref->{sid3}		= $sid3;
	$ref->{sid3_up}		= $sid3_up;
	$ref->{sid3_down}	= $sid3_down;
	$ref->{mns_type}	= $mns_type;
	$ref->{sts}			= 0;
	$ref->{database_type} = $database_type;
	
	
	
	#bless and return
	bless($ref, $class);
	return $ref;
}
 
 
sub make_cdr {
	my $this = shift;
	my @args = @_;
	return new gprscdr(@args);
}

#for printf
sub toStr{
	my $this = shift;
	
	my $str = sprintf "%s|" x 23, 
	$this->{row},$this->{no}, $this->{phone},$this->{imsi},$this->{apn},
	$this->{day},substr($this->{start}->toStr(),8,6),substr($this->{end}->toStr(),8,6),
	$this->{gip},$this->{sip},$this->{cid},$this->{up},$this->{down},
	$this->{sid1},$this->{sid1_up},$this->{sid1_down},
	$this->{sid2},$this->{sid2_up},$this->{sid2_down},
	$this->{sid3},$this->{sid3_up},$this->{sid3_down},
	$this->{mns_type},$this->{database_type};
	return $str;
}

#validate
sub validate{
	my $this = shift;
	my $fetcher = new gprsfetcher();		#A fetcher pass as argument
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
		my $checkresult =  remote('IG',$this->{phone},$this->{day},$this->{start}->toStr());
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
	
	#check if Centralized Payment DDN APN
	my $cp_ddn = $fetcher->check_CP_ddn_apn($this);
		return DBERRO     if ($local == DBERRO);
		return SQLERRO    if ($local == SQLERRO);
	if($cp_ddn != 0)
	{
		$this->{msisdn} = $this->{phone};
		$this->{phone} = $cp_ddn;
	}
	
	#call parent's validate
	my $re = $this->SUPER::validate();
	
	#errno check
	return $re if ($re ne 0);
	
	return 0;
}

#_compare
sub _comp {
	my $this = shift;
	my $other = shift;


	#basic compare rule: phone_number, start_time,end_time
	(return 0) if ($this->{start}->diff($other->{start})>maxdiff);
	(return 0) if ($this->{end}->diff($other->{end})>maxdiff);
	(return 0) if ($this->{phone} ne $other->{phone});
	
	#my @recodes = split(/,/,$other);
	
	
	
	#_compare its own part: opp number
	my $sts = 'OK';
	$sts .= '['.$other->{database_type}.']';
	($sts .= '[APN:'.$other->{apn}.']')          if (uc($this->{apn}) ne uc($other->{apn}));
	($sts .= '[GGSN IP:'.$other->{gip}.']')      if ($this->{gip} ne $other->{gip});
	($sts .= '[SGSN IP:'.$other->{sip}.']')      if ($this->{sip} ne $other->{sip});
	($sts .= '[Charge ID:'.$other->{cid}.']')    if ($this->{cid} ne $other->{cid});
	($sts .= '[UP Volume:'.$other->{up}.']')     if ($this->{up} ne $other->{up});
	($sts .= '[Down Volume:'.$other->{down}.']') if ($this->{down} ne $other->{down});
	($sts .= '[MNS_TYPE:'.$other->{mns_type}.']')	if ($this->{mns_type} ne $other->{mns_type});
	
	
	$this->{sts} = $sts;
	return 1;
}


1;