import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    testCZDispatchQueue()
  }
  
  func testCZDispatchQueue() {
    CZDispatchQueueTests().test()
  }
}

