import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

public struct ImageAttachmentSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var storageService: DocumentStorageService
    public var onImageInserted: (String) -> Void

    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var isCameraPresented: Bool = false
    @State private var isFileImporterPresented: Bool = false
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil

    public init(
        storageService: DocumentStorageService = DocumentStorageService(),
        onImageInserted: @escaping (String) -> Void
    ) {
        self.storageService = storageService
        self.onImageInserted = onImageInserted
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    if isProcessing {
                        ProgressView("Compressing & Saving Image...")
                            .foregroundColor(.white)
                            .padding()
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding()
                    }

                    // Options List
                    VStack(spacing: 12) {
                        // 1. Photos Picker
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "#FFD60A"))
                                Text("Choose from Photo Library")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .liquidGlass(cornerRadius: 12)
                        }
                        .onChange(of: selectedPhotoItem) { _, newItem in
                            guard let newItem = newItem else { return }
                            processPhotosPickerItem(newItem)
                        }

                        // 2. Camera
                        #if canImport(UIKit)
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button {
                                isCameraPresented = true
                            } label: {
                                HStack {
                                    Image(systemName: "camera")
                                        .font(.system(size: 18))
                                        .foregroundColor(Color(hex: "#FFD60A"))
                                    Text("Take Photo with Camera")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .liquidGlass(cornerRadius: 12)
                            }
                        }
                        #endif

                        // 3. Paste from Clipboard
                        Button {
                            pasteFromClipboard()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "#FFD60A"))
                                Text("Paste Image from Clipboard")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .liquidGlass(cornerRadius: 12)
                        }

                        // 4. From Files
                        Button {
                            isFileImporterPresented = true
                        } label: {
                            HStack {
                                Image(systemName: "folder")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "#FFD60A"))
                                Text("Import from Files")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .liquidGlass(cornerRadius: 12)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.top, 24)
            }
            .navigationTitle("Insert Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $isCameraPresented) {
                CameraPickerView { image in
                    processRawImage(image)
                }
            }
            #endif
            .fileImporter(
                isPresented: $isFileImporterPresented,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        processFileURL(url)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func processPhotosPickerItem(_ item: PhotosPickerItem) {
        isProcessing = true
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                #if canImport(UIKit)
                if let uiImage = UIImage(data: data) {
                    processRawImage(uiImage)
                    return
                }
                #endif
            }
            await MainActor.run {
                self.isProcessing = false
                self.errorMessage = "Failed to load image from photo library."
            }
        }
    }

    private func pasteFromClipboard() {
        #if canImport(UIKit)
        if let image = UIPasteboard.general.image {
            processRawImage(image)
        } else {
            self.errorMessage = "No image found in clipboard."
            HapticManager.notification(.error)
        }
        #endif
    }

    private func processFileURL(_ url: URL) {
        isProcessing = true
        guard url.startAccessingSecurityScopedResource() else {
            self.errorMessage = "Permission denied to access file."
            self.isProcessing = false
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        #if canImport(UIKit)
        if let data = try? Data(contentsOf: url),
           let image = UIImage(data: data) {
            processRawImage(image)
        } else {
            self.errorMessage = "Could not decode image from file."
            self.isProcessing = false
        }
        #endif
    }

    #if canImport(UIKit)
    private func processRawImage(_ image: UIImage) {
        isProcessing = true
        Task {
            // Downscale to max 2048px for performance
            let maxDimension: CGFloat = 2048.0
            var finalImage = image
            let size = image.size
            if size.width > maxDimension || size.height > maxDimension {
                let ratio = min(maxDimension / size.width, maxDimension / size.height)
                let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                if let resized = UIGraphicsGetImageFromCurrentImageContext() {
                    finalImage = resized
                }
                UIGraphicsEndImageContext()
            }

            guard let jpegData = finalImage.jpegData(compressionQuality: 0.85) else {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = "Failed to encode JPEG."
                }
                return
            }

            do {
                let relativePath = try await storageService.saveAsset(data: jpegData, fileExtension: "jpg")
                await MainActor.run {
                    self.isProcessing = false
                    self.onImageInserted(relativePath)
                    HapticManager.notification(.success)
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = "Failed to save image asset: \(error.localizedDescription)"
                }
            }
        }
    }
    #endif
}

#if canImport(UIKit)
public struct CameraPickerView: UIViewControllerRepresentable {
    public var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(parent: CameraPickerView) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            parent.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
