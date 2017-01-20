JMC is a fast, no-nonsense media manager for macOS. It has an elegant, streamlined interface that harkens back to early versions of iTunes. JMC aims to give you the power and functionality associated with hackable media managers like foobar2000 with the elegance and simplicity of a well-designed platform-native macOS application.

JMC:

-Uses less memory and CPU than iTunes while performing better with libraries both small and large (50,000+ tracks).
-Lets you look at your album art again.
-Plays your albums in the correct order, Every Time.™
-Lets you share your music over a local area network.
-Fixes some of the (many)[link to something bad] (things)[link to something bad] (wrong)[link to something bad] with the iTunes interface. //should this line be rephrased?

JMC is written completely in Swift, is completely open-source, and runs on any OS X version >10.10, or, without shared libraries, 10.6. //verify

(Installation)
(Roadmap)
(Background)

# Installation
You can either compile (JMC from source manually)[link to github repo] or download the .dmg (here)[link to github download].

### Setup
You can choose to allow JMC to organize your library by moving or copying added files, or have it perform no organization at all. 

To import an existing iTunes library, use the “Import iTunes Library” action in the File menu, and point the importer at your iTunes Library.xml file.

When adding media, JMC can rename your files to follow the “(Disc Number)-(Track Number) (Track Name)” convention. Currently, JMC will never modify the content of files.

# Roadmap
Two of the primary goals for the initial release of JMC were, first, the ability to define custom fields for entities (think “featuring” or “mood”), and, second, the ability to keep track of multiple pieces of album artwork per-album, including multi-page .PDFs. I wanted an elegant way to stare at album artwork and keep track of booklets and other stuff that comes with albums, and have seen compelling reasons to offer custom fields to sort and organize on. Before these features were implemented, however, I realized I would be moving away from my current persistence framework (Core Data) as soon as feasible. After seeing how long each of these features would take to implement, I made the decision not to write them now, only to re-write significant portions of them later on.

To support these, as well as other advanced features present in other powerful media managers such as rich, automatically-tagged metadata, more advanced filesystem organization options, and powerful album art management, the second version of JMC aims to integrate with (beets)[link to beets], which uses SQLite as an underlying store. The largest task on this roadmap, then, is ditching Core Data and integrating with beets. More discussion on how this will look can be found on the (beets integration page)[link to other page about that].

Currently, JMC only offers audio playback of files that can be read by Core Audio. Podcast, radio, and video support are currently nonexistent, but will probably come in the future.

Some simple features that need implementation on JMC right now include:

-Non-placeholder icons.
-A location manager that offers a pleasant interface for viewing and manipulating where JMC thinks media files are. Also, media directory monitoring using FSEvents to watch directories for changes that warrant metadata modification to application entities.
-Advanced playback features like crossfades, custom start-stop playback positions and volume settings for tracks.

A few slightly larger things:

-FLAC support. Currently JMC uses (AVAudioEngine)[link to avaudioengine] for audio playback. If anyone knows a good strategy here, please get in touch.
-A discrete, server-only version of JMC that runs in the background and serves media from a volume to JMC clients on a local area network, and beyond (think Plex). This is basically JMC minus the GUI.
-A better way of displaying and adding these “probably-always-available” remote libraries other than the Shared Libraries tab of the source list.
-Making shared libraries better and less crash-prone.
-Alternate views for media akin to the iTunes album and artist views, except _not terrible_.

Still more stuff:

-Make JMC Applescript-able
-Last.fm integration? Last.fm seems to be on its way out, but there are few alternatives.
-A MiniPlayer!

# Background
Ever since iTunes 11 took away the ability to look at album art in the songs view I’ve contemplated writing my own OS X media manager. About six months ago I graduated from college and was pretty tired of watching iTunes literally play my playlists wrong and generally be a buggy piece of shit //edit for tone. After demonstrating such an undertaking was possible with some proofs of concept, I set to work in earnest with the goal of writing the application that iTunes could have been, had it been well-engineered and focused solely on organizing and listening to your music. 