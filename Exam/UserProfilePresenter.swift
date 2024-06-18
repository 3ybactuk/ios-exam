import SwiftUI
import Combine
import Photos

class UserProfilePresenter: ObservableObject {
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userImage: UIImage? = nil
    @Published var userProfile: UserProfile

    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }

    func fetchUserProfile() {
        if let name = KeychainHelper.shared.get(key: "userName"),
           let email = KeychainHelper.shared.get(key: "userEmail") {
            userName = name
            userEmail = email
        }

        if let localImagePath = KeychainHelper.shared.getLocalImagePath(forKey: "userImagePath"),
           let imageData = try? Data(contentsOf: localImagePath) {
            userImage = UIImage(data: imageData)
            userProfile.localImagePath = localImagePath
        } else {
            downloadImage(from: userProfile.imageURL)
        }
    }

    private func downloadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                return
            }

            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let localPath = documentsDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                try data.write(to: localPath)
                self.userProfile.localImagePath = localPath
                KeychainHelper.shared.saveLocalImagePath(localPath, forKey: "userImagePath")
            } catch {
                print("Error saving image: \(error)")
            }

            DispatchQueue.main.async {
                self.userImage = image
                self.saveImageToGallery(image: image)
            }
        }.resume()
    }
    
    private func saveImageToGallery(image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            request.creationDate = Date()
        } completionHandler: { success, error in
            if let error = error {
                print("Error saving image to gallery: \(error)")
            } else {
                print("Image saved to gallery successfully.")
            }
        }
    }

    func saveUserProfile(name: String, email: String, imageURL: URL) {
        userName = name
        userEmail = email
        userProfile.name = name
        userProfile.email = email
        userProfile.imageURL = imageURL

        KeychainHelper.shared.set(value: name, forKey: "userName")
        KeychainHelper.shared.set(value: email, forKey: "userEmail")

        downloadImage(from: imageURL)
    }
}
