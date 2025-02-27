#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 2b8409e5
#   function = deb_ensure_pam_unix_includes_strong_password_hashing_algorithm
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_pam_unix_includes_strong_password_hashing_algorithm.sh
#
# Name                Date          Description
# ------------------------------------------------------------------------------------------------
# J Brown             12/31/22      Recommendation "Ensure pam_unix does not include remember"
#

deb_ensure_pam_unix_includes_strong_password_hashing_algorithm()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_pam_unix_includes_strong_password_hashing_algorithm_chk()
	{
		echo -e "- Start check - Ensure pam_unix includes a strong password hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""

		# Verify common-password
		if grep -Pqs -- '^\h*password\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?(sha512|yescrypt)\b' /etc/pam.d/common-password; then
			l_output="$l_output\n- /etc/pam.d/common-password contains:\n  $(grep -Ps -- '^\h*password\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?(sha512|yescrypt)\b' /etc/pam.d/common-password)"
		else
			l_output2="$l_output2\n- /etc/pam.d/common-password DOES NOT include 'sha512' or 'yescrypt'"
		fi

		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure pam_unix includes a strong password hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing Values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
				echo -e "- Passing Values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure pam_unix includes a strong password hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	deb_ensure_pam_unix_includes_strong_password_hashing_algorithm_fix()
	{
		echo -e "- Start remediation - Ensure pam_unix includes a strong password hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "- Review the conig files in /usr/share/pam-configs/* or the location of your custom PAM profiles\n- Edit or add a strong hashing algorithm, either sha512 or yescrypt, that meets local site policy to the pam_unix lines in the Password section(s)" | tee -a "$LOG" 2>> "$ELOG"
        echo -e "- Run the following command to update the files in the /etc/pam.d/ directory:\n  # pam-auth-update --enable <MODIFIED_PROFILE_NAME>" | tee -a "$LOG" 2>> "$ELOG"
        l_test="manual"

		echo -e "- End remediation - Ensure pam_unix includes a strong password hashing algorithm" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_pam_unix_includes_strong_password_hashing_algorithm_chk
	if [ $? -eq 101 ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		if [ "$l_test" != "NA" ]; then
			deb_ensure_pam_unix_includes_strong_password_hashing_algorithm_fix
			if [ "$l_test" != "manual" ]; then
				deb_ensure_pam_unix_includes_strong_password_hashing_algorithm_chk
				if [ $? -eq 101 ]; then
					[ "$l_test" != "failed" ] && l_test="remediated"
				else
					l_test="failed"
				fi
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