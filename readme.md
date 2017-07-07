# jmc
![screenshot](https://i.imgur.com/8NhiZpE.png)

jmc is a fast, elegant and powerful media manager for macOS. jmc aims to give you the power and functionality associated with hackable media managers like foobar2000 with the elegance and simplicity of a well-designed platform-native macOS application.

jmc:

- Uses less memory and CPU than iTunes while performing better with libraries both small and large (50,000+ tracks).
- Offers powerful features for viewing album artwork, including text files and PDFs.
- Has a powerful suite of organization tools that let jmc organize your media however you want to, effortlessly.
- Centers around a simple, intuitive, and elegant interface for listening to your music that doesn't get in your way.
- Has a powerful interface for sharing media over a local area network.
- Supports FLAC.

jmc is written completely in Swift, is completely open-source, and runs on OS X (macOS) 10.10 and above.

### Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Roadmap](#roadmap)

# Features

### Library Manager
jmc offers the most powerful tools for library organization of any media player for macOS. jmc keeps track of album artwork, PDFs, logs, cue sheets and more, and offers powerful tools for organizing your media.

jmc elegantly accounts for media spread across external volumes, showing available and unavailable volumes in the sidebar and filtering the music in your library accordingly.

#### Location Manager
jmc will track the locations of files added to it. If your files do manage to go missing, when transferring media between volumes or libraries, for example, you can use the location manager to easily relocate lost files and folders.

### Advanced Search
![screenshot](https://i.imgur.com/oYB83zF.png)

Using advanced search, you can filter your library by arbitrary criteria and create smart playlists.

### Shared Libraries

jmc can connect to jmc clients nearby, displaying them in the source list. Clients can connect to each other using either Ethernet, network Wi-Fi, or peer-to-peer Wi-Fi for clients in close physical proximity on different networks. Users can stream music from each other, or drag and drop to transfer media.

![screenshot](https://i.imgur.com/SJ5RgM5.png)

### Interface
jmc's advanced functionality is designed to stay out of the way of its elegant interface. jmc is intuitive. Maintaining a queue of upcoming music is as easy as dragging and dropping. Playlist creation is simple and easy.

# Installation
You can either compile jmc from source manually or download the latest stable artifact [here](https://github.com/jcm93/jmc/). In the future, binaries for jmc will likely be distributed through the App Store. In the meantime, please consider [buying me some coffee or food](https://jcm93.github.io/money/)!

### Setup
You can choose to allow jmc to organize your library by moving or copying added files, or have it perform no organization at all. 

To import an existing iTunes library, use the “Import iTunes Library” action in the File menu, and point the importer at your iTunes Library.xml file.
