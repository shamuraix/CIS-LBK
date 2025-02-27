#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = cf931567
#   function = ensure_filesystem_integrity_regularly_checked
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_filesystem_integrity_regularly_checked.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/15/20    Recommendation "Ensure filesystem integrity is regularly checked"
# Justin Brown		 12/28/22	 Updated to modern format
# Randie Bejar		 11/06/23	 Updated to new version
# David Neilson		 04/03/24	 Modified to run on Suse, changed "grep" commands to work for Fedora and Debian/Ubuntu, and changed systemctl commands to confirm aidecheck.timer was running/waiting

ensure_filesystem_integrity_regularly_checked()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   	l_test=""
	if grep -Pi -- 'pretty_name' /etc/os-release | grep -Piq -- 'suse'; then
        l_flavor="suse"
    fi
	
	ensure_filesystem_integrity_regularly_checked_chk()
   	{
		echo -e "- Start check - Ensure filesystem integrity is regularly checked" | tee -a "$LOG" 2>> "$ELOG"
		l_cron_test="" l_systemctl_test=""

		if [ -z "$l_flavor" ]; then 
			if grep -Prs -- '^([^#]+\h+)?(\/usr\/s?bin\/|^\h*)aide(\.wrapper)?\h*(--?\H+\h)*(--(check|update)|\$AIDEARGS)*\b' /etc/cron.* /etc/crontab /var/spool/cron/; then
				l_cron_test=passed
			else
				l_cron_test=failed
			fi
		else	
            if crontab -u root -l | grep -Pq -- 'aide' || grep -r aide /etc/cron.* /etc/crontab; then
				l_cron_test=passed
			else
				l_cron_test=failed
			fi
		fi 

		if systemctl is-enabled aidecheck.service 2>/dev/null | grep -q enabled && systemctl is-enabled aidecheck.timer 2> /dev/null | grep -q enabled && systemctl status aidecheck.timer 2> /dev/null | grep -Piq -- '\h+Active:\h+active\h+\H(running|waiting)'; then
			l_systemctl_test=passed
		else
			l_systemctl_test=failed
		fi

		if [ "$l_cron_test" = "passed" ] || [ "$l_systemctl_test" = "passed" ]; then
			echo -e "- PASS:\n- Filesystem integrity is being checked" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure filesystem integrity is regularly checked" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif [ "$l_cron_test" = "failed" ] && [ "$l_systemctl_test" = "failed" ]; then
			echo -e "- FAIL:\n- Filesystem integrity is NOT being checked" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure filesystem integrity is regularly checked" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi

	}

	ensure_filesystem_integrity_regularly_checked_fix()
   	{
      	echo -e "- Start remediation - Ensure filesystem integrity is regularly checked" | tee -a "$LOG" 2>> "$ELOG"
		l_test="manual"

		echo -e "- Configure cron, or set up aide if you are already using it" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- End remediation - Ensure filesystem integrity is regularly checked" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_filesystem_integrity_regularly_checked_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_filesystem_integrity_regularly_checked_fix
		if [ "$l_test" != "manual" ]; then
			ensure_filesystem_integrity_regularly_checked_chk
			if [ "$?" = "101" ]; then
				[ "$l_test" != "failed" ] && l_test="remediated"
			else
				l_test="failed"
			fi
		fi
	fi

   	# Set return code, end recommendation entry in verbose log, and return
   	case "$l_test" in
      	passed)
         	echo -e "- Result - No remediation required\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
         	return "${XCCDF_RESULT_PASS:-101}"
         	;;
      	remediated)
         	echo -e "- Result - successfully remediated\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
         	return "${XCCDF_RESULT_PASS:-103}"
         	;;
      	manual)
         	echo -e "- Result - requires manual remediation\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
         	return "${XCCDF_RESULT_FAIL:-106}"
         	;;
      	NA)
         	echo -e "- Result - Recommendation is non applicable\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
         	return "${XCCDF_RESULT_PASS:-104}"
         	;;
      	*)
         	echo -e "- Result - remediation failed\n- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
         	return "${XCCDF_RESULT_FAIL:-102}"
         	;;
   	esac
}
