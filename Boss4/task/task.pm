package task;

#an abstract file, every task inherit from this class
#the task has a factory for making cdr, an excel file for sacnning, and a ptr for iterting 

use lib qw(../cdr ../lib ../cdrfac);
use Spreadsheet::ParseExcel;  
use Spreadsheet::WriteExcel;  
use Encode;

use cdrfac;
use util;
use conf;
use SOAP::Lite;
use IO::Socket;
use IO::Handle;
use strict;

#an abstract class
sub new{         
	my $class = shift;
	my $fac = shift;		#a factory for making cdr
	my $file = shift;		#the excel file
	my $tag = shift;		#the tag for finding start point
	my $ref={				#the ptr indicating the next position for sacnning excel
		fac		=>	$fac,
		file	=>  $file,
		tag		=>	$tag,
		start	=>	undef,
		sheet	=>	undef,
		col_min	=>	undef,
		col_max	=>	undef,
		row_min	=>	undef,
		row_max	=>	undef
	};
	bless($ref, $class);
	return $ref;
}


#set the parser, remain work is forward to parser
sub set_parser {
	my $this = shift;
	my $parser = shift;
	$this->{parser} = $parser;

}

#open the excel and return the range parameter
sub _open_excel {
	my $this = shift;
	my $file = $this->{file};
	
	#initialize lib
	my $excel   = Spreadsheet::ParseExcel->new()							
	or (p_log("Spreadsheet::ParseExcel Lib Fail") and return INIERR);
	
	#read file
	my $workbook = $excel->Parse($file)
	or (p_log("Can not Open $file") and return FILERR); 
	
	
	#get the work sheet
	my @sheets = $workbook->worksheets();
	my $sheet  = $sheets[0];
	my ($row_min,$row_max) = $sheet->row_range();  
	my ($col_min,$col_max) = $sheet->col_range();  
	p_log("Open $file: $sheet");
	p_log("Row from $row_min to $row_max");
	p_log("Col from $col_min to $col_max");
	
	$this->{sheet} 	 = $sheet;
	$this->{row_max} = $row_max;
	$this->{row_min} = $row_min;
	$this->{col_max} = $col_max;
	$this->{col_min} = $col_min;
	
	return 0;
}

#a virtual function scaning the format, can be redefined by sub-class
sub _scan_format {
	my $this = shift;
	my $tag  = $this->{tag};
	
	#the default behavior is scaning for a satrt point, the behavior can be redefined by sub-class
	my $start; 
	
	#find the start point
	for ($this->{row_min} .. $this->{row_max}){
		my $cell = $this->{sheet}->get_cell($_, 0);   
		next if(!$cell);                                        #skip null value
		if ($cell ->value() eq decode('gb2312',$tag)) {
			$start = $_;
			p_log("Find $tag in $start row");
			last;
		}
		(p_log("Not found '$tag'") && return FERR)
		if ($_ eq $this->{row_max});	#find nothing for begin	
	}
	
	
	$this->{start} = $start;
	return 0;
}

#read a row from excel, return the arguments
sub _read_row {
	my $this = shift;
	my $row = shift;
	my @args;
	
	#the first argument:rowNUM
	push (@args,$row);
	
	#sarch every col
	for my $i ($this->{col_min} .. $this->{col_max}) {
		my $cell = $this->{sheet} -> get_cell($row,$i);
		my $val = ($cell)? $cell->value(): '';			#if the cell is undefined save a null                               
		push(@args, encode('gb2312', $val));
	}
		
	$" = '|';
	
	#chomp the space
	foreach my $arg (@args) {
		$arg =~ s/^\s+//;
		$arg =~ s/\s+$//;
	}
	
	p_log("cdr $row Arg: @args");
		
	
	return @args;
}


