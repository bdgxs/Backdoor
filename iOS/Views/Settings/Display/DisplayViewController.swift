//
//  DisplayViewController.swift
//  nekofiles
//
//  Created by samara on 2/24/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import UIKit

class DisplayViewController: FRSTableViewController {

    lazy var collectionData: [String] = {
        return ["Default", "Berry", "Mint", "Dr Pepper", "Cool Blue", "Fuchsia", "Purplish"]
    }()
    
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
            ["Collection View", "Custom Tint Color"],
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
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CustomTintCell")
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
        let cellText = tableData[indexPath.section][indexPath.row]
        
        switch (indexPath.section, indexPath.row) {
        case (1, 0): // Collection View
            let cell = tableView.dequeueReusableCell(withIdentifier: "CollectionCell", for: indexPath) as! CollectionTableViewCell
            cell.setData(collectionData: collectionData, colors: collectionDataColors)
            cell.backgroundColor = .clear
            return cell
        case (1, 1): // Custom Tint Color
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTintCell", for: indexPath)
            configureCustomTintCell(cell)
            return cell
        case (0, 0): // Appearance
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            configureAppearanceCell(cell)
            return cell
        case (2, _): // Store Options
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            configureStoreCell(cell, at: indexPath)
            return cell
        case (3, 0): // Certificate Name
            let cell = SwitchViewCell()
            configureCertificateNameCell(cell)
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: "Cell")
        }
    }
    
    private func configureCustomTintCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = String.localized("DISPLAY_VIEW_CONTROLLER_CUSTOM_TINT_COLOR")
        cell.accessoryType = .disclosureIndicator
        
        // Assuming you have a method to get the current tint color
        let currentColor = Preferences.currentTintColor ?? UIColor.systemBlue
        cell.detailTextLabel?.text = "RGB: \(Int(currentColor.r * 255)), \(Int(currentColor.g * 255)), \(Int(currentColor.b * 255))"
        cell.detailTextLabel?.textColor = .secondaryLabel
    }
    
    private func configureAppearanceCell(_ cell: UITableViewCell) {
        cell.textLabel?.text = String.localized("APP_SIGNING_INPUT_VIEW_CONTROLLER_SECTION_TITLE_APPEARENCE")
        let segmentedControl = UISegmentedControl(items: UIUserInterfaceStyle.allCases.map { $0.description })
        segmentedControl.selectedSegmentIndex = UIUserInterfaceStyle.allCases.firstIndex { $0.rawValue == Preferences.preferredInterfaceStyle } ?? 0
        segmentedControl.addTarget(self, action: #selector(appearanceSegmentedControlChanged(_:)), for: .valueChanged)
        segmentedControl.accessibilityLabel = String.localized("APPEARANCE_SEGMENTED_CONTROL")
        cell.accessoryView = segmentedControl
    }
    
    private func configureStoreCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        // ... (same as before)
    }
    
    private func configureCertificateNameCell(_ cell: SwitchViewCell) {
        // ... (same as before)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 1 { // Custom Tint Color
            showColorPicker()
        } else if indexPath.section == 2 {
            let previousSelection = Preferences.appDescriptionAppearence
            Preferences.appDescriptionAppearence = indexPath.row

            let previousIndexPath = IndexPath(row: previousSelection, section: indexPath.section)
            tableView.reloadRows(at: [previousIndexPath, indexPath], with: .fade)
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        // ... (same as before)
    }
    
    @objc private func appearanceSegmentedControlChanged(_ sender: UISegmentedControl) {
        // ... (same as before)
    }
    
    @objc private func certificateNameToggle(_ sender: UISwitch) {
        // ... (same as before)
    }
    
    private func showColorPicker() {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        colorPickerVC.selectedColor = Preferences.currentTintColor ?? .blue
        colorPickerVC.supportsAlpha = true // Allow transparency if needed
        present(colorPickerVC, animated: true, completion: nil)
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension DisplayViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        let selectedColor = viewController.selectedColor
        Preferences.currentTintColor = selectedColor
        updateTintColor(selectedColor)
        tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .automatic)
    }
    
    private func updateTintColor(_ color: UIColor) {
        // Update the tint color for the view or any other UI elements here
        view.tintColor = color
        // Update any other UI elements that need to reflect the tint color change
    }
}

// Helper extension for UIColor from hex and RGB values
extension UIColor {
    convenience init?(hex: String) {
        // ... (same as before)
    }
    
    var r: CGFloat {
        // ... (same as before)
    }
    
    var g: CGFloat {
        // ... (same as before)
    }
    
    var b: CGFloat {
        // ... (same as before)
    }
}