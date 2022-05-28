//
//  OutlineGroupPresentable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 10.05.2022.
//

import Foundation

public protocol OutlineGroupPresentable: CellModel {

	associatedtype Item: OutlineItemRepresentable

	var title: String { get set }
	var alwaysExpanded: Bool { get set }
	var children: [Item] { get set }

}
