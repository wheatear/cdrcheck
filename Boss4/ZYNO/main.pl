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
			main({flag=>0,re=>"��Χ����"});
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
	(main({flag=>0,re=>"����ȷ��дtrunk"}) && quit());                    
}
 
 

 


#������
sub main {
my $info = shift;
my $flag = $info->{flag};
my $re = $info->{re};
my $trks = $info->{trks};



print header("text/html; charset=gbk");
print <<HTML;
<HTML>
<HEAD>
<TITLE>ͳһ�Ʒ���֤ƽ̨</TITLE>
</HEAD>
<BODY>
<a href="../index.pl">������֤</a>
<a href="./main.pl"> �����м̲�ѯ</a>
<H1>�����м̺�ȷ��

<FORM ACTION=./main.pl METHOD="POST" ENCTYPE="multipart/form-data" >
<h5>�м̺�:<TEXTAREA ROWS=10 COLS=40 NAME=trunk></TEXTAREA>
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
		print "�м̺�$trk:δ����<br>" ;
		next;
	}
	
	if ($local_info =~ m/^1234#/) {
		print "�м̺�$trk:��ѯ����$local_info<br>" ;
		next;
	}
	
print <<TABLE;
<TABLE BORDER=1 CELLPADDING=9>
 <TR>
    <TH>��Ʒ��(�м̺�:$trk)</TH>
    <TH>serv_id</TH>
    <TH>��Ʒ����</TH>
    <TH>��Чʱ��</TH>
    <TH>ʧЧʱ��</TH>
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


 

#��֤����
sub quit{
util::p_log("******************************************************************");
util::p_log("****************************Validate End**************************");
util::p_log("******************************************************************");
exit;
}
