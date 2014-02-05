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
// (C) 2014 Red Hat, Inc.
// All rights reserved.
// --- END COPYRIGHT BLOCK ---

package com.netscape.certsrv.key;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

@XmlRootElement(name = "KeyRequestResponse")
public class KeyRequestResponse {
    KeyRequestInfo requestInfo;
    KeyData keyData;

    @XmlElement(name="RequestInfo")
    public KeyRequestInfo getRequestInfo() {
        return requestInfo;
    }

    public void setRequestInfo(KeyRequestInfo requestInfo) {
        this.requestInfo = requestInfo;
    }

    @XmlElement(name="KeyData")
    public KeyData getKeyData() {
        return keyData;
    }

    public void setKeyData(KeyData keyData) {
        this.keyData = keyData;
    }
}
