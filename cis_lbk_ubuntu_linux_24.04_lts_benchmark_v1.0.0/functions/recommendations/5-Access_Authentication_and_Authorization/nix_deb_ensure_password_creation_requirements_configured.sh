#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = a37e995e
#   function = deb_ensure_password_creation_requirements_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_creation_requirements_configured.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/31/22    Recommendation "Ensure password creation requirements are configured"
#

deb_ensure_password_creation_requirements_configured()
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

	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_password_creation_requirements_configured_chk()
	{
        echo -e "- Start check - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2="" l_testpkg="" l_test1="" l_test2="" l_test3=""

        # Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi

		# Check to see if libpam-pwquality is installed.  If not, we fail.
		case "$G_PQ" in
			*dpkg*)
				if $G_PQ libpam-pwquality; then
	                l_output="$l_output\n- libpam-pwquality package was found"
					l_testpkg=passed
				else
					l_output2="$l_output2\n- libpam-pwquality package was NOT found"
				fi
			;;
		esac

        # Check password length
        if grep -Eqs '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Correct password length setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,})\b' /etc/security/pwquality.conf)"
            l_test1=passed
        elif grep -Eqs '^\s*(#\s*)?minlen\s*=' /etc/security/pwquality.conf; then
            l_output2="$l_output2\n- Incorrect password length setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*(#\s*)?minlen\s*=' /etc/security/pwquality.conf)"
        else
            l_output2="$l_output2\n- No minlen setting found in /etc/security/pwquality.conf"
        fi

        # Check password complexity
        if grep -Eqs '^\s*minclass\s*=\s*4\b' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Correct minclass setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*minclass\s*=\s*4\b' /etc/security/pwquality.conf)"
            l_test2=passed
		elif grep -Eqs '^\s*dcredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf && grep -Eqs '^\s*ucredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf && grep -Eqs '^\s*ocredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf && grep -Eqs '^\s*lcredit\s*=\s*-[1-9]\b' /etc/security/pwquality.conf; then
            l_output="$l_output\n- Correct dcredit, ucredit, ocredit and lcredit settings found in /etc/security/pwquality.conf:\n$( grep -Es '^\s*[duol]credit\s*=' /etc/security/pwquality.conf)"
            l_test2=passed
        elif grep -Eqs '^\s*(#\s*)?minclass\s*=' /etc/security/pwquality.conf; then
            l_output2="$l_output2\n- Incorrect minclass setting found in /etc/security/pwquality.conf: $(grep -Es '^\s*(#\s*)?minclass\s*=' /etc/security/pwquality.conf)"
        elif grep -Eqs '^\s*(#\s*)?dcredit\s*=' /etc/security/pwquality.conf || grep -Eqs '^\s*(#\s*)?ucredit\s*=' /etc/security/pwquality.conf && grep -Eqs '^\s*(#\s*)?ocredit\s*=' /etc/security/pwquality.conf || grep -Eqs '^\s*(#\s*)?lcredit\s*=' /etc/security/pwquality.conf; then
            l_output2="$l_output2\n- Incorrect dcredit, ucredit, ocredit and lcredit settings found in /etc/security/pwquality.conf:\n$( grep -Es '^\s*(#\s*)?[duol]credit\s*=' /etc/security/pwquality.conf)"
		else
            l_output2="$l_output2\n- No minclass, dcredit, ucredit, ocredit or lcredit settings found in /etc/security/pwquality.conf"
        fi

		# Check /etc/pam.d/common-password entry
		if grep -Eqs '^\s*password\s+requisite\s+pam_pwquality.so' /etc/pam.d/common-password; then
			l_output="$l_output\n- Correct pam_pwquality.so setting found in /etc/pam.d/common-password: $(grep -Es '^\s*password\s+requisite\s+pam_pwquality.so' /etc/security/pwquality.conf)"
			l_test3=passed
		else
            l_output2="$l_output2\n- No pam_pwquality.so settings found in /etc/pam.d/common-password"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing Values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
				echo -e "- Passing Values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }

    deb_ensure_password_creation_requirements_configured_fix()
	{
        echo -e "- Start remediation - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"

        if [ "$l_testpkg" != "passed" ]; then
            $G_PM install -y libpam-pwquality
            echo -e "- Installing libpam-pwquality package" | tee -a "$LOG" 2>> "$ELOG"
        fi

        if [ "$l_test1" != "passed" ]; then
            if grep -Eqs '^\s*(#\s*)?minlen\s*=' /etc/security/pwquality.conf; then
                echo -e "- Updating minlen entry in /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^\s*(#\s*)?(minlen\s*=)(\s*\S+\s*)(\s+#.*)?$/\2 14\4/' /etc/security/pwquality.conf
            else
                echo -e "- Adding minlen entry to /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                echo "minlen = 14" >> /etc/security/pwquality.conf
            fi
        fi

        if [ "$l_test2" != "passed" ]; then
            if grep -Eqs '^\s*(#\s*)?minclass\s*=' /etc/security/pwquality.conf; then
                echo -e "- Updating minclass entry in /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^\s*(#\s*)?(minclass\s*=)(\s*\S+\s*)(\s+#.*)?$/\2 4\4/' /etc/security/pwquality.conf
            else
                echo -e "- Adding minclass entry to /etc/security/pwquality.conf" | tee -a "$LOG" 2>> "$ELOG"
                echo "minclass = 4" >> /etc/security/pwquality.conf
            fi
        fi

		if [ "$l_test3" != "passed" ]; then
			if grep -Eqs '^\s*#\s+here\s+are\s+the\s+per-package\s+modules' /etc/pam.d/common-password; then
				echo -e "- Adding 'password requisite pam_pwquality.so retry=3' to /etc/pam.d/common-password" | tee -a "$LOG" 2>> "$ELOG"
				sed -ri "/^\s*#\s+here\s+are\s+the\s+per-package\s+modules/a password        requisite                       pam_pwquality.so retry=3" /etc/pam.d/common-password
			else
				echo -e "- Could not safely insert 'password requisite pam_pwquality.so retry=3' into /etc/pam.d/common-password\n- This entry should be manually configured" | tee -a "$LOG" 2>> "$ELOG"
                l_test="manual"
			fi
        fi

        echo -e "- End remediation - Ensure password creation requirements are configured" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_password_creation_requirements_configured_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
		deb_ensure_password_creation_requirements_configured_fix
		if [ "$l_test" != "manual" ] ; then
			deb_ensure_password_creation_requirements_configured_chk
			if [ "$?" = "101" ]; then
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