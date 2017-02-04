//
//  QBTakePicture.swift
//  QBWebViewSDK
//
//  Created by 林子帆 on 2017/1/17.
//  Copyright © 2017年 林子帆. All rights reserved.
//

import Foundation
import AssetsLibrary

class QBTakePictureNav: UINavigationController {
    
    var selectedImage:UIImage?
    var allowsEditing:Bool = false
    var completeCallback:((_ image:UIImage?)->Void)!
    
    class func createTakePictureNav(allowsEditing:Bool = false, completeCallback:@escaping (_ image:UIImage?)->Void) ->QBTakePictureNav {
        
        let nav = UIStoryboard(name: "QBTakePicture", bundle: Bundle(identifier: QBWebView_SDK_Identifier)).instantiateViewController(withIdentifier: "QBTakePictureNav") as! QBTakePictureNav
        nav.allowsEditing = allowsEditing
        nav.completeCallback = completeCallback
        return nav
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        completeCallback(selectedImage)
    }
    
}


class QBTakePictureRootViewController:UITableViewController,UIAlertViewDelegate {
    
    let defaultLibray = ALAssetsLibrary()
    var albums:[ALAssetsGroup] = []
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView()
        
        defaultLibray.enumerateGroupsWithTypes(0xFFFFFFFF, usingBlock: { [weak self](group, stop) in
            
            if group != nil {
                
                group!.setAssetsFilter(.allPhotos())
                if group!.numberOfAssets() > 0 {
                    self?.albums.append(group!)
                }
                
            }else {
                
                 self?.sortAlbumsAndShow()
                
            }
            
        }) { [weak self](error) in
            
            if ALAssetsLibrary.authorizationStatus() == .denied {
                self?.showAuthorityAlertWithTitle("无法查看照片! o(>﹏<)o\n 请在系统\"设置－隐私－照片\"选项中打开\(QBAppInfo.appName)的相册权限")
            }
        }
        

    }
    
    private func sortAlbumsAndShow() {
        
        var savedPhotoAlbum:ALAssetsGroup?
        for index in 0..<albums.count {
            
            if albums[index].value(forProperty: ALAssetsGroupPropertyType) as! UInt32 == ALAssetsGroupSavedPhotos {
                savedPhotoAlbum = albums[index]
                albums.remove(at: index)
                break
            }
            
        }
        if savedPhotoAlbum != nil {
            albums.insert(savedPhotoAlbum!, at: 0)
        }
        tableView.reloadData()
        
    }
    
    private func showAuthorityAlertWithTitle(_ title:String) {
        
        let alertView = UIAlertView(title: title, message: "", delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "去设置")
        alertView.show()
        
    }

    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return albums.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "QBPictureAlbumCell") as! QBPictureAlbumCell
        let album = albums[indexPath.row]
        cell.albumImage.image = UIImage(cgImage: album.posterImage().takeUnretainedValue())
        cell.albumName.text = album.value(forProperty: ALAssetsGroupPropertyName) as! String?
        cell.numOfPicture.text = String(album.numberOfAssets())
        return cell
        
    }
    
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let album = UIStoryboard(name: "QBTakePicture", bundle: Bundle(identifier: QBWebView_SDK_Identifier)).instantiateViewController(withIdentifier: "QBAlbumShowViewController") as! QBAlbumShowViewController
        album.album = albums[indexPath.row]
        self.navigationController?.pushViewController(album, animated: true)
        
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        
        if buttonIndex != alertView.cancelButtonIndex {
            
            if let settingURL = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(settingURL)
            }
            
        }
        
    }

    @IBAction func onCancelClick(_ sender: Any) {
        
         self.navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
}

class QBPictureAlbumCell:UITableViewCell {
    
    
    @IBOutlet weak var albumImage: UIImageView!
    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var numOfPicture: UILabel!
    
    
}

class QBAlbumShowViewController:UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var pictureList: UICollectionView!
    
    var album:ALAssetsGroup!
    var assets:[ALAsset] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.title = album.value(forProperty: ALAssetsGroupPropertyName) as? String? ?? ""
        
        if album != nil {
            album.enumerateAssets({ [weak self](asset, index, stop) in
                
                if asset != nil {
                    self?.assets.append(asset!)
                }else {
                    self?.assets.reverse()
                    self?.pictureList.reloadData()
                }
                
            })
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assets.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QBAlbumThumbilPictureCell", for: indexPath) as! QBAlbumThumbilPictureCell
        cell.thumbil.image = UIImage(cgImage: assets[indexPath.row].thumbnail().takeUnretainedValue())
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let vc = UIStoryboard(name: "QBTakePicture", bundle: Bundle(identifier: QBWebView_SDK_Identifier)).instantiateViewController(withIdentifier: "QBPictureShowViewController") as! QBPictureShowViewController
        vc.image = UIImage(cgImage:assets[indexPath.row].defaultRepresentation().fullScreenImage().takeUnretainedValue())
        self.navigationController?.pushViewController(vc, animated: true)

    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if UIScreen.main.bounds.width / 80 > 5 {
            let colomn = UIScreen.main.bounds.width / 80
            let size = UIScreen.main.bounds.width / colomn
            return CGSize(width: size - 1, height: size - 1)
            
        }else {
            
            return CGSize(width: UIScreen.main.bounds.width / 4 - 1, height: UIScreen.main.bounds.width / 4 - 1)
            
        }
        
        
    }

    @IBAction func onCancelClick(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
}

