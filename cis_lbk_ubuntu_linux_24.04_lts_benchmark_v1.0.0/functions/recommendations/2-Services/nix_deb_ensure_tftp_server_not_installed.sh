#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = b03f2b27
#   function = deb_ensure_tftp_server_not_installed
#   applicable =
# # END METADATA
#
#
# 
#
#
#
#
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_tftp_server_not_installed.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus          03/13/24    Recommendation "Ensure tftp server services are not in use"
#

deb_ensure_tftp_server_not_installed()
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
			G_PR="$G_PM -y remove"
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

	deb_ensure_tftp_server_not_installed_chk()
	{
		l_output=""
		l_pkgmgr=""

		echo -e "- Start check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

		# Check to see if the package installed.  If not, we pass.
		if [ -z "$l_output" ]; then
			case "$G_PQ" in
				*rpm*)
					if $G_PQ tftp-server | grep "not installed" ; then
						echo -e "- PASSED:\n- tftp-server package not installed" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-101}"
					elif ! systemctl is-enabled tftp.socket tftp.service 2>/dev/null | grep 'enabled' && ! systemctl is-active tftp.socket tftp.service 2>/dev/null | grep '^active'; then
						echo -e "- PASSED:\n- tftp services are not running or enabled" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-101}"
					else
						echo -e "- FAILED:\n- tftp-server package installed on the system" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-102}"
					fi
				;;
				*dpkg*)
					if ! $G_PQ tftpd-hpa &>/dev/null ; then
						echo -e "- PASSED:\n- tftpd-hpa package is not installed" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-101}"
					elif systemctl is-enabled tftpd-hpa.service 2>/dev/null | grep -Pq -- 'masked'  && systemctl is-active tftpd-hpa.service | grep -Pq -- '^inactive'  2>/dev/null; then
						echo -e "- PASSED:\n- tftpd-hpa.service is masked and inactive" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-101}"
					else
						echo -e "- FAILED:\n- A tftp server package is installed and enabled on the system" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-102}"
					fi
				;;
			esac
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	deb_ensure_tftp_server_not_installed_fix()
	{
		echo -e "- Start remediation - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"

		case "$G_PQ" in 
			*rpm*)
				echo -e "- Stopping service" | tee -a "$LOG" 2>> "$ELOG"
				systemctl stop tftp.socket tftp.service
				echo -e "- Removing package" | tee -a "$LOG" 2>> "$ELOG"
				$G_PR tftp-server
			;;
			*dpkg*)
				echo -e "- Stopping and masking tftpd-hpa.service" | tee -a "$LOG" 2>> "$ELOG"
				systemctl stop tftpd-hpa.service 2>/dev/null
				systemctl mask tftpd-hpa.service 2>/dev/null
			;;
		esac

		echo -e "- End remediation - Ensure tftp server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_tftp_server_not_installed_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
	else
		deb_ensure_tftp_server_not_installed_fix
		deb_ensure_tftp_server_not_installed_chk
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