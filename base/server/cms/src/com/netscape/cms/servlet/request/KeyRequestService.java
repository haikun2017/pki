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
// (C) 2011 Red Hat, Inc.
// All rights reserved.
// --- END COPYRIGHT BLOCK ---

package com.netscape.cms.servlet.request;

import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Request;
import javax.ws.rs.core.UriInfo;

import com.netscape.certsrv.apps.CMS;
import com.netscape.certsrv.base.BadRequestException;
import com.netscape.certsrv.base.EBaseException;
import com.netscape.certsrv.base.PKIException;
import com.netscape.certsrv.dbs.keydb.KeyId;
import com.netscape.certsrv.key.KeyArchivalRequest;
import com.netscape.certsrv.key.KeyRecoveryRequest;
import com.netscape.certsrv.key.KeyRequestInfo;
import com.netscape.certsrv.key.KeyRequestInfos;
import com.netscape.certsrv.key.KeyRequestResource;
import com.netscape.certsrv.logging.ILogger;
import com.netscape.certsrv.request.RequestId;
import com.netscape.certsrv.request.RequestNotFoundException;
import com.netscape.cms.servlet.base.PKIService;
import com.netscape.cms.servlet.key.KeyRequestDAO;
import com.netscape.cmsutil.ldap.LDAPUtil;

/**
 * @author alee
 *
 */
public class KeyRequestService extends PKIService implements KeyRequestResource {

    @Context
    private UriInfo uriInfo;

    @Context
    private HttpHeaders headers;

    @Context
    private Request request;

    @Context
    private HttpServletRequest servletRequest;

    private static final String LOGGING_SIGNED_AUDIT_SECURITY_DATA_ARCHIVAL_REQUEST =
            "LOGGING_SIGNED_AUDIT_SECURITY_DATA_ARCHIVAL_REQUEST_4";

    private static final String LOGGING_SIGNED_AUDIT_SECURITY_DATA_RECOVERY_REQUEST =
            "LOGGING_SIGNED_AUDIT_SECURITY_DATA_RECOVERY_REQUEST_4";

    private static final String LOGGING_SIGNED_AUDIT_SECURITY_DATA_RECOVERY_REQUEST_STATE_CHANGE =
            "LOGGING_SIGNED_AUDIT_SECURITY_DATA_RECOVERY_REQUEST_STATE_CHANGE_4";

    public static final int DEFAULT_START = 0;
    public static final int DEFAULT_PAGESIZE = 20;
    public static final int DEFAULT_MAXRESULTS = 100;
    public static final int DEFAULT_MAXTIME = 10;

    /**
     * Used to retrieve key request info for a specific request
     */
    public KeyRequestInfo getRequestInfo(RequestId id) {
        // auth and authz
        KeyRequestDAO dao = new KeyRequestDAO();
        KeyRequestInfo info;
        try {
            info = dao.getRequest(id, uriInfo);
        } catch (EBaseException e) {
            // log error
            e.printStackTrace();
            throw new PKIException(e.getMessage(), e);
        }
        if (info == null) {
            // request does not exist
            throw new RequestNotFoundException(id);
        }
        return info;
    }

    // Archiving - used to test integration with a browser
    public KeyRequestInfo archiveKey(MultivaluedMap<String, String> form) {
        KeyArchivalRequest data = new KeyArchivalRequest(form);
        return archiveKey(data);
    }

    public KeyRequestInfo archiveKey(KeyArchivalRequest data) {
        // auth and authz
        // Catch this before internal server processing has to deal with it

        if (data == null || data.getClientId() == null
                || data.getWrappedPrivateData() == null
                || data.getDataType() == null) {
            throw new BadRequestException("Invalid key archival request.");
        }

        KeyRequestDAO dao = new KeyRequestDAO();
        KeyRequestInfo info;
        try {
            info = dao.submitRequest(data, uriInfo);
            auditArchivalRequestMade(info.getRequestId(), ILogger.SUCCESS, data.getClientId());
        } catch (EBaseException e) {
            e.printStackTrace();
            auditArchivalRequestMade(null, ILogger.FAILURE, data.getClientId());
            throw new PKIException(e.toString());
        }
        return info;
    }

    //Recovery - used to test integration with a browser
    public KeyRequestInfo recoverKey(MultivaluedMap<String, String> form) {
        KeyRecoveryRequest data = new KeyRecoveryRequest(form);
        return recoverKey(data);
    }

    public KeyRequestInfo recoverKey(KeyRecoveryRequest data) {
        // auth and authz

        //Check for entirely illegal data combination here
        //Catch this before the internal server processing has to deal with it
        //If data has been provided, we need at least the wrapped session key,
        //or the command is invalid.

        if (data == null) {
            throw new BadRequestException("Invalid request.");
        }
        if (data.getTransWrappedSessionKey() == null
                && data.getSessionWrappedPassphrase() != null) {
            throw new BadRequestException("No wrapped session key.");
        }
        KeyRequestDAO dao = new KeyRequestDAO();
        KeyRequestInfo info;
        try {
            info = dao.submitRequest(data, uriInfo);
            auditRecoveryRequestMade(info.getRequestId(), ILogger.SUCCESS, data.getKeyId());
        } catch (EBaseException e) {
            e.printStackTrace();
            auditRecoveryRequestMade(null, ILogger.FAILURE, data.getKeyId());
            throw new PKIException(e.toString());
        }
        return info;
    }

