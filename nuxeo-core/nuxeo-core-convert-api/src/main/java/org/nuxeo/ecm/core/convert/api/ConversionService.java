/*
 * (C) Copyright 2002-2007 Nuxeo SAS (http://nuxeo.com/) and contributors.
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the GNU Lesser General Public License
 * (LGPL) version 2.1 which accompanies this distribution, and is available at
 * http://www.gnu.org/licenses/lgpl.html
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * Contributors:
 *     Nuxeo - initial API and implementation
 *
 */
package org.nuxeo.ecm.core.convert.api;

import java.io.Serializable;
import java.util.List;
import java.util.Map;

import org.nuxeo.ecm.core.api.blobholder.BlobHolder;

/**
 * Interface for the Conversion Service.
 *
 * @author tiry
 */
public interface ConversionService {

    /**
     * Gets the convertName given a source and destination MimeType.
     */
    String getConverterName(String sourceMimeType, String destinationMimeType);

    /**
     * Gets the available convertNames given a source and destination MimeType.
     */
    List<String> getConverterNames(String sourceMimeType, String destinationMimeType);

    /**
     * Converts a Blob given a converter name.
     */
    BlobHolder convert(String converterName, BlobHolder blobHolder,
            Map<String, Serializable> parameters) throws ConversionException;

    /**
     * Converts a Blob given a target destination MimeType.
     */
    BlobHolder convertToMimeType(String destinationMimeType,
            BlobHolder blobHolder, Map<String, Serializable> parameters)
            throws ConversionException;

    /**
     * Returns the names of the registered converters.
     */
    List<String> getRegistredConverters();

    /**
     * Checks for converter availability.
     * <p>
     * Result can be:
     * <ul>
     * <li>{@link ConverterNotRegistered} if converter is not registered.
     * <li>Error Message / Installation message if converter dependencies are
     * not available an successful check.
     * </ul>
     */
    ConverterCheckResult isConverterAvailable(String converterName,
            boolean refresh) throws ConversionException;

    /**
     * Checks for converter availability.
     * <p>
     * Result can be:
     * <ul>
     * <li>{@link ConverterNotRegistered} if converter is not registered.
     * <li>Error Message / Installation message if converter dependencies are
     * not available an successful check.
     * </ul>
     * <p>
     * Result can be taken from an internal cache.
     */
    ConverterCheckResult isConverterAvailable(String converterName)
            throws ConversionException;

}