#!/bin/sh

dnsmasqExec=/Users/drmingdrmer/xp/VCS/dnsmasq/src/dnsmasq
conffn=dnsmasq.local.conf

notice()
{
    syslog -s -l Notice "dnsmasq mng.sh: $*"
}
ok()
{
    notice "OK $*"
}
pid_to_watch()
{
    ps aux | grep "dnsmasq -C $conffn" | grep -v grep | awk '{print $2}'
}

if [ "x$1" == "xconf" ]; then

    cat > $conffn <<-END
	no-resolv
	no-poll
	
	# listen-address=
	
	# server=/google.com/8.8.8.8
	# server=/googleusercontent.com/8.8.8.8
	# server=/google.com/8.8.8.8
	server=/dropbox.com/8.8.8.8
	server=/ggpht.com/8.8.8.8
	server=/github.com/8.8.8.8
	server=/facebook.com/8.8.8.8
	server=/box.net/8.8.8.8
	
	address=/test/127.0.0.1
	address=/google.com/203.208.46.178
	address=/googleusercontent.com/203.208.46.178
	address=/code.google.com/74.125.31.100
	
	END

    for s in $(sh dhcpdns);do
        echo "server=/#/$s" >> $conffn
    done

    ok "Reconfigure"


elif [ "x$1" == "xrestart" ]; then

    kill $(pid_to_watch)
    $dnsmasqExec -C dnsmasq.local.conf

    notice "Restarted"

elif [ "x$1" == "xwatch" ]; then

    lockname=/var/run/bash.xp.plugin.dnsmasqconf.lock
    mkdir $lockname || { notice "Another dnsmasqconf is running"; exit 1; }
    trap "rmdir $lockname" EXIT

    notice "start to watch"
    # dig test @127.0.0.1 +time=1 +tries=1 >/dev/null && notice "service ON, quit" && exit
    # dig google.com @8.8.8.8 +time=1 +tries=1 >/dev/null || { notice "network problem, quit"; exit; }

    last=

    while ``;do

        pid=$(pid_to_watch)
        # notice pid is $pid
        cur=$(sh dhcpdns)

        if [ "x$pid" == "x" ]; then

            notice "DEAD to start"
            sh $0 conf && sh $0 restart

        else

            if [ "x$last" == "x$cur" ]; then
                # notice 'the same, sleep 5'
                sleep 5
            else
                notice 'Default DNS changed'
                sh $0 conf && sh $0 restart
            fi

        fi

        last=$cur

    done
fi
