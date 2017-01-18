//
//  Errors.swift
//  Zippy
//
//  Created by Clemens on 17/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

public enum FileError: Error {
	/// Could not read file
	case readFailed

	/// Split ZIP file is missing segments
	case segmentMissing

	/// File does not exist
	case doesNotExist
}

public enum ZipError: Error {
	/// End of central directory record missing
	case endOfCentralDirectoryRecordMissing

	/// ZIP file is incomplete
	case incomplete

	/// Unexpected bytes
	case unexpectedBytes

	/// Compression method is not in specs.
	case unknownCompressionMethod(method: UInt16)

	/// Offset of central directory is not in valid range
	case invalidCentralDirectoryOffset
}
