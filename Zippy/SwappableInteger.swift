//
//  SwappableInteger.swift
//  Zippy
//
//  Created by Clemens on 21/01/2017.
//  Copyright © 2017 Clemens Schulz. All rights reserved.
//

import Foundation

protocol SwappableInteger: Integer {
	init(bigEndian value: Self)
	init(littleEndian value: Self)
	init(integerLiteral value: Self)
	var bigEndian: Self { get }
	var littleEndian: Self { get }
	var byteSwapped: Self { get }
}

extension UInt16: SwappableInteger {}
extension UInt32: SwappableInteger {}
extension UInt64: SwappableInteger {}
extension Int16: SwappableInteger {}
extension Int32: SwappableInteger {}
extension Int64: SwappableInteger {}
