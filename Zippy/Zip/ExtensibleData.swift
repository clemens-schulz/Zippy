//
//  ExtensibleDataField.swift
//  Zippy
//
//  Created by Clemens on 12.01.18.
//  Copyright © 2018 Clemens Schulz. All rights reserved.
//

import Foundation

extension Zip {

	struct ExtensibleDataField {

		public let headerID: UInt16
		public let data: Data
	}

	struct ExtensibleData {

		let fields: [ExtensibleDataField]

		init(reader: DataReader, at index: inout DataReader.Index, length: Int) throws {
			if length != 0 && length < 4 {
				throw ZipError.invalidExtensibleDataLength
			}

			var extensibleDataFields = [ExtensibleDataField]()
			let endIndex = try reader.offset(index: index, by: length)

			do {
				while index < endIndex {
					let headerID: UInt16 = try reader.read(at: &index)
					let dataSize: UInt16 = try reader.read(at: &index)

					let extensibleData = try reader.read(Int(dataSize), at: &index)

					let extensibleDataField = ExtensibleDataField(headerID: headerID, data: extensibleData)
					extensibleDataFields.append(extensibleDataField)
				}
			} catch DataReaderError.outOfRange {
				throw ZipError.invalidExtensibleDataLength
			}

			if index > endIndex {
				throw ZipError.invalidExtensibleDataLength
			}

			self.fields = extensibleDataFields
		}
	}
}
