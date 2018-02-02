//View when photo has not been captured yet.
import UIKit
import AVFoundation //library that has all photo capture methods

class CameraViewController : UIViewController
{
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
            
            //set up the camera preview layer
            cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            //need to add the layer into the super view
            view.layer.addSublayer(cameraPreviewLayer!)
            //indicates how the video is displayed within the layer bounds
            cameraPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
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
        //this code will be removed when we progress.
        //The goal of pressing the shutter button will be to activate camera mode and
        //have the device take the picture itself. For now, it will capture a photo
        //Just as a normal camera app would do.
        let videoConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        
        //capture a still image asynchronously
        stillImageOutput?.captureStillImageAsynchronously(from: videoConnection,
            completionHandler: { (imageDataBuffer, error) in
            
            if let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: imageDataBuffer!, previewPhotoSampleBuffer:
                imageDataBuffer!) {
                    self.stillImage = UIImage(data: imageData)
                    self.performSegue(withIdentifier: "showPhoto", sender: self)
                }
        })
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPhoto" {
            let imageViewController = segue.destination as! ImageViewController
                imageViewController.image = self.stillImage
        }
    }
}
