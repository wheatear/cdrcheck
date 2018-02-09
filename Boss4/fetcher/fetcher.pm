package fetcher;
#An abstract strategy class for fetching result from data base

use lib qw(../lib);
use conf;
use util;
use Date;
use SOAP::Lite;
use strict;

#It is an abstrct class with no information
sub new{         
	my $class = shift;
	my $ref={};
	bless($ref, $class);
	return $ref;
}

#sub calss redifine this function, return a list reference
sub fetch{
	my $class = shift; 
	return [];
}

#check if anyone is local cdr
sub check_local {
	my $class = shift;
	my $cdr = shift;
	my ($phone,$opp) = ($cdr->{phone},$cdr->{opp});
	
	#check if local
	my $sql = qq(select count(*) cnt from zg.crm_user\@ZWDB where phone_id in ('$phone','$opp'));
	p_log("excecute $sql");
	
	#fetch from webservice
	my $re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetch(DB,USR,PSW,$sql)->result;
	
	(p_log($re) and return DBERRO)     if ($re =~ m/^1{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^2{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^3{1}/g);
	
	p_log("Find ".$re->[0]->{CNT}." Entry");
	return $re->[0]->{CNT};
}
#check if the apn is centralized payment ddn apn
sub check_CP_ddn_apn {
	my $class = shift;
	my $cdr = shift;
	my $apn = $cdr->{apn};
	
	#check if CP-DDN
	my $sql = qq(select phone_id PHONE from zg.crm_user\@ZWDB where serv_id=(select serv_id from aiop1.v_i_user_enterprise\@ZWDB where upper(operator_code) = upper('$apn') and expire_date>sysdate));
	p_log("excecute $sql");
	
	#fetch from webservice
	my $re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetch(DB,USR,PSW,$sql)->result;
	
	(p_log($re) and return DBERRO)     if ($re =~ m/^1{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^2{1}/g);
	(p_log($re) and return SQLERRO)    if ($re =~ m/^3{1}/g);
	return 0    if ($re == "");
	
	p_log("Find ".$re->[0]->{PHONE});
	return $re->[0]->{PHONE};
}	

1;