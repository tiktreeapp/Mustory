import SwiftUI
import MusicKit

struct SongRow: View {
    let index: Int
    let song: Track
    
    var body: some View {
        HStack(spacing: 16) {
            Text("\(index)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .frame(width: 25, alignment: .trailing)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                
                Text(song.artistName)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: "ellipsis")
                .foregroundColor(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
