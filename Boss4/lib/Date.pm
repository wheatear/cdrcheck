package Date;

@ry =
(0,0,31,60,91,121,152,182,213,244,274,305,335,366);
@oy =  
(0,0,31,59,90,120,151,181,212,243,273,304,334,365);
$cyc = 365*3+366;
$daysecs = 60*60*24;

sub new{         
	my $class = shift;
	
#	modify by wxt 20170412
	if (scalar @_ eq 0) {return bless({},$class);}
	
	my $str = shift;
	
	
	my $ref={
		sec=>0  
	};
	
	
	my $yy = substr($str,0,4);
	my $mm = substr($str,4,2);
	my $dd = substr($str,6,2);
	my $hh = substr($str,8,2);
	my $mi = substr($str,10,2);
	my $ss = substr($str,12,2);
	my $yd; 
	
	my $cycs = int(($yy-2000)/4);				#������������
	
	
	$remain = ($yy-2000)%4;						#�༸��
	if ($remain>0){								#��������
		$yd = $cycs*$cyc+$remain*365+1;			#����֮ǰ����������
		$ref->{sec} = ($yd+$oy[$mm]+$dd-1)*24*60*60+$hh*60*60+$mi*60+$ss;
	}
	else{										#������
		$yd = $cycs*$cyc;						#����֮ǰ����������          
		$ref->{sec} = ($yd+$ry[$mm]+$dd-1)*24*60*60+$hh*60*60+$mi*60+$ss;
	}
	
	bless($ref, $class);
	return $ref;
}

#add by wxt 20170412
sub setSec{
	my $this = shift;
	my $se =  shift;
	
	$this->{sec} = $se;
}

#add by wxt 20170412
sub copy{
	my $this = shift;
	
	my $nRef = {};
	$nRef->{sec} = $this->{sec};
	bless($nRef,'Date');
	return $nRef;
}

#������
sub set{
	my $this = shift;
	my $str = shift;
	my $yy = substr($str,0,4);
	my $mm = substr($str,4,2);
	my $dd = substr($str,6,2);
	my $hh = substr($str,8,2);
	my $mi = substr($str,10,2);
	my $ss = substr($str,12,2);
	my $yd; 
	
	my $cycs = int(($yy-2000)/4);        #������������
	
	
	$remain = ($yy-2000)%4;         #�༸��
	if ($remain>0){                 #��������
		$yd = $cycs*$cyc+$remain*365+1;    #����֮ǰ����������
		$this->{sec} = ($yd+$oy[$mm]+$dd-1)*24*60*60+$hh*60*60+$mi*60+$ss;
	}
	else{										#������
		$yd = $cycs*$cyc;							#����֮ǰ����������          
		$this->{sec} = ($yd+$ry[$mm]+$dd-1)*24*60*60+$hh*60*60+$mi*60+$ss;
	}
	
}
 
sub toStr {
	my $this = shift;
	my ($yy,$mm,$dd,$hh,$mi,$ss );
	
	#������
	$cycs = int((int(($this->{sec})/(24*60*60)))/$cyc);            #��������
	$remain = (int(($this->{sec})/(24*60*60)))%$cyc;          #����������
	
	
	$yy = ($remain>366)? ($cycs*4+int(($remain-366)/365)+1): $cycs*4;
	$yy+=2000;                             #���
	
	if ($remain>366){                        #��������
		$remain = ($remain-366)%365;              #���µ�����
		for my $i (1 .. 13) {
			
			if ($remain<$oy[$i]) {
				$mm = $i-1;
				
				$dd = $remain - $oy[$i-1]+1;
				last;
			}
		}
	}
	else{
		for my $i (1 .. 13){
			if ($remain<$ry[$i]) {
				$mm = $i-1;
				$dd = $remain - $ry[$i-1]+1;
				last;
			}
		}
		
	}
	
	
	#ʱ����
	$remain = ($this->{sec})%(24*60*60);
	$hh = int($remain/(60*60));
	$mi = int(($remain%(60*60))/60);
	$ss = ($remain%(60*60))%60;
	
	$yy = sprintf "%4d", $yy;
	$mm = sprintf "%02d", $mm;
	$dd = sprintf "%02d", $dd;
	$hh = sprintf "%02d", $hh;
	$mi = sprintf "%02d", $mi;
	$ss = sprintf "%02d", $ss;
	return $yy.$mm.$dd.$hh.$mi.$ss;l
}

sub diff{
	my $this = shift;
	my $other = shift;
 
	return abs($this->{sec} - $other->{sec});
}
 
sub add {
	my $this = shift;
	my $s = shift;

	$this->{sec} += $s;
}
 
1;