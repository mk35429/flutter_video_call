import Flutter
import UIKit

@available(iOS 10.0, *)
class CallStreamHandler: NSObject, FlutterStreamHandler {

    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("[CallStreamHandler][onListen]");
        SwiftFlutterVideoCallPlugin.callController.actionListener = { event, uuid, args in
            print("[CallStreamHandler][onListen] actionListener: \(event)")
            var data = ["event" : event.rawValue, "uuid": uuid.uuidString.lowercased()] as [String: Any]
            if args != nil{
                data["args"] = args!
            }
            events(data)
        }

        SwiftFlutterVideoCallPlugin.voipController.tokenListener = { token in
            print("[CallStreamHandler][onListen] tokenListener: \(token)")
            let data: [String: Any] = ["event" : "voipToken", "args": ["voipToken" : token]]

            events(data)
        }

        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("[CallStreamHandler][onCancel]")
        SwiftFlutterVideoCallPlugin.callController.actionListener = nil
        SwiftFlutterVideoCallPlugin.voipController.tokenListener = nil
        return nil
    }
}

@available(iOS 10.0, *)
public class SwiftFlutterVideoCallPlugin: NSObject, FlutterPlugin {
static let _methodChannelName = "flutter_video_call.methodChannel";
    static let _callEventChannelName = "flutter_video_call.callEventChannel"
    static let callController = CallKitController()
    static let voipController = VoIPController(withCallKitController: callController)

    public static func register(with registrar: FlutterPluginRegistrar) {
        print("[FlutterVideoCallPlugin][register]")
        //setup method channels
        let methodChannel = FlutterMethodChannel(name: _methodChannelName, binaryMessenger: registrar.messenger())

        //setup event channels
        let callEventChannel = FlutterEventChannel(name: _callEventChannelName, binaryMessenger: registrar.messenger())
        callEventChannel.setStreamHandler(CallStreamHandler())

        let instance = SwiftFlutterVideoCallPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    ///useful for integrating with VIOP notifications
    static public func reportIncomingCall(uuid: String,
                                          callType: Int,
                                          callInitiatorId: Int,
                                          callInitiatorName: String,
                                          opponents: [Int],
                                          userInfo: String?, result: FlutterResult?){
        SwiftFlutterVideoCallPlugin.callController.reportIncomingCall(uuid: uuid.lowercased(), callType: callType, callInitiatorId: callInitiatorId, callInitiatorName: callInitiatorName, opponents: opponents, userInfo: userInfo) { (error) in
            print("[FlutterVideoCallPlugin] reportIncomingCall ERROR: \(error?.localizedDescription ?? "none")")
            result?(error == nil)
        }
    }

    //TODO: remove these defaults and get as arguments
    @available(iOS 10.0, *)
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("[FlutterVideoCallPlugin][handle] method: \(call.method)");
        let arguments = call.arguments as! Dictionary<String, Any>
        if(call.method == "getVoipToken"){
            let voipToken = SwiftFlutterVideoCallPlugin.voipController.getVoIPToken()
            result(voipToken)
        }
        else if(call.method == "updateConfig"){
            let ringtone = arguments["ringtone"] as? String
            let icon = arguments["icon"] as? String
            CallKitController.updateConfig(ringtone: ringtone, icon: icon)

            result(true)
        }
        else if(call.method == "showCallNotification"){
            let callId = arguments["session_id"] as! String
            let callType = arguments["call_type"] as! Int
            let callInitiatorId = arguments["caller_id"] as! Int
            let callInitiatorName = arguments["caller_name"] as! String
            let callOpponentsString = arguments["call_opponents"] as! String
            let callOpponents = callOpponentsString.components(separatedBy: ",")
                .map { Int($0) ?? 0 }
            let userInfo = arguments["user_info"] as? String

            SwiftFlutterVideoCallPlugin.callController.reportIncomingCall(uuid: callId.lowercased(), callType: callType, callInitiatorId: callInitiatorId, callInitiatorName: callInitiatorName, opponents: callOpponents, userInfo: userInfo) { (error) in
                print("[FlutterVideoCallPlugin][handle] reportIncomingCall ERROR: \(error?.localizedDescription ?? "none")")
                result(error == nil)
            }
        }
        else if(call.method == "reportCallAccepted"){
            let callId = arguments["session_id"] as! String
            let callType = arguments["call_type"] as! Int
            let videoEnabled = callType == 1

            SwiftFlutterVideoCallPlugin.callController.startCall(handle: callId, videoEnabled: videoEnabled, uuid: callId)
            result(true)
        }
        else if (call.method == "reportCallFinished"){
            let callId = arguments["session_id"] as! String
            let reason = arguments["reason"] as! String


            SwiftFlutterVideoCallPlugin.callController.reportCallEnded(uuid: UUID(uuidString: callId)!, reason: CallEndedReason.init(rawValue: reason)!);
            result(true);
        }
        else if (call.method == "reportCallEnded"){
            let callId = arguments["session_id"] as! String
                SwiftFlutterVideoCallPlugin.callController.end(uuid: UUID(uuidString: callId)!)
    
            result(true)
        }
        else if (call.method == "muteCall"){
            let callId = arguments["session_id"] as! String
            let muted = arguments["muted"] as! Bool

            SwiftFlutterVideoCallPlugin.callController.setMute(uuid: UUID(uuidString: callId)!, muted: muted)
            result(true)
        }
        else if (call.method == "getCallState"){
            let callId = arguments["session_id"] as! String

            result(SwiftFlutterVideoCallPlugin.callController.getCallState(uuid: callId).rawValue)
        }
        else if (call.method == "setCallState"){
            let callId = arguments["session_id"] as! String
            let callState = arguments["call_state"] as! String

            SwiftFlutterVideoCallPlugin.callController.setCallState(uuid: callId, callState: callState)
            result(true)
        }

        else if (call.method == "getCallData"){
            let callId = arguments["session_id"] as! String

            result(SwiftFlutterVideoCallPlugin.callController.getCallData(uuid: callId))
        }
        else if (call.method == "clearCallData"){
            let callId = arguments["session_id"] as! String

            SwiftFlutterVideoCallPlugin.callController.clearCallData(uuid: callId)
            result(true)
        }
        else if (call.method == "getLastCallId"){
            result(SwiftFlutterVideoCallPlugin.callController.currentCallData["session_id"])
        }
    }
}
