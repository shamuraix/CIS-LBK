#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 30055b32
#   function = deb_ensure_audit_backlog_limit_sufficient
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_audit_backlog_limit_sufficient.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/03/20    Recommendation "Ensure audit_backlog_limit is sufficient"
# Eric Pinnell       01/14/21    Modified - Updated variable name to correct conflict with a global variable
# David Neilson      11/10/22    Runs update-grub
# Justin Brown       1/10/23     Rewrote to ignore EFI vs nonEFI on Debian

deb_ensure_audit_backlog_limit_sufficient()
{
        # Start recommendation entry for verbose log and output to screen
        echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
        l_test=""

        deb_ensure_audit_backlog_limit_sufficient_chk()
        {
                echo -e "- Start check - Ensure audit_backlog_limit is sufficient" | tee -a "$LOG" 2>> "$ELOG"
                l_output="" l_output2=""
                l_kernel_entries="$(find /boot -type f -name 'grub.cfg' -exec grep -Ph -- '^\h*linux\h' {} +)"

                echo -e "- Checking audit_backlog_limit value(s)" | tee -a "$LOG" 2>> "$ELOG"
                while l_kernel= read -r l_entry; do
                        if grep -Pq -- 'audit_backlog_limit=(819[2-9]|8[2-9][0-9]{2}|9[0-9]{3}|[1-9][0-9]{4,})' <<< "$l_entry"; then
                                l_output="$l_output\n$l_entry"
                        else
                                l_output2="$l_output2\n$l_entry"
                        fi
                done <<< "$l_kernel_entries"

                if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure audit_backlog_limit is sufficient" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
                        if [ -n "$l_output" ]; then
                                echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
                        fi
			echo -e "- End check - Ensure audit_backlog_limit is sufficient" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
        }

        deb_ensure_audit_backlog_limit_sufficient_fix()
        {
                echo -e "- Start remediation - Ensure audit_backlog_limit is sufficient" | tee -a "$LOG" 2>> "$ELOG"

                echo -e "- setting audit backlog limit" | tee -a "$LOG" 2>> "$ELOG"
                if grep -Pq -- 'audit_backlog_limit=' /etc/default/grub; then
                        echo -e "- Updating audit_backlog_limit value in /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri 's/^\s*(GRUB_CMDLINE_LINUX=")([^#"]*\s*)?(audit_backlog_limit=)([0-9]+)?(.*)$/\1\2\38192\5/' /etc/default/grub
                else
                        if grep -Pq "^\s*GRUB_CMDLINE_LINUX=" /etc/default/grub; then
                                echo -e "- Adding audit_backlog_limit value to GRUB_CMDLINE_LINUX in /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
                                sed -ri 's/^\s*(GRUB_CMDLINE_LINUX=")([^#"]*\s*)?(")(.*)$/\1\2 audit_backlog_limit=8192\3\4/' /etc/default/grub
                        else
                                echo -e "- Inserting GRUB_CMDLINE_LINUX=\"audit_backlog_limit=8192\" to /etc/default/grub" | tee -a "$LOG" 2>> "$ELOG"
                                echo "GRUB_CMDLINE_LINUX=\"audit_backlog_limit=8192\"" >> /etc/default/grub
                        fi
                fi
                echo -e "- Reconfiguring grub" | tee -a "$LOG" 2>> "$ELOG"
                if command -v update-grub &> /dev/null; then
                        update-grub
                else
                        grub2-mkconfig -o /boot/grub2/grub.cfg
                fi
                
                echo -e "- End remediation - Ensure audit_backlog_limit is sufficient" | tee -a "$LOG" 2>> "$ELOG"
        }

        deb_ensure_audit_backlog_limit_sufficient_chk
        if [ "$?" = "101" ]; then
                [ -z "$l_test" ] && l_test="passed"
        else
                deb_ensure_audit_backlog_limit_sufficient_fix
                deb_ensure_audit_backlog_limit_sufficient_chk
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