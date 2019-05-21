//
//  CertainGlobalFunctions.swift
//  minimalTunes
//
//  Created by John Moody on 7/9/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

//houses functions for editing tags, re-cacheing sorts

import Cocoa
import CoreData
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
/*fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}*/

func resolve(_ object: NSManagedObject, inBackground: Bool) -> NSManagedObject {
    return inBackground ? backgroundContext.object(with: object.objectID) : object
}


var managedContext = (NSApplication.shared.delegate as! AppDelegate).managedObjectContext
var backgroundContext = {() -> NSManagedObjectContext in
    let newContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
    newContext.parent = managedContext
    return newContext
}()

func saveContext() { //does not handle errors
    do {
        try managedContext.save()
    } catch {
        print(error)
    }
}

func informAppDelegateOfErrors(errors: [Error]) {
    guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
    delegate.alertForErrors(errors)
}


var globalRootLibrary: Library! = {() -> Library? in
    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
    let predicate = NSPredicate(format: "parent == nil")
    fetchReq.predicate = predicate
    do {
        let result = try managedContext.fetch(fetchReq)[0] as! Library
        return result
    } catch {
        return nil
    }
}()

var globalRootLibrarySourceListItem = {() -> SourceListItem? in
    print("creating global root library source list item")
    let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "SourceListItem")
    let predicate = NSPredicate(format: "library == %@", globalRootLibrary!)
    fetchReq.predicate = predicate
    do {
        let result = try managedContext.fetch(fetchReq)[0] as! SourceListItem
        return result
    } catch {
        return nil
    }
}()

func getLibrary(withName name: String) -> [Library]? {
    let request = NSFetchRequest<Library>(entityName: "Library")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request)
        return result
    } catch {
        print(error)
        return nil
    }
}

func getAllMiscellaneousAlbumFiles(for album: Album) -> [String] {
    var albumFiles = [String?]()
    albumFiles.append(album.primary_art?.location)
    if let otherArt = album.other_art {
        albumFiles.append(contentsOf: otherArt.map({return ($0 as! AlbumArtwork).location}))
    }
    if let otherFiles = album.other_files {
        albumFiles.append(contentsOf: otherFiles.map({return ($0 as! AlbumFile).location}))
    }
    return albumFiles.compactMap({return $0})
}



func purgeCurrentlyPlaying() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
    let predicate = NSPredicate(format: "is_playing == true")
    fetchRequest.predicate = predicate
    do {
        let results = try managedContext.fetch(fetchRequest) as! [Track]
        for result in results {
            result.is_playing = nil
        }
    } catch {
        print("error retrieving currently playing tracks: \(error)")
    }
}



//sample FLAC metadata dictionary

/*
 ENCODER=X Lossless Decoder 20141129
 TITLE=Eclectrocution
 ARTIST=Bill Fox
 ALBUM=I Stayed Up All Night Listening To Records
 GENRE=Indie Rock
 TRACKNUMBER=2
 TRACKTOTAL=25
 TOTALTRACKS=25
 DISCNUMBER=1
 DISCTOTAL=1
 TOTALDISCS=1
 DATE=1998
 COMPILATION=1
 iTunes_CDDB_1=75103619+311472+25+150+9731+23810+36286+50728+66415+81858+91382+107925+122484+146228+161584+166009+176768+187971+208201+215013+222961+225471+248084+257280+264597+276543+287590+301997
 REPLAYGAIN_TRACK_GAIN=-9.94 dB
 REPLAYGAIN_TRACK_PEAK=0.99163818

 */

func numberOfTracksInsideDirectory(with url: URL) -> Int {
    let absString = url.absoluteString
    return (globalRootLibrary!.tracks as! Set<Track>).filter({return ($0.location ?? "").localizedCaseInsensitiveContains(absString)}).count
}

