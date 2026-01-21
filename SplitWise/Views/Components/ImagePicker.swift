import SwiftUI
import PhotosUI

/// ImagePicker für Teilnehmer-Fotos 📸
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    if let uiImage = image as? UIImage {
                        // Komprimiere das Bild auf max 200x200 für Speichereffizienz
                        let resized = self.resizeImage(uiImage, targetSize: CGSize(width: 200, height: 200))
                        self.parent.imageData = resized.jpegData(compressionQuality: 0.7)
                    }
                }
            }
        }

        private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
            let size = image.size
            let widthRatio = targetSize.width / size.width
            let heightRatio = targetSize.height / size.height
            let ratio = min(widthRatio, heightRatio)

            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let rect = CGRect(origin: .zero, size: newSize)

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage ?? image
        }
    }
}

/// Camera Picker für Live-Fotos 📷
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                let resized = resizeImage(uiImage, targetSize: CGSize(width: 200, height: 200))
                parent.imageData = resized.jpegData(compressionQuality: 0.7)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
            let size = image.size
            let widthRatio = targetSize.width / size.width
            let heightRatio = targetSize.height / size.height
            let ratio = min(widthRatio, heightRatio)

            let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
            let rect = CGRect(origin: .zero, size: newSize)

            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            return newImage ?? image
        }
    }
}

/// Auswahl-Sheet für Foto-Quelle
struct PhotoSourcePicker: View {
    @Binding var imageData: Data?
    @Binding var isPresented: Bool
    @State private var showImagePicker = false
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("📸 Foto auswählen")
                    .font(.headline)
                    .foregroundColor(.n26TextPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.n26TextSecondary)
                }
            }
            .padding()
            .background(Color.n26CardBackground)

            Divider()
                .background(Color.n26Divider)

            // Optionen
            VStack(spacing: 0) {
                Button(action: {
                    showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.n26Teal)
                            .frame(width: 40)
                        Text("Aus Galerie wählen")
                            .foregroundColor(.n26TextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.n26TextMuted)
                    }
                    .padding()
                }

                Divider()
                    .background(Color.n26Divider)
                    .padding(.leading, 56)

                Button(action: {
                    showCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                            .font(.title2)
                            .foregroundColor(.n26Teal)
                            .frame(width: 40)
                        Text("Foto aufnehmen")
                            .foregroundColor(.n26TextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.n26TextMuted)
                    }
                    .padding()
                }

                if imageData != nil {
                    Divider()
                        .background(Color.n26Divider)
                        .padding(.leading, 56)

                    Button(action: {
                        imageData = nil
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.title2)
                                .foregroundColor(.n26Error)
                                .frame(width: 40)
                            Text("Foto entfernen")
                                .foregroundColor(.n26Error)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .background(Color.n26CardBackground)

            Spacer()
        }
        .background(Color.n26Background)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $imageData)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(imageData: $imageData)
                .ignoresSafeArea()
        }
        .onChange(of: imageData) { _, _ in
            if imageData != nil {
                isPresented = false
            }
        }
    }
}
