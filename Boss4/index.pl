#!perl
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use Time::Local;
use POSIX qw(strftime); 
use IO::Socket qw(:DEFAULT :crlf);
use Encode;

use lib qw(./cdr ./lib ./cdrfac ./task ./fetcher);

use strict;
use Date;
use conf;
use util;

 
 
#every cdr goes here
use  cdr;
use  zycdr;
use  gprscdr;
use  rnccdr;

#factory
use  zycdrfac;
use  rnccdrfac;
use  gprscdrfac;

#task
use task;
use zytask;


 
my $action	= param('action');
my $file	= param('file');
my $out		= param('out');                        #result for dowload 
my $type	= param('cdr');                        #result for dowload 
 
 
 
 
p_log("******************************************************************\n");
p_log("****************************Validate Start************************\n");
p_log("******************************************************************\n");
 
 
 
 
 
main() if ($action eq '');					#main page


#upload file
if ($action eq 'UpLoad')  {
	#nofile
	if (!$file) {		
		main("����ѡ���ļ�");
		quit();
	}
	#type not selected
	elsif (!$type) {
		main("��ѡ�񻰵�����");
		quit();
	}
	#upload file
	else {
		 my $fac;
		 my $task;
		 my $file = upload($file);
		 (main("�ϴ�ʧ��") && quit()) if ($file eq UPLOAD_ERR);		#upload fail
		 
		 #get the file name
		 my $infile = InDir."/$file";
		 my $outfile = OutDir."/$file";
		 
		 #check type
		 if ($type eq 'zy'){
			p_log("���ﻰ����֤");
			$fac = new zycdrfac();
			$task = new zytask($fac,$infile,ZY_TAG);
		}
		elsif ($type eq 'gprs'){
			p_log("GPRS����");
			$fac = new gprscdrfac();
			$task = new task($fac,$infile,GPRS_TAG);
		}
		elsif ($type eq 'rnc'){
			p_log("RNC��������");
			$fac = new rnccdrfac();
			$task = new task($fac,$infile,VOICE_TAG);
		}		
		elsif ($type eq 'msc'){
			p_log("MSC��������");
			$fac = new msccdrfac();
			$task = new task($fac,$infile,VOICE_TAG);
		}	
		
		#get the cdr list
		my @list;
		my $sts = $task->parse(\@list);
		p_log($sts);
		(main("�ļ���ʼ��ʧ��") && quit())					if ($sts == INIERR);         
		(main("�ļ���ʧ��,��ʹ��xls��ʽ") && quit())		if ($sts == FILERR);         
		(main("�ļ���ʽ����") && quit())					if ($sts == FERR);     
		(main("$sts") && quit())							if ($sts ne '0');   
		
		#validate th list
		$sts = $task->validate_all(\@list);
 		
		#record the nomatch cdr
		$task->getNomatch(\@list);
		
		#trans the outfile
		main("��֤����,��������",$outfile) if($sts==0);
		main("��֤����,��������<br><font color=red>����:���ֻ�����֤ʧ��,����!",$outfile) if($sts==1);
		p_log("Copy ".$infile." to ".$outfile);
		$task->cp_ex($outfile, \@list);
		quit();
	}
}
#download the file
elsif ($action eq 'DownLoad')  {
	(main("δ���ɽ���ļ�,��������֤") && quit())if (!$out);
	main("δ���ɽ���ļ�,��������֤") if ((dowload($out) eq -1));
	
	dowload();
}
 

#������
sub main {
	my $info = shift;
	my $outfile = shift;
	print header("text/html; charset=gbk");
print <<HTML;
	<HTML>
	<HEAD>
	<TITLE>ͳһ�Ʒ���֤ƽ̨</TITLE>
	<script>
	function showtips()
	{
	document.getElementById("tips").innerHTML="������֤,���Ժ�...";
	}
	</script>
	</HEAD>
	<BODY>
	<a href="./index.pl">������֤</a>
	<a href="./ZYNO/main.pl"> �����м̲�ѯ</a>
	<H1>�Ʒ���֤
	
	<FORM ACTION=./index.pl METHOD="POST" ENCTYPE="multipart/form-data" >
	<INPUT TYPE="FILE" NAME="file">
	<input type=hidden name=out value="$outfile">
	<input type=submit name=action value="UpLoad" onclick="showtips()">
	<input type=submit name=action value="DownLoad">
	
	<H2>
	��ѡ�񻰵����� <BR>
	<!--<input type=radio name=cdr value=rnc>RNC��������<BR>-->
	<!--<input type=radio name=cdr value=msc>MSC��������<BR>-->
	<input type=radio name=cdr value=rnc>��������<BR>
	<input type=radio name=cdr value=zy>���ﻰ��<BR>
	<input type=radio name=cdr value=gprs>GPRS����<BR>
	
	<br>
	<p id="tips">$info</p>
	</FORM>
	</BODY>
	</HTML>
HTML
}

 
 
#upload file
sub upload{
	my $fh = shift;
	my $name = $fh;
	my @name = split(/\\/,$name);
	$name = $name[$#name];
	p_log("Recieve File $name");
	
	open (FH, ">".InDir."/$name") or return UPLOAD_ERR; 
	binmode FH;
	binmode $fh;
	while (my $n = read($fh, my $buf, 1024)) { 
		print FH $buf; 
	}
	close (FH); 
	close ($fh);
	return $name;
}

#end and quit
sub quit{
	p_log("******************************************************************");
	p_log("****************************Validate End**************************");
	p_log("******************************************************************");
	exit;
}

#download file
sub dowload {
	my $file = shift;
	
	my $fileName = $file;
	$fileName =~ s/^(.*?\/)*//g;
	p_log("Download file $fileName");
	
	return -1 if (!(-e $file));
	my $size = -s $file;
 
	my $head =  
		'Connection: close'.CRLF.
		'Content-Type: application/force-download'.CRLF.
		"Content-Disposition: attachment; filename=\"$fileName\"".CRLF.
		"Content-Length: $size".CRLF.
		CRLF;
	
	print $head;
 
	open (FH, $file);
	while (my $n = read(FH, my $buf, 1024)) {
		print $buf;
	}
	close (FH);
	exit(0);
}
 
 

 
