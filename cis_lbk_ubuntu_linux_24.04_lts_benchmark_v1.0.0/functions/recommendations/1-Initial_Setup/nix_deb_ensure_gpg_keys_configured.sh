#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = a35c7f49
#   function = deb_ensure_gpg_keys_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_gpg_keys_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/11/20    Recommendation "Ensure GPG keys are configured"
# Justin Brown       04/18/22    Updated to modern format
# Justin Brown       07/31/22    Copied to Debian specific version to add better manual remediation info
#

deb_ensure_gpg_keys_configured()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   test=""

   deb_ensure_gpg_keys_configured_chk()
   {
      if [ "$test" != "manual" ]; then
         echo -e "- Start check - Ensure GPG keys are configured" | tee -a "$LOG" 2>> "$ELOG"
         l_output=""
         
         echo -e "- Review the current apt-key list:\n$(apt-key list)\n- Result - requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"

         echo -e "- Start check - Ensure GPG keys are configured" | tee -a "$LOG" 2>> "$ELOG"
      fi
   }

   deb_ensure_gpg_keys_configured_fix()
   {
      echo -e "- Start remediation - Ensure GPG keys are configured" | tee -a "$LOG" 2>> "$ELOG"

      echo -e "- Update your package manager GPG keys in accordance with site policy." | tee -a "$LOG" 2>> "$ELOG"
      test=manual

      echo -e "- End remediation - Ensure GPG keys are configured" | tee -a "$LOG" 2>> "$ELOG"
   }

   deb_ensure_gpg_keys_configured_chk
   if [ "$?" = "101" ]; then
      [ -z "$test" ] && test="passed"
   else
      deb_ensure_gpg_keys_configured_fix
      if [ "$test" != "manual" ]; then
         deb_ensure_gpg_keys_configured_chk
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