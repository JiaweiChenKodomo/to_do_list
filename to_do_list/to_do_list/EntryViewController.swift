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

    var textField = UITextField()
    var textFieldKR = UITextField()
    var textFieldBudget = UITextField()
    var datePicker = UIDatePicker()

    private let realm = try! Realm()
    public var completionHandler: (() -> Void)?
    
    var textFieldItem = UITextField()
    var textFieldKRTitle = UITextField()
    var textFieldBGTTitle = UITextField()
    var textFieldDLTitle = UITextField()
    
    var textFieldBatchNo = UITextField()
    var textFieldStep = UITextField()
    
    var yOffset = 160
    var textHeight = 21
    var fieldHeight = 52
    var sSpacing = 5
    var bSpacing = 15
    var startY = 0
    var xOffset = 50
    //var firstEdit = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        startY += yOffset
        
        textFieldItem.frame = CGRect(x: xOffset, y: startY, width: 110, height: textHeight)
        textFieldItem.text = "Objective"
        self.view.addSubview(textFieldItem)
        
        startY += textHeight+sSpacing
        textField.becomeFirstResponder()
        textField.delegate = self
        textField.frame = CGRect(x: xOffset, y: startY, width: 274, height: fieldHeight)
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        self.view.addSubview(textField)
        
        startY += fieldHeight+bSpacing
        textFieldKRTitle.frame = CGRect(x: xOffset, y: startY, width: 274, height: textHeight)
        textFieldKRTitle.text = "Key Results"
        self.view.addSubview(textFieldKRTitle)
        
        startY += textHeight+sSpacing
        textFieldKR.delegate = self
        textFieldKR.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldKR.frame = CGRect(x: xOffset, y: startY, width: 274, height: fieldHeight)
        self.view.addSubview(textFieldKR)
        
        startY += fieldHeight+bSpacing
        textFieldBGTTitle.frame = CGRect(x: xOffset, y: startY, width: 56, height: textHeight)
        textFieldBGTTitle.text = "Budget"
        self.view.addSubview(textFieldBGTTitle)
        
        startY += textHeight+sSpacing
        textFieldBudget.delegate = self
        textFieldBudget.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldBudget.frame = CGRect(x: xOffset, y: startY, width: 274, height: fieldHeight)
        self.view.addSubview(textFieldBudget)
        
        startY += fieldHeight+bSpacing
        textFieldDLTitle.frame = CGRect(x: xOffset, y: startY, width: 67, height: textHeight)
        textFieldDLTitle.text = "Deadline"
        self.view.addSubview(textFieldDLTitle)
        
        startY += textHeight+sSpacing
        datePicker.setDate(Date(), animated: true)
        datePicker.frame = CGRect(x: 30, y: startY, width: 320, height: fieldHeight)
        datePicker.contentHorizontalAlignment = .center
        self.view.addSubview(datePicker)
        
        textFieldBatchNo.delegate = self
        textFieldStep.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(didTapSaveButton))
        
        startY += fieldHeight+bSpacing+100
        textFieldBatchNo.delegate = self
        textFieldBatchNo.frame = CGRect(x: 15, y: startY, width: 150, height: 50)
        textFieldBatchNo.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldBatchNo.text = "Repeat # times"
        textFieldBatchNo.clearsOnBeginEditing = true
        self.view.addSubview(textFieldBatchNo)
        
        textFieldStep.delegate = self
        textFieldStep.frame = CGRect(x: 210, y: startY, width: 150, height: 50)
        textFieldStep.borderStyle = UITextField.BorderStyle.roundedRect
        textFieldStep.text = "Every # days"
        textFieldStep.clearsOnBeginEditing = true
        self.view.addSubview(textFieldStep)
        
        startY += fieldHeight+bSpacing
        
        let BatchBut = UIButton(type: .system)
        BatchBut.frame = CGRect(x: 110, y: startY, width: 150, height: 50)
        BatchBut.setTitle("Add Repeated Items", for: .normal)
        BatchBut.layer.borderWidth = 1.0
        BatchBut.layer.borderColor = UIColor.blue.cgColor
        BatchBut.addTarget(self, action: #selector(didBatch), for: .touchUpInside)
        self.view.addSubview(BatchBut)
        
        
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
        //print(textField.clearsOnBeginEditing)
        if (textField.clearsOnBeginEditing) {
            textField.text = ""
            textField.clearsOnBeginEditing = false
        }
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
            let KR = textFieldKR.text ?? "(No KR)"
            let date = datePicker.date
            let budget = Double(textFieldBudget.text!) ?? 0.0
            
            // write new item to realm 
            realm.beginWrite()
            let newItem = checkListItem()
            newItem.date = date
            newItem.item = text + " \u{21e8} " + KR
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
