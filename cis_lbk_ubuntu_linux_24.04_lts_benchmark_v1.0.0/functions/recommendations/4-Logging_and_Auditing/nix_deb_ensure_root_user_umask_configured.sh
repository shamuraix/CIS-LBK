#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 9d436a62
#   function = deb_ensure_root_user_umask_configured
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
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_root_user_umask_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus          11/07/23    Recommendation "Ensure root user umask is configured"
#
deb_ensure_root_user_umask_configured()
{
    echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation - Ensure root user umask is configured \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_root_user_umask_configured_chk()
    {
        echo -e "- Start check - Ensure root user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2="" l_root_umask=""

        l_root_umask="$(grep -Psi -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' /root/.bash_profile /root/.bashrc)"
        if [ -n "$l_root_umask" ]; then   
            l_output2="$l_root_umask\n - root user umask is NOT configured correctly"
        else
            l_output="- root user umask is configured correctly"
        fi    

        if [ -z "$l_output2" ]; then     
            echo -e "- PASS: root user umask is configured correctly" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure root user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "- FAIL:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure root user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }

    deb_ensure_root_user_umask_configured_fix()
    {
        echo -e "- Start Remediation - Ensure root user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
         l_failed_locations=$(grep -Pls -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' /root/.bash_profile /root/.bashrc)

        if [ -n "$l_failed_locations" ]; then
            for l_file in "$l_failed_locations"; do
                echo -e "Fixing umask configuration in the following location(s):$l_file" | tee -a "$LOG" 2>> "$ELOG"
                sed -i '/^\s*umask/s/.*/# &/'  $l_file # Comment out existing umask lines
                echo -e "umask 0027" >> $l_file  # Add umask 0027 line to the $l_file
            done
                
        fi
    }

    deb_ensure_root_user_umask_configured_chk
        if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
        deb_ensure_root_user_umask_configured_fix
        deb_ensure_root_user_umask_configured_chk
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