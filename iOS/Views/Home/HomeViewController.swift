import UIKit
 import ZIPFoundation
 

 class HomeViewController: UIViewController, UIDocumentPickerDelegate, UISearchResultsUpdating, UITableViewDragDelegate, UITableViewDropDelegate, UITableViewDelegate, UITableViewDataSource, FileHandlingDelegate {
 

  // MARK: - Properties
  private var fileList: [String] =
  private var filteredFileList: [String] =
  private let fileManager = FileManager.default
  private let searchController = UISearchController(searchResultsController: nil)
  private var sortOrder: SortOrder = .name
  let fileHandlers = HomeViewFileHandlers()
  let utilities = HomeViewUtilities()
 

  var documentsDirectory: URL {
  let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("files")
  createFilesDirectoryIfNeeded(at: directory)
  return directory
  }
 

  enum SortOrder {
  case name, date, size
  }
 

  
  let fileListTableView = UITableView()
  let activityIndicator = UIActivityIndicatorView(style: .large)
 

  // MARK: - Lifecycle
  override func viewDidLoad() {
  super.viewDidLoad()
  setupUI()
  setupActivityIndicator()
  loadFiles()
  configureTableView()
  }
 

  // MARK: - UI Setup
  private func setupUI() {
  view.backgroundColor = .systemBackground
 

  let navItem = UINavigationItem(title: "Files")
  let menuButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
  let uploadButton = UIBarButtonItem(image: UIImage(systemName: "arrow.up.doc"), style: .plain, target: self, action: #selector(uploadFile))
  navItem.rightBarButtonItems = [menuButton, uploadButton]
  let navBar = UINavigationBar()
  navBar.translatesAutoresizingMaskIntoConstraints = false
  navBar.barTintColor = .systemBlue
  navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
  navBar.setItems([navItem], animated: false)
  view.addSubview(navBar)
 

  searchController.searchResultsUpdater = self
  searchController.obscuresBackgroundDuringPresentation = false
  searchController.searchBar.placeholder = "Search Files"
  navigationItem.searchController = searchController
  definesPresentationContext = true
 

  fileListTableView.translatesAutoresizingMaskIntoConstraints = false
  fileListTableView.separatorStyle = .singleLine
  fileListTableView.rowHeight = UITableView.automaticDimension
  fileListTableView.estimatedRowHeight = 44
  view.addSubview(fileListTableView)
 

  NSLayoutConstraint.activate([
  navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
  navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
  navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
 

  fileListTableView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
  fileListTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
  fileListTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
  fileListTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
  ])
  }
 

  private func setupActivityIndicator() {
  activityIndicator.translatesAutoresizingMaskIntoConstraints = false
  activityIndicator.hidesWhenStopped = true
  activityIndicator.color = .systemBlue
  
  view.addSubview(activityIndicator)
 

  NSLayoutConstraint.activate([
  activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
  activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
  ])
  }
 

  private func createFilesDirectoryIfNeeded(at directory: URL) {
  if !fileManager.fileExists(atPath: directory.path) {
  do {
  try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
  } catch {
  utilities.handleError(in: self, error: error, withTitle: "Error Creating Directory")
  }
  }
  }
 

  private func configureTableView() {
  fileListTableView.delegate = self
  fileListTableView.dataSource = self
  fileListTableView.dragDelegate = self
  fileListTableView.dropDelegate = self
  searchController.searchResultsUpdater = self
  navigationItem.searchController = searchController
  definesPresentationContext = true
  fileListTableView.register(FileTableViewCell.self, forCellReuseIdentifier: "FileCell")
  }
 

  // 
  // MARK: - File Operations
  func loadFiles() {
  activityIndicator.startAnimating()
  fileList =
  DispatchQueue.global().async { [weak self] in
  guard let self = self else { return }
  do {
  let files = try self.fileManager.contentsOfDirectory(atPath: self.documentsDirectory.path)
  self.fileList = files.filter { !$0.hasPrefix(".") }
  self.sortFiles()
  DispatchQueue.main.async {
  self.filteredFileList = self.fileList
  self.fileListTableView.reloadData()
  self.activityIndicator.stopAnimating()
  }
  } catch {
  DispatchQueue.main.async {
  self.activityIndicator.stopAnimating()
  self.utilities.handleError(in: self, error: error, withTitle: "Error Loading Files")
  }
  }
  }
 

  func sortFiles() {
  guard !fileList.isEmpty else { return }
  switch sortOrder {
  case .name:
  fileList.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
  case .date:
  fileList.sort {
  let url1 = documentsDirectory.appendingPathComponent($0)
  let url2 = documentsDirectory.appendingPathComponent($1)
  if let date1 = try?
  fileManager.attributesOfItem(atPath: url1.path).fileModificationDate,
  let date2 = try? fileManager.attributesOfItem(atPath: url2.path).fileModificationDate {
  return date1 < date2
  }
  return false
  }
  case .size:
  fileList.sort {
  let url1 = documentsDirectory.appendingPathComponent($0)
  let url2 = documentsDirectory.appendingPathComponent($1)
  if let size1 = try?
  fileManager.attributesOfItem(atPath: url1.path).fileSize,
  let size2 = try? fileManager.attributesOfItem(atPath: url2.path).fileSize {
  return size1 < size2
  }
  return false
  }
  }
  }
 

  func showFileOptions(for fileURL: URL) {
  let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
 

  let openAction = UIAlertAction(title: "Open", style: .default) { [weak self] _ in
  self?.openFile(at: fileURL)
  }
  alertController.addAction(openAction)
 

  let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
  self?.showRenameDialog(for: fileURL)
  }
  alertController.addAction(renameAction)
 

  let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
  self?.deleteFile(at: fileURL)
  }
  alertController.addAction(deleteAction)
 

  if fileURL.pathExtension == "zip" {
  let unzipAction = UIAlertAction(title: "Unzip", style: .default) { [weak self] _ in
  self?.unzipFile(at: fileURL)
  }
  alertController.addAction(unzipAction)
  }
 

  let shareAction = UIAlertAction(title: "Share", style: .default) { [weak self] _ in
  self?.fileHandlers.shareFile(viewController: self, fileURL: fileURL)
  }
  alertController.addAction(shareAction)
 

  let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
  alertController.addAction(cancelAction)
 

  present(alertController, animated: true, completion: nil)
  }
 

  func openFile(at fileURL: URL) {
  if ["txt", "md", "swift", "js", "html", "css"].contains(fileURL.pathExtension) {
  let textEditorVC = 
  TextEditorViewController(fileURL: fileURL)
  navigationController?.pushViewController(textEditorVC, animated: true)
  } else if fileURL.pathExtension == "plist" {
  let plistEditorVC = PlistEditorViewController(fileURL: fileURL)
  navigationController?.pushViewController(plistEditorVC, animated: true)
  } else {
  UIDocumentInteractionController(url: fileURL).presentPreview(animated: true)
  }
  }
 

  func deleteFile(at fileURL: URL) {
  fileHandlers.deleteFile(viewController: self, fileURL: fileURL) { result in
  switch result {
  case .success(_):
  break
  case .failure(let error):
  self.utilities.handleError(in: self, error: error, withTitle: "Error Deleting File")
  }
  }
  }
 

  func unzipFile(at fileURL: URL) {
  let destinationName = fileURL.deletingPathExtension().lastPathComponent
  let destinationURL = documentsDirectory.appendingPathComponent(destinationName)
 

  let progress = Progress(totalUnitCount: 100) // Initialize Progress
  
  do {
  let archive = try Archive(url: fileURL, accessMode: .read)
  
  try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
  
  try archive.extractAll(to: destinationURL, progress: progress) { entry in
  // Update progress here based on the entry, if needed.
  // ZIPFoundation doesn't give a simple percentage, but you can
  // track the number of files or bytes processed if you need more granular progress.
  // For now, we rely on ZIPFoundation's internal progress updates.
  print("Extracted: \(entry.path)") // You can log this or use it for more complex progress updates
  }
  
  // Handle completion on the main thread
  DispatchQueue.main.async {
  self.loadFiles() // Reload files to show the unzipped content
  }
  
  } catch {
  // Handle errors on the main thread
  DispatchQueue.main.async {
  self.utilities.handleError(in: self, error: error, withTitle: "Error Unzipping File")
  }
  }
  }
 

  func showRenameDialog(for fileURL: URL) {
  let alertController = UIAlertController(title: "Rename File", message: "Enter new file name", preferredStyle: .alert)
  alertController.addTextField()
  let renameAction = UIAlertAction(title: "Rename", style: .default) { [weak self] _ in
  guard let self = self, let newName = alertController.textFields?.first?.text, !newName.isEmpty else { return }
  let newURL = fileURL.deletingLastPathComponent().appendingPathComponent(newName)
  do {
  try FileManager.default.moveItem(at: fileURL, to: newURL)
  self.loadFiles()
  } catch {
  self.utilities.handleError(in: self, error: error, withTitle: "Error Renaming File")
  }
  }
  alertController.addAction(renameAction)
  let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
  alertController.addAction(cancelAction)
  present(alertController, animated: true, completion: nil)
  }
 

  // MARK: - UI Actions
 

  @objc func uploadFile() {
  fileHandlers.uploadFile(viewController: self)
  }
 

  @objc func showMenu() {
  let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
 

  let newFolderAction = UIAlertAction(title: "New Folder", style: .default) { [weak self] _ in
  self?.showNewFolderDialog()
  }
  alertController.addAction(newFolderAction)
 

  let newFileAction = UIAlertAction(title: "New File", style: .default) { [weak self] _ in
  self?.showNewFileDialog()
  }
  alertController.addAction(newFileAction)
 

  let sortAction = UIAlertAction(title: "Sort", style: .default) { [weak self] _ in
  self?.showSortOptions()
  }
  alertController.addAction(sortAction)
 

  let importAction = UIAlertAction(title: "Import File", style: .default) { [weak self] _ in
  self?.fileHandlers.importFile(viewController: self)
  }
  alertController.addAction(importAction)
 

  let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
  alertController.addAction(cancelAction)
 

  present(alertController, animated: true, completion: nil)
  }
 

  /// Shows a dialog to create a new folder.
  func showNewFolderDialog() {
  let alertController = UIAlertController(title: "New Folder", message: "Enter folder name", preferredStyle: .alert)
  alertController.addTextField()
  let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
  guard let self = self, let folderName = alertController.textFields?.first?.text, !folderName.isEmpty else { return }
  self.fileHandlers.createNewFolder(viewController: self, folderName: folderName) { result in
  switch result {
  case .success(_):
  break // No extra handling needed, folder created and list reloaded
  case .failure(let error):
  self.utilities.handleError(in: self, error: error, withTitle: "Error Creating Folder")
  }
  }
  }
  alertController.addAction(createAction)
  let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
  alertController.addAction(cancelAction)
  present(alertController, animated: true, completion: nil)
  }
 

  /// Shows a dialog to create a new file.
  func showNewFileDialog() {
  let alertController = UIAlertController(title: "New File", message: "Enter file name", preferredStyle: .alert)
  alertController.addTextField()
  let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
  guard let self = self, let fileName = alertController.textFields?.first?.text, !fileName.isEmpty else { return }
  self.fileHandlers.createNewFile(viewController: self, fileName: fileName) { result in
  switch result {
  case .success(_):
  break // No extra handling needed, file created and list reloaded
  case .failure(let error):
  self.utilities.handleError(in: self, error: error, withTitle: "Error Creating File")
  }
  }
  }
  alertController.addAction(createAction)
  let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
  alertController.addAction(cancelAction)
  present(alertController, animated: true, completion: nil)
  }
 

  func showSortOptions() {
  let alertController = UIAlertController(title: "Sort by", message: nil, preferredStyle: .actionSheet)
 

  let sortByNameAction = UIAlertAction(title: "Name", style: .default) { [weak self] _ in
  self?.sortOrder = .name
  self?.sortFiles()
  self?.fileListTableView.reloadData()
  }
  alertController.addAction(sortByNameAction)
 

  let sortByDateAction = UIAlertAction(title: "Date", style: .default) { [weak self] _ in
  self?.sortOrder = .date
  self?.sortFiles()
  self?.fileListTableView.reloadData()
  }
  alertController.addAction(sortByDateAction)
 

  let sortBySizeAction = UIAlertAction(title: "Size", style: .default) { [weak self] _ in
  self?.sortOrder = .size
  self?.sortFiles()
  self?.fileListTableView.reloadData()
  }
  alertController.addAction(sortBySizeAction)
 

  let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
  alertController.addAction(cancelAction)
 

  present(alertController, animated: true, completion: nil)
  }
 

  // MARK: - UISearchResultsUpdating
  func updateSearchResults(for searchController: UISearchController) {
  guard let searchText = searchController.searchBar.text else { return }
  filteredFileList = fileList.filter { $0.localizedCaseInsensitiveContains(searchText) }
  fileListTableView.reloadData()
  }
 

  // MARK: - UITableViewDragDelegate
  func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
  let item = self.fileList[indexPath.row]
  let itemProvider = NSItemProvider(object: item as NSString)
  let dragItem = UIDragItem(itemProvider: itemProvider)
  return [dragItem]
  }
 

  // MARK: - UITableViewDropDelegate
  func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
  coordinator.session.loadObjects(ofClass: NSString.self) { items in
  guard let string = items.first as? String else { return }
  self.fileList.append(string as String)
  self.fileListTableView.reloadData()
  }
  }
 

  func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
  return session.canLoadObjects(ofClass: NSString.self)
  }
