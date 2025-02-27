#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 38aafcea
#   function = ensure_shadow_group_empty
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_shadow_group_empty.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       10/09/20    Recommendation "Ensure shadow group is empty"
# Justin Brown		 04/26/22    Update to modern format. Added passing criteria.
#
 
ensure_shadow_group_empty()
{
	# Checks for duplicate user names
	echo -e "- Start check - Ensure shadow group is empty" | tee -a "$LOG" 2>> "$ELOG"
    test=""

	ensure_shadow_group_empty_chk()
	{
		l_shadow_group=""
		l_shadow_user=""
		
		l_shadow_group=$(awk -F: '($1=="shadow") {print $NF}' /etc/group)
		
		l_shadow_user=$(awk -F: -v GID="$(awk -F: '($1=="shadow") {print $3}' /etc/group)" '($4==GID) {print $1}' /etc/passwd)
		
		if [ -z "$l_shadow_group" ] && [ -z "$l_shadow_user" ]; then
			echo -e "- PASS: - No users in shadow group or users with a primary group of shadow."  | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure shadow group is empty." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL: - " | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_shadow_group" ]; then
				echo -e "Users in shadow group: $l_shadow_group" | tee -a "$LOG" 2>> "$ELOG"
			fi
			if [ -n "$l_shadow_user" ]; then
				echo -e "Users with primary group shadow: $l_shadow_user" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure shadow group is empty." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi	
	}
	
	ensure_shadow_group_empty_fix()
	{
		echo -e "- Start remediation - Ensure shadow group is empty." | tee -a "$LOG" 2>> "$ELOG"
		
      echo -e "- Making modifications to /etc/passwd or /etc/group could have significant unintended consequences or result in outages and unhappy users. Therefore, it is recommended that the current user and group list be reviewed and determine the action to be taken in accordance with site policy. -" | tee -a "$LOG" 2>> "$ELOG"
      test="manual"
            
		echo -e "- End remediation - Ensure shadow group is empty." | tee -a "$LOG" 2>> "$ELOG"
	}
	
	ensure_shadow_group_empty_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		ensure_shadow_group_empty_fix
		if [ "$test" != "manual" ]; then
			ensure_shadow_group_empty_chk
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