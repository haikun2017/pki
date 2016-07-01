#!/bin/sh
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /CoreOS/dogtag/acceptance/cli-tests/pki-tps-group-cli
#   Description: PKI tps-group-del CLI tests
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following pki cli commands needs to be tested:
#  pki-tps-group-cli-tps-group-del   Delete pki subsystem groups.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Author: Roshni Pattath <rpattath@redhat.com>
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

run_pki-tps-group-cli-tps-group-del_tests(){

    rlPhaseStartSetup "pki_tps_group_cli_tps_group_del-startup: Create temporary directory"
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
local TEMP_NSS_DB="$TmpDir/nssdb"
local TEMP_NSS_DB_PASSWD="redhat123"
local cert_info="$TmpDir/cert_info"
ROOTCA_agent_user=${caId}_agentV
    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-configtest-001: pki tps-group-del --help configuration test"
        rlRun "pki tps-group-del --help > $TmpDir/tps_group_del.out 2>&1" 0 "pki tps-group-del --help"
        rlAssertGrep "usage: tps-group-del <Group ID>" "$TmpDir/tps_group_del.out"
        rlAssertGrep "\--help   Show help options" "$TmpDir/tps_group_del.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-configtest-002: pki tps-group-del configuration test"
        rlRun "pki tps-group-del > $TmpDir/tps_group_del_2.out 2>&1" 255 "pki tps-group-del"
        rlAssertGrep "usage: tps-group-del <Group ID>" "$TmpDir/tps_group_del_2.out"
        rlAssertGrep " --help   Show help options" "$TmpDir/tps_group_del_2.out"
	rlAssertNotGrep "ResteasyIOException: IOException" "$TmpDir/tps_group_del_2.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-003: Delete valid groups" 
	group1=tps_group
	group1desc="Test group"
	group2=abcdefghijklmnopqrstuvwxyx12345678
	group3=abc#
	group4=abc$
	group5=abc@
	group6=abc?
	group7=0
	#positive test cases
	#Add groups to TPS using TPS_adminV cert
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

	#===Deleting groups created using TPS_adminV cert===#
	i=1
	while [ $i -lt 25 ] ; do
	       rlLog "pki -d $CERTDB_DIR \
			  -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del  g$i"
               rlRun "pki -d $CERTDB_DIR \
			  -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del  g$i > $TmpDir/pki-tps-group-del-group1-00$i.out" \
                           0 \
                           "Deleted group g$i"
		rlAssertGrep "Deleted group \"g$i\"" "$TmpDir/pki-tps-group-del-group1-00$i.out"
	   	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-show g$i"
		errmsg="GroupNotFoundException: Group g$i not found"
		errorcode=255
		rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - deleted group should not exist"
                let i=$i+1
        done
	#Add groups to TPS using TPS_adminV cert
        i=1
        while [ $i -lt 8 ] ; do
	       eval grp=\$group$i
               rlRun "pki -d $CERTDB_DIR \
			   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-add --description=test_group $grp"
                let i=$i+1
        done

        #===Deleting groups(symbols) created using TPS_adminV cert===#
	j=1
        while [ $j -lt 8 ] ; do
	       eval grp=\$group$j
	       rlLog "pki -d $CERTDB_DIR \
			  -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del $grp "
               rlRun "pki -d $CERTDB_DIR \
			  -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del $grp > $TmpDir/pki-tps-group-del-group2-00$j.out" \
			   0 \
			   "Deleted group $grp"
		rlAssertGrep "Deleted group \"$grp\"" "$TmpDir/pki-tps-group-del-group2-00$j.out"
	   	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-show $grp"
		errmsg="GroupNotFoundException: Group $grp not found"
		errorcode=255
		rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - deleted group should not exist"
                let j=$j+1
        done
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-004: Case sensitive groupid"
	rlRun "pki -d $CERTDB_DIR \
			   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-add --description=test_group group_abc"
	rlRun "pki -d $CERTDB_DIR \
			   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del GROUP_ABC > $TmpDir/pki-tps-group-del-group-002_1.out" \
                           0 \
                           "Deleted group GROUP_ABC groupid is not case sensitive"
        rlAssertGrep "Deleted group \"GROUP_ABC\"" "$TmpDir/pki-tps-group-del-group-002_1.out"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-show group_abc"
	errmsg="GroupNotFoundException: Group group_abc not found"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - deleted group group_abc should not exist"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-005: Delete group when required option group id is missing"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del"
	errmsg="Error: No Group ID specified."
        errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Cannot delete a group without groupid"
    rlPhaseEnd
  
    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-006: Maximum length of group id"
	group2=$(openssl rand -hex 2048 |  perl -p -e 's/\n//')
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description=test \"$group2\" > $TmpDir/pki-tps-group-add-001_1.out" \
                    0 \
                    "Added group using TPS_adminV with maximum group id length"
	rlRun "pki -d $CERTDB_DIR \
			   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del \"$group2\" > $TmpDir/pki-tps-group-del-group-006.out" \
                           0 \
                           "Deleting group with maximum group id length using TPS_adminV"
	actual_groupid_string=`cat $TmpDir/pki-tps-group-del-group-006.out | grep 'Deleted group' | xargs echo`
        expected_groupid_string="Deleted group $group2"  
	if [[ $actual_groupid_string = $expected_groupid_string ]] ; then
                rlPass "Deleted group \"$group2\" found"
        else
                rlFail "Deleted group \"$group2\" not found"
        fi
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-show \"$group2\""
        errmsg="GroupNotFoundException: Group \"$group2\" not found"
	errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - deleted group with max length should not exist"
    rlPhaseEnd 
    
    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-007: groupid with maximum length and symbols"
	rand_groupid=$(openssl rand -base64 2048 |  perl -p -e 's/\n//')
	groupid=$(echo $rand_groupid | sed 's/\///g')
        rlRun "pki -d $CERTDB_DIR \
		    -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description=test '$groupid' > $TmpDir/pki-tps-group-add-001_8.out" \
                    0 \
                    "Added group using TPS_adminV with maximum groupid length and character symbols in it"
	rlRun "pki -d $CERTDB_DIR \
			   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-del '$groupid' > $TmpDir/pki-tps-group-del-group-007.out" \
                           0 \
                           "Deleting group with maximum group id length and character symbols using TPS_adminV"
	actual_groupid_string=`cat $TmpDir/pki-tps-group-del-group-007.out| grep 'Deleted group' | xargs echo`
        expected_groupid_string="Deleted group $groupid"
	if [[ $actual_groupid_string = $expected_groupid_string ]] ; then
                rlPass "Deleted group $groupid found"
        else
                rlFail "Deleted group $groupid not found"
        fi
	rlRun "pki -d $CERTDB_DIR \
			   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                           tps-group-show '$groupid'  > $TmpDir/pki-tps-group-del-group-007_2.out 2>&1" \
                           255 \
                           "Verify expected error message - deleted group with max length and character symbols should not exist"
        actual_error_string=`cat $TmpDir/pki-tps-group-del-group-007_2.out| grep 'GroupNotFoundException:' | xargs echo`
        expected_error_string="GroupNotFoundException: Group $groupid not found"
	if [[ $actual_error_string = $expected_error_string ]] ; then
                rlPass "GroupNotFoundException: Group $groupid not found message found"
        else
                rlFail "GroupNotFoundException: Group $groupid not found message not found"
        fi
     rlPhaseEnd
    
    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-008: Delete group from TPS with -t option"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
		    -t tps \
                    tps-group-add --description=\"g1description\" g1 > $TmpDir/pki-tps-group-add-009.out" \
                    0 \
                    "Add group g1 to TPS"
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                   -t tps \
                    group-del g1 > $TmpDir/pki-tps-group-del-group-009.out" \
                    0 \
                    "Deleting group g1 using -t tps option" 
	rlAssertGrep "Deleted group \"g1\"" "$TmpDir/pki-tps-group-del-group-009.out"
        command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-show g1"
        errmsg="GroupNotFoundException: Group g1 not found"
	errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - deleted group g1 should not exist"	
    rlPhaseEnd 
     
    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-009: Should not be able to delete group using a revoked cert TPS_adminR"
	#Add a group
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description=\"g2description\" g2 > $TmpDir/pki-group-add-tps-010.out" \
                    0 \
                    "Add group g2 to TPS"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminR_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g2"
	errmsg="PKIException: Unauthorized"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g2 using a admin having a revoked cert"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g2 > $TmpDir/pki-tps-group-show-001.out" \
		    0 \
		    "Show group g2"
        rlAssertGrep "Group \"g2\"" "$TmpDir/pki-tps-group-show-001.out"
        rlAssertGrep "Group ID: g2" "$TmpDir/pki-tps-group-show-001.out"
        rlAssertGrep "Description: g2description" "$TmpDir/pki-tps-group-show-001.out"
	rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1134"
        rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1182"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-010: Should not be able to delete group using a agent with revoked cert TPS_agentR"
	#Add a group
        rlRun "pki -d $CERTDB_DIR \
                   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-add --description=\"g3description\" g3 > $TmpDir/pki-group-add-tps-010.out" \
                    0 \
                    "Add group g3 to TPS"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_agentR_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g3"
	errmsg="PKIException: Unauthorized"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g3 using a agent having a revoked cert"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-tps-group-show-002.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-tps-group-show-002.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-tps-group-show-002.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-tps-group-show-002.out"
	rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1134"
        rlLog "PKI Ticket: https://fedorahosted.org/pki/ticket/1182"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-011: Should not be able to delete group using a valid agent TPS_agentV user"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_agentV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g3"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g3 using a valid agent cert"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-tps-group-show-003.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-tps-group-show-003.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-tps-group-show-003.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-tps-group-show-003.out"
    rlPhaseEnd
    
    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-012: Should not be able to delete group using a admin user with expired cert TPS_adminE"
	#Set datetime 2 days ahead
        rlRun "date --set='+2 days'" 0 "Set System date 2 days ahead"
	rlRun "date"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminE_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g3"
	errmsg="ForbiddenException: Authorization Error" 
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g3 using an expired admin cert"
	#Set datetime back on original
        rlRun "date --set='-2 days'" 0 "Set System back to the present day"
	rlLog "PKI TICKET :: https://engineering.redhat.com/trac/pki-tests/ticket/962"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-group-show-tps-004.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-group-show-tps-004.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-group-show-tps-004.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-group-show-tps-004.out"
    rlPhaseEnd 

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-013: Should not be able to delete a group using TPS_agentE cert"
	rlRun "date --set='+2 days'" 0 "Set System date 2 days ahead"
        rlRun "date"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_agentE_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g3"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g3 using a agent cert"

        rlLog "PKI Ticket::  https://fedorahosted.org/pki/ticket/962"
	rlRun "date --set='-2 days'" 0 "Set System back to the present day"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-group-show-tps-005.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-group-show-tps-005.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-group-show-tps-005.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-group-show-tps-005.out"
    rlPhaseEnd 

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-014: Should not be able to delete group using a TPS_officerV"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_officerV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g3"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g3 using a officer cert"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-group-show-tps-006.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-group-show-tps-006.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-group-show-tps-006.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-group-show-tps-006.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-015: Should not be able to delete group using a TPS_operatorV"
	command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_operatorV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g3"
	errmsg="ForbiddenException: Authorization Error"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g3 using a operator cert"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-group-show-tps-007.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-group-show-tps-007.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-group-show-tps-007.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-group-show-tps-007.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-016: Should not be able to delete group using a cert created from a untrusted CA TPS_adminUTCA"
	command="pki -d $UNTRUSTED_CERT_DB_LOCATION -n role_user_UTCA -c $UNTRUSTED_CERT_DB_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-del g3"
	errmsg="PKIException: Unauthorized"
	errorcode=255
	rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - Should not be able to delete group g3 using a untrusted cert"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                    -h $TPS_HOST \
                    -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-group-show-tps-008.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-group-show-tps-008.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-group-show-tps-008.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-group-show-tps-008.out"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-017: Should not be able to delete group using a user cert"
	#Create a user cert
        rlRun "generate_new_cert tmp_nss_db:$TEMP_NSS_DB tmp_nss_db_pwd:$TEMP_NSS_DB_PASSWD request_type:pkcs10 \
        algo:rsa key_size:2048 subject_cn:\"pki User2\" subject_uid:pkiUser2 subject_email:pkiuser2@example.org \
        organizationalunit:Engineering organization:Example.Inc country:US archive:false req_profile:caUserCert \
        target_host:$CA_HOST protocol: port:$CA_PORT cert_db_dir:$CERTDB_DIR cert_db_pwd:$CERTDB_DIR_PASSWORD \
        certdb_nick:\"$ROOTCA_agent_user\" cert_info:$cert_info"
        local valid_pkcs10_serialNumber=$(cat $cert_info| grep cert_serialNumber | cut -d- -f2)
        local valid_decimal_pkcs10_serialNumber=$(cat $cert_info| grep decimal_valid_serialNumber | cut -d- -f2)
        rlRun "pki -h $CA_HOST -p $CA_PORT cert-show $valid_pkcs10_serialNumber --encoded > $TmpDir/pki_tps_group_del_encoded_0025pkcs10.out" 0 "Executing pki cert-show $valid_pkcs10_serialNumber"
        rlRun "sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' $TmpDir/pki_tps_group_del_encoded_0025pkcs10.out > $TmpDir/pki_tps_group_del_encoded_0025pkcs10.pem"
        rlRun "certutil -d $TEMP_NSS_DB -A -n \"casigningcert\" -i $CERTDB_DIR/ca_cert.pem -t \"CT,CT,CT\""
        rlRun "certutil -d $TEMP_NSS_DB -A -n pkiUser2 -i $TmpDir/pki_tps_group_del_encoded_0025pkcs10.pem  -t "u,u,u""
        rlLog "Executing: pki -d $TEMP_NSS_DB \
                   -n pkiUser2 \
                   -c $TEMP_NSS_DB_PASSWD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-del g3"
        rlRun "pki -d $TEMP_NSS_DB \
                   -n pkiUser2 \
                   -c $TEMP_NSS_DB_PASSWD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-del g3 >  $TmpDir/pki-tps-group-del-pkiUser1-0025.out 2>&1" 255 "Should not be able to find groups using a user cert"
        rlAssertGrep "PKIException: Unauthorized" "$TmpDir/pki-tps-group-del-pkiUser1-0025.out"
	#Make sure group is not deleted
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-show g3 > $TmpDir/pki-group-show-tps-009.out" \
                    0 \
                    "Show group g3"
        rlAssertGrep "Group \"g3\"" "$TmpDir/pki-group-show-tps-009.out"
        rlAssertGrep "Group ID: g3" "$TmpDir/pki-group-show-tps-009.out"
        rlAssertGrep "Description: g3description" "$TmpDir/pki-group-show-tps-009.out"	

	#Cleanup:delete group g3
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-del g3 > $TmpDir/pki-group-del-tps-018.out 2>&1"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-018: delete group id with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
		    -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-add --description=test 'ÖrjanÄke' > $TmpDir/pki-group-add-tps-001_19.out 2>&1" \
                    0 \
                    "Adding gid ÖrjanÄke with i18n characters"
        rlAssertGrep "Added group \"ÖrjanÄke\"" "$TmpDir/pki-group-add-tps-001_19.out"
        rlAssertGrep "Group ID: ÖrjanÄke" "$TmpDir/pki-group-add-tps-001_19.out"
	rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-del 'ÖrjanÄke'"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-del 'ÖrjanÄke' > $TmpDir/pki-group-del-tps-001_19_3.out 2>&1" \
                    0 \
                    "Deleted gid ÖrjanÄke with i18n characters"
	rlAssertGrep "Deleted group \"ÖrjanÄke\""  "$TmpDir/pki-group-del-tps-001_19_3.out"
        command="pki -d $CERTDB_DIR -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-show 'ÖrjanÄke'"
        errmsg="GroupNotFoundException: Group ÖrjanÄke not found"
	errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - deleted group 'ÖrjanÄke' should not exist"
    rlPhaseEnd

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del-019: delete groupid with i18n characters"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-add --description=test 'ÉricTêko' > $TmpDir/pki-group-add-tps-001_20.out 2>&1" \
                    0 \
                    "Adding group id ÉricTêko with i18n characters"
        rlAssertGrep "Added group \"ÉricTêko\"" "$TmpDir/pki-group-add-tps-001_20.out"
        rlAssertGrep "Group ID: ÉricTêko" "$TmpDir/pki-group-add-tps-001_20.out"
        rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-show 'ÉricTêko' > $TmpDir/pki-group-add-tps-001_20_2.out" \
                    0 \
                    "Show group 'ÉricTêko'"
        rlAssertGrep "Group \"ÉricTêko\"" "$TmpDir/pki-group-add-tps-001_20_2.out"
        rlAssertGrep "Group ID: ÉricTêko" "$TmpDir/pki-group-add-tps-001_20_2.out"
	rlLog "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-del 'ÉricTêko'"
	rlRun "pki -d $CERTDB_DIR \
		   -n $(eval echo \$${subsystemId}_adminV_user) \
                    -c $CERTDB_DIR_PASSWORD \
                   -h $TPS_HOST \
                   -p $TPS_PORT \
                    tps-group-del 'ÉricTêko' > $TmpDir/pki-group-del-tps-001_20_3.out 2>&1" \
                    0 \
                    "Delete gid ÉricTêko with i18n characters"
	rlAssertGrep "Deleted group \"ÉricTêko\""  "$TmpDir/pki-group-del-tps-001_20_3.out"
        command="pki -d $CERTDB_DIR  -n $(eval echo \$${subsystemId}_adminV_user) -c $CERTDB_DIR_PASSWORD -h $TPS_HOST -p $TPS_PORT tps-group-show 'ÉricTêko'"
        errmsg="GroupNotFoundException: Group ÉricTêko not found"
	errorcode=255
        rlRun "verifyErrorMsg \"$command\" \"$errmsg\" \"$errorcode\"" 0 "Verify expected error message - deleted group 'ÉricTêko' should not exist"
    rlPhaseEnd 

    rlPhaseStartTest "pki_tps_group_cli_tps_group_del_cleanup-004: Deleting the temp directory"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
else
        rlPhaseStartCleanup "pki tps-group-del cleanup: Delete temp dir"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
        rlLog "TPS subsystem is not installed"
        rlPhaseEnd
fi
}