#parse excel, put them all together, return a list of cdrs
sub parse {
	my $this = shift;
	my $list = shift;	
	my $sts;

	return $sts	if (($sts = $this->_open_excel())!=0);
	return $sts	if (($sts = $this->_scan_format())!=0);

	my $start = $this->{start}+1;

	for my $i ($start .. $this->{row_max}) {
		my @args = $this->_read_row($i);			#read every rows from excel
		my $res = $this->{fac}->make_cdr(@args);		#make cdr through factory			
		p_log($res);
	
		my $cdr = new cdr();
		$cdr->{row} = $i;
		#empty item
		if ($res == EMP) {$cdr->{sts} = '';}
		#erro promotion
		elsif	($res ==  PHONE_ERR)	{$cdr->{sts} = "主叫号格式错误";}
		elsif	($res ==  NO_ERR)		{$cdr->{sts} = "序号错误";}
		elsif	($res ==  OPP_ERR)		{$cdr->{sts} = "被叫号格式错误";}
		elsif	($res == THIRD_ERR)		{$cdr->{sts} = "呼转号格式错误";}
		elsif	($res == DAY_ERR)		{$cdr->{sts} = "日期格式错误,正确格式20130801,请注意不能是2013801!";}
		elsif	($res == START_ERR)		{$cdr->{sts} = "起始时间格式错误,正确格式01:45:03,请注意不能是1:45:3";}
		elsif	($res == END_ERR)		{$cdr->{sts} = "终止时间格式错误,正确格式01:45:03,请注意不能是1:45:3";}
		elsif	($res == IMSI_ERR)		{$cdr->{sts} = "IMSI格式错误";}
		elsif	($res == APN_ERR)		{$cdr->{sts} = "APN格式错误";}
		elsif	($res == GIP_ERR)		{$cdr->{sts} = "Ggsn IP格式错误";}
		elsif	($res == SIP_ERR)		{$cdr->{sts} = "sgsn ip格式错误";}
		elsif	($res == CID_ERR)		{$cdr->{sts} = "charge id格式错误";}
		elsif	($res == UP_ERR)		{$cdr->{sts} = "上行流量格式错误";}
		elsif	($res == DOWN_ERR)		{$cdr->{sts} = "下行流量式错误";}
		elsif	($res == SID1_ERR)      {$cdr->{sts} = "service id 1格式错误";}			  
		elsif	($res == SID1UP_ERR)	{$cdr->{sts} = "sercice id 1 上行流量格式错误";}				
		elsif	($res == SID1DOWN_ERR)  {$cdr->{sts} = "sercice id 1 下行流量格式错误";}	
		elsif	($res == SID2_ERR)		{$cdr->{sts} = "service id 2 格式错误";}		
		elsif	($res == SID2UP_ERR)	{$cdr->{sts} = "sercice id 2 上行流量格式错误";}
		elsif	($res == SID2DOWN_ERR)	{$cdr->{sts} = "sercice id 2 下行流量格式错误";}
		elsif	($res == SID3_ERR)		{$cdr->{sts} ="service id 3 格式错误";}			
		elsif	($res == SID3UP_ERR)	{$cdr->{sts} ="sercice id 3 上行流量格式错误";} 
		elsif	($res == SID3DOWN_ERR)	{$cdr->{sts} ="sercice id 3 下行流量格式错误";} 
		#normal cdr
		else	{$cdr = $res;$cdr->{sts} = READY;}

		#record the cdr
		p_log($cdr->toStr());
		push(@$list,$cdr);
	}

	p_log(scalar @$list." Cdr Generated:");
	foreach (@$list) {
		p_log($_->toStr());
	}

	return 0;
}
 
 

#generate result
sub cp_ex {
	my $this	=	shift;
	my $des		=	shift;
	my $list	=	shift;
	
	my $src		=	$this->{file};
	my $excel   = Spreadsheet::ParseExcel->new();
	my $workbook = $excel->Parse($src) ;
	my @sheets = $workbook->worksheets();
	my $sheet  = $sheets[0];


	#set status
	my @sts;
	foreach (@$list) {
		$sts[$_->{row}] = $_->{sts};
	}


	my ($rmin,$rmax) = $sheet->row_range();  
	my ($cmin,$cmax) = $sheet->col_range();        
 
 
	#open the result file
	my $book = new Spreadsheet::WriteExcel($des);
	my $s = $book->add_worksheet(); 
	
	#set colunm width
	$s->set_column(0,0,5);
	$s->set_column(1,2,20);
	$s->set_column(3,$cmax,20);
	
	#write into it
	for my $i ($rmin .. $rmax) {
		for my $j ($cmin .. $cmax) {
			my $cell = $sheet->get_cell($i,$j);
			next if (!$cell);
			my $val = $cell->value();
			next if (!(defined $val));
			
			#set format
			my $f1 = $cell->get_format();
			my $f2  = $book->add_format();
			
			$f2->set_font($f1->{Font}->{Name});
			$f2->set_size($f1->{Font}->{Height});
			$f2->set_color($f1->{Font}->{Color});
			$f2->set_bold($f1->{Font}->{Bold});
			$f2->set_underline($f1->{Font}->{Underline});
			$f2->set_font_strikeout($f1->{Font}->{Strikeout});
			$f2->set_align($f1->{AlignH});
			
			$s->write_string($i,$j, $val,$f2);
		}
		my $cell = $sheet->get_cell($i,0);
		next if (!$cell);
		my $val = $cell->value();
		next if (!$val);
		$s->write($i,$cmax+1,decode('gb2312',$sts[$i]));
	}


	$book->close();  
}


#record all nomatch cdr in log
sub getNomatch {
	my $this = shift;
	my $list = shift;
	
	p_log("No Match:");
	
	foreach my $cdr (@$list) {
		p_log($cdr->toStr()) if ($cdr->{sts} eq BAD or $cdr->{sts} eq -1);
	}
	
}

#validate all
sub validate_all {
	my $this = shift;
	my $list = shift;
	my @list = @$list;
	my $sts;
	my $flag=0;
	foreach (@list) {
		if ($_->{sts} ne READY){
			$flag=1 if ($_->{sts} ne '');
			next;
		}
		$sts = $_->validate();
		if ($sts==DBERRO){
			$flag=1;
			$_->{sts} = "无法连接数据库";
		}elsif($sts==SQLERRO){
			$flag=1;
			$_->{sts} = "无法执行SQL,可能是表已经过期了,请检查一下话单日期";
		}elsif($sts==TRKERRO){
			$flag=1;
			$_->{sts} = "中继号信息不存在";
		}else{
			$flag=1 if ($_->{sts} eq BAD or $_->{sts} eq FAIL);
		}
	}
	return $flag;
}



1;