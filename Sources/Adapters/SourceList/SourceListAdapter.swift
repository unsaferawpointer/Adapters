//
//  SourceListAdapter.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import AppKit

/// Public interface of the source list adapter
public protocol SourceListAdapter {

	typealias Index = SourceList.Index

	init(_ outlineView: NSOutlineView)

	/// Selection provider of adapter
	var selectionProvider: SourceList.SelectionProvider? { get set }

	/// Setup cell first responder with this identifier
	///
	/// - Note: Cell must be implement `Focusable` protocol
	func setupFocus(_ identifier: AnyHashable)

	/// Scroll to cell with specific identifier
	func scrollTo(_ identifier: AnyHashable, withAnimation: Bool)

	/// Expand cell with specific identifier
	///
	/// - Parameters:
	///    - identifier: Model identifier of the cell
	///    - withAnimation: Flag of the animation
	///    - expandChildren: Expand all children
	func expand(_ identifier: AnyHashable, withAnimation: Bool, expandChildren: Bool)

	/// Update  model cell without diffing
	///
	/// - Parameters:
	///    - model: Updating model
	func forceUpdate(_ model: any ListItem)

	/// - Returns: Returns selected indexes in current moment
	func getSelection() -> [Index]

	/// Select cells with following identifiers
	func select(identifiers: [AnyHashable], byExtendingSelection extendSelection: Bool)
}
