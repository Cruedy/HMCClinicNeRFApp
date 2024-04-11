//
//  SendImagesToServerView.swift
//  NeRFCapture
//
//  Created by Rin Ha on 11/8/23.
//

import SwiftUI
import Zip
import Foundation

@available(iOS 17.0, *)
struct SendImagesToServerView: View {
    @State private var showingInstructions = false
    @State private var serverResponse: String = "Awaiting response..."
    @State private var serverStatus: ServerStatus?
    @State private var serverError: String = ""
    @StateObject var viewModel: ARViewModel
    @EnvironmentObject var dataModel: DataModel
    @Binding var path: NavigationPath // Add this line

    init(viewModel vm: ARViewModel, path: Binding<NavigationPath>) {
        _viewModel = StateObject(wrappedValue: vm)
        _path = path
    }
    
    @State private var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
//    @State private var splatName: String = "iPad5"

    var body: some View {
        VStack {  // Main UI portion
            Text(testForStatus(status: serverStatus))
            .padding()
            Spacer()
//            TextField("Enter splat name", text: $splatName)
//                            .padding()
//                            .textFieldStyle(RoundedBorderTextFieldStyle())
//                            .padding()
//            Spacer()
//            Text(serverResponse) // Display server response
//                .padding()
//            Button(action: {
//                print("send")
//                let urlString = "http://osiris.cs.hmc.edu:15002/heartbeat"
//                makeGetRequest(urlString: urlString) { data, response, error in
//                    processData(data: data, response: response, error: error)
//                }
//            }) {
//                Text("Send Data to Server")
//                    .padding(.horizontal, 20)
//                    .padding(.vertical, 5)
//            }
//            .buttonStyle(.bordered)
//            .buttonBorderShape(.capsule)
            Button(action: {
                print("send zip to server")
                let urlString = "http://osiris.cs.hmc.edu:15002/upload_device_data"
                let directoryPath = viewModel.datasetWriter.projectDir
                let zipPath = convertDirectoryPathToZipPath(directoryPath: directoryPath.absoluteString)
                print(zipPath)
                uploadZipFile(urlString: urlString, zipFilePath: URL(string: zipPath)!, splatName: viewModel.datasetWriter.projectName)
            }) {
                Text("Send zip to Server")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            Spacer()
            Button(action: {
                print("trigger full pipeline")
                let urlString = "http://osiris.cs.hmc.edu:15002/full_pipeline"
                startFullPipeline(urlString: urlString)
            }) {
                Text("Generate Splatt")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            
            Spacer()

            Button(action: {
                print("get video")
                let urlString = "http://osiris.cs.hmc.edu:15002/download_video/\(viewModel.datasetWriter.projName)"
                downloadVideo(urlString: urlString, splatName: viewModel.datasetWriter.projName)
//                let urlString = "http://osiris.cs.hmc.edu:15002/download_video/\(viewModel.datasetWriter.projectName)"
//                downloadVideo(urlString: urlString, splatName: viewModel.datasetWriter.projectName)

            }) {
                Text("get video")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)

            
            HelpButton {
                showingInstructions = true
            }
            .sheet(isPresented: $showingInstructions) {
                VStack {
                    InstructionsView()
                }
            }
        }
        .onAppear {
                    // Reconnect the timer if needed when the view appears or reappears
                    self.timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
        }
        .onReceive(timer) { _ in
            let urlString = "http://osiris.cs.hmc.edu:15002/status"
            makeGetRequest(urlString: urlString) { data, response, error in
                pollServerStatus(data: data, response: response, error: error)
            }
        }
        .onDisappear {
            // Invalidate the timer when the view disappears to stop the polling
            self.timer.upstream.connect().cancel()
        }
        .preferredColorScheme(.dark)
        // --- Navigation Bar ---
        .navigationBarTitle("Send to Server")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)  // Prevents navigation back button from being shown
        
        NavigationLink("Next", destination: VideoView(viewModel: viewModel, path: $path).environmentObject(dataModel)).navigationViewStyle(.stack)
            .padding(.horizontal, 20)
            .padding(.vertical, 5)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
    }
    
    func convertDirectoryPathToZipPath(directoryPath: String) -> String {
        // Check if the directory path ends with a slash and remove it if present
        var adjustedPath = directoryPath
        if adjustedPath.hasSuffix("/") {
            adjustedPath.removeLast()
        }
        
        // Append '.zip' to the adjusted path
        let zipPath = "\(adjustedPath).zip"
        
        return zipPath
    }
    
    func testForStatus(status: ServerStatus?) -> String {
        if let status = status {
            switch status {
            case .waiting_for_data:
                return "Server is ready for upload"
            case .data_upload_started:
                return "Server is extracting uploaded data"
            case .data_upload_ended:
                return "Server finished extracting uploaded data"
            case .preprocessing_started:
                return "Server is preprocessing data"
            case .preprocessing_ended:
                return "Server is done preprocessing data"
            case .training_started:
                return "Server started training"
            case .training_ended:
                return "Server finished training"
            case .rendering_started:
                return "Server is rendering video"
            case .rendering_ended:
                return "Server finished rendering video"
            }
        }
        return serverError
    }
    // Function to make a GET request
    func makeGetRequest(urlString: String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            DispatchQueue.main.async {
                self.serverResponse = "Invalid URL"
            }
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            completion(data, response, error)
        }

        task.resume()
    }
    

