#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = b3f25691
#   function = deb_ensure_at_restricted_authorized_users
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_at_restricted_authorized_users.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/12/22    Recommendation "Ensure at is restricted to authorized users"
#

deb_ensure_at_restricted_authorized_users()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	
	test=""

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
	
	deb_ensure_at_restricted_authorized_users_chk()
	{
		l_output=""	l_fperm="" l_fog="" l_test1="" l_test2="" l_test3=""
		
		# Checks for restrictions
		echo -e "- Start check - Ensure at is restricted to authorized users" | tee -a "$LOG" 2>> "$ELOG"
	
		if [ ! -f /etc/at.deny ]; then
			l_output="- /etc/at.deny does NOT exist" && l_test1="pass"
		else
			l_output="- /etc/at.deny does exist"
		fi
		
		if [ -f /etc/at.allow ]; then
			l_fperm="$(stat -Lc "%a" /etc/at.allow)"
			l_fog="$(stat -Lc "%U %G" /etc/at.allow)"
			grep -Pq -- '^\h*[0-6][0-4]0\h*$' <<< "$l_fperm" && l_test2="pass"
			grep -Pq -- '^\h*root\h+root\h*$' <<< "$l_fog" && l_test3="pass"
			l_output="$l_output\n- /etc/at.allow is mode: \"$l_fperm\" and has owner and group of: \"$l_fog\""
		else
			l_output="$l_output\n- /etc/at.allow doesn't exist"
		fi
		
		if [ "$l_test1" = "pass" ] && [ "$l_test2" = "pass" ] && [ "$l_test3" = "pass" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure at is restricted to authorized users." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure at is restricted to authorized users." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	deb_ensure_at_restricted_authorized_users_fix()
	{
		echo -e "- Start remediation - Ensure at is restricted to authorized users." | tee -a "$LOG" 2>> "$ELOG"
		
		if [ -f /etc/at.deny ]; then
			echo -e "- Removing /etc/at.deny" | tee -a "$LOG" 2>> "$ELOG"
			rm -f /etc/at.deny
		fi
		
		if [ ! -f /etc/at.allow ]; then
			echo -e "- Creating /etc/at.allow" | tee -a "$LOG" 2>> "$ELOG"
			touch /etc/at.allow
		fi
		
		if [ -f /etc/at.allow ]; then
			if ! stat -Lc "%a" /etc/at.allow | grep -Pq -- '^\h*[0-6][0-4]0\h*$'; then
				echo -e "- Removing excess permissions from /etc/at.allow" | tee -a "$LOG" 2>> "$ELOG"
				chmod u-x,g-wx,o-rwx /etc/at.allow
			fi
			if ! stat -Lc "%U %G" /etc/at.allow | grep -Pq -- '^\h*root\h+root\h*$'; then
				echo -e "- Setting ownership on /etc/at.allow" | tee -a "$LOG" 2>> "$ELOG"
				chown root:root /etc/at.allow
			fi
		fi
		echo -e "- End remediation - Ensure at is restricted to authorized users." | tee -a "$LOG" 2>> "$ELOG"
	}


	# Check is package manager is defined
	if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
		nix_package_manager_set
		[ "$?" = "102" ] && test="manual"
	fi

	# Check is cronie is installed
	if ! $G_PQ cronie >/dev/null && ! $G_PQ cron >/dev/null; then
		test="NA"
	else
		deb_ensure_at_restricted_authorized_users_chk
		if [ "$?" = "101" ]; then
			[ -z "$test" ] && test="passed"
		else
			deb_ensure_at_restricted_authorized_users_fix
			deb_ensure_at_restricted_authorized_users_chk
			if [ "$?" = "101" ]; then
				[ "$test" != "failed" ] && test="remediated"
			fi
		fi
	fi
	
	# Set return code, end recommendation entry in verbose log, and return
	case "$test" in
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