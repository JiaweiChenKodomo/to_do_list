//
//  ModViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 11/25/21.
//

import RealmSwift
import UIKit

class ModViewController: UIViewController, UITextFieldDelegate {
    
    public var item: checkListItem?

    @IBOutlet var textField: UITextField!
    @IBOutlet var textFieldBudget: UITextField!
    @IBOutlet var datePicker: UIDatePicker!

    private let realm = try! Realm()
    public var completionHandler: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        textField.becomeFirstResponder()
        textField.delegate = self
        textField.text = item?.item
        datePicker.setDate(item!.date, animated: true)
        textFieldBudget.delegate = self
        textFieldBudget.text = String(format: "%.1f", item!.budget)
        

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    }
    
    @objc func didTapSaveButton() {
        if let text = textField.text, !text.isEmpty {
            let date = datePicker.date
            let budget = Double(textFieldBudget.text!) ?? 0.0
            
            // write new item to realm
            realm.beginWrite()
            
            item!.date = date
            item!.item = text
            item!.budget = budget
            
            try! realm.commitWrite()

            completionHandler?()
            navigationController?.popToRootViewController(animated: true)
        }
        else {
            //print("Add something")
        }
    }
    
}
