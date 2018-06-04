//
//  ViewController.swift
//  EditWorld
//
//  Created by Student User on 5/21/18.
//  Copyright © 2018 EditWorld. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import SpriteKit

extension UserDefaults {
    func colorForKey(key: String) -> UIColor? {
        var color: UIColor?
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor
        }else{
            color = UIColor.white
        }
        return color
    }
    
    func setColor(color: UIColor?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color) as NSData?
        }
        set(colorData, forKey: key)
    }
    
}

extension UIView {
    func addContraintsWithFormat(_ format: String, views: UIView...) {
        var viewDict = [String: UIView]()
        
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewDict[key] = view
        }
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewDict))
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var customizedView: UIView!
    
    @IBOutlet var textInputView: UIView!
    @IBOutlet weak var postText: UIButton!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var textBox: UITextField!
    @IBOutlet weak var sendBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    
    @IBOutlet weak var fontSlider: UISlider!
    @IBOutlet weak var fontLabel: UILabel!
    @IBOutlet weak var distanceSlider: UISlider!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var colorSlider: UISlider!
    
    var ishidden = false
    
    let session = ARSession()
    let defaults = UserDefaults.standard
    let config = ARWorldTrackingConfiguration()

    var textNode:SCNNode?
    var textSize:CGFloat = 5
    var textDistance:Float = 15
    private var drawingNodes = [DynamicGeometryNode]()
    var previousPoint: SCNVector3?
    var addPointButton : UIButton!
    //var frameIdx = 0
    //var splitLine = false
    //var isDrawing = false
    
    let colorArray = [ 0x000000, 0xfe0000, 0xff7900, 0xffb900, 0xffde00, 0xfcff00, 0xd2ff00, 0x05c000, 0x00c0a7, 0x0600ff, 0x6700bf, 0x9500c0, 0xbf0199, 0xffffff ]
    
    
    static func registerDefaults() {
        
        if (UserDefaults.standard.object(forKey:"textDistance") == nil) {
            UserDefaults.standard.register(defaults: ["textDistance":20])
        }
        
        if (UserDefaults.standard.object(forKey:"textFont") == nil) {
            UserDefaults.standard.register(defaults: ["textFont":60])
        }
        
        if (UserDefaults.standard.object(forKey:"textColor") == nil) {
            UserDefaults.standard.setColor(color: UIColor.white, forKey: "textColor")
        }
    }
    
    //set all main buttons first
    var infoButton:UIButton = {
        let image = UIImage(named: "information.png") as? UIImage?
        let btn = UIButton(type: UIButtonType.custom)
        btn.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        btn.center = CGPoint(x: UIScreen.main.bounds.width * 0.84, y: UIScreen.main.bounds.height * 0.15)
        btn.setImage(image!, for: .normal)
        btn.alpha = 0.8
        return btn
    }()
    
    
    var drawButton:UIButton = {
        let image = UIImage(named: "Group 1.png") as? UIImage?
        let btn = UIButton(type: UIButtonType.custom)
        btn.frame = CGRect(x: 0, y: 0, width: 68, height: 68)
        btn.center = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height*0.88)
        btn.layer.cornerRadius = btn.bounds.height/2
        btn.setImage(image!, for: .normal)
        //btn.alpha = 0.8
        btn.tag = 0
        return btn
    }()
    
    var emojiButton:UIButton = {
        let image = UIImage(named: "Group 3.png") as? UIImage?
        let btn = UIButton(type: UIButtonType.custom)
        btn.frame = CGRect(x: 0, y: 0, width: 68, height: 68)
        btn.center = CGPoint(x: UIScreen.main.bounds.width * 0.77, y: UIScreen.main.bounds.height * 0.9)
        btn.layer.cornerRadius = btn.bounds.height/2
        btn.setImage(image!, for: .normal)
        //btn.alpha = 0.8
        return btn
    }()
    
    var imageButton:UIButton = {
        let image = UIImage(named: "Group 2.png") as? UIImage?
        let btn = UIButton(type: UIButtonType.custom)
        btn.frame = CGRect(x: 0, y: 0, width: 68, height: 68)
        btn.center = CGPoint(x: UIScreen.main.bounds.width * 0.23, y: UIScreen.main.bounds.height * 0.9)
        btn.layer.cornerRadius = btn.bounds.height/2
        btn.setImage(image!, for: .normal)
        //btn.alpha = 0.8
        return btn
    }()
    
    private func isReadyForDrawing(trackingState: ARCamera.TrackingState) -> Bool {
        switch trackingState {
        case .normal:
            return true
        default:
            return false
        }
    }
    
    // main components load
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        customizedView.layer.cornerRadius = 12
        
        self.sceneView.showsStatistics = false
        self.sceneView.session.run(config)
        self.sceneView.delegate = self
        self.view.addSubview(drawButton)
        self.view.addSubview(imageButton)
        self.view.addSubview(emojiButton)
        self.view.addSubview(infoButton)

        
        // Add buttons' targets to handle user button selections
        drawButton.addTarget(self, action: #selector(tapDrawButton(sender:)), for: .touchUpInside)
        imageButton.addTarget(self, action: #selector(tapImageButton(sender:)), for: .touchUpInside)
        emojiButton.addTarget(self, action: #selector(tapEmojiButton(sender:)), for: .touchUpInside)
        infoButton.addTarget(self, action: #selector(tapInfoButton(sender:)), for: .touchUpInside)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == gestureRecognizer.view
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func changeFontSize(_ sender: UISlider) {
        fontLabel.text = String(Int(sender.value)) + " pt"
        defaults.set(CGFloat(sender.value), forKey: "textFont")
    }
    
    @IBAction func changeDistance(_ sender: UISlider) {
        distanceLabel.text = String(format: "%.0f cm", sender.value)
        defaults.set(sender.value, forKey: "textDistance")
    }
    
    @IBAction func changeColor(_ sender: UISlider) {
        let color = uiColorFromHex(rgbValue: colorArray[Int(sender.value)])
        defaults.setColor(color: color, forKey: "textColor")
    }
    
    func uiColorFromHex(rgbValue: Int) -> UIColor {
        
        let red =   CGFloat((rgbValue & 0xFF0000) >> 16) / 0xFF
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 0xFF
        let blue =  CGFloat(rgbValue & 0x0000FF) / 0xFF
        let alpha = CGFloat(1.0)
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    // call customized popUp
    func animateIn() {
        self.view.addSubview(customizedView)

        customizedView.transform = CGAffineTransform.init(translationX: 0, y: -600)
        customizedView.transform = CGAffineTransform.init(scaleX: 1, y: 1)
        customizedView.alpha = 0
        
        UIView.animate(withDuration: 0.4) {
            self.customizedView.alpha = 1
            self.customizedView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.customizedView.transform = CGAffineTransform(translationX: 0, y: 0)
        }
    }
    
    func animateOut() {
        UIView.animate(withDuration: 0.3, animations: {
            self.customizedView.transform = CGAffineTransform.init(scaleX: 0.3, y: 0.3)
            self.customizedView.alpha = 0
        }) {(success:Bool) in
            self.customizedView.removeFromSuperview()
        }
    }
    
    @objc func tapInfoButton(sender: UIButton!) {
        animateIn()
    }
    
    @IBAction func dissmissPopUp(_ sender: Any) {
        animateOut()
    }
    
    //input text contents by typing
    func setupScene() {
        sceneView.delegate = self
        sceneView.session = session
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
        
        enableEnvironmentMapWithIntensity(25.0)
        
        DispatchQueue.main.async {
            //center the view
        }
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
        }
        
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    func startType() {
        self.view.addSubview(textInputView)
        textInputView.center = self.view.center
        textInputView.transform = CGAffineTransform.init(translationX: 0, y: 206)
        textBox.becomeFirstResponder()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func tapPostText(_ sender: UIButton) {
        if let text = textBox.text {
            self.showText(text: text)
        }else{
            print("empty string")
        }
        //print(growingTextView.textView.text)
        self.textBox.text = ""
        self.view.endEditing(true)
        self.textInputView.removeFromSuperview()
    }
    
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                self.inputBottomConstraint.constant = -34
                self.sendBottomConstraint.constant = -34
                UIView.animate(withDuration: 0.25, animations: { () -> Void in self.view.layoutIfNeeded() })
            }
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        if let userInfo = notification.userInfo {
            if let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size.height {
                self.inputBottomConstraint.constant = -keyboardHeight
                self.sendBottomConstraint.constant = -keyboardHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    @objc func tapEmojiButton(sender: UIButton!) {
        startType()
        //self.showText(text: "test")
    }
    
    //draw graffiti
    func worldPositionForScreenCenter() -> SCNVector3 {
        let screenBounds = UIScreen.main.bounds
        let center = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
        let centerVec3 = SCNVector3Make(Float(center.x), Float(center.y), 0.99)
        return sceneView.unprojectPoint(centerVec3)
    }
    
    @objc func tapDrawButton(sender: UIButton!) {
        guard let frame = sceneView.session.currentFrame else {return}
        guard isReadyForDrawing(trackingState: frame.camera.trackingState) else {return}
        //call lineNode function to draw
        let drawingNode = DynamicGeometryNode(color: defaults.colorForKey(key: "textColor")!, lineWidth: defaults.float(forKey: "textFont") / 10000)
        sceneView.scene.rootNode.addChildNode(drawingNode)
        drawingNodes.append(drawingNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let currentDrawing = drawingNodes.last else {return}
        DispatchQueue.main.async(execute: {
            if self.drawButton.isHighlighted {
                let vertice = self.worldPositionForScreenCenter()
                currentDrawing.addVertice(vertice)
            }
        })
    }
    
    //image inserting
    @objc func tapImageButton(sender: UIButton!) {
        print("image inserting")
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        let actionSheet = UIAlertController()
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action:UIAlertAction) in
            imagePickerController.sourceType = UIImagePickerControllerSourceType.camera
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose from Photo Library", style: .default, handler: { (action:UIAlertAction) in
            imagePickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            print("convert to image success")
            
            let box = SCNBox(width: image.size.width / 40000, height: image.size.height / 40000, length: 0.0001, chamferRadius: 0.000)
            let imageMaterial = SCNMaterial()
            imageMaterial.isDoubleSided = false
            imageMaterial.diffuse.contents = image
            box.materials = [imageMaterial]
            
            let boxNode = SCNNode(geometry: box)
            //boxNode.rotation = SCNVector4(Double.pi / 2 , 1, 0, 0)
            boxNode.position = getPointerPosition().pos
            sceneView.scene.rootNode.addChildNode(boxNode)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func getPointerPosition() -> (pos : SCNVector3, valid: Bool, camPos : SCNVector3 ) {
        
        guard let pointOfView = sceneView.pointOfView else { return (SCNVector3Zero, false, SCNVector3Zero) }
        
        // Transform Matrix
        let transform = pointOfView.transform
        let cameraOrientation = SCNVector3(-0.02 * transform.m31, -0.02 * transform.m32, -0.02 * transform.m33)
        let cameraLocation = SCNVector3(transform.m41, transform.m42, transform.m43)
        let cameraCurrentPosition = cameraOrientation + cameraLocation
        
        return (cameraCurrentPosition, true, cameraOrientation)
        
    }
    
    
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    func showText(text:String) -> Void{
        let textScn = ARText(text: text, font: UIFont .systemFont(ofSize: CGFloat(defaults.float(forKey: "textFont"))), color: defaults.colorForKey(key: "textColor")!, depth: CGFloat(defaults.float(forKey: "textFont"))/12)
        let textNode = TextNode(distance: defaults.float(forKey: "textDistance")/20, scntext: textScn, sceneView: self.sceneView, scale: 1/100.0)
        self.sceneView.scene.rootNode.addChildNode(textNode)
    }
    

    func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness : CGFloat = CGFloat(arc4random() & 128) / 256 + 0.5
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
}
