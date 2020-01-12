//
//  imageUtil.swift
//  HelloPytorchMobile
//
//  Copyright © 2020 peterpan. All rights reserved.
//

import UIKit
import SwiftUI

extension UIImage {
    func resized(to newSize: CGSize, scale: CGFloat = 1) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let image = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image
    }

    func normalized() -> [Float32]? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        let w = cgImage.width
        let h = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * w
        let bitsPerComponent = 8
        var rawBytes: [UInt8] = [UInt8](repeating: 0, count: w * h * 4)
        rawBytes.withUnsafeMutableBytes { ptr in
            if let cgImage = self.cgImage,
                let context = CGContext(data: ptr.baseAddress,
                                        width: w,
                                        height: h,
                                        bitsPerComponent: bitsPerComponent,
                                        bytesPerRow: bytesPerRow,
                                        space: CGColorSpaceCreateDeviceRGB(),
                                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                let rect = CGRect(x: 0, y: 0, width: w, height: h)
                context.draw(cgImage, in: rect)
            }
        }
        var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: w * h * 3)
        // normalize the pixel buffer
        // see https://pytorch.org/hub/pytorch_vision_resnet/ for more detail
        for i in 0 ..< w * h {
            normalizedBuffer[i] = (Float32(rawBytes[i * 4 + 0]) / 255.0 - 0.485) / 0.229 // R
            normalizedBuffer[w * h + i] = (Float32(rawBytes[i * 4 + 1]) / 255.0 - 0.456) / 0.224 // G
            normalizedBuffer[w * h * 2 + i] = (Float32(rawBytes[i * 4 + 2]) / 255.0 - 0.406) / 0.225 // B
        }
        return normalizedBuffer
    }
}

var module: TorchModule = {
    if let filePath = Bundle.main.path(forResource: "model", ofType: "pt"),
        let module = TorchModule(fileAtPath: filePath) {
        return module
    } else {
        fatalError("Can't find the model file!")
    }
}()

var labels: [String] = {
    if let filePath = Bundle.main.path(forResource: "words", ofType: "txt"),
        let labels = try? String(contentsOfFile: filePath) {
        return labels.components(separatedBy: .newlines)
    } else {
        fatalError("Can't find the text file!")
    }
}()

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode)
    var presentationMode

    @Binding var image: UIImage?
    @Binding var text: String?
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

        @Binding var presentationMode: PresentationMode
        @Binding var image: UIImage?
        @Binding var text: String?

        init(presentationMode: Binding<PresentationMode>, image: Binding<UIImage?>, text: Binding<String?>) {
            _presentationMode = presentationMode
            _image = image
            _text = text
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let uiImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            image = uiImage
            let resizedImage = uiImage.resized(to: CGSize(width: 224, height: 224))
            guard var pixelBuffer = resizedImage.normalized() else {
                return
            }
            guard let outputs = module.predict(image: UnsafeMutableRawPointer(&pixelBuffer)) else {
                return
            }
            let zippedResults = zip(labels.indices, outputs)
            let sortedResults = zippedResults.sorted { $0.1.floatValue > $1.1.floatValue }.prefix(3)
            var textRes = ""
            for result in sortedResults {
                textRes += "\u{2022} \(labels[result.0]) \n\n"
            }
            text = textRes
            presentationMode.dismiss()

        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            presentationMode.dismiss()
        }

    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, image: $image, text: $text)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<ImagePicker>) {

    }

}
