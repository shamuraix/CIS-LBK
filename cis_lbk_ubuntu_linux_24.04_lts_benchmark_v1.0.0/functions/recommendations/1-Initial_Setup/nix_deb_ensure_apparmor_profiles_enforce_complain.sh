#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 7b97c072
#   function = deb_ensure_apparmor_profiles_enforce_complain
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_apparmor_profiles_enforce_complain.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# David Neilson	     12/01/22	 Recommendation "Ensure all AppArmor Profiles are in enforce or complain mode (Automated)"
# David Neilson	     12/29/22	 Commented out process checks
deb_ensure_apparmor_profiles_enforce_complain()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_apparmor_profiles_enforce_complain_chk()
	{
		# Set local variables.
        l_test1=""
		l_test2=""		
        l_apparmor_status=$(apparmor_status)
        l_num_profiles_loaded=$(echo "$l_apparmor_status" | grep "profiles are loaded" | awk '{print $1}')
        l_num_profiles_enforce=$(echo "$l_apparmor_status" | grep "profiles are in enforce mode" | awk '{print $1}')
        l_num_profiles_complain=$(echo "$l_apparmor_status" | grep "profiles are in complain mode" | awk '{print $1}')
		### l_num_processes_unconfined=$(echo "$l_apparmor_status" | grep "processes are unconfined" | awk '{print $1}')

        # Verify the number of profiles loaded equals the sum of profiles in enforce mode + profiles in complain mode.
        if [ $l_num_profiles_loaded -gt 0 -a $l_num_profiles_loaded -eq $( expr $l_num_profiles_enforce + $l_num_profiles_complain ) ]; then
            l_test1="passed"
        fi

        ### # Verify no processes are unconfined.
		### if [ $l_num_processes_unconfined -eq 0 ]; then
        ###    l_test2="passed"
		### else
        ###    l_test2="manual" 
        ### fi

        ### # If l_test1 and l_test2 both equal "passed", we pass.  
		### if [ "$l_test1" = "passed"  -a "$l_test2" = "passed" ]; then
		# If l_test1 equals "passed", we pass.
		if [ "$l_test1" = "passed" ]; then
		###	if [ "$l_test" = "manual" ]; then
        ###                       echo -e "- Remediation required:\n- Any processes that were unconfined may need to have a profile created or activated for them" | tee -a "$LOG" 2>> "$ELOG"
        ###                       return "${XCCDF_RESULT_PASS:-106}"
        ###                	else
            echo -e "- PASSED:\n- AppArmor profiles are in enforce or complain mode" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure AppArmor profiles enforce or complain" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
        ###					fi
        ### elif [ "$l_test1" = "passed" -a "$l_test2" = "manual" ] || [ -z "$l_test1" -a "$l_test2" = "manual" ]; then
		###	l_test="manual"
		###	echo -e "- Remediation required:\n- Any unconfined processes may need to have a profile created or activated for them and then be restarted" | tee -a "$LOG" 2>> "$ELOG"
		###	return "${XCCDF_RESULT_PASS:-106}"    
        else
			echo -e "- FAILED:\n- AppArmor profiles are NOT in enforce or complain mode" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure AppArmor profiles enforce or complain" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-102}"
		fi	
	}
	
	deb_ensure_apparmor_profiles_enforce_complain_fix()
	{
		echo -e "- Start remediation - Setting all profiles to complain mode" | tee -a "$LOG" 2>> "$ELOG"

		aa-complain /etc/apparmor.d/* > /dev/null 2>&1

		echo -e "- End remediation - Profiles set to complain mode" | tee -a "$LOG" 2>> "$ELOG"
	}

    deb_ensure_apparmor_profiles_enforce_complain_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	### elif [ "$l_test" = "manual" ]; then
	### 	deb_ensure_apparmor_profiles_enforce_complain_fix
	### 	deb_ensure_apparmor_profiles_enforce_complain_chk
	### 	if [ "$?" = "106" ]; then
	### 		:
	###	else
	###		l_test="failed"
	###	fi
	else
		deb_ensure_apparmor_profiles_enforce_complain_fix
		deb_ensure_apparmor_profiles_enforce_complain_chk
		if [ "$?" = "101" ]; then
			[ "$l_test" != "failed" ] && l_test="remediated"
		else
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