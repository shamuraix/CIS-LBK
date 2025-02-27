#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = c8600657
#   function = deb_ensure_web_server_not_in_use
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
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_web_server_not_in_use.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus         11/23/22    Recommendation "Ensure web server services are not in use"
# 

deb_ensure_web_server_not_in_use()
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

	deb_ensure_web_server_not_in_use_chk()
	{
		l_output=""
		l_pkgmgr=""

		echo -e "- Start check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

		# Check to see if web server services are installed.  If not, we pass.
		if [ -z "$l_output" ]; then
			case "$G_PQ" in
				*rpm*)
					if [ -z "$l_flavor" ]; then
						if $G_PQ httpd | grep "not installed" && $G_PQ nginx | grep "not installed"; then
							echo -e "- PASSED:\n- Web server packages not found" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						elif ! systemctl is-enabled httpd.socket httpd.service nginx.service 2>/dev/null | grep 'enabled' && ! systemctl is-active httpd.socket httpd.service nginx.service 2>/dev/null | grep '^active'; then
							echo -e "- PASSED:\n- Web server services are not running or enabled" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						else
							echo -e "- FAILED:\n- Web server packages installed on the system" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-102}"
						fi
					else
						if $G_PQ apache2 | grep "not installed"; then
							echo -e "- PASSED:\n- Web server packages not found" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						elif ! systemctl is-enabled apache2.service 2>/dev/null | grep 'enabled' && ! systemctl is-active apache2.service 2>/dev/null | grep '^active'; then
							echo -e "- PASSED:\n- Web server services are not running or enabled" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-101}"
						else
							echo -e "- FAILED:\n- Web server packages installed on the system" | tee -a "$LOG" 2>> "$ELOG"
							echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
							return "${XCCDF_RESULT_PASS:-102}"
						fi
					fi
				;;
				*dpkg*)
					if  $G_PQ apache2 2>/dev/null| grep "not installed" && $G_PQ nginx 2>/dev/null| grep "not installed"; then
						echo -e "- PASSED:\n- Web server packages not found" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-101}"
					elif ! systemctl is-enabled apache2.socket apache2.service nginx.service 2>/dev/null | grep 'enabled' && ! systemctl is-active apache2.socket apache2.service nginx.service 2>/dev/null | grep '^active'; then
						echo -e "- PASSED:\n- Web server services are not running or enabled" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-101}"
					else
						echo -e "- FAILED:\n- Web server packages installed on the system" | tee -a "$LOG" 2>> "$ELOG"
						echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
						return "${XCCDF_RESULT_PASS:-102}"
					fi
				;;
			esac
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	deb_ensure_web_server_not_in_use_fix()
	{
		echo -e "- Start remediation - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"

		case "$G_PQ" in 
			*rpm*)
				if [ -z "$l_flavor" ]; then
					echo -e "- Stopping service" | tee -a "$LOG" 2>> "$ELOG"
					systemctl stop httpd.socket httpd.service nginx.service
					echo -e "- Removing package" | tee -a "$LOG" 2>> "$ELOG"
					$G_PR httpd nginx
				else
					echo -e "- Stopping service" | tee -a "$LOG" 2>> "$ELOG"
					systemctl stop apache2.service
					echo -e "- Removing package" | tee -a "$LOG" 2>> "$ELOG"
					$G_PR apache2
				fi
			;;
			*dpkg*)
				echo -e "- Stopping and masking web server services" | tee -a "$LOG" 2>> "$ELOG"
				systemctl stop apache2.socket apache2.service nginx.service 2>/dev/null
				systemctl mask apache2.socket apache2.service nginx.service 2>/dev/null
			;;
		esac

		echo -e "- End remediation - Ensure web server services are not in use" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_web_server_not_in_use_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
	else
		deb_ensure_web_server_not_in_use_fix
		deb_ensure_web_server_not_in_use_chk
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