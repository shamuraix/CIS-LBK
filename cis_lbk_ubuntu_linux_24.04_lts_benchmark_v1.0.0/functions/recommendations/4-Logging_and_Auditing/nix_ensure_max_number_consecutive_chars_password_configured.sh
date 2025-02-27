#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = fd8a1d7c
#   function = ensure_max_number_consecutive_chars_password_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_max_number_consecutive_chars_password_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       07/03/23    Recommendation "Ensure maximum number of same consecutive characters in a password is configured"
# 
 
ensure_max_number_consecutive_chars_password_configured()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""
   
    ensure_max_number_consecutive_chars_password_configured_chk()
	{
        echo -e "- Start check - Ensure maximum number of same consecutive characters in a password is configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        if grep -Piq '^\h*maxrepeat\h*=\h*[1-3]\b' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Entry found in pwquality.conf: $(grep -Pi '^\h*maxrepeat\h*=\h*' /etc/security/pwquality.conf)"
        elif grep -Piq '^\h*#\h*maxrepeat\h*=\h*' /etc/security/pwquality.conf; then
            l_output2="$l_output2\n- Commented entry found in pwquality.conf: $(grep -Pi '^\h*#\h*maxrepeat\h*=\h*' /etc/security/pwquality.conf)"
        elif grep -Piq '^\h*maxrepeat\h*=\h*' /etc/security/pwquality.conf; then
            l_output2="$l_output2\n- Incorrect entry found in pwquality.conf: $(grep -Pi '^\h*maxrepeat\h*=\h*' /etc/security/pwquality.conf)"
        else
            l_output2="$l_output2\n- NO Entry found in pwquality.conf for maxrepeat"
        fi
      
        if [ -z "$l_output2" ]; then
            echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure maximum number of same consecutive characters in a password is configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "- FAIL:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure maximum number of same consecutive characters in a password is configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }
   
    ensure_max_number_consecutive_chars_password_configured_fix()
	{
        echo -e "- Start remediation - Ensure maximum number of same consecutive characters in a password is configured" | tee -a "$LOG" 2>> "$ELOG"
        
        if grep -Piq '^\h*(#\h*)?maxrepeat\s+' /etc/security/pwquality.conf; then
            echo -e "- Updating maxrepeat entry in /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
            sed -ri 's/^\s*(#\s*)?(maxrepeat\s*=)(\s*\S+\s*)(\s+#.*)?$/\2 3\4/' /etc/security/pwquality.conf
        else
            echo -e "- Adding maxrepeat entry to /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
            echo "maxrepeat = 3" >> /etc/security/pwquality.conf
        fi
        
        echo -e "- End remediation - Ensure maximum number of same consecutive characters in a password is configured" | tee -a "$LOG" 2>> "$ELOG"
    }
   
    ensure_max_number_consecutive_chars_password_configured_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            ensure_max_number_consecutive_chars_password_configured_fix
            ensure_max_number_consecutive_chars_password_configured_chk
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