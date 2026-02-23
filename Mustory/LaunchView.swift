
import SwiftUI
import MusicKit

struct LaunchView: View {
    @State private var musicManager = MusicManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(colors: [.black, Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App Logo/Icon Simulation
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .blur(radius: isAnimating ? 20 : 10)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 12) {
                    Text("Mustory")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("Capture your every music story")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if musicManager.authorizationStatus == .notDetermined {
                    Button {
                        Task {
                            await musicManager.requestAuthorization()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "apple.logo")
                            Text("Connect Apple Music")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(color: .white.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if musicManager.authorizationStatus == .denied || musicManager.authorizationStatus == .restricted {
                    Text("Please enable Music permissions in Settings to use Mustory")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    ProgressView()
                        .tint(.white)
                }
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    LaunchView()
}
