#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = b282da41
#   function = ensure_ssh_warning_banner_configured
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_ssh_warning_banner_configured.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/23/20    Recommendation "Ensure SSH warning banner is configured"
# Justin Brown       05/15/22    Updated to modern format
# David Neilson		 11/16/23	 Changed "$G_PM -y remove" to "$G_PM remove -y", variable "test" to "l_test", "grep -E" to "grep -P --""
 
ensure_ssh_warning_banner_configured()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   l_test=""
   
   nix_package_manager_set()
	{
		echo "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"
		if command -v rpm 2>/dev/null; then
			echo "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM remove -y"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM purge -y"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}   
   
   ensure_ssh_warning_banner_configured_chk()
	{
      echo -e "- Start check - Ensure SSH warning banner is configured" | tee -a "$LOG" 2>> "$ELOG"
      l_output="" l_sshd_cmd="" l_sshd_config=""
      
      if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
         nix_package_manager_set
      fi
      
      # Check is openssh-server is installed
      if ! $G_PQ openssh-server >/dev/null ; then
         l_test=NA
      else
         if sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Piq -- 'Banner\h\S+' && ! sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep "$(hostname)" /etc/hosts | awk '{print $1}')" | grep -Piq -- 'Banner\h+none' ; then
            l_output="- Entry found in sshd -T -C output: $(sshd -T -C user=root -C host="$(hostname)" -C addr="$(grep $(hostname) /etc/hosts | awk '{print $1}')" | grep -Pi -- 'Banner\h\S+')" && l_sshd_cmd="passed"
         else
            l_output="- No entry found in sshd -T -C output" && l_sshd_cmd="failed"
         fi
         
         if grep -Piq -- '^\h*Banner\h+none' /etc/ssh/sshd_config; then
            l_output="$l_output\n- Incorrect entry found in sshd_config: $(grep -Pi -- '^\h*Banner\h+none' /etc/ssh/sshd_config)" && l_sshd_config="failed"
         elif grep -Piq -- '^\h*#\h*Banner\h+' /etc/ssh/sshd_config; then
            l_output="$l_output\n- Commented entry found in sshd_config: $(grep -Pi -- '^\h*#\h*Banner\h+' /etc/ssh/sshd_config)" && l_sshd_config="failed"
         elif grep -Piq -- '^\h*Banner\h\S+' /etc/ssh/sshd_config; then
            l_output="$l_output\n- Entry found in sshd_config: $(grep -Pi -- '^\h*Banner\h\S+' /etc/ssh/sshd_config)" && l_sshd_config="passed"
         else
            l_output="$l_output\n- NO Entry found in sshd_config for Banner" && l_sshd_config="failed"
         fi
      fi
      
      if [ "$l_sshd_cmd" = "passed" ] && [ "$l_sshd_config" = "passed" ]; then
         echo -e "- PASS:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
         echo -e "- End check - Ensure SSH warning banner is configured" | tee -a "$LOG" 2>> "$ELOG"
         return "${XCCDF_RESULT_PASS:-101}"
      else
         echo -e "- FAIL:\n$l_output" | tee -a "$LOG" 2>> "$ELOG"
         echo -e "- End check - Ensure SSH warning banner is configured" | tee -a "$LOG" 2>> "$ELOG"
         return "${XCCDF_RESULT_FAIL:-102}"
      fi
   }
   
   ensure_ssh_warning_banner_configured_fix()
	{
      echo -e "- Start remediation - Ensure SSH warning banner is configured" | tee -a "$LOG" 2>> "$ELOG"
      
      if grep -Piq -- '^\h*(#\h*)?Banner\h+' /etc/ssh/sshd_config; then
         echo -e "- Updating Banner entry in /etc/ssh/sshd_config" | tee -a "$LOG" 2>> "$ELOG"
         sed -ri 's/^\s*(#\s*)?([Bb]anner)(\s+\S+\s*)(\s+#.*)?$/\2 \/etc\/issue.net\4/' /etc/ssh/sshd_config
      else
         echo -e "- Adding Banner entry to /etc/ssh/sshd_config" | tee -a "$LOG" 2>> "$ELOG"
         sed -E -i '/^\s*\#\s* Authentication/a Banner \/etc\/issue.net' /etc/ssh/sshd_config
      fi
      
      echo -e "- End remediation - Ensure SSH warning banner is configured" | tee -a "$LOG" 2>> "$ELOG"
   }
   
   ensure_ssh_warning_banner_configured_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
      if [ "$l_test" != "NA" ]; then
         ensure_ssh_warning_banner_configured_fix
         ensure_ssh_warning_banner_configured_chk
		 if [ "$?" = "101" ]; then
            [ "$l_test" != "failed" ] && l_test="remediated"
         else
            l_test="failed"
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