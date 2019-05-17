//
//  EditingFunctions.swift
//  jmc
//
//  Created by John Moody on 9/7/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Cocoa
import CoreData

func editName(_ tracks: [Track]?, name: String) {
    let sortName = getSortName(name)
    for track in tracks! {
        track.name = name
        if sortName != nil && sortName != name {
            track.sort_name = sortName
        }
    }
}

func editMovementName(_ tracks: [Track]?, name: String) {
    for track in tracks! {
        track.movement_name = name
    }
}

func editMovementNum(_ tracks: [Track]?, num: Int) {
    for track in tracks! {
        track.movement_number = num as NSNumber
    }
}
func editArtist(_ tracks: [Track]?, artistName: String) {
    guard let tracks = tracks else { return }
    print(artistName)
    let artistCheck = checkIfArtistExists(artistName)
    if artistCheck != nil {
        for track in tracks {
            track.artist = artistCheck!
            let artistName = artistCheck!.name!
            let sortArtistName = getSortName(artistName)
            if sortArtistName != artistName {
                track.sort_artist = sortArtistName
            }
        }
    } else {
        let new_artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
        new_artist.name = artistName
        new_artist.id = globalRootLibrary?.next_artist_id
        globalRootLibrary!.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
        let sortArtistName = getSortName(artistName)
        for track in tracks {
            track.artist = new_artist
            if sortArtistName != artistName {
                track.sort_artist = sortArtistName
            }
        }
    }
    let tracksWithoutAlbumArtists = tracks.filter({ return $0.album?.album_artist != nil })
    editAlbumArtist(tracksWithoutAlbumArtists, albumArtistName: artistName)
}

func editComposer(_ tracks: [Track]?, composerName: String) {
    print(composerName)
    let composerCheck = checkIfComposerExists(composerName)
    if composerCheck != nil {
        for track in tracks! {
            track.composer = composerCheck!
            let sortComposerName = getSortName(composerName)
            if sortComposerName != composerName {
                track.sort_composer = sortComposerName
            }
        }
    } else {
        let new_composer = NSEntityDescription.insertNewObject(forEntityName: "Composer", into: managedContext) as! Composer
        new_composer.name = composerName
        new_composer.id = globalRootLibrary?.next_composer_id
        globalRootLibrary!.next_composer_id = Int(globalRootLibrary!.next_composer_id!) + 1 as NSNumber
        let sortComposerName = getSortName(composerName)
        for track in tracks! {
            track.composer = new_composer
            if sortComposerName != composerName {
                track.sort_composer = sortComposerName
            }
        }
    }
}

func editAlbum(_ tracks: [Track]?, albumName: String) {
    print(albumName)
    guard let tracks = tracks else { return }
    var artistTrackDictionary = [Artist : [Track]]()
    for track in tracks {
        if artistTrackDictionary[track.artist!] == nil {
            artistTrackDictionary[track.artist!] = [Track]()
        }
        artistTrackDictionary[track.artist!]?.append(track)
    }
    for (artist, tracks) in artistTrackDictionary {
        if let albumCheck = checkIfAlbumExists(withName: albumName, withArtist: artist) {
            for track in tracks {
                track.album = albumCheck
                let albumName = albumCheck.name!
                let sortAlbumName = getSortName(albumName)
                if sortAlbumName != albumName {
                    track.sort_album = sortAlbumName
                }
            }
        } else {
            let new_album = NSEntityDescription.insertNewObject(forEntityName: "Album", into: managedContext) as! Album
            new_album.name = albumName
            new_album.id = globalRootLibrary?.next_album_id
            new_album.album_artist = artist
            globalRootLibrary!.next_album_id = Int(globalRootLibrary!.next_album_id!) + 1 as NSNumber
            let sortAlbumName = getSortName(albumName)
            for track in tracks {
                track.album = new_album
                if sortAlbumName != albumName {
                    track.sort_album = sortAlbumName
                }
            }
        }
    }
}

