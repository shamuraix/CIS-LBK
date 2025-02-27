#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = d1ce5f1c
#   function = ensure_local_interactive_user_dot_files_access_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_local_interactive_user_dot_files_access_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       07/01/23    Recommendation "Ensure local interactive user dot files access is configured"
#

ensure_local_interactive_user_dot_files_access_configured()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
    l_test=""

    ensure_local_interactive_user_dot_files_access_configured_chk()
    {
        echo -e "- Start check - Ensure local interactive user dot files access is configured" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2="" l_output3="" l_bf="" l_df="" l_nf="" l_hf=""
        unset a_uarr && a_uarr=() # Clear and initialize array

        l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"
        
        while read -r l_epu l_eph; do # Populate array with users and user home location
            [[ -n "$l_epu" && -n "$l_eph" ]] && a_uarr+=("$l_epu $l_eph")
        done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)"
        
        l_asize="${#a_uarr[@]}" # Here if we want to look at number of users before proceeding 
        l_maxsize="1000" # Maximun number of local interactive users before warning (Default 1,000)
        [ "$l_asize " -gt "$l_maxsize" ] && echo -e "\n  ** INFO **\n  - \"$l_asize\" Local interactive users found on the system\n  - This may be a long running check\n"
        
        file_access_chk()
        {
            l_facout2=""
            l_max="$( printf '%o' $(( 0777 & ~$l_mask)) )"
            if [ $(( $l_mode & $l_mask )) -gt 0 ]; then
                l_facout2="$l_facout2\n  - File: \"$l_hdfile\" is mode: \"$l_mode\" and should be mode: \"$l_max\" or more restrictive"
            fi
            if [[ ! "$l_owner" =~ ($l_user) ]]; then
                l_facout2="$l_facout2\n  - File: \"$l_hdfile\" owned by: \"$l_owner\" and should be owned by \"${l_user//|/ or }\""
            fi
            if [[ ! "$l_gowner" =~ ($l_group) ]]; then
                l_facout2="$l_facout2\n  - File: \"$l_hdfile\" group owned by: \"$l_gowner\" and should be group owned by \"${l_group//|/ or }\""
            fi
        }

        while read -r l_user l_home; do
            l_fe="" l_nout2="" l_nout3="" l_dfout2="" l_hdout2="" l_bhout2=""
            if [ -d "$l_home" ]; then
                l_group="$(id -gn "$l_user" | xargs)"
                l_group="${l_group// /|}"
                while IFS= read -r -d $'\0' l_hdfile; do
                    while read -r l_mode l_owner l_gowner; do
                    case "$(basename "$l_hdfile")" in
                        .forward | .rhost )
                            l_fe="Y" && l_bf="Y"
                            l_dfout2="$l_dfout2\n  - File: \"$l_hdfile\" exists" ;;
                        .netrc )
                            l_mask='0177'
                            file_access_chk
                            if [ -n "$l_facout2" ]; then
                                l_fe="Y" && l_nf="Y"
                                l_nout2="$l_facout2"
                            else
                                l_nout3="   - File: \"$l_hdfile\" exists"
                            fi ;;
                        .bash_history )
                            l_mask='0177'
                            file_access_chk
                            if [ -n "$l_facout2" ]; then
                                l_fe="Y" && l_hf="Y"
                                l_bhout2="$l_facout2"
                            fi ;;
                        * )
                            l_mask='0133'
                            file_access_chk
                            if [ -n "$l_facout2" ]; then
                                l_fe="Y" && l_df="Y"
                                l_hdout2="$l_facout2"
                            fi ;;
                        esac
                    done <<< "$(stat -Lc '%#a %U %G' "$l_hdfile")"
                done < <(find "$l_home" -xdev -type f -name '.*' -print0)
            fi
            if [ "$l_fe" = "Y" ]; then
                l_output2="$l_output2\n - User: \"$l_user\" Home Directory: \"$l_home\""
                [ -n "$l_dfout2" ] && l_output2="$l_output2$l_dfout2"
                [ -n "$l_nout2" ] && l_output2="$l_output2$l_nout2"
                [ -n "$l_bhout2" ] && l_output2="$l_output2$l_bhout2"
                [ -n "$l_hdout2" ] && l_output2="$l_output2$l_hdout2"
            fi
            [ -n "$l_nout3" ] && l_output3="$l_output3\n  - User: \"$l_user\" Home Directory: \"$l_home\"\n$l_nout3"
        done <<< "$(printf '%s\n' "${a_uarr[@]}")"

        unset a_uarr # Remove array
        
        [ -n "$l_output3" ] && l_output3=" - ** Warning **\n - \".netrc\" files should be removed unless deemed necessary\n   and in accordance with local site policy:$l_output3"
        [ -z "$l_bf" ] && l_output="$l_output\n   - \".forward\" or \".rhost\" files"
        [ -z "$l_nf" ] && l_output="$l_output\n   - \".netrc\" files with incorrect access configured"
        [ -z "$l_hf" ] && l_output="$l_output\n   - \".bash_history\" files with incorrect access configured"
        [ -z "$l_df" ] && l_output="$l_output\n   - \"dot\" files with incorrect access configured"
        [ -n "$l_output" ] && l_output="  - No local interactive users home directories contain:$l_output"
        
        if [ -z "$l_output2" ]; then # If l_output2 is empty, we pass
            echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :\n$l_output\n"
            echo -e "$l_output3\n"
            echo -e "- End check - Ensure local interactive user dot files access is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
        else
            echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n"
            echo -e "$l_output3\n"
            [ -n "$l_output" ] && echo -e "- * Correctly configured * :\n$l_output\n"
            echo -e "- End check - Ensure local interactive user dot files access is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-102}"
        fi
    }

    ensure_local_interactive_user_dot_files_access_configured_fix()
    {
        echo -e "- Start remediation - Ensure local interactive user dot files access is configured" | tee -a "$LOG" 2>> "$ELOG"

        l_valid_shells="^($( awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"
        
        unset a_uarr && a_uarr=() # Clear and initialize array
        
        while read -r l_epu l_eph; do # Populate array with users and user home location
            [[ -n "$l_epu" && -n "$l_eph" ]] && a_uarr+=("$l_epu $l_eph")
        done <<< "$(awk -v pat="$l_valid_shells" -F: '$(NF) ~ pat { print $1 " " $(NF-1) }' /etc/passwd)"
        
        l_asize="${#a_uarr[@]}" # Here if we want to look at number of users before proceeding 
        l_maxsize="1000" # Maximum number of local interactive users before warning (Default 1,000)
        [ "$l_asize " -gt "$l_maxsize" ] && echo -e "\n  ** INFO **\n  - \"$l_asize\" Local interactive users found on the system\n  - This may be a long running check\n"
        
        file_access_fix()
        {
            l_facout2=""
            l_max="$( printf '%o' $(( 0777 & ~$l_mask)) )"
            if [ $(( $l_mode & $l_mask )) -gt 0 ]; then
                echo -e "  - File: \"$l_hdfile\" is mode: \"$l_mode\" and should be mode: \"$l_max\" or more restrictive\n   - Changing to mode \"$l_max\""
                chmod "$l_chp" "$l_hdfile"
            fi
            if [[ ! "$l_owner" =~ ($l_user) ]]; then
                echo -e "  - File: \"$l_hdfile\" owned by: \"$l_owner\" and should be owned by \"${l_user//|/ or }\"\n   - Changing ownership to \"$l_user\""
                chown "$l_user" "$l_hdfile"
            fi
            if [[ ! "$l_gowner" =~ ($l_group) ]]; then
                echo -e "  - File: \"$l_hdfile\" group owned by: \"$l_gowner\" and should be group owned by \"${l_group//|/ or }\"\n   - Changing group ownership to \"$l_group\""
                chgrp "$l_group" "$l_hdfile"
            fi
        }

        while read -r l_user l_home; do
            if [ -d "$l_home" ]; then
                echo -e "\n - Checking user: \"$l_user\" home directory: \"$l_home\""
                l_group="$(id -gn "$l_user" | xargs)"
                l_group="${l_group// /|}"
                while IFS= read -r -d $'\0' l_hdfile; do
                    while read -r l_mode l_owner l_gowner; do
                    case "$(basename "$l_hdfile")" in
                        .forward | .rhost )
                            echo -e "  - File: \"$l_hdfile\" exists\n   - Please investigate and manually delete \"$l_hdfile\""
                            l_test="manual"
                        ;;
                        .netrc )
                            l_mask='0177'
                            l_chp="u-x,go-rwx"
                            file_access_fix ;;
                        .bash_history )
                            l_mask='0177'
                            l_chp="u-x,go-rwx"
                            file_access_fix ;;
                        * )
                            l_mask='0133'
                            l_chp="u-x,go-wx"
                            file_access_fix ;;
                        esac
                    done <<< "$(stat -Lc '%#a %U %G' "$l_hdfile")"
                done < <(find "$l_home" -xdev -type f -name '.*' -print0)
            fi
        done <<< "$(printf '%s\n' "${a_uarr[@]}")"
        
        unset a_uarr # Remove array

        echo -e "- End remediation - Ensure local interactive user dot files access is configured" | tee -a "$LOG" 2>> "$ELOG"
    }
	
	ensure_local_interactive_user_dot_files_access_configured_chk
    if [ "$?" = "101" ] || [ "$l_test" = "NA" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        ensure_local_interactive_user_dot_files_access_configured_fix
        if [ "$l_test" != "manual" ]; then
            ensure_local_interactive_user_dot_files_access_configured_chk
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