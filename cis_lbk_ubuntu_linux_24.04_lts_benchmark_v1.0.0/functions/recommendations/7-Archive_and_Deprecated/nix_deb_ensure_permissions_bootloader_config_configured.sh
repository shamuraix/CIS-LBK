#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 1797897e
#   function = deb_ensure_permissions_bootloader_config_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Deprecated Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_permissions_bootloader_config_configured.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       01/17/22    Recommendation "Ensure permissions on bootloader config are configured"
# Justin Brown       09/24/23    Updated stat command to support symlinks
# J Brown			 04/03/24	 This script will be deprecated and replaced by 'nix_deb_ensure_access_bootloader_config_configured.sh'
#

deb_ensure_permissions_bootloader_config_configured()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

    # Set grubfile vars 
    l_grubfile=$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -Pl '^\h*(kernelopts=|linux|kernel)' {} \;)
	l_grubdir=$(dirname "$l_grubfile")

	deb_ensure_permissions_bootloader_config_configured_chk()
	{
		echo -e "- Start check - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"

		l_tst1="" l_tst2="" l_output="" l_output2=""

		stat -Lc "%a" "$l_grubfile" | grep -Pq '^\h*[0-4]00$' && l_tst1=pass
		l_output="Permissions on \"$l_grubfile\" are \"$(stat -c "%a" "$l_grubfile")\""

		stat -Lc "%u:%g" "$l_grubfile" | grep -Pq '^\h*0:0$' && l_tst2=pass
		l_output2="\"$l_grubfile\" is owned by \"$(stat -c "%U" "$l_grubfile")\" and belongs to group \"$(stat -c "%G" "$l_grubfile")\""

		if [ "$l_tst1" = "pass" ] && [ "$l_tst2" = "pass" ]; then
			echo -e "- PASSED" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output" ] && echo "- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output2" ] && echo "- $l_output2" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo -e "- FAILED"  | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output" ] && echo "- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output2" ] && echo "- $l_output2" | tee -a "$LOG" 2>> "$ELOG"
			echo "- End check - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	deb_ensure_permissions_bootloader_config_configured_fix()
	{
		echo -e "- Start remediation - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"

		if [ -f "$l_grubdir"/grubenv ]; then
            echo -e "- Setting permissions on $l_grubdir/grubenv" | tee -a "$LOG" 2>> "$ELOG"
			chown root:root "$l_grubdir"/grubenv
			chmod u-wx,go-rwx "$l_grubdir"/grubenv   
		fi

		if [ -f "$l_grubdir"/grub.cfg ]; then
            echo -e "- Setting permissions on $l_grubdir/grub.cfg" | tee -a "$LOG" 2>> "$ELOG"
			chown root:root "$l_grubdir"/grub.cfg
			chmod u-wx,go-rwx "$l_grubdir"/grub.cfg
		fi

		if [ -f "$l_grubdir"/grub.conf ]; then
            echo -e "- Setting permissions on $l_grubdir/grub.conf" | tee -a "$LOG" 2>> "$ELOG"
			chown root:root "$l_grubdir"/grub.conf
			chmod u-wx,go-rwx "$l_grubdir"/grub.conf
		fi

		echo  -e "- End remediation - Ensure permissions on bootloader config are configured" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_permissions_bootloader_config_configured_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		if grep -Pq -- "^\h*\/boot\/efi\/" <<< "$l_grubdir"; then
			l_test="manual"
		else
			deb_ensure_permissions_bootloader_config_configured_fix
			deb_ensure_permissions_bootloader_config_configured_chk
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