var cachedOrders: [String : CachedOrder]? = {
    print("accessing cached orders")
    var result = [String : CachedOrder]()
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedOrder")
    do {
        let list = try managedContext.fetch(request) as! [CachedOrder]
        for order in list {
            result[order.order!] = order
            //order.mutableCachedOrder = order.track_views!.mutableCopy() as! NSMutableOrderedSet
        }
        return result
    } catch {
        print(error)
        return nil
    }
}()

func getCachedOrders(for context: NSManagedObjectContext) -> [String : CachedOrder]? {
    var result = [String : CachedOrder]()
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedOrder")
    do {
        let list = try context.fetch(request) as! [CachedOrder]
        for order in list {
            result[order.order!] = order
        }
        return result
    } catch {
        print(error)
        return nil
    }
}

func validateStringForFilename(_ string: String) -> String {
    let newString = String(string.map({
        $0 == "/" ? ":" : $0
    }))
    return newString
}

func volumeIsAvailable(volume: Volume) -> Bool {
    let fileManager = FileManager.default
    let libraryPath = URL(string: volume.location!)!.path
    var isDirectory = ObjCBool(booleanLiteral: false)
    return fileManager.fileExists(atPath: libraryPath, isDirectory: &isDirectory) && isDirectory.boolValue
}

func determineTemplateLocations(context: NSManagedObjectContext, visualUpdateHandler: ProgressBarController?) -> [NSObject : URL] {
    let library = context.object(with: globalRootLibrary!.objectID) as! Library
    let templateBundle = library.organization_template!
    let count = library.tracks!.count
    DispatchQueue.main.async {
        visualUpdateHandler?.prepareForNewTask(actionName: "Checking organization template for", thingName: "files", thingCount: count)
    }
    var index = 0
    var newFileLocations = [NSObject : URL]()
    let allAlbums = Set(library.tracks!.compactMap({return ($0 as? Track)?.album}))
    for album in allAlbums {
        newFileLocations.merge(templateBundle.match(wholeAlbum: album), uniquingKeysWith: {(first, second) -> URL in
            print("url conflict; this is bad");
            return first
        })
        index += album.tracks?.count ?? 0
        DispatchQueue.main.async {
            visualUpdateHandler?.increment(thingsDone: index)
        }
    }
    return newFileLocations
}

func getCurrentLocations(context: NSManagedObjectContext, visualUpdateHandler: ProgressBarController?) -> [NSObject : URL] {
    let library = context.object(with: globalRootLibrary!.objectID) as! Library
    var result = [NSObject : URL]()
    for track in library.tracks! {
        let track = track as! Track
        if let location = track.location, let url = URL(string: location) {
            result[track] = url
        }
    }
    return result
}

func changeVolumeLocation(volume: Volume, newLocation: URL) {
    let oldVolumeURL = URL(string: volume.location!)!
    let oldVolumeURLAbsoluteString = oldVolumeURL.absoluteString
    let newAbsoluteString = newLocation.absoluteString
    for track in globalRootLibrary!.tracks! as! Set<Track> {
        let url = URL(string: track.location!)!
        let trackVolume = getVolumeOfURL(url: url)
        if trackVolume == oldVolumeURL {
            track.location = track.location!.replacingOccurrences(of: oldVolumeURLAbsoluteString, with: newAbsoluteString, options: .anchored, range: nil)
        }
    }
    if let watchDirs = globalRootLibrary?.watch_dirs as? [URL] {
        var newWatchDirs = [URL]()
        for url in watchDirs {
            let watchDirVolume = getVolumeOfURL(url: url)
            if watchDirVolume == oldVolumeURL {
                let oldWatchDirAbsoluteString = url.absoluteString
                let newURLAbsoluteString = oldWatchDirAbsoluteString.replacingOccurrences(of: oldVolumeURLAbsoluteString, with: newAbsoluteString, options: .anchored, range: nil)
                newWatchDirs.append(URL(string: newURLAbsoluteString)!)
            } else {
                newWatchDirs.append(url)
            }
        }
        globalRootLibrary?.watch_dirs = newWatchDirs as NSArray
    }
}

