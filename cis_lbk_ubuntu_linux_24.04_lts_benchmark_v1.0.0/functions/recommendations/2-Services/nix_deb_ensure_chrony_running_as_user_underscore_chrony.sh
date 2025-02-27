#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = f6889c18
#   function = deb_ensure_chrony_running_as_user_underscore_chrony
#   applicable =
# # END METADATA
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_chrony_running_as_user_underscore_chrony.sh
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/26/22    Recommendation "Ensure chrony is running as user _chrony"
#

deb_ensure_chrony_running_as_user_underscore_chrony()
{
	nix_package_manager_set()
	{
		echo -e "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"

		if command -v rpm 2>/dev/null; then
			echo -e "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM remove -y"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM purge -y"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_chrony_running_as_user_underscore_chrony_chk()
	{
		echo -e "- Start check - Ensure chrony is running as user _chrony" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_pkgmgr=""

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

		if [ -z "$l_output" ]; then
			! $G_PQ chrony | grep -Pq "^Status:\s+install\s+ok\s+installed" > /dev/null 2>&1 && l_test="NA"

			if [ "$l_test" != "NA" ]; then
				l_output="$(ps -ef | awk '(/[c]hronyd/ && $1!="_chrony")')"

				if [ -z "$l_output" ]; then
					echo -e "\n- PASS:\n- Chrony is running as _chrony"
					echo -e "- End check - Ensure chrony is running as user _chrony" | tee -a "$LOG" 2>> "$ELOG"
					return "${XCCDF_RESULT_PASS:-101}"
				else
					echo -e "\n- FAIL:\n$l_output\n"
					echo -e "- End check - Ensure chrony is running as user _chrony" | tee -a "$LOG" 2>> "$ELOG"
					return "${XCCDF_RESULT_PASS:-102}"
				fi
			fi
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure chrony is running as user _chrony" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	deb_ensure_chrony_running_as_user_underscore_chrony_fix()
	{
		echo -e "- Start remediation - Ensure chrony is running as user _chrony" | tee -a "$LOG" 2>> "$ELOG"
		l_fafile=""
		l_searchloc="/etc/chrony/chrony.conf /etc/chrony/conf.d/*.conf"

		# comment out incorrect user entries in config file(s)
		l_fafile="$(grep -Pls -- "^\s*user" $l_searchloc)"

		if [ -n "$l_fafile" ]; then
			echo -e "- Comment out incorrect user entries in config file(s)" | tee -a "$LOG" 2>> "$ELOG"
			for l_file in $l_fafile; do
				echo -e "- Commenting out \"user\" in \"$l_file\"" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri "/^\s*user\s/s/^/# /" "$l_file"
			done

			# Set correct parameter in a kernel parameter file
			if ! grep -Pslq -- "^\h*user\h+_chrony" $l_searchloc; then
				echo -e "- Setting \"user\" to \"_chrony\" in \"/etc/chrony/chrony.conf\"" | tee -a "$LOG" 2>> "$ELOG"
				echo "user _chrony" >> /etc/chrony/chrony.conf
			fi

			# restart chrony
			echo -e "- Restarting chrony" | tee -a "$LOG" 2>> "$ELOG"
			systemctl restart chrony
		fi

		echo -e "- End remediation - Ensure chrony is running as user _chrony" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_chrony_running_as_user_underscore_chrony_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
    elif [ "$l_test" = "NA" ]; then
        l_test="NA"
	else
		deb_ensure_chrony_running_as_user_underscore_chrony_fix
		deb_ensure_chrony_running_as_user_underscore_chrony_chk
		if [ "$?" = "101" ] ; then
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