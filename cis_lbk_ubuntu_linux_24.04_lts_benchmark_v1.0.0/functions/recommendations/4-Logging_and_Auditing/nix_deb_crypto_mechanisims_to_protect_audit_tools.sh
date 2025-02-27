#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 2902223f
#   function = deb_crypto_mechanisims_to_protect_audit_tools
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_crypto_mechanisims_to_protect_audit_tools.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       12/31/22    Recommendation "Ensure cryptographic mechanisms are used to protect the integrity of audit tools"
# 
   
deb_crypto_mechanisims_to_protect_audit_tools()
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

    l_params="p i n u g s b acl xattrs sha512"
    l_tool_list="/sbin/auditctl /sbin/auditd /sbin/ausearch /sbin/aureport /sbin/autrace /sbin/augenrules"
   
    deb_crypto_mechanisims_to_protect_audit_tools_chk()
	{
        echo -e "- Start check - Ensure cryptographic mechanisms are used to protect the integrity of audit tools" | tee -a "$LOG" 2>> "$ELOG"
        l_output="" l_output2=""

        # Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && echo -e "- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
		fi

        if $G_PQ aide > /dev/null 2>&1 && $G_PQ aide-common > /dev/null 2>&1; then
            l_audit_tools="$(grep -P -- '(\/sbin\/(audit|au)\H*\b)' /etc/aide/aide.conf /etc/aide/aide.conf.d/*)"
        
            if [ -n "$l_audit_tools" ]; then
                while IFS= read -r l_tool; do
                    l_tool_file="$(awk -F: '{print $1}' <<< "$l_tool")"
                    l_tool_name="$(awk -F: '{print $2}' <<< "$l_tool" | awk -F" " '{print $1}')"
                    l_tool_attr="$(awk -F: '{print $2}' <<< "$l_tool" | awk -F" " '{print $2}')"
                    l_attr_array="$(tr '+' ' ' <<< "$l_tool_attr")"

                    l_tool_name_list="$l_tool_name_list $l_tool_name"
                    l_attr_diff=$(echo "${l_params[@]}" "${l_attr_array[@]}" "${l_attr_array[@]}" | tr ' ' '\n' | sort | uniq -u )

                    if [ -z "$l_attr_diff" ]; then
                        l_output="$l_output\n- File: $l_tool_file has tool $l_tool_name with attributes: $l_tool_attr"
                    else
                        l_output2="$l_output2\n- File: $l_tool_file has tool $l_tool_name missing attribute(s): $l_tool_attr"
                    fi
                done <<< "$l_audit_tools"
            else
                l_tool_name_list=""
            fi

            l_tool_diff=$(echo "${l_tool_list[@]}" "${l_tool_name_list[@]}" "${l_tool_name_list[@]}" | tr ' ' '\n' | sort | uniq -u )
            
            if [ -n "$l_tool_diff" ]; then
                l_output2="$l_output2\n- Missing Entries:\n $l_tool_diff"
            fi

            if [ -z "$l_output2" ]; then
                echo -e "- PASS:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
                echo -e "- End check - Ensure cryptographic mechanisms are used to protect the integrity of audit tools" | tee -a "$LOG" 2>> "$ELOG"
                return "${XCCDF_RESULT_PASS:-101}"
            else
                echo -e "- FAIL:\n- Failing values:\n$l_output2\n" | tee -a "$LOG" 2>> "$ELOG"
                if [ -n "$l_output" ]; then
                    echo -e "- Passing values:\n$l_output\n" | tee -a "$LOG" 2>> "$ELOG"
                fi
                echo -e "- End check - Ensure cryptographic mechanisms are used to protect the integrity of audit tools" | tee -a "$LOG" 2>> "$ELOG"
                return "${XCCDF_RESULT_FAIL:-102}"
            fi
        else
			echo -e "- aide packages NOT installed on the system." | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure cryptographic mechanisms are used to protect the integrity of audit tools" | tee -a "$LOG" 2>> "$ELOG"
			l_test="manual"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
    }
   
    deb_crypto_mechanisims_to_protect_audit_tools_fix()
	{
        echo -e "- Start remediation - Ensure cryptographic mechanisms are used to protect the integrity of audit tools" | tee -a "$LOG" 2>> "$ELOG"
        
        if [ "$l_test" != "manual" ]; then
            if [ -n "$l_audit_tools" ]; then
                while IFS= read -r l_tool; do
                    l_tool_file="$(awk -F: '{print $1}' <<< "$l_tool")"
                    l_tool_name="$(awk -F: '{print $2}' <<< "$l_tool" | awk -F" " '{print $1}')"
                    l_tool_attr="$(awk -F: '{print $2}' <<< "$l_tool" | awk -F" " '{print $2}')"
                    l_attr_array="$(tr '+' ' ' <<< "$l_tool_attr")"

                    l_tool_name_list="$l_tool_name_list $l_tool_name"
                    l_attr_diff=$(echo "${l_params[@]}" "${l_attr_array[@]}" "${l_attr_array[@]}" | tr ' ' '\n' | sort | uniq -u )

                    if [ -n "$l_attr_diff" ]; then
                        echo -e "- Updating entry for $l_tool_name in $l_tool_file" | tee -a "$LOG" 2>> "$ELOG"
                        l_update="$(tr '\n' '+' <<< "$l_attr_diff")"
                        l_update_tool="$(sed 's/\//\\\//g' <<< "$l_tool_name")"
                        sed -ri "s/^\s*(#\s*)?($l_update_tool\s+)([^#]+)?(\s*#.*)?$/\2$l_update\3\4/" "$l_tool_file"
                    fi
                done <<< "$l_audit_tools"
            fi

            if [ -n "$l_tool_diff" ]; then
                for l_missing_tool in $l_tool_diff; do
                    echo -e "- Adding entry for $l_missing_tool to /etc/aide/aide.conf" | tee -a "$LOG" 2>> "$ELOG"
                    echo "$l_missing_tool p+i+n+u+g+s+b+acl+xattrs+sha512" >> /etc/aide/aide.conf
                done
            fi
        else
			echo -e "- Install the aide package as appropriate for your environment then add lines to /etc/aide.conf to protect the audit tools" | tee -a "$LOG" 2>> "$ELOG"
            echo -e "- EXAMPLE:\n  # Audit Tools\n  /sbin/auditctl p+i+n+u+g+s+b+acl+xattrs+sha512" | tee -a "$LOG" 2>> "$ELOG"
            l_test="manual"
		fi
        
        echo -e "- End remediation - Ensure cryptographic mechanisms are used to protect the integrity of audit tools" | tee -a "$LOG" 2>> "$ELOG"
    }
   
    deb_crypto_mechanisims_to_protect_audit_tools_chk
    if [ "$?" = "101" ]; then
        [ -z "$l_test" ] && l_test="passed"
    else
        if [ "$l_test" != "NA" ]; then
            deb_crypto_mechanisims_to_protect_audit_tools_fix
            if [ "$l_test" != "manual" ]; then
                deb_crypto_mechanisims_to_protect_audit_tools_chk
                if [ "$?" = "101" ] ; then
                    [ "$l_test" != "failed" ] && l_test="remediated"
                else
                    l_test="failed"
                fi
            fi
        fi
    fi
	
	# Set return code and return
	case "$l_test" in
		passed)
			echo "Recommendation \"$RNA\" No remediation required" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
			;;
		remediated)
			echo "Recommendation \"$RNA\" successfully remediated" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-103}"
			;;
		manual)
			echo "Recommendation \"$RNA\" requires manual remediation" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-106}"
			;;
		NA)
			echo "Recommendation \"$RNA\" Something went wrong - Recommendation is non applicable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}