func changeLibraryCentralMediaFolder(library: Library, newLocation: URL) {
    library.organization_template?.default_template?.base_url_string = newLocation.absoluteString
}

func getVolumeOfURL(url: URL) -> URL {
    do {
        let key = URLResourceKey.volumeURLKey
        let resourceValues = try url.resourceValues(forKeys: Set([key]))
        let volURL = resourceValues.volume
        return volURL!.standardizedFileURL
    } catch {
        print(error)
        fatalError()
    }
}

func checkIfVolumeExists(withURL url: URL, subcontext: NSManagedObjectContext? = nil) -> Volume? {
    let fetch = NSFetchRequest<Volume>(entityName: "Volume")
    let predicate = NSPredicate(format: "location == %@", url.absoluteString)
    fetch.predicate = predicate
    do {
        let results = subcontext != nil ? (try subcontext!.fetch(fetch)) : (try managedContext.fetch(fetch))
        if results.count > 0 {
            return results[0]
        } else {
            return nil
        }
    } catch {
        print(error)
        return nil
    }
}

func createNonTemplateDirectoryFor(album albumOptional: Album?, dry: Bool) -> URL? { // does not handle errors
    guard let album = albumOptional else { return nil }
    let baseURL = globalRootLibrary.getCentralMediaFolder()!
    var albumDirectory = baseURL.appendingPathComponent("Album Files")
    if album.is_compilation == true {
        albumDirectory.appendPathComponent("Compilations")
    } else {
        if album.album_artist != nil {
            albumDirectory.appendPathComponent(album.album_artist!.name ?? UNKNOWN_ARTIST_STRING)
        } else {
            let set = Set(album.tracks!.compactMap({return ($0 as! Track).artist?.name}))
            if set.count > 1 {
                albumDirectory.appendPathComponent(UNKNOWN_ALBUM_ARTIST_STRING)
            } else {
                albumDirectory.appendPathComponent(set.first ?? UNKNOWN_ARTIST_STRING)
            }
        }
    }
    albumDirectory.appendPathComponent(album.name ?? UNKNOWN_ALBUM_STRING)
    do {
        if !dry {
            try FileManager.default.createDirectory(at: albumDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return albumDirectory
    } catch {
        print(error)
        return nil
    }
}

func getImageExtension(_ uti: CFString) -> String? {
    if UTTypeConformsTo(uti, kUTTypeImage) {
        if UTTypeConformsTo(uti, kUTTypeJPEG) {
            return "jpg"
        } else if UTTypeConformsTo(uti, kUTTypeJPEG2000) {
            return "jpg"
        } else if UTTypeConformsTo(uti, kUTTypeTIFF) {
            return "tiff"
        } else if UTTypeConformsTo(uti, kUTTypePICT) {
            return "pict"
        } else if UTTypeConformsTo(uti, kUTTypeGIF) {
            return "gif"
        } else if UTTypeConformsTo(uti, kUTTypePNG) {
            return "png"
        } else if UTTypeConformsTo(uti, kUTTypeQuickTimeImage) {
            return "qtif"
        } else if UTTypeConformsTo(uti, kUTTypeAppleICNS) {
            return "icns"
        } else if UTTypeConformsTo(uti, kUTTypeBMP) {
            return "bmp"
        } else if UTTypeConformsTo(uti, kUTTypeICO) {
            return "ico"
        } else {
            return nil
        }
    } else if UTTypeConformsTo(uti, kUTTypePDF) {
        return "pdf"
    } else {
        return nil
    }
}


func shuffleArray(_ array: [AnyObject]) -> [AnyObject] {
    guard array.count > 0 else { return array }
    var newArray = array
    for i in 0..<array.count - 1 {
        let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
        guard i != j else {continue}
        newArray.swapAt(i, j)
    }
    return newArray
}

func shuffleMutableOrderedSet(_ mos: inout NSMutableOrderedSet) {
    guard mos.count > 0 else {return}
    for i in 0..<mos.count - 1 {
        let j = Int(arc4random_uniform(UInt32(mos.count - i))) + i
        guard i != j else {continue}
        swap(&mos[i], &mos[j])
    }
}

func getTrackWithID(_ id: Int, background: Bool) -> Track? {
    let fetch_req = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
    let pred = NSPredicate(format: "id == \(id)")
    fetch_req.predicate = pred
    let result: Track? = {() -> Track? in
        do {
            let context = background ? backgroundContext : managedContext
            let trackList = try context.fetch(fetch_req) as? [Track]
            if trackList!.count > 0 {
                return trackList![0]
            } else {
                return nil
            }
        }
        catch {
            return nil
        }
    }()
    return result
}

func getNetworkTrackWithID(_ id: Int) -> Track? {
    let fetch_req = NSFetchRequest<NSFetchRequestResult>(entityName: "Track")
    let pred = NSPredicate(format: "id == \(id) && is_network == true")
    fetch_req.predicate = pred
    let result: Track? = {() -> Track? in
        do {
            return try (managedContext.fetch(fetch_req) as! [Track])[0]
        }
        catch {
            return nil
        }
    }()
    return result
}


let sharedLibraryNamesDictionary = NSMutableDictionary()


/*var albumSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending: true), NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]
//var albumSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_album", ascending: true)]
var dateAddedSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "date_added", ascending: true, selector: #selector(NSDate.compare(_:))), NSSortDescriptor(key: "sort_artist", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "sort_album", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:))), NSSortDescriptor(key: "track_num", ascending:true)]
var nameSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]
var timeSortDescriptors: [NSSortDescriptor] = [NSSortDescriptor(key: "time", ascending: true), NSSortDescriptor(key: "sort_name", ascending:true, selector: #selector(NSString.localizedStandardCompare(_:)))]*/

func shuffle_array(_ array: inout [Int]) {
    guard array.count > 0 else {return}
    for i in 0..<array.count - 1 {
        let j = Int(arc4random_uniform(UInt32(array.count - i))) + i
        guard i != j else {continue}
        array.swapAt(i, j)
    }
}

func createMD5HashOf(data: Data) -> String {
    //only used for images, to test data equality
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    data.withUnsafeBytes { bytes in
        CC_MD5(bytes, CC_LONG(data.count), &digest)
    }
    let hashData = Data(bytes: digest)
    let hashString = hashData.base64EncodedString()
    return hashString
}

func createThirtyTwoCharacterMD5HashOf(data: Data) -> String {
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    data.withUnsafeBytes { bytes in
        CC_MD5(bytes, CC_LONG(data.count), &digest)
    }
    let hashData = Data(bytes: digest)
    let string = hashData.map( { return String(format: "%02hhx", $0) } ).joined()
    return string
}

func getFileType(image: Data) -> String? {
    guard let imageSource = CGImageSourceCreateWithData(image as NSData, [:] as NSDictionary) else { return nil }
    guard let uniformTypeIdentifier = CGImageSourceGetType(imageSource) else { return nil }
    return getImageExtension(uniformTypeIdentifier)
}

func getFileTypeFrom(url: URL) -> String? {
    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, [:] as NSDictionary) else {
        return nil
    }
    guard let uniformTypeIdentifier = CGImageSourceGetType(imageSource) else {
        return nil
    }
    return getImageExtension(uniformTypeIdentifier)
}

/*func getUTIFrom(url: URL) -> CFString? {
    guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, [:] as NSDictionary) else {
        return nil
    }
    guard let uniformTypeIdentifier = CGImageSourceGetType(imageSource) else {
        return nil
    }
    return uniformTypeIdentifier
}*/

func getUTIFrom(url: URL) -> String? {
    return (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
}

var jmcUnknownArtist = {() -> Artist in
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
    let predicate = NSPredicate(format: "id == 1")
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Artist]
        return result[0]
    } catch {
        let unknownArtist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
        unknownArtist.id = 1
        unknownArtist.name = ""
        return unknownArtist
    }
}

