package zytask;

#zy cdr is different to others 
#the task has a factory for making cdr, an excel file for sacnning, and a ptr for iterting 


use lib qw(../cdr ../lib ../cdrfac);
use Spreadsheet::ParseExcel;  
use Spreadsheet::WriteExcel;  
use Encode;

use cdrfac;
use util;
use conf;
use task;

#inherited from cdr class
@ISA = qw(task);


use strict;
#zy task is the same as other task
sub new{         
	my $class = shift;
	
	#construct the parent part
	my $ref = new task(@_);
	
	#bless and return
	bless($ref, $class);
	return $ref;
}

#a virtual function scaning the format, can be redefined by sub-class
sub _scan_format {
	my $this = shift;
	my $tag  = $this->{tag};
	
	#to record the trunc
	my %pos;
	
	my ($sheet,$row_min, $row_max, $col_min,$col_max) = 
	($this->{sheet},$this->{row_min},$this->{row_max},$this->{col_min},$this->{col_max});
	
	#find every trunc
	for my $i ($row_min .. $row_max){
		#search every col
		for my $j ($col_min .. $col_max) {
			my $cell = $sheet->get_cell($i, $j);   
			next if(!$cell);						#skip null col, search from the first col
				#mark the point
				if (substr(encode('gb2312',$cell ->value()),0,8)  eq $this->{tag}) {
					my $trunk;
					my $k;
					#extrct the digit id from cell
					while(!($trunk =~ m/^\d{4}$/g)) {
						$trunk = substr(encode('gb2312',$cell ->value()),$k,4);
						$k++;
					}
					p_log("Find $trunk in $i row");
					#record the trunk
					$pos{$i} = $trunk;
			}
		}
	}
	
	#record the position of every trucid
	$this->{pos} = \%pos;
	return 0;
}

