#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 346fbdd8
#   function = deb_ensure_package_manager_repositories_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Deprecated Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_package_manager_repositories_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/11/20    Recommendation "Ensure package manager repositories are configured"
# Justin Brown       04/18/22    Updated to modern format
# Justin Brown       07/31/22    Copied to Debian specific version to add better audit and remediation info
# Gokhan Lus	      05/10/24    This script will be deprecated and replaced by 'nix_ensure_package_manager_repositories_configured.sh'

deb_ensure_package_manager_repositories_configured()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   test=""

   deb_ensure_package_manager_repositories_configured_chk()
   {
      if [ "$test" != "manual" ]; then
         echo -e "- Start check - Ensure package manager repositories are configured" | tee -a "$LOG" 2>> "$ELOG"
         
         echo -e "- Review the current package repositories:\n$(apt-cache policy)\n- Result - requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"

         echo -e "- Start check - Ensure package manager repositories are configured" | tee -a "$LOG" 2>> "$ELOG"
      fi
   }

   deb_ensure_package_manager_repositories_configured_fix()
   {
      echo -e "- Start remediation - Ensure package manager repositories are configured" | tee -a "$LOG" 2>> "$ELOG"

      echo -e "- Configure your package manager repositories according to site policy." | tee -a "$LOG" 2>> "$ELOG"
      test=manual

      echo -e "- End remediation - Ensure package manager repositories are configured" | tee -a "$LOG" 2>> "$ELOG"
   }

   deb_ensure_package_manager_repositories_configured_chk
   if [ "$?" = "101" ]; then
      [ -z "$test" ] && test="passed"
   else
      deb_ensure_package_manager_repositories_configured_fix
      if [ "$test" != "manual" ]; then
         deb_ensure_package_manager_repositories_configured_chk
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