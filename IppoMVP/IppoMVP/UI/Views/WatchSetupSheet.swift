import SwiftUI
import WatchConnectivity

struct WatchSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var watchConnectivity: WatchConnectivityService

    @State private var pollTimer: Timer?
    @State private var showSuccessState = false
    @State private var autoDismissTask: Task<Void, Never>?

    private var watchReady: Bool {
        watchConnectivity.isPaired && watchConnectivity.isWatchAppInstalled
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroSection
                    statusSection
                    if !watchReady {
                        instructionsSection
                        troubleshootingSection
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background {
                ParchmentBackground(showVineBorder: false)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.accent)
                }
            }
            .onAppear { startPolling() }
            .onDisappear { stopPolling() }
            .onChange(of: watchReady) { _, ready in
                if ready { handleWatchReady() }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(watchReady ? AppColors.success.opacity(0.15) : AppColors.accent.opacity(0.1))
                    .frame(width: 88, height: 88)

                Image(systemName: watchReady ? "checkmark.circle.fill" : "applewatch")
                    .font(.system(size: 44))
                    .foregroundColor(watchReady ? AppColors.success : AppColors.accent)
                    .symbolEffect(.bounce, value: showSuccessState)
            }

            Text(watchReady ? "Watch Connected!" : "Set Up Your Apple Watch")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text(watchReady
                 ? "You're all set to start running with Ippo!"
                 : "Install Ippo on your Apple Watch to start running and catching pets.")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 14) {
            statusRow(
                title: "Apple Watch Paired",
                isOK: watchConnectivity.isPaired,
                helpText: "Pair your Watch in the Watch app on your iPhone"
            )
            Divider().padding(.horizontal, 4)
            statusRow(
                title: "Ippo Installed on Watch",
                isOK: watchConnectivity.isWatchAppInstalled,
                helpText: "Follow the steps below to install"
            )
        }
        .padding(18)
        .background(AppColors.surface)
        .cornerRadius(16)
    }

    private func statusRow(title: String, isOK: Bool, helpText: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isOK ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 24))
                .foregroundColor(isOK ? AppColors.success : AppColors.textTertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                if !isOK {
                    Text(helpText)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            Spacer()
        }
    }

    // MARK: - Instructions

    private var instructionsSection: some View {
        VStack(spacing: 16) {
            Text("How to Install")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            instructionStep(
                number: 1,
                icon: "applewatch",
                text: "Open the **Watch** app on your iPhone"
            )
            instructionStep(
                number: 2,
                icon: "arrow.down.app",
                text: "Scroll down to **Available Apps**"
            )
            instructionStep(
                number: 3,
                icon: "arrow.down.circle",
                text: "Find **Ippo** and tap **Install**"
            )

            Button { openWatchApp() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 15))
                    Text("Open Watch App")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.accent)
                .cornerRadius(14)
            }
            .padding(.top, 4)
        }
    }

    private func instructionStep(number: Int, icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.accent)
                    .frame(width: 30, height: 30)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 24)

                Text(LocalizedStringKey(text))
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.surface)
        .cornerRadius(12)
    }

    // MARK: - Troubleshooting

    private var troubleshootingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                Text("Don't see Ippo in Available Apps?")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                troubleshootItem("In the Watch app, go to **General** > **Automatic App Install** and turn it on")
                troubleshootItem("Or open the **App Store** on your Apple Watch and search for **Ippo**")
                troubleshootItem("Make sure your Apple Watch is nearby, charged, and connected to Wi-Fi")
            }
        }
        .padding(16)
        .background(AppColors.surfaceElevated.opacity(0.6))
        .cornerRadius(14)
    }

    private func troubleshootItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textTertiary)
            Text(LocalizedStringKey(text))
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    // MARK: - Actions

    private func openWatchApp() {
        if let url = URL(string: "itms-watchs://bridge:root=GENERAL_LINK"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let url = URL(string: "itms-watchs://") {
            UIApplication.shared.open(url)
        }
    }

    private func startPolling() {
        watchConnectivity.refreshStatus()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task { @MainActor in
                watchConnectivity.refreshStatus()
            }
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        autoDismissTask?.cancel()
    }

    private func handleWatchReady() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccessState = true
        }
        pollTimer?.invalidate()
        pollTimer = nil

        autoDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }
}
