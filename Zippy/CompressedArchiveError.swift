//
//  CompressedArchiveError.swift
//  Zippy-iOS
//
//  Created by Clemens on 09.11.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public enum CompressedArchiveError: Error {
	/// URL or FileWrapper doesn't point to regular file.
	case noRegularFile

	/// Unable to read file data. May be caused by modifiying the file or removing the storage volume during read.
	case readFailed

	/// Unable to write data to file.
	case writeFailed

	/// Archive could not be read, because it is not in the expected format or checksum check failed
	case corrupted

	/// Missing data for segment
	case incomplete

	/// Password is wrong
	case wrongPassword

	/// Filename does not match any file in archive
	case noSuchFile

	/// Archive requires features that are not implemented
	case unsupported
}
