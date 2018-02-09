#!perl
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use strict;
use Time::Local;
use POSIX qw(strftime); 


use lib 'lib','../';
use util;
use conf;
use Encode;


 
my $action   = param('action');
my $trunk    = param('trunk');
 
 
 
 
util::p_log("******************************************************************\n");
util::p_log("****************************Validate Start************************\n");
util::p_log("******************************************************************\n");
 
 
 
 
if ($action eq ''){
	main({flag=>0,re=>""})        
}
elsif (($trunk =~ m/^(\d+\s*)+$/g) ||  ($trunk =~ m/\d+\s*-{1}\s*\d+/g)) {
	my @trks;
	
	if (index($trunk,'-') != -1) {
		$trunk =~ s/s+//g;
		my ($beg, $end) = split(/\-/,$trunk);
		if ($beg > $end){
			main({flag=>0,re=>"范围错误"});
		}
		else {
			foreach ($beg .. $end){
				push(@trks,$_);
			}
		}
			
	}
	else {
		@trks = split(/\s+/,$trunk);
	}
	util::p_log("@trks");
	my $infos = [];
	
	foreach (@trks){
		util::p_log("Search:$_");
		my $err = util::fetch($_);
		($err = util::fetchid($_) )if (scalar @$err == 0);
		
		push(@$infos,$err);
	}
	
	main({flag=>1, re=>$infos, trks=>\@trks});
}
else {
	(main({flag=>0,re=>"请正确填写trunk"}) && quit());                    
}
 
 

 


#主界面
sub main {
my $info = shift;
my $flag = $info->{flag};
my $re = $info->{re};
my $trks = $info->{trks};



print header("text/html; charset=gbk");
print <<HTML;
<HTML>
<HEAD>
<TITLE>统一计费验证平台</TITLE>
</HEAD>
<BODY>
<a href="../index.pl">话单验证</a>
<a href="./main.pl"> 综语中继查询</a>
<H1>综语中继号确认

<FORM ACTION=./main.pl METHOD="POST" ENCTYPE="multipart/form-data" >
<h5>中继号:<TEXTAREA ROWS=10 COLS=40 NAME=trunk></TEXTAREA>
<input type=submit name=action value="check">
 


<br>
HTML

if ($flag eq 0) {
print $re;
}
else {
my $i = 0;
foreach my $local_info (@$re){
	my $trk = $trks->[$i];
	if (!$local_info) {
		print "中继号$trk:未生成<br>" ;
		next;
	}
	
	if ($local_info =~ m/^1234#/) {
		print "中继号$trk:查询错误$local_info<br>" ;
		next;
	}
	
print <<TABLE;
<TABLE BORDER=1 CELLPADDING=9>
 <TR>
    <TH>产品名(中继号:$trk)</TH>
    <TH>serv_id</TH>
    <TH>产品属性</TH>
    <TH>生效时间</TH>
    <TH>失效时间</TH>
    <TH>SO_ID</TH>
 </TR>
TABLE
 

foreach (@$local_info){	
print <<HTML; 
<TR>
<TD>$_->{PROD_NAME}</TD>
<TD>$_->{SERV_ID}</TD>
<TD>$_->{SPROM_PARA}</TD>
<TD>$_->{VALID_DATE}</TD>
<TD>$_->{EXPIRE_DATE}</TD>
<TD>$_->{SO_ID}</TD>
</TR>
HTML
}

print "<br><br>";
$i++;
}



}




print <<HTML;
</FORM>
</BODY>
</HTML>
HTML
}


 

#验证结束
sub quit{
util::p_log("******************************************************************");
util::p_log("****************************Validate End**************************");
util::p_log("******************************************************************");
exit;
}
