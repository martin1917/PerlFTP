#!"C:\Dwimperl\perl\bin\perl.exe"
use CGI qw(:all);
use HTML::Entities;
use Encode qw(encode decode);
use CGI::Cookie;
use Net::FTP;
use JSON;
use Common;
use DBUtil;

my $cgi = CGI->new();
my %cookies = CGI::Cookie->fetch;
my $host = $cookies{host}->value;
my $userId = $cookies{userId}->value;
my $username = $cookies{username}->value;

my ($id, $login, $password) = DBUtil::getUserById($userId);
my $ftp = Common::connectToFTPServer($host, $login, $password);

my $postData = $cgi->param('POSTDATA');
exit unless $postData;
my %data = %{JSON::decode_json($postData)};
my $path = $data{path};

my ($remote_file_content, $remote_file_handle);
open($remote_file_handle, '>', \$remote_file_content);

$ftp->get($path, $remote_file_handle) or die "get failed ", $ftp->message;

print $cgi->header(
	-type => 'text/html',
	-charset => 'utf-8',,
);

$ftp->quit;

$remote_file_content =~ s{>}{&gt;}g;
$remote_file_content =~ s{<}{&lt;}g;
$remote_file_content =~ s{\n}{<br>}g;
print $remote_file_content;