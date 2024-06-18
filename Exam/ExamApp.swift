import SwiftUI

@main
struct ExamApp: App {
    var body: some Scene {
        WindowGroup {
            let userProfile = UserProfile(name: "", email: "", imageURL: URL(string: "https://example.com/image.jpg")!)
            let presenter = UserProfilePresenter(userProfile: userProfile)
            UserProfileView(presenter: presenter)
        }
    }
}
