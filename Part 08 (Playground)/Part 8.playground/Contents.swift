import UIKit
import MetalKit
import PlaygroundSupport

class MyViewController : UIViewController {
    override func loadView() {
        let device = MTLCreateSystemDefaultDevice()
        let metalView = MetalMTKView(frame: .zero, device: device)
        
        self.view = metalView
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
