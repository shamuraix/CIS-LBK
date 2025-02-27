#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = a0ebcfcf
#   function = ensure_suid_sgid_files_reviewed
#   applicable =
# # END METADATA
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_suid_sgid_files_reviewed.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       08/03/22    Recommendation "Ensure SUID and SGID files are reviewed"
#

ensure_suid_sgid_files_reviewed()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    ensure_suid_sgid_files_reviewed_chk()
    {
        echo -e "- Start check - Ensure SUID and SGID files are reviewed" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""
        a_arr=(); a_suid=(); a_sgid=() # initialize arrays
        
        # Populate array with files that will possibly fail one of the audits
        while read -r l_mpname; do
            while IFS= read -r -d $'\0' l_file; do
                [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
            done < <(find "$l_mpname" -xdev -not -path "/run/user/*"  -type f \( -perm -2000 -o -perm -4000 \) -print0)
        done <<< "$(findmnt -Derno target)"
        
        # Test files in the array
        while IFS="^" read -r l_fname l_mode; do
            if [ -f "$l_fname" ]; then
                l_suid_mask="04000"; l_sgid_mask="02000"
                [ $(( $l_mode & $l_suid_mask )) -gt 0 ] && a_suid+=("$l_fname")
                [ $(( $l_mode & $l_sgid_mask )) -gt 0 ] && a_sgid+=("$l_fname")
            fi
        done <<< "$(printf '%s\n' "${a_arr[@]}")" 
        
        if ! (( ${#a_suid[@]} > 0 )); then
            l_output="$l_output\n - There are no SUID files exist on the system"
        else
            l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_suid[@]}")\" SUID executable files:\n$(printf '%s\n' "${a_suid[@]}")\n - end of list -\n"
        fi
        
        if ! (( ${#a_sgid[@]} > 0 )); then
            l_output="$l_output\n - There are no SGID files exist on the system"
        else
            l_output2="$l_output2\n - List of \"$(printf '%s' "${#a_sgid[@]}")\" SGID executable files:\n$(printf '%s\n' "${a_sgid[@]}")\n - end of list -\n"
        fi
        
        [ -n "$l_output2" ] && l_output2="$l_output2\n- Review the preceding list(s) of SUID and/or SGID files to\n- ensure that no rogue programs have been introduced onto the system.\n" 
        
        unset a_arr; unset a_suid; unset a_sgid # Remove arrays
        
        # If l_output2 is empty, we pass
        if [ -z "$l_output2" ]; then
            echo -e "\n- Audit Result: **PASS**\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure SUID and SGID files are reviewed" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- Audit Result: **FAIL**\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
            [ -n "$l_output" ] && echo -e "$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure SUID and SGID files are reviewed" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }

    ensure_suid_sgid_files_reviewed_fix()
    {
        echo -e "- Start remediation - Ensure SUID and SGID files are reviewed" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "- Review the files returned and confirm the integrity of these binaries.\n- Ensure that no rogue SUID or SGID programs have been introduced into the system." | tee -a "$LOG" 2>> "$ELOG"
        l_test=manual

        echo -e "- End remediation - Ensure SUID and SGID files are reviewed" | tee -a "$LOG" 2>> "$ELOG"
    }
	
	ensure_suid_sgid_files_reviewed_chk
    if [ "$?" = "101" ] || [ "$l_test" = "NA" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        ensure_suid_sgid_files_reviewed_fix
        if [ "$l_test" != "manual" ]; then
            ensure_suid_sgid_files_reviewed_chk
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
			echo "Recommendation \"$RNA\" Chrony is not installed on the system - Recommendation is non applicable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}