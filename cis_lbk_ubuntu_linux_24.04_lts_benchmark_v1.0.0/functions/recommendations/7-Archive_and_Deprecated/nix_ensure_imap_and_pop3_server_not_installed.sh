#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 74fd6c97
#   function = ensure_imap_and_pop3_server_not_installed
#   applicable =
# # END METADATA
#
#
# CIS-LBK Deprecated Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_imap_and_pop3_server_not_installed.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/23/22    Recommendation "Ensure IMAP and POP3 server are not installed"
# David Neilson		 03/01/24	 Determines the package to remove based on whether the system is Suse or not.  Changed "$G_PM -y remove" to "$G_PM remove -y"
# J Brown			 04/05/24	 This script will be deprecated and replaced by 'nix_ensure_message_access_server_services_not_in_use.sh'
#

ensure_imap_and_pop3_server_not_installed()
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
	if grep -Pi -- 'pretty_name' /etc/os-release | grep -Piq -- 'suse'; then
		l_flavor="suse"
	fi

	ensure_imap_and_pop3_server_not_installed_chk()
	{
		l_output=""
		l_pkgmgr=""

		echo -e "- Start check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

		# Check to see if dovecot and cyrus-imapd are installed.  If not, we pass.
		if [ -z "$l_output" ]; then
			case "$G_PQ" in
				*rpm*)
					if [ -z "$l_flavor" ]; then
						if $G_PQ dovecot | grep "not installed" && $G_PQ cyrus-imapd | grep "not installed"; then
							echo -e "- PASSED:\n- dovecot and cyrus-imapd packages not found" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						elif ! systemctl is-enabled dovecot.socket dovecot.service cyrus-imapd.service 2>/dev/null | grep 'enabled' && ! systemctl is-active dovecot.socket dovecot.service cyrus-imapd.service 2>/dev/null | grep '^active'; then
							echo -e "- PASSED:\n- dovecot and cyrus-imapd services are not running or enabled" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						else
							echo -e "- FAILED:\n- dovecot and cyrus-imapd packages installed on the system" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-102}"
						fi
					else
						if $G_PQ dovecot | grep "not installed"; then
							echo -e "- PASSED:\n- dovecot package not found" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						elif ! systemctl is-enabled dovecot.socket dovecot.service 2>/dev/null | grep 'enabled' && ! systemctl is-active dovecot.socket dovecot.service 2>/dev/null | grep '^active'; then
							echo -e "- PASSED:\n- dovecot service is not running or enabled" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						else
							echo -e "- FAILED:\n- dovecot package installed on the system" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-102}"
						fi
					fi
				;;
				*dpkg*)
					if $G_PQ dovecot-imapd || $G_PQ dovecot-pop3d; then
						# If packages are not installed, this command returns a "1", which means we go to the else clause and the test passes
						echo -e "- FAILED:\n- dovecot-imapd and dovecot-pop3d package installed on the system" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-102}"
					else
						echo -e "- PASSED:\n- dovecot-imapd and dovecot-pop3d package not installed" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-101}"
					fi
				;;
			esac
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	ensure_imap_and_pop3_server_not_installed_fix()
	{
		echo -e "- Start remediation - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"

		case "$G_PQ" in
			*rpm*)
				if [ -z "$l_flavor" ]; then
					echo -e "- Stopping services" | tee -a "$LOG" 2>> "$ELOG"
					systemctl stop dovecot.socket dovecot.service cyrus-imapd.service
					echo -e "- Removing package" | tee -a "$LOG" 2>> "$ELOG"
					$G_PR dovecot cyrus-imapd
				else
					echo -e "- Stopping services" | tee -a "$LOG" 2>> "$ELOG"
					systemctl stop dovecot.socket dovecot.service
					echo -e "- Removing package" | tee -a "$LOG" 2>> "$ELOG"
					$G_PR dovecot
				fi
			;;
			*dpkg*)
				echo -e "- Removing package" | tee -a "$LOG" 2>> "$ELOG"
				$G_PR dovecot-imapd dovecot-pop3d
			;;
		esac

		echo -e "- End remediation - Ensure IMAP and POP3 server are not installed" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_imap_and_pop3_server_not_installed_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
	else
		ensure_imap_and_pop3_server_not_installed_fix
		ensure_imap_and_pop3_server_not_installed_chk
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