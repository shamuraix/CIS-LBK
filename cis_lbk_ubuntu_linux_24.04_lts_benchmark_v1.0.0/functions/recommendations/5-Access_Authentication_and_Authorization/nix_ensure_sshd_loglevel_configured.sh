#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 61871078
#   function = ensure_sshd_loglevel_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_sshd_loglevel_configured.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/05/23    Recommendation "Ensure sshd LogLevel is configured"
#

ensure_sshd_loglevel_configured()
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

   	ensure_sshd_loglevel_configured_chk()
	{
        echo -e "- Start check - Ensure sshd LogLevel is configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        l_loglevel="$(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep loglevel)"

        if sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Eq 'loglevel\s(VERBOSE|INFO)'; then
            l_output="$l_output\n- Correct LogLevel entry found in sshd -T -C output:\n$l_loglevel"
        else
            if [ -n "$l_loglevel" ]; then
                l_output2="$l_output2\n- Incorrect LogLevel entry found in sshd -T -C output:\n$l_loglevel"
            else
                l_output2="$l_output2\n- No LogLevel entry found in sshd -T -C output"
            fi
        fi

        if grep -Piq '^\h*LogLevel\s(QUIET|FATAL|ERROR|DEBUG|DEBUG1|DEBUG2|DEBUG3)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
            l_output2="$l_output2\n- Incorrect LogLevel entry found in sshd_config:\n$(grep -Pi '^\s*LogLevel\s+' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)"
        elif grep -Piq '^\h*LogLevel\s(VERBOSE|INFO)\b' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
            l_output="$l_output\n- Entry found in sshd_config:\n$(grep -Pi '^\s*LogLevel\s+' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null)"
        else
            l_output2="$l_output2\n- NO entry found in sshd_config for LogLevel"
        fi

        if [ -z "$l_output2" ]; then
            echo -e "\n- Audit Result:\n  *** PASS ***\n- * Correctly set * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure sshd LogLevel is configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
            [ -n "$l_output" ] && echo -e " - * Correctly set * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure sshd LogLevel is configured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
   	}

   	ensure_sshd_loglevel_configured_fix()
	{
        echo -e "- Start remediation - Ensure sshd LogLevel is configured" | tee -a "$LOG" 2>> "$ELOG"

		if grep -Piq '^\h*LogLevel\s+' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
            echo -e "- Commenting LogLevel entries in /etc/ssh/sshd_config.d/*.conf files" | tee -a "$LOG" 2>> "$ELOG"
            find /etc/ssh/sshd_config.d/ -type f -name "*.conf" -exec sed -ri 's/^\s*(LogLevel\s+.*)$/# \1 # Commented out by CIS Build Kit remediation/g' {} \;
            echo -e "- Commenting LogLevel entries in /etc/ssh/sshd_config file" | tee -a "$LOG" 2>> "$ELOG"
            sed -ri 's/^\s*(LogLevel\s+.*)$/# \1 # Commented out by CIS Build Kit remediation/g' /etc/ssh/sshd_config
        fi

		if grep -Piq '^\h*Include\s+' /etc/ssh/sshd_config; then
            echo -e "- Adding LogLevel entry in /etc/ssh/sshd_config" | tee -a "$LOG" 2>> "$ELOG"
            sed -ri '0,/^\s*Include\s+/s/^\s*Include\s+/LogLevel VERBOSE # Added by CIS Build Kit remediation\n&/' /etc/ssh/sshd_config
        else
            echo -e "- Adding LogLevel entry to /etc/ssh/sshd_config" | tee -a "$LOG" 2>> "$ELOG"
            sed -E -i '/^\s*\#\s*Logging/a LogLevel VERBOSE # Added by CIS Build Kit remediation/' /etc/ssh/sshd_config
        fi

        echo -e "- End remediation - Ensure sshd LogLevel is configured" | tee -a "$LOG" 2>> "$ELOG"
   	}

    # Check is package manager is defined
	if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
		nix_package_manager_set
		[ "$?" = "102" ] && l_test="manual"
	fi

	# Check is openssh-server is installed
	if ! $G_PQ openssh-server >/dev/null; then
		l_test="NA"
	else
        ensure_sshd_loglevel_configured_chk
        if [ "$?" = "101" ]; then
            [ -z "$l_test" ] && l_test="passed"
        else
            if [ "$l_test" != "NA" ]; then
                ensure_sshd_loglevel_configured_fix
                ensure_sshd_loglevel_configured_chk
                if [ "$?" = "101" ]; then
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