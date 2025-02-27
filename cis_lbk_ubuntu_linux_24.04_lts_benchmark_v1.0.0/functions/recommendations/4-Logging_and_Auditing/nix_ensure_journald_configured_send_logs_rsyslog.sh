#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 9720e3c7
#   function = ensure_journald_configured_send_logs_rsyslog
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_journald_configured_send_logs_rsyslog.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/22/20    Recommendation "Ensure journald is configured to send logs to rsyslog"
# Justin Brown       05/12/22    Updated to modern format
# Randie Bejar		 11/06/23    updated to new version

ensure_journald_configured_send_logs_rsyslog()
{
   echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   l_test=""
   
   ensure_journald_configured_send_logs_rsyslog_chk()
   {
		if pgrep rsyslogd >/dev/null 2>&1 && ! pgrep -x systemd-journald >/dev/null 2>&1; then
			echo -e "- rsyslog is being used instead of systemd-journald." | tee -a "$LOG" 2>> "$ELOG"
		else
			echo -e "- System is not using rsyslog or is using systemd-journald." | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- Recommendation Ensure journald is configured to send logs to rsyslog is NA"  | tee -a "$LOG" 2>> "$ELOG"
			l_test="NA"
		fi

		echo -e "- Start check - Ensure journald is configured to send logs to rsyslog" | tee -a "$LOG" 2>> "$ELOG"
		l_output="" l_output2=""
		a_parlist=("ForwardToSyslog=yes")
		l_systemd_config_file="/etc/systemd/journald.conf" # Main systemd configuration file
		l_active_test=""

		config_file_parameter_chk()
		{
			unset A_out; declare -A A_out # Check config file(s) setting
			while read -r l_out; do
				if [ -n "$l_out" ]; then
					if [[ $l_out =~ ^\s*# ]]; then
					l_file="${l_out//# /}"
					else
					l_systemd_parameter="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
					[ "${l_systemd_parameter^^}" = "${l_systemd_parameter_name^^}" ] && A_out+=(["$l_systemd_parameter"]="$l_file")
					fi
				fi
			done < <(/usr/bin/systemd-analyze cat-config "$l_systemd_config_file" | grep -Pio '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')
			if (( ${#A_out[@]} > 0 )); then # Assess output from files and generate output
				while IFS="=" read -r l_systemd_file_parameter_name l_systemd_file_parameter_value; do
					l_systemd_file_parameter_name="${l_systemd_file_parameter_name// /}"
					l_systemd_file_parameter_value="${l_systemd_file_parameter_value// /}"
					if [ "${l_systemd_file_parameter_value^^}" = "${l_systemd_parameter_value^^}" ]; then
					l_output="$l_output\n - \"$l_systemd_parameter_name\" is correctly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\"\n"
					else
					l_output2="$l_output2\n - \"$l_systemd_parameter_name\" is incorrectly set to \"$l_systemd_file_parameter_value\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_systemd_parameter_value\"\n"
					fi
				done < <(grep -Pio -- "^\h*$l_systemd_parameter_name\h*=\h*\H+" "${A_out[@]}")
			else
				l_output2="$l_output2\n - \"$l_systemd_parameter_name\" is not set in an included file\n   ** Note: \"$l_systemd_parameter_name\" May be set in a file that's ignored by load procedure **\n"
			fi
		}
		while IFS="=" read -r l_systemd_parameter_name l_systemd_parameter_value; do # Assess and check parameters
			l_systemd_parameter_name="${l_systemd_parameter_name// /}"
			l_systemd_parameter_value="${l_systemd_parameter_value// /}"
			config_file_parameter_chk
		done < <(printf '%s\n' "${a_parlist[@]}")

		if systemctl list-units --type service | grep -P -- '(journald|rsyslog)' >/dev/null; then
			echo "Both rsyslog.service and systemd-journald.service are running."
			systemctl list-units --type service | grep -P -- '(journald|rsyslog)'
			l_active_test="passed"
		else
			echo "Either rsyslog.service or systemd-journald.service is not running."
			systemctl list-units --type service | grep -P -- '(journald|rsyslog)'
			l_active_test="failed"
		fi


		if [ -z "$l_output2" ] && [ "$l_active_test" = "passed" ]; then # Provide output from checks
			echo -e "\n- Audit Result:\n  ** PASS **\n$l_output\n"
			echo -e "- End check - Ensure journald is configured to send logs to rsyslog" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "\n- Audit Result:\n  ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
			[ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
			echo -e "- End check - Ensure journald is configured to send logs to rsyslog" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi		
   }
   
   ensure_journald_configured_send_logs_rsyslog_fix()
   {
      	echo -e "- Start remediation - Ensure journald is configured to send logs to rsyslog" | tee -a "$LOG" 2>> "$ELOG"

		# edit the file /etc/systemd/journald.conf
		if grep -Eq '^\s*(#)?\s*[Ff]orward[Tt]o[Ss]yslog' /etc/systemd/journald.conf; then
			echo -e "- Fixing ForwardToSyslog entry in /etc/systemd/journald.conf" | tee -a "$LOG" 2>> "$ELOG"
			sed -E -i 's/^\s*(#)?\s*[Ff]orward[Tt]o[Ss]yslog.*$/ForwardToSyslog=yes/g' /etc/systemd/journald.conf
		else
			echo -e "- Adding ForwardToSyslog entry to /etc/systemd/journald.conf" | tee -a "$LOG" 2>> "$ELOG"
			echo "ForwardToSyslog=yes" >> /etc/systemd/journald.conf
		fi
		
		# Restart the systemd-journald service
		systemctl restart systemd-journald.service

		echo -e "- End remediation - Ensure journald is configured to send logs to rsyslog" | tee -a "$LOG" 2>> "$ELOG"
   }
   
   ensure_journald_configured_send_logs_rsyslog_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
      	ensure_journald_configured_send_logs_rsyslog_fix
      	ensure_journald_configured_send_logs_rsyslog_chk
	  	if [ "$?" = "101" ]; then
			[ "$l_test" != "failed" ] && l_test="remediated"
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