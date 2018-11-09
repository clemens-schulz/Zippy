//
//  ZipError.swift
//  Zippy
//
//  Created by Clemens on 01.02.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public enum ZipError: Error {

	/// End of central directory record is missing or broken
	case endOfCentralDirectoryRecordNotFound

	/// Encountered signature does not match expected signature
	case unexpectedSignature

	/// Segment or offset of Zip64 end of central directory record is invalid
	case invalidZip64EndOfCentralDirectoryOffset

	/// Length of extensible data section is invalid
	case invalidExtensibleDataLength

	/// Compression method is not in specs.
	case unknownCompressionMethod(method: UInt16)

	/// Length of central directory does not match actual length
	case invalidCentralDirectoryLength

	/// Data of filename or comment could not be decoded
	case encodingError

	/// Data for zip64 extended information extra field does not contain all expected fields
	case invalidZip64ExtendedInformationExtraFieldLength

	/// Support for encryption method is not implemented
	case unsupportedEncryption

	/// Support for compression method is not implemented
	case unsupportedCompressionMethod
}
