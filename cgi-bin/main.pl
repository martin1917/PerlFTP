#!"C:\Dwimperl\perl\bin\perl.exe"
use CGI qw(:all);
use Encode qw(encode decode);
use CGI::Cookie;
use Net::FTP;
use JSON;
use Common;
use DBUtil;

sub getExt {
	my ($fileName) = @_;
	my @res = ($fileName =~ m/(.*)(\.)(.+)$/);
	return undef unless (@res);
	return @res[2];
}

my $cgi = CGI->new();

my %icons = (
	rar => "rar.png",
	zip => "zip.png",
	txt => "txt.png",
	docx => "docx.png",
	xlsx => "excel.png",
	jpg => "jpg.png",
	png => "png.png"
);

my %cookies = CGI::Cookie->fetch;
if (!defined($cookies{userId}) || !defined($cookies{host})) {
	print $cgi->header(
	   -type=>'text/plain',
	   -status=> '401 Coockies error'
	);
	exit;
}
my $host = $cookies{host}->value;
my $userId = $cookies{userId}->value;
my $username = $cookies{username}->value;

my ($id, $login, $password) = DBUtil::getUserById($userId);
my $ftp = Common::connectToFTPServer($host, $login, $password);
unless ($ftp) {
	print $cgi->header(
		-type=>'text/plain',
		-status=> '401 Connection error'
	);
	exit;
}

my $path = $cgi->param('path');

print $cgi->header(
	-type => 'text/html',
	-charset => 'utf-8',,
);

print $cgi->start_html({
	-title => 'ftp server',
	-head=>Link(
		{
			-rel=>'stylesheet', 
			-type=>'text/css', 
			-href=>'../main.css'
		}),
	-script => [ 
		{
			-type => 'text/javascript',
			-src => '../lib/jquery-3.5.1.min.js'
		},
		{
			-type => 'text/javascript',
			-src => '../main.js'
		}
	],
});

print<<HTML;
<div class="head">
    <div class="host">хост: <span style="font-weight: bold;">$host</span></div>
    <div class="user">пользователь: <span style="font-weight: bold;">$login</span></div>
    <button id="btn_disconnect">отключиться</button>
</div>
<div class="main">
    <form action="main.pl" method="post" id="updateForm" hidden>
        <input type="text" id="updateForm_input_path" name="path">
    </form>
    <form action="put.pl" method="post" id="uploadForm" hidden enctype="multipart/form-data">
        <input type="text" id="uploadForm_input_path" name="path">
        <input type="file" id="uploadForm_input_file" name="file">
    </form>
    <form action="mkdir.pl" method="post" id="mkdirForm" hidden>
        <input type="text" id="mkdirForm_input_path" name="path">
        <input type="text" id="mkdirForm_input_folderName" name="folderName">
    </form>
    <div class="container">
        <div class="files_manage">
            <div class="buttons">
                <button id="btn_download"><img src="../icons/download.png" alt="download" height="30" width="30"></button>
                <button id="btn_upload"><img src="../icons/upload.png" alt="upload" height="30" width="30"></button>
                <button id="btn_delete"><img src="../icons/delete.png" alt="upload" height="30" width="30"></button>
                <button id="btn_mkdir"><img src="../icons/mkdir.png" alt="mkdir" height="30" width="30"></button>
            </div>
            <div class="files_tree">
HTML

    my $backBtnDisabled = "disabled" unless $path;
    my $beginPath = $path;
    $beginPath = "/" unless $path;

print<<HTML;
                <div class='pwd'>
                    <button id='btn_back' $backBtnDisabled><img src='../icons/back.png' alt='back' height='10' width='10'></button>
                    <button id='btn_root' $backBtnDisabled>/</button>
                    <div>$beginPath</div>
                </div>
HTML

    foreach my $f ($ftp->dir($path)) {
        $f =~ s/ +/ /gi;
        my @parts = split(/ /, $f);
        my $perm = @parts[0];
        my $name = join(" ", @parts[8..(scalar(@parts) - 1)]);
        my $size = @parts[4];
        my $ext = getExt($name);
        
        my $icon = $icons{$ext};
        $icon = "unknown_filetype.png" unless $icon;
        
        if ($perm =~ /^d/) {
            print "<div class='file'>";
            print "    <input type='checkbox' name='cb_folder' class='cb_folder'>";
            print "    <img src='../icons/folder.png' alt='txt' height='30' width='30'>";
            print "    <div class='it_folder'>$name</div>";
            print "</div>";
        } else {
            print "<div class='file'>";
            print "    <input type='checkbox' name='cb_file' class='cb_file'>";
            print "    <img src='../icons/$icon' alt='txt' height='30' width='30'>";
            print "    <div class='file_name'>$name</div>";
            print "    <div class='file_size'> (bytes: $size)</div>";
            print "</div>";
        }
    }

print<<HTML;
            </div>
        </div>
        <div class="view">
            <div class="view_file_name">Файл: </div>
            <caption>Содержимое файла</caption>
            <div class="view_file_content"></div>
        </div>
    </div>
</div>
HTML

print $cgi->end_html;

$ftp->quit;