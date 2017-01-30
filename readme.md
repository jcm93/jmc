# jmc
![screenshot](https://i.imgur.com/8NhiZpE.png)

jmc is a fast, no-nonsense media manager for macOS. It has an elegant, streamlined interface that harkens back to early versions of iTunes. jmc aims to give you the power and functionality associated with hackable media managers like foobar2000 with the elegance and simplicity of a well-designed platform-native macOS application.

jmc:

- Uses less memory and CPU than iTunes while performing better with libraries both small and large (50,000+ tracks).
- Lets you look at your album art again.
- Plays your albums in the correct order, Every Time.™
- Lets you share your music over a local area network.
- Has an elegant, simple and powerful interface.

jmc is written completely in Swift, is completely open-source, and runs on OS X (macOS) 10.10 and above.

### Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Roadmap](#roadmap)

# Features
jmc looks a lot like iTunes, but fixes many frustrating and unintuitive aspects of the iTunes interface. In particular:

- jmc doesn't change your focus in the songs view when you skip a song.
- If you're listening to a playlist and queue up a track, you won't hear it twice.
- Ordering a track to play while there are manually queued tracks doesn't result in [this dumb dialog box](https://i.imgur.com/oQb22Fk.png). jmc just plays the track.
- Deterministic behavior upon adding tracks to the library. jmc doesn't automatically play songs that you add to the library unless you tell it to.
- jmc remembers your selection, scroll point, and sort behavior in all playlist views, so you can more easily manage your playlists.

In short, jmc's interface should simply work the way you want it to.

### Advanced Search
jmc does away with the Column Browser in iTunes, in favor of a more powerful and flexible advanced search:

![screenshot](https://i.imgur.com/oYB83zF.png)

Using advanced search, users can filter their library by arbitrary criteria and create smart playlists.

### Shared Libraries

jmc can connect to jmc clients nearby, displaying them in the source list. Clients can connect to each other using either Ethernet, infrastructure Wi-Fi, or peer-to-peer Wi-Fi for clients in close physical proximity on different networks. Clients can stream music from each other, or drag and drop.

![screenshot](https://i.imgur.com/SJ5RgM5.png)

# Installation
You can either compile jmc from source manually or download the latest stable artifact [here](https://github.com/jcm93/jmc/). In the future, binaries for jmc will likely be distributed through the App Store. In the meantime, please consider [buying me some coffee or food](https://jcm93.github.io/money/)!

### Setup
You can choose to allow jmc to organize your library by moving or copying added files, or have it perform no organization at all. 

To import an existing iTunes library, use the “Import iTunes Library” action in the File menu, and point the importer at your iTunes Library.xml file.

When adding media, jmc can rename your files to follow the “${disc number}-${track number} ${track name}.${extension}” convention. Currently, jmc will never modify the content of files.

# Roadmap

A few high priorities for jmc features are:

- Support for multiple pieces of album artwork per album, including PDFs.
- More thorough, and preferably automatically tagged metadata.
- Custom fields for media (think "featuring", or "mood").

While some of these features were half-written and planned for the current release, I realized that the best way to support them would likely be to introduce compatibility with the [beets](http://beets.io/) project, which is already a wonderful media management system for macOS users that supports auto-tagging, artwork management and much more. Since supporting beets will involve migrating from jmc's current persistence framework (Core Data) toward SQLite, I elected not to complete half-baked versions of the above, only to rewrite large swaths of them later on.

Note: this upcoming migration has the side effect that subsequent versions of jmc will probably require you to re-import your library.

Some simple features that need implementation on jmc right now include:

- Non-placeholder icons.
- A location manager that offers a powerful interface for viewing and manipulating where jmc thinks media files are. Also, media directory monitoring using FSEvents to watch directories for changes that warrant metadata modification to application entities.
- Advanced playback features like crossfades, custom start-stop playback positions and volume settings for tracks.

A few slightly larger things:

- Fancier views for media akin to the iTunes album and artist views (but which aren't broken).
- FLAC support. Currently jmc uses [AVAudioEngine](https://developer.apple.com/reference/avfoundation/avaudioengine) for audio playback. I am currently investigating solutions here.
- A discrete, server-only version of jmc that runs in the background and serves media from a volume to jmc clients on a local area network, and beyond (think Plex). This is basically jmc minus the GUI.
- A better way of displaying and adding these “probably-always-available” remote libraries other than the Shared Libraries tab of the source list.
- Making shared libraries better and less crash-prone.

Still more stuff:

- Make jmc Applescript-able
- Last.fm integration? Last.fm seems to be on its way out, but there are few alternatives.
- A MiniPlayer!

Also, jmc currently doesn't play podcasts or videos. This functionality will likely arrive in some capacity in the future.
