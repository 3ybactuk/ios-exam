import SwiftUI
import PhotosUI

struct UserProfileView: View {
    @ObservedObject var presenter: UserProfilePresenter
    @State private var newName: String = ""
    @State private var newEmail: String = ""
    @State private var newImageURL: String = ""
    @State private var isPickerPresented: Bool = false

    var body: some View {
        VStack {
            ZStack {
                if let image = presenter.userImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                } else {
                    ProgressView()
                        .frame(width: 100, height: 100)
                }

                Button(action: {
                    isPickerPresented = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                        .frame(width: 30, height: 30)
                }
                .padding(6)
                .offset(x: 40, y: 40)
                .sheet(isPresented: $isPickerPresented) {
                    PhotoPicker(presenter: presenter)
                }
            }
            .frame(width: 100, height: 100)
            
            Text(presenter.userName)
                .font(.largeTitle)
                .padding()

            Text(presenter.userEmail)
                .font(.subheadline)
                .padding()

            Spacer()

            TextField("enter_name", text: $newName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("enter_email", text: $newEmail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("enter_image_url", text: $newImageURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: {
                if let url = URL(string: newImageURL) {
                    presenter.saveUserProfile(name: newName, email: newEmail, imageURL: url)
                }
            }) {
                Text("save_changes")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            presenter.fetchUserProfile()
            newName = presenter.userName
            newEmail = presenter.userEmail
            newImageURL = presenter.userProfile.imageURL.absoluteString
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @ObservedObject var presenter: UserProfilePresenter

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(presenter: presenter)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var presenter: UserProfilePresenter

        init(presenter: UserProfilePresenter) {
            self.presenter = presenter
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true, completion: nil)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self, let image = image as? UIImage else {
                    return
                }

                DispatchQueue.main.async {
                    self.presenter.userImage = image

                    if let data = image.jpegData(compressionQuality: 1.0) {
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let localPath = documentsDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                        do {
                            try data.write(to: localPath)
                            self.presenter.userProfile.localImagePath = localPath
                            KeychainHelper.shared.saveLocalImagePath(localPath, forKey: "userImagePath")
                        } catch {
                            print("Error saving image: \(error)")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    UserProfileView(presenter: UserProfilePresenter(userProfile: UserProfile(name: "", email: "", imageURL: URL(string: "https://example.com/image.jpg")!)))
        .environment(\.locale, .init(identifier: "ru"))
    
}
