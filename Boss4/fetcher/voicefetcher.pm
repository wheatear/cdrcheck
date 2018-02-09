package voicefetcher;
#fetch voice cdr
use lib qw(../lib);
use SOAP::Lite;
use conf;
use util;
use Date;
use fetcher;

#add by wxt 20170410
use IO::Socket::INET;


#inherited from fetcher class
@ISA = qw(fetcher);

use strict;

 
#sub fetch{
#	my $class = shift; 
#	my $cdr   = shift;
#	my $day   = shift;				#specify a day
#	my ($phone,$opp,$start) = ($cdr->{phone},$cdr->{opp},$cdr->{start}->toStr());
#	my $re = [];
#	$start		=	"to_date(\'$start\', \'yyyymmddhh24miss\')";
#	my $sql  =  qq (
#	Select
#	t.user_number                                         phone,
#	t.opp_number                                          opp,
#	t.a_number                                            third,
#	to_char(t.start_time,'yyyymmdd')                      day, 
#	to_char(t.start_time,'hh24miss')                      "START", 
#	to_char(t.start_time+duration/(24*60*60),'hh24miss')  "END",
#	t.original_file                                       chu
#	from jf.dr_cs_100_$day t
#	where
#	user_number in\('$phone','$opp'\) 
#	and    start_time between $start-10/(24*60*60) and $start+10/(24*60*60) 
#	order by t.start_time);
# 
#	p_log("excecute $sql");
#	
#	#fetch from webservice
#	$re = SOAP::Lite
#	-> uri(URI)
#	-> proxy(PROXY)
#	-> fetch(DB,USR,PSW,$sql)->result;
#	
#	p_log($re);
#	
#	return DBERRO     if ($re =~ m/^1{1}/g);
#	return SQLERRO    if ($re =~ m/^2{1}/g);
#	return SQLERRO    if ($re =~ m/^3{1}/g);
#	
#	p_log("Fetch ".(scalar @$re)." Records");
#	
#	foreach (@$re) {
#		$_ = [1,1.1,1,1,$_->{PHONE},$_->{OPP},$_->{THIRD},$_->{DAY},$_->{START},$_->{END},$_->{CHU}];
#	}
#	return $re;
#}

#add by wxt 20170412
#fetch from socket server by zhoubo
sub fetch{
	my $class = shift; 
	my $cdr   = shift;
	my $day   = shift;				#specify a day
	my ($phone,$opp,$start) = ($cdr->{phone},$cdr->{opp},$cdr->{start}->toStr());
	my $re = [];
#	$start		=	"to_date(\'$start\', \'yyyymmddhh24miss\')";
#	my $sql  =  qq (
#	Select
#	t.user_number                                         phone,
#	t.opp_number                                          opp,
#	t.a_number                                            third,
#	to_char(t.start_time,'yyyymmdd')                      day, 
#	to_char(t.start_time,'hh24miss')                      "START", 
#	to_char(t.start_time+duration/(24*60*60),'hh24miss')  "END",
#	t.original_file                                       chu
#	from jf.dr_cs_100_$day t
#	where
#	user_number in\('$phone','$opp'\) 
#	and    start_time between $start-10/(24*60*60) and $start+10/(24*60*60) 
#	order by t.start_time);
	
	#fetch from webservice . add by wxt 20170412
	my $dayBegn = $cdr->{start}->copy();
	my $dayEnd = $cdr->{start}->copy();
	$dayBegn->add(-10);
	$dayEnd->add(10);
	my $startBegn = $dayBegn->toStr();
	my $startEnd = $dayEnd->toStr();
	
#	re:QUERYTYPE 6,PPHONE,POPP,PSTART_TIME,PEND_TIME
#	rsp:phone,opp,third,day,START,duration,chu
#	qq ({"QUERYTYPE":"2","DATE":"20170409","USER_NUMBER":"13439448871","START_TIME":"20170409000000","END_TIME":"20170409001259","RETURNTYPE":"socket"});
	my $sql = qq ({"QUERYTYPE":"6","DATE":"$day","PHONE":"$phone","OPP":"$opp","START_TIME":"$startBegn","END_TIME":"$startEnd","RETURNTYPE":"socket"});

	p_log("excecute $sql");
	
	#fetch from webservice

	$re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetchSocket(SK_HOST,SK_PORT,$sql)->result;
	
	p_log($re);
	
	return DBERRO     if ($re =~ m/^1{1}/g);
	return SQLERRO    if ($re =~ m/^2{1}/g);
	return SQLERRO    if ($re =~ m/^3{1}/g);
	
	p_log("Fetch ".(scalar @$re)." Records");
	
	foreach (@$re) {
		my $reDura = $_->{DURATION};
		my $reStart = $_->{START};
		my $reEnd = new Date($reStart);
		my $startTime = $reEnd->toStr();
		my $startTime = substr($startTime,8,6);
		$reEnd->add($reDura);
		my $endTime = substr($reEnd->toStr(),8,6);
		
		$_ = [1,1.1,1,1,$_->{PHONE},$_->{OPP},$_->{THIRD},$_->{DAY},$startTime,$endTime,$_->{CHU}];
	}
	return $re;
}

1;
