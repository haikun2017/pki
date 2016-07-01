#!/bin/sh
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/dogtag/acceptance/cli-tests/pki-tps-group-cli
#   Description: PKI tps-group-find CLI tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following pki cli commands needs to be tested:
#  pki-tps-group-cli-tps-group-find  To  list  groups in TPS.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Authors: Roshni Pattath <rpattath@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include rhts environment
. /usr/bin/rhts-environment.sh
. /usr/share/beakerlib/beakerlib.sh
. /opt/rhqa_pki/rhcs-shared.sh
. /opt/rhqa_pki/pki-cert-cli-lib.sh
. /opt/rhqa_pki/env.sh

########################################################################
# Test Suite Globals
########################################################################

run_pki-tps-group-cli-tps-group-find_tests(){
#### Create Temporary directory ####    

     rlPhaseStartSetup "pki_tps_group_cli_tps_group_add-startup: Create temporary directory"
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd
subsystemId=$1
SUBSYSTEM_TYPE=$2
MYROLE=$3
caId=$4
CA_HOST=$5
get_topo_stack $MYROLE $TmpDir/topo_file
        local TPS_INST=$(cat $TmpDir/topo_file | grep MY_TPS | cut -d= -f2)
        tps_instance_created="False"
        if [ "$TOPO9" = "TRUE" ] ; then
                prefix=$TPS_INST
                tps_instance_created=$(eval echo \$${prefix}_INSTANCE_CREATED_STATUS)
        elif [ "$MYROLE" = "MASTER" ] ; then
                prefix=TPS1
                tps_instance_created=$(eval echo \$${prefix}_INSTANCE_CREATED_STATUS)
        else
                prefix=$MYROLE
                tps_instance_created=$(eval echo \$${prefix}_INSTANCE_CREATED_STATUS)
        fi
if [ "$tps_instance_created" = "TRUE" ];  then
TPS_HOST=$(eval echo \$${MYROLE})
TPS_PORT=$(eval echo \$${subsystemId}_UNSECURE_PORT)
CA_PORT=$(eval echo \$${caId}_UNSECURE_PORT)
eval ${subsystemId}_adminV_user=${subsystemId}_adminV
eval ${subsystemId}_adminR_user=${subsystemId}_adminR
eval ${subsystemId}_adminE_user=${subsystemId}_adminE
eval ${subsystemId}_adminUTCA_user=${subsystemId}_adminUTCA
eval ${subsystemId}_agentV_user=${subsystemId}_agentV
eval ${subsystemId}_agentR_user=${subsystemId}_agentR
eval ${subsystemId}_agentE_user=${subsystemId}_agentE
eval ${subsystemId}_officerV_user=${subsystemId}_officerV
eval ${subsystemId}_operatorV_user=${subsystemId}_operatorV
ROOTCA_agent_user=${caId}_agentV
    rlPhaseStartSetup "pki_tps_group_cli_tps_group_find-startup: Create temporary directory and add groups"
        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
	i=1
        while [ $i -lt 25 ] ; do
               rlRun "pki -d $CERTDB_DIR \
			   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-add --description=test_group g$i"
                let i=$i+1
        done
    rlPhaseEnd

local TEMP_NSS_DB="$TmpDir/nssdb"
local TEMP_NSS_DB_PASSWD="redhat123"
local cert_info="$TmpDir/cert_info"

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-configtest-001: pki tps-group-find --help configuration test"
        rlRun "pki tps-group-find --help > $TmpDir/tps_group_find.out 2>&1" 0 "pki tps-group-find --help"
        rlAssertGrep "usage: tps-group-find \[FILTER\] \[OPTIONS...\]" "$TmpDir/tps_group_find.out"
        rlAssertGrep "\--size <size>     Page size" "$TmpDir/tps_group_find.out"
        rlAssertGrep "\--start <start>   Page start" "$TmpDir/tps_group_find.out"
        rlAssertGrep "\--help            Show help options" "$TmpDir/tps_group_find.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-configtest-002: pki tps-group-find configuration test"
	command="pki tps-group-find"
	errmsg="ProcessingException: Unable to invoke request"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - pki tps-group-find"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-003: Find 5 groups, --size=5"
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --size=5  > $TmpDir/pki-tps-group-find-001.out 2>&1" \
                         0 \
                        "Found 5 groups"
	rlAssertGrep "Number of entries returned 5" "$TmpDir/pki-tps-group-find-001.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-004: Find no group, --size=0"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --size=0  > $TmpDir/pki-tps-group-find-002.out 2>&1" \
                    0 \
                    "Found no groups"
        rlAssertGrep "Number of entries returned 0" "$TmpDir/pki-tps-group-find-002.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-005: Find all groups, large value as input"
        large_num=1000000
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --size=$large_num  > $TmpDir/pki-tps-group-find-003.out 2>&1" \
                         0 \ 
                    "Find all groups, large value as input"
	result=`cat $TmpDir/pki-tps-group-find-003.out | grep "Number of entries returned"`
        number=`echo $result | cut -d " " -f 5`
        if [ $number -gt 25 ] ; then
                rlPass "Number of entries returned is more than 25 as expected"
        else

                rlFail "Number of entries returned is not expected, Got: $number, Expected: > 25"
        fi
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-006: Find all groups, --size with maximum possible value as input"
	randhex=$(openssl rand -hex 3 |  perl -p -e 's/\n//')
        randhex_covup=${randhex^^}
	maximum_check=$(echo "ibase=16;$randhex_covup" | BC_LINE_LENGTH=0 bc)
	rlLog "$maximum_check"
	rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --size=$maximum_check"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --size=$maximum_check  > $TmpDir/pki-tps-group-find-003_2.out 2>&1" \
                   0 \
                   "Find all groups, maximum possible value as input"
	result=`cat $TmpDir/pki-tps-group-find-003_2.out | grep "Number of entries returned"`
	number=`echo $result | cut -d " " -f 5`	
	if [ $number -gt 25 ] ; then
        	rlPass "Number of entries returned is more than 25 as expected"
	else
	
        	rlFail "Number of entries returned is not expected, Got: $number, Expected: > 25"
	fi
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-007: Find all groups, --size more than maximum possible value"
	randhex=$(openssl rand -hex 12 |  perl -p -e 's/\n//')
	randhex_covup=${randhex^^}
        maximum_check=$(echo "ibase=16;$randhex_covup"|bc)
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --size=$maximum_check"
	errmsg="NumberFormatException: For input string: $maximum_check"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - More than maximum possible value as input should fail"	
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-008: Find groups, check for negative input --size=-1"
	command="pki -d $CERTDB_DIR  -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --size=-1"
	errmsg="size should not have value less than 0"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - size with negative value should fail"
	rlLog "FAIL: https://fedorahosted.org/pki/ticket/861"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-009: Find groups for size input as noninteger, --size=abc"
        size_noninteger="abc"
	command="pki -d $CERTDB_DIR  -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --size=$size_noninteger"
	errmsg="NumberFormatException: For input string: $size_noninteger"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - size with characters should fail"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-010: Find groups, check for no input --size="
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --size="
	errmsg="NumberFormatException: For input string: \"""\""
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - size with empty value should fail"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-011: Find groups, --start=10"
	#Find the 10th group
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find  > $TmpDir/pki-tps-group-find-007_1.out 2>&1" \
                   0 \
                   "Get all groups in TPS"
	group_entry_10=`cat $TmpDir/pki-tps-group-find-007_1.out | grep "Group ID" | head -11 | tail -1`
	rlLog "10th entry=$group_entry_10"

	rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --start=10"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --start=10  > $TmpDir/pki-tps-group-find-007.out 2>&1" \
                   0 \
                   "Displays groups from the 10th group and the next to the maximum 20 groups, if available "
	#First group in the response should be the 10th group $group_entry_10
	group_entry_1=`cat $TmpDir/pki-tps-group-find-007.out | grep "Group ID" | head -1`
	rlLog "1st entry=$group_entry_1"
	if [ "$group_entry_1" = "$group_entry_10" ]; then
		rlPass "Displays groups from the 10th group"
	else
		rlFail "Display did not start from the 10th group"
	fi
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-012: Find groups, --start=10000, large possible input"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --start=10000  > $TmpDir/pki-tps-group-find-008.out 2>&1" \
                    0 \
                   "Find users, --start=10000, large possible input"
        rlAssertGrep "Number of entries returned 0" "$TmpDir/pki-tps-group-find-008.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-013: Find groups, --start with maximum possible input"
	randhex=$(openssl rand -hex 3 |  perl -p -e 's/\n//')
        randhex_covup=${randhex^^}
        maximum_check=$(echo "ibase=16;$randhex_covup"|bc)
	rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --start=$maximum_check"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --start=$maximum_check  > $TmpDir/pki-tps-group-find-008_2.out 2>&1" \
                    0 \
                   "Find groups, --start with maximum possible input"
        rlAssertGrep "Number of entries returned 0" "$TmpDir/pki-tps-group-find-008_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-014: Find groups, --start with more than maximum possible input"
	randhex=$(openssl rand -hex 12 |  perl -p -e 's/\n//')
        randhex_covup=${randhex^^}
        maximum_check=$(echo "ibase=16;$randhex_covup"|bc)
	command="pki -d $CERTDB_DIR  -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=$maximum_check"
	errmsg="NumberFormatException: For input string: \"$maximum_check\""
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Find users, --start with more than maximum possible input should fail"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-015: Find groups, --start=0"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --start=0  > $TmpDir/pki-tps-group-find-009.out 2>&1" \
                     0 \
                     "Displays from the zeroth user, maximum possible are 20 users in a page"
        rlAssertGrep "Number of entries returned 20" "$TmpDir/pki-tps-group-find-009.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-016: Find groups, --start=-1"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=-1"
        errmsg="start should not have value less than 0"
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - start with negative value should fail"
        rlLog "FAIL: https://fedorahosted.org/pki/ticket/929"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-017: Find groups for size input as noninteger, --start=abc"
        size_noninteger="abc"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=$size_noninteger"
	errmsg="NumberFormatException: For input string: \"$size_noninteger\""
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - start with non integer value should fail"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-018: Find groups, check for no input --start= "
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start="
	errmsg="NumberFormatException: For input string: \"""\""
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - start with empty value should fail"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-019: Find groups, --size=12 --start=12"
        #Find 12 groups starting from 12th group
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find  > $TmpDir/pki-tps-group-find-00_13_1.out 2>&1" \
                     0 \
                   "Get all groups in TPS"
        group_entry_12=`cat $TmpDir/pki-tps-group-find-00_13_1.out | grep "Group ID" | head -13 | tail -1`

        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --start=12 --size=12  > $TmpDir/pki-tps-group-find-0013.out 2>&1" \
                   0 \
                   "Displays groups from the 12th group and the next to the maximum 12 groups"
        #First group in the response should be the 12th group $group_entry_12
        group_entry_1=`cat  $TmpDir/pki-tps-group-find-0013.out | grep "Group ID" | head -1`
        if [ "$group_entry_1" = "$group_entry_12" ]; then
                rlPass "Displays groups from the 12th group"
        else
                rlFail "Display did not start from the 12th group"
        fi
        rlAssertGrep "Number of entries returned 12" "$TmpDir/pki-tps-group-find-0013.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-020: Find groups, --size=0 --start=12"
        #Find 12 groups starting from 12th group
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find  > $TmpDir/pki-tps-group-find-00_14_1.out 2>&1" \
                  0 \
                        "Get all groups in TPS"
        group_entry_12=`cat $TmpDir/pki-tps-group-find-00_14_1.out | grep "Group ID" | head -13 | tail -1`

        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   tps-group-find --start=12 --size=0  > $TmpDir/pki-tps-group-find-0014.out 2>&1" \
                    0 \
                   "Displays groups from the 12th group and 0 groups"
        rlAssertGrep "Number of entries returned 0" "$TmpDir/pki-tps-group-find-0014.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-021: Should not be able to find group using a revoked cert TPS_adminR"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminR_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="PKIException: Unauthorized"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find users using a revoked admin cert"
	rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1134"
        rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1182"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-022: Should not be able to find groups using an agent with revoked cert TPS_agentR"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_agentR_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="PKIException: Unauthorized"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find users using a revoked agent cert"
	rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1134"
        rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1182"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-023: Should not be able to find groups using a valid agent TPS_agentV user"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_agentV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find groups using a valid agent cert"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-024: Should not be able to find groups using admin user with expired cert TPS_adminE"
        rlRun "date --set='next day'" 0 "Set System date a day ahead"
	rlRun "date --set='next day'" 0 "Set System date a day ahead"
	rlRun "date"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminE_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find groups using a expired admin cert"
        rlRun "date --set='2 days ago'" 0 "Set System back to the present day"
	rlLog "FAIL: https://fedorahosted.org/pki/ticket/962"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-025: Should not be able to find groups using TPS_agentE cert"
        rlRun "date --set='next day'" 0 "Set System date a day ahead"
	rlRun "date --set='next day'" 0 "Set System date a day ahead"
	rlRun "date"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_agentE_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find groups using a expired agent cert"
        rlRun "date --set='2 days ago'" 0 "Set System back to the present day"
	rlLog "FAIL: https://fedorahosted.org/pki/ticket/962"
    rlPhaseEnd

     rlPhaseStartTest "pki_tps_group_cli_tps_group_find-026: Should not be able to find groups using a TPS_officerV"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_officerV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find groups using a valid officer cert"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-027: Should not be able to find groups using a TPS_operatorV"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_operatorV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find groups using a valid operator cert"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-028: Should not be able to find groups using a cert created from a untrusted CA TPS_adminUTCA"
	command="pki -d $UNTRUSTED_CERT_DB_LOCATION -n role_user_UTCA -c $UNTRUSTED_CERT_DB_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find --start=1 --size=5"
	errmsg="PKIException: Unauthorized"
	errocode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to find groups using TPS_adminUTCA"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-029: Should not be able to find groups using a user cert"
	#Create a user cert
	rlRun "generate_new_cert tmp_nss_db:$TEMP_NSS_DB tmp_nss_db_pwd:$TEMP_NSS_DB_PASSWD request_type:pkcs10 \
        algo:rsa key_size:2048 subject_cn:\"pki User1\" subject_uid:pkiUser1 subject_email:pkiuser1@example.org \
        organizationalunit:Engineering organization:Example.Inc country:US archive:false req_profile:caUserCert \
        target_host:$CA_HOST protocol: port:$CA_PORT cert_db_dir:$CERTDB_DIR cert_db_pwd:$CERTDB_DIR_PASSWORD \
        certdb_nick:\"$ROOTCA_agent_user\" cert_info:$cert_info"
        local valid_pkcs10_serialNumber=$(cat $cert_info| grep cert_serialNumber | cut -d- -f2)
        local valid_decimal_pkcs10_serialNumber=$(cat $cert_info| grep decimal_valid_serialNumber | cut -d- -f2)
        rlRun "pki -h $CA_HOST -p $CA_PORT cert-show $valid_pkcs10_serialNumber --encoded > $TmpDir/pki_tps_group_find_encoded_0029pkcs10.out" 0 "Executing pki cert-show $valid_pkcs10_serialNumber"
        rlRun "sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' $TmpDir/pki_tps_group_find_encoded_0029pkcs10.out > $TmpDir/pki_tps_group_find_encoded_0029pkcs10.pem"
	rlRun "certutil -d $TEMP_NSS_DB -A -n \"casigningcert\" -i $CERTDB_DIR/ca_cert.pem -t \"CT,CT,CT\""
	rlRun "certutil -d $TEMP_NSS_DB -A -n pkiUser1 -i $TmpDir/pki_tps_group_find_encoded_0029pkcs10.pem  -t "u,u,u""
	rlLog "Executing: pki -d $TEMP_NSS_DB \
                   -n pkiUser1 \
                   -c $TEMP_NSS_DB_PASSWD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-find --start=1 --size=5"
        rlRun "pki -d $TEMP_NSS_DB \
                   -n pkiUser1 \
                   -c $TEMP_NSS_DB_PASSWD \
		   -h $TPS_HOST \
		   -p $TPS_PORT \
                    tps-group-find --start=1 --size=5 >  $TmpDir/pki-tps-group-find-pkiUser1-002.out 2>&1" 255 "Should not be able to find groups using a user cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-tps-group-find-pkiUser1-002.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-030: find groups when group id has i18n characters"
	rlLog "pki -d $CERTDB_DIR \
                   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description='Örjan Äke' 'ÖrjanÄke'"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description='Örjan Äke' 'ÖrjanÄke' > $TmpDir/pki-tps-group-find-001_31.out 2>&1" \
                    0 \
                    "Adding gid ÖrjanÄke with i18n characters"
        rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --size=1000"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --size=1000 > $TmpDir/pki-tps-group-show-001_31_2.out" \
                    0 \
                    "Find group with max size"
        rlAssertGrep "Group ID: ÖrjanÄke" "$TmpDir/pki-tps-group-show-001_31_2.out"
        rlAssertGrep "Description: Örjan Äke" "$TmpDir/pki-tps-group-show-001_31_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_find-031: find group when group id has i18n characters"
	rlLog "pki -d $CERTDB_DIR \
                   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description='Éric Têko' 'ÉricTêko'"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description='Éric Têko' 'ÉricTêko' > $TmpDir/pki-tps-group-show-001_32.out 2>&1" \
                    0 \
                    "Adding group id ÉricTêko with i18n characters"
        rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --size=1000"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find --size=1000 > $TmpDir/pki-tps-group-show-001_32_2.out" \
                    0 \
                    "Find group with max size"
        rlAssertGrep "Group ID: ÉricTêko" "$TmpDir/pki-tps-group-show-001_32_2.out"
        rlAssertGrep "Description: Éric Têko" "$TmpDir/pki-tps-group-show-001_32_2.out"
    rlPhaseEnd
	
	#pki group-find with filters

	rlPhaseStartTest "pki_tps_group_cli_tps_group_find-032: find group - filter 'Administrator'"
        rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find Administrator"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-find Administrator > $TmpDir/pki-tps-group-show-033.out" \
                    0 \
                    "Find group with Keyword Administrator"
	rlAssertGrep "Group ID: Administrators" "$TmpDir/pki-tps-group-show-033.out"
    rlPhaseEnd

	rlPhaseStartTest "pki_tps_group_cli_tps_group_find-033: find group should fail when filter keyword has less than 3 characters"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-find CA"
	errmsg="BadRequestException: Filter is too short."
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - pki tps-group-find should fail if the filter has less than 3 characters"	
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_group_cleanup-001: Deleting groups"
        #===Deleting groups created using TPS_adminV cert===#
        i=1
        while [ $i -lt 25 ] ; do
               rlRun "pki -d $CERTDB_DIR \
			  -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del  g$i > $TmpDir/pki-group-del-tps-group-00$i.out" \
                           0 \
                           "Deleted group  g$i"
                rlAssertGrep "Deleted group \"g$i\"" "$TmpDir/pki-group-del-tps-group-00$i.out"
                let i=$i+1
        done

	#===Deleting i18n groups created using TPS_adminV cert===#
        rlRun "pki -d $CERTDB_DIR \
		-n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                tps-group-del 'ÖrjanÄke' > $TmpDir/pki-group-del-tps-group-i18n_1.out" \
                0 \
                "Deleted group ÖrjanÄke"
        rlAssertGrep "Deleted group \"ÖrjanÄke\"" "$TmpDir/pki-group-del-tps-group-i18n_1.out"

        rlRun "pki -d $CERTDB_DIR \
		-n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
              tps-group-del 'ÉricTêko' > $TmpDir/pki-group-del-tps-group-i18n_2.out" \
                0 \
                "Deleted group ÉricTêko"
        rlAssertGrep "Deleted group \"ÉricTêko\"" "$TmpDir/pki-group-del-tps-group-i18n_2.out"

	#Delete temporary directory
	rlRun "popd"
	rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
else
        rlPhaseStartCleanup "pki tps-group-find cleanup: Delete temp dir"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlLog "TPS subsystem is not installed"
        rlPhaseEnd
fi
}
