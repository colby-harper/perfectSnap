//View when photo has not been captured yet.
import UIKit
import AVFoundation //library that has all photo capture methods
import Vision
import CoreML

class CameraViewController : UIViewController
{
    let shapeLayer = CAShapeLayer()
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    var defaultMode = true;
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var reverseButton: UIButton!
    var captureSession = AVCaptureSession() //this is responsible for capturing the image
    
    //which camera input (front or back)
    var backCamera: AVCaptureDevice? //? makes it optional
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    //output device that will store the image
    var stillImageOutput: AVCaptureStillImageOutput? //captures still image output
    var stillImage: UIImage? //stores still image output
    
    //camera preview layer
    //this is what will appear on the screen so the user can see what is in the camera's view.
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto //for full resolution of camera
        
        //this returns an array of devices (cameras on phone) and stores them in cameras var
        let cameras = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        
        //loop through cameras array and check back or front facing
        //this just ensures that back and front facing cameras exist so that
        //we don't set currentCamera to null by mistake
        for camera in cameras {
            if camera.position == .back {
                backCamera = camera
            } else if camera.position == .front {
                frontCamera = camera
            }
        }
        
        //set default device on opening of app
        currentCamera = backCamera
        
        //configure the session with the output for capturing the still image
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput?.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG] //iphone standard
        
        do {
            //this will capture input from the currentCamera
            let captureCameraInput = try AVCaptureDeviceInput(device: currentCamera)
            
            //need to assign input and output devices to captureSession
            captureSession.addInput(captureCameraInput)
            captureSession.addOutput(stillImageOutput)
            let dataOutput = AVCaptureVideoDataOutput()
            dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(dataOutput)
            
            //set up the camera preview layer
            cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            //need to add the layer into the super view
            view.layer.addSublayer(cameraPreviewLayer!)
            //indicates how the video is displayed within the layer bounds
            cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                //TODO
                switch UIDevice.current.orientation{
                case .portrait:
                    cameraPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                case .portraitUpsideDown:
                    cameraPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                case .landscapeLeft:
                    cameraPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                case .landscapeRight:
                    cameraPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                case .unknown:
                    cameraPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                case .faceUp:
                    cameraPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                case .faceDown:
                    cameraPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
            }


            cameraPreviewLayer?.frame = view.layer.frame
            
            //activate camera mode button
            view.bringSubview(toFront: cameraButton)
            //reverse screen button
            view.bringSubview(toFront: reverseButton)
            
            //now the layer is ready to display the image, so give it the image
            captureSession.startRunning()
            
        } catch let error {
            print(error)
        }
    }
    
    @IBAction func reverseCamera() {
        captureSession.beginConfiguration()
        let newCamera = (currentCamera?.position == .back) ?
            frontCamera : backCamera
        
        //drop all existing input
        for input in captureSession.inputs {
            captureSession.removeInput(input as! AVCaptureDeviceInput)
        }
        
        //get new input
        let cameraInput: AVCaptureDeviceInput
        do {
            cameraInput = try AVCaptureDeviceInput(device: newCamera)
        } catch let error {
            print(error)
            return
        }
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        }
        
        //save new setup
        currentCamera = newCamera
        captureSession.commitConfiguration()
    }
    
    @IBAction func shutterButtonDidTap()
    {
        
        //Edited by Manoj:
        if defaultMode{
            if let image = UIImage(named: "cancel.png") {
                cameraButton.setImage(image, for:.normal)
                reverseButton.isHidden = true;
                defaultMode = false;
            }
        } else{
            if let image = UIImage(named: "button-shutter.png") {
                cameraButton.setImage(image, for:.normal)
                reverseButton.isHidden = false;
                defaultMode = true;
            }
        }

    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            if let image = UIImage(named: "button-shutter.png") {
                cameraButton.setImage(image, for:.normal)
                reverseButton.isHidden = false;
                defaultMode = true;
            }
            let imageViewController = segue.destination as! ImageViewController
                imageViewController.image = self.stillImage
        }
    }

}
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        
        //leftMirrored for front camera
        let ciImageWithOrientation = ciImage.applyingOrientation(Int32(UIImageOrientation.leftMirrored.rawValue))
        
        detectFace(on: ciImageWithOrientation)
    }
    
}

extension CameraViewController {
    
