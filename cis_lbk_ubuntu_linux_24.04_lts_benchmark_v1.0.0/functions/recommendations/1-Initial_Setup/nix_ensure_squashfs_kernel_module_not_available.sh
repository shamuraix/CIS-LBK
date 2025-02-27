#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 9aceee1a
#   function = ensure_squashfs_kernel_module_not_available
#   applicable =
# # END METADATA
#
#
#
#
# CIS-LBK _Main Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_squashfs_kernel_module_not_available.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       07/20/22    Recommendation "Ensure squashfs kernel module is not available"
# Justin Brown       06/21/23    Update to add type support
# David Neilson      09/30/23    Changed "install " to "install\h+", and set l_test="remediated" if second run of ensure_squash_filesystem_disabled_chk succeeds.
# David Neilson      07/27/24    Updated to latest benchmark.

ensure_squashfs_kernel_module_not_available()
{
    echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_mod_name="squashfs" # set module name
    l_mod_type="fs" # set module type
    l_mod_path="$(readlink -f /lib/modules/**/kernel/$l_mod_type | sort -u)"

    f_module_chk()
    {
        l_dl="y" # Set to ignore duplicate checks
        a_showconfig=() # Create array with modprobe output
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_name//-/_}"'\b')
        if ! lsmod | grep -P -- "$l_mod_name\b" &> /dev/null; then # Check if the module is currently loaded
            a_output+=("  - kernel module: \"$l_mod_name\" is not loaded")
        else
            a_output2+=("  - kernel module: \"$l_mod_name\" is loaded")
        fi
        if grep -Pq -- '\binstall\h+'"${l_mod_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output+=("  - kernel module: \"$l_mod_name\" is not loadable")
        else
            a_output2+=("  - kernel module: \"$l_mod_name\" is loadable")
        fi
        if grep -Pq -- '\bblacklist\h+'"${l_mod_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output+=("  - kernel module: \"$l_mod_name\" is deny listed")
        else
            a_output2+=("  - kernel module: \"$l_mod_name\" is not deny listed")
        fi
    }

    f_module_fix()
    {
        l_dl="y" # Set to ignore duplicate checks
        a_showconfig=() # Create array with modprobe output
        while IFS= read -r l_showconfig; do
            a_showconfig+=("$l_showconfig")
        done < <(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+'"${l_mod_name//-/_}"'\b')
        if  lsmod | grep -P -- "$l_mod_name\b" &> /dev/null; then # Check if the module is currently loaded
            a_output2+=(" - unloading kernel module: \"$l_mod_name\"")
            modprobe -r "$l_mod_name" 2>/dev/null; rmmod "$l_mod_name" 2>/dev/null
        fi
        if ! grep -Pq -- '\binstall\h+'"${l_mod_name//-/_}"'\h+(\/usr)?\/bin\/(true|false)\b' <<< "${a_showconfig[*]}"; then
            a_output2+=(" - setting kernel  module: \"$l_mod_name\" to \"$(readlink -f /bin/false)\"")
            printf '%s\n' "install $l_mod_name $(readlink -f /bin/false)" >> /etc/modprobe.d/"$l_mod_name".conf
        fi
        if ! grep -Pq -- '\bblacklist\h+'"${l_mod_name//-/_}"'\b' <<< "${a_showconfig[*]}"; then
            a_output2+=(" - denylisting kernel module: \"$l_mod_name\"")
            printf '%s\n' "blacklist $l_mod_name" >> /etc/modprobe.d/"$l_mod_name".conf
        fi
    }

    ensure_squashfs_kernel_module_not_available_chk()
    {
        echo -e "- Start check - Ensure $l_mod_name kernel module is not available" | tee -a "$LOG" 2>> "$ELOG"

        # initialize arrays & clear variables
        a_output=(); a_output2=(); a_output3=(); l_dl="" 

        # Check if the module exists on the system
        for l_mod_base_directory in $l_mod_path; do 
            if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}")" ]; then
                a_output3+=("  - \"$l_mod_base_directory\"")
                [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"        
                [ "$l_dl" != "y" ] && f_module_chk
            else
                a_output+=(" - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"")
            fi
        done

        # Report results. If no failures output in a_output2, we pass
        [ "${#a_output3[@]}" -gt 0 ] && printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}" | tee -a "$LOG" 2>> "$ELOG"
        if [ "${#a_output2[@]}" -le 0 ]; then
            printf '%s\n' "" "- Audit Result:" "  ** PASS **" "${a_output[@]}" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure $l_mod_name kernel module is not available" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        else
            printf '%s\n' "" "- Audit Result:" "  ** FAIL **" " - Reason(s) for audit failure:" "${a_output2[@]}" | tee -a "$LOG" 2>> "$ELOG"
            [ "${#a_output[@]}" -gt 0 ] && printf '%s\n' "- Correctly set:" "${a_output[@]}"
            echo -e "- End check - Ensure $l_mod_name kernel module is not available" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_FAIL:-102}"
        fi
    }
    
    ensure_squashfs_kernel_module_not_available_fix()
    {
        echo -e "- Start remediation - Ensure $l_mod_name kernel module is not available" | tee -a "$LOG" 2>> "$ELOG"

        # initialize array and clear variables
        a_output2=(); a_output3=(); l_dl="" 

        for l_mod_base_directory in $l_mod_path; do # Check if the module exists on the system
            if [ -d "$l_mod_base_directory/${l_mod_name/-/\/}" ] && [ -n "$(ls -A "$l_mod_base_directory/${l_mod_name/-/\/}")" ]; then
                a_output3+=("  - \"$l_mod_base_directory\"")
                [[ "$l_mod_name" =~ overlay ]] && l_mod_name="${l_mod_name::-2}"        
                [ "$l_dl" != "y" ] && f_module_fix
            else
                printf '%s\n' " - kernel module: \"$l_mod_name\" doesn't exist in \"$l_mod_base_directory\"" | tee -a "$LOG" 2>> "$ELOG"
            fi
        done

        [ "${#a_output3[@]}" -gt 0 ] && printf '%s\n' "" " -- INFO --" " - module: \"$l_mod_name\" exists in:" "${a_output3[@]}" | tee -a "$LOG" 2>> "$ELOG"
        [ "${#a_output2[@]}" -gt 0 ] && printf '%s\n' "" "${a_output2[@]}" || printf '%s\n' "" " - No changes needed" | tee -a "$LOG" 2>> "$ELOG"
        printf '%s\n' "" " - remediation of kernel module: \"$l_mod_name\" complete" "" | tee -a "$LOG" 2>> "$ELOG"

        echo -e "- End remediation - Ensure $l_mod_name kernel module is not available" | tee -a "$LOG" 2>> "$ELOG"
    }

    ensure_squashfs_kernel_module_not_available_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        ensure_squashfs_kernel_module_not_available_fix
        if [ "$l_test" != "manual" ]; then
            ensure_squashfs_kernel_module_not_available_chk
        if [ "$?" = "101" ] ; then
                [ "$l_test" != "failed" ] && l_test="remediated"
            else
                l_test="failed"
            fi
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
