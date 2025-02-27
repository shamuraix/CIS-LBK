#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 9bb76b7f
#   function = deb_ensure_perms_etc_gshadow_dash_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_perms_etc_gshadow_dash_configured.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/09/22     Recommendation "Ensure permissions on /etc/gshadow- are configured"

deb_ensure_perms_etc_gshadow_dash_configured()
{

	# Ensure permissions on /etc/gshadow- are configured
	echo
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test="" l_output="" l_output2=""
    l_filename="/etc/gshadow-"
    l_perms_correct="(0[0-6][0-4]0)"
    l_owner_correct="root"
    l_group_correct="(root|shadow)"
    l_permissions=""
    l_ownergroup=""

	deb_ensure_perms_etc_gshadow_dash_configured_chk()
	{
		# Checks for correctly set permissions and ownership
		echo "- Start check - Ensure permissions on /etc/gshadow- are configured" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""
		
        l_buffer=$(stat $l_filename | grep -i access | grep -i id)
		l_perms=$(echo $l_buffer | awk '{print $2}' | cut -d'/' -f1 | sed "s/(//g")
		l_uid=$(echo $l_buffer |  awk '{print $6}' | sed "s/)//g")
		l_gid=$(echo $l_buffer |  awk '{print $NF}' | sed "s/)//g")

        # Check permissions
		if  grep -Pq "$l_perms_correct" <<< "$l_perms" ; then
			l_output="$l_output\n- $l_filename has permissions of '$l_perms'"
        else
            l_output2="$l_output2\n- $l_filename has permissions of '$l_perms'"
            l_permissions="failed"
		fi

		# Check owner
		if  grep -Pq "$l_owner_correct" <<< "$l_uid" ; then
			l_output="$l_output\n- $l_filename has owner of '$l_uid'"
        else
            l_output2="$l_output2\n- $l_filename has owner of '$l_uid'"
            l_ownergroup="failed"
		fi

        # Check group
		if  grep -Pq "$l_group_correct" <<< "$l_gid" ; then
			l_output="$l_output\n- $l_filename has group of '$l_gid'"
        else
            l_output2="$l_output2\n- $l_filename has group of '$l_gid'"
            l_ownergroup="failed"
		fi

		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output"  | tee -a "$LOG" 2>> "$ELOG"
		   	echo -e "- End check - Ensure permissions on /etc/gshadow- are configured" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
		   	echo -e "- FAILED:\n- Incorrect values:\n$l_output2"  | tee -a "$LOG" 2>> "$ELOG"
			[ -n "$l_output" ] && echo -e "\nCorrect values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
		   	echo "- End check - Ensure permissions on /etc/gshadow- are configured" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_FAIL:-102}"
		fi	
	}

	deb_ensure_perms_etc_gshadow_dash_configured_fix()
	{
        echo -e "- Start remediation - Ensure permissions on /etc/gshadow- are configured" | tee -a "$LOG" 2>> "$ELOG"

		if [ "$l_permissions" = "failed" ]; then
			echo -e "- Remediating $l_filename permissions set incorrectly to \"$l_perms\"" | tee -a "$LOG" 2>> "$ELOG"	
			chmod 640 "$l_filename"
		fi

		if [ "$l_ownergroup" = "failed" ]; then
			echo -e "- Remediating $l_filename owner and group set incorrectly to \"$l_uid\" and \"$l_gid\"" | tee -a "$LOG" 2>> "$ELOG"
 			chown root:shadow "$l_filename"
		fi

        echo -e "- End remediation - Ensure permissions on /etc/gshadow- are configured" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_perms_etc_gshadow_dash_configured_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		deb_ensure_perms_etc_gshadow_dash_configured_fix
		deb_ensure_perms_etc_gshadow_dash_configured_chk
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