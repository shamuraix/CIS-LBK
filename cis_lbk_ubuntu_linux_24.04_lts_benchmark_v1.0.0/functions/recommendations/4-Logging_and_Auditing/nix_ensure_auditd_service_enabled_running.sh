#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = c7deceac
#   function = ensure_auditd_service_enabled_running
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_auditd_service_enabled_running.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/03/20    Recommendation "Ensure auditing for processes that start prior to auditd is enabled"
# David Neilson	     07/23/22	 Updated to latest standards
# David Neilson	     10/28/22	 Slight modifications to systemctl command
# Randie Bejar		 11/06/23	 updated to auditd service is enabled

ensure_auditd_service_enabled_running()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation - Ensure auditd service is enabled \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	
	l_test=""	

	ensure_auditd_service_enabled_running_chk()
	{
		l_test1=""
		
		# Verify auditd is enabled
		if systemctl is-enabled auditd; then
			l_test1="passed"
		else
			l_test1="failed"	
		fi

		# If auditd is enabled, we pass.
		if [ "$l_test1" = "passed" ] ; then
			echo -e "- PASS:\n- auditd service is enabled." | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - auditd package" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- auditd package is NOT enabled." | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - auditd package" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	ensure_auditd_service_enabled_running_fix()
	{
		echo -e "- Start remediation - Ensure auditd service is enabled." | tee -a "$LOG" 2>> "$ELOG"

		
		if systemctl is-enabled auditd | grep -q 'masked'; then
			echo -e "- Unmasking auditd service" | tee -a "$LOG" 2>> "$ELOG"
			systemctl unmask auditd
			echo -e "- Starting auditd service" | tee -a "$LOG" 2>> "$ELOG"
			systemctl --now enable auditd
		else
			echo -e "- Starting auditd service" | tee -a "$LOG" 2>> "$ELOG"
			systemctl --now enable auditd
		fi

		echo -e "- End remediation - Ensure auditd service is enabled." | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_auditd_service_enabled_running_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_auditd_service_enabled_running_fix
		ensure_auditd_service_enabled_running_chk
		if [ "$?" = "101" ]; then
			[ "$l_test" != "failed" ] && l_test="remediated"
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