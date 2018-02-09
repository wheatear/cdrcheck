package zyfetcher;
#fetch zy cdr
use lib qw(../lib);
use SOAP::Lite;
use conf;
use util;
use Date;
use fetcher;

#inherited from fetcher class
#@ISA = qw(fetcher);

use strict;


#my $sql = qq ({"QUERYTYPE":"7","DATE":"$day","USER_NUMBER":"$u_num","OPP_NUMBER":"$opp","START_TIME":"$startBegn","END_TIME":"$startEnd","DURATION_START":"$dStart","DURATION_END":"$dEnd","PHONE":"$phone","RETURNTYPE":"socket"});
my $sql = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"15713595036","START_TIME":"20170424092751","END_TIME":"20170424092801","DURATION_START":"313","DURATION_END":"319","PHONE":"95522","RETURNTYPE":"socket"});
my $sql7 = qq ({"QUERYTYPE":"7","DATE":"20170424","USER_NUMBER":"26001920203","OPP_NUMBER":"13482790424","START_TIME":"20170423235238","END_TIME":"20170423235248","DURATION_START":"164","DURATION_END":"170","PHONE":"95522","RETURNTYPE":"socket"});
my $sql2 = qq ({"QUERYTYPE":"2","DATE":"20170517","USER_NUMBER":"18201324313","START_TIME":"20170516000000","END_TIME":"20170517234837","RETURNTYPE":"socket"});
my $sql6 = qq ({"QUERYTYPE":"6","DATE":"20170519","PHONE":"13810448251","OPP":"0085234234010","START_TIME":"20170519031832","END_TIME":"20170519031852","RETURNTYPE":"socket"});

$sql = $sql6;

	print("excecute $sql \n");
	
	#fetch from webservice
	my $re = SOAP::Lite
	-> uri(URI)
	-> proxy(PROXY)
	-> fetchSocket("10.4.87.60","20210",$sql)->result;
	
	(print("mongo return: $re") and return DBERRO)     if ($re =~ m/^1{1}/g);
	(print("mongo return: $re") and return SQLERRO)    if ($re =~ m/^2{1}/g);
	(print("mongo return: $re") and return SQLERRO)    if ($re =~ m/^3{1}/g);
	
	print("Fetch ".(scalar @$re)." Records\n");           
	foreach (@$re) {
		my $reDura = $_->{DURATION};
		my $reStart = $_->{SSS};
		my $reEnd = new Date($reStart);
		my $startTime = substr($reEnd->toStr(),8,6);
		$reEnd->add($reDura);
		my $endTime = $reEnd->toStr();
		
		my $ssts = $_->{STS};
		while((my $reKey,my $reVal) = each(%$_)) {
			print "$reKey:$reVal, ";
		}
		print "\n";
		print("Fetch 1,'tid',$_->{PHONE},$_->{OPP},$_->{DAY},$reStart,$endTime,$ssts\n");
#		my $phone = $_->{PHONE};
#		$phone =~ s/^(86|\d+-|010)//g;
#		$_ = [1,$tid,$phone,$_->{OPP},$_->{DAY},$startTime,$endTime,$_->{STS}];
		$_ = [1,'tid',$_->{PHONE},$_->{OPP},$_->{DAY},$reStart,$endTime,$_->{STS}];
	}
	