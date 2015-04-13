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

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Trash,
            target: self,
            action: "emptyCache")

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Organize,
            target: self,
            action: "promptDownload")
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        RMConfiguration.sharedInstance().accessToken =
            "pk.eyJ1IjoianVzdGluIiwiYSI6IlpDbUJLSUEifQ.4mG8vhelFMju6HpIY-Hi5A"

        // configure map tile source based on previous metadata if available
        var tileSource: RMMapboxSource?
        if (NSUserDefaults.standardUserDefaults().objectForKey("tileJSON") != nil) {
            tileSource = RMMapboxSource(tileJSON:
                NSUserDefaults.standardUserDefaults().objectForKey("tileJSON")! as! String)
        } else {
            tileSource = RMMapboxSource(mapID: "mapbox.streets")
        }

        // only proceed if either pre-cached or online
        if (tileSource == nil) {
            UIAlertView(title: "Must Start Online",
                message: "This app requires a first run while online.",
                delegate: nil,
                cancelButtonTitle: "OK").show()
        } else {
            map = RMMapView(frame: view.bounds, andTilesource: tileSource!)
            map.autoresizingMask = .FlexibleWidth | .FlexibleHeight
            map.setZoom(13, atCoordinate: map.centerCoordinate, animated: false)
            map.maxZoom = Float(maxDownloadZoom)

            // never expire tiles
            map.tileCache = RMTileCache(expiryPeriod: 0)

            // store TileJSON for tile source if not already
            if (NSUserDefaults.standardUserDefaults().objectForKey("tileJSON") == nil) {
                let tileJSON = (map.tileSource as! RMMapboxSource).tileJSON
                NSUserDefaults.standardUserDefaults().setObject(tileJSON, forKey: "tileJSON")
            }

            view.addSubview(map)
        }
    }

    // MARK: - Actions

    func emptyCache() {
        map.removeAllCachedImages()
        UIAlertView(title: "Offline Cache Cleared",
            message: "The offline map tile cache was cleared.",
            delegate: nil,
            cancelButtonTitle: "OK").show()
        map.reloadTileSource(map.tileSource)
    }

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
                message += " Caching may take a long time. It is recommended"
                message += " that you connect to Wi-Fi and plug in the device."
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
