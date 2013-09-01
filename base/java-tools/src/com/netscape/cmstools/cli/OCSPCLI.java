// --- BEGIN COPYRIGHT BLOCK ---
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; version 2 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// (C) 2013 Red Hat, Inc.
// All rights reserved.
// --- END COPYRIGHT BLOCK ---

package com.netscape.cmstools.cli;

import com.netscape.certsrv.client.Client;
import com.netscape.certsrv.ocsp.OCSPClient;
import com.netscape.cmstools.group.GroupCLI;
import com.netscape.cmstools.user.UserCLI;

/**
 * @author Endi S. Dewata
 */
public class OCSPCLI extends SubsystemCLI {

    public OCSPClient ocspClient;

    public OCSPCLI(CLI parent) {
        super("ocsp", "OCSP management commands", parent);

        addModule(new GroupCLI(this));
        addModule(new UserCLI(this));
    }

    public void init() throws Exception {
        client = parent.getClient();
        ocspClient = new OCSPClient(client);
    }

    public void login() {
        ocspClient.login();
    }

    public void logout() {
        ocspClient.logout();
    }

    public Client getClient(String name) {
        return ocspClient.getClient(name);
    }
}