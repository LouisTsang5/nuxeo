/*
 * Copyright (c) 2014 Nuxeo SA (http://nuxeo.com/) and others.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors:
 *     Florent Guillaume
 */
package org.nuxeo.ecm.core.storage.sql;

import static org.junit.Assert.assertEquals;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.TimeUnit;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.junit.Test;
import org.nuxeo.ecm.core.api.ClientException;
import org.nuxeo.ecm.core.api.CoreInstance;
import org.nuxeo.ecm.core.api.CoreSession;
import org.nuxeo.ecm.core.api.DocumentModel;
import org.nuxeo.ecm.core.api.DocumentModelList;
import org.nuxeo.ecm.core.api.security.ACE;
import org.nuxeo.ecm.core.api.security.impl.ACLImpl;
import org.nuxeo.ecm.core.api.security.impl.ACPImpl;
import org.nuxeo.ecm.core.query.sql.NXQL;
import org.nuxeo.runtime.transaction.TransactionHelper;

/**
 * Tests read ACLs behavior in a transactional setting.
 */
public class TestSQLRepositoryReadAcls extends TXSQLRepositoryTestCase {

    protected static final Log log = LogFactory.getLog(TestSQLRepositoryJTAJCA.class);

    @Test
    public void testParallelPrepareUserReadAcls() throws Throwable {
        // set ACP on root
        ACPImpl acp = new ACPImpl();
        ACLImpl acl = new ACLImpl();
        acl.add(new ACE("Administrator", "Everything", true));
        acl.add(new ACE("bob", "Everything", true));
        acp.addACL(acl);
        DocumentModel root = session.getRootDocument();
        root.setACP(acp, true);
        session.saveDocument(root);
        DocumentModel doc = session.createDocumentModel("/", "foo", "File");
        doc = session.createDocument(doc);
        session.save();

        closeSession();
        TransactionHelper.commitOrRollbackTransaction();

        CyclicBarrier barrier = new CyclicBarrier(2);
        CountDownLatch firstReady = new CountDownLatch(1);
        PrepareUserReadAclsJob r1 = new PrepareUserReadAclsJob(
                database.repositoryName, firstReady, barrier);
        PrepareUserReadAclsJob r2 = new PrepareUserReadAclsJob(
                database.repositoryName, null, barrier);
        Thread t1 = null;
        Thread t2 = null;
        try {
            t1 = new Thread(r1, "t1");
            t2 = new Thread(r2, "t2");
            t1.start();
            if (firstReady.await(60, TimeUnit.SECONDS)) {
                t2.start();

                t1.join();
                t1 = null;
                t2.join();
                t2 = null;
                if (r1.throwable != null) {
                    throw r1.throwable;
                }
                if (r2.throwable != null) {
                    throw r2.throwable;
                }
            } // else timed out
        } finally {
            // error condition recovery
            if (t1 != null) {
                t1.interrupt();
            }
            if (t2 != null) {
                t2.interrupt();
            }
        }

        // after both threads have run, check that we don't see
        // duplicate documents
        TransactionHelper.startTransaction();
        session = openSessionAs("bob");
        checkOneDoc(session); // failed for PostgreSQL
    }

    protected static void checkOneDoc(CoreSession session)
            throws ClientException {
        String query = "SELECT * FROM File WHERE ecm:isProxy = 0";
        DocumentModelList res = session.query(query, NXQL.NXQL, null, 0, 0,
                false);
        assertEquals(1, res.size());
    }

    protected static class PrepareUserReadAclsJob implements Runnable {

        private String repositoryName;

        public CountDownLatch ready;

        public CyclicBarrier barrier;

        public Throwable throwable;

        public PrepareUserReadAclsJob(String repositoryName,
                CountDownLatch ready, CyclicBarrier barrier) {
            this.repositoryName = repositoryName;
            this.ready = ready;
            this.barrier = barrier;
        }

        protected CoreSession openSession(String userName)
                throws ClientException {
            TransactionHelper.startTransaction();
            Map<String, Serializable> context = new HashMap<String, Serializable>();
            context.put("username", userName);
            return CoreInstance.getInstance().open(repositoryName, context);
        }

        protected void closeSession(CoreSession session) {
            CoreInstance.getInstance().close(session);
            TransactionHelper.commitOrRollbackTransaction();
        }

        @Override
        public void run() {
            CoreSession session = null;
            try {
                session = openSession("bob");
                if (ready != null) {
                    ready.countDown();
                    ready = null;
                }
                barrier.await(30, TimeUnit.SECONDS); // (throws on timeout)
                barrier = null;
                checkOneDoc(session); // fails for Oracle
            } catch (Throwable t) {
                t.printStackTrace();
                throwable = t;
            } finally {
                if (session != null) {
                    closeSession(session);
                }
                // error recovery
                // still count down as main thread is awaiting us
                if (ready != null) {
                    ready.countDown();
                }
                // break barrier for other thread
                if (barrier != null) {
                    barrier.reset(); // break barrier
                }
            }
        }
    }

}