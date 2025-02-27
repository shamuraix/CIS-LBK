#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = cb2ab2ba
#   function = ensure_etc_shadow_password_fields_not_empty
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_etc_shadow_password_fields_not_empty.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/09/22    Recommendation "Ensure /etc/shadow password fields are not empty"
#

ensure_etc_shadow_password_fields_not_empty()
{
	# Checks for files in user home directories
	echo -e "- Start check - Ensure /etc/shadow password fields are not empty" | tee -a "$LOG" 2>> "$ELOG"
    test=""
	
	ensure_etc_shadow_password_fields_not_empty_chk()
	{
		l_output="" l_output2=""

        l_output2="$(awk -F: '($2 == "" ) { print $1 " does not have a password "}' /etc/shadow)"
	
		if [ -z "$l_output2" ]; then
			echo -e "- PASS: - All acounts in '/etc/shadow' have a password or are locked."  | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure /etc/shadow password fields are not empty" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL: - \n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure /etc/shadow password fields are not empty" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	ensure_etc_shadow_password_fields_not_empty_fix()
	{
		test=""
			
		echo -e "- Start remediation - Ensure /etc/shadow password fields are not empty" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Any accounts without a password should be investigated.\n- If the account is logged in, investigate what it is being used for to determine if it needs to be forced off.\n- Run the following command to lock the account until it can be determined why it does not have a password:\n  '# passwd -l <username>'" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- End remediation - Ensure /etc/shadow password fields are not empty" | tee -a "$LOG" 2>> "$ELOG"
		test="manual"
	}

	ensure_etc_shadow_password_fields_not_empty_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		ensure_etc_shadow_password_fields_not_empty_fix
		if [ "$test" != "manual" ]; then
			ensure_etc_shadow_password_fields_not_empty_chk
            if [ "$?" = "101" ]; then
                [ "$l_test" != "failed" ] && l_test="remediated"
            else
                l_test="failed"
            fi
		fi
	fi
	
	# Set return code, end recommendation entry in verbose log, and return
	case "$test" in
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