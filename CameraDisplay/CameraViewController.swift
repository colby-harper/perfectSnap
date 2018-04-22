//View when photo has not been captured yet.
import UIKit
import AVFoundation //library that has all photo capture methods
import Vision
import CoreImage
import ImageIO

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
    
    let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: faceDetectorOptions)
    
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
                
                //start capturing frames here and use model
                //start with dataOutput
                //then func capture output
                
                //Add delegate at the beginning
                //Add the capturefunc similar to the video
                
                //CoreML called from captureFunc
                //if output of model is face, (or yes) then capture photo as done below.
                
//                if(TAKE_PHOTO == 1) {
//                    // Your code with delay
//
//                    if (!self.defaultMode){
//                        print("take photo")
//                    let videoConnection = self.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
//
//                    //capture a still image asynchronously
//                    self.stillImageOutput?.captureStillImageAsynchronously(from: videoConnection,
//                                                                           completionHandler: { (imageDataBuffer, error) in
//
//                                                                            if let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: imageDataBuffer!, previewPhotoSampleBuffer:
//                                                                                imageDataBuffer!) {
//                                                                                self.stillImage = UIImage(data: imageData)
//                                                                                self.performSegue(withIdentifier: "showPhoto", sender: self)
//                                                                            }
//                    })
//                    }
//                }
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
    var options : [String : AnyObject]?
    
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
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                
                
                //print(results.count)
                let accuracy = [CIDetectorAccuracy : CIDetectorAccuracyHigh]
                let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
                let faces = faceDetector?.features(in: image, options:[CIDetectorSmile:true])
                
                //Added by Manoj
                //Convert faces into an array of faces
                
                //Only move forward if all the faces are smiling
                var numOfFaces = faces?.count
                var numOfSmiles = 0
                var numOfEyesOpen = 0
                
                var capturePhoto = false
                if !faces!.isEmpty{
                    for face in faces as! [CIFaceFeature]{
                        var bothEyesOpen = true
                        if !face.hasLeftEyePosition || !face.hasRightEyePosition{
                            bothEyesOpen = false
                        }
                        
                        if(face.hasSmile && bothEyesOpen){
                            numOfSmiles += 1
                            numOfEyesOpen += 1
                        }
                    }
                }
                options = [CIDetectorSmile : true, CIDetectorEyeBlink: true, CIDetectorImageOrientation : 6]
                
                let features = self.faceDetector!.featuresInImage(image, options: options)
                
                if(numOfSmiles == numOfEyesOpen && numOfSmiles == faces?.count){
                    //capturePhoto = true
                     faceLandmarks.inputFaceObservations = results
                     detectLandmarks(on: image)
                }
                
            if(capturePhoto){
                
                if (!self.defaultMode){
                    print("take photo")
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
                //faceLandmarks.inputFaceObservations = results
                //detectLandmarks(on: image)
                
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                }
            }
            }
        }
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
                        //let rightEye = observation.landmarks?.rightPupil
                        //let leftEye = observation.landmarks?.leftPupil
                        if (observation.landmarks?.rightPupil) != nil {
                            if (!self.defaultMode){
                                print("take photo")
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
                        }
//                        //self.convertPointsForFace(rightEye, faceBoundingBox)
                        
                    }
                }
            }
        }
}
}
