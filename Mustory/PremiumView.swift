import SwiftUI
import MusicKit
import Combine
import StoreKit

struct PremiumView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: Int = 1 // 1 for Year, 0 for Month
    @State private var showCloseButton = false
    @State private var carouselIndex = 0
    @State private var musicManager = MusicManager.shared
    @State private var storeManager = StoreManager.shared
    @State private var isProcessing = false // 购买/恢复中的加载状态
    @State private var purchaseMessage = ""
    @State private var showPurchaseAlert = false

    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // 采用纯净启动页背景，去掉会导致边缘反光的 blur
            LaunchBackgroundView()

            VStack {
                // Top controls
                HStack {
                    Spacer()
                    if showCloseButton {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                        .padding(.top, 30) // X 按钮再下移 12 像素 (回到 24)
                        .transition(.opacity)
                    } else {
                        // Keep layout spacing balanced
                        Spacer().frame(height: 44).padding()
                    }
                }

                Spacer()

                // Favorites Cover Carousel
                let carouselSongs = Array(musicManager.favoriteSongs.prefix(10))
                if !carouselSongs.isEmpty {
                    TabView(selection: $carouselIndex) {
                        ForEach(Array(carouselSongs.enumerated()), id: \.offset) { index, song in
                            if let artwork = song.artwork {
                                // 边长减小 20 像素左右 (从 0.5 改为 0.45)
                                ArtworkImage(artwork, width: UIScreen.main.bounds.width * 0.45, height: UIScreen.main.bounds.width * 0.45)
                                    .cornerRadius(18)
                                    .shadow(color: .white.opacity(0.15), radius: 12, x: 0, y: 8)
                                    .tag(index)
                                    .padding(.bottom, 20)
                            } else {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: UIScreen.main.bounds.width * 0.45, height: UIScreen.main.bounds.width * 0.45)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: UIScreen.main.bounds.width * 0.6)
                    .onReceive(timer) { _ in
                        withAnimation {
                            if !carouselSongs.isEmpty {
                                carouselIndex = (carouselIndex + 1) % carouselSongs.count
                            }
                        }
                    }
                }

                // Titles
                Text("👑 Premium")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 30)

                // Features
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(title: "No Limited to View Music Story")
                    FeatureRow(title: "No Limited to View Flowing Emoji")
                    FeatureRow(title: "No Ads")
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)

                // Plans
                HStack(spacing: 20) {
                    if storeManager.products.count >= 2 {
                        let monthProduct = storeManager.products.first { $0.id == "com.wxyapp.mustory.month" }
                        let yearProduct = storeManager.products.first { $0.id == "com.wxyapp.mustory.year" }

                        PlanButton(
                            title: "1 Month",
                            price: monthProduct?.displayPrice ?? "$2.99",
                            subtitle: "/Mon",
                            isSelected: selectedPlan == 0,
                            action: {
                                print("🧾 IAP selected plan=month")
                                selectedPlan = 0
                            }
                        )

                        PlanButton(
                            title: "1 Year",
                            price: yearProduct?.displayPrice ?? "$17.99",
                            subtitle: "/Year",
                            badge: "50% OFF",
                            isSelected: selectedPlan == 1,
                            action: {
                                print("🧾 IAP selected plan=year")
                                selectedPlan = 1
                            }
                        )
                    } else {
                        // 降级兜底展示（如果 StoreKit 没拉到数据）
                        PlanButton(
                            title: "1 Month",
                            price: "$2.99",
                            subtitle: "/Mon",
                            isSelected: selectedPlan == 0,
                            action: {
                                print("🧾 IAP selected fallback plan=month")
                                selectedPlan = 0
                            }
                        )

                        PlanButton(
                            title: "1 Year",
                            price: "$17.99",
                            subtitle: "/Year",
                            badge: "50% OFF",
                            isSelected: selectedPlan == 1,
                            action: {
                                print("🧾 IAP selected fallback plan=year")
                                selectedPlan = 1
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)

                // Continue Button
                Button {
                    handleContinue()
                } label: {
                    ZStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink) // Apple Music style red/pink
                    .cornerRadius(15)
                }
                .disabled(isProcessing)
                .padding(.horizontal, 30)
                .padding(.bottom, 20)

                // Legal & Restore
                HStack(spacing: 15) {
                    Link("Privacy Policy", destination: URL(string: "https://docs.qq.com/doc/DZnFhVnNIeWVSTG1O")!)
                    Text("|").foregroundColor(.gray)
                    Link("Terms of Service", destination: URL(string: "https://docs.qq.com/doc/DZnRrT2R3TWFXY0Rs")!)
                    Text("|").foregroundColor(.gray)
                    Button("Restore Purchase") {
                        handleRestore()
                    }
                }
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            // 8s 后显示关闭按钮
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                withAnimation {
                    showCloseButton = true
                }
            }
        }
        .task {
            // 初始化拉取 StoreKit 产品
            print("🧾 IAP PremiumView task start")
            await storeManager.fetchProducts()
            await storeManager.updatePurchasedProducts()
            print("🧾 IAP PremiumView task end products=\(storeManager.products.map { $0.id }) isPremium=\(storeManager.isPremium)")
        }
        .alert("Purchase Unavailable", isPresented: $showPurchaseAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseMessage)
        }
    }

    // MARK: - Actions
    private func handleContinue() {
        let selectedPlanName = selectedPlan == 0 ? "month" : "year"
        print("🧾 IAP Continue tapped selectedPlan=\(selectedPlanName) currentProducts=\(storeManager.products.map { $0.id })")
        isProcessing = true
        Task {
            if storeManager.products.isEmpty {
                print("🧾 IAP Continue products empty; refetching")
                await storeManager.fetchProducts()
                print("🧾 IAP Continue refetch done products=\(storeManager.products.map { $0.id })")
            }

            let productId = selectedPlan == 0 ? "com.wxyapp.mustory.month" : "com.wxyapp.mustory.year"
            print("🧾 IAP Continue targetProductId=\(productId)")
            guard let product = storeManager.products.first(where: { $0.id == productId }) else {
                print("🧾 IAP Continue abort: target product missing products=\(storeManager.products.map { $0.id })")
                await MainActor.run {
                    purchaseMessage = "Products are still unavailable. Please check the product IDs in App Store Connect and try again."
                    showPurchaseAlert = true
                    isProcessing = false
                }
                return
            }

            print("🧾 IAP Continue calling purchase id=\(product.id)")
            let success = await storeManager.purchase(product)
            print("🧾 IAP Continue purchase completed success=\(success)")
            await MainActor.run {
                isProcessing = false
                if success {
                    dismiss() // 购买成功后自动关闭
                }
            }
        }
    }

    private func handleRestore() {
        print("🧾 IAP Restore tapped")
        isProcessing = true
        Task {
            await storeManager.restorePurchases()
            await MainActor.run {
                isProcessing = false
                print("🧾 IAP Restore UI reset")
            }
        }
    }
}

// Reusable Background Extracted visually from LaunchView
struct LaunchBackgroundView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(white: 0.1)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 还原开机屏的彩色光圈 (去掉了白色的音乐符号)
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.red, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .blur(radius: isAnimating ? 20 : 10)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                }

                // 去掉了 Mustory 文本和 Slogan 文本

                Spacer()
                    .frame(height: 280) // 整体视觉往上提一点，避开底部的订阅按钮
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct FeatureRow: View {
    let title: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium, design: .rounded))
            Spacer()
        }
    }
}

struct PlanButton: View {
    let title: String
    let price: String
    let subtitle: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    // 删掉了 1 Month / 1 Year 文本

                    Text(price)
                        .font(.system(size: 16, weight: .bold, design: .rounded)) // 字号减小 8 像素 (从 24 改为 16)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white.opacity(isSelected ? 0.15 : 0.05))
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
                )

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pink)
                        .cornerRadius(8)
                        .offset(x: 10, y: -10)
                }
            }
        }
    }
}

#Preview {
    PremiumView()
}
