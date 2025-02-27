#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = a688b202
#   function = deb_ensure_password_failed_attempts_lockout_includes_root
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_failed_attempts_lockout_includes_root.sh
#
# Name                  Date            Description
# ------------------------------------------------------------------------------------------------
# J Brown               03/23/24        Recommendation "Ensure password failed attempts lockout includes root account"
#

deb_ensure_password_failed_attempts_lockout_includes_root()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_password_failed_attempts_lockout_includes_root_chk()
	{
        echo -e "- Start check - Ensure password failed attempts lockout includes root account" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        # Verify settings in /etc/security/faillock.conf
        l_faillock_entry="$(grep -Pi -- '^\h*(even_deny_root|root_unlock_time\h*=\h*[0-9]+)\b' /etc/security/faillock.conf)"

        if [ "$l_faillock_entry" = "even_deny_root" ]; then
            l_faillock_val="even_deny_root"
        else
            l_faillock_val="$(awk -F'=' '{print $2}' <<< "$l_faillock_entry" | xargs)"
        fi

        if [ -n "$l_faillock_val" ]; then
            if [ "$l_faillock_val"  -le 60 ] || [ "$l_faillock_val" = "even_deny_root" ]; then
                l_output="$l_output\n- /etc/security/faillock.conf value set to: $l_faillock_val"
            else
                l_output2="$l_output2\n- /etc/security/faillock.conf value set to: $l_faillock_val"
            fi
        else
            l_output2="$l_output2\n- No value found in /etc/security/faillock.conf"
        fi

        # Verify settings in /etc/pam.d/common-auth
        l_faillock_config="$(grep -Pi -- '^\h*auth\h+([^#\n\r]+\h+)pam_faillock\.so\h+([^#\n\r]+\h+)?root_unlock_time\h*=\h*(6[1-9]|[1-9][0-9]{2,})\b' /etc/pam.d/common-auth)"

        if [ -n "$l_faillock_config" ]; then
            l_output2="$l_output2\n- 'root_unlock_time' value(s) NOT configured correctly in /etc/pam.d/common-auth:\n$l_faillock_config"
        else
            l_output="$l_output\n- No non-compliant 'root_unlock_time' values configured in /etc/pam.d/common-auth"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password failed attempts lockout includes root account" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure password failed attempts lockout includes root account" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }

    deb_ensure_password_failed_attempts_lockout_includes_root_fix()
	{
        echo -e "- Start remediation - Ensure password failed attempts lockout includes root account" | tee -a "$LOG" 2>> "$ELOG"

        # Update the entries in /etc/security/faillock.conf
        if [ -z "$l_faillock_val" ] || [ "$l_faillock_val"  -gt 60 ] ; then
            if grep -Piq -- '^\h*(#\h*)?root_unlock_time\h*=\h*[0-9]+\b' /etc/security/faillock.conf; then
                echo -e "- Updating 'root_unlock_time' value in /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^\s*(#\s*)?(root_unlock_time\s*=)(\s*[0-9]+)(.*)?$/\2 60 \4/' /etc/security/faillock.conf
            else
                if grep -Pq -- "^\h*#\h*The\h*default\h*is\h*600\." /etc/security/faillock.conf; then
                    echo -e "- Adding 'root_unlock_time = 60' to /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri '/^\s*#\s+the\s+value\s+is\s+the\s+same\s+as\s+of\s+the\s+`unlock_time`\s+option./a root_unlock_time = 60' /etc/security/faillock.conf
                else
                    echo -e "- Inserting 'root_unlock_time = 60' to end of /etc/security/faillock.conf" | tee -a "$LOG" 2>> "$ELOG"
                    echo "root_unlock_time = 60" >> /etc/security/faillock.conf
                fi
            fi
        fi

        # Update the entries in /usr/share/pam-configs/*
        l_config_files="$(grep -Pl -- '\bpam_faillock\.so\h+([^#\n\r]+\h+)?root_unlock_time\b' /usr/share/pam-configs/*)"
        if [ -n "$l_config_files" ]; then
            while read -r l_file; do
                echo -e "- Removing 'root_unlock_time' values from $l_file" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^(.*pam_faillock\.so)([^#]+\s*)?(root_unlock_time\s*=\s*[0-9]+)(.*)?$/\1\2\4/' "$l_file"
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

        echo -e "- End remediation - Ensure password failed attempts lockout includes root account" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_password_failed_attempts_lockout_includes_root_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_password_failed_attempts_lockout_includes_root_fix
            if [ "$l_test" != "manual" ] ; then
                deb_ensure_password_failed_attempts_lockout_includes_root_chk
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