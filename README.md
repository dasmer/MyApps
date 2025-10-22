# MyApps

**MyApps** is an iOS app that lets you browse and explore all apps published by any developer on the Apple App Store. Discover complete developer portfolios, explore app catalogs, and find hidden gems from your favorite creators.

## Overview

The Apple App Store doesn't provide an easy way to see all apps from a single developer at once. MyApps fills this gap by providing a beautiful, intuitive interface to search for developers and browse their complete app catalog.

## Features

### Developer Search
- Search for any developer or company by name
- Real-time search with smart debouncing
- View developer information and primary genre

### App Catalog Browser
- See all apps published by a selected developer
- Apps sorted by popularity (rating count)
- Visual display of ratings, prices, and app icons
- Pull-to-refresh to update data
- Quick search to switch between developers

### Detailed App Information
- Comprehensive app details including:
  - Star ratings and review counts (exact numbers, not abbreviated)
  - What's New (latest release notes)
  - Full description
  - Screenshots gallery
  - Technical specifications (version, size, compatibility)
  - Release and update dates
  - Supported languages and devices
- Direct "View in App Store" button
- Raw JSON viewer for developers

### Smart Persistence
- Remembers your last selected developer
- Automatically loads previous selection on launch
- Seamless experience across app sessions

## Screenshots

_Coming soon_

## Requirements

- iOS 15.0 or later
- Xcode 14.0 or later (for development)
- Swift 5.7 or later
- Active internet connection

## Installation

### For Development

1. Clone the repository:
```bash
git clone https://github.com/yourusername/MyApps.git
```

2. Open the project in Xcode:
```bash
cd MyApps
open MyApps.xcodeproj
```

3. Build and run the project in Xcode (⌘R)

### For Users

_App Store link coming soon_

## Usage

1. **Search for a Developer**
   - Launch the app and tap the search bar
   - Type a developer or company name (e.g., "Meta", "Spotify", "Microsoft")
   - Select the developer from the search results

2. **Browse Apps**
   - Scroll through the list of apps sorted by popularity
   - Tap any app to see detailed information
   - Pull down to refresh the app list

3. **View App Details**
   - View comprehensive information about any app
   - Swipe through screenshots
   - Tap "View in App Store" to open the app in the App Store
   - Use the JSON viewer to see raw API data (for developers)

4. **Quick Developer Switch**
   - Tap the search bar at any time to search for a different developer
   - Your selection is automatically saved

## Architecture

### Technical Stack
- **Framework**: SwiftUI
- **Language**: Swift
- **Minimum Deployment**: iOS 15.0
- **APIs**: iTunes Search API & iTunes Lookup API
- **Networking**: URLSession with async/await
- **Storage**: UserDefaults for preferences

### Project Structure
```
MyApps/
├── MyAppsApp.swift           # App entry point
├── Views/
│   ├── ContentView.swift     # Main app list view
│   ├── ArtistSearchView.swift # Developer search interface
│   └── AppDetailView.swift   # Detailed app information
├── Models/
│   ├── AppItem.swift         # App data model
│   └── Artist.swift          # Developer data model
└── Utilities/
    └── AppSettings.swift     # UserDefaults wrapper
```

### Key Components

- **AppSettings**: Manages persistent storage of selected developer
- **Artist Model**: Represents developer/artist data from iTunes API
- **AppItem Model**: Represents app data with comprehensive metadata
- **ContentView**: Main view displaying app catalog with sorting and filtering
- **ArtistSearchView**: Searchable list of developers with debounced search
- **AppDetailView**: Comprehensive app information display

## API Usage

This app uses Apple's public iTunes APIs:

- **Search API**: `https://itunes.apple.com/search`
  - Used to find developers by name
  - Search for apps by various criteria

- **Lookup API**: `https://itunes.apple.com/lookup`
  - Fetch all apps from a specific developer
  - Retrieve detailed app information

No API key required. Rate limiting applies as per Apple's guidelines.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Future Enhancements

- [ ] Favorites/bookmarking for developers
- [ ] App comparison view
- [ ] Historical rating tracking
- [ ] Share app lists
- [ ] Dark mode optimization
- [ ] iPad optimization
- [ ] macOS version

## Privacy

MyApps does not collect, store, or transmit any personal user data. All app and developer information is fetched directly from Apple's public iTunes APIs. The only data stored locally is your selected developer preference using iOS UserDefaults.

## License

[Add your chosen license here]

## Contact

[Add your contact information or links]

## Acknowledgments

- App data provided by Apple's iTunes Search API
- Built with SwiftUI and modern Swift concurrency
