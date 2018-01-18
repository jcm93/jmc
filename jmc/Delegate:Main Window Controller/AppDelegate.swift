
//
//  AppDelegate.swift
//  minimalTunes
//
//  Created by John Moody on 5/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    var mainWindowController: MainWindowController?
    var databaseManager: DatabaseManager?
    var preferencesWindowController: PreferencesWindowController?
    var setupWindowController: InitialSetupWindowController?
    var equalizerWindowController: EqualizerWindowController?
    var importWindowController: ImportWindowController?
    var iTunesParser: iTunesLibraryParser?
    var locationManager: LocationManager?
    var audioModule: AudioModule = AudioModule()
    let fileHandler = FileManager.default
    var serviceBrowser: ConnectivityManager?
    var importErrorWindowController: ImportErrorWindowController?
    var backgroundAddFilesHandler: GenericProgressBarSheetController?
    var addFilesQueueLoop: AddFilesQueueLoop?
    var lastFMDelegate: LastFMDelegate?
    var mediaKeyListener: MediaKeyListener?
    @IBOutlet var menuDelegate: MainMenuDelegate!
    
    
    func presentSevereErrors(_ errors: [Error]) {
        //todo check docs for how to show mult. errors
        for error in errors {
            let alertModal = NSAlert(error: error)
        }
    }
    
    
    func initializeLibraryAndShowMainWindow() {
        mainWindowController = MainWindowController(windowNibName: NSNib.Name(rawValue: "MainWindowController"))
        mainWindowController?.delegate = self
        mainWindowController?.showWindow(self)
        //self.serviceBrowser = ConnectivityManager(delegate: self, slvc: mainWindowController!.sourceListViewController!)
        let defaultsEQOnState = UserDefaults.standard.integer(forKey: DEFAULTS_IS_EQ_ENABLED_STRING)
        audioModule.toggleEqualizer(defaultsEQOnState)
    }
    
    func launchAddFilesDialog() {
        print("launch add files called")
        self.backgroundAddFilesHandler = GenericProgressBarSheetController(windowNibName: NSNib.Name(rawValue: "GenericProgressBarSheetController"))
        self.mainWindowController?.window?.addChildWindow(self.backgroundAddFilesHandler!.window!, ordered: .above)
        //self.backgroundAddFilesHandler?.window?.level = Int(CGWindowLevelForKey(CGWindowLevelKey.floatingWindow))
    }
    
    func reinitializeInterfaceForRemovedSource() {
        mainWindowController?.sourceListViewController?.server = nil
        self.serviceBrowser = nil
        mainWindowController?.window?.close()
        audioModule.resetEngineCompletely()
        initializeLibraryAndShowMainWindow()
        //source was removed
        
    }
    
    func doneImportingiTunesLibrary() {
        mainWindowController?.sourceListViewController?.reloadData()
        self.iTunesParser = nil
    }
    
    @IBAction func addToLibrary(_ sender: AnyObject) {
        openFiles()
    }
    
    func openFiles() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = VALID_FILE_TYPES
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        let modalResponse = panel.runModal()
        if modalResponse.rawValue == NSFileHandlingPanelOKButton {
            let urls = self.databaseManager?.getMediaURLsInDirectoryURLs(panel.urls).0
            //self.launchAddFilesDialog()
            self.addFilesQueueLoop?.addChunksToQueue(urls: urls!)
            self.addFilesQueueLoop?.start()
        }
        
    }
    
    func alertForErrors(_ errors: [Error]) {
        //stub
    }
    
    func showImportErrors(_ errors: [FileAddToDatabaseError]) {
        if errors.count > 0 {
            self.importErrorWindowController = ImportErrorWindowController(windowNibName: NSNib.Name(rawValue: "ImportErrorWindowController"))
            self.importErrorWindowController?.errors = errors
            self.importErrorWindowController?.showWindow(self)
        }
    }
    
    func addURLsToLibrary(_ urls: [URL], library: Library) -> [FileAddToDatabaseError] {
        let result = databaseManager?.addTracksFromURLs(urls, visualUpdateHandler: nil, callback: nil)
        return result!
    }

    @IBAction func openPreferences(_ sender: AnyObject) {
        preferencesWindowController = PreferencesWindowController(windowNibName: NSNib.Name(rawValue: "PreferencesWindowController"))
        preferencesWindowController?.showWindow(self)
    }

    @IBAction func showAdvancedFilter(_ sender: AnyObject) {
        if let item = sender as? NSMenuItem {
            item.state = item.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        }
        mainWindowController?.advancedFilterButtonPressed(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        managedObjectContext.perform {
            for fetchRequest in BATCH_PURGE_NETWORK_FETCH_REQUESTS {
                do {
                    fetchRequest.predicate = IS_NETWORK_PREDICATE
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    try self.persistentStoreCoordinator.execute(deleteRequest, with: self.managedObjectContext)
                } catch {
                    print(error)
                }
            }
            purgeCurrentlyPlaying()
        }
        if !UserDefaults.standard.bool(forKey: DEFAULTS_ARE_INITIALIZED_STRING) {
            self.setupWindowController = InitialSetupWindowController(windowNibName: NSNib.Name(rawValue: "InitialSetupWindowController"))
            mainQueueChildContext.performAndWait {
                self.setupWindowController!.setupForNilLibrary()
                do {
                    try mainQueueChildContext.save()
                } catch {
                    print(error)
                }
                privateQueueParentContext.performAndWait {
                    do {
                        try privateQueueParentContext.save()
                    } catch {
                        print(error)
                    }
                    self.databaseManager = DatabaseManager(context: privateQueueParentContext)
                }
                privateQueueParentContext.performAndWait {
                    self.locationManager = LocationManager(delegate: self)
                    self.addFilesQueueLoop = AddFilesQueueLoop(delegate: self)
                    self.locationManager?.initializeEventStream()
                    self.lastFMDelegate = LastFMDelegate()
                }
            }
        } else {
            privateQueueParentContext.performAndWait {
                self.locationManager = LocationManager(delegate: self)
                self.addFilesQueueLoop = AddFilesQueueLoop(delegate: self)
                self.locationManager?.initializeEventStream()
                self.lastFMDelegate = LastFMDelegate()
            }
        }
        // Insert code here to initialize your application
        let dumbTransform = TransformerURLStringToURL()
        ValueTransformer.setValueTransformer(dumbTransform, forName: NSValueTransformerName("TransformURLStringToURL"))
        let fuckTransform = TransformerIntegerToTimestamp()
        ValueTransformer.setValueTransformer(fuckTransform, forName: NSValueTransformerName("AssTransform"))
        initializeLibraryAndShowMainWindow()
        if UserDefaults.standard.bool(forKey: DEFAULTS_ARE_INITIALIZED_STRING) != true {
            print("has not started before")
            mainWindowController?.window?.beginSheet(setupWindowController!.window!, completionHandler: nil)
        }
        //NotificationCenter.default.addObserver(self, selector: #selector(managedObjectsDidChangeDebug), name: Notification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext)
        self.managedObjectContext.perform {
            NotificationCenter.default.addObserver(self, selector: #selector(self.managedObjectsDidUndo), name: Notification.Name.NSUndoManagerDidUndoChange, object: self.managedObjectContext.undoManager)
        }
        self.mediaKeyListener = MediaKeyListener(self)
        self.menuDelegate.delegate = self
        self.menuDelegate.mainWindowController = self.mainWindowController
    }
    
    @objc func managedObjectsDidUndo() {
        print("managed objects did undo")
        self.mainWindowController?.trackQueueViewController?.refreshForChangedData()
        self.mainWindowController?.currentTableViewController?.trackViewArrayController.rearrangeObjects()
    }
    
    func managedObjectsDidChangeDebug(_ notification: Notification) {
        let userInfo = notification.userInfo!
        if let updated = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updated.count > 0 {
            print("UPDATED")
            for object in updated {
                print(object.objectSpecifier)
                print(object.changedValuesForCurrentEvent())
            }
            print("-------")
        }
        if let inserted = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserted.count > 0 {
            print("INSERTED")
            for object in inserted {
                print(object.objectSpecifier)
                print(object.changedValuesForCurrentEvent())
            }
            print("-------")
        }
        if let deleted = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject>, deleted.count > 0 {
            print("DELETED")
            for object in deleted {
                print(object.objectSpecifier)
                print(object.changedValuesForCurrentEvent())
            }
            print("-------")
        }
        print("DONE")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        do {
            try mainQueueChildContext.save()
        } catch {
            print(error)
        }
        privateQueueParentContext.performAndWait {
            do {
                try privateQueueParentContext.save()
            } catch {
                print(error)
            }
        }
    }
    
    func showMainWindow() {
        mainWindowController = MainWindowController(windowNibName: NSNib.Name(rawValue: "MainWindowController"))
        mainWindowController!.showWindow(self)
    }
    
    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        self.launchAddFilesDialog()
        privateQueueParentContext.perform {
            self.databaseManager!.addTracksFromURLs(filenames.map({return URL(fileURLWithPath: $0)}), visualUpdateHandler: self.backgroundAddFilesHandler, callback: nil)
        }
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "jcm.minimalTunes" in the user's Application Support directory.
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.appendingPathComponent("jcm.jmc")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "jmc", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = FileManager.default
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try (self.applicationDocumentsDirectory as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
            if !(properties[URLResourceKey.isDirectoryKey]! as AnyObject).boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
                
            }
        }
    
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.appendingPathComponent("jmc.db")
            do {
                var options = [AnyHashable : Any]()
                options[NSMigratePersistentStoresAutomaticallyOption] = true
                options[NSInferMappingModelAutomaticallyOption] = true
                options[NSSQLitePragmasOption] = ["journal_mode" : "DELETE"]
                try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            } catch {
                failError = error as NSError
            }
        }
        
        if shouldFail || (failError != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.shared.presentError(error)
            abort()
        } else {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        //managedObjectContext.undoManager = UndoManager()
        return managedObjectContext
        
    }()
    
    lazy var childContext: NSManagedObjectContext = {
        var context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = self.managedObjectContext
        return context
    }()
    

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }
    
    func undo(_ sender: Any) {
        managedObjectContext.undoManager?.undo()
        mainWindowController?.currentTableViewController?.trackViewArrayController.fetch(nil)
    }
    
    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.l
        var returnValueFromBlock: NSApplication.TerminateReply = .terminateNow
        managedObjectContext.performAndWait {
            for fetchRequest in BATCH_PURGE_NETWORK_FETCH_REQUESTS {
                do {
                    fetchRequest.predicate = IS_NETWORK_PREDICATE
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    try self.persistentStoreCoordinator.execute(deleteRequest, with: self.managedObjectContext)
                } catch {
                    print(error)
                }
            }
            purgeCurrentlyPlaying()
            //mainWindowController.cachePlayOrderObject()
            if !managedObjectContext.commitEditing() {
                NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
                returnValueFromBlock = .terminateCancel
                return
            }
            
            if !managedObjectContext.hasChanges {
                returnValueFromBlock = .terminateNow
                return
            }
            
            do {
                self.databaseManager!.saveAndCommit(errorHandler: nil)
            } catch {
                let nserror = error as NSError
                // Customize this code block to include application-specific recovery steps.
                let result = sender.presentError(nserror)
                if (result) {
                    returnValueFromBlock = .terminateCancel
                }
                let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
                let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
                let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
                let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
                let alert = NSAlert()
                alert.messageText = question
                alert.informativeText = info
                alert.addButton(withTitle: quitButton)
                alert.addButton(withTitle: cancelButton)
                
                let answer = alert.runModal()
                if answer == NSApplication.ModalResponse.alertFirstButtonReturn {
                    returnValueFromBlock = .terminateCancel
                    return
                }
            }
        }
        // If we got here, it is time to quit.
        return returnValueFromBlock
    }

}

