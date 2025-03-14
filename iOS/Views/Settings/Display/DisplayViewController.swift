//
//  DisplayViewController.swift
//  nekofiles
//
//  Created by samara on 2/24/24.
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import UIKit

class DisplayViewController: FRSTableViewController, UIColorPickerViewControllerDelegate {

    let collectionData = ["Lime Green", "Red", "Purple", "Baby Blue", "Yellow", "White", "Orange"]
    let collectionDataColors = ["99CC00", "FF0000", "800080", "89CFF0", "FFFF00", "FFFFFF", "FFA500"]
    
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
    
    private func updateAppearance(with color: UIColor) {
        view.window?.tintColor = color
        // Store this color in UserDefaults or similar for persistence
        Preferences.customTintColor = color
    }
}

extension DisplayViewController {
    // ... other methods ...

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        var cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        cell.selectionStyle = .none

        if indexPath.section == 0 {
            cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
            cell.textLabel?.text = String.localized("APP_SIGNING_INPUT_VIEW_CONTROLLER_SECTION_TITLE_APPEARENCE")
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        
        // ... rest of your existing logic ...

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let colorPicker = UIColorPickerViewController()
            colorPicker.delegate = self
            if let customColor = Preferences.customTintColor {
                colorPicker.selectedColor = customColor
            }
            present(colorPicker, animated: true)
        } else if indexPath.section == 2 {
            // ... existing code for handling section 2 ...
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // UIColorPickerViewControllerDelegate methods
    func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
        updateAppearance(with: viewController.selectedColor)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // ... rest of your methods ...
}

// Assuming Preferences is a custom class or struct for managing user preferences
struct Preferences {
    static var customTintColor: UIColor? {
        get {
            if let colorData = UserDefaults.standard.data(forKey: "customTintColor"),
               let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: colorData) {
                return color
            }
            return nil
        }
        set {
            if let color = newValue {
                let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
                UserDefaults.standard.set(colorData, forKey: "customTintColor")
            } else {
                UserDefaults.standard.removeObject(forKey: "customTintColor")
            }
        }
    }
    // ... other preference properties ...
}