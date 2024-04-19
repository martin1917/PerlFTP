#!"C:\Dwimperl\perl\bin\perl.exe"
use FindBin qw( $RealBin );
use Encode;
use CGI qw(:all);
use CGI::Cookie;
use Net::FTP;
use JSON;
use Common;
use DBUtil;

my $cgi = CGI->new();

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
my $localPath = $data{localPath};
my @files = @{$data{files}};
my @folders = @{$data{folders}};

unless (-d $localPath) {
	print $cgi->header(
	   -type=>'text/plain',
	   -status=> '400 folder doesn\'t exist'
	);
	exit;
}

print $cgi->header(
	-type => 'text/html',
	-charset => 'utf-8',
);

$ftp->binary;
foreach my $file (@files) {
	my $remotePath = "$path/$file";
	my $localPath = "$localPath/$file";
	$ftp->get(encode_utf8($remotePath), $localPath);
}

foreach my $folder (@folders) {
	my $remotePath = "$path/$folder";
	my $localPath = "$localPath/$folder";

	mkdir($localPath);
	chdir($localPath);
	get_recursive(encode_utf8($remotePath));
	chdir($RealBin);
}

$ftp->quit;

sub get_recursive {
	my ($folder) = @_;
	foreach my $f ($ftp->dir($folder)) {
		$f =~ s/ +/ /gi;
		my @parts = split(/ /, $f);
		my $perm = @parts[0];
		my $name = join(" ", @parts[8..(scalar(@parts) - 1)]);
		if ($perm =~ /^d/) {
			mkdir($name);
			chdir($name);
			get_recursive("$folder/$name");
			chdir("..");
		} else {
			$ftp->get("$folder/$name", $name);
		}
	}
}