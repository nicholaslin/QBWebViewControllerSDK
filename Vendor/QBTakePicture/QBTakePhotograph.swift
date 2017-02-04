//
//  QBTakePhotograph.swift
//  QBWebViewSDK
//
//  Created by 林子帆 on 2017/1/17.
//  Copyright © 2017年 林子帆. All rights reserved.
//

import Foundation
import AssetsLibrary
import Photos

class QBTakePhotographNav: UIImagePickerController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
     var allowEditing:Bool = false
     var selectedImage:UIImage?
     var completeCallback:((_ image:UIImage?)->Void)!

     override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        completeCallback(selectedImage)
    }
    
     func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image = self.allowsEditing ? (info[UIImagePickerControllerEditedImage] as! UIImage): (info[UIImagePickerControllerOriginalImage] as! UIImage)
        
        selectedImage = fixOrientation(image: image)
        
        self.dismiss(animated: true, completion: nil)

    }
    
     func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func fixOrientation(image:UIImage) -> UIImage {
        
        if image.imageOrientation == .up {
            return image
        }

        var transform = CGAffineTransform.identity
        
        switch (image.imageOrientation) {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: CGFloat(M_PI))
            
        case .left,.leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI))
            
        case .right,.rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))
            
        case .up,.upMirrored:
            break
        }
        
        switch (image.imageOrientation) {
        case .upMirrored,.downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .leftMirrored,.rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            
        case .up,.down,.left,.right:
            break
        }
        
        let ctx = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height),
                            bitsPerComponent: (image.cgImage?.bitsPerComponent)!, bytesPerRow: 0,
                            space: (image.cgImage?.colorSpace!)!,
                            bitmapInfo: (image.cgImage?.bitmapInfo.rawValue)!)
        ctx?.concatenate(transform)
        switch (image.imageOrientation) {
        case .left,.leftMirrored,.right,.rightMirrored:
            // Grr...
            ctx?.draw(image.cgImage!, in: CGRect(x: 0,y: 0,width: image.size.height,height: image.size.width));
            
        default:
            ctx?.draw(image.cgImage!, in: CGRect(x: 0,y: 0,width: image.size.width,height: image.size.height));
            break
        }

        let cgimg = ctx?.makeImage()
        let img = UIImage(cgImage: cgimg!)

        return img

        
        
    }
    
}
