package conf;
require Exporter;
@ISA = qw(Exporter);		
@EXPORT = qw(InDir OutDir LogDir PLOG DB ZW USR PSW PROXY URI SERVER  SERVERPORT TIMEOUT
VOICE_TAG GPRS_TAG ZY_TAG BAD FAIL verifyUrl dirFmt verifyMethod SK_HOST SK_PORT
);
  

#上传下载目录
use constant InDir  =>  './in';
use constant OutDir=>   './out';

#log directory
use constant LogDir			=>  './log';
use constant PLOG			=>  'finder.log';
 
#DB配置
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


#173配置
use constant SERVER			=>	'10.4.70.173';  
use constant SERVERPORT		=>	81394;

#超时限制
use constant TIMEOUT		=> 400;

#tag
use constant VOICE_TAG		=>	'项目号码';
use constant ZY_TAG			=>	'中继群号';
use constant GPRS_TAG		=>	'序号';
use constant BAD			=>	'没找到匹配话单';
use constant FAIL			=>	'结算主机连接失败';

#socket server conf  add by wxt 20170412
use constant SK_HOST    => '10.4.87.60';
use constant SK_PORT    => '20210';
1;