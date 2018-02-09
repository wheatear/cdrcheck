package conf;
require Exporter;
@ISA = qw(Exporter);		
@EXPORT = qw(InDir OutDir LogDir PLOG DB ZW USR PSW PROXY URI SERVER  SERVERPORT TIMEOUT
VOICE_TAG GPRS_TAG ZY_TAG BAD FAIL verifyUrl dirFmt verifyMethod SK_HOST SK_PORT
);
  

#�ϴ�����Ŀ¼
use constant InDir  =>  './in';
use constant OutDir=>   './out';

#log directory
use constant LogDir			=>  './log';
use constant PLOG			=>  'finder.log';
 
#DB����
use constant DB		=> 'jfdb';
use constant ZW		=> 'SRV_ZW1';
use constant USR	=> "aiop1";                    
use constant PSW	=> "ng3,aiop";      
 
 
#webservice
use constant PROXY		=> 'http://10.7.6.199:8080/cgi-bin/Boss4/proxy/proxy.pl';
use constant URI		=> 'proxy';
use constant verifyUrl	=>	'http://10.4.70.173:13800/RPC2';
use constant dirFmt		=> '/gss2/data/databak/%s/upload/%s';
use constant verifyMethod	=>	'verifyCdr';


#173����
use constant SERVER			=>	'10.4.70.173';  
use constant SERVERPORT		=>	81394;

#��ʱ����
use constant TIMEOUT		=> 400;

#tag
use constant VOICE_TAG		=>	'��Ŀ����';
use constant ZY_TAG			=>	'�м�Ⱥ��';
use constant GPRS_TAG		=>	'���';
use constant BAD			=>	'û�ҵ�ƥ�仰��';
use constant FAIL			=>	'������������ʧ��';

#socket server conf  add by wxt 20170412
use constant SK_HOST    => '10.4.87.60';
use constant SK_PORT    => '20210';
1;