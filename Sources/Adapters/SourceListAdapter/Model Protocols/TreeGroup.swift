//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 26.06.2022.
//

public struct TreeGroup<GroupModel: SourceListGroupRepresentable, ItemModel: SourceListItemRepresentable> {

	public var viewModel: GroupModel
	public var children: [TreeItem<ItemModel>]

	public init(viewModel: GroupModel, children: [TreeItem<ItemModel>]) {
		self.viewModel = viewModel
		self.children = children
	}
}
