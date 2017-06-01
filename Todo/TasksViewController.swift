//
//  TasksViewController.swift
//  Todo
//
//  Created by Arvind Ravi on 31/05/17.
//  Copyright © 2017 Arvind Ravi. All rights reserved.
//

import UIKit
import RealmSwift

class TasksViewController: UIViewController {
  
  // MARK: - IBOutlets
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!
  
  
  // MARK: - Properties
  var tasks: Results<Task>!
  var tasksList: List<Task>!
  var openTasks: Results<Task>!
  var completedTasks: Results<Task>!
  var filteredTasks: Results<Task>! {
    didSet {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  var createAction: UIAlertAction!
  var isSearchActive: Bool = false
  var editMode: Bool = false
  var currentSortState: SortBy! = .Title
  
  enum SortBy {
    case Priority
    case DateCreated
    case Title
  }
  
  // MARK: - Lifecycle Methods
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    updateUI()
    
    //Looks for single or multiple taps.
    let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TasksViewController.dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
  }
  
  // MARK: - IBActions
  
  // Add Button Tapped
  @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
    displayAddTaskAlert(nil)
  }
  
  // Edit Button Tapped
  @IBAction func editTasksTapped(_ sender: UIBarButtonItem) {
    editMode = !editMode
    tableView.setEditing(editMode, animated: true)
  }
  
  // Sort Button Tapped
  @IBAction func sortTasksTapped(_ sender: UIBarButtonItem) {
    displaySortTasksActionSheet()
  }
  
  
  // MARK: - Methods
  func dismissKeyboard() {
    view.endEditing(true)
    self.filteredTasks = nil
  }
  
