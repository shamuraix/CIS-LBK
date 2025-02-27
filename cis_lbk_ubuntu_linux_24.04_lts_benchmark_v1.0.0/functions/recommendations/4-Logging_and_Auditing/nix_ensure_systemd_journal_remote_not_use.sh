#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 3478bb7b
#   function = ensure_systemd_journal_remote_not_use
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
# ~/CIS-LBK/functions/recommendations/nix_ensure_systemd_journal_remote_not_use.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus		 03/11/24    Recommendation "Ensure systemd-journal-remote service is not in use"
# 

ensure_systemd_journal_remote_not_use()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	
	l_test=""	

	if pgrep rsyslogd >/dev/null 2>&1 && ! pgrep -f systemd-journald >/dev/null 2>&1; then
		echo -e "- rsyslog is being used instead of systemd-journald" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Recommendation Ensure systemd-journal-remote service is not in use is NA"  | tee -a "$LOG" 2>> "$ELOG"
		l_test="NA"
		echo -e "- End Recommendation \"$RN - $RNA\"\n**************************************************\n" | tee -a "$LOG" 2>> "$ELOG"
		return "${XCCDF_RESULT_PASS:-104}"
	else
		echo -e "- System is using systemd-journald, continue recommendation check" | tee -a "$LOG" 2>> "$ELOG"
	fi

	ensure_systemd_journal_remote_not_use_chk()
	{	
        echo -e "- Start Check - Ensure systemd-journal-remote service is not in use" | tee -a "$LOG" 2>> "$ELOG"
		l_output=""
		l_output2=""

		# Verify systemd-journal-remote.socket and systemd-journal-remote.service are masked
		if  systemctl is-enabled systemd-journal-remote.socket 2>/dev/null| grep -Pq -- '^masked'; then
			l_output="$l_output\n- systemd-journal-remote.socket is set to $(systemctl is-enabled systemd-journal-remote.socket 2>/dev/null)"
		else
			l_output2="$l_output2\n- systemd-journal-remote.socket is set to $(systemctl is-enabled systemd-journal-remote.socket 2>/dev/null)"
		fi

		if  systemctl is-enabled systemd-journal-remote.service | grep -Pq -- '^masked'; then
			l_output="$l_output\n- systemd-journal-remote.service is set to $(systemctl is-enabled systemd-journal-remote.service)"
		else
			l_output2="$l_output2\n- systemd-journal-remote.service is set to $(systemctl is-enabled systemd-journal-remote.service)"
		fi

		# Verify systemd-journal-remote.socket and systemd-journal-remote.service are inactive
		if ! systemctl is-active systemd-journal-remote.socket 2>/dev/null| grep -Pq -- '^active'; then
			l_output="$l_output\n- systemd-journal-remote.socket is set to $(systemctl is-active systemd-journal-remote.socket 2>/dev/null)"
		else
			l_output2="$l_output2\n- systemd-journal-remote.socket is set to $(systemctl is-active systemd-journal-remote.socket 2>/dev/null)"
		fi

		if ! systemctl is-active systemd-journal-remote.service | grep -Pq -- '^active'; then
			l_output="$l_output\n- systemd-journal-remote.service is set to $(systemctl is-active systemd-journal-remote.service)"
		else
			l_output2="$l_output2\n- systemd-journal-remote.service is set to $(systemctl is-active systemd-journal-remote.service)"
		fi
		
		# If systemd-journal-remote.socket and systemd-journal-remote.service are masked and inactive, we pass.
		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure systemd-journal-remote service is not in use" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
					echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure systemd-journal-remote service is not in use" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	ensure_systemd_journal_remote_not_use_fix()
	{
		echo -e "- Start remediation - Ensure systemd-journal-remote service is not in use" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Stopping systemd-journal-remote.socket and systemd-journal-remote.service" | tee -a "$LOG" 2>> "$ELOG"
				systemctl stop systemd-journal-remote.socket systemd-journal-remote.service &>/dev/null
		echo -e "- Masking systemd-journal-remote.socket and systemd-journal-remote.service" | tee -a "$LOG" 2>> "$ELOG"
				systemctl mask systemd-journal-remote.socket systemd-journal-remote.service &>/dev/null

		echo -e "- End remediation - Ensure systemd-journal-remote service is not in use" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_systemd_journal_remote_not_use_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_systemd_journal_remote_not_use_fix
		ensure_systemd_journal_remote_not_use_chk
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