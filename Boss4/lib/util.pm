package util;
#SOME util function irrelevant to calss goes here

 
use Time::Local;
use POSIX qw(strftime); 
use conf;
 
use IO::Socket;
use IO::Handle;
use SOAP::Lite;

require Exporter;
@ISA = qw(Exporter);		
@EXPORT = qw(p_log swap remote
PHONE_ERR START_ERR END_ERR DAY_ERR EMP
OPP_ERR THIRD_ERR IMSI_ERR APN_ERR GIP_ERR SIP_ERR CID_ERR UP_ERR DOWN_ERR 
SID1_ERR SID1UP_ERR SID1DOWN_ERR  NO_ERR
SID2_ERR SID2UP_ERR SID2DOWN_ERR 
SID3_ERR SID3UP_ERR SID3DOWN_ERR
DBERRO SQLERRO TRKERRO UPLOAD_ERR INIERR FILERR FERR
maxdiff
hex2dec
READY
);


use strict;
use warnings;

use Frontier::Client;
 
 
#ALL THE exception defined here
#cdrexception
use constant PHONE_ERR		=> 1001;
use constant START_ERR		=> 1002;
use constant END_ERR		=> 1003;
use constant DAY_ERR        => 1005;
use constant NO_ERR         => 1006;
use constant OPP_ERR		=> 1004;
use constant THIRD_ERR      => 1007;
use constant EMP		    => 1008;
use constant IMSI_ERR		=> 1009;
use constant APN_ERR 		=> 1010;
use constant GIP_ERR 		=> 1011;
use constant SIP_ERR 		=> 1012;
use constant CID_ERR 		=> 1013;
use constant UP_ERR  		=> 1014;
use constant DOWN_ERR		=> 1015;
use constant SID1_ERR		=> 1016;
use constant SID1UP_ERR		=> 1017;
use constant SID1DOWN_ERR   => 1018;
use constant SID2_ERR       => 1019;
use constant SID2UP_ERR     => 1020;
use constant SID2DOWN_ERR   => 1021;
use constant SID3_ERR       => 1022;
use constant SID3UP_ERR     => 1023;
use constant SID3DOWN_ERR   => 1024;


#excel exception
use constant INIERR => 100;					#can not initialization
use constant FILERR => 101;					#can not read file
use constant FERR   => 102;					#format erro


#DB exception
use constant DBERRO  	=> 200;				#DB FAIL
use constant SQLERRO	=> 201;				#SQL FAIL
use constant TRKERRO 	=> 202;				#trunck not exist
use constant UPLOAD_ERR => 203;				#upload fail


#tolarable difference
use constant maxdiff	=> 5; 

#the status flag
use constant	READY	=>	"0x81394";


 
#logging
sub p_log {
	my $content = shift;
	open(my $fd, ">>".conf::LogDir."/".conf::PLOG);
	
	my $now = time;
	my $time = strftime("[%Y-%m-%d %H:%M:%S]: ", localtime $now);
	print $fd $time.$content."\n";
	close $fd;
}

#exchange
sub swap {
	my $a = shift;
	my $b = shift;
	my $t = $$a;
	$$a = $$b;
	$$b = $t;
}

#fetch result from remote server
sub old_remote{
	my ($type,$phone,$day,$time) = @_;
	socket(SOCKFH,AF_INET,SOCK_STREAM,0) or (p_log("Socket Fail $!") && return -1);
	
	my $addr = inet_aton(SERVER);
	p_log("Connect to ".SERVER.":".SERVERPORT);
	my $packed_addr = pack_sockaddr_in(SERVERPORT,$addr);
	
	connect(SOCKFH,$packed_addr) or (p_log("Connect Fail $!") && return -1);
	
	my $buf = pack("A4 A32 A32 A32",$type,$phone,$day,$time);
	syswrite(SOCKFH,$buf,length($buf)) or (p_log("Write Fail $!") && return -1);
	
	my $recv;
	
	sysread(SOCKFH,$recv,32) or (p_log("Read Fail $!") && return -1);
	
	return $recv;
}

#fetch result from remote server
sub remote{
	my ($type,$phone,$day,$time) = @_;
	my $res = eval {
		my $client = new Frontier::Client(
			url			=>	verifyUrl
		);
		
		my $arg = {
			dirFmt	=>		dirFmt,
			phone	=>		$phone,
			type	=>		$type,
			day		=>		$day,
			time	=>		$time
		};
		
		
		$client->call(verifyMethod,$arg);		
	};
	
	if (!(defined $res)) {
		p_log($@);
	}
	return $res;
}


#16to10
sub hex2dec{
	my $str = shift;
	return hex(substr($str,0,2)).".".hex(substr($str,2,2)).".".
		hex(substr($str,4,2)).".".hex(substr($str,6,2));
}



1;