#!"C:\Dwimperl\perl\bin\perl.exe"
use CGI qw(:all);
use Encode;
use CGI::Cookie;
use Net::FTP;
use JSON;
use Common;
use DBUtil;

my $cgi = CGI->new();

# достаем необходимые куки
my %cookies = CGI::Cookie->fetch;
my $host = $cookies{host}->value;
my $userId = $cookies{userId}->value;

my ($id, $login, $password) = DBUtil::getUserById($userId);

my $ftp = Common::connectToFTPServer($host, $login, $password);

my $postData = $cgi->param('POSTDATA');
exit unless $postData;
my %data = %{JSON::decode_json($postData)};
my $path = $data{path};

if ($ftp->cwd($path)) {
	print $cgi->header(
	   -type=>'text/plain',
	   -status=> '400 Directory already exist'
	);
	$ftp->quit;
	exit;
} 

$ftp->cwd("/");

print $cgi->header(
	-type => 'text/html',
	-charset => 'utf-8'
);

$ftp->mkdir(encode("utf8", $path)) or print "already exist <br>";
$ftp->quit;