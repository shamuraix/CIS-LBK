#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = b5c6fbfa
#   function = ensure_all_users_last_password_change_in_past
#   applicable =
# # END METADATA
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_all_users_last_password_change_in_past.sh
#
# Name                  Date            Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell          09/29/20        Recommendation "Ensure all users last password change date is in the past"
# Justin Brown          05/15/22        Update to modern format.
# Randie Bejar          11/06/23        updated to new version

ensure_all_users_last_password_change_in_past()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

	ensure_all_users_last_password_change_in_past_chk()
	{
        echo -e "- Start check - Ensure all users last password change date is in the past" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""

		# Loop through users to check last password change date
		while IFS= read -r l_user; do
			l_change=$(date -d "$(chage --list "$l_user" | grep '^Last password change' | cut -d: -f2 | grep -v 'never$')" +%s)
			if [[ "$l_change" -gt "$(date +%s)" ]]; then
				l_output2+="User: \"$l_user\" last password change was \"$(chage --list "$l_user" | grep '^Last password change' | cut -d: -f2)\"\n"
            fi
		done < <(awk -F: '/^[^:\n\r]+:[^!*xX\n\r]/{print $1}' /etc/shadow)

		# Check and output based on test results
		if [ -z "$l_output2" ]; then
			echo -e "- PASS: - All users' last password change dates are in the past" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure all users' last password change dates are in the past" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL: - \n- Some users' last password change dates are NOT in the past\n- Failing Values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure all users' last password change dates are in the past" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi

	}

	ensure_all_users_last_password_change_in_past_fix()
	{
		echo -e "- Start remediation - Ensure all users last password change date is in the past" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- Investigate any users with a password change date in the future and correct them according to site policy" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- End remediation - Ensure all users last password change date is in the past" | tee -a "$LOG" 2>> "$ELOG"
		l_test="manual"

        echo -e "- End remediation - Ensure all users last password change date is in the past" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_all_users_last_password_change_in_past_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            ensure_all_users_last_password_change_in_past_fix
            if [ "$l_test" != "manual" ]; then
                ensure_all_users_last_password_change_in_past_chk
                if [ "$?" = "101" ]; then
                    [ "$l_test" != "failed" ] && l_test="remediated"
                else
                    l_test="failed"
                fi
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