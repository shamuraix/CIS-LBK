#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 485eddcf
#   function = deb_ensure_password_history_enforced_root_user
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_history_enforced_root_user.sh
#
# Name                  Date            Description
# ------------------------------------------------------------------------------------------------
# J Brown               03/28/24        Recommendation "Ensure password history is enforced for the root user"
#

deb_ensure_password_history_enforced_root_user()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_password_history_enforced_root_user_chk()
	{
        echo -e "- Start check - Ensure password history is enforced for the root user" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        # Verify settings in /etc/pam.d/common-password
        l_pwhistory_config="$(grep -Psi -- '^\h*password\h+[^#\n\r]+\h+pam_pwhistory\.so\h+([^#\n\r]+\h+)?enforce_for_root\b' /etc/pam.d/common-password)"

        if [ -n "$l_pwhistory_config" ]; then
            l_output="$l_output\n- 'enforce_for_root' is configured in /etc/pam.d/common-password:\n$l_pwhistory_config"
        else
            l_output2="$l_output2\n- 'enforce_for_root' is NOT configured in /etc/pam.d/common-password"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password history is enforced for the root user" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure password history is enforced for the root user" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }

    deb_ensure_password_history_enforced_root_user_fix()
	{
        echo -e "- Start remediation - Ensure password history is enforced for the root user" | tee -a "$LOG" 2>> "$ELOG"

        # Update the entries in /usr/share/pam-configs/*
        l_config_files="$(grep -Pl -- '\bpam_pwhistory\.so\h+([^#\n\r]+\h+)?' /usr/share/pam-configs/*)"

        if [ -n "$l_config_files" ]; then
            while read -r l_file; do
                if ! grep -P '\benforce_for_root\b' "$l_file"; then
                    echo -e "- Adding 'enforce_for_root' values in $l_file" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^(.*pam_pwhistory\.so)([^#]+\s*)?(.*)?$/\1 enforce_for_root\2\3/' "$l_file"
                fi
            done <<< "$l_config_files"

            # run pam-auth-update
            echo -e "- Running 'pam-auth-update'" | tee -a "$LOG" 2>> "$ELOG"
            l_pam_auth_update="$(timeout 5s pam-auth-update --package 2>&1)"

            # Verify that command ran successfully
            if [ $? -ne 124 ]; then
                if grep -Pqs -- '\h+not\h+updating\b' <<< "$l_pam_auth_update"; then
                    echo -e "- 'pam-auth-update' did NOT complete successfully\n- Verify that no manual changes were made to the files in /etc/pam.d" | tee -a "$LOG" 2>> "$ELOG"
                    l_test="manual"
                else
                    echo -e "- 'pam-auth-update' command ran successfully" | tee -a "$LOG" 2>> "$ELOG"
                fi
            else
                # Resetting terminal
                reset &> /dev/null
                echo -e "- 'pam-auth-update' command hung during execution and was killed\n- Verify that no manual changes were made to the files in /etc/pam.d" | tee -a "$LOG" 2>> "$ELOG"
                l_test="manual"
            fi
        fi

        echo -e "- End remediation - Ensure password history is enforced for the root user" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_password_history_enforced_root_user_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_password_history_enforced_root_user_fix
            if [ "$l_test" != "manual" ] ; then
                deb_ensure_password_history_enforced_root_user_chk
                if [ "$?" = "101" ] ; then
                    [ "$l_test" != "failed" ] && l_test="remediated"
                else
                    l_test="failed"
                fi
            fi
        fi
    fi

	# Set return code and return
	case "$l_test" in
		passed)
			echo "Recommendation \"$RNA\" No remediation required" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo "Recommendation \"$RNA\" successfully remediated" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo "Recommendation \"$RNA\" requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo "Recommendation \"$RNA\" Something went wrong - Recommendation is non applicable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}