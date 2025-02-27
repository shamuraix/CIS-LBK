#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 41da80b4
#   function = deb_ensure_apparmor_profiles_enforcing
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_apparmor_profiles_enforcing.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# David Neilson	     11/23/22	 Recommendation "Ensure all AppArmor Profiles are enforcing (Automated)"
# David Neilson	     12/29/22	 Commented out process checks
deb_ensure_apparmor_profiles_enforcing()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_apparmor_profiles_enforcing_chk()
	{
		# Set local variables.
        l_test1=""
		l_test2=""		
        l_apparmor_status=$(apparmor_status)
        l_num_profiles_loaded=$(echo "$l_apparmor_status" | grep "profiles are loaded" | awk '{print $1}')
        l_num_profiles_enforce=$(echo "$l_apparmor_status" | grep "profiles are in enforce mode" | awk '{print $1}')
		#l_num_processes_defined=$(echo "$l_apparmor_status" | grep "processes have profiles defined" | awk '{print $1}')
        #l_num_processes_enforce=$(echo "$l_apparmor_status" | grep "processes are in enforce mode" | awk '{print $1}')
		### l_num_processes_unconfined=$(echo "$l_apparmor_status" | grep "processes are unconfined" | awk '{print $1}')

        # Verify the number of profiles loaded is >= 1, and that the number of profiles loaded equals the number of profiles in enforce mode.
        if [ "$l_num_profiles_loaded" -gt 0 ] && [ "$l_num_profiles_loaded" -eq "$l_num_profiles_enforce" ]; then
            l_test1="passed"
        fi

        ### # Verify no processes are unconfined.
		### #if [ $l_num_processes_defined -eq $l_num_processes_enforce ]; then
		### if [ $l_num_processes_unconfined -eq 0 ]; then
        ###    l_test2="passed"
        ### else
        ###    l_test2="manual" 
        ### fi

        ### # If the number of profiles loaded equals the number of profiles in enforce mode (l_test1="passed"), and no processes are unconfined (l_test2="passed"),
        ### # then we pass.  
		# If the number of profiles loaded equals the number of profiles in enforce mode (l_test1="passed"), we pass.  
		### if [ "$l_test1" = "passed"  -a "$l_test2" = "passed" ]; then
		if [ "$l_test1" = "passed" ]; then
                        ### if [ "$l_test" = "manual" ]; then
                        ###         echo -e "- Remediation required:\n- Any processes that were unconfined may need to have a profile created or activated for them" | tee -a "$LOG" 2>> "$ELOG"
                        ###         return "${XCCDF_RESULT_PASS:-106}"
                        ### else
            echo -e "- PASSED:\n- AppArmor profiles are being enforced" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- End check - Ensure AppArmor profiles enforcing" | tee -a "$LOG" 2>> "$ELOG"
            return "${XCCDF_RESULT_PASS:-101}"
            			### fi
		### elif [ "$l_test1" = "passed" -a "$l_test2" = "manual" ] || [ -z "$l_test1" -a "$l_test2" = "manual" ]; then
		###	l_test="manual"
		###	echo -e "- Remediation required:\n- Any unconfined processes may need to have a profile created or activated for them and then be restarted" | tee -a "$LOG" 2>> "$ELOG"
		###	return "${XCCDF_RESULT_PASS:-106}"
		# At this point, if one or the other variable equals "failed", we fail.    
		else
			echo -e "- FAILED:\n- AppArmor profiles are NOT being enforced" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure AppArmor profiles enforcing" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-102}"
		fi	
	}
	
	deb_ensure_apparmor_profiles_enforcing_fix()
	{
		echo -e "- Start remediation - Ensure AppArmor profiles are being enforced" | tee -a "$LOG" 2>> "$ELOG"

		aa-enforce /etc/apparmor.d/* > /dev/null 2>&1

		echo -e "- End remediation - Ensure AppArmor profiles enforcing" | tee -a "$LOG" 2>> "$ELOG"
	}

    deb_ensure_apparmor_profiles_enforcing_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	### elif [ "$l_test" = "manual" ]; then
	###	deb_ensure_apparmor_profiles_enforcing_fix
	###	deb_ensure_apparmor_profiles_enforcing_chk
	###	if [ "$?" = "106" ]; then
	###		:
	###	else
	###		l_test="failed"
	###	fi
	else
		deb_ensure_apparmor_profiles_enforcing_fix
		deb_ensure_apparmor_profiles_enforcing_chk
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