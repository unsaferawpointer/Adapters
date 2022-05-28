//
//  CellRepresentable.swift
//  
//
//  Created by Anton Cherkasov on 18.06.2022.
//

import AppKit

/// Represent cell of the table
public protocol CellRepresentable: NSView {
	associatedtype ViewModel
	/// View model of the cell
	var viewModel: ViewModel? { get set }
	/// Will invoke when view model did changed
	var valueDidChanged: ((ViewModel) -> Void)? { get set }
}
