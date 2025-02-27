#!/usr/bin/env bash
#
# # START METADATA
#   recommendation = 7d809dbb
#   function = deb_ensure_ip6tables_default_deny_firewall_policy
#   applicable =
# # END METADATA
#

#
# CIS-LBK Recommendation Function
# ~/CIS-LBK/functions/recommendations/nix_deb_ensure_ip6tables_default_deny_firewall_policy.sh
# 
# Name                Date       Description
# ------------------------------------------------------------------------------------------------
# Justin Brown       06/28/22    Recommendation "Ensure ip6tables default deny firewall policy"
#

deb_ensure_ip6tables_default_deny_firewall_policy()
{
	# Start recommendation entriey for verbose log and output to screen
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
	
	deb_firewall_chk()
	{
		echo "- Start - Check to determine Firewall in use on the system" | tee -a "$LOG" 2>> "$ELOG"
		# Firewall Options:
		# Firewalld               - FWd
		# NFTables                - NFt
		# IPTables                - IPt
        # Uncomplicated Fireall   - UFw
		# No firewall installed   - FNi
		# Multiple firewalls used - MFu
		# Firewall Unknown        - UKn	
		G_FWIN=""

		# Check is package manager is defined
		if [ -z "$G_PQ" ] || [ -z "$G_PM" ] || [ -z "$G_PR" ]; then
			nix_package_manager_set
		fi

		# Check FirewallD status
		echo "- Start - Determine FirewallD status" | tee -a "$LOG" 2>> "$ELOG"
		l_fwds=""
		if ! $G_PQ firewalld >/dev/null 2>&1; then
			l_fwds="nnn"
			echo "- FirewallD is not install on the system" | tee -a "$LOG" 2>> "$ELOG"
		else
			echo "- FirewallD is installed on the system"  | tee -a "$LOG" 2>> "$ELOG"
			if systemctl is-enabled firewalld | grep -q 'enabled' && systemctl is-active firewalld | grep -Pq -- '^\s*active'; then
				l_fwds="yyy"
				echo "- FirewallD is installed on the system, is enabled, and is active" | tee -a "$LOG" 2>> "$ELOG"
			elif systemctl is-enabled firewalld | grep -q 'enabled' && ! systemctl is-active firewalld | grep -Pq -- '^\s*active'; then
				l_fwds="yyn"
				echo "- FirewallD is installed on the system, is enabled, but is not active" | tee -a "$LOG" 2>> "$ELOG"
			elif ! systemctl is-enabled firewalld | grep -q 'enabled' && systemctl is-active firewalld | grep -Pq -- '^\s*active'; then
				l_fwds="yny"
				echo "- FirewallD is installed on the system, is disabled, but is active" | tee -a "$LOG" 2>> "$ELOG"
			else
				l_fwds="ynn"
				echo "- FirewallD is installed on the system, is disabled, and is not active"  | tee -a "$LOG" 2>> "$ELOG"
			fi
		fi	
		echo "- End - Determine FirewallD status" | tee -a "$LOG" 2>> "$ELOG"
		
		# Check NFTables status
		echo "- Start - Determine NFTables status" | tee -a "$LOG" 2>> "$ELOG"
		l_nfts=""
		l_nftr=""
		if ! $G_PQ nftables >/dev/null 2>&1; then
			l_nfts="nnn"
			echo "- NFTables is not install on the system" | tee -a "$LOG" 2>> "$ELOG"
		else
			echo "- NFTables is installed on the system"  | tee -a "$LOG" 2>> "$ELOG"
			if systemctl is-enabled nftables | grep -q 'enabled' && systemctl is-active nftables | grep -Pq -- '^\s*active'; then
				l_nfts="yyy"
				echo "- NFTables is installed on the system, is enabled, and is active" | tee -a "$LOG" 2>> "$ELOG"
			elif systemctl is-enabled nftables | grep -q 'enabled' && ! systemctl is-active nftables | grep -Pq -- '^\s*active'; then
				l_nfts="yyn"
				echo "- NFTables is installed on the system, is enabled, but is not active" | tee -a "$LOG" 2>> "$ELOG"
			elif ! systemctl is-enabled nftables | grep -q 'enabled' && systemctl is-active nftables | grep -Pq -- '^\s*active'; then
				l_nfts="yny"
				echo "- NFTables is installed on the system, is disabled, but is active" | tee -a "$LOG" 2>> "$ELOG"
			else
				l_nfts="ynn"
				echo "- NFTables is installed on the system, is disabled, and is not active"  | tee -a "$LOG" 2>> "$ELOG"
			fi
			if [ -n "$(nft list ruleset)" ]; then
				l_nftr="y"
				echo "- NFTables rules exist on the system" | tee -a "$LOG" 2>> "$ELOG"
			fi
		fi
		echo "- End - Determine NFTables status" | tee -a "$LOG" 2>> "$ELOG"
		
		# Check IPTables status
		echo "- Start - Determine IPTables status" | tee -a "$LOG" 2>> "$ELOG"
		l_ipts=""
		l_iptr=""
		if ! $G_PQ iptables >/dev/null 2>&1; then
			l_ipts="nnn"
			echo "- IPTables is not install on the system" | tee -a "$LOG" 2>> "$ELOG"
		else
			echo "- IPTables is installed on the system" | tee -a "$LOG" 2>> "$ELOG"
			if iptables -n -L -v --line-numbers | grep -Eq '^[0-9]+'; then
				l_iptr="y"
				echo "- IPTables rules exist on the system" | tee -a "$LOG" 2>> "$ELOG"
			fi
			if $G_PQ iptables-services >/dev/null 2>&1; then
				echo "- IPTables service package \"iptables-services\" is installed" | tee -a "$LOG" 2>> "$ELOG"
				if systemctl is-enabled iptables | grep -Pq '(enabled|alias)' && systemctl is-active iptables | grep -Pq -- '^\s*active'; then
					l_ipts="yyy"
					echo "- iptables-service is installed on the system, is enabled, and is active" | tee -a "$LOG" 2>> "$ELOG"
				elif systemctl is-enabled iptables | grep -Pq '(enabled|alias)' && ! systemctl is-active iptables | grep -Pq -- '^\s*active'; then
					l_ipts="yyn"
					echo "- iptables-service is installed on the system, is enabled, but is not active" | tee -a "$LOG" 2>> "$ELOG"
				elif ! systemctl is-enabled iptables | grep -Pq '(enabled|alias)' && systemctl is-active iptables | grep -Pq -- '^\s*active'; then
					l_ipts="yny"
					echo "- iptables-service is installed on the system, is disabled, but is active" | tee -a "$LOG" 2>> "$ELOG"
				else
					l_ipts="ynn"
					echo "- iptables-service is installed on the system, is disabled, and is not active"  | tee -a "$LOG" 2>> "$ELOG"
				fi
            elif $G_PQ iptables-persistent >/dev/null 2>&1; then
				echo "- IPTables service package \"iptables-persistent\" is installed" | tee -a "$LOG" 2>> "$ELOG"
				if systemctl is-enabled iptables | grep -Pq '(enabled|alias)' && systemctl is-active iptables | grep -Pq -- '^\s*active'; then
					l_ipts="yyy"
					echo "- iptables-persistent is installed on the system, is enabled, and is active" | tee -a "$LOG" 2>> "$ELOG"
				elif systemctl is-enabled iptables | grep -Pq '(enabled|alias)' && ! systemctl is-active iptables | grep -Pq -- '^\s*active'; then
					l_ipts="yyn"
					echo "- iptables-persistent is installed on the system, is enabled, but is not active" | tee -a "$LOG" 2>> "$ELOG"
				elif ! systemctl is-enabled iptables | grep -Pq '(enabled|alias)' && systemctl is-active iptables | grep -Pq -- '^\s*active'; then
					l_ipts="yny"
					echo "- iptables-persistent is installed on the system, is disabled, but is active" | tee -a "$LOG" 2>> "$ELOG"
				else
					l_ipts="ynn"
					echo "- iptables-persistent is installed on the system, is disabled, and is not active"  | tee -a "$LOG" 2>> "$ELOG"
				fi
			else
				echo "- iptables-service or iptables-persistent is not installed on the system"
				l_ipts="ynn"
			fi	
		fi

        # Check UFW status
		echo "- Start - Determine UFW status" | tee -a "$LOG" 2>> "$ELOG"
		l_ufws=""
		l_ufwr=""
		if ! $G_PQ ufw >/dev/null 2>&1; then
			l_ufws="nnn"
			echo "- UFW is not install on the system" | tee -a "$LOG" 2>> "$ELOG"
		else
			echo "- UFW is installed on the system" | tee -a "$LOG" 2>> "$ELOG"
			if ufw status numbered | grep -Pq '^\h*\[[\h0-9]+'; then
				l_ufwr="y"
				echo "- UFW rules exist on the system" | tee -a "$LOG" 2>> "$ELOG"
			fi
            if systemctl is-enabled ufw | grep -q 'enabled' && (systemctl is-active ufw | grep -Pq -- '^\s*active' || ufw status | grep -Pq -- '^\s*Status:\s+active'); then
                l_ufws="yyy"
                echo "- UFW is installed on the system, is enabled, and is active" | tee -a "$LOG" 2>> "$ELOG"
            elif systemctl is-enabled ufw | grep -q 'enabled' && (! systemctl is-active ufw | grep -Pq -- '^\s*active' || ! ufw status | grep -Pq -- '^\s*Status:\s+active'); then
                l_ufws="yyn"
                echo "- UFW is installed on the system, is enabled, but is not active" | tee -a "$LOG" 2>> "$ELOG"
            elif ! systemctl is-enabled ufw | grep -q 'enabled' && (systemctl is-active ufw | grep -Pq -- '^\s*active' || ufw status | grep -Pq -- '^\s*Status:\s+active'); then
                l_ufws="yny"
                echo "- UFW is installed on the system, is disabled, but is active" | tee -a "$LOG" 2>> "$ELOG"
            else
                l_ufws="ynn"
                echo "- UFW is installed on the system, is disabled, and is not active"  | tee -a "$LOG" 2>> "$ELOG"
            fi
		fi

		echo "- End - Determine UFW status" | tee -a "$LOG" 2>> "$ELOG"
		
		# Determin which firewall is in use
		echo "- Start - Determine which firewall is in use" | tee -a "$LOG" 2>> "$ELOG"
		# Check for no installed firewall
		if [[ "$l_fwds" = "nnn" && "$l_nfts" = "nnn" && "$l_ipts" = "nnn" && "$l_ufws" = "nnn" ]]; then
			G_FWIN="NFi"
		# Check for multiple firewalls
		elif [[ "$l_nftr" = "y" && "$l_iptr" = "y" && ! $l_ufws = "yyy" ]] || [[ "$l_fwds" =~ yy. && "$l_nfts" =~ yy. ]] || [[ "$l_fwds" =~ yy. && "$l_ipts" =~ yy. ]] || [[ "$l_fwds" =~ yy. && "$l_ufws" =~ yy. ]] || [[ "$l_nfts" =~ yy. && "$l_ipts" =~ yy. ]] || [[ "$l_nfts" =~ yy. && "$l_ufws" =~ yy. ]] || [[ "$l_ipts" =~ yy. && "$l_ufws" =~ yy. ]]; then
			G_FWIN="MFu"
		else
			# Check for which firewall
			# Check for FirewallD
			if [[ -z "$G_FWIN" && "$l_fwds" =~ yy. && "$l_nfts" =~ .nn && "$l_ufws" =~ .nn && "$l_ipts" =~ .nn ]] && [[ "$l_nfts" =~ y.. || "$l_ipts" =~ y.. ]]; then
				G_FWIN="FWd"
			fi
			# Check for NFTables
			if [[ -z "$G_FWIN" && "$l_nfts" =~ yy. && "$l_fwds" =~ .nn && "$l_ufws" =~ .nn && "$l_ipts" =~ .nn && -z "$l_iptr" ]]; then
				G_FWIN="NFt"
			fi
			# Check for IPTables
			if [[ -z "$G_FWIN" && "$l_ipts" =~ y.. && "$l_fwds" =~ .nn && "$l_nfts" =~ .nn && "$l_ufws" =~ .nn && -z "$l_nftr" ]]; then
				G_FWIN="IPt"
			fi
            # Check for UFW
			if [[ -z "$G_FWIN" && "$l_ufws" =~ yy. && "$l_fwds" =~ .nn && "$l_nfts" =~ .nn && "$l_ipts" =~ .nn ]]; then
				G_FWIN="UFw"
			fi
		fi
		echo "- End - Determine which firewall is in use" | tee -a "$LOG" 2>> "$ELOG"
		
		# Output results
		case "$G_FWIN" in
			FWd)
				echo "- Firewall determined to be FirewallD. Checks for NFTables, IPTables and Uncomplicated Firewall will be marked as Non Applicable" | tee -a "$LOG" 2>> "$ELOG"
				;;
			NFt)
				echo "- Firewall determined to be NFTables. Checks for FirewallD, IPTables and Uncomplicated Firewall will be marked as Non Applicable" | tee -a "$LOG" 2>> "$ELOG"
				;;
            UFw)
				echo "- Firewall determined to be Uncomplicated Firewall. Checks for FirewallD, NFTables and IPTables will be marked as Non Applicable" | tee -a "$LOG" 2>> "$ELOG"
				;;
			IPt)
				echo "- Firewall determined to be IPTables. Checks for FirewallD, NFTables and Uncomplicated Firewall will be marked as Non Applicable" | tee -a "$LOG" 2>> "$ELOG"
				;;
			NFi)
				echo "- No firewall is installed on the system. Firewall recommendations will be marked as MANUAL" | tee -a "$LOG" 2>> "$ELOG"
				G_FWIN="UKn"
				;;
			MFu)
				echo "- Multiple firewalls in use on the system. Firewall recommendations will be marked as MANUAL" | tee -a "$LOG" 2>> "$ELOG"
				G_FWIN="UKn"
				;;
			*)
				echo "- Unable to determine firewall. Firewall recommendations will be marked as MANUAL" | tee -a "$LOG" 2>> "$ELOG"
				G_FWIN="UKn"
				;;
		esac
		export G_FWIN
		echo "- End - Check to determine Firewall in use on the system" | tee -a "$LOG" 2>> "$ELOG"
	}
   
	ipv6_chk()
	{
		l_passing="" G_IPV6=""
		
		grubfile="$(find /boot -type f \( -name 'grubenv' -o -name 'grub.conf' -o -name 'grub.cfg' \) \
		-exec grep -Pl -- '^\h*(kernelopts=|linux|kernel)' {} \;)"
		
		! grep -P -- "^\h*(kernelopts=|linux|kernel)" "$grubfile" | grep -vq -- ipv6.disable=1 && l_passing="true"
		
		grep -Pq -- "^\s*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\h*(#.*)?$" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf && grep -Pq -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\h*(#.*)?$" /etc/sysctl.conf /etc/sysctl.d/*.conf /usr/lib/sysctl.d/*.conf /run/sysctl.d/*.conf && sysctl net.ipv6.conf.all.disable_ipv6 | grep -Pq -- "^\h*net\.ipv6\.conf\.all\.disable_ipv6\h*=\h*1\h*(#.*)?$" &&     sysctl net.ipv6.conf.default.disable_ipv6 | grep -Pq -- "^\h*net\.ipv6\.conf\.default\.disable_ipv6\h*=\h*1\h*(#.*)?$" && l_passing="true"
		
		if [ "$l_passing" = true ] ; then
			echo -e "\nIPv6 is disabled on the system\n"
			export G_IPV6=false
		else
			echo -e "\nIPv6 is enabled on the system\n"
			export G_IPV6=true
		fi
	}
	
	deb_ensure_ip6tables_default_deny_firewall_policy_chk()
	{
		echo "- Start check - Ensure ip6tables default deny firewall policy" | tee -a "$LOG" 2>> "$ELOG"
		l_input_default_deny="" l_forward_default_deny="" l_output_default_deny="" l_ruleset=""
		            
		# Collect iptables rules
		l_input_default_deny=$(ip6tables -L | grep -Pi '^\s*chain\s+input\s+' | grep -Piv 'policy\s+drop')
		l_forward_default_deny=$(ip6tables -L | grep -Pi '^\s*chain\s+forward\s+' | grep -Piv 'policy\s+drop')
		l_output_default_deny=$(ip6tables -L | grep -Pi '^\s*chain\s+output\s+' | grep -Piv 'policy\s+drop')
			
		# Check chain defaults
		if [ -z "$l_input_default_deny" ]; then
			echo -e "- All input chains enforce default deny" | tee -a "$LOG" 2>> "$ELOG"
			if [ -z "$l_forward_default_deny" ]; then
				echo -e "- All forward chains enforce default deny" | tee -a "$LOG" 2>> "$ELOG"
				if [ -z "$l_output_default_deny" ]; then
				echo -e "- All output chains enforce default deny" | tee -a "$LOG" 2>> "$ELOG"
				l_ruleset=passed
				else
				echo -e "- Some output chains do NOT enforce default deny:\n $l_output_default_deny" | tee -a "$LOG" 2>> "$ELOG"
				fi
			else
				echo -e "- Some forward chains do NOT enforce default deny:\n $l_forward_default_deny" | tee -a "$LOG" 2>> "$ELOG"
			fi
		else
			echo -e "- Some input chains do NOT enforce default deny:\n $l_input_default_deny" | tee -a "$LOG" 2>> "$ELOG"
		fi
		
		# if ruleset passes, we pass
		if [ "$l_ruleset" = passed ]; then
			echo -e "- All chains enforce a default deny policy" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure ip6tables default deny firewall policy" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_PASS:-101}"
		else
			# print the reason why we are failing
			echo -e "- Some chains do NOT enforce a default deny policy" | tee -a "$LOG" 2>> "$ELOG"
			echo -e "- End check - Ensure ip6tables default deny firewall policy" | tee -a "$LOG" 2>> "$ELOG"
			return "${XCCDF_RESULT_FAIL:-102}"
		fi
	}
	
	deb_ensure_ip6tables_default_deny_firewall_policy_fix()
	{
		echo -e "- Start remediation - Ensure ip6tables default deny firewall policy" | tee -a "$LOG" 2>> "$ELOG"

		echo -e "- Update the chains to enforce a default policy of drop." | tee -a "$LOG" 2>> "$ELOG"
		echo -e "- These example rules can be used if desired:\n ip6tables -P INPUT DROP\n ip6tables -P OUTPUT DROP\n ip6tables -P FORWARD DROP" | tee -a "$LOG" 2>> "$ELOG"
		test=manual
      
		echo -e "- End remediation - Ensure ip6tables default deny firewall policy" | tee -a "$LOG" 2>> "$ELOG"
	}

	# Set firewall applicability
	[ -z "$G_FWIN" ] && deb_firewall_chk
	# Set IPv6 applicability
	[ -z "$G_IPV6" ] && ipv6_chk
	# Check to see if recommendation is applicable
   	echo "- Firewall is: $G_FWIN" | tee -a "$LOG" 2>> "$ELOG"
	if [ "$G_FWIN" = "UKn" ]; then
		echo "- Firewall is unknown, Manual review is required" | tee -a "$LOG" 2>> "$ELOG"
		test="manual"
	elif [ "$G_FWIN" != "IPt" ]; then
		echo "- IPTables is not in use on the system, recommendation is not applicable" | tee -a "$LOG" 2>> "$ELOG"
		test="NA"
   elif [ "$G_IPV6" = false ]; then
		echo "- IPv6 is not in use on the system, recommendation is not applicable" | tee -a "$LOG" 2>> "$ELOG"
		test="NA"
	else
		deb_ensure_ip6tables_default_deny_firewall_policy_chk
		if [ "$?" = "101" ]; then
			[ -z "$test" ] && test="passed"
		else
			deb_ensure_ip6tables_default_deny_firewall_policy_fix
			deb_ensure_ip6tables_default_deny_firewall_policy_chk
			if [ "$?" = "101" ]; then
				[ "$test" != "failed" ] && test="remediated"
			fi
		fi
	fi

	# Set return code, end recommendation entry in verbose log, and return
	case "$test" in
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