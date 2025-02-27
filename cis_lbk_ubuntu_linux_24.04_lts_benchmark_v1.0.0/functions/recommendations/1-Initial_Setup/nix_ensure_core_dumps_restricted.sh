#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 1adbe3b0
#   function = ensure_core_dumps_restricted
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_core_dumps_restricted.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Eric Pinnell       09/16/20    Recommendation "Ensure core dumps are restricted"
# David Neilson	   05/23/22	 	Updated to current standards.
# Justin Brown			08/22/22		Updated file and function names to conform to standards

ensure_core_dumps_restricted()
{
	# Start recommendation entry for verbose log and output to screen
	echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
	l_test=""
	l_test1=""
	l_test2=""
	l_test3=""
	l_test4=""

	ensure_core_dumps_restricted_chk()
	{
		# Determine if "* hard core 0" is in one of the these files 
		if grep -Eqs '^\s*\*\s+hard\s+core\s+0\b' /etc/security/limits.conf /etc/security/limits.d/*; then
			l_test1="passed"
		fi

		# Determine if the output of "sysctl fs.suid_dumpable" is 0
		if sysctl fs.suid_dumpable | grep -Eqs '^\s*fs.suid_dumpable\s+=\s+0\b' ; then
			l_test2="passed"
		fi

		# Test sysctl to verify "fs.suid_dumpable" equals 0 in the files listed
		if grep -Eqs '^\s*fs.suid_dumpable\s+=\s+0\b' /etc/sysctl.conf /etc/sysctl.d/*; then
			l_test3="passed"
		fi

		# Check to see if systemd-coredump is installed.  If it is installed, but we were unable to set parameters in /etc/systemd/coredump.conf, l_test4a will have a value.
		if systemctl is-enabled coredump.service 2> /dev/null | egrep -qi "enabled|disabled" 2> /dev/null; then
			if grep -Eqs '^\s*[Ss]torage\s*=\s*none\b' /etc/systemd/coredump.conf && grep -Eqs '^\s*[Pp]rocess[Ss]ize[Mm]ax\s*=\s*0\b' /etc/systemd/coredump.conf; then
				l_test4="passed"
			else
				l_test4="failed"
			fi
		else
			l_test4="notInstalled"
		fi

		# If l_test1, l_test2, l_test3, and l_test4 all equal "passed", we pass the test and confirm that systemd-coredump is installed and configured correctly.
		if [ "$l_test1" = "passed" -a "$l_test2" = "passed" -a "$l_test3" = "passed" -a "$l_test4" = "passed" ]; then
			echo -e "- PASSED:\n- core dump restrictions in place " | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - core dump restrictions" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		elif [ "$l_test1" = "passed" -a "$l_test2" = "passed" -a "$l_test3" = "passed" -a "$l_test4" = "notInstalled" ]; then
			echo -e "- PASSED:\n- core dump restrictions in place though systemd-coredump is not installed" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - core dump restrictions" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			echo -e "- FAILED:\n- improper core dump restrictions" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - core dump restrictions" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-102}"
		fi
	}

	ensure_core_dumps_restricted_fix()
	{
		# If "* hard core 0" is not set correctly in /etc/security/limits.conf or /etc/security/limits.d/*, add it.
		if [ "$l_test1" != "passed" ]; then
			grep -Eq 'hard\s+core' /etc/security/limits.conf && sed -ri 's/^\s*(\S+)(\s+)(hard\s+core)(\s+)(\S+)(\s+.*)?$/*\2\3\40 \6/' /etc/security/limits.conf
			for file in /etc/security/limits.d/*; do
				grep -Eq 'hard\s+core' "$file" && sed -ri 's/^\s*(\S+)(\s+)(hard\s+core)(\s+)(\S+)(\s+.*)?$/*\2\3\40 \6/' "$file"
			done
			grep -Eqs '^\s*\*\s+hard\s+core\s+0\b' /etc/security/limits.conf /etc/security/limits.d/* || echo "*     hard     core     0" >> /etc/security/limits.d/cis_limits.conf	
		fi

		# If the output of sysctl "fs.suid_dumpable" is not 0, then set it.
		if [ "$l_test2" != "passed" ]; then	
			sysctl -w fs.suid_dumpable=0
		fi

		# If the parameter "fs.suid_dumpable = 0" is not set in /etc/sysctl.conf or /etc/sysctl.d/*, then set it.
		if [ "$l_test3" != "passed" ]; then	
			grep -q 'fs.suid_dumpable' /etc/sysctl.conf && sed -ri 's/^(.*)(fs.suid_dumpable\s+=\s+)(\S+\s*)(\s+#.*)?$/fs.suid_dumpable = 0\4/' /etc/sysctl.conf
			for file in /etc/sysctl.d/*; do
				grep -q 'fs.suid_dumpable' "$file" && sed -ri 's/^(.*)(fs.suid_dumpable\s+=\s+)(\S+\s*)(\s+#.*)?$/fs.suid_dumpable = 0\4/' "$file"
			done
			grep -Eqs '^\s*\fs.suid_dumpable\s+=\s+0\b' /etc/sysctl.conf /etc/sysctl.d/* || echo "fs.suid_dumpable = 0" >> /etc/sysctl.d/cis_sysctl.conf
		fi

		# If systemd-coredump is installed, set parameters in /etc/systemd/coredump.conf and reload daemon.
		if [ "$l_test4" = "failed" ]; then
			grep -Eqs '[Ss]torage' /etc/systemd/coredump.conf && sed -ri 's/^(.*)([Ss]torage\s*=\s*\S+\s*)(\s+#.*)?$/Storage=none\3/' /etc/systemd/coredump.conf || echo "Storage=none" >> /etc/systemd/coredump.conf
			grep -Eqs '[Pp]rocess[Ss]ize[Mm]ax' /etc/systemd/coredump.conf && sed -ri 's/^(.*)([Pp]rocess[Ss]ize[Mm]ax\s*=\s*\S+\s*)(\s+#.*)?$/ProcessSizeMax=0\3/' /etc/systemd/coredump.conf || echo "ProcessSizeMax=0" >> /etc/systemd/coredump.conf
			systemctl daemon-reload
		fi
	}

	ensure_core_dumps_restricted_chk
	if [ "$?" = "101" ]; then
		[ -z "$l_test" ] && l_test="passed"
	else
		ensure_core_dumps_restricted_fix
		ensure_core_dumps_restricted_chk
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