var jmcUnknownAlbum = {() -> Album in
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
    let predicate = NSPredicate(format: "id == 1")
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Album]
        return result[0]
    } catch {
        let unknownAlbum = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
        unknownAlbum.id = 1
        unknownAlbum.name = ""
        return unknownAlbum
    }
}

var jmcUnknownComposer = {() -> Composer in
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Composer")
    let predicate = NSPredicate(format: "id == 1")
    request.predicate = predicate
    do {
        let result = try managedContext.fetch(request) as! [Composer]
        return result[0]
    } catch {
        let unknownComposer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
        unknownComposer.id = 1
        unknownComposer.name = "Unknown Composer"
        return unknownComposer
    }
}

func checkIfArtistExists(_ name: String, subcontext: NSManagedObjectContext? = nil) -> Artist? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artist")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = subcontext != nil ? (try subcontext!.fetch(request) as! [Artist]) : (try managedContext.fetch(request) as! [Artist])
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking artist: \(error)")
        return nil
    }
}

func checkIfAlbumExists(withName name: String, withArtist artist: Artist, subcontext: NSManagedObjectContext? = nil) -> Album? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Album")
    let predicate = NSPredicate(format: "name == %@ and album_artist == %@", name, artist)
    request.predicate = predicate
    do {
        let result = subcontext != nil ? (try subcontext!.fetch(request) as! [Album]) : (try managedContext.fetch(request) as! [Album])
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking album: \(error)")
        return nil
    }
}

