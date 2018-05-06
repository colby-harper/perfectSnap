//View when photo has been captured by machine learning model
import UIKit
import AVFoundation

class ImageViewController : UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?
    var camera: AVCaptureDevice?
    var newImage: UIImage?
    
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        newImage = image

        if(UIDevice.current.orientation == .landscapeLeft) {
            if(camera?.position == .front) {
                newImage = image?.rotate(radians: .pi/2) // Rotate 45 degrees
            }
            else {
                newImage = image?.rotate(radians: -.pi/2)
            }
        }
        else if(UIDevice.current.orientation == .landscapeRight) {
            if(camera?.position == .front) {
                newImage = image?.rotate(radians: -.pi/2)
            }
            else {
                newImage = image?.rotate(radians: .pi/2)
            }
        }
        
        imageView.image = newImage
    }
    
    //discard photo
    @IBAction func deleteButtonDidTap () {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func save(sender: UIButton) {
        guard let imageToSave = newImage else {
            return
        }
        //save photo
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: false, completion: nil)
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, self.scale)
        let context = UIGraphicsGetCurrentContext()!
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