    // Function to process the received data
    func processData(data: Data?, response: URLResponse?, error: Error?) {
        // Check for errors
        if let error = error {
            print("Error: \(error)")
            DispatchQueue.main.async {
                self.serverResponse = "Error: \(error.localizedDescription)"
            }
            return
        }

        // Check for valid data
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let data = data else {
            DispatchQueue.main.async {
                self.serverResponse = "No data or invalid response"
            }
            return
        }

        // Process the data
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let message = json["message"] as? String {
                DispatchQueue.main.async {
                    self.serverResponse = message
                }
            } else {
                DispatchQueue.main.async {
                    self.serverResponse = "Received unknown response"
                }
            }
        } catch let error {
            print("JSON error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.serverResponse = "JSON error: \(error.localizedDescription)"
            }
        }
    }
    
    // Function to process the received data
    func pollServerStatus(data: Data?, response: URLResponse?, error: Error?) {
        // Check for errors
        if let error = error {
            print("Error: \(error)")
            DispatchQueue.main.async {
                self.serverStatus = nil
                self.serverError = "Error: \(error.localizedDescription)"
            }
            return
        }

        // Check for valid data
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
              let data = data else {
            DispatchQueue.main.async {
                self.serverStatus = nil
                self.serverError = "No data or invalid response"
            }
            return
        }

        // Process the data
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let status = json["status"] as? String {
                print(status)
                DispatchQueue.main.async {
                    if status == "waiting_for_data"{
                        self.serverStatus = ServerStatus.waiting_for_data
                    } else if status == "data_upload_started" {
                        self.serverStatus = ServerStatus.data_upload_started
                    } else if status == "data_upload_ended" {
                        self.serverStatus = ServerStatus.data_upload_ended
                    } else if status == "preprocessing_started" {
                        self.serverStatus = ServerStatus.preprocessing_started
                    } else if status == "preprocessing_ended" {
                        self.serverStatus = ServerStatus.preprocessing_ended
                    } else if status == "training_started" {
                        self.serverStatus = ServerStatus.training_started
                    } else if status == "training_ended" {
                        self.serverStatus = ServerStatus.training_ended
                    } else if status == "rendering_started" {
                        self.serverStatus = ServerStatus.rendering_started
                    } else if status == "rendering_ended" {
                        self.serverStatus = ServerStatus.rendering_ended
                    } else{
                        self.serverStatus = nil
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.serverStatus = nil
                    self.serverError = "Received unknown response"
                }
            }
        } catch let error {
            print("JSON error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.serverStatus = nil
                self.serverError = "JSON error: \(error.localizedDescription)"
            }
        }
    }
    
    func uploadZipFile(urlString: String, zipFilePath: URL, splatName: String) {
        let fileManager = FileManager.default
        do {
            guard fileManager.fileExists(atPath: zipFilePath.path) else {
                print("ZIP file does not exist at specified path.")
                return
            }
            
            let filename = zipFilePath.lastPathComponent
            let mimeType = "application/zip"
            let fileData = try Data(contentsOf: zipFilePath)
            
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            // Add the ZIP file data
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            
            // If you need to send additional data, like the 'splatName'
            // Adjust the 'name' accordingly to what your server expects
            data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"splatName\"\r\n\r\n".data(using: .utf8)!)
            data.append(splatName.data(using: .utf8)!)
            
            // End of the multipart/form-data
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("ZIP file uploaded successfully.")
                } else {
                    print("Upload failed.")
                }
            }
            
            task.resume()
            
        } catch {
            print("Error preparing ZIP file for upload: \(error)")
        }
    }

    
    func uploadPhotos(urlString: String, directoryPath: URL) {
        // Assuming `directoryPath` is the path to the directory containing photos
        let fileManager = FileManager.default
        do {
            // URL(fileURLWithPath: directoryPath)
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryPath,
                                                               includingPropertiesForKeys: nil,
                                                               options: .skipsHiddenFiles)
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            for fileURL in fileURLs {
                print("fileURL")
                print(fileURL)
                let filename = fileURL.lastPathComponent
                let mimeType = "image/png" // Adjust based on your actual file type
                let fileData = try Data(contentsOf: fileURL)
                
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"photos\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                data.append(fileData)
            }
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Files uploaded successfully.")
                } else {
                    print("Upload failed.")
                }
            }
            
            task.resume()
            
        } catch {
            print("Error reading directory: \(error)")
        }
    }
    
    func uploadSplatName(urlString: String, splatName: String) {
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["splatName": splatName]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    // Update your UI here if necessary
                    print("Splat name uploaded successfully.")
                }
            } else {
                print("Upload failed with response: \(String(describing: response))")
            }
        }
        
        task.resume()
    }
    
    func uploadBoundingBox(urlString: String, directoryPath: URL) {
        // Assuming `directoryPath` is the path to the directory containing photos
        let fileManager = FileManager.default
        do {
            // URL(fileURLWithPath: directoryPath)
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryPath,
                                                               includingPropertiesForKeys: nil,
                                                               options: .skipsHiddenFiles)
            var request = URLRequest(url: URL(string: urlString)!)
            request.httpMethod = "POST"
            
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            var data = Data()
            
            for fileURL in fileURLs {
                print("fileURL")
                print(fileURL)
                let filename = fileURL.lastPathComponent
                let mimeType = "image/png" // Adjust based on your actual file type
                let fileData = try Data(contentsOf: fileURL)
                
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"photos\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                data.append(fileData)
            }
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
            
            request.httpBody = data
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Files uploaded successfully.")
                } else {
                    print("Upload failed.")
                }
            }
            
            task.resume()
            
        } catch {
            print("Error reading directory: \(error)")
        }
    }
    
    func uploadJSONFile(urlString: String, fileURL: URL) {
        // Ensure the URL is valid
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // Append the file data to the request body
        let filename = fileURL.lastPathComponent
        let mimeType = "application/json" // MIME type for JSON files
        do {
            let fileData = try Data(contentsOf: fileURL)
            
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            data.append(fileData)
            data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        } catch {
            print("Error reading file: \(error)")
            return
        }
        
        request.httpBody = data
        
        // Perform the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("File uploaded successfully.")
            } else {
                print("Upload failed with response: \(String(describing: response))")
            }
        }
        task.resume()
    }
    
    func startFullPipeline(urlString: String) {
        
        let statusUrlString = "http://osiris.cs.hmc.edu:15002/status"
        makeGetRequest(urlString: statusUrlString) { data, response, error in
            pollServerStatus(data: data, response: response, error: error)
        }
        if (serverStatus != ServerStatus.data_upload_ended)
        {
            print("Server isn't ready")
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    print("pipeline started successfully.")
                }
            } else {
                print("pipeline failed with response: \(String(describing: response))")
            }
        }
        task.resume()
    }
    
    
    func downloadVideo(urlString: String, splatName: String) {
//        let baseURL = "http://yourserver.com" // Replace with your actual server URL
//        let downloadURLString = "\(baseURL)/download_video/\(splatName)"
        
        let statusUrlString = "http://osiris.cs.hmc.edu:15002/status"
        makeGetRequest(urlString: statusUrlString) { data, response, error in
            pollServerStatus(data: data, response: response, error: error)
        }
//        if ((serverStatus != ServerStatus.rendering_ended) && (serverStatus != ServerStatus.waiting_for_data))
//        {
//            print("Server hasn't finished generating the video.")
//            return
//        }
        
        let downloadURLString = urlString
        
        guard let downloadURL = URL(string: downloadURLString) else {
            print("Invalid URL")
            return
        }
        
        let task = URLSession.shared.downloadTask(with: downloadURL) { localURL, urlResponse, error in
            guard let localURL = localURL else {
                print("Error downloading file: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Optionally, move the file to a permanent location in your app's sandbox container
            // Here's how you might do that:
            do {
                let fileManager = FileManager.default
                let documentsPath = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let savedURL = documentsPath.appendingPathComponent("\(splatName).mp4")
                
                // Check if file exists, remove it
                if fileManager.fileExists(atPath: savedURL.path) {
                    try fileManager.removeItem(at: savedURL)
                }
                
                // Move the downloaded file to the new location
                try fileManager.moveItem(at: localURL, to: savedURL)
                print("File moved to documents folder: \(savedURL)")
            } catch {
                print("File error: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
}

enum ServerStatus {
    case waiting_for_data
    case data_upload_started
    case data_upload_ended
    case preprocessing_started
    case preprocessing_ended
    case training_started
    case training_ended
    case rendering_started
    case rendering_ended
}

