#!"C:\Dwimperl\perl\bin\perl.exe"
use File::Basename;
use Encode;
use CGI qw(:all);
use CGI::Cookie;
use Net::FTP;
use JSON;
use Common;
use DBUtil;

my $cgi = CGI->new();

print $cgi->header(
	-type => 'text/html',
	-charset => 'utf-8',
);

# достаем необходимые куки
my %cookies = CGI::Cookie->fetch;
my $userId = $cookies{userId}->value;
my $host = $cookies{host}->value;

my ($id, $login, $password) = DBUtil::getUserById($userId);

my $ftp = Common::connectToFTPServer($host, $login, $password);

my $path = $cgi->param('path');
my $file = $cgi->param('file');
my $remotePath = "$path/$file";

$ftp->binary;
$ftp->put(\*$file, $remotePath) or print "error\n$!", $ftp->message;
$ftp->quit;