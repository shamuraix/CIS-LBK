#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 54b68a8e
#   function = deb_ensure_password_hash_algorithm_up_to_date
#   applicable =
# # END METADATA
#
#
# CIS-LBK Deprecated Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_hash_algorithm_up_to_date.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/31/22    Recommendation "Ensure password hashing algorithm is up to date with the latest standards"
#

deb_ensure_password_hash_algorithm_up_to_date()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_password_hash_algorithm_up_to_date_chk()
	{
        echo -e "- Start check - Ensure password hashing algorithm is up to date with the latest standards" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        if grep -v '^#' /etc/pam.d/common-password | grep -Pqs '(yescrypt|md5|bigcrypt|sha256|sha512|blowfish)'; then
            l_output2="- Password hash value set in /etc/pam.d/common-password:\n  $(grep -v '^#' /etc/pam.d/common-password | grep -P '(yescrypt|md5|bigcrypt|sha256|sha512|blowfish)')"
        else
            l_output="- Password hash value is NOT set in /etc/pam.d/common-password"
        fi

        if grep -Pqi "^\h*ENCRYPT_METHOD\h*(yescrypt|sha512)\h*$" /etc/login.defs; then
            l_output="- Password hash value set correctly in /etc/login.defs"
        else
            l_output2="- Password hash value is NOT set correctly in /etc/login.defs"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password hashing algorithm is up to date with the latest standards" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure password hashing algorithm is up to date with the latest standards" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }

    deb_ensure_password_hash_algorithm_up_to_date_fix()
	{
        echo -e "- Start remediation - Ensure password hashing algorithm is up to date with the latest standards" | tee -a "$LOG" 2>> "$ELOG"

        if grep -v '^#' /etc/pam.d/common-password | grep -Pqs '(yescrypt|md5|bigcrypt|sha256|sha512|blowfish)'; then
            echo -e "- Removing hash value from /etc/pam.d/common-password" | tee -a "$LOG" 2>> "$ELOG"
			sed -ri 's/^\s*(#\s*)?(password\s+)(.*)?(yescrypt|md5|bigcrypt|sha256|sha512|blowfish)(.*)?$/\1\2\3\5/' /etc/pam.d/common-password
        fi

		if grep -Pqs '^\h*ENCRYPT_METHOD\h*' /etc/login.defs; then
            echo -e "- Updating 'ENCRYPT_METHOD' value in /etc/login.defs" | tee -a "$LOG" 2>> "$ELOG"
			sed -ri 's/^\s*(#\s*)?(ENCRYPT_METHOD\s*)(\S+)(.*)?$/\2yescrypt \4/' /etc/login.defs
		else
            echo -e "- Adding 'ENCRYPT_METHOD' to /etc/login.defs" | tee -a "$LOG" 2>> "$ELOG"
            sed -ri '/^#\s*the\s*PAM\s*modules\s*configuration\./a ENCRYPT_METHOD yescrypt' /etc/login.defs
		fi

        echo -e "- End remediation - Ensure password hashing algorithm is up to date with the latest standards" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_password_hash_algorithm_up_to_date_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_password_hash_algorithm_up_to_date_fix
            deb_ensure_password_hash_algorithm_up_to_date_chk
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