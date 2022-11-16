//
//  ConfigurableCell.swift
//  
//
//  Created by Anton Cherkasov on 17.09.2022.
//

import Cocoa

/// Cell of  list
public protocol ConfigurableCell: NSView {

	/// View-model of the cell
	associatedtype Model

	/// Identifier for cell reusing
	static var userIdentifier: String { get }

	init(_ model: Model)

	var model: Model { get set }
}
