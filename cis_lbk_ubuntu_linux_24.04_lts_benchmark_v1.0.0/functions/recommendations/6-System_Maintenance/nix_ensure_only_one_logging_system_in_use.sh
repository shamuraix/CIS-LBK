#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 00e2c0a0
#   function = ensure_only_one_logging_system_in_use
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
# ~/CIS-LBK/functions/recommendations/nix_ensure_only_one_logging_system_in_use.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus         06/17/24    Recommendation "Ensure only one logging system is in use"
# 

ensure_only_one_logging_system_in_use()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	
	ensure_only_one_logging_system_in_use_chk()
	{
		echo -e "- Start check - Ensure only one logging system is in use" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""

		# Check the status of rsyslog and journald
		if systemctl is-active --quiet rsyslog; then
        	l_output="$l_output\n - rsyslog is in use\n- follow the recommendations in Configure rsyslog subsection only"
    		elif systemctl is-active --quiet systemd-journald; then
        		l_output="$l_output\n - journald is in use\n- follow the recommendations in Configure journald subsection only"
    	else
        	echo -e "unable to determine system logging"
""        	l_output2="$l_output2\n - unable to determine system logging\n- Configure only ONE system logging: rsyslog OR journald"
    	fi

    	if [ -z "$l_output2" ]; then  # Provide audit results
    	    echo -e "- PASSED:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
    	    echo -e "- End check - Ensure only one logging system is in use" | tee -a "$LOG" 2>> "$ELOG"
        	return "${XCCDF_RESULT_PASS:-101}"
    	else
        	echo -e "\n- FAILED:\n - Reason(s) for audit failure:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure only one logging system is in use" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
    	fi
	}

	ensure_only_one_logging_system_in_use_fix()
	{
		echo -e "- Start remediation - EEnsure only one logging system is in use" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- Result - requires manual remediation\n - unable to determine system logging\n- Configure only ONE system logging: rsyslog OR journald" | tee -a "$LOG" 2>> "$ELOG"
		l_test="manual"

		echo -e "- End remediation - Ensure only one logging system is in use" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_only_one_logging_system_in_use_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_only_one_logging_system_in_use_fix
        if [ "$l_test" != "manual" ]; then
            ensure_only_one_logging_system_in_use_chk
            if [ "$?" = "101" ]; then
                [ "$l_test" != "failed" ] && l_test="remediated"
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