#read a row from excel, return the arguments
sub _read_row {
	my $this = shift;
	my $row = shift;
	my $trk = shift;		#explicityly pass the truck id
	my @args;
	
	my ($sheet,$row_min, $row_max, $col_min,$col_max) = 
	($this->{sheet},$this->{row_min},$this->{row_max},$this->{col_min},$this->{col_max});
	
	
	#the first argument:rowNUM
	push (@args,$row);
	
	#the second argument is trunc id
	push (@args,$trk);
			
	
	#search every col
	for my $j (1 .. $col_max) {
		my $cell = $sheet -> get_cell($row,$j);
		next if (!$cell);											#skip null                                        	   
		next if (!($cell->value()=~ m/^\s*\d+-*:*\d+/g));			#search from the first digit
		push(@args, encode('gb2312', $cell->value()));
	}
		$" = '|';
	
	#format the day field
	$args[4]  =~ s/:|-|\s+//g;
	$args[5]  =~ s/:|-|\s+//g;
	my $day = substr($args[4],0,8);
	@args = ((@args[0..3]), $day,(@args[4..5]) );
	
	p_log("cdr $row Arguments:");
	$" = '|';
	
	#chomp the head and tail space
	foreach (@args) {s/^\s+//;s/\s+$//;}
	p_log("@args");
	
	return @args;
}

#parse excel, put them all together, return a list of cdrs
sub parse {
	my $this = shift;
	my $list = shift;
	
	my $sts;
	my @list = @$list;
	return $sts	if (($sts = $this->_open_excel())!=0);
	return $sts	if (($sts = $this->_scan_format())!=0);
	
	my %pos = %{$this->{pos}};
	
	my ($sheet,$row_min, $row_max, $col_min,$col_max) = 
	($this->{sheet},$this->{row_min},$this->{row_max},$this->{col_min},$this->{col_max});
	
	
	#if find no mark ,return FERR
	my @trunks = keys %pos;
	return FERR if ((scalar @trunks) eq 0);
	
	
	#generate cdr
	my @keys = sort {$a <=> $b} keys %pos;
	
	
	#search from every keys
	for my $row (0 .. $#keys) {
		#search every row
		for my $i ($keys[$row]+1 .. $row_max) {
			last if ($i eq $keys[$row+1]);			#if reach the next trunc skip
			my @args = $this->_read_row($i,$pos{$keys[$row]});
			my $res = $this->{fac}->make_cdr(@args);		#make cdr through factory			
			p_log($res);
			my $cdr = new cdr();
			$cdr->{row} = $i;
			#if illegle cdr skip to next row 
			if		($res == PHONE_ERR)	{$cdr->{sts} = "主叫号码错误";}
			elsif	($res == OPP_ERR)	{$cdr->{sts} = "对端号码错误";}
			elsif	($res == START_ERR)	{$cdr->{sts} = "开始时间错误";}
			elsif	($res == END_ERR)	{$cdr->{sts} = "结束时间错误";}
			elsif	($res == EMP)		{$cdr->{sts} = "";}
			else {$cdr = $res;$cdr->{sts}=READY;}
			
			#record the cdr
			p_log($cdr->toStr());
			push @$list,$cdr;
		}
		
	} 
	
	
	p_log(scalar @$list." Cdr Generated:");
	foreach (@$list) {
	p_log($_->toStr());
	}
	
	return 0;
}
 
 
#generate the result
sub cp_ex {
	my $this = shift;
	my $des = shift;
	my $cdrs = shift;
	
	my $src = $this->{file};
	
	my @sts;
	my %trk;
	
	#change status
	foreach (@$cdrs) {
		$_->{sts} =~ s/\D\./0\./g;
		$_->{sts} =~ s/basic/基本费/g;
		$_->{sts} =~ s/long/长途费/g;
		$_->{sts} =~ s/info/信息费/g;
		
		#set status
		$sts[$_->{row}] = $_->{sts};
		$trk{$_->{tid}}++;
	}
		
	#fetch trunc id
	my @trk = keys %trk;
	
	my $excel   = Spreadsheet::ParseExcel->new();
	my $workbook = $excel->Parse($src) ;
	my @sheets = $workbook->worksheets();
	my $sheet  = $sheets[0];
	
	
	my ($rmin,$rmax) = $sheet->row_range();  
	my ($cmin,$cmax) = $sheet->col_range();        
	
	
	
	#create result file
	my $book = new Spreadsheet::WriteExcel($des);
	my $s = $book->add_worksheet(); 
	
	#col width
	$s->set_column(0,0,5);
	$s->set_column(1,2,20);
	$s->set_column(3,$cmax,20);
	
	#write to result
	for my $i ($rmin .. $rmax) {
		for my $j ($cmin .. $cmax) {
			my $cell = $sheet->get_cell($i,$j);
			next if (!$cell);
			my $val = $cell->value();
			next if (!$val);
			
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
		
		$s->write($i,$cmax+1,decode('gb2312',$sts[$i]));
	}
	
	
	
	
	p_log("Fetch Trunk: @trk");
	
	
	#record every trunc id
	foreach my $trk (@trk) {
		next if (!($trk =~ m/\d+/));
		my $discount = SOAP::Lite
		-> uri(URI)
		-> proxy(PROXY)
		-> fetchZy($trk)->result;
		
		my @disc = @$discount;
		
		$s->write($rmax+2,3,decode('gb2312',"中继号: ".$trk));
		
		if (!$discount){
			$s->write($rmax+3,3,decode('gb2312','无折扣信息(所有项目按100%计费)'));
		}
		else {
			$s->write($rmax+3,3,decode('gb2312','产品名'));
			$s->write($rmax+3,4,decode('gb2312','serv_id'));
			$s->write($rmax+3,5,decode('gb2312','产品属性'));
			$s->write($rmax+3,6,decode('gb2312','生效时间'));
			$s->write($rmax+3,7,decode('gb2312','失效时间'));
			$s->write($rmax+3,8,decode('gb2312','SO_ID'));
			
					
			foreach my $rindex (0 .. $#disc){
				$s->write_string($rmax+4+$rindex,3,decode('gb2312',$disc[$rindex]->{PROD_NAME}));
				$s->write_string($rmax+4+$rindex,4,decode('gb2312',$disc[$rindex]->{SERV_ID}));
				$s->write_string($rmax+4+$rindex,5,decode('gb2312',$disc[$rindex]->{SPROM_PARA}));
				$s->write_string($rmax+4+$rindex,6,decode('gb2312',$disc[$rindex]->{VALID_DATE}));
				$s->write_string($rmax+4+$rindex,7,decode('gb2312',$disc[$rindex]->{EXPIRE_DATE}));
				$s->write_string($rmax+4+$rindex,8,decode('gb2312',$disc[$rindex]->{SO_ID}));
			}
			
		}
		$rmax+=12;
	}
	
	
	$book->close();  
}





1;