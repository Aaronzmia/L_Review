#!/usr/bin/perl
use DBI;
use strict;
use warnings;
use POSIX ":sys_wait_h";
use Data::Dumper;
BEGIN {    
	unshift @INC, '/usr/local/nagios/patrol/lib/';
}

use mon qw(islive  get_cpu get_load get_mem get_traffic get_disk_status);
my  $command_list="get_load get_cpu";
my $pid;

my ($dbh, $sth, $query, $dosql, $ref);
my @today = localtime(time());
my $now = sprintf(    "%4d-%02d-%02d %02d:%02d:%02d",
    $today[5] + 1900,
    $today[4] + 1,
    $today[3],
    $today[2],
    $today[1],
    $today[0]);


my_connect();


$ref = $dbh->selectall_hashref(q{select * from global_host_lists}, 1);
#print Dumper($ref);
foreach my $hid (keys %$ref){
	if($ref->{$hid}{state} eq 'Y'){
		$pid = fork();
		if(!defined($pid)){
			print "[EE] Error in fork:$!\n";
			exit(1);
		}
		if($pid==0){
			print "$ref->{$hid}{host_id}, $ref->{$hid}{host_ip}, $ref->{$hid}{host_name}\n";
			$query=get_load($ref->{$hid}{host_ip},$ref->{$hid}{host_id},"$now");
			print "$query\n";
			$dbh->do("$query");
			$query=get_cpu($ref->{$hid}{host_ip},$ref->{$hid}{host_id},"$now");
			print "$query\n";
			$dbh->do("$query")
	;
			$query=get_mem($ref->{$hid}{host_ip},$ref->{$hid}{host_id},"$now");
			print "$query\n";
			$dbh->do("$query");
			$query=get_traffic($ref->{$hid}{host_ip},$ref->{$hid}{host_id},"$now");
			print "$query\n";
			$dbh->do("$query");
			exit(0);
		}else{
			waitpid($pid, 0);	
		}
	}
}

while ((my $collect = waitpid(-1, WNOHANG)) >0 ){
1;
}
#----------------------------------------------------------------
#相关的get动作


#-----------------------------------------------------------------
print "end\n";
my_disconnect();
exit(0);

#----------------------------------------------------------------

sub my_connect{
	my $dsn="DBI:mysql:patrol_db:host=192.168.110.18:port=3306";
	$dbh = DBI->connect($dsn, 'monitor', 'monitoradmin', { RaiseError => 1, PrintError => 0 } );
}

sub my_disconnect{
#	$sth->finish();
	$dbh->disconnect();
}
