//
//  TrackExtension.swift
//  jmc
//
//  Created by John Moody on 5/31/17.
//  Copyright © 2017 John Moody. All rights reserved.
//

import Foundation

extension Track {
    @objc func compareArtist(_ other: Track) -> ComparisonResult {
        let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
        let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
        let artist_comparison: ComparisonResult
        if self_artist_name == nil || other_artist_name == nil {
            artist_comparison = (self_artist_name == other_artist_name) ? .orderedSame : (other_artist_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
        }
        if artist_comparison == .orderedSame {
            let self_album_name = self.sort_album != nil ? self.sort_album : self.album?.name
            let other_album_name = other.sort_album != nil ? other.sort_album : other.album?.name
            let album_comparison: ComparisonResult
            if self_album_name == nil || other_album_name == nil {
                album_comparison = (self_album_name == other_album_name) ? .orderedSame : (other_album_name != nil) ? .orderedAscending : .orderedDescending
            } else {
                album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            }
            if album_comparison == .orderedSame {
                let self_disc_num = self.disc_number
                let other_disc_num = other.disc_number
                let disc_num_comparison: ComparisonResult
                if self_disc_num == nil || other_disc_num == nil {
                    disc_num_comparison = (self_disc_num == other_disc_num) ? .orderedSame : (other_disc_num != nil) ? .orderedAscending : .orderedDescending
                } else {
                    disc_num_comparison = self_disc_num!.compare(other_disc_num!)
                }
                if disc_num_comparison == .orderedSame {
                    let self_track_num = self.track_num
                    let other_track_num = other.track_num
                    let track_num_comparison: ComparisonResult
                    if self_track_num == nil || other_track_num == nil {
                        track_num_comparison = (self_track_num == other_track_num) ? .orderedSame : (other_track_num != nil) ? .orderedAscending : .orderedDescending
                    } else {
                        track_num_comparison = self_track_num!.compare(other_track_num!)
                    }
                    if track_num_comparison == .orderedSame {
                        let self_name = self.sort_name != nil ? self.sort_name : self.name
                        let other_name = other.sort_name != nil ? other.sort_name : other.name
                        guard self_name != nil && other_name != nil else {
                            return (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
                        }
                        return self_name!.localizedStandardCompare(other_name!)
                    } else {
                        return track_num_comparison
                    }
                } else {
                    return disc_num_comparison
                }
            } else {
                return album_comparison
            }
        } else {
            return artist_comparison
        }
    }
    
    @objc func compareAlbum(_ other: Track) -> ComparisonResult {
        let self_album_name = self.sort_album != nil ? self.sort_album : self.album?.name
        let other_album_name = other.sort_album != nil ? other.sort_album : other.album?.name
        let album_comparison: ComparisonResult
        if self_album_name == nil || other_album_name == nil {
            album_comparison = (self_album_name == other_album_name) ? .orderedSame : (other_album_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
        }
        if album_comparison == .orderedSame {
            let self_artist_name = (self.sort_artist != nil) ? self.sort_artist : self.artist?.name
            let other_artist_name = (other.sort_artist != nil) ? other.sort_artist : other.artist?.name
            let artist_comparison: ComparisonResult
            if self_artist_name == nil || other_artist_name == nil {
                artist_comparison = (self_artist_name == other_artist_name) ? .orderedSame : (other_artist_name != nil) ? .orderedAscending : .orderedDescending
            } else {
                artist_comparison = self_artist_name!.localizedStandardCompare(other_artist_name!)
            }
            if artist_comparison == .orderedSame {
                let self_disc_num = self.disc_number
                let other_disc_num = other.disc_number
                let disc_num_comparison: ComparisonResult
                if self_disc_num == nil || other_disc_num == nil {
                    disc_num_comparison = (self_disc_num == other_disc_num) ? .orderedSame : (other_disc_num != nil) ? .orderedAscending : .orderedDescending
                } else {
                    disc_num_comparison = self_disc_num!.compare(other_disc_num!)
                }
                if disc_num_comparison == .orderedSame {
                    let self_track_num = self.track_num
                    let other_track_num = other.track_num
                    let track_num_comparison: ComparisonResult
                    if self_track_num == nil || other_track_num == nil {
                        track_num_comparison = (self_track_num == other_track_num) ? .orderedSame : (other_track_num != nil) ? .orderedAscending : .orderedDescending
                    } else {
                        track_num_comparison = self_track_num!.compare(other_track_num!)
                    }
                    if track_num_comparison == .orderedSame {
                        let self_name = self.sort_name != nil ? self.sort_name : self.name
                        let other_name = other.sort_name != nil ? other.sort_name : other.name
                        guard self_name != nil && other_name != nil else {
                            return (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
                        }
                        return self_name!.localizedStandardCompare(other_name!)
                    } else {
                        return track_num_comparison
                    }
                } else {
                    return disc_num_comparison
                }            } else {
                return artist_comparison
            }
        } else {
            return album_comparison
        }
    }
    
    @objc func compareAlbumArtist(_ other: Track) -> ComparisonResult {
        let self_album_artist_name = self.sort_album_artist != nil ? self.sort_album_artist : self.album?.album_artist?.name != nil ? self.album?.album_artist?.name : self.sort_artist != nil ? self.sort_artist : self.artist?.name
        let other_album_artist_name = other.sort_album_artist != nil ? other.sort_album_artist : other.album?.album_artist?.name != nil ? other.album?.album_artist?.name : other.sort_artist != nil ? other.sort_artist : self.artist?.name
        let album_artist_comparison: ComparisonResult
        if self_album_artist_name == nil || other_album_artist_name == nil {
            album_artist_comparison = (self_album_artist_name == other_album_artist_name) ? .orderedSame : (other_album_artist_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            album_artist_comparison = self_album_artist_name!.localizedStandardCompare(other_album_artist_name!)
        }
        if album_artist_comparison == .orderedSame {
            let self_album_name = (self.sort_album != nil) ? self.sort_album : self.album?.name
            let other_album_name = (other.sort_album != nil) ? other.sort_album : other.album?.name
            let album_comparison: ComparisonResult
            if self_album_name == nil || other_album_name == nil {
                album_comparison = (self_album_name == other_album_name) ? .orderedSame : (other_album_name != nil) ? .orderedAscending : .orderedDescending
            } else {
                album_comparison = self_album_name!.localizedStandardCompare(other_album_name!)
            }
            if album_comparison == .orderedSame {
                let self_disc_num = self.disc_number
                let other_disc_num = other.disc_number
                let disc_num_comparison: ComparisonResult
                if self_disc_num == nil || other_disc_num == nil {
                    disc_num_comparison = (self_disc_num == other_disc_num) ? .orderedSame : (other_disc_num != nil) ? .orderedAscending : .orderedDescending
                } else {
                    disc_num_comparison = self.disc_number!.compare(other_disc_num!)
                }
                if disc_num_comparison == .orderedSame {
                    let self_track_num = self.track_num
                    let other_track_num = other.track_num
                    let track_num_comparison: ComparisonResult
                    if self_track_num == nil || other_track_num == nil {
                        track_num_comparison = (self_track_num == other_track_num) ? .orderedSame : (other_track_num != nil) ? .orderedAscending : .orderedDescending
                    } else {
                        track_num_comparison = self_track_num!.compare(other_track_num!)
                    }
                    if track_num_comparison == .orderedSame {
                        let self_name = self.sort_name != nil ? self.sort_name : self.name
                        let other_name = other.sort_name != nil ? other.sort_name : other.name
                        guard self_name != nil && other_name != nil else {
                            return (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
                        }
                        return self_name!.localizedStandardCompare(other_name!)
                    } else {
                        return track_num_comparison
                    }
                } else {
                    return disc_num_comparison
                }            } else {
                return album_comparison
            }
        } else {
            return album_artist_comparison
        }
    }
    
    @objc func compareGenre(_ other: Track) -> ComparisonResult {
        let self_genre_name = self.genre
        let other_genre_name = other.genre
        let genre_comparison: ComparisonResult
        if self_genre_name == nil || other_genre_name == nil {
            genre_comparison = (self_genre_name == other_genre_name) ? .orderedSame : (other_genre_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            genre_comparison = self_genre_name!.localizedStandardCompare(other_genre_name!)
        }
        if genre_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return genre_comparison
        }
    }
    
    @objc func compareKind(_ other: Track) -> ComparisonResult {
        let self_kind_name = self.file_kind
        let other_kind_name = other.file_kind
        let kind_comparison: ComparisonResult
        if self_kind_name == nil || other_kind_name == nil {
            kind_comparison = (self_kind_name == other_kind_name) ? .orderedSame : (other_kind_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            kind_comparison = self_kind_name!.localizedStandardCompare(other_kind_name!)
        }
        if kind_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return kind_comparison
        }
    }
    
    @objc func compareComposer(_ other: Track) -> ComparisonResult {
        let self_composer_name = self.sort_composer != nil ? self.sort_composer : self.composer?.name
        let other_composer_name = other.sort_composer != nil ? other.sort_composer : other.composer?.name
        let composer_comparison: ComparisonResult
        if self_composer_name == nil || other_composer_name == nil {
            composer_comparison = (self_composer_name == other_composer_name) ? .orderedSame : (other_composer_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            composer_comparison = self_composer_name!.localizedStandardCompare(other_composer_name!)
        }
        if composer_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return composer_comparison
        }
    }
    
    @objc func compareDateAdded(_ other: Track) -> ComparisonResult {
        let self_date_added = self.date_added
        let other_date_added = other.date_added
        guard self_date_added != nil && other_date_added != nil else {
            return (self_date_added == other_date_added) ? .orderedSame : (other_date_added != nil) ? .orderedAscending : .orderedDescending
        }
        let dateDifference = self_date_added!.timeIntervalSince(other_date_added! as Date)
        let comparison: ComparisonResult = (abs(dateDifference) < DEFAULTS_DATE_SORT_GRANULARITY) ? .orderedSame : (dateDifference > 0) ? .orderedAscending : .orderedDescending
        if comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return comparison
        }
    }
    
    @objc func compareDateReleased(_ other: Track) -> ComparisonResult {
        let self_date_released = self.album?.release_date
        let other_date_released = other.album?.release_date
        guard self_date_released != nil && other_date_released != nil else {
            return (self_date_released == other_date_released) ? .orderedSame : (other_date_released != nil) ? .orderedAscending : .orderedDescending
        }
        let date_released_comparison = self_date_released!.compare(other_date_released! as Date)
        if date_released_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return date_released_comparison
        }
    }
    
    @objc func compareName(_ other: Track) -> ComparisonResult {
        let self_name = self.sort_name != nil ? self.sort_name : self.name
        let other_name = other.sort_name != nil ? other.sort_name : other.name
        let name_comparison: ComparisonResult
        if self_name == nil || other_name == nil {
            name_comparison = (self_name == other_name) ? .orderedSame : (other_name != nil) ? .orderedAscending : .orderedDescending
        } else {
            name_comparison = self_name!.compare(other_name!)
        }
        if name_comparison == .orderedSame {
            return self.compareArtist(other)
        } else {
            return name_comparison
        }
    }
}
