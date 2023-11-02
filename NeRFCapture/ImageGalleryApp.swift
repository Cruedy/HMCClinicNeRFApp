/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI

@available(iOS 16.0, *)

struct ImageGalleryApp: App {
    @StateObject var dataModel = DataModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView2()
            }
            .environmentObject(dataModel)
            .navigationViewStyle(.stack)
        }
    }
}
