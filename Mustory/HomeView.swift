import SwiftUI

struct HomeView: View {
    @State private var selectedTab = "Recently"
    let tabs = ["Recently", "Playlist"]
    @State private var musicManager = MusicManager.shared
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Top Tab Bar + Settings
                    HStack {
                        HStack(spacing: 20) {
                            ForEach(tabs, id: \.self) { tab in
                                Button {
                                    withAnimation(.spring()) {
                                        selectedTab = tab
                                    }
                                } label: {
                                    Text(tab)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(selectedTab == tab ? .primary : .gray.opacity(0.5))
                                        .overlay(alignment: .bottom) {
                                            if selectedTab == tab {
                                                Rectangle()
                                                    .fill(.primary)
                                                    .frame(height: 2)
                                                    .offset(y: 4)
                                            }
                                        }
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Settings Button
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 20)
                    .background(Color(UIColor.systemBackground))
                    
                    // Main Content
                    TabView(selection: $selectedTab) {
                        RecentView()
                            .tag("Recently")
                        
                        PlaylistListView()
                            .tag("Playlist")
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                // Floating Bottom Player Bar
                MusicPlayerBar()
                    .padding(.bottom, 10)
            }
            .task {
                await musicManager.fetchAllData()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

#Preview {
    HomeView()
}
