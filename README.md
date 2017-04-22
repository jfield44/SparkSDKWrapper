# Spark SDK Wrapper

## Embed Voice and Video calling capabilities into your iOS App in 3 lines of code using the Cisco Spark SDK with this wrapper.

The Spark SDK Wrapper is an unofficial convenience library written on top of the Cisco Spark iOS SDK. The purpose of this project is provide a super simple way to add voice and video calling into your app. This wrapper library provides a reference implementation of the SparkSDK as a drop in component that you can add into your existing app to add voice and video capabilities without needing to know how to use the SparkSDK.

This wrapper handles layout of the video streams for local and remote participants, the call setup process, in call functionality such as muting, and switching the camera as well as hanging up the call.
What that means is that you just need to pass the SparkSDKWrapper your Cisco Spark authentication credentials and the address of the recipient and you will be all set.


## Requirements
In order to use the Spark SDK Wrapper you need to have an existing iOS project configured to use the Cisco Spark iOS SDK, you can find instructions on how to do that [here](https://github.com/ciscospark/spark-ios-sdk) .

Download or clone this repository and drag the following files into your Xcode Project:
 * SparkMediaView.swift
 * SparkMediaHelper.swift
 * SparkMediaView.xib
 * SparkMediaSDKAssets.xcassets

*Important:* Apple now require that you provide a justification text to the end user when you request to use the Camera and Microphone on their device. In order to satisfy this requirement you need to provide the justification text. 

To do this, open the info.plist file that resides inside of your Xcode project. Add two new rows, replacing the value with whatever the message is that you wish to display to the end user when they start a call for the first time.

1. Key: `Privacy - Camera Usage Description` Type: `String` Value: `CAMERA_JUSTIFICATION_CHANGE_ME`
2. Key: `Privacy - Microphone Usage Description` Type: `String` Value: `MICROPHONE_JUSTIFICATION_CHANGE_ME`

*If you fail to do the above step, the app will crash* 


## Implementation
The SparkSDKWrapper uses a UIViewController as a drop in component to display the Video/Voice call.  As a result of this, to use this library you need to ensure that the view from which you will start the call is part of a *UINavigationController*.

Place the following code wherever at the appropriate point in your project to begin the call. For a better user experience you should consider showing a popup informing the user that they are about to begin a call with an option to cancel.


#### Implement the `SparkMediaViewDelegate` Protocol in your ViewController, this is how you will be notified when a call has completed or an error occurred.

```swift
import UIKit

class ViewController: UIViewController, SparkMediaViewDelegate {
 // YOUR IMPLEMENTATION
}
```


#### Implement the two mandatory delegate functions `callDidComplete()` and `callFailed(withError: String)`

```swift
import UIKit

class ViewController: UIViewController, SparkMediaViewDelegate {

    // YOUR IMPLEMENTATION

    func callDidComplete() {
        // Add your handling logic here
    }
    
    func callFailed(withError: String) {
        // Add your handling logic here
    }

}
```


#### To start a Video Call:
```swift
import UIKit

class ViewController: UIViewController, SparkMediaViewDelegate {

  // YOUR IMPLEMENTATION

  func startCall() {
  	// Who are you?
  	let sparkMedia = SparkMediaView(authType: .sparkId ,apiKey: "API_KEY", delegate: self) 
	// Who do you want to call? Is it Voice or Video?
	sparkMedia.videoCall(recipient: "RECIPIENT_ADDRESS")     
	// Where should I display the call view?
	self.present(sparkMedia, animated: true, completion: nil) 
    }

  func callDidComplete() {
        // Add your handling logic here
    }
    
  func callFailed(withError: String) {
        // Add your handling logic here
    }
}
```


#### To start a Voice Call:
```swift
import UIKit

class ViewController: UIViewController, SparkMediaViewDelegate {
 
  // YOUR IMPLEMENTATION

  func startCall() {
  	// Who are you?
  	let sparkMedia = SparkMediaView(authType: .sparkId ,apiKey: "API_KEY", delegate: self) 
	// Who do you want to call? Is it Voice or Video?
	sparkMedia.voiceCall(recipient: "RECIPIENT_ADDRESS")     
	// Where should I display the call view?
	self.present(sparkMedia, animated: true, completion: nil) 
    }

  func callDidComplete() {
        // Add your handling logic here
    }
    
  func callFailed(withError: String) {
        // Add your handling logic here
    }
}
```


Thats it… you are all set to start making awesome video and voice calls using the Cisco Spark SDK.


Its likely that you will want to customise the way that the calling experience looks to suit your app or business. You can do this using the SparkMediaView.swift file for the implementation and the SparkMediaView.xib for the GUI.



## License
SparkSDKWrapper is available under the MIT license. See the LICENSE file for more info.
