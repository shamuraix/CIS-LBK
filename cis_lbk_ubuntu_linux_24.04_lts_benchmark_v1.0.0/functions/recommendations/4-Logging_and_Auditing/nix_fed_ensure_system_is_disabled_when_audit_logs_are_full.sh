#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = d00a402f
#   function = fed_ensure_system_is_disabled_when_audit_logs_are_full
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_fed_ensure_system_is_disabled_when_audit_logs_are_full.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Randie Bejar       10/13/23   Recommendation "Ensure system is disabled when audit logs are full"
#

fed_ensure_system_is_disabled_when_audit_logs_are_full()
{
    echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation - Ensure system is disabled when audit logs are full \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

    fed_ensure_system_is_disabled_when_audit_logs_are_full_chk()
    {
        l_output="" l_output2=""

        # verify the disk_full_action is set to either halt or single
        if grep -P -- '^\h*disk_full_action\h*=\h*(halt|single)\b' /etc/audit/auditd.conf; then
            l_output="passed"
        fi

        # verify the disk_error_action is set to syslog, single, or halt   
        if grep -P -- '^\h*disk_error_action\h*=\h*(syslog|single|halt)\b' /etc/audit/auditd.conf; then
            l_output2="passed"
        fi    

        if  [ "$l_output" = "passed" ] && [ "$l_output2" = "passed" ] ; then
			echo -e "- PASS:\n- system will be disabled when audit logs are full"  | tee -a "$LOG" 2>> "$ELOG"
		   	echo "- End check - system will be disabled" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
		   	echo "- FAILED: system will NOT be disabled when audit logs are full"  | tee -a "$LOG" 2>> "$ELOG"
		   	echo "- End check - system will NOT be disabled" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_FAIL:-102}"
		fi	
    }

    fed_ensure_system_is_disabled_when_audit_logs_are_full_fix()
    {
        echo -e " Start remediation - Ensure system is disabled when audit logs are full" | tee -a "$LOG" 2>> "$ELOG"
        # Setting disk_full_action to halt
        if [ -z "$l_output" ]; then
            sed -ri 's/\s*(#*\s*)?(disk_full_action\s*=\s*)(\S+\s*)?(.*)$/\2halt \4/' /etc/audit/auditd.conf
        fi

        # Setting disk_error_action to halt
        if [ -z "$l_output2" ]; then
            sed -ri 's/\s*(#*\s*)?(disk_error_action\s*=\s*)(\S+\s*)?(.*)$/\2halt \4/' /etc/audit/auditd.conf
        fi
    }

    fed_ensure_system_is_disabled_when_audit_logs_are_full_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        fed_ensure_system_is_disabled_when_audit_logs_are_full_fix
        fed_ensure_system_is_disabled_when_audit_logs_are_full_chk
        if [ "$?" = "101" ]; then
            [ "$l_test" != "failed" ] && test="remediated"
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
