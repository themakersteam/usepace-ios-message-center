# Message Center for iOS

# 1. Setup
- Add the follwing in the Podfile:
`pod 'MessageCenter'`

- Install pods using `pod install`

# 2. Usage

`MessageCenter` Class provides access to main functions in the package to use.. by default, SendBird will be used as a client, but all clients conforms to `ClientProtocol` Protocol, which consists of the following functions and properties:

### 2.0 Start a new connection:
`func connect(with connectionRequest: ConnectionRequest, success:  @escaping ConnectionSucceeded, failure:  @escaping MessageCenterFailureCompletion)`

This function should be called at the startup of the app if the user exists, and has an `accessToken`.

A `ConnectionRequest` object must be passed to initialize the connection, the follwoing paramters are required:

- `appId: String` In case of the client needs an AppId (aka ClientId).
- `userId: String` App User Id.
- `accessToken: String` App User Access Token.
- `client: ClientType` Client type.

Along with the ConnectionRequest, you also need to pass a success and a failure completion handlers:

`public typealias MessageCenterFailureCompletion = (_ errorCode: Int, _ errorMessage: String) -> Void`

`public typealias ConnectionSucceeded = (_ userId: String) -> Void`


### 2.1 Check connectivity:
At any point of time, you can check the connectivity using the get-only var `isConnected: Bool`.

### 2.2 Get Un Read Messages Count:
To get the number of the missed messages -Un Read Messages-, call the function:
`func getUnReadMessagesCount(forChannel channel: String?, success: @escaping UnReadMessagesSuccessCompletion, failure: @escaping MessageCenterFailureCompletion)`

Provide `channel: String` to get the count for that channel, leave nil to get the total un read messages across all channels.

Along with that, you also need to pass a success and a failure completion handlers:

`public typealias UnReadMessagesSuccessCompletion = (_ unReadMessagesCount: Int) -> Void`

### 2.3 Start Chatting:
You can open the chatting view by calling the following function:
`func openChatView(forChannel channelId: String, withTheme theme: ChatViewTheme?, completion: @escaping (Any?) -> Void)` with the follwoing args:

- `channelId: String` to open chat view for specific channel.
- `theme: ChatViewTheme` to customize the theming of the chatting view.

`ChatViewTheme` consists of the following properties:

- `title: String`: Page Title.
- `primaryColor: UIColor` and `secondaryColor: UIColor`.

### 2.4 End Chatting:
After you started the chat by calling `openChatView()` you can close the view by calling: `closeChatView()` and pass an optional completion handler.


### 2.5 Notifications:
App should register app delegate and push device token by calling the following function:

`func application(application: application, didFinishLaunchingWithOptions: launchOptions)`

`func registerForRemoteNotificationsWithDeviceToken(deviceToken: Data)`

App should relay APNs notifications to the SDK to handle by calling the following function:

`func handleNotification(_ userInfo: Dictionary<String, String>, completion: @escaping HandleNotificationCompletion)`

The completion will be called once the SDK recognized a Chat-related notification:

`public typealias HandleNotificationCompletion = (_ didMatch: Bool, _ message: [AnyHashable : Any]) -> Void`

*A typed object for the message will be provided later instead of using a dictionary with keys!*

### 2.6 Disconnect:
The SDK provides the following function to use to disconnect the user:
`func disconnect(completion: @escaping () -> Void)`

**Note: This function should be called only upon a successful signout,**
**Connection will be managed by the SDK.**

