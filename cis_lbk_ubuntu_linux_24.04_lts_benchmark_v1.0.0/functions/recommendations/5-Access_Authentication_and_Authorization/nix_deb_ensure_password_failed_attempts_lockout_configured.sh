#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = cd18c581
#   function = deb_ensure_password_failed_attempts_lockout_configured
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_failed_attempts_lockout_configured.sh
#
# Name                  Date        Description
# ------------------------------------------------------------------------------------------------
# J Brown               1/2/23      Recommendation "Ensure lockout for failed password attempts is configured"
#

deb_ensure_password_failed_attempts_lockout_configured()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_password_failed_attempts_lockout_configured_chk()
	{
        echo -e "- Start check - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        # Verify settings in /etc/security/faillock.conf
        l_faillock_val="$(grep -Pi -- '^\h*deny\h*=' /etc/security/faillock.conf | awk -F'=' '{print $2}' | xargs)"

        if [ -n "$l_faillock_val" ]; then
            if [ "$l_faillock_val"  -gt 0 ] && [ "$l_faillock_val"  -le 5 ]; then
                l_output="$l_output\n- /etc/security/faillock.conf 'deny' value set to: $l_faillock_val"
            else
                l_output2="$l_output2\n- /etc/security/faillock.conf 'deny' value set to: $l_faillock_val"
            fi
        else
            l_output2="$l_output2\n- No 'deny' value found in /etc/security/faillock.conf"
        fi

        # Verify settings in /etc/pam.d/common-auth
        l_faillock_config="$(grep -Pi -- '^\h*auth\h+(requisite|required|sufficient)\h+pam_faillock\.so\h+([^#\n\r]+\h+)?deny\h*=\h*(0|[6-9]|[1-9][0-9]+)\b' /etc/pam.d/common-auth)"

        if [ -n "$l_faillock_config" ]; then
            l_output2="$l_output2\n- 'deny' value(s) NOT configured correctly in /etc/pam.d/common-auth:\n$l_faillock_config"
        else
            l_output="$l_output\n- No non-compliant 'deny' values configured in /etc/pam.d/common-auth"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }

    deb_ensure_password_failed_attempts_lockout_configured_fix()
	{
        echo -e "- Start remediation - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"

        # Update the entries in /etc/security/faillock.conf
        if [ -z "$l_faillock_val" ] || [ "$l_faillock_val"  -le 0 ] || [ "$l_faillock_val"  -gt 5 ]; then
            if grep -Piq -- '^\h*deny\h*=\h*[0-9]+\b' /etc/security/faillock.conf; then
                echo -e "- Updating 'deny' value in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^\s*(#\s*)?(deny\s*=)(\s*\S+\b)(.*)?$/\2 5 \4/' /etc/security/faillock.conf
            else
                if grep -Pq -- "^\h*#\h*The\h*default\h*is\h*3\." /etc/security/faillock.conf; then
                    echo -e "- Adding 'deny = 5' to /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri '/^\s*#\s*The\s*default\s*is\s*3\./a deny = 5' /etc/security/faillock.conf
                else
                    echo -e "- Inserting 'deny = 5' to end of /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                    echo "deny = 5" >> /etc/security/faillock.conf
                fi
            fi
        fi

        # Update the entries in /usr/share/pam-configs/*
        l_config_files="$(grep -Pl -- '\bpam_faillock\.so\h+([^#\n\r]+\h+)?deny\b' /usr/share/pam-configs/*)"
        if [ -n "$l_config_files" ]; then
            while read -r l_file; do
                echo -e "- Removing 'deny' values from $l_file" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^(.*pam_faillock\.so)([^#]+\s*)?(deny\s*=\s*[0-9]+)(#.*)?$/\1\2\4/' "$l_file"
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

        echo -e "- End remediation - Ensure lockout for failed password attempts is configured" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_password_failed_attempts_lockout_configured_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_password_failed_attempts_lockout_configured_fix
            if [ "$l_test" != "manual" ] ; then
                deb_ensure_password_failed_attempts_lockout_configured_chk
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