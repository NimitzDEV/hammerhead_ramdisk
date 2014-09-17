#!/sbin/busybox sh

BB=/sbin/busybox;

case "$1" in
	CPUFrequencyList)
		for CPUFREQ in `$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies`; do
		LABEL=$((CPUFREQ / 1000));
			$BB echo "$CPUFREQ:\"${LABEL} MHz\", ";
		done;
	;;
	CPUGovernorList)
		for CPUGOV in `$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors`; do
			$BB echo "\"$CPUGOV\",";
		done;
	;;
	DebugPVS)
		$BB echo "ACPU PVS";
	;;
	DebugSPEED)
		$BB echo "SPEED BIN";
	;;
	DefaultCPUMaxFrequency)
		while read FREQ TIME; do
			if [ $FREQ -le "2260000" ]; then
				MAXCPU=$FREQ;
			fi;
		done < /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state;

		$BB echo $MAXCPU;
	;;
	DefaultCPUMinFrequency)
		S=0;
		while read FREQ TIME; do
			if [ $FREQ -ge "300000" ] && [ $S -eq "0" ]; then
				S=1;
				MINCPU=$FREQ;
			fi;
		done < /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state;

		$BB echo $MINCPU;
	;;
	DefaultGPUGovernor)
		$BB echo "`$BB cat /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/governor`"
	;;
	DirKernelIMG)
		$BB echo "/dev/block/platform/msm_sdcc.1/by-name/boot";
	;;
	DirCPUGovernor)
		$BB echo "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor";
	;;
	DirCPUGovernorTree)
		$BB echo "/sys/devices/system/cpu/cpufreq";
	;;
	DirCPUMaxFrequency)
		$BB echo "/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq";
	;;
	DirCPUMinFrequency)
		$BB echo "/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq";
	;;
	DirGPUGovernor)
		$BB echo "/sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/governor";
	;;
	DirGPUMaxFrequency)
		$BB echo "/sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/max_freq";
	;;
	DirGPUMinPwrLevel)
		$BB echo "/sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/min_freq";
	;;
	#DirGPUNumPwrLevels)
	#	$BB echo "/sys/class/kgsl/kgsl-3d0/num_pwrlevels";
	#;;
	#DirGPUPolicy)
	#	$BB echo "/sys/class/kgsl/kgsl-3d0/pwrscale/policy"; 
	#;;	
	DirIOReadAheadSize)
		$BB echo "/sys/block/mmcblk0/queue/read_ahead_kb";
	;;
	DirIOScheduler)
		$BB echo "/sys/block/mmcblk0/queue/scheduler";
	;;
	DirIOSchedulerTree)
		$BB echo "/sys/block/mmcblk0/queue/iosched";
	;;
	DirTCPCongestion)
		$BB echo "/proc/sys/net/ipv4/tcp_congestion_control";
	;;
	GPUFrequencyList)
		for GPUFREQ in `$BB cat /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/available_frequencies`; do
			LABEL=$((GPUFREQ / 1000000));
			$BB echo "$GPUFREQ:\"${LABEL} MHz\", ";
		done;
	;;
	GPUGovernorList)
		for GPUGOV in `$BB cat /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/available_governors`; do
			$BB echo "\"$GPUGOV\",";
		done;
	;;
	GPUPowerLevel)
		for GPUFREQ in `$BB cat /sys/devices/fdb00000.qcom,kgsl-3d0/devfreq/fdb00000.qcom,kgsl-3d0/available_frequencies`; do
			LABEL=$((GPUFREQ / 1000000));
			$BB echo "$GPUFREQ:\"${LABEL} MHz\", ";
		done;
	;;
	HasBootloader)
		$BB echo "1";
	;;
	HasTamperFlag)
		$BB echo "1";
	;;
	IOSchedulerList)
		for IOSCHED in `$BB cat /sys/block/mmcblk0/queue/scheduler | $BB sed -e 's/\]//;s/\[//'`; do
			$BB echo "\"$IOSCHED\",";
		done;
	;;
	LiveBatteryTemperature)
		BAT_C=`$BB awk '{ print $1 / 10 }' /sys/class/power_supply/battery/temp`;
		BAT_F=`$BB awk "BEGIN { print ( ($BAT_C * 1.8) + 32 ) }"`;
		BAT_H=`$BB cat /sys/class/power_supply/battery/health`;

		$BB echo "$BAT_C°C | $BAT_F°F@nHealth: $BAT_H";
	;;
	LiveBootloader)
		version=`getprop ro.bootloader`;
		
		block=/dev/block/platform/msm_sdcc.1/by-name/misc;
		offset=16400;
		locked=00;
		unlocked=01;
		tamper=16404;
		false=00;
		true=01;
		
		lockstate=`$BB dd ibs=1 count=1 skip=$offset if=$block 2> /dev/null | $BB od -h | $BB head -n 1 | $BB cut -c 11-`;
		tamperstate=`$BB dd ibs=1 count=1 skip=$tamper if=$block 2> /dev/null | $BB od -h | $BB head -n 1 | $BB cut -c 11-`;
		
		if [ $lockstate == $locked ]; then
			state="Locked";
		elif [ $lockstate == $unlocked ]; then
			state="Unlocked";
		else
			state="Unknown";
		fi;
		
		if [ $tamperstate == $false ]; then
			tamper="False";
		elif [ $tamperstate == $true ]; then
			tamper="True";
		else
			tamper="Unknown";
		fi;
		
		$BB echo "Version: $version@nState: $state@nTamper: $tamper";
	;;
	LiveCPUFrequency)
		CPU0=`$BB cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2> /dev/null`;
		CPU1=`$BB cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_cur_freq 2> /dev/null`;
		CPU2=`$BB cat /sys/devices/system/cpu/cpu2/cpufreq/scaling_cur_freq 2> /dev/null`;
		CPU3=`$BB cat /sys/devices/system/cpu/cpu3/cpufreq/scaling_cur_freq 2> /dev/null`;
		
		if [ -z "$CPU0" ]; then CPU0="Offline"; else CPU0="$((CPU0 / 1000)) MHz"; fi;
		if [ -z "$CPU1" ]; then CPU1="Offline"; else CPU1="$((CPU1 / 1000)) MHz"; fi;
		if [ -z "$CPU2" ]; then CPU2="Offline"; else CPU2="$((CPU2 / 1000)) MHz"; fi;
		if [ -z "$CPU3" ]; then CPU3="Offline"; else CPU3="$((CPU3 / 1000)) MHz"; fi;
		
		$BB echo "Core 0: $CPU0@nCore 1: $CPU1@nCore 2: $CPU2@nCore 3: $CPU3";
	;;
	LiveCPUTemperature)
		CPU_C=`$BB cat /sys/class/thermal/thermal_zone7/temp`;
		CPU_F=`$BB awk "BEGIN { print ( ($CPU_C * 1.8) + 32 ) }"`;

		$BB echo "$CPU_C°C | $CPU_F°F";
	;;
	LiveGPUFrequency)
		GPUFREQ="$((`$BB cat /sys/class/kgsl/kgsl-3d0/gpuclk` / 1000000)) MHz";
		$BB echo "$GPUFREQ";
	;;
	LiveMemory)
		while read TYPE MEM KB; do
			if [ "$TYPE" = "MemTotal:" ]; then
				TOTAL="$((MEM / 1024)) MB";
			elif [ "$TYPE" = "MemFree:" ]; then
				CACHED=$((MEM / 1024));
			elif [ "$TYPE" = "Cached:" ]; then
				FREE=$((MEM / 1024));
			fi;
		done < /proc/meminfo;
		
		FREE="$((FREE + CACHED)) MB";
		$BB echo "Total: $TOTAL@nFree: $FREE";
	;;
	LiveTime)
		STATE="";
		CNT=0;
		SUM=`$BB awk '{s+=$2} END {print s}' /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state`;
		
		while read FREQ TIME; do
			if [ "$CNT" -ge $2 ] && [ "$CNT" -le $3 ]; then
				FREQ="$((FREQ / 1000)) MHz:";
				if [ $TIME -ge "100" ]; then
					PERC=`$BB awk "BEGIN { print ( ($TIME / $SUM) * 100) }"`;
					PERC="`$BB printf "%0.1f\n" $PERC`%";
					TIME=$((TIME / 100));
					STATE="$STATE $FREQ `$BB echo - | $BB awk -v "S=$TIME" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'` ($PERC)@n";
				fi;
			fi;
			CNT=$((CNT+1));
		done < /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state;
		
		STATE=${STATE%??};
		$BB echo "$STATE";
	;;
	LiveUpTime)
		TOTAL=`$BB awk '{ print $1 }' /proc/uptime`;
		AWAKE=$((`$BB awk '{s+=$2} END {print s}' /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state` / 100));
		SLEEP=`$BB awk "BEGIN { print ($TOTAL - $AWAKE) }"`;
		
		PERC_A=`$BB awk "BEGIN { print ( ($AWAKE / $TOTAL) * 100) }"`;
		PERC_A="`$BB printf "%0.1f\n" $PERC_A`%";
		PERC_S=`$BB awk "BEGIN { print ( ($SLEEP / $TOTAL) * 100) }"`;
		PERC_S="`$BB printf "%0.1f\n" $PERC_S`%";
		
		TOTAL=`$BB echo - | $BB awk -v "S=$TOTAL" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'`;
		AWAKE=`$BB echo - | $BB awk -v "S=$AWAKE" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'`;
		SLEEP=`$BB echo - | $BB awk -v "S=$SLEEP" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'`;
		$BB echo "Total: $TOTAL (100.0%)@nSleep: $SLEEP ($PERC_S)@nAwake: $AWAKE ($PERC_A)";
	;;
	LiveUnUsed)
		UNUSED="";
		while read FREQ TIME; do
			FREQ="$((FREQ / 1000)) MHz";
			if [ $TIME -lt "100" ]; then
				UNUSED="$UNUSED$FREQ, ";
			fi;
		done < /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state;
		
		UNUSED=${UNUSED%??};
		$BB echo "$UNUSED";
	;;
	LiveWakelocksKernel)
		WL="";
		CNT=0;
		PATH=/sdcard/wakelocks.txt;
		$BB sort -nrk 7 /proc/wakelocks > $PATH;
		
		while read NAME COUNT EXPIRE_COUNT WAKE_COUNT ACTIVE_SINCE TOTAL_TIME SLEEP_TIME MAX_TIME LAST_CHANGE; do
			if [ $CNT -lt 10 ]; then
				NAME=`$BB echo $NAME | $BB sed 's/PowerManagerService./PMS./;s/"//g'`
				TIME=`$BB awk "BEGIN { print ( $SLEEP_TIME / 1000000000 ) }"`;
				TIME=`$BB echo - | $BB awk -v "S=$TIME" '{printf "%dh:%dm:%ds",S/(60*60),S%(60*60)/60,S%60}'`;
				WL="$WL$NAME: $TIME@n";
			fi;
			CNT=$((CNT+1));
		done < $PATH;
		$BB rm -f $PATH;
		
		WL=${WL%??};
		$BB echo $WL;
	;;
	MaxCPU)
		$BB echo "4";
	;;
	MinFreqIndex)
		ID=0;
		MAXID=8;
		while read FREQ TIME; do
			LABEL=$((FREQ / 1000));
			if [ $FREQ -gt "384000" ] && [ $ID -le $MAXID ]; then
				MFIT="$MFIT $ID:\"${LABEL} MHz\", ";
			fi;
			ID=$((ID + 1));
		done < /sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state;

		$BB echo $MFIT;
	;;
	SetCPUGovernor)
		for CPU in /sys/devices/system/cpu/cpu[1-3]; do
			$BB echo 1 > $CPU/online;
			$BB echo $2 > $CPU/cpufreq/scaling_governor;
		done;
	;;
	SetCPUMaxFrequency)
		for CPU in /sys/devices/system/cpu/cpu[1-3]; do
			$BB echo 1 > $CPU/online;
			$BB echo $2 > $CPU/cpufreq/scaling_max_freq;
		done;
	;;
	SetCPUMinFrequency)
		for CPU in /sys/devices/system/cpu/cpu[1-3]; do
			$BB echo 1 > $CPU/online;
			$BB echo $2 > $CPU/cpufreq/scaling_min_freq;
		done;
	;;
	SetGPUMinPwrLevel)
		if [[ ! -z $3 ]]; then
			$BB echo $3 > $2;
		fi;
		
		$BB echo `$BB cat $2`;
	;;
	SetGPUGovernor)
		if [[ ! -z $3 ]]; then
			$BB echo $3 > $2 2> /dev/null;
		fi;
		
		$BB echo `$BB cat $2`;
	;;
	TCPCongestionList)
		for TCPCC in `$BB cat /proc/sys/net/ipv4/tcp_available_congestion_control` ; do
			$BB echo "\"$TCPCC\",";
		done;
	;;
	ToggleBootloader)
		block=/dev/block/platform/msm_sdcc.1/by-name/misc;
		offset=16400;
		locked=00;
		unlocked=01;
		lockstate=`$BB dd ibs=1 count=1 skip=$offset if=$block 2> /dev/null | $BB od -h | $BB head -n 1 | $BB cut -c 11-`;

		if [ $lockstate == $locked ]; then
			$BB echo "Setting state to Unlocked...";
			setstate=$unlocked;
		elif [ $lockstate == $unlocked ]; then
			$BB echo "Setting state to Locked...";
			setstate=$locked;
		else
			$BB echo "State is Unknown. No changes were made.";
		fi;
		
		if [ -n "$setstate" ]; then
			$BB echo -ne "\x$setstate" | $BB dd obs=1 count=1 seek=$offset of=$block 2> /dev/null;
		fi;
	;;
	ToggleTamper)
		block=/dev/block/platform/msm_sdcc.1/by-name/misc;
		offset=16404;
		false=00;
		true=01;
		tamperstate=`$BB dd ibs=1 count=1 skip=$offset obs=1 if=$block 2> /dev/null | $BB od -h | $BB head -n 1 | $BB cut -c 11-`;

		if [ $tamperstate == $true ]; then
			$BB echo "Setting tamper flag to False...";
			setstate=$false;
		elif [ $tamperstate == $false ]; then
			$BB echo "Setting tamper flag to True...";
			setstate=$true;
		else
			"Tamper is Unknown. No changes were made.";
		fi;
		
		if [ -n "$setstate" ]; then
			$BB echo -ne "\x$setstate" | $BB dd obs=1 count=1 seek=$offset of=$block 2> /dev/null;
		fi;
	;;
esac;
