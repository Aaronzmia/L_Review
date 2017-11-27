package mon;

use strict;
use warnings;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION 	= 1.00;
@ISA		= qw(Exporter);
@EXPORT		= ();
@EXPORT_OK	=qw(islive get_cpu get_load get_mem get_traffic get_diskstatus get_diskinfo instance_islive);

my $basedir = "/usr/local/nagios/libexec/";

#=================================================================== 
#this for test the host is live
#==================================================================
sub islive{
    my $islive="$basedir"."check_ping -w 50,50% -c 80,80% -p 3 -t 3 -H ";
    $islive="$islive"."@_";
    my $resulte=`$islive`;
    if ($resulte =~ /PING\ OK/)
    {
        return 0;
    }else{
        return 1;
    }
}
#=================================================================== 
#this for test the instance is live
#==================================================================
sub instance_islive{
    my ($host, $port) = @_;
    my $islive="$basedir"."check_tcp -w 50,50% -c 80,80% -p 3 -t 3 -H $host -p$port";
    my $resulte=`$islive`;
    chomp($resulte);
#    print $resulte."\n";
    if ($resulte =~ /TCP\ OK/)
    {
        return 0;
    }else{
        return 1;
    }
}



#===================================================================
#get systme cpu status
#===================================================================
sub get_cpu{
    my ($host_ip,$host_id,$now) = @_;
    my $get_cpu="$basedir"."check_nrpe -c get_cpu -t 5 -H  ";
    $get_cpu="$get_cpu"."$host_ip";
    my $result=`$get_cpu`;
    if ($result =~ /timeout/ ){
     print "get_cpu error :$result"; 
     return 0;
      }else{
        chomp($result);
	my ($status, $r1) =split('\|\|',$result);
        my %cpu_stat=map{split('=',$_)} split(',',$r1);
        #    print "user=$cpu_stat{user},nice=$cpu_stat{nice},sys=$cpu_stat{sys},iowait=$cpu_stat{iowait},cpu_total_usage=$cpu_stat{cpu_total_usage},idle=$cpu_stat{idle}\n";
        my $rr = "insert into sys_cpu(add_time,host_id,user,sys,total,idle,iowait) values('$now',$host_id,$cpu_stat{user},$cpu_stat{sys},$cpu_stat{cpu_total_usage},$cpu_stat{idle},$cpu_stat{iowait})";
        return $rr;
    }
}

#==================================================================
# get system load
#==================================================================
sub get_load{
   my ($host_ip,$host_id,$now) = @_;
    my $get_load="$basedir"."check_nrpe -c get_load -t 3 -H  ";
     $get_load="$get_load"."$host_ip";
    open (LOAD,"$get_load|");
    my $line = <LOAD>;
    close(LOAD);
    if ($line =~ /timeout/){
        print "get_sys_load error:$line";
        return 0;
    }else{
   my ($status, $r1) = split('\|\|', $line);
    my ($la1,$la5,$la15,$r,$all) = split(",",$r1);
    #print "$la1,$la5,la15,$r,$all";
    my $rr = "insert into sys_cpu_load(add_time,host_id,la1,la5,la15,run,all_process) values('$now',$host_id,$la1,$la5,$la15,$r,$all)";
    return $rr;
}
}

#==================================================================
#get disk status
#==================================================================
sub get_diskstatus{
    my ($host_ip,$host_id,$now) = @_;
    my %disk;
    my $getdisk = "$basedir"."check_nrpe -c get_diskstatus -t 3 -H ";
    $getdisk = "$getdisk"."$host_ip";
    open(DiskInfo, "$getdisk|");
    while(<DiskInfo>){
        my ($mount, $info) = split(":",$_);
        for my $dot (split " ", $info){
            my ($key,$value) = split ("=", $dot);
            $disk{$mount}{$key}=$value;
        }
    }
	close(DiskInfo);
my $rr = "insert into sys_disk_status(add_time,host_id,mount,device, total,used,free,use_per,inode,inode_used,inode_free,inode_used_per) values";
foreach my $key (sort keys %disk){
     $rr .= "('$now',$host_id,'$disk{$key}{mount}','$disk{$key}{Device}',$disk{$key}{TotalSize},$disk{$key}{UsedSize},$disk{$key}{freemb},$disk{$key}{Usepct},$disk{$key}{TotalInode},$disk{$key}{iused},$disk{$key}{ifree},$disk{$key}{iPct}),";
}
chop($rr);
  return $rr;
}

#==================================================================
#get disk info
#==================================================================
sub get_diskinfo{
	my ($host_ip,$host_id,$now) = @_;
	my $getdisk = "$basedir"."check_nrpe -c get_diskinfo -t 5 -H ";
	$getdisk = "$getdisk"."$host_ip";
	open(DiskInfo, "$getdisk|");
	my $line=<DiskInfo>;
	close(DiskInfo);
	my ($status, $r1) = split('\|\|', $line);    
#	print "$r1\n";
	my %dinfo=map{split('=',$_)} split(',',$r1);
	
	my $rr = "insert into sys_disk_info set \
		host_id		=	$host_id,		\
		add_time	=	'$now',			\
		device		=	'$dinfo{dev}',		\
		read_num	=	$dinfo{read_num},	\
		read_merge	=	$dinfo{read_merge},	\
		read_sectors	=	$dinfo{read_sectors},	\
		read_respond	=	$dinfo{read_respond},	\
		write_num	=	$dinfo{write_num},	\
		write_merge	=	$dinfo{write_merge},	\
		write_sectors	=	$dinfo{write_sectors},	\
		write_respond	=	$dinfo{write_respond},	\
		ioqueue		=	$dinfo{ioqueue},	\
		ioqueue_time	=	$dinfo{io_time},	\
		read_size	=	$dinfo{rsize},		\
		write_size	=	$dinfo{wsize},		\
		total_size	=	$dinfo{tsize}";

	return $rr;
}
#==================================================================
# get mem status
#==================================================================
sub get_mem{
    my ($host_ip,$host_id,$now) = @_;
    my $getmem = "$basedir"."check_nrpe -c get_mem -t 3 -H ";
    $getmem = "$getmem"."$host_ip";
    open(MEM,"$getmem|");
    my $line = <MEM>;
    close(MEM);
    if ($line =~ /timeout/ ){
        print "get_mem error: $line\n";
        return 0;
    }else{
    my ($total,$free) = split(" ",$line);
    my $rr = "insert into sys_mem(add_time,host_id,mem_total,mem_free) values('$now',$host_id,$total,$free)";

    return $rr;
}
}


#==================================================================
# get traffic status
#==================================================================
sub get_traffic{
    my ($host_ip,$host_id,$now) = @_;
    my $gettraffic= "$basedir"."check_nrpe -c get_traffic -t 3 -H ";
    $gettraffic = "$gettraffic"."$host_ip";
    open(TR,"$gettraffic|");
    my $line = <TR>;
    close(TR);
    if ($line =~ /timeout/ ){
        print "get_traffic error: $line\n";
        return 0;
    }else{
    my ($reciveKB,$sendKB) = split(" ",$line);
    my $rr = "insert into sys_net_traffic(add_time,host_id,reciveKB,sendKB) values('$now',$host_id,$reciveKB, $sendKB)";

    return $rr;
}
}

1;
