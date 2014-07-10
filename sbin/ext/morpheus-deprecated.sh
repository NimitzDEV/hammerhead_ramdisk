#!/system/xbin/bash

mount -o remount,rw /;
chmod -R 777 /tmp/;

# ==============================================================
# GLOBAL VARIABLES || without "local" also a variable in a function is global
# ==============================================================

FILE_NAME=$0;
DATA_DIR=/data/.chaos;
WAS_ASLEEP="false";

# ==============================================================
# INITIATE
# ==============================================================

# get values from profile
PROFILE=$(cat $DATA_DIR/.active.profile);
. "$DATA_DIR"/"$PROFILE".profile;

CPUFREQ_FIX()
{
	local state="$1";

	if [ "$state" == "awake" ]; then
		echo "$scheduler" > /sys/block/mmcblk0/queue/scheduler
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
		echo "$scaling_governor" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
	elif [ "$state" == "sleep" ]; then
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu1/cpufreq/scaling_governor
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu2/cpufreq/scaling_governor
		echo "$scaling_suspend_governor" > /sys/devices/system/cpu/cpu3/cpufreq/scaling_governor
		echo "$suspend_scheduler" > /sys/block/mmcblk0/queue/scheduler
	fi;

	if [ "$log_mode" == "0" ]; then
		log -p i -t "$FILE_NAME" "*** CPU IMMUNIZED FOR $state MODE ***";
	fi;	
}

THERMAL_CTRL()
{
	local state="$1";

	echo "$freq_step" > /sys/module/msm_thermal/parameters/freq_step

	if [ "$state" == "awake" ]; then
		echo "$limit_temp" > /sys/module/msm_thermal/parameters/limit_temp
		echo "$core_limit_temp" > /sys/module/msm_thermal/parameters/core_limit_temp
	elif [ "$state" == "sleep" ]; then
		echo "$limit_temp_suspend" > /sys/module/msm_thermal/parameters/limit_temp
		echo "$core_limit_temp_suspend" > /sys/module/msm_thermal/parameters/core_limit_temp
	fi;

	echo "$temp_hysteresis" > /sys/module/msm_thermal/parameters/temp_hysteresis
	echo "$core_temp_hysteresis" > /sys/module/msm_thermal/parameters/core_temp_hysteresis

	if [ "$log_mode" == "0" ]; then
		log -p i -t "$FILE_NAME" "*** THERMAL CONTROL IMMUNIZED FOR $state MODE ***";
	fi;
}

# if crond used, then give it root perent - if started by NXTweaks, then it will be killed in time
CROND_SAFETY()
{
	if [ "$crontab" == "on" ]; then
		pkill -f "crond";
		/res/crontab_service/service.sh;

		if [ "$log_mode" == "0" ]; then
			log -p i -t "$FILE_NAME" "*** CROND_SAFETY ***";
		fi;
		return 1;
	else
		return 0;
	fi;
}

MEM_CLEANER()
{
	if [ "$morpheus_memcleaner" == "on" ]; then
		MEM_ALL=`free | grep Mem | awk '{ print $2 }'`;
		MEM_USED=`free | grep Mem | awk '{ print $3 }'`;
		MEM_USED_CALC=$(($MEM_USED*100/$MEM_ALL));

		# do clean cache only if cache uses more than 90% of free memory.
		if [ "$MEM_USED_CALC" -gt "90" ]; then
			sync;
			sysctl -w vm.drop_caches=3;
			if [ "$log_mode" == "0" ]; then
				log -p i -t "$FILE_NAME" "*** Morpheus: Memory hog detected and cleaned. ***";
			fi;
		fi;
	fi;
}

TOUCH_FIX()
{
	# Override these values everytime, in case changed by external app
	echo "$pwrkey_suspend" > /sys/module/qpnp_power_on/parameters/pwrkey_suspend;
	echo "$wake_timeout" > /sys/android_touch/wake_timeout;
	echo "$doubletap2wake" > /sys/android_touch/doubletap2wake;
	echo "$doubletap2wake_feather" > /sys/android_touch/doubletap2wake_feather;
	echo "$s2w_s2sonly" > /sys/android_touch/s2w_s2sonly;
	echo "$sweep2wake" > /sys/android_touch/sweep2wake;
	if [ "$log_mode" == "0" ]; then
		log -p i -t "$FILE_NAME" "*** WAKE CONTROL IMMUNIZED ***";
	fi;
}

HOTPLUG_CONTROL()
{
	if [ "$hotplug" == "mpdecision" ]; then
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
#		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
#			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
#		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable)" -eq "1" ]; then
			echo "0" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable;
		fi;
		if [ "$(ps | grep "mpdecision" | wc -l)" -le "1" ]; then
			/system/bin/start mpdecision
			$BB renice -n -20 -p $(pgrep -f "/system/bin/start mpdecision");
		fi;
	elif [ "$hotplug" == "msm_hotplug" ]; then
		/system/bin/stop mpdecision
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable)" -eq "0" ]; then
			echo "1" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
