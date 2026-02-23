import SwiftUI
import MusicKit
import StoreKit

struct SettingsView: View {
    @State private var musicManager = MusicManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - Apple Music Connection
                Section {
                    Button {
                        openAppleMusic()
                    } label: {
                        HStack {
                            Image(systemName: "music.note.house.fill")
                                .font(.title2)
                                .foregroundColor(.pink)
                                .frame(width: 36)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Apple Music")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(connectionStatusText)
                                    .font(.caption)
                                    .foregroundColor(connectionStatusColor)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Music Service")
                } footer: {
                    if musicManager.authorizationStatus != .authorized {
                        Text("Tap to authorize Mustory to access your Apple Music library.")
                    }
                }
                
                // MARK: - Share & Review
                Section {
                    // Share Music Story
                    Button {
                        shareMustory()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 36)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Share Music Story")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Invite friends to discover music stories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Review Mustory
                    Button {
                        reviewMustory()
                    } label: {
                        HStack {
                            Image(systemName: "star.bubble.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 36)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Review Mustory")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Rate us on the App Store")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Community")
                }
                
                // MARK: - Legal
                Section {
                    // Terms of Service
                    Button {
                        if let url = URL(string: "https://docs.qq.com/doc/DZnRrT2R3TWFXY0Rs") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .frame(width: 36)
                            
                            Text("Terms of Service")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Privacy Policy
                    Button {
                        if let url = URL(string: "https://docs.qq.com/doc/DZnFhVnNIeWVSTG1O") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .frame(width: 36)
                            
                            Text("Privacy Policy")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Legal")
                }
                
                // MARK: - About
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Text("Mustory")
                                .font(.headline)
                            Text("Know the Story. Feel the Music.")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await musicManager.refreshAuthorizationStatus()
        }
    }
    
    private var connectionStatusText: String {
        switch musicManager.authorizationStatus {
        case .authorized: return "Connected"
        case .denied: return "Access Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Connected"
        @unknown default: return "Unknown"
        }
    }
    
    private var connectionStatusColor: Color {
        switch musicManager.authorizationStatus {
        case .authorized: return .green
        case .denied, .restricted: return .red
        default: return .orange
        }
    }
    
    private func openAppleMusic() {
        if let url = URL(string: "music://") {
            UIApplication.shared.open(url)
        }
    }
    
    private func shareMustory() {
        let shareText = "Know the Story. Feel the Music. by Mustory https://apps.apple.com/app/id6759556508"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func reviewMustory() {
        if let url = URL(string: "https://apps.apple.com/app/id6759556508?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}
