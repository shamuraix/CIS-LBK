#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = cc26e668
#   function = ensure_unused_filesystems_kernel_modules_not_available
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_unused_filesystems_kernel_modules_not_available.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# David Neilson      08/03/24    Recommendation "Ensure unused filesystems kernel modules are not available"

ensure_unused_filesystems_kernel_modules_not_available()
{
    echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    a_output=(); a_output2=(); a_modprope_config=(); a_excluded=(); a_available_modules=()
    a_ignore=("xfs" "vfat" "ext2" "ext3" "ext4")
    a_cve_exists=("afs" "ceph" "cifs" "exfat" "ext" "fat" "fscache" "fuse" "gfs2" "nfs_common" "nfsd" "smbfs_common")

    f_module_chk()
    {
        l_out2=""; grep -Pq -- "\b$l_mod_name\b" <<< "${a_cve_exists[*]}" && l_out2=" <- CVE exists!"
        if ! grep -Pq -- '\bblacklist\h+'"$l_mod_name"'\b' <<< "${a_modprope_config[*]}"; then
            a_output2+=("  - Kernel module: \"$l_mod_name\" is not fully disabled $l_out2")
        elif ! grep -Pq -- '\binstall\h+'"$l_mod_name"'\h+(\/usr)?\/bin\/(false|true)\b' <<< "${a_modprope_config[*]}"; then
            a_output2+=("  - Kernel module: \"$l_mod_name\" is not fully disabled $l_out2")
        fi
        if lsmod | grep "$l_mod_name" &> /dev/null; then # Check if the module is currently loaded
            a_output2+=("  - Kernel module: \"$l_mod_name\" is loaded $l_out2" "")
        fi
    }

    ensure_unused_filesystems_kernel_modules_not_available_chk()
    {
        echo -e "- Start check - Ensure unused filesystems kernel modules are not available" | tee -a "$LOG" 2>> "$ELOG"

        # Determine which modules exist on the system.
        while IFS= read -r -d $'\0' l_module_dir; do
            a_available_modules+=("$(basename "$l_module_dir")")
        done < <(find "$(readlink -f /lib/modules/"$(uname -r)"/kernel/fs)" -mindepth 1 -maxdepth 1 -type d ! -empty -print0)
        while IFS= read -r l_exclude; do
            if grep -Pq -- "\b$l_exclude\b" <<< "${a_cve_exists[*]}"; then
                a_output2+=("  - ** WARNING: kernel module: \"$l_exclude\" has a CVE and is currently mounted! **")
            elif 
                grep -Pq -- "\b$l_exclude\b" <<< "${a_available_modules[*]}"; then
                a_output+=("  - Kernel module: \"$l_exclude\" is currently mounted - do NOT unload or disable")
            fi
            ! grep -Pq -- "\b$l_exclude\b" <<< "${a_ignore[*]}" && a_ignore+=("$l_exclude")
        done < <(findmnt -knD | awk '{print $2}' | sort -u)
        while IFS= read -r l_config; do
            a_modprope_config+=("$l_config")
        done < <(modprobe --showconfig | grep -P '^\h*(blacklist|install)')
        for l_mod_name in "${a_available_modules[@]}"; do # Iterate over all filesystem modules
            [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"
            if grep -Pq -- "\b$l_mod_name\b" <<< "${a_ignore[*]}"; then
                a_excluded+=(" - Kernel module: \"$l_mod_name\"")
            else
                f_module_chk
            fi
        done

        # Report results. If no failures output in a_output2, we pass
        [ "${#a_excluded[@]}" -gt 0 ] && printf '%s\n' "" " -- INFO --" \
        "The following intentionally skipped" \
            "${a_excluded[@]}"
        if [ "${#a_output2[@]}" -le 0 ]; then
            printf '%s\n' "" "  - No unused filesystem kernel modules are enabled" "${a_output[@]}" "" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure unused filesystems kernel modules are not available" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            printf '%s\n' "" "-- Audit Result: --" "  ** REVIEW the following **" "${a_output2[@]}" | tee -a "$LOG" 2>> "$ELOG"
            [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "" "-- Correctly set: --" "${a_output[@]}" "" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure unused filesystems kernel modules are not available" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }
    
    ensure_unused_filesystems_kernel_modules_not_available_fix()
    {
        echo -e "- Start remediation - Ensure unused filesystems kernel modules are not available" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "  - Unload the filesystem kernel modules that are not needed\n  - Create the necessary file(s) ending in .conf with \"install <filesystem kernel module> /bin/false\" in /etc/modprobe.d\n  - Create the necessary file(s) ending in .conf with \"blacklist <filesystem kernel module>\" in /etc/modprobe.d" | tee -a "$LOG" 2>> "$ELOG"
        l_test="manual"

        echo -e "- End remediation - Ensure unused filesystems kernel modules are not available" | tee -a "$LOG" 2>> "$ELOG"
    }

    ensure_unused_filesystems_kernel_modules_not_available_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        ensure_unused_filesystems_kernel_modules_not_available_fix
        if [ "$l_test" != "manual" ]; then
            l_test="failed"
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
