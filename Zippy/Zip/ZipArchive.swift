//
//  ZipArchive.swift
//  Zippy
//
//  Created by Clemens on 01.02.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

public class ZipArchive: CompressedArchive, Sequence {
	public var delegate: CompressedArchiveDelegate?

	public let numberOfSegments: Int

	private var fileEntries = [String:ZipFileEntry]()
	public private(set) var filenames = [String]()

	private let reader: DataReader

	private let endOfCentralDirectoryRecord: Zip.EndOfCentralDirectoryRecord
	private let zip64EndOfCentralDirectoryLocator: Zip.Zip64EndOfCentralDirectoryLocator?

	public required init(data: Data, delegate: CompressedArchiveDelegate?) throws {
		var reader = DataReader(data: data)

		// Find and read end of central directory record
		var endOfCentralDirRecIndex = try Zip.EndOfCentralDirectoryRecord.findStartIndex(reader: reader)
		let endOfCentralDirRec = try Zip.EndOfCentralDirectoryRecord(reader: reader, at: endOfCentralDirRecIndex)
		self.endOfCentralDirectoryRecord = endOfCentralDirRec

		// Check for Zip64 end of central directory locator
		let zip64EndLocator: Zip.Zip64EndOfCentralDirectoryLocator?
		do {
			let zip64EndLocatorIndex = endOfCentralDirRecIndex - Zip.Zip64EndOfCentralDirectoryLocator.length
			zip64EndLocator = try Zip.Zip64EndOfCentralDirectoryLocator(reader: reader, at: zip64EndLocatorIndex)
		} catch ZipError.unexpectedSignature {
			zip64EndLocator = nil
		} catch DataReaderError.outOfRange {
			zip64EndLocator = nil
		}
		self.zip64EndOfCentralDirectoryLocator = zip64EndLocator

		// Get number of segments
		let numberOfDisks: Int
		if endOfCentralDirRec.diskNumber == UInt16.max && zip64EndLocator != nil {
			numberOfDisks = Int(zip64EndLocator!.totalNumberOfDisks)
		} else {
			numberOfDisks = Int(endOfCentralDirRec.diskNumber) + 1
		}
		self.numberOfSegments = numberOfDisks

		// Update data reader, if zip file has multiple segments
		if numberOfDisks > 1 {
			let lastDisk = numberOfDisks - 1
			reader = DataReader(data: data, segment: lastDisk, numberOfSegments: numberOfDisks)
			endOfCentralDirRecIndex.segment = numberOfDisks - 1
		}

		self.delegate = delegate
		self.reader = reader

		reader.dataSource = self

		let centralDirectory = try self.readCentralDirectory()

		// Get info for files in central directory
		let encoding: String.Encoding = .utf8

		var filenames = [String]()
		var fileEntries = [String:ZipFileEntry]()

		for header in centralDirectory.headers {
			let filename: String! = String(bytes: header.filename, encoding: encoding)
			guard filename != nil else {
				throw ZipError.encodingError
			}

			guard !fileEntries.keys.contains(filename) else {
				throw ZipError.duplicateFilename
			}

			var startDiskNumber = Int(header.startDiskNumber)
			var relativeOffsetOfLocalHeader = Int(header.relativeOffsetOfLocalHeader)
			var compressedSize = Int(header.compressedSize)
			var uncompressedSize = Int(header.uncompressedSize)

			// Update values, if in zip64 extra field
			let zip64Fields = header.zip64Fields
			if zip64Fields != .none {
				let extraField = header.extraFields.fields.first(where: { (field: Zip.ExtensibleDataField) -> Bool in
					return field.headerID == Zip.Zip64ExtendedInformationExtraField.headerID
				})

				if let extraField = extraField {
					let zip64ExtraField = try Zip.Zip64ExtendedInformationExtraField(data: extraField.data, fields: zip64Fields)

					if zip64ExtraField.startDiskNumber != nil {
						startDiskNumber = Int(zip64ExtraField.startDiskNumber!)
					}

					if zip64ExtraField.relativeHeaderOffset != nil {
						relativeOffsetOfLocalHeader = Int(zip64ExtraField.relativeHeaderOffset!)
					}

					if zip64ExtraField.compressedSize != nil {
						compressedSize = Int(zip64ExtraField.compressedSize!)
					}

					if zip64ExtraField.originalSize != nil {
						uncompressedSize = Int(zip64ExtraField.originalSize!)
					}
				}
			}

			// Create entry
			let localFileHeaderIndex = DataReader.Index(
				segment: Int(startDiskNumber),
				offset: Int(relativeOffsetOfLocalHeader)
			)

			let entry = ZipFileEntry(
				compressedSize: compressedSize,
				uncompressedSize: uncompressedSize,
				crc32checksum: header.crc32checksum,
				localFileHeaderIndex: localFileHeaderIndex
			)

			filenames.append(filename)
			fileEntries[filename] = entry
		}

		self.filenames = filenames
		self.fileEntries = fileEntries
	}

	private func readCentralDirectory() throws -> Zip.CentralDirectory {
		// Read Zip64 end of central directory record, if it exists
		let zip64EndOfCentralDirRec: Zip.Zip64EndOfCentralDirectoryRecord?
		if let zip64EndLocator = self.zip64EndOfCentralDirectoryLocator {
			let segment = Int(zip64EndLocator.zip64EndRecordStartDiskNumber)
			let offset = Int(zip64EndLocator.zip64EndRecordRelativeOffset)
			let recordIndex = DataReader.Index(segment: segment, offset: offset)
			zip64EndOfCentralDirRec = try Zip.Zip64EndOfCentralDirectoryRecord(reader: reader, at: recordIndex)
		} else {
			zip64EndOfCentralDirRec = nil
		}

		// Read central directory
		let centralDirStartDisk: Int
		let centralDirOffset: Int
		let centralDirSize: Int

		if let zip64EndOfCentralDirRec = zip64EndOfCentralDirRec {
			centralDirStartDisk = Int(zip64EndOfCentralDirRec.centralDirectoryStartDiskNumber)
			centralDirOffset = Int(zip64EndOfCentralDirRec.centralDirectoryOffset)
			centralDirSize = Int(zip64EndOfCentralDirRec.centralDirectorySize)
		} else {
			let endOfCentralDirRec = self.endOfCentralDirectoryRecord
			centralDirStartDisk = Int(endOfCentralDirRec.centralDirectoryStartDiskNumber)
			centralDirOffset = Int(endOfCentralDirRec.centralDirectoryOffset)
			centralDirSize = Int(endOfCentralDirRec.centralDirectorySize)
		}

		var centralDirIndex = DataReader.Index(segment: centralDirStartDisk, offset: centralDirOffset)
		let centralDirectory = try Zip.CentralDirectory(reader: reader, at: &centralDirIndex, length: centralDirSize)

		// TODO: verify digital signature of central directory

		return centralDirectory
	}

	public func extract(file filename: String, verify: Bool = false) throws -> Data {
		fatalError("not implemented")
	}

	public func extract(file filename: String, to url: URL, verify: Bool = false) throws {
		fatalError("not implemented")
	}

	public func info(for filename: String) throws -> CompressedFileInfo {
		if let fileInfo = self.fileEntries[filename] {
			return fileInfo
		} else {
			throw CompressedArchiveError.noSuchFile
		}
	}

}

extension ZipArchive: DataReaderDataSource {

	func dataReader(_ dataReader: DataReader, dataForSegment segmentIndex: Int) -> Data? {
		return self.delegate?.compressedArchive(self, dataForSegment: segmentIndex)
	}

}
