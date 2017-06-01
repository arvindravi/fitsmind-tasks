//
//  TodoList.swift
//  Todo
//
//  Created by Arvind Ravi on 31/05/17.
//  Copyright © 2017 Arvind Ravi. All rights reserved.
//

import RealmSwift

class TodoList: Object {
  // MARK: - Properties
  dynamic var title: String   = ""
  dynamic var createdAt: Date = Date()
  let tasks = List<Task>()
}
