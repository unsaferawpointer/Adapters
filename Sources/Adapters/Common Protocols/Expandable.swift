//
//  Expandable.swift
//  
//
//  Created by Anton Cherkasov on 14.11.2022.
//

protocol Expandable {
	var alwaysExpanded: Bool { get }
	var itemDidExpand: () -> Void { get }
	var itemDidCollapse: () -> Void { get }
}
