//
//  DisplayViewController.swift
//  nekofiles
//
//  Created by samara on 2/24/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import UIKit

class DisplayViewController: FRSTableViewController {

    // Lazy loading of collection data for performance
    lazy var collectionData: [String] = {
        return ["Default", "Berry", "Mint", "Dr Pepper", "Cool Blue", "Fuchsia", "Purplish"]
    }()
    
    // Use an array of UIColor instead of hex strings for better color management
    lazy var collectionDataColors: [UIColor] = {
        return [
            UIColor(hex: "848ef9") ?? .blue,
            UIColor(hex: "ff7a83") ?? .red,
            UIColor(hex: "a6e3a1") ?? .green,
            UIColor(hex: "711f25") ?? .brown,
            UIColor(hex: "4161F1") ?? .blue,
            UIColor(hex: "FF00FF") ?? .magenta,
            UIColor(hex: "D7B4F3") ?? .purple
        ]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = String.localized("SETTINGS_VIEW_CONTROLLER_CELL_DISPLAY")
        
        tableData = [
            [String.localized("APP_SIGNING_INPUT_VIEW_CONTROLLER_SECTION_TITLE_APPEARENCE")],
            ["Collection View"],
            [],
            ["Certificate Name"]
        ]
        
        sectionTitles = [
            "",
            String.localized("DISPLAY_VIEW_CONTROLLER_SECTION_TITLE_TINT_COLOR"),
            String.localized("DISPLAY_VIEW_CONTROLLER_SECTION_TITLE_STORE"),
            String.localized("CERTIFICATES_VIEW_CONTROLLER_TITLE")
        ]
        
        self.tableView.register(CollectionTableViewCell.self, forCellReuseIdentifier: "CollectionCell")
    }
    
    private func updateAppearance(with style: UIUserInterfaceStyle) {
        view.window?.overrideUserInterfaceStyle = style
        Preferences.preferredInterfaceStyle = style.rawValue
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension DisplayViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return 3
        } else {
            return tableData[section].count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        var cell: UITableViewCell
        
        if indexPath.section == 2 {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
            configureStoreCell(cell, at: indexPath)
        } else {
            let cellText = tableData[indexPath.section][indexPath.row]
            switch cellText {
            case String.localized("APP_SIGNING_INPUT_VIEW_CONTROLLER_SECTION_TITLE_APPEARENCE"):
                cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
                configureAppearanceCell(cell)
            case "Collection View":
                cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath) as! CollectionTableViewCell
                (cell as! CollectionTableViewCell).setData(collectionData: collectionData, colors: collectionDataColors)
                cell.backgroundColor = .clear
            case "Certificate Name":
                cell = SwitchViewCell()
                configureCertificateNameCell(cell as! SwitchViewCell)
            default:
                cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
            }
        }
        
        cell.accessibilityLabel = cell.textLabel?.text
        cell.selectionStyle = .none
        return cell
    }
    
    private func configureStoreCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CELL_DEFAULT_SUBTITLE")
            cell.detailTextLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CELL_DEFAULT_SUBTITLE_DESCRIPTION")
        case 1:
            cell.textLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CELL_LOCALIZED_SUBTITLE")
            cell.detailTextLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CELL_LOCALIZED_SUBTITLE_DESCRIPTION")
        case 2:
            cell.textLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CELL_BIG_DESCRIPTION")
            cell.detailTextLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CELL_BIG_DESCRIPTION_DESCRIPTION")
        default:
            break
        }
        
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0

        if Preferences.appDescriptionAppearence == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
    }
    
    private func configureAppearanceCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = String.localized("APP_SIGNING_INPUT_VIEW_CONTROLLER_SECTION_TITLE_APPEARENCE")
        let segmentedControl = UISegmentedControl(items: UIUserInterfaceStyle.allCases.map { $0.description })
        segmentedControl.selectedSegmentIndex = UIUserInterfaceStyle.allCases.firstIndex { $0.rawValue == Preferences.preferredInterfaceStyle } ?? 0
        segmentedControl.addTarget(self, action: #selector(appearanceSegmentedControlChanged(_:)), for: .valueChanged)
        segmentedControl.accessibilityLabel = String.localized("APPEARANCE_SEGMENTED_CONTROL")
        cell.accessoryView = segmentedControl
    }
    
    private func configureCertificateNameCell(_ cell: SwitchViewCell) {
        cell.textLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CELL_TEAM_NAME")
        cell.switchControl.addTarget(self, action: #selector(certificateNameToggle(_:)), for: .valueChanged)
        cell.switchControl.isOn = Preferences.certificateTitleAppIDtoTeamID
        cell.selectionStyle = .none
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            let previousSelection = Preferences.appDescriptionAppearence
            Preferences.appDescriptionAppearence = indexPath.row

            let previousIndexPath = IndexPath(row: previousSelection, section: indexPath.section)
            tableView.reloadRows(at: [previousIndexPath, indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 3:
            return String.localized("DISPLAY_VIEW_CONTROLLER_CELL_TEAM_NAME_DESCRIPTION")
        default:
            return nil
        }
    }
    
    @objc private func appearanceSegmentedControlChanged(_ sender: UISegmentedControl) {
        let selectedStyle = UIUserInterfaceStyle.allCases[sender.selectedSegmentIndex]
        updateAppearance(with: selectedStyle)
    }
    
    @objc private func certificateNameToggle(_ sender: UISwitch) {
        Preferences.certificateTitleAppIDtoTeamID = sender.isOn
    }
}

// Helper extension for UIColor from hex
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        
        let length = hexSanitized.count
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
            
        } else {
            return nil
        }
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}