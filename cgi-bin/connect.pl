#!"C:\Dwimperl\perl\bin\perl.exe"
use CGI qw(:all);
use Net::FTP;
use JSON;
use DBUtil;
use Common;

my $cgi = CGI->new();

my %data = %{JSON::decode_json($cgi->param('POSTDATA'))};

my $ftp = Common::connectToFTPServer($data{host}, $data{user}, $data{password});
unless ($ftp) {
	print $cgi->header(
		-type=>'text/plain',
		-status=> '401 Connection error'
	);
	exit;
}

my $db = DBUtil::create_connection();
my $query = "SELECT * FROM user WHERE login = '$data{user}' AND password = '$data{password}'";
my $sth = $db->prepare($query);
$sth->execute();

my @existedUser = $sth->fetchrow_array();
my ($userId, $username);
unless(@existedUser) {
	my $query = "INSERT INTO user (login, password) VALUES ('$data{user}', '$data{password}')";
	my $sth = $db->prepare($query);
	$sth->execute();

	$query = "SELECT last_insert_rowid()";
	$sth = $db->prepare($query);
	$sth->execute();

	my @lastId = $sth->fetchrow_array();
	($userId, $username) = ($lastId[0], $data{user});
} else {	
	($userId, $username) = ($existedUser[0], $existedUser[1]);
}

print header('text/html','200 Success connect');
print JSON::encode_json({id => $userId, username => $username});
$ftp->quit;