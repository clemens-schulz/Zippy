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
		let endOfCentralDirRec = try EndOfCentralDirectoryRecord.find(in: fileContents)

		// TODO: support split ZIP files
		guard endOfCentralDirRec.diskNumber == endOfCentralDirRec.centralDirectoryStartDiskNumber && endOfCentralDirRec.entriesOnDisk == endOfCentralDirRec.totalEntries else {
			throw FileError.segmentMissing
		}

		// Get file comment
		if endOfCentralDirRec.fileComment.count > 0 {
			self.comment = String(data: endOfCentralDirRec.fileComment, encoding: .utf8) // TODO: use actual encoding
		}

		// Parse central directory
		var i = Data.Index(endOfCentralDirRec.centralDirectoryOffset)
		if i > fileContents.endIndex - CentralDirectoryFileHeader.minLength {
			throw ZipError.invalidCentralDirectoryOffset
		}

		var fileEntries: [FileEntry] = []

		var endOfCentralDirectoryReached = false
		while i < fileContents.endIndex {
			let signature = fileContents.readLittleUInt32(offset: i)

			// TODO: digital signature, Zip64 record + locator
			if signature == CentralDirectoryFileHeader.signature {
				let fileHeader = try CentralDirectoryFileHeader(data: fileContents, offset: &i)
				let fileEntry = try FileEntry(header: fileHeader)
				if !fileEntry.filename.hasPrefix("__MACOSX/") {
					// Skip resource forks
					// TODO: find better way to identify resource fork. Probably using extra field
					fileEntries.append(fileEntry)
				}
			} else if signature == EndOfCentralDirectoryRecord.signature {
				endOfCentralDirectoryReached = true
				break
			} else {
				throw ZipError.unexpectedBytes
			}
		}

		if !endOfCentralDirectoryReached {
			// Could happen if variable length field includes end of central directory record
			throw ZipError.unexpectedBytes
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
		fatalError("not implemented")
	}

}
