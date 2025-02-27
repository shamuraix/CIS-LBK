#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 03aa7ba5
#   function = deb_ensure_cron_daemon_enabled_running
#   applicable =
# # END METADATA
#
#
# CIS-LBK Deprecated Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_cron_daemon_enabled_running.sh
#
# Name                  Date            Description
# ------------------------------------------------------------------------------------------------
# J Brown               11/12/22        Recommendation "Ensure cron daemon is enabled and running"
# J Brown               02/21/24        This script will be deprecated and replaced by 'nix_ensure_cron_daemon_enabled_active.sh'
#

deb_ensure_cron_daemon_enabled_running()
{
    echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    nix_package_manager_set()
    {
        echo "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"
        if command -v rpm 2>/dev/null; then
            echo "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
            G_PQ="rpm -q"
            command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
            command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
            command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
            G_PR="$G_PM remove -y"
            export G_PQ G_PM G_PR
            echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        elif command -v dpkg 2>/dev/null; then
            echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
            G_PQ="dpkg -s"
            G_PM="apt"
            G_PR="$G_PM purge -y"
            export G_PQ G_PM G_PR
            echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
            G_PQ="unknown"
            G_PM="unknown"
            export G_PQ G_PM G_PR
            echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }

    deb_ensure_cron_daemon_enabled_running_chk()
    {
        echo -e "- Start check - Ensure cron daemon is enabled and running" | tee -a "$LOG" 2>> "$ELOG"

        # Determine if cron is enabled.
        l_enabled=$(systemctl is-enabled cron)
        l_running=$(systemctl status cron | grep 'Active: active (running)' | awk '{print $3}' | sed 's/[()]//g')

        if [ "$l_enabled" = "enabled" ] && [ "$l_running" = "running" ]; then
            echo -e "- PASS:\n- \"cron\" is enabled and running"  | tee -a "$LOG" 2>> "$ELOG"
            echo "- End check - \"cron\"" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            # print the reason why we are failing
            echo "- FAILED:"  | tee -a "$LOG" 2>> "$ELOG"
            echo "\"cron\" is not enabled and/or running" | tee -a "$LOG" 2>> "$ELOG"
            echo "- End check - \"cron\"" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi

        echo -e "- End check - Ensure cron daemon is enabled and running" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_cron_daemon_enabled_running_fix()
    {
        echo -e "- Start remediation - Ensure cron daemon is enabled and running" | tee -a "$LOG" 2>> "$ELOG"

        if [ "$l_enabled" != "enabled" ] || [ "$l_running" != "running" ]; then
            if systemctl is-enabled cron | grep -q 'masked'; then
                echo -e "- Unmasking cron service " | tee -a "$LOG" 2>> "$ELOG"
                systemctl unmask cron
                echo -e "- Enabling and starting cron service." | tee -a "$LOG" 2>> "$ELOG"
                systemctl --now enable cron
            else
                echo -e "- Enabling and starting cron service." | tee -a "$LOG" 2>> "$ELOG"
                systemctl --now enable cron
            fi
        fi

        echo -e "- End remediation - Ensure cron daemon is enabled and running" | tee -a "$LOG" 2>> "$ELOG"
    }

    # Set package manager information
    if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
        nix_package_manager_set
        [ "$?" != "101" ] && echo -e "- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
    fi

    # Determine if cronie is installed.  If it is, run the chk and fix subfunctions.
    echo "- Determining if \"cron\" is installed on the system" | tee -a "$LOG" 2>> "$ELOG"
    if $G_PQ cron | grep -Pq "^Status:\s+install\s+ok\s+installed" > /dev/null; then
        deb_ensure_cron_daemon_enabled_running_chk
        if [ $? -eq 101 ]; then
                [ -z "$l_test" ] && l_test="passed"
        else
            deb_ensure_cron_daemon_enabled_running_fix
            deb_ensure_cron_daemon_enabled_running_chk
            if [ "$?" = "101" ]; then
                    [ "$l_test" != "failed" ] && l_test="remediated"
            else
                    l_test="failed"
            fi
        fi
    else
        [ -z "$l_test" ] && l_test="passed"
        echo -e "- PASS:\n- \"cron\" is not installed"  | tee -a "$LOG" 2>> "$ELOG"
        echo "- End check - \"cron\"" | tee -a "$LOG" 2>> "$ELOG"
        return "${XCCDF_RESULT_PASS:-104}"
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
