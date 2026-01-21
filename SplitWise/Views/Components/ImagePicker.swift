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
            headerSection
            Divider().background(Color.n26Divider)
            optionsSection
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
        .onChange(of: imageData) { newValue in
            if newValue != nil {
                isPresented = false
            }
        }
    }

    private var headerSection: some View {
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
    }

    private var optionsSection: some View {
        VStack(spacing: 0) {
            // Galerie Button
            Button(action: { showImagePicker = true }) {
                optionRow(icon: "photo.on.rectangle", text: "Aus Galerie wählen", color: .n26Teal)
            }

            Divider().background(Color.n26Divider).padding(.leading, 56)

            // Kamera Button
            Button(action: { showCamera = true }) {
                optionRow(icon: "camera", text: "Foto aufnehmen", color: .n26Teal)
            }

            // Löschen Button (nur wenn Foto vorhanden)
            if imageData != nil {
                Divider().background(Color.n26Divider).padding(.leading, 56)

                Button(action: {
                    imageData = nil
                    isPresented = false
                }) {
                    optionRow(icon: "trash", text: "Foto entfernen", color: .n26Error)
                }
            }
        }
        .background(Color.n26CardBackground)
    }

    private func optionRow(icon: String, text: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            Text(text)
                .foregroundColor(color == .n26Error ? .n26Error : .n26TextPrimary)
            Spacer()
            if color != .n26Error {
                Image(systemName: "chevron.right")
                    .foregroundColor(.n26TextMuted)
            }
        }
        .padding()
    }
}
