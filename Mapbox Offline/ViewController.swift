import UIKit
import Mapbox_iOS_SDK

class ViewController: UIViewController {

    var map: RMMapView!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        RMConfiguration.sharedInstance().accessToken =
            "pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"
        map = RMMapView(frame: view.bounds,
            andTilesource: RMMapboxSource(mapID: "mapbox.streets"))
        map.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        map.setZoom(10, atCoordinate: map.centerCoordinate, animated: false)
        view.addSubview(map)
    }

}