func checkIfComposerExists(_ name: String, subcontext: NSManagedObjectContext? = nil) -> Composer? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Composer")
    let predicate = NSPredicate(format: "name == %@", name)
    request.predicate = predicate
    do {
        let result = subcontext != nil ? (try subcontext!.fetch(request) as! [Composer]) : (try managedContext.fetch(request) as! [Composer])
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking copmoser: \(error)")
        return nil
    }
}

func checkIfCachedOrderExists(_ name: String, subcontext: NSManagedObjectContext? = nil) -> CachedOrder? {
    let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CachedOrder")
    let predicate = NSPredicate(format: "order == %@", name)
    request.predicate = predicate
    do {
        let result = subcontext != nil ? (try subcontext!.fetch(request) as! [CachedOrder]) : (try managedContext.fetch(request) as! [CachedOrder])
        if result.count > 0 {
            return result[0]
        } else {
            return nil
        }
    } catch {
        print("error checking cached order: \(error)")
        return nil
    }
}


func getSortName(_ name: String?) -> String? {
    var sortName = name
    if name != nil {
        for prefix in defaultSortPrefixDictionary.allKeys {
            if name!.lowercased().hasPrefix(prefix as! String) {
                let range = name!.startIndex...name!.index(name!.startIndex, offsetBy: (prefix as! String).count - 1)
                sortName!.removeSubrange(range)
                return sortName
            }
        }
    }
    return nil
}

func getTimeAsString(_ time: TimeInterval) -> String? {
    let dongs = Int(time)
    let hr = dongs / 3600
    let min = (dongs - (hr * 3600)) / 60
    let sec = (dongs - (hr * 3600) - (min * 60))
    var stamp = ""
    if (sec < 10) {
        stamp = "\(min):0\(sec)"
    }
    else {
        stamp = "\(min):\(sec)"
    }
    if hr != 0 {
        if (min < 10) {
            stamp = "\(hr):0\(stamp)"
        }
        else {
            stamp = "\(hr):\(stamp)"
        }
    }
    return stamp
}



