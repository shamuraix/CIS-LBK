#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = bfcbdac6
#   function = deb_ensure_apparmor_enabled_bootloader_configuration
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_apparmor_enabled_bootloader_configuration.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# David Neilson	     11/23/22	 Recommendation "Ensure AppArmor is enabled in the bootloader configuration (Automated)"
# Justin Brown       1/10/23     Rewrote to ignore EFI vs nonEFI on Debian

deb_ensure_apparmor_enabled_bootloader_configuration()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_apparmor_enabled_bootloader_configuration_chk()
	{
		echo -e "- Start check - Ensure AppArmor is enabled in the bootloader configuration" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2="" l_test1="" l_test2=""
        l_kernel_entries="$(find /boot -type f -name 'grub.cfg' -exec grep -Ph -- '^\h*linux\h' {} +)"

		echo -e "- Checking 'apparmor=1' and 'security=apparmor' value(s)" | tee -a "$LOG" 2>> "$ELOG"
		while l_kernel= read -r l_entry; do
			if grep -Pq -- 'apparmor=1\b' <<< "$l_entry"; then
				if grep -Pq -- 'security=apparmor\b' <<< "$l_entry"; then
					l_output="$l_output\n$l_entry"
				else
					l_output2="$l_output2\n$l_entry"
					l_test2="failed"
				fi
			else
					l_output2="$l_output2\n$l_entry"
					l_test1="failed"
					l_test2="failed"
			fi
		done <<< "$l_kernel_entries"

		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure AppArmor is enabled in the bootloader configuration" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
					echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure AppArmor is enabled in the bootloader configuration" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	deb_ensure_apparmor_enabled_bootloader_configuration_fix()
	{
		echo -e "- Start remediation - Ensure AppArmor is enabled in the bootloader configuration file" | tee -a "$LOG" 2>> "$ELOG"

		if [ "$l_test1" = "failed" ]; then
			if grep -Pq '^\s*GRUB_CMDLINE_LINUX="([^#]+\h+)?apparmor=' /etc/default/grub; then
				echo -e "- Updating apparmor value in /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri 's/(^\s*GRUB_CMDLINE_LINUX=".*)(apparmor=[01]+)(.*"$)/\1apparmor=1\3/' /etc/default/grub
			else
				echo -e "- Adding apparmor=1 value to /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri 's/(^\s*GRUB_CMDLINE_LINUX=".*)("$)/\1 apparmor=1\2/' /etc/default/grub
			fi
		fi

        if [ "$l_test2" = "failed" ]; then
			if grep -Pq '^\s*GRUB_CMDLINE_LINUX="([^#]+\h+)?security=' /etc/default/grub; then
				echo -e "- Updating security= value in /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri 's/(^\s*GRUB_CMDLINE_LINUX=".*)(security=[^\s]+)(.*"$)/\1security=apparmor\3/' /etc/default/grub
			else
				echo -e "- Adding security=apparmor value to /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri 's/(^\s*GRUB_CMDLINE_LINUX=".*)("$)/\1 security=apparmor\2/' /etc/default/grub
			fi
		fi

        update-grub > /dev/null 2>&1

		echo -e "- End remediation - Ensure AppArmor is enabled in the bootloader configuration file" | tee -a "$LOG" 2>> "$ELOG"
	}

    deb_ensure_apparmor_enabled_bootloader_configuration_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ "$l_test" = "manual" ]; then
		:
	else
		deb_ensure_apparmor_enabled_bootloader_configuration_fix
		deb_ensure_apparmor_enabled_bootloader_configuration_chk
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