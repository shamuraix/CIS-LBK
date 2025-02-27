#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 1d6d672e
#   function = ensure_nosuid_set_tmp_partition
#   applicable =
# # END METADATA
#
#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_ensure_nosuid_set_tmp_partition.sh
#
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       07/25/22    Recommendation "Ensure nosuid option set on /tmp partition"
# David Neilson       04/20/24    Changed variable "test" to "l_test", removed variable "l_mount_files" altogether (it was not used), changed "grep -P" to "grep -P --", removed reference to "l_mount_test=failed", does not check in "/.snapshot" or "/snap" directories, and verifies all filesystems listed by "findmnt --kernel" command have "nosuid" option set.  

ensure_nosuid_set_tmp_partition()
{

echo -e "\n**************************************************\n- $(date +%d-%b-%Y' '%T)\n- Start Recommendation \"$RN - $RNA\"" | tee -a "$LOG" 2>> "$ELOG"
   l_test=""
   XCCDF_VALUE_REGEX="/tmp"
   l_option="nosuid"

   ensure_nosuid_set_tmp_partition_chk()
   {
      echo -e "- Start check - Ensure nosuid option set on /tmp partition" | tee -a "$LOG" 2>> "$ELOG"
      l_current_test="" l_mount_test="" 
     
      # # Verify current mount options 
      if findmnt --kernel "$XCCDF_VALUE_REGEX"; then
         echo -e "- $XCCDF_VALUE_REGEX is a separate partition" | tee -a "$LOG" 2>> "$ELOG"
         if findmnt --kernel "$XCCDF_VALUE_REGEX" | grep -P -- "$XCCDF_VALUE_REGEX" | grep -Pvq -- "$l_option"; then
            echo -e "- $XCCDF_VALUE_REGEX does NOT have $l_option configured\n$(findmnt --kernel $XCCDF_VALUE_REGEX | grep -P -- "$XCCDF_VALUE_REGEX" | grep -Pv -- "$l_option")" | tee -a "$LOG" 2>> "$ELOG"
         else   
            echo -e "- $XCCDF_VALUE_REGEX has $l_option configured\n$(findmnt --kernel $XCCDF_VALUE_REGEX | grep -P -- "$XCCDF_VALUE_REGEX" | grep -P -- "$l_option")" | tee -a "$LOG" 2>> "$ELOG"
            l_current_test="passed"
         fi
      else
         echo -e "- $XCCDF_VALUE_REGEX is NOT a separate partition" | tee -a "$LOG" 2>> "$ELOG"
      fi

      # # Verify mount in /etc/fstab options
      if grep -Pq -- "^\h*[^#]+\h+$XCCDF_VALUE_REGEX(/)?\h+" /etc/fstab; then
         echo -e "- $XCCDF_VALUE_REGEX is configured in /etc/fstab" | tee -a "$LOG" 2>> "$ELOG"
         if grep -P -- "^\h*[^#]+\h+$XCCDF_VALUE_REGEX(/)?\h+" /etc/fstab | grep -Pq -- "$l_option"; then
            echo -e "- $l_option found in mount entry for $XCCDF_VALUE_REGEX in /etc/fstab" | tee -a "$LOG" 2>> "$ELOG"
            l_mount_test="passed"
         fi
      else
         echo -e "- $XCCDF_VALUE_REGEX is NOT configured in /etc/fstab" | tee -a "$LOG" 2>> "$ELOG"
      fi

      # Verify mount in systemd options
      if [ -z $l_mount_test ]; then
         l_unit_files="" l_dname="" l_mfile=""

         l_unit_files=$(find / -name '*.mount' -type f -exec grep -Plis -- "^\h*Where\h*=\h*$XCCDF_VALUE_REGEX" {} + 2>/dev/null | grep -Pv -- '(/\.snapshots/|/snap/)' )
  
         if [ -n "$l_unit_files" ]; then
            for l_dname in $l_unit_files; do
               l_mfile=$(awk -F'/' '(!($2 == "snap" || $2 == "run")) {print $NF}' <<< "$l_dname")
               if [ -n "$l_mfile" ] && systemctl list-unit-files --type mount "$l_mfile" &>/dev/null; then
                  echo -e "- $XCCDF_VALUE_REGEX is configured in $l_dname" | tee -a "$LOG" 2>> "$ELOG"
                  if awk '/[Mount]/,0' $l_dname | grep -Eq "^\s*Options=([^#]+,)?$l_option"  && [ "$l_mount_test" != "failed" ]; then
                     echo -e "- $l_dname contains $l_option option" | tee -a "$LOG" 2>> "$ELOG"
                     l_mount_test="passed"
                  else
                     echo -e "- $l_dname does NOT contain $l_option option" | tee -a "$LOG" 2>> "$ELOG"
                     l_mount_test="failed"
                  fi
               fi
            done
         else
            echo -e "- $XCCDF_VALUE_REGEX was NOT found in any systemd unit files" | tee -a "$LOG" 2>> "$ELOG"
         fi
      fi

      if [ "$l_current_test" = "passed" ] && [ "$l_mount_test" = "passed" ]; then
         echo -e "- PASS:\n- $XCCDF_VALUE_REGEX is properly configured"  | tee -a "$LOG" 2>> "$ELOG"
         echo -e "- End check - Ensure nosuid option set on /tmp partition" | tee -a "$LOG" 2>> "$ELOG"
         return "${XCCDF_RESULT_PASS:-101}"
      else
         echo -e "- FAIL:\n- $XCCDF_VALUE_REGEX is NOT properly configured" | tee -a "$LOG" 2>> "$ELOG"
         echo -e "- End check - Ensure nosuid option set on /tmp partition" | tee -a "$LOG" 2>> "$ELOG"
         return "${XCCDF_RESULT_FAIL:-102}"
      fi
   }

   ensure_nosuid_set_tmp_partition_fix()
   {
      echo -e "- Start remediation - Ensure nosuid option set on /tmp partition" | tee -a "$LOG" 2>> "$ELOG"
      l_rem_systemd="" l_rem_fstab=""

      # Update systemd mount files if applicable
      if ! grep -Pq -- "^\h*[^#]+\h+$XCCDF_VALUE_REGEX(/)?\h+" /etc/fstab; then
         l_unit_files=$(find / -name '*.mount' -type f -exec grep -Plis -- "^\h*Where\h*=\h*$XCCDF_VALUE_REGEX" {} + 2>/dev/null | grep -Pv -- '(/\.snapshots/|/snap/)' )
         if [ -n "$l_unit_files" ]; then
            for l_dname in $l_unit_files; do
               l_mfile=$(awk -F'/' '(!($2 == "snap" || $2 == "run")) {print $NF}' <<< "$l_dname")
               if [ -n "$l_mfile" ] && systemctl list-unit-files --type mount "$l_mfile" &>/dev/null; then
                  if ! awk '/[Mount]/,0' $l_dname | grep -Eq "^\s*Options=([^#]+,)?$l_option"; then
                     echo -e "- Updating $XCCDF_VALUE_REGEX in $l_dname" | tee -a "$LOG" 2>> "$ELOG"
                     sed -ri "s|(^\s*Options=[^#]+)|\1,$l_option|" $l_dname
                     awk '/[Mount]/,0' $l_dname | grep -Pq -- "^\h*Options=([^#]+,)?$l_option" && l_rem_systemd=remediated && G_REBOOT_REQUIRED=yes
                     echo -e "- Remounting $XCCDF_VALUE_REGEX with noexec,nodev,nosuid" | tee -a "$LOG" 2>> "$ELOG"
                     mount -o remount,noexec,nodev,nosuid $XCCDF_VALUE_REGEX
                  fi
               fi
            done
         fi
      fi

      # Update fstab 
      if [ "$l_rem_systemd" != "remediated" ]; then
         if grep -Pq -- "^\h*[^#]+\h+$XCCDF_VALUE_REGEX(/)?\h+" /etc/fstab; then
            echo -e "- $XCCDF_VALUE_REGEX is configured in /etc/fstab" | tee -a "$LOG" 2>> "$ELOG"
            if ! grep -Pq -- "^\h*[^#]+\h+$XCCDF_VALUE_REGEX(/)?\h+" /etc/fstab | grep -vq "$l_option"; then
               echo -e "- Updating $XCCDF_VALUE_REGEX in /etc/fstab" | tee -a "$LOG" 2>> "$ELOG"
               sed -ri "s|^\s*([^#]+\s+$XCCDF_VALUE_REGEX/?\s+)(\S+\s+)(\S+)?(\s+[0-9]\s+[0-9].*)$|\1\2\3,$l_option\4|" /etc/fstab
               grep -P -- "^\h*[^#]+\h+$XCCDF_VALUE_REGEX\h+" /etc/fstab | grep -Pq -- "$l_option" && l_rem_fstab=remediated && G_REBOOT_REQUIRED=yes
               echo -e "- Remounting $XCCDF_VALUE_REGEX with noexec,nodev,nosuid" | tee -a "$LOG" 2>> "$ELOG"
               mount -o remount,noexec,nodev,nosuid $XCCDF_VALUE_REGEX
            fi
         else
            echo -e "- Adding $XCCDF_VALUE_REGEX entry to /etc/fstab" | tee -a "$LOG" 2>> "$ELOG"
            echo "tmpfs           /tmp            tmpfs   defaults,noatime,nosuid,nodev,noexec,mode=1777    0       0" >> /etc/fstab
            grep -P -- "^\h*[^#]+\h+$XCCDF_VALUE_REGEX\h+" /etc/fstab | grep -Pq -- "$l_option" && l_rem_fstab=remediated && G_REBOOT_REQUIRED=yes
            echo -e "- Mounting $XCCDF_VALUE_REGEX with noexec,nodev,nosuid" | tee -a "$LOG" 2>> "$ELOG"
            mount -o noexec,nodev,nosuid $XCCDF_VALUE_REGEX
         fi
      fi

      if [ "$l_rem_systemd" = "remediated" ] || [ "$l_rem_fstab" = "remediated" ]; then
         l_test=remediated
      else
         echo -e "- Could not remediate $XCCDF_VALUE_REGEX in systemd unit files or /etc/fstab" | tee -a "$LOG" 2>> "$ELOG"
      fi

      echo -e "- End remediation - Ensure nosuid option set on /tmp partition" | tee -a "$LOG" 2>> "$ELOG"
   }

   ensure_nosuid_set_tmp_partition_chk
   if [ "$?" = "101" ]; then
      [ -z "$l_test" ] && l_test="passed"
   else
      ensure_nosuid_set_tmp_partition_fix
      if [ "$l_test" != "manual" ]; then
         ensure_nosuid_set_tmp_partition_chk
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