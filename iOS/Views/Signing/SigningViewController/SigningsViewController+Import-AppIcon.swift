//
//  SigningsViewController+Import-AppIcon.swift
//  feather
//
//  Created by samara on 27.10.2024.
//

import UIKit
import SwiftUI
import UniformTypeIdentifiers

extension SigningsViewController: UIDocumentPickerDelegate, UIImagePickerControllerDelegate {
    func importAppIconFile() {
        let actionSheet = UIAlertController(title: "Select App Icon", message: nil, preferredStyle: .actionSheet)
        
        let altIconAction = UIAlertAction(title: "Select Alt Icon", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let settingsAltIconView = SettingsAltIconView(mainOptions: self.mainOptions, app: self.getFilesForDownloadedApps(app: self.application as! DownloadedApps, getuuidonly: false))
            let hostingController = UIHostingController(rootView: settingsAltIconView)
            
            if let sheet = hostingController.sheetPresentationController {
                sheet.detents = [.medium()]
            }
            
            self.present(hostingController, animated: true, completion: nil)
        }
        
        let documentPickerAction = UIAlertAction(title: "Choose from Files", style: .default) { [weak self] _ in
            self?.presentDocumentPicker(fileExtension: [UTType.image])
        }
        
        let photoLibraryAction = UIAlertAction(title: "Choose from Photos", style: .default) { [weak self] _ in
            self?.presentPhotoLibrary(mediaTypes: ["public.image"])
        }
        
        let cancelAction = UIAlertAction(title: String.localized("CANCEL"), style: .cancel, handler: nil)
        
        [altIconAction, documentPickerAction, photoLibraryAction, cancelAction].forEach { actionSheet.addAction($0) }
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(actionSheet, animated: true, completion: nil)
    }

    // MARK: - Documents
    
    func presentDocumentPicker(fileExtension: [UTType]) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: fileExtension, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedFileURL = urls.first else { return }
        
        if let image = CoreDataManager.shared.loadImage(from: selectedFileURL) {
            mainOptions.mainOptions.iconURL = image.resizeToSquare()
            Debug.shared.log(message: "Selected file URL: \(selectedFileURL)")
            self.tableView.reloadData()
        } else {
            Debug.shared.log(message: "Failed to load image from URL: \(selectedFileURL)", type: .error)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Library
    
    func presentPhotoLibrary(mediaTypes: [String]) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = mediaTypes
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let selectedImage = info[.originalImage] as? UIImage {
            mainOptions.mainOptions.iconURL = selectedImage.resizeToSquare()
            self.tableView.reloadData()
        } else {
            Debug.shared.log(message: "Failed to retrieve image from photo library", type: .error)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
