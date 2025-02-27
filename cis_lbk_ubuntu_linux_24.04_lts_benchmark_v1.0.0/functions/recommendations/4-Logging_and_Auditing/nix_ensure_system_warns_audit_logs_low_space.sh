#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 219235c7
#   function = ensure_system_warns_audit_logs_low_space
#   applicable =
# # END METADATA
#
#
#
#
#
#
#
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_system_warns_audit_logs_low_space.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus		03/11/24	Recommendation "Ensure system warns when audit logs are low on space"
# 

ensure_system_warns_audit_logs_low_space()
{
	echo
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	ensure_system_warns_audit_logs_low_space_chk()
	{
		echo -e "- Start check - Ensure system warns when audit logs are low on space" | tee -a "$LOG" 2>> "$ELOG"
		l_test1=""
		l_test2=""
		
		# Check space_left_action
		if grep -Eqs '^\s*admin_space_left_action\s*=\s*(email|exec|single|halt)\b' /etc/audit/auditd.conf; then
			l_test1=passed
		fi

		# Check admin_space_left_action
		if grep -Eqs '^\s*admin_space_left_action\s*=\s*(halt|single)\b' /etc/audit/auditd.conf; then
			l_test2=passed
		fi
		
		if  [ "$l_test1" = "passed" ] && [ "$l_test2" = "passed" ]; then
			echo -e "- PASS:\n- system warns when audit logs are low on space"  | tee -a "$LOG" 2>> "$ELOG"
		   	echo -e "- End check - Ensure system warns when audit logs are low on space" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
		   	echo -e "- FAILED: system does NOT warn when audit logs are low on space" | tee -a "$LOG" 2>> "$ELOG"
		   	echo -e "- End check - Ensure system warns when audit logs are low on space" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_FAIL:-102}"
		fi	
	}

	ensure_system_warns_audit_logs_low_space_fix()
	{
		echo -e "- Start remediation - Ensure system warns when audit logs are low on space" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Setting space_left_action parameter in /etc/audit/auditd.conf to email" | tee -a "$LOG" 2>> "$ELOG"
		
		if [ -z "$l_test1" ]; then
			if grep -Eqs '^\s*(#*\s*)?space_left_action\s*=\s*' /etc/audit/auditd.conf; then
				sed -ri 's/^\s*(#*\s*)?(space_left_action\s*=\s*)(\S+\s*)?(.*)$/\2email \4/' /etc/audit/auditd.conf
			else
				echo "space_left_action = email" >> /etc/audit/auditd.conf
			fi
		fi	

		echo -e "- Setting admin_space_left_action parameter in /etc/audit/auditd.conf to single" | tee -a "$LOG" 2>> "$ELOG"

		if [ -z "$l_test2" ]; then
			if grep -Eqs '\s*(#*\s*)?admin_space_left_action\s*=\s*' /etc/audit/auditd.conf; then
				sed -ri 's/\s*(#*\s*)?(admin_space_left_action\s*=\s*)(\S+\s*)?(.*)$/\2single \4/' /etc/audit/auditd.conf
			else
				echo "admin_space_left_action = single" >> /etc/audit/auditd.conf
			fi
		fi

		echo -e "- Reboot required to reload the active auditd configuration settings" | tee -a "$LOG" 2>> "$ELOG"
		G_REBOOT_REQUIRED="yes"
		echo -e "- End remediation - Ensure the audit log directory is 0750 or more restrictive" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_system_warns_audit_logs_low_space_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_system_warns_audit_logs_low_space_fix
		[ "$G_REBOOT_REQUIRED" = "yes" ] && l_test="manual"
		ensure_system_warns_audit_logs_low_space_chk
		if [ "$?" != "101" ]; then
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