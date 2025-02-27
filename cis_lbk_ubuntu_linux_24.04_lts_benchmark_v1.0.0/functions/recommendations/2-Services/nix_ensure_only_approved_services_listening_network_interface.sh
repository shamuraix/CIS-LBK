#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 4bf76967
#   function = ensure_only_approved_services_listening_network_interface
#   applicable =
# # END METADATA
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_only_approved_services_listening_network_interface.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# J Brown              08/28/23    Recommendation "Ensure only approved services are listening on a network interface"
#

ensure_only_approved_services_listening_network_interface()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    ensure_only_approved_services_listening_network_interface_chk()
    {
        echo -e "- Start check - Ensure only approved services are listening on a network interface" | tee -a "$LOG" 2>> "$ELOG"
        l_svcs=""

        l_svcs="$(ss -plntu)"

        if [ -z "$l_svcs" ]; then
                echo -e "- PASS:\n- No services appear to be listening"  | tee -a "$LOG" 2>> "$ELOG"
                echo -e "- End check - Ensure only approved services are listening on a network interface" | tee -a "$LOG" 2>> "$ELOG"
                return "${XCCDF_RESULT_PASS:-101}"
            else
                echo -e "- FAIL:\n- Services that appear to be listing: \n$l_svcs" | tee -a "$LOG" 2>> "$ELOG"
                echo -e "- End check - Ensure only approved services are listening on a network interface" | tee -a "$LOG" 2>> "$ELOG"
                return "${XCCDF_RESULT_FAIL:-102}"
            fi
    }

    ensure_only_approved_services_listening_network_interface_fix()
    {
        echo -e "- Start remediation - Ensure only approved services are listening on a network interface" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "- If a listed service is not required, remove the package containing the service.\n- If the package containing the service is required or part of a dependency, stop and mask the service." | tee -a "$LOG" 2>> "$ELOG"
        l_test=manual

        echo -e "- End remediation - Ensure only approved services are listening on a network interface" | tee -a "$LOG" 2>> "$ELOG"
    }

    ensure_only_approved_services_listening_network_interface_chk
    if [ $? -eq 101 ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            ensure_only_approved_services_listening_network_interface_fix
            if [ "$l_test" != "manual" ]; then
                ensure_only_approved_services_listening_network_interface_chk
                if [ $? -eq 101 ]; then
                    [ "$l_test" != "failed" ] && l_test="remediated"
                else
                    l_test="failed"
                fi
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