//
//  Data+Utils.swift
//  Zippy
//
//  Created by Clemens on 15/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

extension Data {

	/**
	Returns little-endian ordered bytes at `offset` as UInt16 value.
	*/
	func readLittleUInt16(offset: Data.Index) -> UInt16 {
		let range: Range<Data.Index> = offset..<(offset+MemoryLayout<UInt16>.size)
		let value: UInt16 = self.subdata(in: range).withUnsafeBytes { return $0.pointee }
		return NSSwapLittleShortToHost(value)
	}

	/**
	Returns little-endian ordered bytes at `offset` as UInt32 value.
	*/
	func readLittleUInt32(offset: Data.Index) -> UInt32 {
		let range: Range<Data.Index> = offset..<(offset+MemoryLayout<UInt32>.size)
		let value: UInt32 = self.subdata(in: range).withUnsafeBytes { return $0.pointee }
		return NSSwapLittleIntToHost(value)
	}

	/**
	Returns little-endian ordered bytes at `offset` as UInt16 value and advances offset by 2 bytes.
	*/
	func readLittleUInt16(offset: inout Data.Index) -> UInt16 {
		let value: UInt16 = self.readLittleUInt16(offset: offset)
		offset += MemoryLayout<UInt16>.size
		return value
	}

	/**
	Returns little-endian ordered bytes at `offset` as UInt32 value and advances offset by 4 bytes.
	*/
	func readLittleUInt32(offset: inout Data.Index) -> UInt32 {
		let value: UInt32 = self.readLittleUInt32(offset: offset)
		offset += MemoryLayout<UInt32>.size
		return value
	}

}
