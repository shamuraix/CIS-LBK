#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 5ed41775
#   function = ensure_mail_transfer_agent_configured_local_only
#   applicable =
# # END METADATA
#
#
# CIS-LBK Deprecated Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_mail_transfer_agent_configured_local_only.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/30/20    Recommendation "Ensure mail transfer agents are configured for local-only mode"
# David Neilson	     06/22/22	 Updated to latest standards
# J Brown			 10/20/23	 Refactor to match more current script model
# J Brown			04/20/24	This script will be deprecated and replaced by 'nix_ensure_mail_transfer_agent_configured_local_only_mode.sh'
#

ensure_mail_transfer_agent_configured_local_only()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"

	ensure_mail_transfer_agent_configured_local_only_chk()
	{
		echo -e "- Start check - Ensure mail transfer agents are configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"

		# Determine if postfix is enabled.  If it is not, then manual remediation is required.
		if systemctl is-enabled postfix.service 2>/dev/null| grep -Pqi -- "enabled|disabled"; then
			# Verify that the MTA is not listening on any non-loopback address
			l_test="" l_output="" l_output2=""

			# If something is returned, the test fails
			if ss -plntu | grep -P -- ':25\b' | grep -Pv -- '\h+(127\.0\.0\.1|\[?::1\]?):25\b'; then
				l_output2="$l_output2\n- MTA appears to be listening on port 25\n  $(ss -plntu | grep -P -- ':25\b' | grep -Pv -- '\h+(127\.0\.0\.1|\[?::1\]?):25\b')"
			else
				l_output="$l_output\n- MTA does NOT appear to be listening on port 25"
			fi

			if ss -plntu | grep -P -- ':465\b' | grep -Pv -- '\h+(127\.0\.0\.1|\[?::1\]?):465\b'; then
				l_output2="$l_output2\n- MTA appears to be listening on port 465\n  $(ss -plntu | grep -P -- ':465\b' | grep -Pv -- '\h+(127\.0\.0\.1|\[?::1\]?):465\b')"
			else
				l_output="$l_output\n- MTA does NOT appear to be listening on port 465"
			fi

			if ss -plntu | grep -P -- ':587\b' | grep -Pv -- '\h+(127\.0\.0\.1|\[?::1\]?):587\b'; then
				l_output2="$l_output2\n- MTA appears to be listening on port 587\n  $(ss -plntu | grep -P -- ':587\b' | grep -Pv -- '\h+(127\.0\.0\.1|\[?::1\]?):587\b')"
			else
				l_output="$l_output\n- MTA does NOT appear to be listening on port 587"
			fi

			if [ -z "$l_output2" ]; then
				echo -e "- PASSED:\n- mail transfer agent is configured for local-only mode\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure mail transfer agents are configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			elif [ -n "$l_output2" ]; then
				echo -e "- FAILED:\n- mail transfer agent is listening for remote connections.\nFailing Settings:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
				if [ -n "$l_output" ]; then
					echo -e "- Passing Settings:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
				fi
				echo -e "- End check - Ensure mail transfer agents are configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-102}"
			else
				l_test="manual"
				echo -e "- Remediation required:\n- Could not determine if mail transfer agent is configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure mail transfer agents are configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-106}"
			fi
		else
			l_test="manual"
			echo -e "- Remediation required:\n- Could not determine if mail transfer agent is configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure mail transfer agents are configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	ensure_mail_transfer_agent_configured_local_only_fix()
	{
			echo -e "- Start remediation - Ensure mail transfer agents are configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"

			# If "inet_interfaces" line exists in file, change its value to loopback-only.
			if grep -Eq '^\s*inet_interfaces\s*=\s*[^#]*\s*' /etc/postfix/main.cf; then
				echo -e "- Updating Postfix main.conf to set inet_interfaces to 'loopback-only'" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri 's/(^\s*inet_interfaces\s*=\s*)([^#]*\s*)?(#.*)?/\1loopback-only\3/' /etc/postfix/main.cf
			# If "inet_interfaces" line does not exist in file, append it to the RECEIVING MAIL section.
			else
				echo -e "- Adding 'inet_interfaces = loopback-only' to Postfix main.cf" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri '/^#\s*RECEIVING MAIL\s*.*$/a inet_interfaces = loopback-only' /etc/postfix/main.cf
			fi

			echo -e "- Restarting Postfix" | tee -a "$LOG" 2>> "$ELOG"
			systemctl restart postfix

			echo -e "- End remediation - Ensure mail transfer agents are configured for local-only mode" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_mail_transfer_agent_configured_local_only_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ "$l_test" = "manual" ]; then
		:
	else
		ensure_mail_transfer_agent_configured_local_only_fix
		ensure_mail_transfer_agent_configured_local_only_chk
		if [ "$?" = "101" ]; then
			[ "$l_test" != "failed" ] && l_test="remediated"
		else
			l_test="failed"
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