  func updateUI() {
    // Get Tasks
    tasks = realm.objects(Task.self)
    
    // Filter Open & Completed Tasks
    openTasks      = realm.objects(Task.self).filter("completed = false")
    completedTasks = realm.objects(Task.self).filter("completed = true")
    
    // Update Table
    if self.currentSortState == .Priority {
      self.sortAndUpdateUI(sortBy: .Priority)
    } else if self.currentSortState == .DateCreated {
      self.sortAndUpdateUI(sortBy: .DateCreated)
    } else if self.currentSortState == .Title {
      self.sortAndUpdateUI(sortBy: .Title)
    } else {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  func displayAddTaskAlert(_ taskToBeUpdated: Task!) {
    // Alert Constants
    var title       = "New Task"
    var doneTitle   = "Create"
    let cancelTitle = "Cancel"
    
    if taskToBeUpdated != nil {
      title     = "Update Task"
      doneTitle = "Update"
    }
    
    // Alert Controller
    let alertController = UIAlertController(title: title, message: "Enter Task Title", preferredStyle: .alert)
    
    // Alert Actions
    let createAction = UIAlertAction(title: doneTitle, style: .default) { (action) in
      let taskTitle = alertController.textFields?.first?.text
      
      
      if taskToBeUpdated != nil { // Update Task
        try? realm.write {
          taskToBeUpdated.title = taskTitle!
          self.updateUI()
        }
      } else {  // New Task
        // Set TaskID
        var taskID: Int!
        if let lastTask = self.tasks.last {
         taskID = lastTask.id + 1
        } else {
          taskID = self.tasks.count + 1
        }
        
        // Create a new Task
        let task   = Task()
        task.title = taskTitle ?? ""
        task.id    = taskID
        task.priority = .Low
        
        // Write to Realm
        try? realm.write {
          realm.add(task)
          self.updateUI()
        }
        
        print(taskTitle ?? "")
      }
      
    }
    
    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
    
    alertController.addTextField { (textField) in
      textField.placeholder = "Enter task name"
      textField.addTarget(self, action: #selector(TasksViewController.taskNameFieldDidChange(_:)), for: .editingChanged)
      
      // Update TextField with Task Title if any
      if taskToBeUpdated != nil { textField.text = taskToBeUpdated.title }
    }
    
    // Present Alert Controller
    alertController.addAction(createAction)
    alertController.addAction(cancelAction)
    createAction.isEnabled = false
    self.createAction = createAction
    self.present(alertController, animated: true, completion: nil)
  }
  
  func taskNameFieldDidChange(_ textField:UITextField){
    guard let textFieldString = textField.text else { return }
    self.createAction.isEnabled = textFieldString.characters.count > 0
  }
  
  // MARK: - Sort
  func sortAndUpdateUI(sortBy: SortBy) {
    var keyPath: String!
    var ascending: Bool!
    if sortBy == .Priority {
      keyPath   = "priority"
      ascending = true
      currentSortState = .Priority
    } else if sortBy == .DateCreated {
      keyPath   = "createdAt"
      ascending = false
      currentSortState = .DateCreated
    } else {
      keyPath   = "title"
      ascending = true
      currentSortState = .Title
    }
    
    
    tasks = realm.objects(Task.self).sorted(byKeyPath: keyPath, ascending: ascending)
    openTasks      = realm.objects(Task.self).filter("completed = false").sorted(byKeyPath: keyPath, ascending: ascending)
    completedTasks = realm.objects(Task.self).filter("completed = true").sorted(byKeyPath: keyPath, ascending: ascending)
    
    DispatchQueue.main.async {
     self.tableView.reloadData()
    }
  }
  
  func displaySortTasksActionSheet() {
    // Action Sheet Constants
    let title = "Sort"
    let priorityActionTitle = "By Priority"
    let dateActionTitle = "By Date Created"
    let nameActionTitle = "By Name"
    
    let actionSheetController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
    
    let priorityAction = UIAlertAction(title: priorityActionTitle, style: .default) { (priorityAction) in
      print("Sorting by Priority")
      self.sortAndUpdateUI(sortBy: .Priority)
    }
    
    let dateAction = UIAlertAction(title: dateActionTitle, style: .default) { (dateAction) in
      print("Sorting by Date")
      self.sortAndUpdateUI(sortBy: .DateCreated)
    }
    
    let nameAction = UIAlertAction(title: nameActionTitle, style: .default) { (nameAction) in
      print("Sorting by Name")
      self.sortAndUpdateUI(sortBy: .Title)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    actionSheetController.addAction(priorityAction)
    actionSheetController.addAction(dateAction)
    actionSheetController.addAction(nameAction)
    actionSheetController.addAction(cancelAction)
    
    self.present(actionSheetController, animated: true, completion: nil)
  }
  
  func displayPriorityActionSheetFor(_ task: Task!) {
    // Action Sheet Constants
    let title           = "Set Priority"
    let highActionTitle = "High"
    let lowActionTitle  = "Low"
    
    // Alert Controller
    let actionSheetController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
    
    let highAction = UIAlertAction(title: highActionTitle, style: .destructive) { (highAction) in
      try? realm.write {
        task.priority = .High
      }
      if self.currentSortState == .Priority {
        self.sortAndUpdateUI(sortBy: .Priority)
      } else {
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      }
    }
    
    let lowAction = UIAlertAction(title: lowActionTitle, style: .default) { (lowAction) in
      try? realm.write {
        task.priority = .Low
      }
      if self.currentSortState == .Priority {
        self.sortAndUpdateUI(sortBy: .Priority)
      } else {
        DispatchQueue.main.async {
          self.tableView.reloadData()
        }
      }
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    actionSheetController.addAction(highAction)
    actionSheetController.addAction(lowAction)
    actionSheetController.addAction(cancelAction)
    
    self.present(actionSheetController, animated: true, completion: nil)
  }
}

// MARK: - Table View Datasource Methods
extension TasksViewController: UITableViewDataSource {
  // Number of Sections
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  
  // Number of Rows
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if filteredTasks != nil {
      if section == 0 {
        let openTasks = self.filteredTasks.filter("completed = false")
        guard openTasks.count > 0 else { return 0 }
        return openTasks.count
      } else {
        let completedTasks = self.filteredTasks.filter("completed = true")
        guard completedTasks.count > 0 else { return 0 }
        return completedTasks.count
      }
    } else {
      if section == 0 {
        guard let openTasks = self.openTasks else { return 0 }
        guard openTasks.count > 0 else { return 0 }
        return openTasks.count
      }
      guard let completedTasks = self.completedTasks else { return 0 }
      guard completedTasks.count > 0 else { return 0 }
      return completedTasks.count
    }
  }
  
  // Title for Headers
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if section == 0 {
      return "Open Tasks"
    }
    return "Completed Tasks"
  }
  
  // Cell Content
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.Identifiers.Cells.TaskCell) else { return UITableViewCell() }
    guard tasks.count > 0 else { return UITableViewCell() }
    let task: Task!
    var openTasks: Results<Task>!
    var completedTasks: Results<Task>!
    
    if filteredTasks != nil {
      openTasks = self.filteredTasks.filter("completed = false")
      completedTasks = self.filteredTasks.filter("completed = true")
    } else {
      openTasks = self.openTasks
      completedTasks = self.completedTasks
    }
    
    // Retrieve corresponding Task
    if indexPath.section == 0 {
      task = openTasks[indexPath.row]
    } else {
      task = completedTasks[indexPath.row]
    }
    
    // Set Title
    cell.textLabel?.text = task.title
    
    cell.detailTextLabel?.textColor = UIColor.gray
    if task.priority.rawValue == 0 {
      cell.detailTextLabel?.text  = "HIGH"
    } else {
      cell.detailTextLabel?.text = "LOW"
    }
    
    return cell
  }
}

// MARK: - Table View Delegate Methods
extension TasksViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    var task: Task!
    
