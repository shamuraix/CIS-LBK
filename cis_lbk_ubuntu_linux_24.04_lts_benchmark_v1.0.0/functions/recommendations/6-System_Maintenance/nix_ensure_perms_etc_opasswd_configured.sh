#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 3c0a7a22
#   function = ensure_perms_etc_opasswd_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Remediation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_perms_etc_opasswd_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# J Brown             07/02/23     Recommendation "Ensure permissions on /etc/opasswd are configured"

ensure_perms_etc_opasswd_configured()
{

	# Ensure permissions on /etc/opasswd are configured
	echo
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	l_perms_correct="0600"
	l_uid_correct="root"
	l_gid_correct="root"

	ensure_perms_etc_opasswd_configured_chk()
	{
		# Checks for correctly set permissions and ownership
		echo "- Start check - Ensure permissions on /etc/opasswd are configured" | tee -a "$LOG" 2>> "$ELOG"
         l_output="" l_output2=""
		
        for file in /etc/security/opasswd /etc/security/opasswd.old; do
            if [ -e $file ]; then
                l_buffer=$(stat $file | grep -i access | grep -i id)
                l_perms=$(echo $l_buffer | awk '{print $2}' | cut -d'/' -f1 | sed "s/(//g")
                l_uid=$(echo $l_buffer |  awk '{print $6}' | sed "s/)//g")
                l_gid=$(echo $l_buffer |  awk '{print $NF}' | sed "s/)//g")
                l_ownergroup="" l_permissions=""

                if ! grep -Pq '[0-6]00' <<< "$l_perms"; then
                    l_permissions="failed"
                fi

                if [ "$l_uid" != "$l_uid_correct" ] || [ "$l_gid" != "$l_gid_correct" ]; then
                    l_ownergroup="failed"
                fi

                # If $l_perms does not equal "failed" and $l_uid does not equal "failed", we pass
                if [ "$l_permissions" != "failed" ] && [ "$l_ownergroup" != "failed" ]; then
                    l_output="$l_output\n- $file permissions set to \"$l_perms_correct\", ownership set to \"$l_uid_correct\", and group set to \"$l_gid_correct\""
                else
                    # print the reason why we are failing
                    [ "$l_perms" != "$l_perms_correct" ] && l_output2="$l_output2\n- $file permissions are set to \"$l_perms\""
                    [ "$l_uid" != "$l_uid_correct" ] && [ "$l_gid" != "$l_gid_correct" ] && l_output2="$l_output2\n- $file owner is \"$l_uid\" and group is \"$l_gid\""
                fi
            else
                l_output="$l_output\n- $file was not found on the system"
            fi
        done

        if [ -z "$l_output2" ]; then
            echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo "- End check - Ensure permissions on /etc/opasswd are configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
            [ -n "$l_output" ] && echo -e "- * Correctly configured * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo "- End check - Ensure permissions on /etc/opasswd are configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
	}

	ensure_perms_etc_opasswd_configured_fix()
	{
		echo "- Start remediation - Ensure permissions on /etc/opasswd are configured" | tee -a "$LOG" 2>> "$ELOG"
		
        for file in /etc/security/opasswd /etc/security/opasswd.old; do
            if [ -e $file ]; then
                l_buffer=$(stat $file | grep -i access | grep -i id)
                l_perms=$(echo $l_buffer | awk '{print $2}' | cut -d'/' -f1 | sed "s/(//g")
                l_uid=$(echo $l_buffer |  awk '{print $6}' | sed "s/)//g")
                l_gid=$(echo $l_buffer |  awk '{print $NF}' | sed "s/)//g")
                l_ownergroup="" l_permissions=""

                if ! grep -Pq '[0-6]00' <<< "$l_perms"; then
                    l_permissions="failed"
                fi

                if [ "$l_uid" != "$l_uid_correct" ] || [ "$l_gid" != "$l_gid_correct" ]; then
                    l_ownergroup="failed"
                fi

                # If $l_perms does not equal "failed" and $l_uid does not equal "failed", we pass
                if [ "$l_permissions" = "failed" ] || [ "$l_ownergroup" = "failed" ]; then
                    if [ "$l_permissions" = "failed" ]; then
                    echo "- Remediating $file permissions set incorrectly to \"$l_perms\"" | tee -a "$LOG" 2>> "$ELOG"	
                    chmod $l_perms_correct $file
                    fi

                    if [ "$l_ownergroup" = "failed" ]; then
                        echo "- Remediating $file owner and group set incorrectly to \"$l_uid\" and \"$l_gid\"" | tee -a "$LOG" 2>> "$ELOG"
                        chown $l_uid_correct:$l_gid_correct $file
                    fi
                fi
            fi
        done

        echo "- End remediation - Ensure permissions on /etc/opasswd are configured" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_perms_etc_opasswd_configured_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
        if [ "$l_test" != "NA" ]; then
            ensure_perms_etc_opasswd_configured_fix
            ensure_perms_etc_opasswd_configured_chk
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