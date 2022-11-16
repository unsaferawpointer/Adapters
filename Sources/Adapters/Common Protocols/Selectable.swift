//
//  Selectable.swift
//  
//
//  Created by Anton Cherkasov on 05.11.2022.
//

public protocol Selectable {
	var itemDidSelected: (() -> Void)? { get set }
}
