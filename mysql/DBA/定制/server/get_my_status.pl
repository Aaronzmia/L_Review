#!/usr/bin/perl
use DBI;
use strict;
use warnings;
use POSIX ":sys_wait_h";
use Data::Dumper;

BEGIN {    
	unshift @INC, '/usr/local/nagios/patrol/lib/';
}

use mon qw(instance_islive);
my $pid;
my ($user , $pw) = ('patrol_user', 'patrol_user');
my ($dbh, $sth, $query, $dosql, $ref);
my ($dbp,%stats, @row, $req);
my @today = localtime(time());
my $now = sprintf(    "%4d-%02d-%02d %02d:%02d:%02d",
    $today[5] + 1900,
    $today[4] + 1,
    $today[3],
    $today[2],
    $today[1],
    $today[0]);


my_connect();

#取出所有的instance_id
$ref = $dbh->selectall_hashref(q{select instance_id,host_id, host_ip, port, ismaster, islive, state, instance_name, group_id from global_instance_lists}, 1);
#print Dumper($ref);
foreach my $iid (keys %$ref){

		print $iid."\n";	
		my $status=instance_islive($ref->{$iid}{host_ip}, $ref->{$iid}{port});

		print "$ref->{$iid}{host_ip}, $ref->{$iid}{port} : $status\n";

		if( $ref->{$iid}{islive} eq 'Y' and $status != 0){
			print "$ref->{$iid}{instance_name} $ref->{$iid}{host_ip}, $ref->{$iid}{port} down!\n";
			$ref->{$iid}{islive}='N';
			$query="update global_instance_lists set islive='N' where instance_id=$ref->{$iid}{instance_id}";
			print "$query\n";
		}

		if($ref->{$iid}{islive} eq 'N'  and $status==0){
			$ref->{$iid}{islive}='Y';
			$query="update global_instance_lists set islive='Y' where instance_id=$ref->{$iid}{instance_id}";
			print $query."\n";
		}

		if($ref->{$iid}{islive} eq 'Y' and $ref->{$iid}{state} eq 'Y')
		{
			$pid=fork();
			if(!defined($pid)){
				print "[EE] Error in fork at get_my_status: $!\n";
				exit(1);
			}
			if($pid == 0){
			print "$ref->{$iid}{host_ip}, $ref->{$iid}{port} get status\n";	
			do_get_status($ref->{$iid}{host_id}, $ref->{$iid}{instance_id}, $ref->{$iid}{host_ip}, $ref->{$iid}{port}, $ref->{$iid}{ismaster});
			undef $ref;
			exit(0);
			}else{
				waitpid($pid, 0);
			}
		}
		
}

while((my $collect = waitpid(-1, WNOHANG)) > 0){
1;
}
#----------------------------------------------------------------


#-----------------------------------------------------------------
print "end\n";
my_disconnect();
exit(0);

#----------------------------------------------------------------

sub my_connect{
	my $dsn="DBI:mysql:patrol_db:host=192.168.110.18:port=3306";
	$dbh = DBI->connect($dsn, 'monitor', 'monitoradmin', { RaiseError => 1, PrintError => 0 } );
	$dbh->{mysql_auto_reconnect} = 1;
}

sub my_disconnect{
#	$sth->finish();
	$dbh->disconnect();
}
#-----------------------------------------------------------------
sub connect_to_mysql{
	my ($host, $port,$dcon) = @_;
	my $dsn;
	$dsn="DBI:mysql:host=$host;". ($port ? ";port=$port" : "");
	$$dcon=DBI->connect($dsn, $user, $pw) or print" $dsn, $user, $pw连接失败\n";
}

sub get_status{
	my $g_status=$dbp->prepare("show global status;");
	#my $g_status=$dbp->prepare("select version()");
	undef %stats;
	$g_status->execute();
	while(@row = $g_status->fetchrow_array()) { $stats{$row[0]}=$row[1]; } 
	$dbp->disconnect();
}

