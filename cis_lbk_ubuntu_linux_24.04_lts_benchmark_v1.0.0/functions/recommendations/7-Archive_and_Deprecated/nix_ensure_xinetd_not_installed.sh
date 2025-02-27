#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 17599d5d
#   function = ensure_xinetd_not_installed
#   applicable =
# # END METADATA
#
#
# CIS-LBK Deprecated Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_xinetd_not_installed.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/17/20    Recommendation "Ensure xinetd is not installed"
# Justin Brown       10/25/22    Updated to modern format
# David Neilson		 10/25/23	 Changed "$G_PM -y remove" to "$G_PM remove -y" in nix_package_manager_set(), removed references to telnet server and rpcbind, and added code to deal with how "dpkg -s" writes to STDERR
# J Brown			 04/19/24	 This script will be deprecated and replaced by 'nix_ensure_xinetd_services_not_in_use.sh'
#

ensure_xinetd_not_installed()
{
	# Start recommendation entry for verbose log and output to screen
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

    ensure_xinetd_not_installed_chk()
	{
		l_output=""
		l_pkgmgr=""

		# Checks to see if cups is installed
		echo "- Start check - Ensure xinetd is not installed" | tee -a "$LOG" 2>> "$ELOG"

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

		# Check to see if xinetd is installed.  If not, we pass.
		if [ -z "$l_output" ]; then
			if $G_PQ xinetd | grep "not installed" > /dev/null; then
				echo -e "- PASSED:\n- xinetd not installed" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure xinetd is not installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			# dpkg -s will write "not installed" to STDERR, not STDOUT, if a package is not installed
			elif echo $G_PQ | grep -Piq -- 'dpkg' && $G_PQ xinetd 2>&1 > /dev/null | grep "not installed" > /dev/null; then
				echo -e "- PASSED:\n- xinetd not installed" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure xinetd is not installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			elif ! systemctl is-enabled xinetd.service 2>/dev/null | grep 'enabled' && ! systemctl is-active xinetd.service 2>/dev/null | grep '^active'; then
				echo -e "- PASSED:\n- xinetd is not running or enabled" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure xinetd is not installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			else
				echo -e "- FAILED:\n- xinetd is installed on the system" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check -Ensure xinetd is not installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-102}"
			fi
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	ensure_xinetd_not_installed_fix()
	{
		echo "- Start remediation - Ensure xinetd is not installed" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- Stopping service" | tee -a "$LOG" 2>> "$ELOG"
		systemctl stop xinetd.service
		echo -e "- Removing package" | tee -a "$LOG" 2>> "$ELOG"
		$G_PR xinetd

		echo "- End remediation - Ensure xinetd is not installed" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_xinetd_not_installed_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
	else
		ensure_xinetd_not_installed_fix
		ensure_xinetd_not_installed_chk
		if [ "$?" = "101" ] ; then
			[ "$l_test" != "failed" ] && l_test="remediated"
		else
			l_test="failed"
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