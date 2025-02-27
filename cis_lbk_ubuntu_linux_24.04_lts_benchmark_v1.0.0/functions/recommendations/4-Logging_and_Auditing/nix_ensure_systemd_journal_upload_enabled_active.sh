#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 2641b3a3
#   function = ensure_systemd_journal_upload_enabled_active
#   applicable =
# # END METADATA
#
#
# 
#
#
#
#
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_systemd_journal_upload_enabled_active.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus		 03/11/24    Recommendation "Ensure systemd-journal-upload is enabled and active"
# 

ensure_systemd_journal_upload_enabled_active()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	
	l_test=""	

	if pgrep rsyslogd >/dev/null 2>&1 && ! pgrep -x systemd-journald >/dev/null 2>&1; then
		echo -e "- rsyslog is being used instead of systemd-journald" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Recommendation Ensure systemd-journal-upload is enabled and active is NA"  | tee -a "$LOG" 2>> "$ELOG"
		l_test="NA"
		echo -e "- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
		return "${XCCDF_RESULT_PASS:-104}"
	else
		echo -e "- System is using systemd-journald, continue recommendation check" | tee -a "$LOG" 2>> "$ELOG"
	fi

	ensure_systemd_journal_upload_enabled_active_chk()
	{	
        echo -e "- Start Check - Ensure systemd-journal-upload is enabled and active" | tee -a "$LOG" 2>> "$ELOG"
		l_output=""
		l_output2=""

		# Verify systemd-journal-upload is enabled
		if systemctl is-enabled systemd-journal-upload.service &>/dev/null; then
			l_output="$l_output\n- systemd-journal-upload.service is set to $(systemctl is-enabled systemd-journal-upload.service)"
		else
			l_output2="$l_output2\n- systemd-journal-upload.service is set to $(systemctl is-enabled systemd-journal-upload.service)"
		fi
		
		# Verify systemd-journal-upload is active
		if systemctl is-active systemd-journal-upload.service &>/dev/null; then
			l_output="$l_output\n- systemd-journal-upload.service is set to $(systemctl is-active systemd-journal-upload.service)"
		else
			l_output2="$l_output2\n- systemd-journal-upload.service is set to $(systemctl is-active systemd-journal-upload.service)"
		fi

		# If systemd-journal-upload is enabled and active, we pass.
		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure systemd-journal-upload is enabled and active" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
					echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure systemd-journal-upload is enabled and active" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	ensure_systemd_journal_upload_enabled_active_fix()
	{
		echo -e "- Start remediation - Ensure systemd-journal-upload is enabled and active" | tee -a "$LOG" 2>> "$ELOG"

		if systemctl is-enabled systemd-journal-upload.service | grep -q 'masked'; then
			echo -e "- Unmasking systemd-journal-upload service" | tee -a "$LOG" 2>> "$ELOG"
			systemctl unmask systemd-journal-upload.service &>/dev/null
			echo -e "- Starting systemd-journal-upload service" | tee -a "$LOG" 2>> "$ELOG"
			systemctl --now enable systemd-journal-upload.service &>/dev/null
		else
			echo -e "- Starting systemd-journal-upload service" | tee -a "$LOG" 2>> "$ELOG"
			systemctl --now enable systemd-journal-upload.service &>/dev/null
		fi

		echo -e "- End remediation - Ensure systemd-journal-upload is enabled and active" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_systemd_journal_upload_enabled_active_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_systemd_journal_upload_enabled_active_fix
		ensure_systemd_journal_upload_enabled_active_chk
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