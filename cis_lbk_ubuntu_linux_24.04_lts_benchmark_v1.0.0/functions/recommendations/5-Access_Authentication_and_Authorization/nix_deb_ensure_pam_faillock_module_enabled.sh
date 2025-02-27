#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 19461218
#   function = deb_ensure_pam_faillock_module_enabled
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_pam_faillock_module_enabled.sh
#
# Name                Date          Description
# ------------------------------------------------------------------------------------------------
# J Brown             12/31/22      Recommendation "Ensure pam_faillock module is enabled"
#

deb_ensure_pam_faillock_module_enabled()
{
    echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_pam_faillock_module_enabled_chk()
    {
        echo -e "- Start check - Ensure pam_faillock module is enabled" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        # Verify common-auth preauth
        if grep -Pqs -- '^\h*auth\h+([^#\r\n]+)?\h+pam_faillock\.so\h+preauth\b' /etc/pam.d/common-auth; then
            l_output="$l_output\n- /etc/pam.d/common-auth contains:\n  $(grep -Ps -- '^\h*auth\h+([^#\r\n]+)?\h+pam_faillock\.so\h+preauth\b' /etc/pam.d/common-auth)"
        else
            l_output2="$l_output2\n- /etc/pam.d/common-auth DOES NOT include a pam_faillock.so preauth line"
        fi

        # Verify common-auth authfail
        if grep -Pqs -- '^\h*auth\h+([^#\r\n]+)?\h+pam_faillock\.so\h+authfail\b' /etc/pam.d/common-auth; then
            l_output="$l_output\n- /etc/pam.d/common-auth contains:\n  $(grep -Ps -- '^\h*auth\h+([^#\r\n]+)?\h+pam_faillock\.so\h+authfail\b' /etc/pam.d/common-auth)"
        else
            l_output2="$l_output2\n- /etc/pam.d/common-auth DOES NOT include a pam_faillock.so authfail line"
        fi

        # Verify common-account
        if grep -Pqs -- '^\h*account\s+([^#\r\n]+)?\h+pam_faillock\.so\b' /etc/pam.d/common-account; then
            l_output="$l_output\n- /etc/pam.d/common-account contains:\n  $(grep -Ps -- '^\h*account\s+([^#\r\n]+)?\h+pam_faillock\.so\b' /etc/pam.d/common-account)"
        else
            l_output2="$l_output2\n- /etc/pam.d/common-account DOES NOT include a pam_unix.so line"
        fi

        if [ -z "$l_output2" ]; then
            echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure pam_faillock module is enabled" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "- FAIL:\n- Failing Values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing Values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
            echo -e "- End check - Ensure pam_faillock module is enabled" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }

    deb_ensure_pam_faillock_module_enabled_fix()
    {
        echo -e "- Start remediation - Ensure pam_faillock module is enabled" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "- Creating pam-auth-update profiles" | tee -a "$LOG" 2>> "$ELOG"
        # Check if file exists; if so set remedaiton manual, if not, create file with req. contents
        if [ -e /usr/share/pam-configs/faillock ]; then
            echo -e "  - /usr/share/pam-configs/faillock file exists\n  - Verify it's contents against the benchmark remediation and run 'pam-auth-update'" | tee -a "$LOG" 2>> "$ELOG"
            l_test="manual"
        else
            echo -e "  - Creating '/usr/share/pam-configs/faillock' file" | tee -a "$LOG" 2>> "$ELOG"
            faillock_contents=('Name: Enable pam_faillock to deny access' 'Default: yes' 'Priority: 0' 'Auth-Type: Primary' 'Auth:' '        [default=die]                   pam_faillock.so authfail')
            printf '%s\n' "${faillock_contents[@]}" > /usr/share/pam-configs/faillock
        fi

        # Check if file exists; if so set remedaiton manual, if not, create file with req. contents
        if [ -e /usr/share/pam-configs/faillock_notify ]; then
            echo -e "  - /usr/share/pam-configs/faillock_notify file exists\n  - Verify it's contents against the benchmark remediation and run 'pam-auth-update'" | tee -a "$LOG" 2>> "$ELOG"
            l_test="manual"
        else
            echo -e "  - Creating '/usr/share/pam-configs/faillock_notify' file" | tee -a "$LOG" 2>> "$ELOG"
            faillock_notify_contents=('Name: Notify of failed login attempts and reset count upon success' 'Default: yes' 'Priority: 1024' 'Auth-Type: Primary' 'Auth:' '        requisite                       pam_faillock.so preauth' 'Account-Type: Primary' 'Account:' '        required                        pam_faillock.so')
            printf '%s\n' "${faillock_notify_contents[@]}" > /usr/share/pam-configs/faillock_notify
        fi

        if [ "$l_test" != "manual" ]; then
            echo -e "- Running 'pam-auth-update' to enable the faillock profile" | tee -a "$LOG" 2>> "$ELOG"
            l_pam_auth_update="$(timeout 5s pam-auth-update --enable faillock --package 2>&1)"

            # Verify that command ran successfully
            if [ $? -ne 124 ]; then
                if grep -Pqs -- '\h+not\h+updating\b' <<< "$l_pam_auth_update"; then
                    echo -e "- 'pam-auth-update' could not enable the faillock profile\n- Verify that no manual changes were made to the files in /etc/pam.d" | tee -a "$LOG" 2>> "$ELOG"
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

        if [ "$l_test" != "manual" ]; then
            echo -e "- Running 'pam-auth-update' to enable the faillock_notify profile" | tee -a "$LOG" 2>> "$ELOG"
            l_pam_auth_update="$(timeout 5s pam-auth-update --enable faillock_notify --package 2>&1)"

            # Verify that command ran successfully
            if [ $? -ne 124 ]; then
                if grep -Pqs -- '\h+not\h+updating\b' <<< "$l_pam_auth_update"; then
                    echo -e "- 'pam-auth-update' could not enable the faillock_notify profile\n- Verify that no manual changes were made to the files in /etc/pam.d" | tee -a "$LOG" 2>> "$ELOG"
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

        echo -e "- End remediation - Ensure pam_faillock module is enabled" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_pam_faillock_module_enabled_chk
    if [ $? -eq 101 ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_pam_faillock_module_enabled_fix
            if [ "$l_test" != "manual" ]; then
                deb_ensure_pam_faillock_module_enabled_chk
                if [ $? -eq 101 ]; then
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