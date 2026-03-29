# Mustory

Mustory is a music management application built with SwiftUI and MusicKit. It allows users to explore their recently played songs, albums, and playlists, as well as manage their favorite tracks and explore their library.

## Features

- **Home Dashboard**: View recently played music items categorized by Songs, Albums, and Playlists.
- **Favorites**: Quick access to liked tracks.
- **Album Details**: Browse tracks within an album and playback music directly.
- **Playlist Management**: View and explore library playlists.
- **Music Player**: Floating player bar for controlling playback across the app.
- **AI Integration**: (Inferred from StepAIManager) Support for AI-assisted music exploration or recommendations.

## Project Structure

- `MustoryApp.swift`: Main entry point of the application.
- `HomeView.swift`: Root view managing the main navigation and tab structure.
- `MusicManager.swift`: Centralized manager for handling Apple Music playback, data fetching, and state management.
- `RecentView.swift`: Displays recently played items.
- `AlbumDetailView.swift`: Detailed view for albums including their tracklists.
- `MusicItemCell.swift`: Reusable cell component for displaying music items (Artwork + Title + Subtitle).
- `MusicPlayerBar.swift`: Persistent overlay for music playback control.
- `StepAIManager.swift`: Manager for AI-related functionality.

## Architecture

The project follows a modern SwiftUI architecture:
- **UI**: SwiftUI views (`View` protocol) for declarative UI definition.
- **Data Flow**: `@StateObject` and `@Published` properties within `MusicManager` for reactive data updates.
- **Services**: Integration with `MusicKit` for accessing the Apple Music library and playback.
- **Navigation**: Uses `NavigationStack` for hierarchical navigation.

## Development

Requires Xcode and an Apple Developer account with MusicKit permissions for full functionality.

---
Created by Antigravity AI.
