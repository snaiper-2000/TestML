//
//  ViewController.swift
//  TestML
//
//  Created by Rogatsevich Dmitry on 2/28/20.
//  Copyright © 2020 Rogatsevich Dmitry. All rights reserved.
//

import UIKit
import Vision
import CoreML

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: ImageClassifier().model)
            else { fatalError("Can't load VisionML model") }

        let request = VNCoreMLRequest(model: visionModel) { (request, error) in
            guard let results = request.results else { return }
            self.handleRequestResults(results)
        }

        requests = [request]
    }
    
    func handleRequestResults(_ results: [Any]) {
        let categoryText: String?

        defer {
            DispatchQueue.main.async {
                self.categoryLabel.text = categoryText
            }
        }

        guard let foundObject = results
            .compactMap({ $0 as? VNClassificationObservation })
            .first(where: { $0.confidence > 0.7 })
            else {
                categoryText = nil
                return
        }

        let category = categoryTitle(identifier: foundObject.identifier)
        let confidence = "\(round(foundObject.confidence * 100 * 100) / 100)%"
        categoryText = "\(category) \(confidence)"
    }
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        var requestOptions: [VNImageOption: Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(
            sampleBuffer,
            key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
            attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
        }
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            options: requestOptions)

        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print(error)
        }
    }

}

