#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = ff5fe2f3
#   function = ensure_default_user_umask_027_more_restrictive_v2
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_default_user_umask_027_more_restrictive_v2.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/29/20    Recommendation "Ensure default user umask is 027 or more restrictive"
# Eric Pinnell       11/30/20    created v2 to be case insensitive, add /etc/login.defs to search, and change setting to /etc/login.defs
# Justin Brown       06/22/22    Updated to modern format
# Randie Bejar       11/06/23    updated to new version - Ensure default user umask is configured
 
ensure_default_user_umask_027_more_restrictive_v2()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   l_test=""

   file_umask_chk()
     { if grep -Psiq -- '^\h*umask\h+(0?[0-7][2-7]7|u(=[rwx]{0,3}),g=([rx]{0,2}),o=)(\h*#.*)?$' "$l_file"; then
         l_out="$l_out\n - umask is set correctly in \"$l_file\""
      elif grep -Psiq -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' "$l_file"; then
         l_output2="$l_output2\n   - \"$l_file\""
      fi
     }
   
   ensure_default_user_umask_027_more_restrictive_v2_chk()
	{
      echo -e "- Start check - Ensure default user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
      l_output="" l_output2=""
      
         if grep -Psiq -- '^\h*umask\h+(0?[0-7][2-7]7|u(=[rwx]{0,3}),g=([rx]{0,2}),o=)(\h*#.*)?$' "$l_file"; then
            l_output="$l_output\n - umask is set correctly in \"$l_file\""
         elif grep -Psiq -- '^\h*umask\h+(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b|[0-7][0-7][0-6]\b)|(u=[rwx]{1,3},)?(((g=[rx]?[rx]?w[rx]?[rx]?\b)(,o=[rwx]{1,3})?)|((g=[wrx]{1,3},)?o=[wrx]{1,3}\b)))' "$l_file"; then
            l_output2="$l_output2\n - umask is incorrectly set in \"$l_file\""
         fi

      while IFS= read -r -d $'\0' l_file; do
         file_umask_chk
      done < <(find /etc/profile.d/ -type f -name '*.sh' -print0)
      l_file="/etc/profile" && file_umask_chk
      l_file="/etc/bashrc" && file_umask_chk
      l_file="/etc/bash.bashrc" && file_umask_chk
      l_file="/etc/pam.d/postlogin"
      if grep -Psiq -- '^\h*session\h+[^#\n\r]+\h+pam_umask\.so\h+([^#\n\r]+\h+)?umask=(0?[0-7][2-7]7)\b' "$l_file"; then
         l_output1="$l_output1\n - umask is set correctly in \"$l_file\""
      elif grep -Psiq '^\h*session\h+[^#\n\r]+\h+pam_umask\.so\h+([^#\n\r]+\h+)?umask=(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b))' "$l_file"; then
         l_output2="$l_output2\n - umask is incorrectly set in \"$l_file\""
      fi
      l_file="/etc/login.defs" && file_umask_chk
      l_file="/etc/default/login" && file_umask_chk
      [[ -z "$l_output" && -z "$l_output2" ]] && l_output2="$l_output2\n - umask is not set"
      if [ -z "$l_output2" ]; then
         echo -e "\n- Audit Result:\n  ** PASS **\n - * Correctly configured * :\n$l_output\n"
         echo -e "- End check - Ensure default user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
      else
         echo -e "\n- Audit Result:\n  ** FAIL **\n - * Reasons for audit failure * :\n$l_output2"
         [ -n "$l_output" ] && echo -e "\n- * Correctly configured * :\n$l_output\n"
         echo -e "- End check - Ensure default user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
      fi
         
   }
   
   ensure_default_user_umask_027_more_restrictive_v2_fix()
	{
      echo -e "- Start remediation - Ensure default user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
      l_output="" l_output2="" l_out=""
         
      while IFS= read -r -d $'\0' l_file; do
         file_umask_chk
      done < <(find /etc/profile.d/ -type f -name '*.sh' -print0)
      [ -n "$l_out" ] && l_output="$l_out"
      l_file="/etc/profile" && file_umask_chk
      l_file="/etc/bashrc" && file_umask_chk
      l_file="/etc/bash.bashrc" && file_umask_chk
      l_file="/etc/pam.d/postlogin"
      if grep -Psiq '^\h*session\h+[^#\n\r]+\h+pam_umask\.so\h+([^#\n\r]+\h+)?umask=(([0-7][0-7][01][0-7]\b|[0-7][0-7][0-7][0-6]\b)|([0-7][01][0-7]\b))' "$l_file"; then
         l_output2="$l_output2\n   - \"$l_file\""
      fi
      l_file="/etc/login.defs" && file_umask_chk
      l_file="/etc/default/login" && file_umask_chk
      if [ -z "$l_output2" ]; then
         echo -e " - No files contain a UMASK that is not restrictive enough\n   No UMASK updates required to existing files"
      else
         echo -e "\n - UMASK is not restrictive enough in the following file(s):$l_output2\n\n- Manual Remediation Procedure:\n - Update these files and comment out the UMASK line\n  - or update umask to be \"0027\" or more restrictive"
         l_test="manual"
      fi
      if [ -n "$l_output" ]; then
         echo -e "$l_output"
      else
         echo -e " - Manual remedition required - Configure UMASK in a file in the \"/etc/profile.d/\" directory ending in \".sh\"\n\n"
         l_test="manual"
      fi
      
      echo -e "- End remediation - Ensure default user umask is configured" | tee -a "$LOG" 2>> "$ELOG"
   }
   
   ensure_default_user_umask_027_more_restrictive_v2_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
      if [ "$l_test" != "NA" ]; then
         ensure_default_user_umask_027_more_restrictive_v2_fix
         if [ "$l_test" != "manual" ]; then
            ensure_default_user_umask_027_more_restrictive_v2_chk
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