#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 27cf721e
#   function = ensure_reverse_path_filtering_enabled
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_reverse_path_filtering_enabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       10/21/20    Recommendation "Ensure Reverse Path Filtering is enabled"
# Eric Pinnell       11/12/20    Modified "Modified to include sub-functions"
# Eric Pinnell       04/08/22    Modified to enhance logging
# Justin Brown		 11/20/22	 Refactored to use common functions
# Randie Bejar       11/07/23    Updated to new version

ensure_reverse_path_filtering_enabled()
{
	# Start recommendation entriey for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	
	ensure_reverse_path_filtering_enabled_chk()
	{
        echo "- Start check - Ensure Reverse Path Filtering is enabled" | tee -a "$LOG" 2>> "$ELOG" 
        l_output="" l_output2="" 
        a_parlist=("net.ipv4.conf.all.rp_filter=1" "net.ipv4.conf.default.rp_filter=1")
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
                    l_output="$l_output\n - \"$l_kpname\" is correctly set to \"$l_fkpvalue\" in \"$(printf '%s' "${A_out[@]}")\"\n"
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
            echo "- End check - Ensure Reverse Path Filtering is enabled" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_PASS:-101}" 
        else
            echo -e "\n- Audit Result:\n  ** FAIL **\n - Reason(s) for audit failure:\n$l_output2\n"
            [ -n "$l_output" ] && echo -e "\n- Correctly set:\n$l_output\n"
             echo "- End check - Ensure Reverse Path Filtering is enabled" | tee -a "$LOG" 2>> "$ELOG"
		   	return "${XCCDF_RESULT_FAIL:-102}" 
        fi
	}

	ensure_reverse_path_filtering_enabled_fix()
	{
        echo "- Start remediation - Ensure Reverse Path Filtering is enabled" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2="" 
        
        l_parlist="net.ipv4.conf.all.rp_filter=1 net.ipv4.conf.default.rp_filter=1" 
        l_searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf $([ -f /etc/default/ufw ] && awk -F= '/^\s*IPT_SYSCTL=/ {print $2}' /etc/default/ufw)" 
        l_kpfile="/etc/sysctl.d/60-netipv4_sysctl.conf" 
        
        KPF() 
        { 
            # comment out incorrect parameter(s) in kernel parameter file(s)
            l_fafile="$(grep -s -- "^\s*$l_kpname" $l_searchloc | grep -Pv -- "\h*=\h*$l_kpvalue\b\h*" | awk -F: '{print $1}')" 
            
            for l_bkpf in $l_fafile; do 
                echo -e "\n - Commenting out \"$l_kpname\" in \"$l_bkpf\"" | tee -a "$LOG" 2>> "$ELOG"
                sed -ri "/$l_kpname/s/^/# /" "$l_bkpf"
            done 
            
            # Set correct parameter in a kernel parameter file 
            if ! grep -Pslq -- "^\h*$l_kpname\h*=\h*$l_kpvalue\b\h*(#.*)?$" "$l_searchloc"; then 
                echo -e "\n - Setting \"$l_kpname\" to \"$l_kpvalue\" in \"$l_kpfile\"" | tee -a "$LOG" 2>> "$ELOG"
                echo "$l_kpname = $l_kpvalue" >> "$l_kpfile" 
            fi 
            
            # Set correct parameter in active kernel parameters 
            l_krp="$(sysctl "$l_kpname" | awk -F= '{print $2}' | xargs)" 
            
            if [ "$l_krp" != "$l_kpvalue" ]; then 
                echo -e "\n - Updating \"$l_kpname\" to \"$l_kpvalue\" in the active kernel parameters" | tee -a "$LOG" 2>> "$ELOG"
                sysctl -w "$l_kpname=$l_kpvalue" 
                sysctl -w "$(awk -F'.' '{print $1"."$2".route.flush=1"}' <<< "$l_kpname")" 
            fi 
        } 
        
        for l_kpe in $l_parlist; do
            l_kpname="$(awk -F= '{print $1}' <<< "$l_kpe")" 
            l_kpvalue="$(awk -F= '{print $2}' <<< "$l_kpe")"
            KPF 
        done

        echo "- End remediation - Ensure Reverse Path Filtering is enabled" | tee -a "$LOG" 2>> "$ELOG"
	}
			
	ensure_reverse_path_filtering_enabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_reverse_path_filtering_enabled_fix
		ensure_reverse_path_filtering_enabled_chk
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