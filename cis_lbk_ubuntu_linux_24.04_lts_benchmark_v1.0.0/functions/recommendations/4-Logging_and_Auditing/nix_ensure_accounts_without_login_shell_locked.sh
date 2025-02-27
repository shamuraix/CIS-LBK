#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = f21e5649
#   function = ensure_accounts_without_login_shell_locked
#   applicable =
# # END METADATA
#
#
#
#
#
#
#
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_accounts_without_login_shell_locked.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Gokhan Lus          03/15/24   Recommendation "Ensure accounts without a valid login shell are locked"
#
  
ensure_accounts_without_login_shell_locked()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   l_test=""
   
   
   ensure_accounts_without_login_shell_locked_chk()
	{
      echo -e "- Start check - Ensure accounts without a valid login shell are locked" | tee -a "$LOG" 2>> "$ELOG"
      l_valid_shells="" 
      l_user=""
      l_output2=""
      
      # Check accounts without a valid login shell
      l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"
      while IFS= read -r l_user; do
        if [ -n "$(passwd -S "$l_user" | awk '$2 !~ /^L/ {print $1}')" ]; then
         l_output2="$l_output2\n$l_user does not have a valid login shell and is not locked"
        fi
      done < <(awk -v pat="$l_valid_shells" -F: '($1 != "root" && $(NF) !~ pat) {print $1}' /etc/passwd)
      
      if [ -z "$l_output2" ]; then
			echo -e "- PASS:\n- All accounts without a valid login shell are locked" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure accounts without a valid login shell are locked" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n$l_output2" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure accounts without a valid login shell are locked" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
   }
   
   ensure_accounts_without_login_shell_locked_fix()
	{
      echo -e "- Start remediation - Ensure accounts without a valid login shell are locked" | tee -a "$LOG" 2>> "$ELOG"
      
   l_valid_shells="^($(awk -F\/ '$NF != "nologin" {print}' /etc/shells | sed -rn '/^\//{s,/,\\\\/,g;p}' | paste -s -d '|' - ))$"  
   while IFS= read -r l_user; do
      if [ -n "$(passwd -S "$l_user" | awk '$2 !~ /^L/ {print $1}')" ]; then
       echo -e "- Locking account for $l_user" | tee -a "$LOG" 2>> "$ELOG"
       usermod -L $l_user
      fi
   done < <(awk -v pat="$l_valid_shells" -F: '($1 != "root" && $(NF) !~ pat) {print $1}' /etc/passwd)
      
      echo -e "- End remediation - Ensure accounts without a valid login shell are locked" | tee -a "$LOG" 2>> "$ELOG"
   }
   
   ensure_accounts_without_login_shell_locked_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
      ensure_accounts_without_login_shell_locked_fix
      if [ "$l_test" != "manual" ]; then
         ensure_accounts_without_login_shell_locked_chk
         if [ "$?" = "101" ]; then
             [ "$l_test" != "failed" ] && l_test="remediated"
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