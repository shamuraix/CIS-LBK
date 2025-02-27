#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = d49673fb
#   function = deb_ensure_chrony_configured_authorized_timeserver
#   applicable =
# # END METADATA
#
#
# CIS-LBK Cloud Team Built Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_chrony_configured_authorized_timeserver.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       11/20/20    Recommendation "Ensure chrony is configured with authorized timeserver"
# Justin Brown       08/02/22    Updated to modern format
#

deb_ensure_chrony_configured_authorized_timeserver()
{
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   test=""

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

	if [ -z "$G_PQ" ] || [ -z "$G_PM" ]; then
		nix_package_manager_set
	fi

	deb_ensure_chrony_configured_authorized_timeserver_chk()
   {
      if ! $G_PQ chrony | grep -Pq "^Status:\s+install\s+ok\s+installed" 2>/dev/null; then
			test=NA
		else
			echo -e "- Start check - Ensure chrony is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
      	l_test1="" l_test2=""

			if grep -Eq '"^(server|pool)' /etc/chrony/chrony.conf; then
				l_test1=passed
			else
				test=manual
			fi

			if ps -ef | grep 'chronyd' | grep '_chrony'; then
				l_test2=passed
			else
				test=manual
			fi

			if [ "$l_test1" = passed ] && [ "$l_test2" = passed ]; then
				echo -e "- PASS:\n- Chrony is configured to use a time server:\n $(grep -P '"^(server|pool)' /etc/chrony/chrony.conf)"  | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure chrony is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_PASS:-101}"
			else
				echo -e "- FAIL:\n- Chrony is NOT configured to use a time server" | tee -a "$LOG" 2>> "$ELOG"
				echo -e "- End check - Ensure chrony is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
				return "${XCCDF_RESULT_FAIL:-102}"
			fi
		fi
   }

	deb_ensure_chrony_configured_authorized_timeserver_fix()
   {
      echo -e "- Start remediation - Ensure chrony is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"

      echo -e "- Edit /etc/chrony/chrony.conf or a file ending in .sources in /etc/chrony/sources.d/ and add or edit server or pool lines as appropriate according to local site policy." | tee -a "$LOG" 2>> "$ELOG"
      test=manual

      echo -e "- End remediation - Ensure chrony is configured with authorized timeserver" | tee -a "$LOG" 2>> "$ELOG"
   }
	
	deb_ensure_chrony_configured_authorized_timeserver_chk
   if [ "$?" = "101" ] || [ "$test" = "NA" ]; then
      [ -z "$test" ] && test="passed"
   else
      deb_ensure_chrony_configured_authorized_timeserver_fix
      if [ "$test" != "manual" ]; then
         deb_ensure_chrony_configured_authorized_timeserver_chk
      fi
   fi

	# Set return code and return
	case "$test" in
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
			echo "Recommendation \"$RNA\" Chrony is not installed on the system - Recommendation is non applicable" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-104}"
			;;
		*)
			echo "Recommendation \"$RNA\" remediation failed" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
			;;
	esac
}