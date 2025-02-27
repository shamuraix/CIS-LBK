#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 9671f616
#   function = ensure_local_interactive_user_home_dir_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_local_interactive_user_home_dir_configured.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       07/01/23    Recommendation "Ensure local interactive user home directories are configured"
#

ensure_local_interactive_user_home_dir_configured()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    ensure_local_interactive_user_home_dir_configured_chk()
    {
        echo -e "- Start check - Ensure local interactive user home directories are configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2="" l_heout2="" l_hoout2="" l_haout2=""
        l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"

        unset a_uarr && a_uarr=() # Clear and initialize array

        while read -r l_epu l_eph; do # Populate array with users and user home location
            a_uarr+=("$l_epu $l_eph")
        done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)"

        l_asize="${#a_uarr[@]}" # Here if we want to look at number of users before proceeding 
        [ "$l_asize " -gt "10000" ] && echo -e "\n  ** INFO **\n  - \"$l_asize\" Local interactive users found on the system\n  - This may be a long running check\n"

        while read -r l_user l_home; do
            if [ -d "$l_home" ]; then
                l_mask='0027'
                l_max="$( printf '%o' $(( 0777 & ~$l_mask)) )"
                while read -r l_own l_mode; do
                    [ "$l_user" != "$l_own" ] && l_hoout2="$l_hoout2\n  - User: \"$l_user\" Home \"$l_home\" is owned by: \"$l_own\""
                    if [ $(( $l_mode & $l_mask )) -gt 0 ]; then
                    l_haout2="$l_haout2\n  - User: \"$l_user\" Home \"$l_home\" is mode: \"$l_mode\" should be mode: \"$l_max\" or more restrictive"
                    fi
                done <<< "$(stat -Lc '%U %#a' "$l_home")"
            else
                l_heout2="$l_heout2\n  - User: \"$l_user\" Home \"$l_home\" Doesn't exist"
            fi
        done <<< "$(printf '%s\n' "${a_uarr[@]}")"

        [ -z "$l_heout2" ] && l_output="$l_output\n   - home directories exist" || l_output2="$l_output2$l_heout2"
        [ -z "$l_hoout2" ] && l_output="$l_output\n   - own their home directory" || l_output2="$l_output2$l_hoout2"
        [ -z "$l_haout2" ] && l_output="$l_output\n   - home directories are mode: \"$l_max\" or more restrictive" || l_output2="$l_output2$l_haout2"
        [ -n "$l_output" ] && l_output="  - All local interactive users:$l_output"

        if [ -z "$l_output2" ]; then # If l_output2 is empty, we pass
            echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :\n$l_output"
            echo -e "- End check - Ensure local interactive user home directories are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2"
            [ -n "$l_output" ] && echo -e "\n- * Correctly configured * :\n$l_output"
            echo -e "- End check - Ensure local interactive user home directories are configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-102}"
        fi
    }

    ensure_local_interactive_user_home_dir_configured_fix()
    {
        echo -e "- Start remediation - Ensure local interactive user home directories are configured" | tee -a "$LOG" 2>> "$ELOG"

        l_output2=""
        l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"

        unset a_uarr && a_uarr=() # Clear and initialize array

        while read -r l_epu l_eph; do # Populate array with users and user home location
            a_uarr+=("$l_epu $l_eph")
        done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)"

        l_asize="${#a_uarr[@]}" # Here if we want to look at number of users before proceeding 
        [ "$l_asize " -gt "10000" ] && echo -e "\n  ** INFO **\n  - \"$l_asize\" Local interactive users found on the system\n  - This may be a long running process\n"

        while read -r l_user l_home; do
            if [ -d "$l_home" ]; then
                l_mask='0027'
                l_max="$( printf '%o' $(( 0777 & ~$l_mask)) )"
                while read -r l_own l_mode; do
                    if [ "$l_user" != "$l_own" ]; then
                    l_output2="$l_output2\n  - User: \"$l_user\" Home \"$l_home\" is owned by: \"$l_own\"\n  -  changing ownership to: \"$l_user\"\n"
                    chown "$l_user" "$l_home"
                    fi
                    if [ $(( $l_mode & $l_mask )) -gt 0 ]; then
                    l_output2="$l_output2\n  - User: \"$l_user\" Home \"$l_home\" is mode: \"$l_mode\" should be mode: \"$l_max\" or more restrictive\n  -  removing excess permissions\n"
                    chmod g-w,o-rwx "$l_home"
                    fi
                done <<< "$(stat -Lc '%U %#a' "$l_home")"
            else
                l_output2="$l_output2\n  - User: \"$l_user\" Home \"$l_home\" Doesn't exist\n  -  Please create a home in accordance with local site policy"
                l_test="manual"
            fi
        done <<< "$(printf '%s\n' "${a_uarr[@]}")"

        if [ -z "$l_output2" ]; then # If l_output2 is empty, we pass
            echo -e " - No modification needed to local interactive users home directories"
        else
            echo -e "\n$l_output2"
        fi

        echo -e "- End remediation - Ensure local interactive user home directories are configured" | tee -a "$LOG" 2>> "$ELOG"
    }

	ensure_local_interactive_user_home_dir_configured_chk
    if [ "$?" = "101" ] || [ "$l_test" = "NA" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        ensure_local_interactive_user_home_dir_configured_fix
        if [ "$l_test" != "manual" ]; then
            ensure_local_interactive_user_home_dir_configured_chk
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