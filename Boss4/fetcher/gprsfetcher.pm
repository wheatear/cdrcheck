package gprsfetcher;
#fetch voice cdr
use lib qw(../lib);
use SOAP::Lite;
use conf;
use util;
use Date;
use fetcher;

#inherited from fetcher class
@ISA = qw(fetcher);

use strict;

 
sub fetch{
	my $class = shift; 
	my $cdr   = shift;
	my $day   = shift;				#specify a day
	my ($phone,$start,$msisdn) = ($cdr->{phone},$cdr->{start}->toStr(),$cdr->{msisdn});
	my $re = [];
	my $re1 = [];
	my $re2 = [];
	$start		=	"to_date(\'$start\', \'yyyymmddhh24miss\')";
	
		#fetch from webservice . add by wxt 20170412
	my $dayBegn = $cdr->{start}->copy();
	my $dayEnd = $cdr->{start}->copy();
	$dayBegn->add(-10);
	$dayEnd->add(10);
	my $startBegn = $dayBegn->toStr();
	my $startEnd = $dayEnd->toStr();
	
	#local sql
	#-------------------------------------------离线库查询---------------------------------------------------------------
#	my $sql = qq (
#	select t.user_number                                            phone,
#	to_char(t.start_time, 'yyyymmdd')                               day,
#	t.apn_ni                                                        apn,
#	t.ggsn_address                                                  gip,
#	t.sgsn_address                                                  sip,
#	charging_id                                                     cid,
#	nvl(data_flow_up1,0)+nvl(data_flow_up2,0)                       up,
#	nvl(data_flow_down1,0)+nvl(t.data_flow_down2,0)                 down,
#	mns_type														mns_type,
#	to_char(t.start_time, 'hh24miss')								"START",
#	to_char(t.start_time+t.duration/(24*60*60),'hh24miss')			end
#	from jf.dr_ps_100_$day t
#	where  t.user_number = '$phone'
#	and    start_time between $start-10/(24*60*60) and $start+10/(24*60*60) 
#	order by t.start_time
#	);
	#	re:QueryType 2,PUSER_NUMBER,PSTART_TIME,PEND_TIME
	#	qq ({"QUERYTYPE":"2","DATE":"20170409","USER_NUMBER":"13439448871","START_TIME":"20170409000000","END_TIME":"20170409001259","RETURNTYPE":"socket"});
	my $sql = qq ({"QUERYTYPE":"2","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$startBegn","END_TIME":"$startEnd","RETURNTYPE":"socket"});
 
	#对于集团统付的DDN APN,用下面的语句验证
	if($msisdn){
#	$sql = qq (
#	select t.member_msisdn                                            phone,
#	to_char(t.start_time, 'yyyymmdd')                               day,
#	t.apn_ni                                                        apn,
#	t.ggsn_address                                                  gip,
#	t.sgsn_address                                                  sip,
#	charging_id                                                     cid,
#	nvl(data_flow_up1,0)+nvl(data_flow_up2,0)                       up,
#	nvl(data_flow_down1,0)+nvl(t.data_flow_down2,0)                 down,
#	mns_type														mns_type,
#	to_char(t.start_time, 'hh24miss')								"START",
#	to_char(t.start_time+t.duration/(24*60*60),'hh24miss')			end
#	from jf.dr_ps_100_$day t
#	where  t.user_number = '$phone'
#	and    start_time between $start-10/(24*60*60) and $start+10/(24*60*60)
#	and member_msisdn='$msisdn'
#	order by t.start_time
#	);
	#	re:QueryType 3,PUSER_NUMBER,PSTART_TIME,PEND_TIME,PMEMBER_MSISDN
	#	qq ({"QUERYTYPE":"2","DATE":"20170409","USER_NUMBER":"13439448871","START_TIME":"20170409000000","END_TIME":"20170409001259","RETURNTYPE":"socket"});
	$sql = qq ({"QUERYTYPE":"3","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$startBegn","END_TIME":"$startEnd","MEMBER_MSISDN":"$msisdn","RETURNTYPE":"socket"});
 
	}
	p_log("excecute $sql");
	
	#fetch from webservice
#	$re = SOAP::Lite
#	-> uri(URI)
#	-> proxy(PROXY)
#	-> fetch(DB,USR,PSW,$sql)->result;
	$re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetchSocket(SK_HOST,SK_PORT,$sql)->result;
	#p_log($re);
	
	
	return DBERRO     if ($re =~ m/^1{1}/g);
	return SQLERRO    if ($re =~ m/^2{1}/g);
	return SQLERRO    if ($re =~ m/^3{1}/g);
	
	p_log("Fetch ".(scalar @$re)." Records");
	
	#construct arguments
	foreach (@$re) {
		my $reDura = $_->{DURATION};
		my $reStart = $_->{START};
		my $reEnd = new Date($reStart);
		my $startTime = substr($reEnd->toStr(),8,6);
		$reEnd->add($reDura);
		my $endTime = substr($reEnd->toStr(),8,6);
		
		$_ = [1,1,$_->{PHONE},1,$_->{APN},$_->{DAY},$startTime,$endTime,
		hex2dec($_->{GIP}),hex2dec($_->{SIP}),$_->{CID},$_->{UP},$_->{DOWN},1,1,1,1,1,1,1,1,1,$_->{MNS_TYPE},'离线'];
		
	}
	p_log(@$re);
	
	
	#---------------------------------------实时库查询----------------------------------------------------------------------------------
	my $sql1 = qq (
	select t.user_number                                            phone,
	to_char(t.start_time, 'yyyymmdd')                               day,
	t.apn_ni                                                        apn,
	t.ggsn_address                                                  gip,
	t.sgsn_address                                                  sip,
	charging_id                                                     cid,
	nvl(data_flow_up1,0)+nvl(data_flow_up2,0)                       up,
	nvl(data_flow_down1,0)+nvl(t.data_flow_down2,0)                 down,
	mns_type														mns_type,
	to_char(t.start_time, 'hh24miss')								"START",
	to_char(t.start_time+t.duration/(24*60*60),'hh24miss')			end
	from qk.dr_ocsps_100_$day t
	where  t.user_number = '$phone'
	and    start_time between $start-10/(24*60*60) and $start+10/(24*60*60) 
	order by t.start_time
	);
	#	re:QueryType 4,PUSER_NUMBER,PSTART_TIME,PEND_TIME
	#	qq ({"QUERYTYPE":"2","DATE":"20170409","USER_NUMBER":"13439448871","START_TIME":"20170409000000","END_TIME":"20170409001259","RETURNTYPE":"socket"});
#	my $sql1 = qq ({"QUERYTYPE":"4","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$startBegn","END_TIME":"$startEnd","RETURNTYPE":"socket"});
 
	
	#对于集团统付的DDN APN,用下面的语句验证
	if($msisdn){
	$sql1 = qq (
	select t.member_msisdn                                            phone,
	to_char(t.start_time, 'yyyymmdd')                               day,
	t.apn_ni                                                        apn,
	t.ggsn_address                                                  gip,
	t.sgsn_address                                                  sip,
	charging_id                                                     cid,
	nvl(data_flow_up1,0)+nvl(data_flow_up2,0)                       up,
	nvl(data_flow_down1,0)+nvl(t.data_flow_down2,0)                 down,
	mns_type														mns_type,
	to_char(t.start_time, 'hh24miss')								"START",
	to_char(t.start_time+t.duration/(24*60*60),'hh24miss')			end
	from qk.dr_ocsps_100_$day t
	where  t.user_number = '$phone'
	and    start_time between $start-10/(24*60*60) and $start+10/(24*60*60)
	and member_msisdn='$msisdn'
	order by t.start_time
	);
	#	re:QueryType 5,PUSER_NUMBER,PSTART_TIME,PEND_TIME,PMEMBER_MSISDN
#	$sql1 = qq ({"QUERYTYPE":"5","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$startBegn","END_TIME":"$startEnd","MEMBER_MSISDN":"$msisdn","RETURNTYPE":"socket"});
 
	}
	p_log("excecute $sql1");
	
	#fetch from webservice
	$re1 = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetch(DB,USR,PSW,$sql1)->result;
	
#	fetch from socket server, add by wxt 20170412
#	$re = SOAP::Lite
#	-> uri(URI)
#	-> proxy(PROXY)
#	-> fetchSocket(SK_HOST,SK_PORT,$sql)->result;
	#p_log($re1);
	
	#如果第二次查询出现错误，则直接返回第一次的查询结果
	return $re     if ($re1 =~ m/^1{1}/g);
	return $re     if ($re1 =~ m/^2{1}/g);
	return $re     if ($re1 =~ m/^3{1}/g);
	
	p_log("Fetch ".(scalar @$re1)." Records");
	
	#construct arguments
	foreach (@$re1) {
		my $reDura = $_->{DURATION};
		my $reStart = $_->{START};
		my $reEnd = new Date($reStart);
		$reEnd->add($reDura);
		
		$_ = [1,1,$_->{PHONE},1,$_->{APN},$_->{DAY},$_->{START},$reEnd->toStr(),
		hex2dec($_->{GIP}),hex2dec($_->{SIP}),hex($_->{CID}),$_->{UP},$_->{DOWN},1,1,1,1,1,1,1,1,1,$_->{MNS_TYPE},'实时'];
		
	}
	p_log(@$re1);
	
	#将第一次和第二次的查询结果连接起来
	@$re2=(@$re,@$re1);
	p_log(@$re2);
	return $re2;
}
 
1;