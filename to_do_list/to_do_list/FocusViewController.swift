//
//  FocusViewController.swift
//  to_do_list
//
//  Created by Jiawei Chen on 2/5/22.
//


import UIKit
import SwiftUI
import EventKit
import EventKitUI
import SpriteKit

class FocusViewController: UIViewController, EKEventEditViewDelegate, UIScrollViewDelegate, UNUserNotificationCenterDelegate {
    
    //public var item: checkListItem?
    
    public var completionHandler: (() -> Void)?
    
    public var startFocus: Date?
    
    public var checkInTime: Date?
    
    private let store =  EKEventStore()
    
    private let center = UNUserNotificationCenter.current()
    
    let emitterNode = SKEmitterNode(fileNamed: "snow1.sks")!
    
    private var canNotify = true;
    
    public var addedTime = 1800.0 // in seconds
    
    private var animationPlayed = false
    
    var timer: Timer!
    
    let formatter = DateComponentsFormatter()
    
    
    @IBOutlet var label: UILabel!
    @IBOutlet var label2: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let time_elapsed = -(self.startFocus?.timeIntervalSinceNow ?? 0)
        let time_elapsed2 = -(self.checkInTime?.timeIntervalSinceNow ?? 0)
        
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [ .pad ]
        
        let formattedString = formatter.string(from: TimeInterval(time_elapsed))!
        let formattedString2 = formatter.string(from: TimeInterval(time_elapsed2))!
        
        label.text = formattedString
        label2.text = formattedString2
        
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(back))
        self.navigationItem.leftBarButtonItem = newBackButton
        
        if self.canNotify {
            DispatchQueue.main.async { [self] in
                let content = UNMutableNotificationContent()
                content.body = "Get up and take a rest!"
                content.sound = UNNotificationSound.default
                
                //let addedTime = 3000.0 // in seconds
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: self.addedTime, repeats: false)
                
                let request = UNNotificationRequest(identifier: "Get up and take a rest!",
                            content: content, trigger: trigger)

                // Schedule the request with the system.
                self.center.add(request) { (error) in
                    if let error = error {
                       
                        // Handle any errors.
                        print("Error: ", error)
                    }
                    
                }
                
            }
            
        }
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(step), userInfo: nil, repeats: true)
        
        
    }
    
    private func addSnow() {
        let skView = SKView(frame: view.frame)
        skView.backgroundColor = .clear
        let scene = SKScene(size: view.frame.size)
        scene.backgroundColor = .clear
        skView.presentScene(scene)
        skView.isUserInteractionEnabled = false
        scene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scene.addChild(emitterNode)
        emitterNode.position.y = scene.frame.maxY
        emitterNode.particlePositionRange.dx = scene.frame.width
        view.addSubview(skView)
    }
    
    @objc func back() {
        // Perform your custom actions
        if self.canNotify {
            DispatchQueue.main.async {
                
                self.center.removePendingNotificationRequests(withIdentifiers: ["Get up and take a rest!"])
                
            }
        }
        // Go back to the previous ViewController
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func step() {
        let time_elapsed = -(self.startFocus?.timeIntervalSinceNow ?? 0)
        let time_elapsed2 = -(self.checkInTime?.timeIntervalSinceNow ?? 0)
        
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [ .pad ]
        
        let formattedString = formatter.string(from: TimeInterval(time_elapsed))!
        let formattedString2 = formatter.string(from: TimeInterval(time_elapsed2))!
        
        label.text = formattedString
        label2.text = formattedString2
        
        if (!animationPlayed && time_elapsed >= addedTime) {
            addSnow()
            animationPlayed = true
        }
    }
    
    
    func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func center(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    func center(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .badge])
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
