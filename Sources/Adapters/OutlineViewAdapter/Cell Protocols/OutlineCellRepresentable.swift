//
//  OutlineCellRepresentable.swift
//  
//
//  Created by Anton Cherkasov on 29.05.2022.
//

import AppKit

public protocol OutlineCellRepresentable: NSView {
	associatedtype ViewModel: OutlineItemRepresentable
	init()
	var model: ViewModel? { get set }
	var valueDidChanged: ((ViewModel.ID, [String: Any]) -> Void)? { get set }
}
