//
//  SourceAppViewController.swift
//  feather
//
//  Created by samara on 5/22/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import UIKit
import Nuke
import AlertKit
import CoreData
import SwiftUI

class SourceAppViewController: UITableViewController {
    var newsData: [NewsData] = []
    var apps: [StoreAppsData] = []
    var oApps: [StoreAppsData] = []
    var filteredApps: [StoreAppsData] = []
    
    var name: String? { didSet { self.title = name } }
    var uri: [URL]!
    
    var highlightAppName: String?
    var highlightBundleID: String?
    var highlightVersion: String?
    var highlightDeveloperName: String?
    var highlightDescription: String?
    
    var sortActionsGroup: UIMenu?
    
    private let sourceGET = SourceGET()
    
    public var searchController: UISearchController!
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    init() { super.init(style: .plain) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        o setupSearchController()
        setupViews()
        loadAppsData()
    }
    
    fileprivate func setupViews() {
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.tableHeaderView = UIView()
        self.tableView.register(AppTableViewCell.self, forCellReuseIdentifier: "AppTableViewCell")
        self.navigationItem.titleView = activityIndicator
        self.activityIndicator.startAnimating()
    }
    
    private func setupHeader() {
        guard uri.count == 1, !newsData.isEmpty else { return }
        let headerView = UIHostingController(rootView: NewsCardsScrollView(newsData: newsData))
        headerView.view.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 170)
        tableView.tableHeaderView = headerView.view
        