func addIDsAndMakeNonNetwork(_ track: Track) {
    let library = {() -> Library? in
        let fetchReq = NSFetchRequest<NSFetchRequestResult>(entityName: "Library")
        let predicate = NSPredicate(format: "is_network == nil OR is_network == false")
        fetchReq.predicate = predicate
        do {
            let result = try managedContext.fetch(fetchReq)[0] as! Library
            return result
        } catch {
            return nil
        }
    }()
    track.id = Int(library!.next_track_id!) as NSNumber?
    library!.next_track_id = Int(library!.next_track_id!) + 1 as NSNumber
    if track.album?.is_network == true {
        track.album?.is_network = false
        track.album?.id = library?.next_album_id
        library!.next_album_id = Int(library!.next_album_id!) + 1 as NSNumber
    }
    if track.artist?.is_network == true {
        track.artist?.is_network = false
        track.artist?.id = library?.next_artist_id
        library!.next_artist_id = Int(library!.next_artist_id!) + 1 as NSNumber
    }
    if track.composer?.is_network == true {
        track.composer?.is_network = false
        track.composer?.id = library?.next_composer_id
        library!.next_composer_id = Int(library!.next_composer_id!) + 1 as NSNumber
    }
}

func getInstanceWithHighestIDForEntity(_ entityName: String) -> NSManagedObject? {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    fetchRequest.fetchLimit = 1
    let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]
    do {
        let result = try managedContext.fetch(fetchRequest) as! [NSManagedObject]
        return result[0]
    } catch {
        print("error getting instance with highest id: \(error)")
    }
    return nil
}

func insert(_ tracks: NSOrderedSet, track: TrackView, isGreater: ((Track) -> (Track) -> ComparisonResult)) -> Int {
    var high: Int = tracks.count - 1
    var low: Int = 0
    var index: Int
    while (low <= high) {
        index = (low + high) / 2
        let result = isGreater(track.track!)((tracks[index] as! TrackView).track!)
        if result == .orderedDescending {
            low = index + 1
        }
        else if result == .orderedAscending {
            high = index - 1
        }
        else {
            return index
        }
    }
    return low
}

func fixIndicesImmutable(order: CachedOrder) {
    notEnablingUndo {
        var key: String
        switch order.order! {
        case "Artist":
            key = "artist_order"
        case "Album":
            key = "album_order"
        case "Date Added":
            key = "date_added_order"
        case "Name":
            key = "name_order"
        case "Album Artist":
            key = "album_artist_order"
        case "Genre":
            key = "genre_order"
        case "Kind":
            key = "kind_order"
        case "Date Released":
            key = "release_date_order"
        case "Composer":
            key = "composer_order"
        default:
            key = "poop"
        }
        for (index, trackView) in order.track_views!.enumerated() {
            (trackView as AnyObject).setValue(index, forKey: key)
        }
        order.needs_update = false
    }
}

func fixIndices(_ set: NSMutableOrderedSet, index: Int, order: String) {
    let trackView = (set[index] as! TrackView)
    var testIndex = index + 1
    let key: String
    switch order {
    case "Artist":
        key = "artist_order"
    case "Album":
        key = "album_order"
    case "Date Added":
        key = "date_added_order"
    case "Name":
        key = "name_order"
    case "Album Artist":
        key = "album_artist_order"
    case "Genre":
        key = "genre_order"
    case "Kind":
        key = "kind_order"
    case "Date Released":
        key = "release_date_order"
    case "Composer":
        key = "composer_order"
    default:
        key = "poop"
    }
    trackView.setValue(index, forKey: key)
    var firstIndex = index
    while (testIndex < set.count && ((set[testIndex] as AnyObject).value(forKey: key) as! Int) <= ((set[firstIndex] as AnyObject).value(forKey: key) as! Int)) {
        let currentValue = (set[testIndex] as AnyObject).value(forKey: key) as! Int
        (set[testIndex] as AnyObject).setValue(currentValue + 1, forKey: key)
        firstIndex = firstIndex + 1
        testIndex = testIndex + 1
    }
}