#		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
#			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
#		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "0" ]; then
			echo "1" > /sys/module/msm_hotplug/msm_enabled;
		fi;
	elif [ "$hotplug" == "intelli" ]; then
		/system/bin/stop mpdecision
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable)" -eq "0" ]; then
			echo "1" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable;
		fi;
#		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "1" ]; then
#			echo "0" > /sys/kernel/alucard_hotplug/hotplug_enable;
#		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "0" ]; then
			echo "1" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
	elif [ "$hotplug" == "alucard" ]; then
		/system/bin/stop mpdecision
		if [ "$(cat /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable)" -eq "0" ]; then
			echo "1" > /sys/devices/system/cpu/cpu0/rq-stats/hotplug_disable;
		fi;
		if [ "$(cat /sys/kernel/intelli_plug/intelli_plug_active)" -eq "1" ]; then
			echo "0" > /sys/kernel/intelli_plug/intelli_plug_active;
		fi;
		if [ "$(cat /sys/module/msm_hotplug/msm_enabled)" -eq "1" ]; then
			echo "0" > /sys/module/msm_hotplug/msm_enabled;
		fi;
		if [ "$(cat /sys/kernel/alucard_hotplug/hotplug_enable)" -eq "0" ]; then
			echo "1" > /sys/kernel/alucard_hotplug/hotplug_enable;
		fi;
	fi;
	if [ "$log_mode" == "0" ]; then
		log -p i -t "$FILE_NAME" "*** HOTPLUG CONTROL IMMUNIZED ***";
	fi;
}


ZRAM_CHECK()
{
	if [ "$zramtweaks" == "4" ]; then
		if [ -e /dev/block/zram0 ]; then
			swapoff /dev/block/zram0 >/dev/null 2>&1;
			echo "1" > /sys/block/zram0/reset;
			if [ "$log_mode" == "0" ]; then
				log -p i -t "$FILE_NAME" "*** ZRAM IMMUNIZED ***";
			fi;
		fi;
	fi;
}

# ==============================================================
# TWEAKS: if Screen-ON
# ==============================================================
AWAKE_MODE()
{
	if [ "$WAS_ASLEEP" == "false" ]; then
		return;
	fi;
	WAS_ASLEEP="false";
	CPUFREQ_FIX "awake";
	THERMAL_CTRL "awake";
#	TOUCH_FIX;
	if [ "$log_mode" == "0" ]; then
		log -p i -t "$FILE_NAME" "*** Morpheus: Wake mode activated. ***";
	fi;
}

# ==============================================================
# TWEAKS: if Screen-OFF
# ==============================================================
SLEEP_MODE()
{
	# we only read the config when the screen turns off
	PROFILE=$(cat "$DATA_DIR"/.active.profile);
	. "$DATA_DIR"/"$PROFILE".profile;

	# wait 10 seconds before suspending to make sure device is really suspended
	sleep 10;
	if [ "$(cat /sys/power/autosleep)" != "mem" ]; then
		if [ "$log_mode" == "0" ]; then
			log -p i -t "$FILE_NAME" "*** Morpheus: Sleep mode deferred. ***";		
		fi;
		return;
	fi;

	WAS_ASLEEP="true";
#	TOUCH_FIX;
	CROND_SAFETY;
	CPUFREQ_FIX "sleep";
	THERMAL_CTRL "sleep";
	MEM_CLEANER;
	HOTPLUG_CONTROL;
	ZRAM_CHECK;
	if [ "$log_mode" == "0" ]; then
		log -p i -t "$FILE_NAME" "*** Morpheus: Sleep mode activated. ***";
	fi;

	# Prevent worst case sleep
	if [ "$(cat /sys/power/autosleep)" != "mem" ]; then
		WAS_ASLEEP="true";
		AWAKE_MODE;
	fi;
}

# ==============================================================
# Background process to check screen state
# ==============================================================

# Dynamic value do not change/delete
morpheus_background_process=1;

if [ "$morpheus_background_process" -eq "1" ]; then
	echo "Morpheus mode initiating!";
	(while true; do
		while [ "$(cat /sys/power/autosleep)" != "off" ]; do
			sleep "2";
		done;
		# AWAKE State. All system ON
		AWAKE_MODE;

		while [ "$(cat /sys/power/autosleep)" != "mem" ]; do
			sleep "3";
		done;
		# SLEEP state. All system to power save
		SLEEP_MODE;
	done &);
else
	echo "Morpheus mode disabled!"
fi;