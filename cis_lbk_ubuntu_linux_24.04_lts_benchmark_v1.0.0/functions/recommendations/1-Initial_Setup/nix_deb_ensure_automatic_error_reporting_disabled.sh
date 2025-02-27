#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 1f458323
#   function = deb_ensure_automatic_error_reporting_disabled
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_automatic_error_reporting_disabled.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown        12/20/22   Recommendation "Ensure Automatic Error Reporting is not enabled"
#

deb_ensure_automatic_error_reporting_disabled()
{
	nix_package_manager_set()
	{
		echo -e "- Start - Determine system's package manager " | tee -a "$LOG" 2>> "$ELOG"

		if command -v rpm 2>/dev/null; then
			echo -e "- system is rpm based" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="rpm -q"
			command -v yum 2>/dev/null && G_PM="yum" && echo "- system uses yum package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v dnf 2>/dev/null && G_PM="dnf" && echo "- system uses dnf package manager" | tee -a "$LOG" 2>> "$ELOG"
			command -v zypper 2>/dev/null && G_PM="zypper" && echo "- system uses zypper package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PR="$G_PM  remove -y"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif command -v dpkg 2>/dev/null; then
			echo -e "- system is apt based\n- system uses apt package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="dpkg -s"
			G_PM="apt"
			G_PR="$G_PM purge -y"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAIL:\n- Unable to determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			G_PQ="unknown"
			G_PM="unknown"
			export G_PQ G_PM G_PR
			echo -e "- End - Determine system's package manager" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}

	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""

	deb_ensure_automatic_error_reporting_disabled_chk()
	{
		echo -e "- Start check - Ensure Automatic Error Reporting is not enabled" | tee -a "$LOG" 2>> "$ELOG"
		l_output=""  l_pkgmgr="" l_enabled="" l_running=""
		
		# Set package manager information
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
			[ "$?" != "101" ] && l_output="- Unable to determine system's package manager"
		fi
		
		if [ -z "$l_output" ]; then
            ! $G_PQ apport | grep -Eq 'apport-\S+' && l_test="passed"

            if [ "$l_test" != "passed" ]; then
                # Determine if apport.service is running.
                l_running=$(systemctl is-active apport.service)

                if [ "$l_running" = "active" ]; then
					# print the reason why we are failing
					echo -e "- FAILED:\n- apport.service is running"  | tee -a "$LOG" 2>> "$ELOG"
                    echo -e "- End check - Ensure Automatic Error Reporting is not enabled" | tee -a "$LOG" 2>> "$ELOG"
                    return "${XCCDF_RESULT_FAIL:-102}"
                else
                    echo -e "- PASS:\n- apport.service is NOT running"  | tee -a "$LOG" 2>> "$ELOG"
                    echo -e "- End check - Ensure Automatic Error Reporting is not enabled" | tee -a "$LOG" 2>> "$ELOG"
                    return "${XCCDF_RESULT_PASS:-101}"
                fi
            else
                echo -e "- PASS:\n- apport package is NOT installed"  | tee -a "$LOG" 2>> "$ELOG"
                echo -e "- End check - Ensure Automatic Error Reporting is not enabled" | tee -a "$LOG" 2>> "$ELOG"
                return "${XCCDF_RESULT_PASS:-101}"
            fi
        else
			# If we can't determine the pkg manager, need manual remediation
			l_pkgmgr="$l_output"
			echo -e "- FAILED:\n- $l_output" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure Automatic Error Reporting is not enabled" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-106}"
		fi
	}

	deb_ensure_automatic_error_reporting_disabled_fix()
	{
		echo -e "- Start remediation - Ensure Automatic Error Reporting is not enabled" | tee -a "$LOG" 2>> "$ELOG"

        if [ "$l_test" != "passed" ]; then
            echo -e "- Updating enabled value in /etc/default/apport" | tee -a "$LOG" 2>> "$ELOG"
            sed -ri 's/^\s*(enabled=)(\S+)(.*)$/\10 \3/' /etc/default/apport
        fi

        if [ "$l_running" = "active" ]; then
            echo -e "- Stopping apport.service" | tee -a "$LOG" 2>> "$ELOG"
            systemctl stop apport.service
            echo -e "- Masking apport.service" | tee -a "$LOG" 2>> "$ELOG"
            systemctl --now mask apport.service
        fi

		echo -e "- End remediation - Ensure Automatic Error Reporting is not enabled" | tee -a "$LOG" 2>> "$ELOG"
	}

	deb_ensure_automatic_error_reporting_disabled_chk
	if [ "$?" = "101" ] ; then
		[ -z "$l_test" ] && l_test="passed"
	elif [ -n "$l_pkgmgr" ] ; then
		l_test="manual"
    elif [ "$l_test" = "NA" ]; then
        l_test="NA"
	else
		deb_ensure_automatic_error_reporting_disabled_fix
		deb_ensure_automatic_error_reporting_disabled_chk
		if [ "$?" = "101" ] ; then
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