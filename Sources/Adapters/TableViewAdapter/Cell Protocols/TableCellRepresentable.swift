//
//  ItemCellRepresentable.swift
//  Adapters
//
//  Created by Anton Cherkasov on 12.05.2022.
//

import AppKit

public protocol TableCellRepresentable: NSView {
	associatedtype ViewModel: TableItemRepresentable
	init()
	var model: ViewModel? { get set }
	var valueDidChanged: ((ViewModel.ID, [String: Any]) -> Void)? { get set }
}
