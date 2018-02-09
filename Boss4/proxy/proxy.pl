#!perl -w
package proxy;
# use strict; 
use Net::Config;
use SOAP::Transport::HTTP;
use DBI;
#add by wxt 20170410
use IO::Socket::INET;

SOAP::Transport::HTTP::CGI
-> dispatch_to('proxy')
-> handle;

 
sub fetch {
	my $this = shift;
	my ($db,$usr,$psw,$sql) = @_;
	my $dbh = DBI->connect('dbi:Oracle:'.$db,$usr,$psw,) ||
	return "1:$DBI::errstr";

	my $sth = $dbh->prepare($sql)
	or return "2:$DBI::errstr";
	$sth->execute()
	or return "3:$DBI::errstr";
	my $res=[];

	while (my $hash = $sth->fetchrow_hashref()) {
		push(@$res, $hash);
	}
	$sth->finish();
	$dbh->disconnect();
	return $res;
}


#add by wxt 20170410
#fetch from socket
sub fetchSocket {
	my $this = shift;
	my ($host,$port,$sql) = @_;
	
	my $socket = IO::Socket::INET->new(PeerAddr => $host,
	PeerPort =>$port,
	Proto => "tcp",
	Type =>SOCK_STREAM) 
	or return "1:Couldn't connect to $host:$port:$!";

#	sent qry by socket
	print $socket "$sql\n" or return "2:Send query failed:$!";
	
#	receive response from socket server
#{ "_id" : "20170409000451_28cbede69f0253cb561859bed328e277", "phone" : null, "apn" : null, "sip" : null, "cid" : "0", "mns_type" : null, "START" : "20170409000451", "duration" : 900, "up" : 0, "down" : 0 }
	my $res=[];
	while (<$socket>) {
		chomp;
		
		next if(!$_);
		next if(!($_ =~ /(\{.+\})/));
		$_ = $1;
		$_ =~ s/\s+//g;
		next if(length($_) == 0);
		$_ =~ s/{|}//g;
		
		my $resHash = {};
		my @params = split(/,/,$_);
		for(my $i = 0; $i < scalar @params; $i++) {
			
			my @rePara = split(/:/,$params[$i]);
			my $key = $rePara[0];
			my $val = $rePara[1];
			$val = $rePara[2] if(scalar @rePara  == 3);
			$key =~ s/\"//g;
			$val =~ s/\"//g;
			$val = '' if(uc($val) == 'NULL');
			if(scalar @rePara > 3){
				my $keyLen = length($key);
				$keyLen++;
				$val =  $params[$i] ;
				$$resHash{$key} = substr($params[$i],7,32);
			}


			#$val = '' if(uc($val) == 'NULL');
			$key = uc($key);
			$$resHash{$key} = $val;
		}
		push(@$res,$resHash);
	}

	close($socket);

	return $res;
}


sub fetchZy {
my $this = shift;
my $trunk = shift;

my $dbh = DBI->connect('dbi:Oracle:srv_zw1','ng3upd','boss4,dml',
{
AutoCommit => 0
}) || 
return "1111#$DBI::errstr";

my $sql;
my $sth;
$sql = qq (
CREATE  GLOBAL TEMPORARY TABLE solisyke_tempa (prod_name varchar2(64),prod_id number(8) )
ON COMMIT DELETE ROWS 
);
$sth = $dbh->do($sql) or return "1232#$DBI::errstr";
 
$sql = qq (
CREATE  GLOBAL TEMPORARY TABLE solisyke_tempbc (SPROM_ID varchar2(8),SO_ID number(15) )
ON COMMIT DELETE ROWS
);
$sth = $dbh->do($sql) or return "1233#$DBI::errstr";

$sql = qq (
insert into solisyke_tempa  (prod_name,prod_id) select a.prod_name,a.prod_id 
from cp.pm_products a  
where a.prod_id in (select distinct b.SPROM_ID from honghao.v_user_sprom_all b ,sunhq.v_user_pbx_all     c 
where b.serv_id = c.serv_id and c.IN_TRUNK in ('$trunk')  
and sysdate between c.valid_date and c.expire_date)
);
$sth = $dbh->do($sql) or return "1234#$DBI::errstr";

$sql = qq (
insert into solisyke_tempbc  (SPROM_ID,SO_ID) select  distinct b.SPROM_ID,b.SO_ID 
from honghao.v_user_sprom_all b ,sunhq.v_user_pbx_all c  
where b.serv_id = c.serv_id
and c.IN_TRUNK in ('$trunk')
and sysdate between c.valid_date and c.expire_date
);
$sth = $dbh->do($sql) or return "1235#$DBI::errstr";




$sql = qq (
select a.prod_name,d.SERV_ID,d.SPROM_PARA,
to_char(d.VALID_DATE,'yyyy-mm-dd hh24:mi:ss') VALID_DATE,
to_char(d.EXPIRE_DATE,'yyyy-mm-dd hh24:mi:ss') EXPIRE_DATE,d.SO_ID 
from sunhq.v_sprom_param_all d,solisyke_tempa a ,solisyke_tempbc bc 
where a.prod_id = bc.sprom_id and d.SO_ID = bc.so_id
);

 
$sth = $dbh->prepare($sql) 
or return "1236#$DBI::errstr";
$sth->execute()
or return "1237#$DBI::errstr";

my $res=[];
 

while (my $hash = $sth->fetchrow_hashref()) {
push(@$res, $hash);
}


$sql = 'DROP TABLE solisyke_tempbc';
$sth = $dbh->do($sql) or return "1238#$DBI::errstr";

$sql = 'DROP TABLE solisyke_tempa';
$sth = $dbh->do($sql) or return "1239#$DBI::errstr";

#$sth->finish() or return "$DBI::errstr";
#$dbh->disconnect() or return "$DBI::errstr";
 
return $res;
}
 



1;