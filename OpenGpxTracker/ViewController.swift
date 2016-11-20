//
//  ViewController.swift
//  OpenGpxTracker
//
//  Created by merlos on 13/09/14.
//  Copyright (c) 2014 TransitBox. All rights reserved.
//

import UIKit

import CoreLocation
import MapKit

//Button colors
let kPurpleButtonBackgroundColor: UIColor =  UIColor(red: 146.0/255.0, green: 166.0/255.0, blue: 218.0/255.0, alpha: 0.90)
let kGreenButtonBackgroundColor: UIColor = UIColor(red: 142.0/255.0, green: 224.0/255.0, blue: 102.0/255.0, alpha: 0.90)
let kRedButtonBackgroundColor: UIColor =  UIColor(red: 244.0/255.0, green: 94.0/255.0, blue: 94.0/255.0, alpha: 0.90)
let kBlueButtonBackgroundColor: UIColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 0.90)
let kDisabledBlueButtonBackgroundColor: UIColor = UIColor(red: 74.0/255.0, green: 144.0/255.0, blue: 226.0/255.0, alpha: 0.10)
let kDisabledRedButtonBackgroundColor: UIColor =  UIColor(red: 244.0/255.0, green: 94.0/255.0, blue: 94.0/255.0, alpha: 0.10)
let kWhiteBackgroundColor: UIColor = UIColor(red: 254.0/255.0, green: 254.0/255.0, blue: 254.0/255.0, alpha: 0.90)

//Accesory View buttons tags
let kDeleteWaypointAccesoryButtonTag = 666
let kEditWaypointAccesoryButtonTag = 333

//AlertViews tags
let kEditWaypointAlertViewTag = 33
let kSaveSessionAlertViewTag = 88

let kButtonSmallSize: CGFloat = 48.0
let kButtonLargeSize: CGFloat = 96.0
let kButtonSeparation: CGFloat = 6.0

// Upper limits threshold (in meters) on signal accuracy.
let kSignalAccuracy6 = 6.0
let kSignalAccuracy5 = 11.0
let kSignalAccuracy4 = 31.0
let kSignalAccuracy3 = 51.0
let kSignalAccuracy2 = 101.0
let kSignalAccuracy1 = 201.0


class ViewController: UIViewController, UIGestureRecognizerDelegate  {
    
