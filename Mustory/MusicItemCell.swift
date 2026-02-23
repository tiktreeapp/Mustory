import SwiftUI
import MusicKit

struct MusicItemCell: View {
    let title: String
    let subtitle: String
    let artwork: Artwork?
    let size: CGFloat = 140
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面图
            if let artwork = artwork {
                ArtworkImage(artwork, width: size, height: size)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                    .overlay(Image(systemName: "music.note").foregroundColor(.gray))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(.gray)
            }
            .frame(width: size, alignment: .leading)
        }
    }
}
