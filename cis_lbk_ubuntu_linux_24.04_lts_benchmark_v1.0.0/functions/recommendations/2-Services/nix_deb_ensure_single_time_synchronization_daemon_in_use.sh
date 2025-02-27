#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = b31a6e9c
#   function = deb_ensure_single_time_synchronization_daemon_in_use
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_single_time_synchronization_daemon_in_use.sh
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/26/22    Recommendation "Ensure a single time synchronization daemon is in use"
#

deb_ensure_single_time_synchronization_daemon_in_use()
{
	nix_package_manager_set()
	{
		echo -e "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"

		if command -v rpm 2>/dev/null; then
			echo -e "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM remove -y"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM purge -y"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	# Set package manager information
	if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
		nix_package_manager_set
		[ "$?" != "101" ] && output="- Unable to determine system's package manager"
	fi

	deb_ensure_single_time_synchronization_daemon_in_use_chk()
	{
		echo -e "- Start check - Ensure a single time synchronization daemon is in use" | tee -a "$LOG" 2>> "$ELOG"
		output="" l_tsd="" l_sdtd="" l_chrony="" l_ntp=""

        $G_PQ chrony > /dev/null 2>&1 && l_chrony="y"
        $G_PQ ntp > /dev/null 2>&1 && l_ntp="y" || l_ntp=""
        systemctl list-units --all --type=service | grep -q 'systemd-timesyncd.service' && systemctl is-enabled systemd-timesyncd.service | grep -q 'enabled' && l_sdtd="y"

        if [[ "$l_chrony" = "y" && "$l_ntp" != "y" && "$l_sdtd" != "y" ]]; then
            l_tsd="chrony"
            output="$output\n- chrony is in use on the system"
        elif [[ "$l_chrony" != "y" && "$l_ntp" = "y" && "$l_sdtd" != "y" ]]; then
            l_tsd="ntp"
            output="$output\n- ntp is in use on the system"
        elif [[ "$l_chrony" != "y" && "$l_ntp" != "y" ]]; then
            if systemctl list-units --all --type=service | grep -q 'systemd-timesyncd.service' && systemctl is-enabled systemd-timesyncd.service | grep -Eq '(enabled|disabled|masked)'; then
                l_tsd="sdtd"
                output="$output\n- systemd-timesyncd is in use on the system"
            fi
        else [[ "$l_chrony" = "y" && "$l_ntp" = "y" ]] && output="$output\n- both chrony and ntp are in use on the system"
            [[ "$l_chrony" = "y" && "$l_sdtd" = "y" ]] && output="$output\n- both chrony and systemd-timesyncd are in use on the system"
            [[ "$l_ntp" = "y" && "$l_sdtd" = "y" ]] && output="$output\n- both ntp and systemd-timesyncd are in use on the system"
        fi

        if [ -n "$l_tsd" ]; then
            echo -e "\n- PASS:\n$output\n"
            echo -e "- End check - Ensure a single time synchronization daemon is in use" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- FAIL:\n$output\n"
            echo -e "- End check - Ensure a single time synchronization daemon is in use" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-102}"
        fi
	}

	deb_ensure_single_time_synchronization_daemon_in_use_fix()
	{
		echo -e "- Start remediation - Ensure a single time synchronization daemon is in use" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- Installing chrony" | tee -a "$LOG" 2>> "$ELOG"
		$G_PM install -y chrony

        echo -e "- Stopping and masking systemd-timesyncd.service" | tee -a "$LOG" 2>> "$ELOG"
        systemctl stop systemd-timesyncd.service
        systemctl --now mask systemd-timesyncd.service

        echo -e "- Removing NTP package" | tee -a "$LOG" 2>> "$ELOG"
        $G_PR ntp

		echo -e "- End remediation - Ensure a single time synchronization daemon is in use" | tee -a "$LOG" 2>> "$ELOG"

	}

	deb_ensure_single_time_synchronization_daemon_in_use_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
	else
		deb_ensure_single_time_synchronization_daemon_in_use_fix
		deb_ensure_single_time_synchronization_daemon_in_use_chk
		if [ "$?" = "101" ] ; then
			[ "$l_test" != "failed" ] && l_test="remediated"
		else
			l_test="failed"
		fi
	fi

	# Set return code and return
	case "$l_test" in
		passed)
			echo "Recommendation \"$RNA\" No remediation required" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo "Recommendation \"$RNA\" successfully remediated" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo "Recommendation \"$RNA\" requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}