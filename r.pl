#!/usr/bin/env perl
#[ivrsql]
#exten => *777,1,Answer()
#exten => *777,n,Wait(1)
#exten => *777,n,AGI(sqlmenu.agi)
#exten => *777,n,Hangup()
use warnings;
use strict;
use Asterisk::AGI;
use DBI;
#$|=1;

my $AGI = new Asterisk::AGI;
my %input = $AGI->ReadParse();

### Play "welcome.gsm", greeting the caller 

$AGI->stream_file('welcome');

### Play "product-code-prompt.gsm", instructing the caller to enter the 
### product code, then allow ten seconds to enter four-digits

my $prodcode = $AGI->get_data('product',10000,4);
my $quantity = &quan_by_code($prodcode);

#$AGI->verbose("prodcode=$prodcode\n", 1);


sub quan_by_code {
### Takes a product code as input, then returns the quantity available.
        my $code = shift;
        my $dbh = open_connection();
        #//'SELECT `operator`,`region` FROM `codes` WHERE 4404417 BETWEEN `code_from` AND `code_to` AND `code_abcdef`=952;'
		#//'SELECT `region`,`operator` FROM `codes` WHERE `code_abcdef`= ? AND ? > `code_from` AND ? < `code_to`'
        'SELECT `region` FROM `codes` WHERE `code_abcdef`= ? AND ? > `code_from` AND ? < `code_to` LIMIT 1'
        my $sql = "SELECT code, quantity FROM product WHERE code=\'$code\' LIMIT 1";
        my $sth = $dbh->prepare($sql);
        $sth->execute or die "Unable to execute SQL query: $dbh->errstr\n";
        my $row = $sth->fetchrow_arrayref;
        $sth->finish;
        $dbh->disconnect;
        if ( ($row->[0] == "Нижегородская область"){
                return 1;
        } else {
                return 0;
        }
}

sub open_connection {
        my $database = "telnumbers";
        my $hostname = "localhost";
        my $username = "asteriskuser";
        my $password = "amp109";
        my $dsn = "mysql:$database:$hostname";
        return DBI->connect("DBI:$dsn",$username,$password) or die $DBI::errstr;
}
