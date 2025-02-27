#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 6b03ff2c
#   function = deb_ensure_updates_patches_security_software_installed
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_updates_patches_security_software_installed.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       10/26/20    Recommendation "Ensure updates, patches, and additional security software are installed"
# Justin Brown       04/18/22    Updated to modern format
# Justin Brown       07/31/22    Copied to Debian specific version to add better manual remediation info
#

deb_ensure_updates_patches_security_software_installed()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   test=""

   deb_ensure_updates_patches_security_software_installed_chk()
   {
      if [ "$test" != "manual" ]; then
         echo -e "- Start check - Ensure updates, patches, and additional security software are installed" | tee -a "$LOG" 2>> "$ELOG"
         l_output=""
         
         echo -e "- Result - requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"

         echo -e "- Start check - Ensure updates, patches, and additional security software are installed" | tee -a "$LOG" 2>> "$ELOG"
      fi
   }

   deb_ensure_updates_patches_security_software_installed_fix()
   {
      echo -e "- Start remediation - Ensure updates, patches, and additional security software are installed" | tee -a "$LOG" 2>> "$ELOG"

      echo -e "- Run the following command to update all packages following local site policy guidance on applying updates and patches:\n  'apt upgrade'\nor\n  'apt dist-upgrade'" | tee -a "$LOG" 2>> "$ELOG"
      test=manual

      echo -e "- End remediation - Ensure updates, patches, and additional security software are installed" | tee -a "$LOG" 2>> "$ELOG"
   }

   deb_ensure_updates_patches_security_software_installed_chk
   if [ "$?" = "101" ]; then
      [ -z "$test" ] && test="passed"
   else
      deb_ensure_updates_patches_security_software_installed_fix
      if [ "$test" != "manual" ]; then
         deb_ensure_updates_patches_security_software_installed_chk
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