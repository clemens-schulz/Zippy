//
//  ZipFile.swift
//  Zippy
//
//  Created by Clemens on 02/12/2016.
//  Copyright © 2016 Clemens Schulz. All rights reserved.
//

import Foundation
import Compression

open class ZipFile : Sequence {

	private let fileWrapper: FileWrapper

	private(set) var entries: [FileEntry]
	open var filenames: [String] {
		return self.entries.map { $0.filename }
	}

	open var comment: String?

	convenience init(url: URL) throws {
		let fileWrapper = try FileWrapper(url: url, options: [])
		try self.init(fileWrapper: fileWrapper)
	}

	/**
	Initializes ZIP file. `fileWrapper` must be a regular-file file wrapper.
	
	- Throws: Error of type `FileError` or `ZipError`.
	*/
	init(fileWrapper: FileWrapper) throws {
		precondition(fileWrapper.isRegularFile)

		guard let fileContents = fileWrapper.regularFileContents else {
			throw FileError.readFailed
		}

		// Find end of central directory record
		let endOfCentralDirRecOffset = try EndOfCentralDirectoryRecord.find(in: fileContents)
		var offsetAfterReading = endOfCentralDirRecOffset
		let endOfCentralDirRec = try EndOfCentralDirectoryRecord(data: fileContents, offset: &offsetAfterReading)
		guard offsetAfterReading == fileContents.endIndex else {
			throw ZipError.unexpectedBytes
		}

		// TODO: support split ZIP files
		guard endOfCentralDirRec.diskNumber == endOfCentralDirRec.centralDirectoryStartDiskNumber && endOfCentralDirRec.entriesOnDisk == endOfCentralDirRec.totalEntries else {
			throw FileError.segmentMissing
		}

		// Get file comment
		if endOfCentralDirRec.fileComment.count > 0 {
			self.comment = String(data: endOfCentralDirRec.fileComment, encoding: .utf8) // TODO: use actual encoding
		}

		// TODO: check if zip64 locator is present (value in end record == -1)

		// Parse central directory
		let centralDirectoryOffset = Data.Index(endOfCentralDirRec.centralDirectoryOffset)
		let centralDirectoryEndIndex = centralDirectoryOffset + Data.Index(endOfCentralDirRec.centralDirectorySize)

		if centralDirectoryOffset > endOfCentralDirRecOffset {
			throw ZipError.invalidCentralDirectoryOffset
		} else if centralDirectoryEndIndex > endOfCentralDirRecOffset {
			throw ZipError.invalidCentralDirectoryLength
		}

		var i = centralDirectoryOffset
		var fileEntries: [FileEntry] = []

		while i < fileContents.endIndex {
			let signature = fileContents.readLittleUInt32(offset: i)

			// Check if we reach end of central directory
			if i > centralDirectoryEndIndex {
				// Sum of central directory record sizes does not line up with expected length
				throw ZipError.invalidCentralDirectoryLength
			} else if i == centralDirectoryEndIndex {
				// We make sure that there is no unexpected data between central directory and end record
				if signature == EndOfCentralDirectoryRecord.signature && i == endOfCentralDirRecOffset {
					break
				} else {
					throw ZipError.unexpectedBytes
				}
			}

			// We did not reach the end yet. Look for next entry.

			if signature == CentralDirectoryFileHeader.signature {
				// File Header
				let fileHeader = try CentralDirectoryFileHeader(data: fileContents, offset: &i)
				let fileEntry = try FileEntry(header: fileHeader)
				if !fileEntry.filename.hasPrefix("__MACOSX/") {
					// Skip resource forks
					// TODO: find better way to identify resource fork. Probably using extra field
					fileEntries.append(fileEntry)
				}
			} else {
				// Unknown signature. We don't know what to do.
				throw ZipError.unexpectedBytes
			}
		}

		// TODO: support encrypted ZIP files

		self.entries = fileEntries
		self.fileWrapper = fileWrapper
	}

	subscript(filename: String) -> Data? {
		return try? self.read(filename: filename)
	}

	public func makeIterator() -> IndexingIterator<[String]> {
		return self.filenames.makeIterator()
	}

	func read(filename: String) throws -> Data {
		throw FileError.doesNotExist
	}

}
