#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = b34859ed
#   function = deb_ensure_apparmor_installed
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_apparmor_installed.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# David Neilson	     12/01/22	 Recommendation "Ensure AppArmor is installed"
# Justin Brown		 02/07/23	 Updated to include apparmor-utils
# David Neilson		 03/18/24	 Updated to work with Suse, fixed script to require manual remediation if it can't determine pkg mgr

deb_ensure_apparmor_installed()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	if grep -Pi -- 'pretty_name' /etc/os-release | grep -Piq -- 'suse'; then
		l_apparmor="suse"
		l_suse_pkgs="apparmor-docs apparmor-parser apparmor-profiles apparmor-utils libapparmor1"
	fi

	nix_package_manager_set()
	{
		echo "- Start - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
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

	deb_ensure_apparmor_installed_chk()
	{
		echo "- Start check - Ensure AppArmor is installed" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi
		
        # Check to see if aide is installed.  If not, we fail.
		if [ -z "$l_output" ]; then
			# Verify apparmor package is installed
			if [ -z "$l_apparmor" ]; then # Debian/Ubuntu system
				if $G_PQ apparmor > /dev/null 2>&1; then
					l_output="$l_output\n- Apparmor package is installed"
				else
					l_output2="$l_output2\n- Apparmor package is NOT installed"
				fi

				# Verify apparmor-utils package is installed
				if $G_PQ apparmor-utils > /dev/null 2>&1; then
					l_output="$l_output\n- Apparmor-utils package is installed"
				else
					l_output2="$l_output2\n- Apparmor-utils package is NOT installed"
				fi
			else # Suse system
				if $G_PQ $l_suse_pkgs > /dev/null 2>&1; then
					l_output="$l_output\n- Apparmor packages are installed"
				else
					l_output2="$l_output2\n- Apparmor package(s) are NOT installed"
				fi
			fi	
			
			if [ -z "$l_output2" ]; then
				echo -e "- PASSED:\n- Apparmor packages found\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure AppArmor is installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			else
				echo -e "- FAILED:\n- Apparmor packages NOT found\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
				if [ -n "$l_output" ]; then
					echo -e "\n- Passing values:\n$l_output"
				fi
				echo -e "- End check - Ensure AppArmor is installed" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-102}"
			fi
		else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_pkgmgr" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure AppArmor is installed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi	
	}
	
	deb_ensure_apparmor_installed_fix()
	{
		echo -e "- Start remediation - Ensure AppArmor is installed" | tee -a "$LOG" 2>> "$ELOG"

		if [ -z "$l_apparmor" ]; then # Debian/Ubuntu system
			if ! $G_PQ apparmor > /dev/null 2>&1; then
				echo -e "- Installing apparmor package" | tee -a "$LOG" 2>> "$ELOG"
				$G_PM install -y apparmor
			fi

			if ! $G_PQ apparmor-utils > /dev/null 2>&1; then
				echo -e "- Installing apparmor-utils package" | tee -a "$LOG" 2>> "$ELOG"
				$G_PM install -y apparmor-utils
			fi
		else # Suse system
			for l_pkg in $l_suse_pkgs; do
				if ! $G_PM $l_pkg 2> /dev/null; then
					$G_PM install -y $l_pkg
				fi
			done
		fi

		echo -e "- End remediation - Ensure AppArmor is installed" | tee -a "$LOG" 2>> "$ELOG"
	}

    deb_ensure_apparmor_installed_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
	else
		deb_ensure_apparmor_installed_fix
		deb_ensure_apparmor_installed_chk
		if [ "$?" = "101" ]; then
			[ "$l_test" != "failed" ] && l_test="remediated"
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