    public void approveRequest(RequestId id) {
        if (id == null) {
            throw new BadRequestException("Invalid request id.");
        }
        // auth and authz
        KeyRequestDAO dao = new KeyRequestDAO();
        try {
            dao.approveRequest(id);
            auditRecoveryRequestChange(id, ILogger.SUCCESS, "approve");
        } catch (EBaseException e) {
            e.printStackTrace();
            auditRecoveryRequestChange(id, ILogger.FAILURE, "approve");
            throw new PKIException(e.toString());
        }
    }

    public void rejectRequest(RequestId id) {
        if (id == null) {
            throw new BadRequestException("Invalid request id.");
        }
        // auth and authz
        KeyRequestDAO dao = new KeyRequestDAO();
        try {
            dao.rejectRequest(id);
            auditRecoveryRequestChange(id, ILogger.SUCCESS, "reject");
        } catch (EBaseException e) {
            e.printStackTrace();
            auditRecoveryRequestChange(id, ILogger.FAILURE, "reject");
            throw new PKIException(e.toString());
        }
    }

    public void cancelRequest(RequestId id) {
        if (id == null) {
            throw new BadRequestException("Request id is null.");
        }
        // auth and authz
        KeyRequestDAO dao = new KeyRequestDAO();
        try {
            dao.cancelRequest(id);
            auditRecoveryRequestChange(id, ILogger.SUCCESS, "cancel");
        } catch (EBaseException e) {
            e.printStackTrace();
            auditRecoveryRequestChange(id, ILogger.FAILURE, "cancel");
            throw new PKIException(e.toString());
        }
    }

    /**
     * Used to generate list of key requests based on the search parameters
     */
    public KeyRequestInfos listRequests(String requestState, String requestType, String clientID,
            RequestId start, Integer pageSize, Integer maxResults, Integer maxTime) {
        // auth and authz

        // get ldap filter
        String filter = createSearchFilter(requestState, requestType, clientID);
        CMS.debug("listRequests: filter is " + filter);

        start = start == null ? new RequestId(KeyRequestService.DEFAULT_START) : start;
        pageSize = pageSize == null ? DEFAULT_PAGESIZE : pageSize;
        maxResults = maxResults == null ? DEFAULT_MAXRESULTS : maxResults;
        maxTime = maxTime == null ? DEFAULT_MAXTIME : maxTime;

        KeyRequestDAO reqDAO = new KeyRequestDAO();
        KeyRequestInfos requests;
        try {
            requests = reqDAO.listRequests(filter, start, pageSize, maxResults, maxTime, uriInfo);
        } catch (EBaseException e) {
            CMS.debug("listRequests: error in obtaining request results" + e);
            e.printStackTrace();
            throw new PKIException(e.toString());
        }
        return requests;
    }

    private String createSearchFilter(String requestState, String requestType, String clientID) {
        String filter = "";
        int matches = 0;

        if ((requestState == null) && (requestType == null) && (clientID == null)) {
            filter = "(requeststate=*)";
            return filter;
        }

        if (requestState != null) {
            filter += "(requeststate=" + LDAPUtil.escapeFilter(requestState) + ")";
            matches ++;
        }

        if (requestType != null) {
            filter += "(requesttype=" + LDAPUtil.escapeFilter(requestType) + ")";
            matches ++;
        }

        if (clientID != null) {
            filter += "(clientID=" + LDAPUtil.escapeFilter(clientID) + ")";
            matches ++;
        }

        if (matches > 1) {
            filter = "(&" + filter + ")";
        }

        return filter;
    }

    public void auditRecoveryRequestChange(RequestId requestId, String status, String operation) {
        String msg = CMS.getLogMessage(
                LOGGING_SIGNED_AUDIT_SECURITY_DATA_RECOVERY_REQUEST_STATE_CHANGE,
                servletRequest.getUserPrincipal().getName(),
                status,
                requestId.toString(),
                operation);
        auditor.log(msg);
    }

    public void auditRecoveryRequestMade(RequestId requestId, String status, KeyId dataId) {
        String msg = CMS.getLogMessage(
                LOGGING_SIGNED_AUDIT_SECURITY_DATA_RECOVERY_REQUEST,
                servletRequest.getUserPrincipal().getName(),
                status,
                requestId != null? requestId.toString(): "null",
                dataId.toString());
        auditor.log(msg);
    }

    public void auditArchivalRequestMade(RequestId requestId, String status, String clientId) {
        String msg = CMS.getLogMessage(
                LOGGING_SIGNED_AUDIT_SECURITY_DATA_ARCHIVAL_REQUEST,
                servletRequest.getUserPrincipal().getName(),
                status,
                requestId != null? requestId.toString(): "null",
                clientId);
        auditor.log(msg);
    }
}