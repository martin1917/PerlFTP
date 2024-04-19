#!"C:\Dwimperl\perl\bin\perl.exe"
package DBUtil;
use DBI;

sub create_connection{
	my $db = DBI->connect("DBI:SQLite:../users.db","","");
	$db->{sqlite_unicode} = 1;
	return $db;
}

sub getUserById {
    my ($userId) = @_;
    my $db = create_connection();
    my $query = "SELECT * FROM user WHERE id = '$userId'";
    my $sth = $db->prepare($query);
    $sth->execute();
    my @user = $sth->fetchrow_array();
    return @user;
}

1;