    func detectFace(on image: CIImage) {
        //let pixelBuffer = image.pixelBuffer
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            var all_smiles = false
            var all_eyes = false
            if !results.isEmpty {
                //machine learning model
                guard let model = try? VNCoreMLModel(for: eyesClassifier10().model) else {
                    fatalError("Loading CoreML model failed")
                }
                let request = VNCoreMLRequest(model: model, completionHandler: myResultsMethod)
                let handler = VNImageRequestHandler(ciImage: image)
                                    do{
                                        try! handler.perform([request])
                                    }
                
//                let originalPic = convert(cmage: image)
//                let img_faces = detectFaces(from: originalPic)
//                for face in img_faces{
//
//                    guard let this_ciimage = CIImage(image: face) else { return }
//
//                    guard let model = try? VNCoreMLModel(for: CNNEmotions().model) else{
//                        fatalError("Loading CoreML model failed")
//                    }
//                    let request = VNCoreMLRequest(model: model, completionHandler: myResultsMethod)
//                    let handler = VNImageRequestHandler(ciImage: this_ciimage)
//                    do{
//                        try! handler.perform([request])
//                    }//catch{
//                       // print(error)
//                    //}
//                }
                
                //print(results.count)
                let accuracy = [CIDetectorAccuracy : CIDetectorAccuracyHigh]
                let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
                let faces = faceDetector?.features(in: image, options:[CIDetectorSmile:true])
                
                //Added by Manoj
                //Convert faces into an array of faces
                
                //Only move forward if all the faces are smiling
                var numOfSmiles = 0
                //var numOfEyesOpen = 0
                
                //var all_smiles = false
                if !faces!.isEmpty{
                    for face in faces as! [CIFaceFeature]{
                        //var bothEyesOpen = true
                        //if !face.hasLeftEyePosition || !face.hasRightEyePosition{
                        //    bothEyesOpen = false
                        //}
                        
                        if(face.hasSmile){
                            numOfSmiles += 1
                            //numOfEyesOpen += 1
                        }
                    }
                    if(numOfSmiles == faces?.count){
                        all_smiles = true
                    }
                }
                
            if(all_smiles && all_eyes){
                
                if (!self.defaultMode){
                    //print("take photo")
                    let videoConnection = self.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
                    
                    //capture a still image asynchronously
                    self.stillImageOutput?.captureStillImageAsynchronously(from: videoConnection,
                                                                           completionHandler: { (imageDataBuffer, error) in
                                                                            
                                                    if let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: imageDataBuffer!, previewPhotoSampleBuffer:
                                                        imageDataBuffer!) {
                                                        self.stillImage = UIImage(data: imageData)
                                                        self.performSegue(withIdentifier: "showPhoto", sender: self)
                                                    }
                    })
                }
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
                
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                }
            }
            }
        }
    }
    
    func convert(cmage:CIImage) -> UIImage
    {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
    
    //handle model request. print out confidence
    func myResultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation]
            else { fatalError("huh") }
        for classification in results {
            print(classification.identifier, // the scene label
                classification.confidence)
        }
        
    }
    
    func detectFaces(from image: UIImage) -> [UIImage] {
        guard let ciimage = CIImage(image: image) else { return [] }
        var orientation: NSNumber {
            switch image.imageOrientation {
            case .up:            return 1
            case .upMirrored:    return 2
            case .down:          return 3
            case .downMirrored:  return 4
            case .leftMirrored:  return 5
            case .right:         return 6
            case .rightMirrored: return 7
            case .left:          return 8
            }
        }
        return CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])?
            .features(in: ciimage, options: [CIDetectorImageOrientation: orientation])
            .flatMap {
                let rect = $0.bounds.insetBy(dx: -10, dy: -10)
                let ciimage = ciimage.cropping(to: rect)
                UIGraphicsBeginImageContextWithOptions(rect.size, false, image.scale)
                defer { UIGraphicsEndImageContext() }
                UIImage(ciImage: ciimage).draw(in: CGRect(origin: .zero, size: rect.size))
                guard let face = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
                // now that you have your face image you need to properly apply a circle mask to it
                let size = face.size
                let breadth = min(size.width, size.height)
                let breadthSize = CGSize(width: breadth, height: breadth)
                UIGraphicsBeginImageContextWithOptions(breadthSize, false, image.scale)
                defer { UIGraphicsEndImageContext() }
                guard let cgImage = face.cgImage?.cropping(to: CGRect(origin:
                    CGPoint(x: size.width > size.height ? (size.width-size.height).rounded(.down).divided(by: 2) : 0,
                            y: size.height > size.width ? (size.height-size.width).rounded(.down).divided(by: 2) : 0),
                                                                      size: breadthSize)) else { return nil }
                let faceRect = CGRect(origin: .zero, size: CGSize(width: min(size.width, size.height), height: min(size.width, size.height)))
                UIBezierPath(ovalIn: faceRect).addClip()
                UIImage(cgImage: cgImage).draw(in: faceRect)
                return UIGraphicsGetImageFromCurrentImageContext()
            } ?? []
    }
    
    func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                DispatchQueue.main.async {
                    if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        //                        let faceBoundingBox = boundingBox.scaled(to: self.view.bounds.size)
                        //
                        //                        //different types of landmarks
                        //                        let faceContour = observation.landmarks?.faceContour
                        //                        //self.convertPointsForFace(faceContour, faceBoundingBox)
                        //
                        //                        let rightEye = observation.landmarks?.rightEye
                        //                        //self.convertPointsForFace(rightEye, faceBoundingBox)
                    }
                }
            }
        }
    }
}
