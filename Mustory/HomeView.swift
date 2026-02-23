import SwiftUI

struct HomeView: View {
    @State private var selectedTab = "Recently"
    let tabs = ["Recently", "Playlist"]
    @State private var musicManager = MusicManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Top Tab Bar
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
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
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
        }
    }
}

#Preview {
    HomeView()
}
