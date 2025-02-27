#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = c7deceac
#   function = deb_ensure_auditing_processes_start_prior_auditd_enabled
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_auditing_processes_start_prior_auditd_enabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/03/20    Recommendation "Ensure auditing for processes that start prior to auditd is enabled"
# Eric Pinnell       01/14/21    Modified - Updated variable name to correct conflict with a global variable 
# David Neilson	     07/23/22	 Updated to current standards
# David Neilson	     11/10/22	 Runs update-grub
# Justin Brown       1/10/23     Rewrote to ignore EFI vs nonEFI on Debian

deb_ensure_auditing_processes_start_prior_auditd_enabled()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_auditing_processes_start_prior_auditd_enabled_chk()
	{
		echo -e "- Start check - Ensure auditing for processes that start prior to auditd is enabled" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""
        l_kernel_entries="$(find /boot -type f -name 'grub.cfg' -exec grep -Ph -- '^\h*linux\h' {} +)"	

		echo -e "- Checking audit value(s)" | tee -a "$LOG" 2>> "$ELOG"
		while l_kernel= read -r l_entry; do
			if grep -Pq -- 'audit=1' <<< "$l_entry"; then
					l_output="$l_output\n$l_entry"
			else
					l_output2="$l_output2\n$l_entry"
			fi
		done <<< "$l_kernel_entries"

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure auditing for processes that start prior to auditd is enabled" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
					echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure auditing for processes that start prior to auditd is enabled" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi	
	}

	deb_ensure_auditing_processes_start_prior_auditd_enabled_fix()
	{
		echo -e "- Start remediation - Ensure auditing for processes that start prior to auditd is enabled" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- setting audit" | tee -a "$LOG" 2>> "$ELOG"
		if grep -Pq -- 'audit=' /etc/default/grub; then
				echo -e "- Updating audit value in /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri 's/^\s*(GRUB_CMDLINE_LINUX=")([^#"]*\s*)?(audit=)([0-9]+)?(.*)$/\1\2\31\5/' /etc/default/grub
		else
				if grep -Pq "^\s*GRUB_CMDLINE_LINUX=" /etc/default/grub; then
						echo -e "- Adding audit value to GRUB_CMDLINE_LINUX in /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
						sed -ri 's/^\s*(GRUB_CMDLINE_LINUX=")([^#"]*\s*)?(")(.*)$/\1\2 audit=1\3\4/' /etc/default/grub
				else
						echo -e "- Inserting GRUB_CMDLINE_LINUX=\"audit=1\" to /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
						echo "GRUB_CMDLINE_LINUX=\"audit=1\"" >> /etc/default/grub
				fi
		fi
		echo -e "- Reconfiguring grub" | tee -a "$LOG" 2>> "$ELOG"
		if command -v update-grub &> /dev/null; then
                        update-grub
                else
                        grub2-mkconfig -o /boot/grub2/grub.cfg
                fi

		echo -e "- End remediation - Ensure auditing for processes that start prior to auditd is enabled" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_auditing_processes_start_prior_auditd_enabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ "$l_test" = "manual" ]; then
		:
	else
		deb_ensure_auditing_processes_start_prior_auditd_enabled_fix
		deb_ensure_auditing_processes_start_prior_auditd_enabled_chk
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