func testFixIndices(_ set: NSMutableOrderedSet, order: String) {
    let key: String
    switch order {
    case "Artist":
        key = "artist_order"
    case "Album":
        key = "album_order"
    case "Date Added":
        key = "date_added_order"
    case "Name":
        key = "name_order"
    case "Album Artist":
        key = "album_artist_order"
    case "Genre":
        key = "genre_order"
    case "Kind":
        key = "kind_order"
    case "Date Released":
        key = "release_date_order"
    case "Composer":
        key = "composer_order"
    default:
        key = "poop"
    }
    var index = 0
    for track in set {
        (track as AnyObject).setValue(index, forKey: key)
        index += 1
    }
}


func reorderForTracks(_ tracks: [Track], cachedOrder: CachedOrder, subContext: NSManagedObjectContext?) {
    let actualTracks = subContext != nil ? tracks : tracks.map({return managedContext.object(with: $0.objectID) as! Track})
    print("reordering for tracks for cached order \(cachedOrder.order!)")
    let comparator: (Track) -> (Track) -> ComparisonResult
    switch cachedOrder.order! {
    case "Artist":
        comparator = Track.compareArtist
    case "Album":
        comparator = Track.compareAlbum
    case "Date Added":
        comparator = Track.compareDateAdded
    case "Name":
        comparator = Track.compareName
    case "Date Released":
        comparator = Track.compareDateReleased
    case "Album Artist":
        comparator = Track.compareAlbumArtist
    case "Genre":
        comparator = Track.compareGenre
    case "Kind":
        comparator = Track.compareKind
    case "Composer":
        comparator = Track.compareComposer
    default:
        comparator = Track.compareArtist
    }
    if let cachedOrderTrackViews = cachedOrder.track_views, actualTracks.count > cachedOrderTrackViews.count {
        let allTracksDisparateContexts = (cachedOrder.track_views!.array as! [TrackView]).map({return $0.track!}) + actualTracks
        let allTracks = allTracksDisparateContexts.map( { return $0.managedObjectContext == subContext ? $0 : (subContext!.object(with: $0.objectID) as! Track) } ) as NSArray
        let newTracks: NSArray
        let key: String
        switch cachedOrder.order! {
        case "Artist":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareArtist)) as NSArray
            key = "artist_order"
        case "Album":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareAlbum)) as NSArray
            key = "album_order"
        case "Date Added":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareDateAdded)) as NSArray
            key = "date_added_order"
        case "Name":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareName)) as NSArray
            key = "name_order"
        case "Date Released":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareDateReleased)) as NSArray
            key = "release_date_order"
        case "Album Artist":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareAlbumArtist)) as NSArray
            key = "album_artist_order"
        case "Genre":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareGenre)) as NSArray
            key = "genre_order"
        case "Kind":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareKind)) as NSArray
            key = "kind_order"
        case "Composer":
            newTracks = allTracks.sortedArray(using: #selector(Track.compareComposer)) as NSArray
            key = "composer_order"
        default:
            newTracks = allTracks.sortedArray(using: #selector(Track.compareArtist)) as NSArray
            key = "artist_order"
        }
        cachedOrder.needs_update = true
        cachedOrder.track_views = NSMutableOrderedSet(array: newTracks.map({return ($0 as! Track).view!}))
    } else {
        let mutableVersion = cachedOrder.track_views!.mutableCopy() as! NSMutableOrderedSet
        mutableVersion.removeObjects(in: actualTracks.map({return $0.view!}))
        for track in actualTracks {
            let index = insert(mutableVersion, track: track.view!, isGreater: comparator)
            print("index is \(index)")
            mutableVersion.insert(track.view!, at: index)
        }
        cachedOrder.track_views = mutableVersion
        cachedOrder.needs_update = true
    }
}