sub get_ip_conn{
	my ($instance_id, $host_id ) = @_;
	#print "EE --> $instance_id, $host_id \n";
	my $rr = "insert into my_conn_ip(instance_id, host_id, ip, num, add_time) values";
	my $ip_c=$dbp->prepare("select substring_index(host,':',1) IP,count(*) as num from information_schema.PROCESSLIST where DB IS NOT NULL group by IP");
	$ip_c->execute();
	if($ip_c->rows()){
	while(@row=$ip_c->fetchrow_array()){
	#	print Dumper(@row);
		$rr .= "($instance_id, $host_id, '$row[0]', $row[1], '$now'),";
	}
	chop($rr);	
	#print $rr."\n";
	$dbh->do($rr);
	
	}	
	
	#$dbp->disconnect();
}
#----------------------------------------------------------------------------------
sub get_slave_info {	
	my ($instance_id, $host_id) = @_;
	my $r;
	eval{
		local $SIG{ALRM} = sub { die 'TIMEOUT' };
		alarm(30);
		$r = $dbp->selectall_hashref('show slave status', 1);
		alarm(0);        
	};        
	if($@) { 
		print "Unknown: Unable to get slave status\n";
		print "Timeout 30\n";
	}       
	if( %{$r} ) { 
		my $repl_stats= ( values( %{$r} ))[0];
#		print Dumper(%$repl_stats);
	       
 my $ri= "insert into my_repl_status set 
			instance_id	=	$instance_id,	\
			host_id		=	$host_id,	\
			add_time	=	'$now',		\
			master_host	=	if('$repl_stats->{Master_Host}','$repl_stats->{Master_Host}','undef'), \
			master_log_file	=	if('$repl_stats->{Master_Log_File}','$repl_stats->{Master_Log_File}','undef'), \
			master_log_pos	=	$repl_stats->{Read_Master_Log_Pos},\
			relay_master_log_file	=	if('$repl_stats->{Relay_Master_Log_File}','$repl_stats->{Relay_Master_Log_File}','undef'), \
			sql_thread		=	if('$repl_stats->{Slave_SQL_Running}'='Yes','Y','N'), \
			io_thread		=	if('$repl_stats->{Slave_IO_Running}'='Yes','Y','N'), \
			exec_master_log_pos	=	$repl_stats->{Exec_Master_Log_Pos}";

		if(defined($repl_stats->{Seconds_Behind_Master})){
		$ri .= ",behined=$repl_stats->{Seconds_Behind_Master}";
		}else{
		$ri .= ",behined=-1";
		}
		if(uc($repl_stats->{'Slave_IO_Running'}) ne 'YES' || uc($repl_stats->{'Slave_SQL_Running'}) ne 'YES')
		{
				$ri .= ",flags='N', error_msg='$repl_stats->{Last_Error}'";
		}
	
#		print "$ri\n";

		$dbh->do($ri);	
	}else{
		print "CRITICAL : Slave Not Configure\n";
	}
}

#-----------------------------------------------------------------------------------