class QBAlbumThumbilPictureCell:UICollectionViewCell {
    
    @IBOutlet weak var thumbil: UIImageView!
    
}

class QBPictureShowViewController:UIViewController,UIGestureRecognizerDelegate,UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    var imageView:UIImageView!
    var image:UIImage!
    
    var maxScale:CGFloat = 3.0
    var minScale:CGFloat = 0.5
    
    var cropFrame:CGRect?
    
    var isShowCropFrame:Bool {
        get {
            if let nav = self.navigationController as? QBTakePictureNav {
                if nav.allowsEditing {
                    return true
                }else {
                    return false
                }
            }else {
                return false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        addImageView(image: image)
        addBottomView()
        if isShowCropFrame {
            addEditFrame()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    
    private func addImageView(image:UIImage) {
        
        let screenRatio = UIScreen.main.bounds.width / UIScreen.main.bounds.height
        
        var imageW:CGFloat = 0
        var imageH:CGFloat = 0
        
        if image.size.width / image.size.height > screenRatio {
            
            let ratio = UIScreen.main.bounds.width / image.size.width
            imageH = image.size.height * ratio
            imageW = UIScreen.main.bounds.width
            
        }else {
            let ratio = UIScreen.main.bounds.height / image.size.height
            imageW = image.size.width * ratio
            imageH = UIScreen.main.bounds.height
        }
        
        
        imageView = UIImageView(frame: CGRect(x: (UIScreen.main.bounds.width - imageW) / 2, y: ((UIScreen.main.bounds.height - imageH) / 2) - 20 , width: imageW, height: imageH))
        imageView.center = contentCenter(forBoundingSize: scrollView.bounds.size, contentSize: imageView.bounds.size)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        
        scrollView.delegate = self
        
        scrollView.maximumZoomScale = 3.0
        scrollView.minimumZoomScale = 1.0
        
    }
    
    private func addEditFrame() {
        
        cropFrame = CGRect(x: 0, y: (self.view.frame.height - self.view.frame.width) / 2 , width: self.view.frame.width, height: self.view.frame.width)
        
        let viewpath = UIBezierPath(rect: self.view.bounds)
        let rectPath = UIBezierPath(rect: cropFrame!)
        viewpath.append(rectPath)
        viewpath.usesEvenOddFillRule = true
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = viewpath.cgPath
        shapeLayer.fillColor = UIColor.black.cgColor
        shapeLayer.fillRule = kCAFillRuleEvenOdd
        shapeLayer.opacity = 0.5
        
        self.view.layer.addSublayer(shapeLayer)
        
        let path=UIBezierPath(rect: cropFrame!)
        let layer=CAShapeLayer()
        layer.path=path.cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor=UIColor.white.cgColor
        view.layer.addSublayer(layer)

        
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        imageView.center = contentCenter(forBoundingSize: scrollView.bounds.size, contentSize: scrollView.contentSize)
    }
    
    private func contentCenter(forBoundingSize boundingSize: CGSize, contentSize: CGSize) -> CGPoint {

        let horizontalOffest = (boundingSize.width > contentSize.width) ? ((boundingSize.width - contentSize.width) * 0.5): 0.0
        let verticalOffset = (boundingSize.height > contentSize.height) ? ((boundingSize.height - contentSize.height) * 0.5): 0.0
        
        return CGPoint(x: contentSize.width * 0.5 + horizontalOffest,  y: contentSize.height * 0.5 + verticalOffset)
    }

    private func addBottomView() {
        
        let translucentView = UIView()
        translucentView.frame = CGRect(x: 0, y: self.view.bounds.height - 64, width: self.view.bounds.width, height: 64)
        translucentView.backgroundColor = UIColor.black
        translucentView.alpha = 0.5
        
        let cancelBtn = UIButton(frame: CGRect(x: 10, y: 0, width: 40, height: 64))
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.setTitleColor(UIColor.white, for: .normal)
        cancelBtn.addTarget(self, action: #selector(onCancelClick), for: .touchUpInside)
        translucentView.addSubview(cancelBtn)
        
        let confirmBtn = UIButton(frame: CGRect(x: self.view.bounds.width - 50, y: 0, width: 40, height: 64))
        confirmBtn.setTitle("选取", for: .normal)
        confirmBtn.setTitleColor(UIColor.white, for: .normal)
        confirmBtn.addTarget(self, action: #selector(onPickUpClick), for: .touchUpInside)
        translucentView.addSubview(confirmBtn)
        
        self.view.addSubview(translucentView)
        
    }
    
    private func cropImage() ->UIImage? {
        
        UIGraphicsBeginImageContext(CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        self.view.drawHierarchy(in: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height) , afterScreenUpdates: false)
        var image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard cropFrame != nil else{
            return nil
        }
        
        image = UIImage(cgImage: (image?.cgImage?.cropping(to: cropFrame!))!)
        
        return image
        
    }
    
    func onPickUpClick() {
        
        if isShowCropFrame {
            (self.navigationController as! QBTakePictureNav).selectedImage = cropImage()
        }else {
            (self.navigationController as! QBTakePictureNav).selectedImage = image
        }
        self.navigationController?.dismiss(animated: true, completion: nil)
        
    }
    
    func onCancelClick() {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
}

