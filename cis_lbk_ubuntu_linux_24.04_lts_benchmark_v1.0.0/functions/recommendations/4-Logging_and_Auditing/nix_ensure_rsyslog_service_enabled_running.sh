#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = f659840d
#   function = ensure_rsyslog_service_enabled_running
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_rsyslog_service_enabled_running.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/03/20    Recommendation "Ensure rsyslog Service is enabled and running"
# Justin Brown       05/11/22    Updated to modern format
#

ensure_rsyslog_service_enabled_running()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   test=""
   
   ensure_rsyslog_service_enabled_running_chk()
   {
      echo -e "- Start check - Ensure rsyslog Service is enabled and running" | tee -a "$LOG" 2>> "$ELOG"
      l_output="" l_test1="" l_test2=""
      
      if systemctl is-enabled rsyslog | grep -q 'enabled'; then
         l_output="rsyslog enabled status: $(systemctl is-enabled rsyslog)"
         l_test1=passed
      else 
         l_output="rsyslog enabled status: $(systemctl is-enabled rsyslog)"
      fi
      
      if systemctl status rsyslog | grep 'Active: active (running) ' 1>>/dev/null; then
         l_output="$l_output\nrsyslog active status: $(systemctl status rsyslog | grep 'Active:')"
         l_test2=passed
      else 
         l_output="$l_output\nrsyslog active status: $(systemctl status rsyslog | grep 'Active:')"
      fi
      
      if [ "$l_test1" = passed ] && [ "$l_test2" = passed ]; then
			echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure rsyslog Service is enabled and running" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- rsyslog package was found." | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- FAIL:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure rsyslog Service is enabled and running" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
    
      echo -e "- End check - Ensure rsyslog Service is enabled and running" | tee -a "$LOG" 2>> "$ELOG"
   }
      
   ensure_rsyslog_service_enabled_running_fix()
   {
    	echo -e "- Start remediation - Ensure rsyslog is installed" | tee -a "$LOG" 2>> "$ELOG"
      
	  	if systemctl is-enabled rsyslog | grep -q 'masked'; then
			echo -e "- Unmasking rsyslog service " | tee -a "$LOG" 2>> "$ELOG"
			systemctl unmask rsyslog
			echo -e "- Enabling and starting rsyslog service." | tee -a "$LOG" 2>> "$ELOG"
			systemctl --now enable rsyslog
		else
			echo -e "- Enabling and starting rsyslog service." | tee -a "$LOG" 2>> "$ELOG"
			systemctl --now enable rsyslog
		fi 
      
      echo -e "- End remediation - Ensure rsyslog is installed" | tee -a "$LOG" 2>> "$ELOG"
   }  

	ensure_rsyslog_service_enabled_running_chk
	if [ "$?" = "101" ]; then
		[ -z "$test" ] && test="passed"
	else
    	ensure_rsyslog_service_enabled_running_fix
    	ensure_rsyslog_service_enabled_running_chk
		if [ "$?" = "101" ]; then
			[ "$test" != "failed" ] && test="remediated"
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