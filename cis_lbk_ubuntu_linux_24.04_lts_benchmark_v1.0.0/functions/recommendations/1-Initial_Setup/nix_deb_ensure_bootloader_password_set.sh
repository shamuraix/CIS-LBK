#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 1cf88ffa
#   function = deb_ensure_bootloader_password_set
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_bootloader_password_set.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/31/22    Recommendation "Ensure bootloader password is set"
# 

deb_ensure_bootloader_password_set()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   l_test=""
   
   deb_ensure_bootloader_password_set_chk()
	{
        echo -e "- Start check - Ensure bootloader password is set" | tee -a "$LOG" 2>> "$ELOG"
        l_tst1="" l_tst2="" l_output="" 
      
        l_grubfile="/boot/grub/grub.cfg"
        
		echo -e "$l_grubfile" | tee -a "$LOG" 2>> "$ELOG"

        if [ -z "$l_output" ] && [ -f "$l_grubfile" ]; then 
            grep -Piq '^\h*set\h+superusers\h*=\h*"?[^"\n\r]+"?(\h+.*)?$' "$l_grubfile" && l_tst1=pass 
            grep -Piq '^\h*password_pbkdf2\h+\H+\h+.+$' "$l_grubfile" && l_tst2=pass 
            
            [ "$l_tst1" = pass ] && [ "$l_tst2" = pass ] && l_output="- bootloader password set in \"$l_grubfile\"" 
        fi 
      
        if [ -n "$l_output" ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure bootloader password is set" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- bootloader password is NOT set" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure bootloader password is set" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi 
   }
   
   deb_ensure_bootloader_password_set_fix()
	{
   
      echo -e "- Start remediation - Ensure bootloader password is set" | tee -a "$LOG" 2>> "$ELOG"      
      
      echo -e "- Create an encrypted password with 'grub-mkpasswd-pbkdf2'\n  # grub-mkpasswd-pbkdf2\n\n  Enter password: <password>\n  Reenter password: <password>\n  PBKDF2 hash of your password is <encrypted-password>\n- Add the following into a custom /etc/grub.d configuration file:\n\n  cat <<EOF\n  set superusers=\"<username>\"\n  password_pbkdf2 <username> <encrypted-password>\n  EOF" | tee -a "$LOG" 2>> "$ELOG"
      l_test="manual"
      
      echo -e "- End remediation - Ensure bootloader password is set" | tee -a "$LOG" 2>> "$ELOG"
    }
   
   deb_ensure_bootloader_password_set_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
        if [ "$l_test" != "NA" ]; then
            deb_ensure_bootloader_password_set_fix
            if [ "$l_test" != "manual" ]; then
                deb_ensure_bootloader_password_set_chk
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