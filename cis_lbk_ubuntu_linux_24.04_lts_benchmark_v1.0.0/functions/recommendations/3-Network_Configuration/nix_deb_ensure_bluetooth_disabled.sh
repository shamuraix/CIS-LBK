#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 25c13877
#   function = deb_ensure_bluetooth_disabled
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_bluetooth_disabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       07/03/23    Recommendation "Ensure bluetooth is disabled"
# 

deb_ensure_bluetooth_disabled()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	
	deb_ensure_bluetooth_disabled_chk()
	{
		l_output="" l_output2=""

		echo "- Start check - Ensure bluetooth is disabled" | tee -a "$LOG" 2>> "$ELOG"
		
		if systemctl is-enabled bluetooth.service | grep '^enabled'; then
            l_output2="$l_output2\n- \"bluetooth.service\" appears to be enabled"
        else
            l_output="$l_output\n- \"bluetooth.service\" does NOT appear to be enabled"
        fi

        if systemctl is-active bluetooth.service | grep '^active'; then
            l_output2="$l_output2\n- \"bluetooth.service\" appears to be active"
        else
            l_output="$l_output\n- \"bluetooth.service\" does NOT appear to be active"
        fi
		
		if [ -z "$l_output2" ]; then 
			echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :\n$l_output\n"
			echo -e "- End check - Ensure bluetooth is disabled" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-101}"
		else
			echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n"
            [ -n "$l_output" ] && echo -e "- * Correctly configured * :\n$l_output\n"
			echo -e "- End check - Ensure bluetooth is disabled" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi

	}

	deb_ensure_bluetooth_disabled_fix()
	{
		echo -e "- Start remediation - Ensure bluetooth is disabled" | tee -a "$LOG" 2>> "$ELOG"

		if systemctl is-active bluetooth.service | grep '^active'; then
            echo -e "- Stopping bluetooth.service" | tee -a "$LOG" 2>> "$ELOG"
		    systemctl stop bluetooth.service
        fi

        if systemctl is-enabled bluetooth.service | grep '^enabled'; then
            echo -e "- Masking bluetooth.service" | tee -a "$LOG" 2>> "$ELOG"
		    systemctl mask bluetooth.service
        fi

		echo -e "- End remediation - Ensure bluetooth is disabled" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_bluetooth_disabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		deb_ensure_bluetooth_disabled_fix
		if [ "$l_test" != "manual" ]; then
			deb_ensure_bluetooth_disabled_chk
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