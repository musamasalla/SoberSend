import ActivityKit
import WidgetKit
import SwiftUI

@main
struct SoberSendWidgetBundle: WidgetBundle {
    var body: some Widget {
        SoberSendWidget()
        if #available(iOS 16.1, *) {
            LockdownLiveActivity()
        }
    }
}