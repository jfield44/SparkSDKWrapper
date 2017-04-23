//
//  SparkMediaView.swift
//  SparkMediaView
//
//  The MIT License (MIT)
//
//  Created by Jonathan Field on 09/10/2016.
//  Copyright © 2016 Cisco. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import UIKit
import SparkSDK

/**
 Provides notifications when significant events take place during a video call
 - function callDidComplete: Triggered when the call ends regardless of the reason for call ending.
 - function callFailedWithError: Triggered when there was an error in setting up the call or there was an error with authentication
 */
public protocol SparkMediaViewDelegate: class {
    func callDidComplete()
    func callFailed(withError: String)
}

public class SparkMediaView: UIViewController, CallObserver {
    
    //Video Components
    @IBOutlet weak var remoteMediaView: MediaRenderView!
    @IBOutlet weak var localMediaView: MediaRenderView!
    
    //User Interface
    @IBOutlet weak var muteButton: UIButton!
    @IBOutlet weak var hangupButton: UIButton!
    @IBOutlet weak var rotateCameraButton: UIButton!
    @IBOutlet weak var callTimerLabel: UILabel!
    
    //Enums
    public enum AuthenticationStrategy {
        case sparkId, appId
    }
    
    //Call Variables
    var authenticationType: AuthenticationStrategy
    let apiKey: String!
    var currentCall: Call!
    var callTimer: Timer!
    var currentCallDuration: Int = 0
    
    //Delegate
    weak var delegate:SparkMediaViewDelegate?
    
