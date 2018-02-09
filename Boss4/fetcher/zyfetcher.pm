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
	order by valid_date desc
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
	return TRKERRO if ($sid == 0);			
	p_log("$tid:$sid");

	#search cdr
	p_log("Connect to ".USR."@".DB);
	
	$start = "to_date(\'$start\', \'yyyymmddhh24miss\')";
	$end = "to_date(\'$end\', \'yyyymmddhh24miss\')";
	#根据serv_id查找user_number,然后使用联合索引查询话单
	my $sql = qq (select floor(min(msisdn)) PHONE from aiop1.v_i_user\@ZWDB where serv_id='$sid' and expire_date>sysdate);
	p_log("$sql");
	my $re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetch(DB,USR,PSW,$sql)->result;
	my $u_num = $re->[0]->{PHONE};
	p_log("msisdn: $u_num");
	
#	$sql = qq (
#	select
#	phone,opp,day,  SSS "START",  end ,sts
#	from (
#	Select 
#	member_msisdn																				phone,
#	opp_number																					opp,
#	to_char(start_time,'yyyymmdd')																day,
#	to_char(start_time,'yyyymmddhh24miss')														SSS,
#	to_char(start_time+duration/(24*60*60),'yyyymmddhh24miss')									end,
#	'[basic:'||t.charge1/1000||']'||'[long:'||t.charge2/1000||']'||'[info:'||charge4/1000||']'	sts
#	from jf.dr_cs_100_$day t where  user_number='$u_num' 
#	and opp_number='$opp'
#	and start_time between $start-5/(24*60*60) and $start+5/(24*60*60)
#	and start_time+duration/(24*60*60) between $end-5/(24*60*60) and $end+5/(24*60*60)
#	and member_msisdn like '%$phone%'
#	order by start_time
#	) );

	#fetch from socket server . add by wxt 20170412
	my $dayBegn = $cdr->{start}->copy();
	my $dayEnd = $cdr->{start}->copy();
	$dayBegn->add(-5);
	$dayEnd->add(5);
	my $startBegn = $dayBegn->toStr();
	my $startEnd = $dayEnd->toStr();

	my $dura = $cdr->{end}->diff($cdr->{start});
	my $dStart = $dura - 3;
	my $dEnd = $dura + 3;
	
# re:PUSER_NUMBER,POPP_NUMBER,PSTART_TIME,PEND_TIME,PDURATION_START,PDURATION_END,PPHONE
# rsp:phone,opp,day,SSS
#	qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});
#	my $sql = qq ({"QUERYTYPE":"7","DATE":"$day","USER_NUMBER":"$u_num","OPP_NUMBER":"$opp","START_TIME":"$startBegn","END_TIME":"$startEnd","DURATION_START":"$dStart","DURATION_END":"$dEnd","RETURNTYPE":"socket"});
	my $sql = qq ({"QUERYTYPE":"7","DATE":"$day","USER_NUMBER":"$u_num","OPP_NUMBER":"$opp","START_TIME":"$startBegn","END_TIME":"$startEnd","DURATION_START":"$dStart","DURATION_END":"$dEnd","PHONE":"$phone","RETURNTYPE":"socket"});

	p_log("excecute $sql");
	
	#fetch from webservice
	$re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetchSocket(SK_HOST,SK_PORT,$sql)->result;
	
	(p_log("mongo return: $re") and return DBERRO)     if ($re =~ m/^1{1}/g);
	(p_log("mongo return: $re") and return SQLERRO)    if ($re =~ m/^2{1}/g);
	(p_log("mongo return: $re") and return SQLERRO)    if ($re =~ m/^3{1}/g);
	
	p_log("Fetch ".(scalar @$re)." Records");           
	foreach (@$re) {
		my $reDura = $_->{DURATION};
		my $reStart = $_->{SSS};
		my $reEnd = new Date($reStart);
		my $startTime = substr($reEnd->toStr(),8,6);
		$reEnd->add($reDura);
		my $endTime = $reEnd->toStr();
		
		my $ssts = $_->{STS};
		p_log("Fetch 1,$tid,$_->{PHONE},$_->{OPP},$_->{DAY},$reStart,$endTime,$ssts");
#		my $phone = $_->{PHONE};
#		$phone =~ s/^(86|\d+-|010)//g;
#		$_ = [1,$tid,$phone,$_->{OPP},$_->{DAY},$startTime,$endTime,$_->{STS}];
		$_ = [1,$tid,$_->{PHONE},$_->{OPP},$_->{DAY},$reStart,$endTime,$_->{STS}];
	}
	return $re;
}
 
1;