sub do_get_status{
	my ($host_id, $instance_id, $host_ip, $port, $ismaster) = @_;
	connect_to_mysql($host_ip,$port,\$dbp);
	get_ip_conn($instance_id, $host_id);
	if($ismaster eq 'N'){
	get_slave_info($instance_id, $host_id);
	}
	get_status;
#	print Dumper(%stats);
#------------------------------------------------------------------------------------
	my $rr="insert into my_status_logs set instance_id=$instance_id,host_id=$host_id,add_time='$now'";
	foreach my $key ('Aborted_clients', 'Aborted_connects', 'Binlog_cache_disk_use', 'Binlog_cache_use', 'Bytes_received', 'Bytes_sent','Com_call_procedure', 'Com_commit', 'Com_delete', 'Com_delete_multi', 'Com_insert', 'Com_kill', 'Com_prepare_sql', 'Com_select', 'Com_truncate','Com_update', 'Com_update_multi', 'Connections', 'Created_tmp_disk_tables', 'Created_tmp_files', 'Created_tmp_tables', 'Handler_delete', 'Handler_update','Handler_write', 'Max_used_connections', 'Open_files', 'Open_tables', 'Opened_files', 'Opened_tables', 'Table_locks_immediate', 'Table_locks_waited', 'Threads_cached', 'Threads_connected', 'Threads_created', 'Threads_running', 'Uptime')
	{   

		$rr .= ",$key = $stats{$key}"; 
	}
	$dbh->do($rr);

#---------------------------------------------------------------------------------------
	$rr="insert into my_innodb_status_logs set instance_id=$instance_id,host_id=$host_id,AddTime='$now'";
	foreach my $key ('Innodb_buffer_pool_pages_data', 'Innodb_buffer_pool_pages_dirty', 'Innodb_buffer_pool_pages_flushed', 'Innodb_buffer_pool_pages_free', 'Innodb_buffer_pool_pages_misc', 'Innodb_buffer_pool_pages_total', 'Innodb_buffer_pool_read_requests', 'Innodb_buffer_pool_reads', 'Innodb_buffer_pool_wait_free', 'Innodb_buffer_pool_write_requests', 'Innodb_data_fsyncs', 'Innodb_data_read', 'Innodb_data_reads', 'Innodb_data_writes', 'Innodb_data_written', 'Innodb_dblwr_pages_written', 'Innodb_dblwr_writes', 'Innodb_log_waits', 'Innodb_log_write_requests', 'Innodb_log_writes', 'Innodb_os_log_fsyncs', 'Innodb_os_log_pending_fsyncs', 'Innodb_os_log_pending_writes','Innodb_os_log_written', 'Innodb_pages_created', 'Innodb_pages_read', 'Innodb_pages_written', 'Innodb_row_lock_current_waits', 'Innodb_row_lock_time','Innodb_row_lock_time_avg', 'Innodb_row_lock_time_max', 'Innodb_row_lock_waits', 'Innodb_rows_deleted', 'Innodb_rows_inserted', 'Innodb_rows_read', 'Innodb_rows_updated')
	{
		$rr .= ",$key = $stats{$key}";
	}	 
	$dbh->do($rr);
#--------------------------------相关计算---------------------------------
$rr="select instance_id, sselect, uupdate,iinsert, ddelete, ccall, q_rows_inserted, q_rows_updated, q_rows_deleted, q_rows_read, i_rows_inserted, i_rows_updated, i_rows_deleted, i_rows_read, sendbyte, recivebyte, innodb_data_read, innodb_data_written, innodb_data_reads, innodb_data_writes, innodb_pages_read, innodb_pages_written, innodb_pages_created, innodb_buffer_pool_read_requests, innodb_buffer_pool_reads, innodb_os_log_written, aborted_connects, threads_created, uptime from my_unique_log where instance_id=$instance_id";

my $iref =  $dbh->selectall_hashref($rr, 1);
#print Dumper($iref);

#--------------------------------active-------------------------------------
if($stats{Uptime} > $iref->{$instance_id}{uptime}){
	my $t = $stats{Uptime} - $iref->{$instance_id}{uptime};
	#my_active
	$req->{sselect} = ( $stats{Com_select} - $iref->{$instance_id}{sselect} )/$t;
	$req->{uupdate} = ( $stats{Com_update}+$stats{Com_update_multi} - $iref->{$instance_id}{uupdate} )/$t;
	$req->{ddelete} = ( $stats{Com_delete}+$stats{Com_delete_multi} - $iref->{$instance_id}{ddelete} )/$t;
	$req->{iinsert} = ( $stats{Com_insert}+$stats{Com_insert_select} - $iref->{$instance_id}{iinsert} )/$t;
	$req->{ccall} = ( $stats{Com_call_procedure} - $iref->{$instance_id}{ccall} )/$t;
	$req->{q_rows_inserted} = ( $stats{Handler_write} - $iref->{$instance_id}{q_rows_inserted} )/$t;
	$req->{q_rows_updated}	= ( $stats{Handler_update} - $iref->{$instance_id}{q_rows_updated} )/$t;
	$req->{q_rows_deleted}	= ( $stats{Handler_delete} - $iref->{$instance_id}{q_rows_deleted} )/$t;

	#print Dumper($req);	
	
	$rr="insert into my_active set \
	instance_id	=	$instance_id, \
	host_id		=	$host_id,	\
	add_time	=	'$now',		\
	sselect		= 	$req->{sselect}, \
	iinsert		=	$req->{iinsert}, \
	uupdate		=	$req->{uupdate}, \
	ddelete		=	$req->{ddelete}, \
	ccall		=	$req->{ccall},	\
	q_rows_inserted	=	$req->{q_rows_inserted}, \
	q_rows_updated	= 	$req->{q_rows_updated}, \
	q_rows_deleted	= 	$req->{q_rows_deleted}";
	$dbh->do($rr);
	
	undef $req;
	
#------------------------------------------------------------------------------
	#my_innodb_io_status
	$req->{data_read} = ( $stats{Innodb_data_read} - $iref->{$instance_id}{innodb_data_read} )/$t;
	$req->{data_written} = ( $stats{Innodb_data_written} - $iref->{$instance_id}{innodb_data_written} )/$t;
	$req->{pages_read} = ( $stats{Innodb_pages_read} - $iref->{$instance_id}{innodb_pages_read} )/$t;
	$req->{pages_written} = ( $stats{Innodb_pages_written} - $iref->{$instance_id}{innodb_pages_written} )/$t;
	$req->{pages_created} = ( $stats{Innodb_pages_created} - $iref->{$instance_id}{innodb_pages_created} )/$t;
	$req->{data_reads} = ( $stats{Innodb_data_reads} - $iref->{$instance_id}{innodb_data_reads} )/$t;
	$req->{data_writes} = ( $stats{Innodb_data_writes} - $iref->{$instance_id}{innodb_data_writes} )/$t;
	$req->{bp_read_requests} = ($stats{Innodb_buffer_pool_read_requests} - $iref->{$instance_id}{innodb_buffer_pool_read_requests} )/$t;
	$req->{bp_reads} = ( $stats{Innodb_buffer_pool_reads} - $iref->{$instance_id}{innodb_buffer_pool_reads}	)/$t;
	$req->{log_written} = ( $stats{Innodb_os_log_written} - $iref->{$instance_id}{innodb_os_log_written} )/$t;
	
	$rr="insert into my_innodb_io_status set \
	instance_id	=	$instance_id, \
	host_id		= 	$host_id,	\
	add_time	=	'$now',		\
	data_read	=	$req->{data_read},	\
	data_written	=	$req->{data_written},	\
	pages_read	=	$req->{pages_read},	\
	pages_written	= 	$req->{pages_written},	\
	pages_created	=	$req->{pages_created}, 	\
	data_reads	= 	$req->{data_reads},	\
	data_writes	=	$req->{data_writes},	\
	bp_read_requests=	$req->{bp_read_requests},\
	bp_reads	=	$req->{bp_reads},	\
	log_written	= 	$req->{log_written}";
	#print "$rr\n";
	$dbh->do($rr);
	
	undef $req;
	
#------------------------------------------------------------------------------
	#my_innodb_row_active
	$req->{rows_read} 	=	( $stats{Innodb_rows_read} - $iref->{$instance_id}{i_rows_read} )/$t;
	$req->{rows_inserted}	=	( $stats{Innodb_rows_inserted} - $iref->{$instance_id}{i_rows_inserted} )/$t;
	$req->{rows_updated} 	= 	( $stats{Innodb_rows_updated} - $iref->{$instance_id}{i_rows_updated} )/$t;
	$req->{rows_deleted}	=	( $stats{Innodb_rows_deleted} -	$iref->{$instance_id}{i_rows_deleted} )/$t;
#把bp的命中情况限于更小的区间做对比
	#print "$stats{Innodb_buffer_pool_read_requests} - $iref->{$instance_id}{innodb_buffer_pool_read_requests}||$stats{Innodb_pages_read} - $iref->{$instance_id}{innodb_pages_read} \n";
	if( (($stats{Innodb_buffer_pool_read_requests} - $iref->{$instance_id}{innodb_buffer_pool_read_requests} ) == 0) || ($stats{Innodb_buffer_pool_reads} - $iref->{$instance_id}{innodb_buffer_pool_reads})==0 ){
		$req->{bp_hit}		= 100;
	}else{
		$req->{bp_hit}		=   (100 - (( $stats{Innodb_buffer_pool_reads} - $iref->{$instance_id}{innodb_buffer_pool_reads} )/( $stats{innodb_buffer_pool_read_requests} - $iref->{$instance_id}{Innodb_buffer_pool_read_requests} )*100));
	}
	print "bp_hit : $req->{bp_hit}\n";
	$rr="insert into my_innodb_row_active set \
	instance_id		=	$instance_id,		\
	host_id			= 	$host_id,		\
	add_time		=	'$now',			\
	rows_read		=	$req->{rows_read},	\
	rows_inserted		=	$req->{rows_inserted},	\
	rows_updated		=	$req->{rows_updated},	\
	rows_deleted		=	$req->{rows_deleted},	\
	bp_hit			=	$req->{bp_hit}";
	
#	print "$rr\n";
	$dbh->do($rr);
#------------------------------------------------------------------------------
	undef	$req;
	#my_traffic
	$req->{sendbyte} 	=	( $stats{Bytes_sent} - $iref->{$instance_id}{sendbyte} )/$t;
	$req->{recivebyte}	=	( $stats{Bytes_received} - $iref->{$instance_id}{recivebyte} )/$t;
	
	$rr = "insert into my_traffic set \
	instance_id	= $instance_id,		\
	host_id		= $host_id,		\
	add_time	= '$now',		\
	sendbyte	= $req->{sendbyte},	\
	recivebyte	= $req->{recivebyte}";
#	print "$rr\n";
	$dbh->do($rr);
#-----------------------------------------------------------------------------
	undef	$req;
	#my_conn
	$req->{aborted_connects}	= ( $stats{Aborted_connects} - $iref->{$instance_id}{aborted_connects} )/$t;
	$req->{threads_created}		= ( $stats{Threads_created} - $iref->{$instance_id}{threads_created} )/$t;
	
	$rr = "insert into my_conn set \
	instance_id	=	$instance_id,	\
	host_id		=	$host_id,	\
	add_time	=	'$now',		\
	run		= 	$stats{Threads_running}, \
	cached		=	$stats{Threads_cached},	\
	max_conn	=	$stats{Max_used_connections}, \
	aborted_conn	=	$req->{aborted_connects},		\
	threads_created	=	$req->{threads_created}";
#	print "$rr\n";
	$dbh->do($rr);
	undef $req;
} 

#------------------------------------------------------------------------------
#留下本次取到的值,以便下次取值做对比使用.
$rr="replace into my_unique_log set \
instance_id=$instance_id, \
host_id=$host_id, \
sselect=$stats{Com_select}, \
uupdate=$stats{Com_update}+$stats{Com_update_multi}, 		\
ddelete=$stats{Com_delete}+$stats{Com_delete_multi}, 		\
iinsert			=	$stats{Com_insert_select}+$stats{Com_insert}, \
ccall			=	$stats{Com_call_procedure}, 	\
q_rows_inserted 	=	$stats{Handler_write}, 		\
q_rows_updated		=	$stats{Handler_update}, 	\
q_rows_deleted		=	$stats{Handler_delete},		\
i_rows_inserted		=	$stats{Innodb_rows_inserted},	\
i_rows_updated		=	$stats{Innodb_rows_updated},	\
i_rows_deleted		=	$stats{Innodb_rows_deleted},	\
i_rows_read		=	$stats{Innodb_rows_read},	\
sendbyte		=	$stats{Bytes_sent},		\
recivebyte		=	$stats{Bytes_received},		\
innodb_data_read	=	$stats{Innodb_data_read},	\
innodb_data_written	=	$stats{Innodb_data_written},	\
innodb_data_reads	=	$stats{Innodb_data_reads},	\
innodb_data_writes	=	$stats{Innodb_data_writes},	\
innodb_pages_read	=	$stats{Innodb_pages_read},	\
innodb_pages_written	=	$stats{Innodb_pages_written},	\
innodb_pages_created	=	$stats{Innodb_pages_created},	\
innodb_buffer_pool_read_requests=$stats{Innodb_buffer_pool_read_requests}, \
innodb_buffer_pool_reads=	$stats{Innodb_buffer_pool_reads}, \
innodb_os_log_written	=	$stats{Innodb_os_log_written}, \
aborted_connects	= 	$stats{Aborted_connects}, 	\
threads_created		=	$stats{Threads_created},	\
uptime=$stats{Uptime}";
#print $rr."\n";
$dbh->do($rr);
#-------------------------------------------------------------------------------

print "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n";

}
