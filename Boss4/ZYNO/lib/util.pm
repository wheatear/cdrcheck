package util;
 
use Encode;
use DBI;
use Time::Local;
use POSIX qw(strftime); 
use SOAP::Lite;



use conf;
 

 

sub fetch {
my $trunk = shift;
my $re = SOAP::Lite
-> uri(conf::URI)
-> proxy(conf::PROXY)
-> fetchZy($trunk)->result;

return $re;
}
 
 
sub fetchid{
my $trunk = shift;
 
p_log("Connect to ".conf::USR."/".conf::PSW."@".conf::DB);


my $sql = qq (
select
null PROD_NAME,
null SPROM_PARA,
null SO_ID,
serv_id  SERV_ID,
to_char(valid_date,'yyyy-mm-dd hh24:mi:ss')  VALID_DATE,
to_char(expire_date,'yyyy-mm-dd hh24:mi:ss')  EXPIRE_DATE
from sunhq.V_USER_PBX_ALL\@ZWDB
where IN_TRUNK in (\'$trunk\')
and 
sysdate between valid_date and expire_date
);
 

#fetch from webservice
my $re = SOAP::Lite
-> uri(conf::URI)
-> proxy(conf::PROXY)
-> fetch(conf::DB,conf::USR,conf::PSW,$sql)->result;



(p_log($re) and return DBERRO)     if ($re =~ m/^1{1}/g);
(p_log($re) and return SQLERRO)    if ($re =~ m/^2{1}/g);
(p_log($re) and return SQLERRO)    if ($re =~ m/^3{1}/g);

p_log("Fetch ".(scalar @$re)." Records");
 

return $re;


}
 
#Ð´ÈÕÖ¾
sub p_log {
my $content = shift;
open(FH, ">>./log/finder.log");
my $now = time;
my $time = strftime("[%Y-%m-%d %H:%M:%S]: ", localtime $now);
print FH $time.$content."\n";
close FH;
}


 


1;