    var followUser: Bool = true {
        didSet {
            if followUser {
                print("followUser=true")
                followUserButton.setImage(UIImage(named: "follow_user_high"), for: UIControlState())
                map.setCenter((map.userLocation.coordinate), animated: true)
                
            } else {
                print("followUser=false")
                followUserButton.setImage(UIImage(named: "follow_user"), for: UIControlState())
            }
            
        }
    }
    var followUserBeforePinchGesture = true
    
    
    //MapView
    let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestAlwaysAuthorization()
        
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
        manager.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9.0, *) {
            manager.allowsBackgroundLocationUpdates = true
        }
        return manager
    }()
    
    var map: GPXMapView
    let mapViewDelegate = MapViewDelegate()
    
    //Status Vars
    var stopWatch = StopWatch()
    var lastGpxFilename: String = ""
    
    var hasWaypoints: Bool = false { // Was any waypoint added to the map?
        didSet {
            if hasWaypoints {
                resetButton.backgroundColor = kRedButtonBackgroundColor
            }
        }
    }
    
    enum GpxTrackingStatus {
        case notStarted
        case tracking
        case paused
    }
    var gpxTrackingStatus: GpxTrackingStatus = GpxTrackingStatus.notStarted {
        didSet {
            print("gpxTrackingStatus changed to \(gpxTrackingStatus)")
            switch gpxTrackingStatus {
            case .notStarted:
                print("switched to non started")
                // set Tracker button to allow Start
                trackerButton.setTitle("Start Tracking", for: UIControlState())
                trackerButton.backgroundColor = kGreenButtonBackgroundColor
                //save & reset button to transparent.
                resetButton.backgroundColor = kDisabledRedButtonBackgroundColor
                //reset clock
                stopWatch.reset()
                timeLabel.text = stopWatch.elapsedTimeString
                
                map.clearMap() //clear map
                lastGpxFilename = "" //clear last filename, so when saving it appears an empty field
                
                totalTrackedDistanceLabel.distance = (map.totalTrackedDistance)
                
                /*
                 // XXX Left here for reference
                 UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                 self.trackerButton.hidden = true
                 self.pauseButton.hidden = false
                 }, completion: {(f: Bool) -> Void in
                 println("finished animation start tracking")
                 })
                 */
                
            case .tracking:
                print("switched to tracking mode")
                // set tracerkButton to allow Pause
                trackerButton.setTitle("Pause", for: UIControlState())
                trackerButton.backgroundColor = kPurpleButtonBackgroundColor
                //activate save & reset buttons
                resetButton.backgroundColor = kRedButtonBackgroundColor
                // start clock
                self.stopWatch.start()
                
            case .paused:
                print("switched to paused mode")
                // set trackerButton to allow Resume
                self.trackerButton.setTitle("Resume", for: UIControlState())
                self.trackerButton.backgroundColor = kGreenButtonBackgroundColor
                // activate save & reset (just in case switched from .NotStarted)
                resetButton.backgroundColor = kRedButtonBackgroundColor
                //pause clock
                self.stopWatch.stop()
                // start new track segment
                self.map.startNewTrackSegment()
            }
        }
    }
    
    //Editing Waypoint Temporal Reference
    var lastLocation: CLLocation? //Last point of current segment.
    
    
    //UI
    //labels
    //var appTitleBackgroundView: UIView
   
    var timeLabel: UILabel
    var speedLabel: UILabel
    var totalTrackedDistanceLabel: UIDistanceLabel
    var remainDistanceLabel: UILabel
    
    
    
    //buttons
    var followUserButton: UIButton
    var newPinButton: UIButton
    var folderButton: UIButton
    var aboutButton: UIButton
    var preferencesButton: UIButton
    var resetButton: UIButton
    var trackerButton: UIButton
    
    // Initializer. Just initializes the class vars/const
    required init(coder aDecoder: NSCoder) {
        self.map = GPXMapView(coder: aDecoder)!
        self.timeLabel = UILabel(coder: aDecoder)!
        self.speedLabel = UILabel(coder: aDecoder)!
        self.totalTrackedDistanceLabel = UIDistanceLabel(coder: aDecoder)!
        self.remainDistanceLabel = UIDistanceLabel(coder: aDecoder)!
        self.followUserButton = UIButton(coder: aDecoder)!
        self.newPinButton = UIButton(coder: aDecoder)!
        self.folderButton = UIButton(coder: aDecoder)!
        self.resetButton = UIButton(coder: aDecoder)!
        self.aboutButton = UIButton(coder: aDecoder)!
        self.preferencesButton = UIButton(coder: aDecoder)!
        
        self.trackerButton = UIButton(coder: aDecoder)!
        
        super.init(coder: aDecoder)!
        followUser = true
    }
    
    deinit {
        removeNotificationObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stopWatch.delegate = self
        
        // Map configuration Stuff
        map.delegate = mapViewDelegate
        
        map.showsUserLocation = true
        let mapH: CGFloat = self.view.bounds.size.height - 20.0
        map.frame = CGRect(x: 0.0, y: 20.0, width: self.view.bounds.size.width, height: mapH)
        map.isZoomEnabled = true
        map.isRotateEnabled = true
        map.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(ViewController.addPinAtTappedLocation(_:)))
        )
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(ViewController.stopFollowingUser(_:)))
        panGesture.delegate = self
        map.addGestureRecognizer(panGesture)
        
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
        //let pinchGesture = UIPinchGestureRecognizer(target: self, action: "pinchGesture")
        //map.addGestureRecognizer(pinchGesture)
        
        //Preferences load
        let defaults = UserDefaults.standard
       
        
        
        // set default zoom
        let center = locationManager.location?.coordinate ?? CLLocationCoordinate2D(latitude: 8.90, longitude: -79.50)
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: center, span: span)
        map.setRegion(region, animated: true)
        self.view.addSubview(map)
        
        // HEADER
        let font36 = UIFont(name: "DinCondensed-Bold", size: 36.0)
        let font18 = UIFont(name: "DinAlternate-Bold", size: 18.0)
        let font12 = UIFont(name: "DinAlternate-Bold", size: 12.0)
        
        
        
        
        
        
        // Tracked info
        
        //timeLabel
        timeLabel.frame = CGRect(x: self.map.frame.width - 160, y: 20, width: 150, height: 40)
        timeLabel.textAlignment = .right
        timeLabel.font = font36
        timeLabel.text = "00:00"
        //timeLabel.shadowColor = UIColor.whiteColor()
        //timeLabel.shadowOffset = CGSize(width: 1, height: 1)
        //timeLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        map.addSubview(timeLabel)
        
        //speed Label
        speedLabel.frame = CGRect(x: self.map.frame.width - 160,  y: 20 + 36, width: 150, height: 20)
        speedLabel.textAlignment = .right
        speedLabel.font = font18
        speedLabel.text = "0.00 km/h"
        //timeLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        map.addSubview(speedLabel)
        
        //tracked distance
        totalTrackedDistanceLabel.frame = CGRect(x: self.map.frame.width - 160, y: 60 + 20, width: 150, height: 40)
        totalTrackedDistanceLabel.textAlignment = .right
        totalTrackedDistanceLabel.font = font36
        totalTrackedDistanceLabel.text = "0m"
        //timeLabel.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        map.addSubview(totalTrackedDistanceLabel)
        
        //Remain Destance
        remainDistanceLabel.frame = CGRect(x: self.map.frame.width - 160, y: 80 + 20, width: 150, height: 40)
        remainDistanceLabel.textAlignment = .right
        remainDistanceLabel.font = font36
        remainDistanceLabel.text = "0m"
        map.addSubview(remainDistanceLabel)
        
        
        //
        // Button Bar
        //
        // [ Small ] [ Small ] [ Large     ] [Small] [ Small]
        //                     [ (tracker) ]
        //
        //                     [ track     ]
        // [ follow] [ +Pin  ] [ Pause     ] [ Save ] [ Reset]
        //                     [ Resume    ]
        //
        //                       trackerX
        //                         |
        //                         |
        // [-----------------------|--------------------------]
        //                  map.frame/2 (center)
        
        let yCenterForButtons: CGFloat = map.frame.height - kButtonLargeSize/2 - 5
        //center Y of start
       
        // Start
        let trackerW: CGFloat = kButtonLargeSize
        let trackerH: CGFloat = kButtonLargeSize
        let trackerX: CGFloat = self.map.frame.width/2 - 0.0 // Center of start
        let trackerY: CGFloat = yCenterForButtons
        trackerButton.frame = CGRect(x: 0, y:0, width: trackerW, height: trackerH)
        trackerButton.center = CGPoint(x: trackerX, y: trackerY)
        trackerButton.layer.cornerRadius = trackerW/2
        trackerButton.setTitle("Start Tracking", for: UIControlState())
        trackerButton.backgroundColor = kGreenButtonBackgroundColor
        trackerButton.addTarget(self, action: #selector(ViewController.trackerButtonTapped), for: .touchUpInside)
        trackerButton.isHidden = false
        trackerButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        trackerButton.titleLabel?.numberOfLines = 2
        trackerButton.titleLabel?.textAlignment = .center
        map.addSubview(trackerButton)
        
        
        // Follow user button
        let followW: CGFloat = kButtonSmallSize
        let followH: CGFloat = kButtonSmallSize
        let followY: CGFloat = yCenterForButtons
        followUserButton.frame = CGRect(x: 0, y: 0, width: followW, height: followH)
        followUserButton.layer.cornerRadius = followW/2
        followUserButton.backgroundColor = kWhiteBackgroundColor
        //follow_user_high represents the user is being followed. Default status when app starts
        followUserButton.setImage(UIImage(named: "follow_user_high"), for: UIControlState())
        followUserButton.setImage(UIImage(named: "follow_user_high"), for: .highlighted)
        followUserButton.addTarget(self, action: #selector(ViewController.followButtonTroggler), for: .touchUpInside)
        map.addSubview(followUserButton)
        
        
        
        // Reset button
        let resetW: CGFloat = kButtonSmallSize
        let resetH: CGFloat = kButtonSmallSize
        let resetY: CGFloat = yCenterForButtons
        resetButton.frame = CGRect(x: 0, y: 0, width: resetW, height: resetH)
        resetButton.center = CGPoint(x: resetW, y: resetY)
        resetButton.layer.cornerRadius = resetW/2
        resetButton.setTitle("Reset", for: UIControlState())
        resetButton.backgroundColor = kDisabledRedButtonBackgroundColor
        resetButton.addTarget(self, action: #selector(ViewController.resetButtonTapped), for: .touchUpInside)
        resetButton.isHidden = false
        resetButton.titleLabel?.textAlignment = .center
        map.addSubview(resetButton)
        
        addNotificationObservers()
    }
    
    func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.didEnterBackground),
                                               name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notifications
    
    func didEnterBackground() {
        if gpxTrackingStatus != .tracking {
            locationManager.stopUpdatingLocation()
        }
    }
    
    
    
    
    
    func stopFollowingUser(_ gesture: UIPanGestureRecognizer) {
        if self.followUser {
            self.followUser = false
        }
    }
    
    
    // UIGestureRecognizerDelegate required for stopFollowingUser
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func addPinAtTappedLocation(_ gesture: UILongPressGestureRecognizer) {
        if  gesture.state == UIGestureRecognizerState.began {
            print("Adding Pin map Long Press Gesture")
            let point: CGPoint = gesture.location(in: self.map)
            map.addWaypointAtViewPoint(point)
            //Allows save and reset
            self.hasWaypoints = true
            
        }
    }
    
    // zoom gesture controls that follow user to
    func pinchGesture(_ gesture: UIPinchGestureRecognizer) {
        print("pinchGesture")
        /*   if gesture.state == UIGestureRecognizerState.Began {
         self.followUserBeforePinchGesture = self.followUser
         self.followUser = false
         }
         //return to back
         if gesture.state == UIGestureRecognizerState.Ended {
         self.followUser = self.followUserBeforePinchGesture
         }
         */
    }
    
    func addPinAtMyLocation() {
        print("Adding Pin at my location")
        let waypoint = GPXWaypoint(coordinate: map.userLocation.coordinate)
        map.addWaypoint(waypoint)
        self.hasWaypoints = true
    }
    
    
    func followButtonTroggler() {
        self.followUser = !self.followUser
    }
    
    
    func resetButtonTapped() {
        //clear tracks, pins and overlays if not already in that status
        if self.gpxTrackingStatus != .notStarted {
            self.gpxTrackingStatus = .notStarted
        }
    }
    
    ////////////////////////////
    // TRACKING USER
    
    func trackerButtonTapped() {
        print("startGpxTracking::")
        switch gpxTrackingStatus {
        case .notStarted:
            gpxTrackingStatus = .tracking
        case .tracking:
            gpxTrackingStatus = .paused
        case .paused:
            //set to tracking
            gpxTrackingStatus = .tracking
        }
    }
    
    func saveButtonTapped() {
        print("save Button tapped")
        // ignore the save button if there is nothing to save.
        if (gpxTrackingStatus == .notStarted) && !self.hasWaypoints {
            return
        }
        
        let alert = UIAlertView(title: "Save as", message: "Enter GPX session name", delegate: self, cancelButtonTitle: "Continue tracking")
        
        alert.addButton(withTitle: "Save")
        alert.alertViewStyle = .plainTextInput
        alert.tag = kSaveSessionAlertViewTag
        alert.show()
        alert.textField(at: 0)?.text = lastGpxFilename
        //alert.textFieldAtIndex(0)?.selectAll(self)
    }
    
    override func didReceiveMemoryWarning() {
        print("didReceiveMemoryWarning");
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: UIAlertViewDelegate

extension ViewController: UIAlertViewDelegate {
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        
        switch alertView.tag {
        case kSaveSessionAlertViewTag:
            
            print("alertViewDelegate for Save Session")
            
            switch buttonIndex {
            case 0: //cancel
                print("Save canceled")
                
            case 1: //Save
                let filename = (alertView.textField(at: 0)?.text!.utf16.count == 0) ? " " : alertView.textField(at: 0)?.text
                print("Save File \(filename)")
                //export to a file
                let gpxString = self.map.exportToGPXString()
                GPXFileManager.save(filename!, gpxContents: gpxString)
                self.lastGpxFilename = filename!
                
            default:
                print("[ERROR] it seems there are more than two buttons on the alertview.")
                
        } //buttonIndex
        default:
            print("[ERROR] it seems that the AlertView is not handled properly." )
            
        }
    }
}

// MARK: StopWatchDelegate

extension ViewController: StopWatchDelegate {
    func stopWatch(_ stropWatch: StopWatch, didUpdateElapsedTimeString elapsedTimeString: String) {
        timeLabel.text = elapsedTimeString
    }
}

// MARK: PreferencesTableViewControllerDelegate

// MARK: location manager Delegate

// MARK: CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("didFailWithError\(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //updates signal image accuracy
        let newLocation = locations.first!
        //print("didUpdateLocation: received \(newLocation.coordinate) hAcc: \(newLocation.horizontalAccuracy)")
        let hAcc = newLocation.horizontalAccuracy
        
        
        //Update speed (provided in m/s, but displayed in km/h)
        var speedFormat: String
        if newLocation.speed < 0 {
            speedFormat = "?.??"
        } else {
            speedFormat = String(format: "%.2f", (newLocation.speed * 3.6))
        }
        speedLabel.text = "\(speedFormat) km/h"
        
        //Update Map center and track overlay if user is being followed
        if followUser {
            map.setCenter(newLocation.coordinate, animated: true)
        }
        if gpxTrackingStatus == .tracking {
            print("didUpdateLocation: adding point to track \(newLocation.coordinate)")
            map.addPointToCurrentTrackSegmentAtLocation(newLocation)
            totalTrackedDistanceLabel.distance = map.totalTrackedDistance
        }
        
    }
    
}
