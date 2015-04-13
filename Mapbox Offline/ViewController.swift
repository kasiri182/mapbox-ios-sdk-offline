import UIKit
import MBProgressHUD
import Mapbox_iOS_SDK

class ViewController: UIViewController, UIAlertViewDelegate, RMTileCacheBackgroundDelegate {

    var map: RMMapView!
    let maxDownloadZoom: UInt = 17

    // MARK: - Setup

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Mapbox Offline"

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Organize,
            target: self,
            action: "promptDownload")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        RMConfiguration.sharedInstance().accessToken =
            "pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"

        map = RMMapView(frame: view.bounds,
            andTilesource: RMMapboxSource(mapID: "mapbox.streets"))
        map.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        map.setZoom(13, atCoordinate: map.centerCoordinate, animated: false)

        // never expire tiles
        map.tileCache = RMTileCache(expiryPeriod: 0)

        view.addSubview(map)
    }

    // MARK: - Actions

    func promptDownload() {
        let tileCount = map.tileCache.tileCountForSouthWest(map.latitudeLongitudeBoundingBox().southWest,
            northEast: map.latitudeLongitudeBoundingBox().northEast,
            minZoom: UInt(map.zoom),
            maxZoom: maxDownloadZoom)

        let message: String = {
            let formatter = NSNumberFormatter()
            formatter.usesGroupingSeparator = true
            formatter.groupingSeparator = ","
            var message = "Download \(formatter.stringFromNumber(tileCount)!) map tiles now?"
            if (tileCount > 1000) {
                message += " This may take a long time. It is recommended that you connect to Wi-Fi and plug in the device."
            }
            return message
            }()

        UIAlertView(title: "Download?",
            message: message,
            delegate: self,
            cancelButtonTitle: "Cancel",
            otherButtonTitles: "Download").show()
    }

    // MARK: - Alert View

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 1) {
            map.removeAllCachedImages()

            let hud = MBProgressHUD(view: self.navigationController!.view)
            hud.mode = .DeterminateHorizontalBar
            hud.minShowTime = 1
            self.navigationController!.view.addSubview(hud)
            hud.show(true)

            map.tileCache.backgroundCacheDelegate = self
            map.tileCache.beginBackgroundCacheForTileSource(map.tileSource,
                southWest: map.latitudeLongitudeBoundingBox().southWest,
                northEast: map.latitudeLongitudeBoundingBox().northEast,
                minZoom: UInt(map.zoom),
                maxZoom: maxDownloadZoom)
        }
    }

    // MARK: - Cache Delegate

    func tileCache(tileCache: RMTileCache!, didBackgroundCacheTile tile: RMTile, withIndex tileIndex: UInt, ofTotalTileCount totalTileCount: UInt) {
        MBProgressHUD(forView: self.navigationController!.view).progress = Float(tileIndex) / Float(totalTileCount)
    }

    func tileCacheDidFinishBackgroundCache(tileCache: RMTileCache!) {
        MBProgressHUD(forView: self.navigationController!.view).hide(true)
        MBProgressHUD(forView: self.navigationController!.view).removeFromSuperview()
    }

}
