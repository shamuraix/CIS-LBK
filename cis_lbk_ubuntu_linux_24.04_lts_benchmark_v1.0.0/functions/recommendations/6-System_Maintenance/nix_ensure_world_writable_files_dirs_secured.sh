#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 77543a21
#   function = ensure_world_writable_files_dirs_secured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_world_writable_files_dirs_secured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       08/03/22    Recommendation "Ensure world writable files and directories are secured"
#

ensure_world_writable_files_dirs_secured()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    ensure_world_writable_files_dirs_secured_chk()
    {
        echo -e "- Start check - Ensure world writable files and directories are secured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""
        l_smask='01000'
        
        a_path=(); a_arr=(); a_file=(); a_dir=() # Initialize arrays
        
        a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "/sys/kernel/security/apparmor/*" -a ! -path "/snap/*" -a ! -path "/sys/fs/cgroup/memory/*")
        
        while read -r l_bfs; do
            a_path+=( -a ! -path ""$l_bfs"/*")
        done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/ {print $2}')
        
        # Populate array with files that will possibly fail one of the audits
        while IFS= read -r -d $'\0' l_file; do
            [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
        done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)
        
        while IFS="^" read -r l_fname l_mode; do # Test files in the array
            [ -f "$l_fname" ] && a_file+=("$l_fname") # Add WR files
            if [ -d "$l_fname" ]; then # Add directories w/o sticky bit
                [ ! $(( $l_mode & $l_smask )) -gt 0 ] && a_dir+=("$l_fname")
            fi
        done < <(printf '%s\n' "${a_arr[@]}")
        
        if ! (( ${#a_file[@]} > 0 )); then
            l_output="$l_output\n  - No world writable files exist on the local filesystem."
        else
            l_output2="$l_output2\n - There are \"$(printf '%s' "${#a_file[@]}")\" World writable files on the system.\n   - The following is a list of World writable files:\n$(printf '%s\n' "${a_file[@]}")\n   - end of list\n"
        fi
        
        if ! (( ${#a_dir[@]} > 0 )); then
            l_output="$l_output\n  - Sticky bit is set on world writable directories on the local filesystem."
        else
            l_output2="$l_output2\n - There are \"$(printf '%s' "${#a_dir[@]}")\" World writable directories without the sticky bit on the system.\n   - The following is a list of World writable directories without the sticky bit:\n$(printf '%s\n' "${a_dir[@]}")\n   - end of list\n"
        fi
        
        unset a_path; unset a_arr; unset a_file; unset a_dir # Remove arrays
        
        # If l_output2 is empty, we pass
        if [ -z "$l_output2" ]; then
            echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure world writable files and directories are secured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
            [ -n "$l_output" ] && echo -e "- * Correctly configured * :\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure world writable files and directories are secured" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }

    ensure_world_writable_files_dirs_secured_fix()
    {
        echo -e "- Start remediation - Ensure world writable files and directories are secured" | tee -a "$LOG" 2>> "$ELOG"

        l_smask='01000'
        a_path=(); a_arr=() # Initialize array
        
        a_path=(! -path "/run/user/*" -a ! -path "/proc/*" -a ! -path "*/containerd/*" -a ! -path "*/kubelet/pods/*" -a ! -path "/sys/kernel/security/apparmor/*" -a ! -path "/snap/*" -a ! -path "/sys/fs/cgroup/memory/*")
        
        while read -r l_bfs; do
            a_path+=( -a ! -path ""$l_bfs"/*")
        done < <(findmnt -Dkerno fstype,target | awk '$1 ~ /^\s*(nfs|proc|smb)/ {print $2}')
        
        # Populate array with files
        while IFS= read -r -d $'\0' l_file; do
            [ -e "$l_file" ] && a_arr+=("$(stat -Lc '%n^%#a' "$l_file")")
        done < <(find / \( "${a_path[@]}" \) \( -type f -o -type d \) -perm -0002 -print0 2>/dev/null)
        
        while IFS="^" read -r l_fname l_mode; do # Test files in the array
            if [ -f "$l_fname" ]; then # Remove excess permissions from WW files
                echo -e " - File: \"$l_fname\" is mode: \"$l_mode\"\n  - removing write permission on \"$l_fname\" from \"other\"" | tee -a "$LOG" 2>> "$ELOG"
                chmod o-w "$l_fname"
            fi
            if [ -d "$l_fname" ]; then
                if [ ! $(( $l_mode & $l_smask )) -gt 0 ]; then # Add sticky bit
                    echo -e " - Directory: \"$l_fname\" is mode: \"$l_mode\" and doesn't have the sticky bit set\n  - Adding the sticky bit" | tee -a "$LOG" 2>> "$ELOG"
                    chmod a+t "$l_fname"
                fi
            fi
        done < <(printf '%s\n' "${a_arr[@]}")
        
        unset a_path; unset a_arr # Remove array

        echo -e "- End remediation - Ensure world writable files and directories are secured" | tee -a "$LOG" 2>> "$ELOG"
    }
	
	ensure_world_writable_files_dirs_secured_chk
    if [ "$?" = "101" ] || [ "$l_test" = "NA" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        ensure_world_writable_files_dirs_secured_fix
        if [ "$l_test" != "manual" ]; then
            ensure_world_writable_files_dirs_secured_chk
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