    //Initalizers
    public init(authType: AuthenticationStrategy, apiKey: String, delegate: SparkMediaViewDelegate?) {
        self.authenticationType = authType
        self.apiKey = apiKey
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.apiKey = String()
        self.authenticationType = .appId
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecogniser = UITapGestureRecognizer.init(target: self, action: #selector(tap))
        self.remoteMediaView.addGestureRecognizer(tapGestureRecogniser)
        
        let panGestureRecogniser = UIPanGestureRecognizer.init(target: self, action: #selector(repositionSelfView))
        self.localMediaView.addGestureRecognizer(panGestureRecogniser)
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Convenience Functions
    public func voiceCall(recipient: String!) {
        self.startSparkCall(authType: self.authenticationType, recipient: recipient, mediaAccessType: .audio)
    }
    
    public func videoCall(recipient: String!) {
        self.startSparkCall(authType: self.authenticationType ,recipient: recipient, mediaAccessType: .audioVideo)
    }
    
    /**
     Start a Call using the Spark Media SDK
     - parameter recipient: The Spark URI or SIP URI of the remote particpiant to be dialled
     - parameter mediaAccessType: The type of Media that will be sent to the remote party (Audio or Audio Video)
     */
    func startSparkCall(authType: AuthenticationStrategy, recipient: String, mediaAccessType: Phone.MediaAccessType) {
        
        self.authenticateWithSpark(apiKey: self.apiKey, authType: authType) { (attempted) in
            if attempted {
                self.registerDeviceWithSpark(mediaAccessType: mediaAccessType, successfulRegistration: { (success) in
                    self.registerForSparkCallStateNotifications()
                    self.startSparkCallTo(recipient: recipient, mediaAccessType: mediaAccessType)
                }) { (error) in
                    self.delegate?.callFailed(withError: "Unable to register with Spark, check your access token.")
                }
            }
        }
    }
    
    /**
     Initial Authentication to Spark
     - parameter apiKey: Spark Access Token from www.developer.ciscospark.com
     */
    func authenticateWithSpark(apiKey: String, authType: AuthenticationStrategy, authenticationAttempted: @escaping (_ attempted: Bool ) -> Void){
        if authType == .sparkId {
            Spark.initWith(accessToken: apiKey)
            authenticationAttempted(true)
        }
        else if authType == .appId {
            // TODO
            // let jwtAuthStrategy = JWTAuthStrategy()
            // let spark = Spark(authenticationStrategy: jwtAuthStrategy)
            // if !jwtAuthStrategy.authorized {
            //    jwtAuthStrategy.authorizedWith(jwt: apiKey)
            // if spark.authenticationStrategy.authorized {
            //    print("Not auth")
            //    }
            //}
            authenticationAttempted(true)
        }
        Spark.phone.disableVideoCodecActivation()
    }
    
    /**
     Register this instance of the Media SDK with the Spark Cloud for Outgoing Calls
     - parameter mediaAccessType: The type of Media that will be sent to the remote party (Audio or Audio Video)
     - parameter successfulRegistration: Triggered if the instance of the Media SDK was registered with the Spark Cloud successfully
     - parameter unSuccessfulRegistration: Triggered if the instance of the Media SDK was unable to register with the Spark Cloud
     */
    func registerDeviceWithSpark(mediaAccessType: Phone.MediaAccessType, successfulRegistration: @escaping (_ successfulRegistration: String ) -> Void, unSuccessfulRegistration: @escaping (_ error: String) -> Void){
        Spark.phone.requestMediaAccess(Phone.MediaAccessType.audioVideo) { granted in
            if !granted {
                print("not granted")
            }
        }
        Spark.phone.register() { success in
            if success {
                print("success")
                successfulRegistration("success")
            } else {
                print("failure")
                unSuccessfulRegistration("failed")
            }
        }
    }
    
    func registerForSparkCallStateNotifications() {
        CallNotificationCenter.sharedInstance.add(observer: self)
    }
    
    /**
     Trigger the Spark call to start
     - parameter recipient: The Spark URI or SIP URI of the remote particpiant to be dialled
     - parameter mediaAccessType: The type of Media that will be sent to the remote party (Audio or Audio Video)
     */
    func startSparkCallTo(recipient: String, mediaAccessType: Phone.MediaAccessType){
        self.startCallTimer()
        Spark.phone.defaultFacingMode = Call.FacingMode.User
        let call = Spark.phone.dial(recipient, option: mediaAccessType == .audio ? MediaOption.audioOnly : MediaOption.audioVideo(local: self.localMediaView, remote: self.remoteMediaView)) { success in
            if success {
                if mediaAccessType == .audio {
                    self.callTimerLabel.isHidden = false
                    self.rotateCameraButton.isEnabled = false
                    self.toggleButtonVisibilityState()
                }
            }
            else {
                print("Failed to dial call.")
                self.delegate?.callFailed(withError: "Failed to Dial, check your recipient has a valid address and that you have internet connectivity.")
            }
        }
        self.currentCall = call
    }
    
    // Call Notifications
    public func callDidBeginRinging(_ call: Call) {
        // Your custom logic
    }
    
    public func callDidDisconnect(_ call: Call, disconnectionType: DisconnectionType) {
        self.dismiss(animated: true, completion: {
            self.delegate?.callDidComplete()
        })
    }
    
    // Button Actions
    @IBAction func rotateCameraPressed(_ sender: UIButton) {
        self.currentCall.toggleFacingMode()
        if self.currentCall.facingMode.hashValue == 0 {
            self.rotateCameraButton.setImage(UIImage(named: "rotate"), for: UIControlState())
        }
        else if self.currentCall.facingMode.hashValue == 1{
            self.rotateCameraButton.setImage(UIImage(named: "rotateActive"), for: UIControlState())
        }
    }
    
    @IBAction func hangupPressed(_ sender: UIButton) {
        self.view.backgroundColor = UIColor.black
        self.callTimerLabel.isHidden = true
        self.currentCall.hangup() { success in
            if !success {
                print("Failed to hangup call.")
            } else {
                self.currentCall = nil
                self.dismiss(animated: true, completion: {
                    
                })
            }
        }
    }
    
    @IBAction func mutePressed(_ sender: UIButton) {
        self.currentCall.toggleSendingAudio()
        if self.currentCall.sendingAudio {
            self.muteButton.setImage(UIImage(named: "mute"), for: UIControlState())
        }
        else{
            self.muteButton.setImage(UIImage(named: "muteActive"), for: UIControlState())
        }
    }
    
    // Gesture Recognisers
    func tap(_ gestureRecognizer: UITapGestureRecognizer) {
        self.toggleButtonVisibilityState()
    }
    
    func repositionSelfView(_ gestureRecognizer: UIPanGestureRecognizer){
        self.updateLocalMediaView(sender: gestureRecognizer)
    }
    
    // UI Helpers
    func toggleButtonVisibilityState() {
        if self.muteButton.isHidden || self.hangupButton.isHidden || self.rotateCameraButton.isHidden {
            self.muteButton.isHidden = false
            self.hangupButton.isHidden = false
            self.rotateCameraButton.isHidden = false
            self.callTimerLabel.isHidden = false
        }
        else {
            self.muteButton.isHidden = true
            self.hangupButton.isHidden = true
            self.rotateCameraButton.isHidden = true
            self.callTimerLabel.isHidden = true
        }
    }
    
    func updateLocalMediaView(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        sender.view!.center = CGPoint(x: sender.view!.center.x + translation.x, y: sender.view!.center.y + translation.y)
        sender.setTranslation(CGPoint.init(x: 0, y: 0), in: self.view)
        
    }
    
    func startCallTimer() {
        self.callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.currentCallDuration += 1
            self.callTimerLabel.text = SparkMediaHelper.timeStringFromSeconds(currrentCallDuration: self.currentCallDuration)
        })
    }
    
    fileprivate func showPhoneRegisterFailAlert() {
        let alert = UIAlertController(title: "Alert", message: "Phone register fail", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
