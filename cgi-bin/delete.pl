#!"C:\Dwimperl\perl\bin\perl.exe"
use CGI qw(:all);
use Encode;
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

my $postData = $cgi->param('POSTDATA');
exit unless $postData;
my %data = %{JSON::decode_json($postData)};
my $path = $data{path};
my @files = @{$data{files}};
my @folders = @{$data{folders}};

foreach my $file (@files) {
	my $remotePath = "$path/$file";
	$ftp->delete(encode_utf8($remotePath));
}

foreach my $folder (@folders) {
	my $remotePath = "$path/$folder";
	delete_recursive(encode_utf8($remotePath));
	$ftp->rmdir(encode_utf8($remotePath));
}

$ftp->quit;

sub delete_recursive {
	my ($folder) = @_;
	foreach my $f ($ftp->dir($folder)) {
		$f =~ s/ +/ /gi;
		my @parts = split(/ /, $f);
		my $perm = @parts[0];
		my $name = join(" ", @parts[8..(scalar(@parts) - 1)]);
		if ($perm =~ /^d/) {
			delete_recursive("$folder/$name");
			$ftp->rmdir("$folder/$name");
		} else {
			$ftp->delete("$folder/$name");
		}
	}
}