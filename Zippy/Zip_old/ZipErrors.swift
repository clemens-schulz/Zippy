//
//  ZipErrors.swift
//  Zippy
//
//  Created by Clemens on 12.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

/**
Error in ZIP file
*/
public enum ZipError: Error {
	/// End of central directory record is missing or broken
	case endOfCentralDirectoryRecordNotFound

	/// Disk or offset of Zip64 end of central directory record is invalid
	case invalidZip64EndOfCentralDirectoryOffset

	/// ZIP file is incomplete
	case incomplete

	/// Unexpected bytes
	case unexpectedBytes

	/// Compression method is not in specs.
	case unknownCompressionMethod(method: UInt16)

	/// Offset or start disk of central directory is not in valid range
	case invalidCentralDirectoryOffset

	/// Length of central directory does not match actual length
	case invalidCentralDirectoryLength

	/// Number of entries in central directory does not match number in end record
	case invalidNumberOfCentralDirectoryEntries

	/// Redundant values are different
	case conflictingValues

	/// Unexpected signature
	case unexpectedSignature

	/// Multiple files with same name found
	case duplicateFileName

	/// Length of extensible data section is invalid
	case invalidExtensibleDataLength

	/// Zip64 extended information field is missing
	case missingZip64ExtendedInformation

	/// Checksum of extracted data does not match expected checksum
	case invalidChecksum

	/// Password is wrong
	case wrongPassword

	/// Delegate did not return a password
	case noPasswordProvided

}
