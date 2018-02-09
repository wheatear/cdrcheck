#!perl -w
package proxy;
# use strict; 
use Net::Config;
use SOAP::Transport::HTTP;
use DBI;
#add by wxt 20170410
use IO::Socket::INET;

#SOAP::Transport::HTTP::CGI
#-> dispatch_to('proxy')
#-> handle;







 
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
}

#add by wxt 20170410
#fetch from socket
sub fetchSocket {
#	my $this = shift;
	my ($host,$port,$sql) = @_;
#	print "Type => SOCK_STREAM \n";
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

		print "recv: $_\n";

		my $resHash = {};
		my @params = split(/,/,$_);
		for(my $i = 0; $i <= $#params; $i++) {
			
			my @rePara = split(/:/,$params[$i]);
			my $key = $rePara[0];
			my $val = $rePara[1];
			$val = $rePara[2] if(scalar @rePara  == 3);
			if(scalar @rePara > 3){
				my $keyLen = length($key);
				$keyLen++;
				$val =  substr($params[$i],$keyLen);
			}

			$key =~ s/\"//g;
			$val =~ s/\"//g;
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
 


#test part

print "starting...\n";
my $host = "10.4.87.60";
my $port = "20210";

my $aSql = [];

#my $day = '20170418';
#my $phone = "13426208711";
#my $durStart = "20170418000000";
#my $durEnd = "20170418011259";
#my $msisdn = "13426208711";
#my $u_num = "13426208711";
#my $opp = "13426208711";
#my $dStart = '3697';
#my $dEnd = '3603';
#my $sql = qq ({"QUERYTYPE":"2","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$durStart","END_TIME":"$durEnd","RETURNTYPE":"socket"});


my $day = '20170418';
my $phone = "13426208711";
my $durStart = "20170418000000";
my $durEnd = "20170418011259";
my $msisdn = "13426208711";
my $u_num = "13426208711";
my $opp = "13520498010";
my $dStart = '3697';
my $dEnd = '3603';

#2:DATE : 20170417 USER_NUMBER:15711257029 START_TIME:"20170417000000" END_TIME:"20170417235959" 
#3:DATE : 20170417 USER_NUMBER:15711257029 START_TIME:"20170417000000" END_TIME:"20170417235959",MEMBER_MSISDN:null 
#6:DATE : 20170417 USER_NUMBER:13522063500 START_TIME:"20170417000000" END_TIME:"20170417235959"
#7:DATE:\"20170417\",USER_NUMBER:\"13522063500\",OPP_NUMBER:\"18612944141\",START_TIME:\"20170417000000\",END_TIME:\"20170417235959\",DURATION_START:0,DURATION_END:100,PHONE:null
#{"QUERYTYPE":"7","DATE":"20170417","USER_NUMBER":"13522063500","OPP_NUMBER":"18612944141","START_TIME":"20170417000000","END_TIME":"20170417235959","DURATION_START":"0","DURATION_END":"100","PHONE":"null","RETURNTYPE":"socket"}
	
my $sql2 = qq ({"QUERYTYPE":"2","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$durStart","END_TIME":"$durEnd","RETURNTYPE":"socket"});


#$sql = qq ({"QUERYTYPE":"3","DATE":"20170417","USER_NUMBER":"15711257029","START_TIME":"20170417000000","END_TIME":"20170417235959","MEMBER_MSISDN":"null","RETURNTYPE":"socket"});
#3:DATE : 20170417 USER_NUMBER:15711257029 START_TIME:"20170417000000" END_TIME:"20170417235959",MEMBER_MSISDN:null 
$day = '20170417';
$phone = "15711257029";
$durStart = "20170417000000";
$durEnd = "20170417235959";
$msisdn = "null";
my $sql3 = qq ({"QUERYTYPE":"3","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$durStart","END_TIME":"$durEnd","MEMBER_MSISDN":"$msisdn","RETURNTYPE":"socket"});
#push(@$aSql,$sql);

# $sql = qq ({"QUERYTYPE":"4","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$durStart","END_TIME":"$durEnd","RETURNTYPE":"socket"});
#push(@$aSql,$sql);
# $sql = qq ({"QUERYTYPE":"5","DATE":"$day","USER_NUMBER":"$phone","START_TIME":"$durStart","END_TIME":"$durEnd","MEMBER_MSISDN":"$msisdn","RETURNTYPE":"socket"});
#push(@$aSql,$sql);

#6:DATE : 20170417 USER_NUMBER:13522063500 START_TIME:"20170417000000" END_TIME:"20170417235959"
$day = '20170418';
$phone = "13426208711";
$opp = "13910156485";
$durStart = "20170418091904";
$durEnd = "20170418091924";
#$day = '20170417';
#$phone = "15711257029";
#$opp = "15711257029";
#$durStart = "20170417000000";
#$durEnd = "20170417235959";
#13426208711	13910156485		20170418	091914	092155
#my $sql6 = qq ({"QUERYTYPE":"6","DATE":"$day","PHONE":"$phone","OPP":"$opp","START_TIME":"$durStart","END_TIME":"$durEnd","RETURNTYPE":"socket"});
#push(@$aSql,$sql);

#7:DATE:\"20170417\",USER_NUMBER:\"13522063500\",OPP_NUMBER:\"18612944141\",START_TIME:\"20170417000000\",END_TIME:\"20170417235959\",DURATION_START:0,DURATION_END:100,PHONE:null
$day = '20170417';
$u_num = "13522063500";
$opp = "18612944141";
$durStart = "20170417000000";
$durEnd = "20170417015959";
$dStart = "0";
$dEnd = "100";
$phone = "null";
my $sql7 = qq ({"QUERYTYPE":"7","DATE":"$day","USER_NUMBER":"$u_num","OPP_NUMBER":"$opp","START_TIME":"$durStart","END_TIME":"$durEnd","DURATION_START":"$dStart","DURATION_END":"$dEnd","PHONE":"$phone","RETURNTYPE":"socket"});
my $sql7 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"15713595036","START_TIME":"20170424092751","END_TIME":"20170424092801","DURATION_START":"313","DURATION_END":"319","PHONE":"95522","RETURNTYPE":"socket"});

