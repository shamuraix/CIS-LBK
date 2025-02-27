#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = fec42df7
#   function = ensure_root_path_integrity
#   applicable =
# # END METADATA
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/nix_ensure_root_path_integrity.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Patrick Araya      09/25/20    Recommendation "Ensure root PATH Integrity"
# Justin Brown		 04/25/22    Update to modern format
# Justin Brown			09/08/22		Small syntax changes
# Randie Bejar       11/21/23    Updated to new version

ensure_root_path_integrity()
{
	# Checks root PATH integrity
	echo -e "- Start check - Ensure root PATH Integrity" | tee -a "$LOG" 2>> "$ELOG"
	
	ensure_root_path_integrity_chk()
	{
		l_output2=""
		l_pmask="0022"
		l_maxperm="$( printf '%o' $(( 0777 & ~$l_pmask )) )"
		l_root_path="$(sudo -Hiu root env | grep '^PATH' | cut -d= -f2)"
		unset a_path_loc && IFS=":" read -ra a_path_loc <<< "$l_root_path"
		grep -q "::" <<< "$l_root_path" && l_output2="$l_output2\n - root's path contains a empty directory (::)"
		grep -Pq ":\h*$" <<< "$l_root_path" && l_output2="$l_output2\n - root's path contains a trailing (:)"
		grep -Pq '(\h+|:)\.(:|\h*$)' <<< "$l_root_path" && l_output2="$l_output2\n - root's path contains current working directory (.)"
		while read -r l_path; do
			if [ -d "$l_path" ]; then
				while read -r l_fmode l_fown; do
					[ "$l_fown" != "root" ] && l_output2="$l_output2\n - Directory: \"$l_path\" is owned by: \"$l_fown\" should be owned by \"root\""
					[ $(( $l_fmode & $l_pmask )) -gt 0 ] && l_output2="$l_output2\n - Directory: \"$l_path\" is mode: \"$l_fmode\" and should be mode: \"$l_maxperm\" or more restrictive"
				done <<< "$(stat -Lc '%#a %U' "$l_path")"
			else
				l_output2="$l_output2\n - \"$l_path\" is not a directory"
			fi
		done <<< "$(printf "%s\n" "${a_path_loc[@]}")"
		
		if [ -z "$l_output2" ]; then
			echo -e "\n- Audit Result:\n  *** PASS ***\n - Root's path is correctly configured\n"
			echo -e "- End check - Ensure root PATH Integrity." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2\n"
			echo -e "- End check - Ensure root PATH Integrity." | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
		
	}
	
	ensure_root_path_integrity_fix()
	{
		test=""
		echo -e "- Start remediation - Ensure root PATH Integrity" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- Making modifications to the root users PATH could have significant unintended consequences or result in outages and unhappy users. Therefore, it is recommended that the current PATH contents be reviewed and determine the action to be taken in accordance with site policy. -" | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- End remediation - Ensure root PATH Integrity" | tee -a "$LOG" 2>> "$ELOG"
		test="manual"
	}
	
	ensure_root_path_integrity_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
		ensure_root_path_integrity_fix
		if [ "$test" != "manual" ]; then
		    ensure_root_path_integrity_chk
        fi
	fi
	
	# Set return code, end recommendation entry in verbose log, and return
	case "$test" in
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