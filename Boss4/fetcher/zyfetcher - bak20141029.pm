package zyfetcher;
#fetch zy cdr
use lib qw(../lib);
use SOAP::Lite;
use conf;
use util;
use Date;
use fetcher;

#inherited from fetcher class
@ISA = qw(fetcher);

use strict;

#fetch infomation of tid, return 0 indicating non-exist tid
sub _fetch_sid {
	my $class = shift;
	my $tid = shift;
	my $sql = qq (
	select serv_id  from sunhq.v_user_pbx_all\@ZWDB
	where IN_TRUNK in ('$tid') and sysdate between valid_date and expire_date
	);
	p_log("excecute $sql");
	 
	#fetch from webservice
	my $re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetch(DB,USR,PSW,$sql)->result;
	
	
	(p_log($re) and return DBERRO)     if ($re =~ m/^1{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^2{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^3{1}/g);
	(p_log("$tid not exist") and return 0) if (!$re);
	
	return $re->[0]->{SERV_ID};

}
 
sub fetch{
	my $class = shift; 
	my $cdr = shift;
	my $day = shift;
	my ($tid,$phone,$opp,$start,$end) = ($cdr->{tid},$cdr->{phone},$cdr->{opp},$cdr->{start}->toStr(),$cdr->{end}->toStr());

	#fetch sid
	my $sid = $class->_fetch_sid($tid);
	#non-exist tid return 0
	return 0 if ($sid == 0);			
	p_log("$tid:$sid");

	#search cdr
	p_log("Connect to ".USR."/".PSW."@".DB);
	
	$start = "to_date(\'$start\', \'yyyymmddhh24miss\')";
	$end = "to_date(\'$end\', \'yyyymmddhh24miss\')";
	my $sql = qq (
	select
	phone,opp,day,  SSS "START",  end ,sts
	from (
	Select 
	member_msisdn																				phone,
	opp_number																					opp,
	to_char(start_time,'yyyymmdd')																day,
	to_char(start_time,'yyyymmddhh24miss')														SSS,
	to_char(start_time+duration/(24*60*60),'yyyymmddhh24miss')									end,
	'[basic:'||t.charge1/1000||']'||'[long:'||t.charge2/1000||']'||'[info:'||charge4/1000||']'	sts
	from jf.dr_cs_100_$day t where  user_id='$sid' 
	) 
	where  (phone like '%$phone%'  or phone like '%$opp%')
	and    to_date(SSS,'yyyymmddhh24miss') between $start-5/(24*60*60) and $start+5/(24*60*60)  
	and    to_date(end,'yyyymmddhh24miss') between $end-5/(24*60*60) and $end+5/(24*60*60)  
	order by   SSS
	);
	
	p_log("excecute $sql");
	
	#fetch from webservice
	my $re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetch(DB,USR,PSW,$sql)->result;
	
	(p_log($re) and return DBERRO)     if ($re =~ m/^1{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^2{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^3{1}/g);
	
	p_log("Fetch ".(scalar @$re)." Records");           
	foreach (@$re) {
		$_ = [1,$tid,$_->{PHONE},$_->{OPP},$_->{DAY},$_->{START},$_->{END},$_->{STS}];
	}
	return $re;
}
 
1;