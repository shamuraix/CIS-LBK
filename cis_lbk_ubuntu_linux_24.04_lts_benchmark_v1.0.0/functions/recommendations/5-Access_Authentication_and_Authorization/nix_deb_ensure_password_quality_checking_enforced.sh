#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 8f1ef2bf
#   function = deb_ensure_password_quality_checking_enforced
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_password_quality_checking_enforced.sh
#
# Name                  Date            Description
# ------------------------------------------------------------------------------------------------
# J Brown               03/23/24        Recommendation "Ensure password quality checking is enforced"
#

deb_ensure_password_quality_checking_enforced()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    deb_ensure_password_quality_checking_enforced_chk()
	{
        echo -e "- Start check - Ensure password quality checking is enforced" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        # Verify settings in /etc/security/pwquality.conf and /etc/security/pwquality.conf.d/*.conf
        l_pwquality_val="$(grep -PHsi -- '^\h*enforcing\h*=\h*0\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf 2>/dev/null)"

        if [ -z "$l_pwquality_val" ]; then
            l_output="$l_output\n- 'enforcing = 0' not set in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf"
        else
            l_output2="$l_output2\n- 'enforcing = 0' set in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf\n$l_pwquality_val"
        fi

        # Verify settings in /etc/pam.d/common-auth
        l_pwquality_config="$(grep -PHsi -- '^\h*password\h+[^#\n\r]+\h+pam_pwquality\.so\h+([^#\n\r]+\h+)?enforcing=0\b' /etc/pam.d/common-password)"

        if [ -z "$l_pwquality_config" ]; then
            l_output="$l_output\n- No non-compliant 'enforcing' values configured in /etc/pam.d/common-password"
        else
            l_output2="$l_output2\n- 'enforcing' value(s) NOT configured correctly in /etc/pam.d/common-password:\n$l_pwquality_config"
        fi

        if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure password quality checking is enforced" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Failing values:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            if [ -n "$l_output" ]; then
                echo -e "- Passing values:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
            fi
			echo -e "- End check - Ensure password quality checking is enforced" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    }

    deb_ensure_password_quality_checking_enforced_fix()
	{
        echo -e "- Start remediation - Ensure password quality checking is enforced" | tee -a "$LOG" 2>> "$ELOG"

        # Update the entries in /etc/security/pwquality.conf or /etc/security/pwquality.conf.d/*.conf
        if [ -n "$l_pwquality_val" ] ; then
            l_pwquality_files="$(grep -PHsi -- '^\h*enforcing\h*=\h*0\b' /etc/security/pwquality.conf /etc/security/pwquality.conf.d/*.conf | awk -F: '{ print $1 }' 2>/dev/null)"

            for l_file in $l_pwquality_files; do
                if grep -Piq -- '^\h*(#\h*)?enforcing\h*=\h*0\b' "$l_file"; then
                    echo -e "- Updating 'enforcing' value in $l_file" | tee -a "$LOG" 2>> "$ELOG"
                    sed -ri 's/^\s*(#\s*)?(enforcing\s*=)(\s*[0-9]+)(.*)?$/\2 1 \4/' "$l_file"
                else
                    if grep -Pq -- "^\h*#\h+The\h+new\h+password\h+is\h+rejected\h+if\h+it\h+fails\h+the\h+check\h+and\h+the\h+value\h+is\h+not\h+0." "$l_file"; then
                        echo -e "- Adding 'enforcing = 0' to $l_file" | tee -a "$LOG" 2>> "$ELOG"
                        sed -ri '/^\s*#\s+The\s+new\s+password\s+is\s+rejected\s+if\s+it\s+fails\s+the\s+check\s+and\s+the\s+value\s+is\s+not\s+0./a enforcing = 0' "$l_file"
                    else
                        echo -e "- Inserting 'enforcing = 0' to end of $l_file" | tee -a "$LOG" 2>> "$ELOG"
                        echo "enforcing = 0" >> "$l_file"
                    fi
                fi
            done
        fi

        # Update the entries in /usr/share/pam-configs/*
        l_config_files="$(grep -Pl -- '\bpam_pwquality\.so\h+([^#\n\r]+\h+)?enforcing=0\b' /usr/share/pam-configs/*)"
        if [ -n "$l_config_files" ]; then
            while read -r l_file; do
                echo -e "- Removing 'enforcing=0' values from $l_file" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri 's/^(.*pam_pwquality\.so)([^#]+\s*)?(enforcing\s*=\s*[0-9]+)(.*)?$/\1\2\4/' "$l_file"
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

        echo -e "- End remediation - Ensure password quality checking is enforced" | tee -a "$LOG" 2>> "$ELOG"
    }

    deb_ensure_password_quality_checking_enforced_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_password_quality_checking_enforced_fix
            if [ "$l_test" != "manual" ] ; then
                deb_ensure_password_quality_checking_enforced_chk
                if [ "$?" = "101" ] ; then
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