    if indexPath.section == 0 {
      task = self.openTasks?[indexPath.row]
    } else {
      task = self.completedTasks?[indexPath.row]
    }
    
    self.displayPriorityActionSheetFor(task)
  }
  
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (deleteAction, indexPath) in
      
      var taskTitle: String!
      var task: Task!
      
      if indexPath.section == 0 {
        guard let openTasks = self.openTasks else { return }
        
        // Retrieve Task
        task = openTasks[indexPath.row]
        
        // Task Title for Reference
        taskTitle = task.title
        
      } else {
        guard let completedTasks = self.completedTasks else { return }
        
        // Retrieve Task
        task = completedTasks[indexPath.row]
        
        // Task Title for Reference
        taskTitle = task.title
        
      }
      
      // Reference to Realm Object
      let taskToRemove = realm.objects(Task.self).filter("title=%@", taskTitle)
    
      // Remove Task and Update UI
      try? realm.write {
        realm.delete(taskToRemove)
        self.updateUI()
      }
    }
    
    let completeAction = UITableViewRowAction(style: .normal, title: "Done") { (completeAction, indexPath) in
      var task: Task!
      
      if indexPath.section == 0 {
        task = self.openTasks?[indexPath.row]
      } else {
        task = self.completedTasks?[indexPath.row]
      }
      
      try? realm.write {
        task.completed = true
        self.updateUI()
      }
    }
    
    let editAction = UITableViewRowAction(style: .normal, title: "Edit") { (editAction, indexPath) in
      var task: Task!
      
      if indexPath.section == 0 {
        task = self.openTasks?[indexPath.row]
      } else {
        task = self.completedTasks?[indexPath.row]
      }
      
      self.displayAddTaskAlert(task)
    }
    
    // Set Background Colors
    completeAction.backgroundColor = UIColor(rgb: 0x27ae60)
    editAction.backgroundColor     = UIColor(rgb: 0xf39c12)
    
    if indexPath.section == 0 {
      return [deleteAction, completeAction, editAction]
    } else {
      return [deleteAction, editAction]
    }
    
  }
}

// MARK: - Search Bar Delegate Methods
extension TasksViewController: UISearchBarDelegate {
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    isSearchActive = true
  }
  
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    isSearchActive = false
  }
  
  func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
    return true
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    isSearchActive = false
    self.filteredTasks = nil
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    isSearchActive = false
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    guard !searchText.isEmpty else {
      self.filteredTasks = self.tasks
      return
    }
    let predicate = NSPredicate(format: "title CONTAINS [c] %@", searchText)
    let filteredTasks = realm.objects(Task.self).filter(predicate)
    self.filteredTasks = filteredTasks
  }
}
