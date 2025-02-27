#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = cc922b60
#   function = deb_determine_ipv6_enabled
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_determine_ipv6_enabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       11/19/22    Recommendation "Ensure system is checked to determine if IPv6 is enabled"
# 

deb_determine_ipv6_enabled()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	
	deb_determine_ipv6_enabled_chk()
	{
		l_output=""

		echo "- Start check - Ensure system is checked to determine if IPv6 is enabled" | tee -a "$LOG" 2>> "$ELOG"
		
		grubfile=$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) -exec grep -Pl -- '^\h*(kernelopts=|linux|kernel)' {} \;) 
		searchloc="/run/sysctl.d/*.conf /etc/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /lib/sysctl.d/*.conf /etc/sysctl.conf" 
		
		if [ -s "$grubfile" ]; then
			! grep -P -- "^\h*(kernelopts=|linux|kernel)" "$grubfile" | grep -vq -- ipv6.disable=1 && output="IPv6 Disabled in \"$grubfile\"" 
		fi 
		
		if grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\h*(#.*)?$" $searchloc && grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\h*(#.*)?$" $searchloc && sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\h*(#.*)?$" && sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pqs -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\h*(#.*)?$"; then
			[ -n "$l_output" ] && l_output="- $l_output, and in sysctl config" || l_output="- ipv6 disabled in sysctl config" 
		fi 
		
		if [ -n "$l_output" ]; then 
			echo -e "- $l_output" || 
			echo -e "- End check - Ensure system is checked to determine if IPv6 is enabled" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		else
			echo -e "- IPv6 is enabled on the system\n"
			echo -e "- End check - Ensure system is checked to determine if IPv6 is enabled" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi

	}

	deb_determine_ipv6_enabled_fix()
	{
		echo -e "- Start remediation - Ensure system is checked to determine if IPv6 is enabled" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- It is recommended that IPv6 be enabled and configured in accordance with Benchmark recommendations" | tee -a "$LOG" 2>> "$ELOG"
		l_test="manual"

		echo -e "- End remediation - Ensure system is checked to determine if IPv6 is enabled" | tee -a "$LOG" 2>> "$ELOG"

	}

	deb_determine_ipv6_enabled_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		deb_determine_ipv6_enabled_fix
		if [ "$l_test" != "manual" ]; then
			deb_determine_ipv6_enabled_chk
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