#my $sql72 = qq ({"QUERYTYPE":"7","DATE":"20170423","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});
#my $sql73 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"15713595036","START_TIME":"20170424092751","END_TIME":"20170424092801","DURATION_START":"313","DURATION_END":"319","PHONE":"95522","RETURNTYPE":"socket"});

my $sql72 = qq ({"QUERYTYPE":"7","DATE":"20170423","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});
my $sql73 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});
my $sql74 = qq ({"QUERYTYPE":"7","DATE":"20170423","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});
my $sql75 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});
my $sql76 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});

#push(@$aSql,$sql72);
#push(@$aSql,$sql73);
#push(@$aSql,$sql74);
#push(@$aSql,$sql75);
#push(@$aSql,$sql76);

my $sql710 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"15713595036","START_TIME":"20170424092751","END_TIME":"20170424092801","DURATION_START":"313","DURATION_END":"319","PHONE":"95522","RETURNTYPE":"socket"});
my $sql711 = qq ({"QUERYTYPE":"7","DATE":"20170425","USER_NUMBER":"26001920203","OPP_NUMBER":"15713595036","START_TIME":"20170424092751","END_TIME":"20170424092801","DURATION_START":"313","DURATION_END":"319","PHONE":"95522","RETURNTYPE":"socket"});
my $sql712 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"15713595036","START_TIME":"20170424092751","END_TIME":"20170424092801","DURATION_START":"313","DURATION_END":"319","PHONE":"95522","RETURNTYPE":"socket"});

#push(@$aSql,$sql710);
#push(@$aSql,$sql711);
#push(@$aSql,$sql712);
my $sql22 = qq ({"QUERYTYPE":"2","DATE":"20170427","USER_NUMBER":"18201324313","START_TIME":"20170517000000","END_TIME":"20170517234837","RETURNTYPE":"socket"});
push(@$aSql,$sql22);

#push(@$aSql,$sql2);
#push(@$aSql,$sql3);
#push(@$aSql,$sql6);
#push(@$aSql,$sql7);

#foreach my $s (@$aSql) {
#	print "$s\n";
#}

for (my $k = 0; $k < scalar @$aSql; $k++) {
	print "send: ,$host,$port,$$aSql[$k]\n";
	my $re = fetchSocket($host,$port,$$aSql[$k]);

#	print("@$re\n");

	print "$re\n"     if ($re =~ m/^1{1}/g);
	print "$re\n"    if ($re =~ m/^2{1}/g);
	print "$re\n"    if ($re =~ m/^3{1}/g);

	print("Fetch ".(scalar @$re)." Records\n");

	foreach (@$re) {
#		my $reDura = $_->{DURATION};
#		my $reStart = $_->{START};
#		my $reEnd = new Date($reStart);
#		$reEnd->add($reDura);

#		$_ = [1,1.1,1,1,$_->{PHONE},$_->{OPP},$_->{THIRD},$_->{DAY},$_->{START},$_->{DURATION},$_->{CHU}];

		print "re_$k:";
		while(($reKey,$reVal) = each(%$_)) {
			print "$reKey:$reVal, ";
		}
		print "\n";
	}
}

1;


