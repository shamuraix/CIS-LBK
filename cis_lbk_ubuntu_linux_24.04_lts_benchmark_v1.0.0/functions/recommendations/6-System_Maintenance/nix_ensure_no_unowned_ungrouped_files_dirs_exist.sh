#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 31f419c2
#   function = ensure_no_unowned_ungrouped_files_dirs_exist
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_no_unowned_ungrouped_files_dirs_exist.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       07/01/23    Recommendation "Ensure no unowned or ungrouped files or directories exist"
#

ensure_no_unowned_ungrouped_files_dirs_exist()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    ensure_no_unowned_ungrouped_files_dirs_exist_chk()
    {
        echo -e "- Start check - Ensure no unowned or ungrouped files or directories exist" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""
        a_path=(); a_arr=(); a_nouser=(); a_nogroup=() # Initialize arrays
        
        a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*")
        
        while read -r l_bfs; do
            a_path+=( -a ! -path ""$l_bfs"/*")
        done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/ {print $2}')
        
        while IFS= read -r -d $'\0' l_file; do
            [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%U^%G' "$l_file")") && echo "Adding: $l_file"
        done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) \( -nouser -o -nogroup \) -print0 2> /dev/null)
        
        while IFS="^" read -r l_fname l_user l_group; do # Test files in the array
            [ "$l_user" = "UNKNOWN" ] && a_nouser+=("$l_fname")
            [ "$l_group" = "UNKNOWN" ] && a_nogroup+=("$l_fname")
        done <<< "$(printf '%s\n' "${a_arr[@]}")"
        
        if ! (( ${#a_nouser[@]} > 0 )); then
            l_output="$l_output\n  - No unowned files or directories exist on the local filesystem."
        else
            l_output2="$l_output2\n  - There are \"$(printf '%s' "${#a_nouser[@]}")\" unowned files or directories on the system.\n   - The following is a list of unowned files and/or directories:\n$(printf '%s\n' "${a_nouser[@]}")\n   - end of list"
        fi
        
        if ! (( ${#a_nogroup[@]} > 0 )); then
            l_output="$l_output\n  - No ungrouped files or directories exist on the local filesystem."
        else
            l_output2="$l_output2\n  - There are \"$(printf '%s' "${#a_nogroup[@]}")\" ungrouped files or directories on the system.\n   - The following is a list of ungrouped files and/or directories:\n$(printf '%s\n' "${a_nogroup[@]}")\n   - end of list"
        fi 
        
        unset a_path; unset a_arr ; unset a_nouser; unset a_nogroup # Remove arrays
        
        if [ -z "$l_output2" ]; then # If l_output2 is empty, we pass
            echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure no unowned or ungrouped files or directories exist" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            [ -n "$l_output" ] && echo -e "\n- * Correctly configured * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure no unowned or ungrouped files or directories exist" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }

    ensure_no_unowned_ungrouped_files_dirs_exist_fix()
    {
        echo -e "- Start remediation - Ensure no unowned or ungrouped files or directories exist" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "- Remove or set ownership and group ownership of these files and/or directories to an active user on the system as appropriate.." | tee -a "$LOG" 2>> "$ELOG"
        l_test=manual

        echo -e "- End remediation - Ensure no unowned or ungrouped files or directories exist" | tee -a "$LOG" 2>> "$ELOG"
    }
	
	ensure_no_unowned_ungrouped_files_dirs_exist_chk
    if [ "$?" = "101" ] || [ "$l_test" = "NA" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        ensure_no_unowned_ungrouped_files_dirs_exist_fix
        if [ "$l_test" != "manual" ]; then
            ensure_no_unowned_ungrouped_files_dirs_exist_chk
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