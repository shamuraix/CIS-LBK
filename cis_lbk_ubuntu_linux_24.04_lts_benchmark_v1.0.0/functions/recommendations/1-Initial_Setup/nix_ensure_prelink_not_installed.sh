#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = c0a892d6
#   function = ensure_prelink_not_installed
#   applicable =
# # END METADATA
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendation/nix_ensure_prelink_not_installed.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       10/29/20    Recommendation "Ensure prelink is not installed"
# Justin Brown       04/19/22    Updated to modern format
# David Neilson		 04/09/24	 Added command to restore binaries to normal (prelink -ua), changed some variables names to include "l_", modified code if pkg mgr not found

ensure_prelink_not_installed()
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
			G_PR="$G_PM  remove -y"
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
	
	ensure_prelink_not_installed_chk()
	{
		echo -e "- Start check - Ensure prelink is not installed" | tee -a "$LOG" 2>> "$ELOG"
		l_output=""
		
		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi
		
		if [ -z "$l_output" ]; then
			# Check if prelink is installed
			if $G_PQ prelink 2>>/dev/null; then 
				echo -e "- FAILED:\n- Prelink package found" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure prelink is installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_FAIL:-102}"
			else
				echo -e "- PASSED:\n- Prelink package is NOT installed" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure prelink is not installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			fi
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n$l_pkgmgr" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure prelink is not installed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	ensure_prelink_not_installed_fix()
	{
		echo -e "- Start remediation - Ensure prelink is not installed" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Removing prelink" | tee -a "$LOG" 2>> "$ELOG"
		prelink -ua
		$G_PR prelink
		if ! $G_PQ prelink; then
			l_test="remediated"
		fi
		echo -e "- End remediation - Ensure prelink is not installed" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_prelink_not_installed_chk
	if [ "$?" = "101" ] || [ "$l_test" = "NA" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ]; then
		l_test="manual"
	else
		ensure_prelink_not_installed_fix
		if [ "$l_test" != "manual" ]; then
			ensure_prelink_not_installed_chk
			if [ "$?" = "101" ] ; then
				[ "$l_test" != "failed" ] && l_test="remediated"
			else
				l_test="failed"
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
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}