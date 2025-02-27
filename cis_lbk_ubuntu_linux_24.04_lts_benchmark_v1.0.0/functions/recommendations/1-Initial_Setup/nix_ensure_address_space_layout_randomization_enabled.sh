#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = f4c15700
#   function = ensure_address_space_layout_randomization_enabled
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_address_space_layout_randomization_enabled.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell        09/16/20   Recommendation "Ensure address space layout randomization (ASLR) is enabled"
# David Neilson	    05/28/22	Updated to latest standards
# Justin Brown        08/22/22	Modified chk function to mimic audit steps from benchmark, changed function and file name to fit standard, added logging to remediation
# J Brown			10/3/23		Updated to improved scripts from the benchmark file.
# David Neilson	    10/23/23	Updated string "GPG keys are configured" to "Ensure ASLR is enabled", and added "XCCDF_RESULT_PASS..." lines to the check function.

ensure_address_space_layout_randomization_enabled()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	ensure_address_space_layout_randomization_enabled_chk()
	{
		echo -e "- Start check - Ensure address space layout randomization (ASLR) is enabled" | tee -a "$LOG" 2>> "$ELOG"

		l_output="" l_output2=""
   		a_parlist=("kernel.randomize_va_space=2")
   		l_ufwscf="$([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)"

		kernel_parameter_chk()
   		{
			l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" # Check running configuration

			if [ "$l_krp" = "$l_kpvalue" ]; then
				l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in the running configuration"
			else
				l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_krp\" in the running configuration and should have a value of: \"$l_kpvalue\""
			fi

			unset A_out; declare -A A_out # Check durable setting (files)

			while read -r l_out; do
				if [ -n "$l_out" ]; then
					if [[ $l_out =~ ^\s*# ]]; then
						l_file="${l_out//# /}"
					else
						l_kpar="$(awk -F= '{print $1}' <<< "$l_out" | xargs)"
						[ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_file")
					fi
				fi
			done < <(/usr/lib/systemd/systemd-sysctl --cat-config | grep -Po '^\h*([^#\n\r]+|#\h*\/[^#\n\r\h]+\.conf\b)')

			if [ -n "$l_ufwscf" ]; then # Account for systems with UFW (Not covered by systemd-sysctl --cat-config)
				l_kpar="$(grep -Po "^\h*$l_kpname\b" "$l_ufwscf" | xargs)"
				l_kpar="${l_kpar//\//.}"
				[ "$l_kpar" = "$l_kpname" ] && A_out+=(["$l_kpar"]="$l_ufwscf")
			fi

			if (( ${#A_out[@]} > 0 )); then # Assess output from files and generate output
				while IFS="=" read -r l_fkpname l_fkpvalue; do
					l_fkpname="${l_fkpname// /}"; l_fkpvalue="${l_fkpvalue// /}"
					if [ "$l_fkpvalue" = "$l_kpvalue" ]; then
						l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_krp\" in \"$(printf '%s' "${A_out[@]}")\"\n"
					else
						l_output2="$l_output2\n - \"$l_kpname\" is incorrectly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\" and should have a value of: \"$l_kpvalue\"\n"
					fi
				done < <(grep -Po -- "^\h*$l_kpname\h*=\h*\H+" "${A_out[@]}")
			else
				l_output2="$l_output2\n - \"$l_kpname\" is not set in an included file\n   ** Note: \"$l_kpname\" May be set in a file that's ignored by load procedure **\n"
			fi
		}

		while IFS="=" read -r l_kpname l_kpvalue; do # Assess and check parameters
			l_kpname="${l_kpname// /}"; l_kpvalue="${l_kpvalue// /}"
			if ! grep -Pqs '^\h*0\b' /sys/module/ipv6/parameters/disable && grep -q '^net.ipv6.' <<< "$l_kpname"; then
				l_output="$l_output\n - IPv6 is disabled on the system, \"$l_kpname\" is not applicable"
			else
				kernel_parameter_chk
			fi
		done < <(printf '%s\n' "${a_parlist[@]}")

		if [ -z "$l_output2" ]; then # Provide output from checks
			echo -e "\n- Audit Result:\n  ** PASS **\n$l_output\n"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "\n- Audit Result:\n  ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
			[ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
			return "${XCCDF_RESULT_PASS:-102}"
		fi
	}

	ensure_address_space_layout_randomization_enabled_fix()
	{
		echo -e "- Start remediation - Ensure address space layout randomization (ASLR) is enabled" | tee -a "$LOG" 2>> "$ELOG"

		# If the parameter is correctly set in the file(s), set the active kernel parameter
		if grep -Eqs '^\s*kernel.randomize_va_space\s*=\s*2\b' /etc/sysctl.conf /etc/sysctl.d/*; then
			echo -e "- Writing kernel.randomize_va_space to sysctl" | tee -a "$LOG" 2>> "$ELOG"
			sysctl -w kernel.randomize_va_space=2
		else
			# If the parameter is in the file(s) but not correctly set, fix it in the file(s)
			grep -q 'kernel.randomize_va_space' /etc/sysctl.conf && sed -ri 's/^(.*)(kernel\.randomize_va_space\s*=\s*\S+\s*)(\s+#.*)?$/kernel.randomize_va_space = 2\3/' /etc/sysctl.conf
			for file in /etc/sysctl.d/*; do
				grep -qs 'kernel.randomize_va_space' "$file" && sed -ri 's/^(.*)(kernel\.randomize_va_space\s*=\s*\S+\s*)(\s+#.*)?$/kernel.randomize_va_space = 2\3/' "$file" && echo -e "- Updating kernel.randomize_va_space in $file" | tee -a "$LOG" 2>> "$ELOG"
			done
			# If the parameter does not exist in the file(s), create a new file with it
			if ! grep -Eqs '^\s*kernel.randomize_va_space\s*=\s*2\b' /etc/sysctl.conf /etc/sysctl.d/*; then
				echo -e "- Adding kernel.randomize_va_space to /etc/sysctl.d/60-kernel_sysctl.conf" | tee -a "$LOG" 2>> "$ELOG"
				echo "kernel.randomize_va_space = 2" >> /etc/sysctl.d/60-kernel_sysctl.conf
			fi
			# If we had to add or modify the parameter in a file(s), we need to set the active kernel parameter
			sysctl -w kernel.randomize_va_space=2
		fi

		echo -e "- End remediation - Ensure address space layout randomization (ASLR) is enabled" | tee -a "$LOG" 2>> "$ELOG"
	}

	ensure_address_space_layout_randomization_enabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_address_space_layout_randomization_enabled_fix
		ensure_address_space_layout_randomization_enabled_chk
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