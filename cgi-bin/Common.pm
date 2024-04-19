#!"C:\Dwimperl\perl\bin\perl.exe"
package Common;
use Net::FTP;
use Encode qw(encode decode);

sub connectToFTPServer {
    my ($host, $login, $password) = @_;

    my $ftp = Net::FTP->new($host, Timeout => 2);
    return undef unless $ftp;
    
    my $successLogin = $ftp->login($login, $password);
    return undef unless $successLogin;
    
    return $ftp;
}

1;