# jmc
![screenshot](https://puu.sh/xoZYo/bd6d6deeb0.png)

jmc is a media manager/player for macOS. jmc aims to give you the power and functionality you want from a hackable media manager, along with the elegance and simplicity of a well-designed macOS application.

jmc:

- Centers around a sane and consistent interface that stays out of the way of listening to your music.
- Performs well with large libraries with minimal CPU and RAM use.
- Has a useful set of organization tools for organizing your media however you want to.
- Offers features for viewing and organizing album artwork, including images, text files, logs, and PDFs.
- Integrates seamlessly with Apple Music and iCloud Music Library, as well as offers features for LAN sharing.

jmc is open-source, written in Swift and runs on macOS 10.15 and above.

### Table of Contents
- [Features](#features)
- [Installation](#installation)
- [Roadmap](#roadmap)

# Features
The primary goal of jmc is to act as a replacement for Music.app, solving all of the glaring problems with its user interface. jmc will not randomly scroll away from your focus, does not take 3+ seconds to pause and unpause with a large library, has consistent keyboard controls regardless of how you are viewing your library, and aims to be pleasant and enjoyable to use. jmc also offers a number of useful tools for organizing your music library.

### Library Manager
![screenshot](https://puu.sh/xoZHp/31dddfc751.png)
jmc offers a set of useful tools for library media organization. jmc keeps track of album artwork, PDFs, logs, cue sheets and more, and offers flexible options for organizing your media.

jmc accounts for media spread across external volumes, showing available and unavailable volumes in the sidebar and filtering the music in your library accordingly.

#### Location Manager
jmc will track the locations of files added to it. If your files do go missing, when transferring media between volumes or libraries, for example, you can use the location manager to easily relocate lost files and folders.

### Advanced Search
![screenshot](https://i.imgur.com/oYB83zF.png)

Using advanced search, you can filter your library by arbitrary criteria and create smart playlists.

### Shared Libraries

jmc can connect to jmc clients nearby, displaying them in the source list. Clients can connect to each other using either Ethernet, network Wi-Fi, or peer-to-peer Wi-Fi for clients in close physical proximity on different networks. Users can stream music from each other, or drag and drop to transfer media.

![screenshot](https://i.imgur.com/SJ5RgM5.png)

# Installation
You can either compile jmc from source manually or download the latest stable artifact [here](https://github.com/jcm93/jmc/).

### Setup
You can choose to allow jmc to organize your library by moving or copying added files, or have it perform no organization at all. 

To import an existing iTunes library, use the “Import iTunes Library” action in the File menu, and point the importer at your iTunes Library.xml file.