func editAlbumArtist(_ tracks: [Track]?, albumArtistName: String) {
    guard let tracks = tracks else { return }
    print(albumArtistName)
    let artistCheck = checkIfArtistExists(albumArtistName)
    let albums = Set(tracks.map({return $0.album!}))
    var nameAlbumDictionary = [String : [Album]]()
    for album in albums {
        if nameAlbumDictionary[album.name!] == nil {
            nameAlbumDictionary[album.name!] = [Album]()
        }
        nameAlbumDictionary[album.name!]!.append(album)
    }
    var combinedAlbums = [Album]()
    for (_, albums) in nameAlbumDictionary {
        combinedAlbums.append(albums.reduce(albums.first!) {
            return combineAlbums($0, $1)
        })
    }
    if artistCheck != nil {
        for album in combinedAlbums {
            album.album_artist = artistCheck!
            let artistName = artistCheck!.name!
            let sortArtistName = getSortName(artistName)
            if sortArtistName != artistName {
                for track in album.tracks as! Set<Track> {
                    track.sort_album_artist = sortArtistName
                }
            }
        }
    } else {
        let new_artist = NSEntityDescription.insertNewObject(forEntityName: "Artist", into: managedContext) as! Artist
        new_artist.name = albumArtistName
        new_artist.id = globalRootLibrary?.next_artist_id
        globalRootLibrary!.next_artist_id = Int(globalRootLibrary!.next_artist_id!) + 1 as NSNumber
        let sortArtistName = getSortName(albumArtistName)
        for album in combinedAlbums {
            album.album_artist = new_artist
        }
        for track in tracks {
            if sortArtistName != albumArtistName {
                track.sort_album_artist = sortArtistName
            }
        }
    }
}

func combineAlbums(_ firstAlbum: Album, _ secondAlbum: Album) -> Album {
    //combine primary artwork
    if firstAlbum.primary_art != nil {
        if secondAlbum.primary_art != nil {
            firstAlbum.addToOther_art(secondAlbum.primary_art!)
        }
    } else {
        if secondAlbum.primary_art != nil {
            firstAlbum.primary_art = secondAlbum.primary_art
        }
    }
    //combine secondary artwork
    if let secondOtherArt = secondAlbum.other_art, secondOtherArt.count > 0 {
        if firstAlbum.primary_art == nil {
            firstAlbum.primary_art = secondAlbum.other_art?.firstObject as! AlbumArtwork
        } else {
            firstAlbum.addToOther_art(secondAlbum.other_art!.array)
        }
    }
    //combine other files
    if let secondOtherFiles = secondAlbum.other_files, secondOtherFiles.count > 0 {
        firstAlbum.addToOther_files(secondAlbum.other_files!)
    }
    
    //combine tracks
    for track in secondAlbum.tracks as! Set<Track> {
        track.album = firstAlbum
    }
    
    return firstAlbum
}

func notEnablingUndo(stuff: () -> Void) {
    managedContext.processPendingChanges()
    managedContext.undoManager?.disableUndoRegistration()
    stuff()
    managedContext.processPendingChanges()
    managedContext.undoManager?.enableUndoRegistration()
}

func withUndoBlock(name: String, stuff: () -> Void) {
    managedContext.undoManager?.beginUndoGrouping()
    stuff()
    managedContext.undoManager?.endUndoGrouping()
    managedContext.undoManager?.setActionName(name)
}

func editTrackNum(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        for track in tracks! {
            track.track_num = num as NSNumber?
        }
    }
}

func editTrackNumOf(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.track_count = num as NSNumber?
        }
    }
}

func editDiscNum(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        for track in tracks! {
            track.disc_number = num as NSNumber?
        }
    }
}

func editDiscNumOf(_ tracks: [Track]?, num: Int) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.disc_count = num as NSNumber?
        }
    }
}

func editComments(_ tracks: [Track]?, comments: String) {
    if tracks != nil {
        for track in tracks! {
            track.comments = comments
        }
    }
}

func editGenre(_ tracks: [Track]?, genre: String) {
    if tracks != nil {
        for track in tracks! {
            track.genre = genre
        }
    }
}

func editRating(_ tracks: [Track]?, rating: Int) {
    if tracks != nil {
        for track in tracks! {
            track.rating = rating as NSNumber?
        }
    }
}

func editIsComp(_ tracks: [Track]?, isComp: Bool) {
    if tracks != nil {
        let unique_albums = Set(tracks!.map({return $0.album!}))
        for album in unique_albums {
            album.is_compilation = isComp as NSNumber?
        }
    }
}

func editSortName(_ tracks: [Track]?, sortName: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_name = sortName
        }
    }
}

func editSortArtist(_ tracks: [Track]?, sortArtist: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_name = sortArtist
        }
    }
}

func editSortAlbum(_ tracks: [Track]?, sortAlbum: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_album = sortAlbum
        }
    }
}

func editSortAlbumArtist(_ tracks: [Track]?, sortAlbumArtist: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_album_artist = sortAlbumArtist
        }
    }
}

func editSortComposer(_ tracks: [Track]?, sortComposer: String) {
    if tracks != nil {
        for track in tracks! {
            track.sort_composer = sortComposer
        }
    }
}

func editReleaseDate(_ tracks: [Track]?, date: JMDate) {
    if tracks != nil {
        for album in Set(tracks!.compactMap({return $0.album})) {
            album.release_date = date
        }
    }
}
