/*
See the License.txt file for this sample’s licensing information.
*/

import Foundation

class DataModel: ObservableObject {
    
    @Published var items: [Item] = []
    
    init() {
//        if let documentDirectory = FileManager.default.documentDirectory {
//                let urls = FileManager.default.getContentsOfDirectory(documentDirectory).filter { $0.hasDirectoryPath}
//                for url in urls {
//                    let sub = FileManager.default.getContentsOfDirectory(url).filter{$0.hasDirectoryPath}
//                    let subDirectory = FileManager.default.getContentsOfDirectory(sub[0]).filter{$0.isImage}
//                    for image in subDirectory{
//                        if image.absoluteString.contains("depth") == false {
//                            let item = Item(url: image)
//                            items.append(item)
//                        }
//                    }
//                }
//            }
            
//            if let urls = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: nil) {
//                for url in urls {
//                    let item = Item(url: url)
//                    items.append(item)
//                }
//            }
        }
    func initializeGallery() {
        if let documentDirectory = FileManager.default.documentDirectory {
                let urls = FileManager.default.getContentsOfDirectory(documentDirectory).filter { $0.hasDirectoryPath}
                for url in urls {
                    let sub = FileManager.default.getContentsOfDirectory(url).filter{$0.hasDirectoryPath}
                    let subDirectory = FileManager.default.getContentsOfDirectory(sub[0]).filter{$0.isImage}
                    for image in subDirectory{
                        if image.absoluteString.contains("depth") == false {
                            let item = Item(url: image)
                            items.append(item)
                        }
                    }
                }
            }
    }
    /// Adds an item to the data collection.
    func addItem(_ item: Item) {
        items.insert(item, at: 0)
    }
    
    /// Removes an item from the data collection.
    func removeItem(_ item: Item) {
        if let index = items.firstIndex(of: item) {
            items.remove(at: index)
            FileManager.default.removeItemFromDocumentDirectory(url: item.url)
        }
    }
}

extension URL {
    /// Indicates whether the URL has a file extension corresponding to a common image format.
    var isImage: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "heic"]
        return imageExtensions.contains(self.pathExtension)
    }
}

