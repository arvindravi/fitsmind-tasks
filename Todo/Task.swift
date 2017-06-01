//
//  Task.swift
//  Todo
//
//  Created by Arvind Ravi on 31/05/17.
//  Copyright © 2017 Arvind Ravi. All rights reserved.
//

import RealmSwift

class Task: Object {
  // MARK: - Enums
  @objc enum Priority: Int {
    case High
    case Low
  }
  
  // MARK: - Properties
  dynamic var id: Int            = 0
  dynamic var title: String      = ""
  dynamic var createdAt: Date    = Date()
  dynamic var completed: Bool    = false
  dynamic var priority: Priority = .Low
}
