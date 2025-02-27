#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = f07049a1
#   function = deb_ensure_libpam_modules_installed
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_libpam_modules_installed.sh
#
# Name               Date           Description
# ------------------------------------------------------------------------------------------------
# J Brown   	     03/16/24	    Recommendation "Ensure libpam-modules is installed"
#

deb_ensure_libpam_modules_installed()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test="" l_pkg=""

	nix_package_manager_set()
	{
		echo -e "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"

		if command -v rpm 2>/dev/null; then
			echo -e "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -qa"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM remove -y"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg-query -s"
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

	deb_ensure_libpam_modules_installed_chk()
	{
		echo "- Start check - Ensure libpam-modules is installed" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""

		# Check to see if libpam-modules is installed.  If not, we fail.
		if $G_PQ libpam-modules &> /dev/null; then
			l_output="$l_output\n- 'libpam-modules' package is installed"
		else
			l_output2="$l_output2\n- 'libpam-modules' package is NOT installed"
		fi

		if [ -z "$l_output2" ]; then
			echo -e "- PASSED:\n- 'libpam-modules' packages found\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure libpam-modules is installed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAILED:\n- 'libpam-modules' packages NOT found\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
				echo -e "\n- Passing values:\n$l_output"
			fi
			echo -e "- End check - Ensure libpam-modules is installed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-102}"
		fi
	}

	deb_ensure_libpam_modules_installed_fix()
	{
		echo -e "- Start remediation - Ensure libpam-modules is installed" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- Installing 'libpam-modules' package" | tee -a "$LOG" 2>> "$ELOG"
		$G_PM install -y libpam-modules

		echo -e "- End remediation - Ensure libpam-modules is installed" | tee -a "$LOG" 2>> "$ELOG"
	}

	# Set package manager information
	if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
		nix_package_manager_set
		[ $? -ne 101 ] && l_pkg="false"
	fi

	if [ "$l_pkg" != "false" ]; then
		deb_ensure_libpam_modules_installed_chk
		if [ $? -eq 101 ]; then
			[ -z "$l_test" ] && l_test="passed"
		else
			if [ "$l_test" != "NA" ]; then
				deb_ensure_libpam_modules_installed_fix
				if [ "$l_test" != "manual" ]; then
					deb_ensure_libpam_modules_installed_chk
					if [ $? -eq 101 ]; then
						[ "$l_test" != "failed" ] && l_test="remediated"
					else
						l_test="failed"
					fi
				fi
			fi
		fi
	else
		echo -e "- MANUAL:\n- Unable to determine system's package manager"  | tee -a "$LOG" 2>> "$ELOG"
		return "${XCCDF_RESULT_PASS:-106}"
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