        addChild(headerView)
        headerView.didMove(toParent: self)
    }
    
    private func updateFilterMenu() {
        let filterMenu = UIMenu(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_TITLE"), children: createSubSortMenu())
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease"), menu: filterMenu)
        
        self.navigationItem.rightBarButtonItem = filterButton
    }
    
    private func createSubSortMenu() -> [UIMenuElement] {
        let sortByDefaultAction = createSortAction(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_BY_DEFAULT"), sortOption: .default)
        let sortByNameAction = createSortAction(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_BY_NAME"), sortOption: .name)
        let sortByDateAction = createSortAction(title: String.localized("SOURCES_CELLS_ACTIONS_FILTER_BY_DATE"), sortOption: .date)
        
        return [UIMenu(options: .displayInline, children: [sortByDefaultAction, sortByNameAction, sortByDateAction])]
    }
    
    func applyFilter() {
        let sortOption = Preferences.currentSortOption
        let ascending = Preferences.currentSortOptionAscending
        
        switch sortOption {
        case .default:
            apps = ascending ? oApps : oApps.reversed()
        case .name:
            apps = apps.sorted { ascending ? $0.name < $1.name : $0.name > $1.name }
        case .date:
            apps = apps.sorted {
                let date0 = $0.versions?.first?.date ?? $0.versionDate
                let date1 = $1.versions?.first?.date ?? $1.versionDate
                
                if date0 == nil && date1 == nil { return ascending }
                guard let date0 = date0, let date1 = date1 else { return date0 != nil }
                return ascending ? date0 > date1 : date0 < date1
            }
        }
        
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
        
        updateFilterMenu()
    }
    
    private func createSortAction(title: String, sortOption: SortOption) -> UIAction {
        return UIAction(title: title,
                       image: arrowImage(for: sortOption),
                       identifier: UIAction.Identifier("sort\(title)"),
                       state: Preferences.currentSortOption == sortOption ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            if Preferences.currentSortOption == sortOption {
                Preferences.currentSortOptionAscending.toggle()
            } else {
                Preferences.currentSortOption = sortOption
            }
            self.applyFilter()
        }
    }
    
    private func arrowImage(for sortOption: SortOption) -> UIImage? {
        guard sortOption == Preferences.currentSortOption else { return nil }
        return UIImage(systemName: Preferences.currentSortOptionAscending ? "chevron.up" : "chevron.down")
    }
    
    fileprivate func setupNavigation() {
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    private func loadAppsData() {
        guard let urls = uri else { return }
        let dispatchGroup = DispatchGroup()
        var allApps: [StoreAppsData] = []
        var newsData: [NewsData] = []
        var website: String = ""
        var tintColor: String = ""
        
        for url in urls {
            dispatchGroup.enter()
            sourceGET.downloadURL(from: url) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let (data, _)):
                    if let parseResult = self.sourceGET.parse(data: data), case .success(let sourceData) = parseResult {
                        allApps.append(contentsOf: sourceData.apps)
                        newsData.append(contentsOf: sourceData.news ?? [])
                        tintColor = sourceData.tintColor ?? ""
                        website = sourceData.website ?? ""
                    }
                case .failure(let error):
                    Debug.shared.log(message: "Error fetching data from \(url): \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.apps = allApps
            self.oApps = allApps
            self.newsData = newsData
            
            self.setupHeader()
            
            if !tintColor.isEmpty {
                self.view.tintColor = UIColor(hex: tintColor)
            }
            
            if let filteredApp = self.shouldFilter() {
                self.apps = [filteredApp]
            } else {
                self.applyFilter()
            }
            
            if self.uri.count == 1, !website.isEmpty, #available(iOS 16.0, *) {
                let menu = UIMenu(children: [
                    UIAction(title: "Visit Website", image: UIImage(systemName: "globe")) { _ in
                        UIApplication.shared.open(URL(string: website)!, options: [:], completionHandler: nil)
                    }
                ])
                self.navigationItem.titleMenuProvider = { _ in menu }
            }
            
            UIView.transition(with: self.tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.activityIndicator.stopAnimating()
                self.navigationItem.titleView = nil
                if self.highlightAppName == nil {
                    self.updateFilterMenu()
                }
                self.tableView.reloadData()
            }, completion: nil)
        }
    }
    
    private func shouldFilter() -> StoreAppsData? {
        guard let name = highlightAppName,
              let id = highlightBundleID,
              let version = highlightVersion,
              let desc = highlightDescription else { return nil }
        
        return apps.first { app in
            app.name == name &&
            app.bundleIdentifier == id &&
            app.version == version &&
            app.localizedDescription == desc &&
            (highlightDeveloperName == nil || app.developerName == highlightDeveloperName)
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension SourceAppViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredApps.count : apps.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let app = isFiltering ? filteredApps[indexPath.row] : apps[indexPath.row]
        if let screenshots = app.screenshotURLs, !screenshots.isEmpty, Preferences.appDescriptionAppearence != 2 {
            return 322
        } else if Preferences.appDescriptionAppearence == 2 {
            return UITableView.automaticDimension
        }
        return 72
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AppTableViewCell", for: indexPath) as! AppTableViewCell
        let app = isFiltering ? filteredApps[indexPath.row] : apps[indexPath.row]
        cell.configure(with: app)
        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.getButton.tag = indexPath.row
        cell.getButton.addTarget(self, action: #selector(getButtonTapped(_:)), for: .touchUpInside)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(getButtonHold(_:)))
        cell.getButton.addGestureRecognizer(longPressGesture)
        cell.getButton.longPressGestureRecognizer = longPressGesture
        return cell
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let app = isFiltering ? filteredApps[indexPath.row] : apps[indexPath.row]
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let versionActions = (app.versions ?? []).map { version in
                UIAction(title: version.version, image: UIImage(systemName: "doc.on.clipboard")) { _ in
                    UIPasteboard.general.string = version.downloadURL.absoluteString
                }
            }
            
            let versionsMenu = UIMenu(title: "Other Download Links", image: UIImage(systemName: "list.bullet"), children: versionActions)
            let latestAction = UIAction(title: "Copy Latest Download Link", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = app.downloadURL?.absoluteString ?? app.versions?.first?.downloadURL.absoluteString
            }
            
            return UIMenu(children: [latestAction, versionsMenu])
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !isFiltering, !apps.isEmpty, highlightAppName == nil else { return nil }
        return String.localized(apps.count > 1 ? "SOURCES_APP_VIEW_CONTROLLER_NUMBER_OF_APPS_PLURAL" : "SOURCES_APP_VIEW_CONTROLLER_NUMBER_OF_APPS", arguments: "\(apps.count)")
    }
}

// MARK: - Search Controller
extension SourceAppViewController: UISearchControllerDelegate, UISearchBarDelegate {
    func setupSearchController() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.placeholder = String.localized("SOURCES_APP_VIEW_CONTROLLER_SEARCH_APPS")
        if highlightAppName == nil {
            navigationItem.searchController = searchController
            definesPresentationContext = true
            navigationItem.hidesSearchBarWhenScrolling = true
        }
    }
    
    var isFiltering: Bool {
        searchController.isActive && !searchBarIsEmpty
    }
    
    var searchBarIsEmpty: Bool {
        searchController.searchBar.text?.isEmpty ?? true
    }
}

// MARK: - Search Results Updating
extension SourceAppViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased() {
            filteredApps = apps.filter { app in
                app.name.lowercased().contains(searchText) ||
                app.bundleIdentifier.lowercased().contains(searchText) ||
                app.developerName?.lowercased().contains(searchText) ?? false ||
                app.subtitle?.lowercased().contains(searchText) ?? false ||
                app.localizedDescription?.lowercased().contains(searchText) ?? false
            }
            tableView.reloadData()
        }
    }
}

// MARK: - Button Actions
extension SourceAppViewController {
    @objc func getButtonTapped(_ sender: UIButton) {
        // Implementation for button tap
    }
    
    @objc func getButtonHold(_ gesture: UILongPressGestureRecognizer) {
        // Implementation for button long press
    }
}