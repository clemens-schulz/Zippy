//
//  Errors.swift
//  Zippy
//
//  Created by Clemens on 17/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

/**
File-related error
*/
public enum FileError: Error {
	/// Could not read file
	case readFailed

	/// Split ZIP file is missing segments
	case segmentMissing

	/// More split ZIP file segments than actually needed
	case tooManySegments

	/// File extension of split ZIP file does not conform to standard
	case invalidSegmentFileExtension

	/// File does not exist
	case doesNotExist

	/// Tried to read past end of file
	case endOfFileReached
}

/**
Error in ZIP file
*/
public enum ZipError: Error {
	/// End of central directory record missing
	case endOfCentralDirectoryRecordMissing

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

	/// Extensible data field contains invalid data
	case invalidExtraField

	/// Zip64 extended information field is missing
	case missingZip64ExtendedInformation
}

/**
Zippy implementation-specific error
*/
public enum ZippyError: Error {
	/// Compression algorithm not implemented
	case unsupportedCompression

	/// ZIP file is using strong encryption, which requires special license agreement from PKWARE
	case unsupportedEncryption
}
