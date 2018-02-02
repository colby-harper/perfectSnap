//View when photo has been captured by machine learning model
import UIKit

class ImageViewController : UIViewController
{
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.image = image
    }
    
    //discard photo
    @IBAction func deleteButtonDidTap () {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func save(sender: UIButton) {
        guard let imageToSave = image else {
            return
        }
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil)
        dismiss(animated: false, completion: nil)
    }
}
