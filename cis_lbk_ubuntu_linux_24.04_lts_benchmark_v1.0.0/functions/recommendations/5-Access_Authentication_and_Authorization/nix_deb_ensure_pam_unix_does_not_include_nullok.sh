#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 5a813fb3
#   function = deb_ensure_pam_unix_does_not_include_nullok
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_pam_unix_does_not_include_nullok.sh
#
# Name                Date          Description
# ------------------------------------------------------------------------------------------------
# J Brown             12/31/22      Recommendation "Ensure pam_unix does not include nullok"
#

deb_ensure_pam_unix_does_not_include_nullok()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_pam_unix_does_not_include_nullok_chk()
	{
		echo -e "- Start check - Ensure pam_unix does not include nullok" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""

		# Verify common-account
		if grep -Pqs -- '^\h*account\s+([^#\r\n]+)?\h+pam_unix\.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-account; then
			l_output2="$l_output2\n- /etc/pam.d/common-account contains:\n  $(grep -Ps -- '^\h*account\s+([^#\r\n]+)?\h+pam_unix\.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-account)"
		else
			l_output="$l_output\n- /etc/pam.d/common-account DOES NOT include 'nullok'"
		fi

		# Verify common-session
		if grep -Pqs -- '^\h*session\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-session; then
			l_output2="$l_output2\n- /etc/pam.d/common-session contains:\n  $(grep -Ps -- '^\h*session\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-session)"
		else
			l_output="$l_output\n- /etc/pam.d/common-session DOES NOT include 'nullok'"
		fi

		# Verify common-auth
		if grep -Pqs -- '^\h*auth\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-auth; then
			l_output2="$l_output2\n- /etc/pam.d/common-auth contains:\n  $(grep -Ps -- '^\h*auth\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-auth)"
		else
			l_output="$l_output\n- /etc/pam.d/common-auth DOES NOT include 'nullok'"
		fi

		# Verify common-password
		if grep -Pqs -- '^\h*password\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-password; then
			l_output2="$l_output2\n- /etc/pam.d/common-password contains:\n  $(grep -Ps -- '^\h*password\h+([^#\r\n]+)?\h+pam_unix.so([^#\r\n]+)?nullok\b' /etc/pam.d/common-password)"
		else
			l_output="$l_output\n- /etc/pam.d/common-password DOES NOT include 'nullok'"
		fi

		if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure pam_unix does not include nullok" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing Values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			if [ -n "$l_output" ]; then
				echo -e "- Passing Values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			fi
			echo -e "- End check - Ensure pam_unix does not include nullok" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	deb_ensure_pam_unix_does_not_include_nullok_fix()
	{
		echo -e "- Start remediation - Ensure pam_unix does not include nullok" | tee -a "$LOG" 2>> "$ELOG"

		# Update the entries in /usr/share/pam-configs/*
        l_config_files="$(grep -Pl -- '\bpam_unix\.so\h+([^#\n\r]+\h+)?nullok\b' /usr/share/pam-configs/*)"
        if [ -n "$l_config_files" ]; then
            while read -r l_file; do
                echo -e "- Removing 'nullok' values from $l_file" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^(.*pam_unix\.so)([^#]+\s*)?(nullok)(.*)?$/\1\2\4/g' "$l_file"
            done <<< "$l_config_files"

            # run pam-auth-update
            echo -e "- Running 'pam-auth-update'" | tee -a "$LOG" 2>> "$ELOG"
            l_pam_auth_update="$(timeout 5s pam-auth-update --package 2>&1)"

            # Verify that command ran successfully
            if [ $? -ne 124 ]; then
                if grep -Pqs -- '\h+not\h+updating\b' <<< "$l_pam_auth_update"; then
                    echo -e "- 'pam-auth-update' did NOT complete successfully\n- Verify that no manual changes were made to the files in /etc/pam.d" | tee -a "$LOG" 2>> "$ELOG"
                    l_test="manual"
                else
                    echo -e "- 'pam-auth-update' command ran successfully" | tee -a "$LOG" 2>> "$ELOG"
                fi
            else
                # Resetting terminal
                reset &> /dev/null
                echo -e "- 'pam-auth-update' command hung during execution and was killed\n- Verify that no manual changes were made to the files in /etc/pam.d" | tee -a "$LOG" 2>> "$ELOG"
                l_test="manual"
            fi
        fi

		echo -e "- End remediation - Ensure pam_unix does not include nullok" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_pam_unix_does_not_include_nullok_chk
	if [ $? -eq 101 ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		if [ "$l_test" != "NA" ]; then
			deb_ensure_pam_unix_does_not_include_nullok_fix
			if [ "$l_test" != "manual" ]; then
				deb_ensure_pam_unix_does_not_include_nullok_chk
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