//
//  EntryViewController.swift
//  MyToDoList
//
//  Created by Afraz Siddiqui on 4/28/20.
//  Copyright © 2020 ASN GROUP LLC. All rights reserved.
//

import RealmSwift
import UIKit

class EntryViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var textField: UITextField!
    @IBOutlet var textFieldBudget: UITextField!
    @IBOutlet var datePicker: UIDatePicker!

    private let realm = try! Realm()
    public var completionHandler: (() -> Void)?
    
    var textFieldBatchNo = UITextField()
    var textFieldStep = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()

        textField.becomeFirstResponder()
        textField.delegate = self
        datePicker.setDate(Date(), animated: true)
        textFieldBudget.delegate = self
        
        textFieldBatchNo.delegate = self
        textFieldStep.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        
        let BatchBut = UIButton(type: .system)
        BatchBut.frame = CGRect(x: 110, y: 700, width: 150, height: 50)
        BatchBut.setTitle("Add Repeated Items", for: .normal)
        BatchBut.layer.borderWidth = 1.0
        BatchBut.layer.borderColor = UIColor.blue.cgColor
        BatchBut.addTarget(self, action: #selector(didBatch), for: .touchUpInside)
        self.view.addSubview(BatchBut)
        
        textFieldBatchNo.delegate = self
        textFieldBatchNo.frame = CGRect(x: 15, y: 600, width: 150, height: 50)
        textFieldBatchNo.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldBatchNo.text = "Repeat # times"
        self.view.addSubview(textFieldBatchNo)
        
        textFieldStep.delegate = self
        textFieldStep.frame = CGRect(x: 210, y: 600, width: 150, height: 50)
        textFieldStep.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldStep.text = "Every # days"
        self.view.addSubview(textFieldStep)
    }
    
    @objc func didBatch() {
        if let text = textField.text, !text.isEmpty {
            let date = datePicker.date
            let budget = Double(textFieldBudget.text!) ?? 0.0
            let batchNo = Int(textFieldBatchNo.text!) ?? 1
            let dayStep = (Int(textFieldStep.text!) ?? 1) * 86400 //3600 * 24 = 86400
            
            // write new item to realm
            realm.beginWrite()
            for aa in 0..<batchNo {
                let newItem = checkListItem()
                newItem.date = date.advanced(by: Double(dayStep * aa))
                newItem.item = text
                newItem.budget = budget
                realm.add(newItem)
            }
            try! realm.commitWrite()

            completionHandler?()
            navigationController?.popToRootViewController(animated: true)
        }
        else {
            //print("Add something")
        }
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //print("Begin!")
        textField.text = ""
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
            let newItem = checkListItem()
            newItem.date = date
            newItem.item = text
            newItem.budget = budget
            realm.add(newItem)
            try! realm.commitWrite()

            completionHandler?()
            navigationController?.popToRootViewController(animated: true)
        }
        else {
            //print("Add something")
        }
    }
    
}
