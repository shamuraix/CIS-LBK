#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = d5b8a93a
#   function = ensure_audit_tools_files_mode_755
#   applicable =
# # END METADATA
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_audit_tools_files_mode_755.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/22/22     Recommendation "Ensure audit tools are 755 or more restrictive"
# 

ensure_audit_tools_files_mode_755()
{

	# Ensure permissions on /etc/group- are configured
	echo
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	ensure_audit_tools_files_mode_755_chk()
	{
		echo "- Start check - Ensure audit tools are 755 or more restrictive" | tee -a "$LOG" 2>> "$ELOG"
		l_output=""
		l_output="$(stat -Lc "%n %a" /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules | grep -Pv -- '^\h*\H+\h+([0-7][0,1,4,5][0,1,4,5])\h*$')"
		
		# If all files passed, then we pass
		if [ -z "$l_output" ]; then
			echo -e "- PASS\n- All audit tools files are mode 0755 or less permissive" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure audit tools are 755 or more restrictive" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo -e "- FAIL:" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "$l_output" | while read -r filemode; do
				echo "- File: \"$(awk '{print $1}' <<< "$filemode")\" is mode: \"$(awk '{print $2}' <<< "$filemode")\"" | tee -a "$LOG" 2>> "$ELOG"
			done
			echo -e "- End check - Ensure audit tools are 755 or more restrictive" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi	
	}

	ensure_audit_tools_files_mode_755_fix()
	{
		echo -e "- Start remediation - Ensure audit tools are 755 or more restrictive" | tee -a "$LOG" 2>> "$ELOG"
        l_audittools="/sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules"

        for file in $l_audittools; do
            l_fileperm=""
            l_fileperm="$(stat -Lc "%n %a" "$file" | grep -Pv -- '^\h*\H+\h+([0-7][0,1,4,5][0,1,4,5])\h*$')"
            if [ -n "$l_fileperm" ]; then
                echo "- Removing excess permissions from file: \"$file\"" | tee -a "$LOG" 2>> "$ELOG"
                chmod 755 "$file"
            fi
        done
		
		echo -e "- End remediation - Ensure audit tools are 755 or more restrictive" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_audit_tools_files_mode_755_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_audit_tools_files_mode_755_fix
		ensure_audit_tools_files_mode_755_chk
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