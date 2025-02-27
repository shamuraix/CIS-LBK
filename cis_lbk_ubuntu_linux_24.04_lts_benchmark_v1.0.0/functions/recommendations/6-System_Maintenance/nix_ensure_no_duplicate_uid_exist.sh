#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 759886a9
#   function = ensure_no_duplicate_uid_exist
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_no_duplicate_uid_exist.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       10/09/20    Recommendation "Ensure no duplicate UIDs exist"
# Justin Brown		 04/26/22    Update to modern format. Added passing criteria.
#
 
ensure_no_duplicate_uid_exist()
{
	# Checks for duplicate GIDs
	echo -e "- Start check - Ensure no duplicate GIDs exist" | tee -a "$LOG" 2>> "$ELOG"
	test=""
	
	ensure_no_duplicate_uid_exist_chk()
	{
		l_output=""
		l_output=$(cut -f3 -d":" /etc/passwd | sort -n | uniq -c | while read x ; do
					[ -z "$x" ] && break
					set - $x
					if [ $1 -gt 1 ]; then
						users=$(awk -F: '($3 == n) { print $1 }' n=$2 /etc/passwd | xargs)
						echo "Duplicate UID ($2): $users"
					fi
				done)
		
		if [ -z "$l_output" ]; then
			echo -e "- PASS: - No duplicate UIDs exist."  | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure no duplicate UIDs exist." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL: - \n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure no duplicate UIDs exist." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi	
	}
	
	ensure_no_duplicate_uid_exist_fix()
	{
		echo -e "- Start remediation - Ensure no duplicate UIDs exist." | tee -a "$LOG" 2>> "$ELOG"
		
      echo -e "- Making modifications to /etc/passwd could have significant unintended consequences or result in outages and unhappy users. Therefore, it is recommended that the current user list be reviewed and determine the action to be taken in accordance with site policy. -" | tee -a "$LOG" 2>> "$ELOG"
		test="manual"
      
      echo -e "- End remediation - Ensure no duplicate UIDs exist." | tee -a "$LOG" 2>> "$ELOG"
	}
	
	ensure_no_duplicate_uid_exist_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		ensure_no_duplicate_uid_exist_fix
		if [ "$test" != "manual" ]; then
			ensure_no_duplicate_uid_exist_chk
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