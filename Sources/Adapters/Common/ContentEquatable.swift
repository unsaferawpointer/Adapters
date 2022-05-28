//
//  ContentEquatable.swift
//  Adapters
//
//  Created by Anton Cherkasov on 15.02.2022.
//

import Foundation

public protocol ContentEquatable {
	func isContentEqual(to source: Self) -> Bool
}
