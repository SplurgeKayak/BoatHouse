import SwiftUI

/// Main content view that handles navigation based on auth state
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            if appState.isLoading {
                LaunchScreenView()
            } else if !appState.isAuthenticated {
                AuthenticationView()
            } else if appState.showOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .task {
            await checkInitialState()
        }
    }

    @MainActor
    private func checkInitialState() async {
        // Show splash for a bit while "loading"
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // For demo purposes, skip auth and show main app with mock data
        appState.currentUser = MockData.racerUser
        appState.isAuthenticated = true
        appState.isLoading = false
    }
}

// MARK: - Animated Launch Screen (Kayak Racing)

struct LaunchScreenView: View {
    @State private var kayakOffset: CGFloat = -200
    @State private var wavePhase: CGFloat = 0
    @State private var sprayOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            // Water gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.35),
                    Color(red: 0.08, green: 0.25, blue: 0.55),
                    Color(red: 0.10, green: 0.35, blue: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Animated water waves (background layer)
            WaterWavesView(phase: wavePhase, amplitude: 12, frequency: 1.2)
                .fill(Color.white.opacity(0.06))
                .offset(y: 120)

            WaterWavesView(phase: wavePhase + 1.5, amplitude: 8, frequency: 1.8)
                .fill(Color.white.opacity(0.08))
                .offset(y: 140)

            WaterWavesView(phase: wavePhase + 3.0, amplitude: 15, frequency: 0.9)
                .fill(Color.white.opacity(0.04))
                .offset(y: 100)

            VStack(spacing: 0) {
                Spacer()

                // App title
                VStack(spacing: 8) {
                    Text("Race Pace")
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .opacity(titleOpacity)

                    Text("Kayak Racing")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(subtitleOpacity)
                }

                Spacer()
                    .frame(height: 60)

                // Kayak animation area
                ZStack {
                    // Spray particles behind kayak
                    SprayParticlesView()
                        .offset(x: kayakOffset - 40, y: -5)
                        .opacity(sprayOpacity)

                    // Kayak silhouette
                    KayakShape()
                        .fill(Color.white)
                        .frame(width: 120, height: 28)
                        .shadow(color: .white.opacity(0.3), radius: 8)
                        .offset(x: kayakOffset)

                    // Wake trail behind kayak
                    WakeTrailView()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 80, height: 10)
                        .offset(x: kayakOffset - 90, y: 8)
                        .opacity(sprayOpacity)
                }
                .frame(height: 60)

                // Animated water surface
                WaterWavesView(phase: wavePhase, amplitude: 10, frequency: 1.5)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 80)

                Spacer()

                // Loading indicator
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Continuous wave animation
        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
            wavePhase = .pi * 2
        }

        // Kayak slides in from left
        withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
            kayakOffset = 0
        }

        // Spray appears once kayak is moving
        withAnimation(.easeIn(duration: 0.5).delay(0.6)) {
            sprayOpacity = 0.6
        }

        // Title fades in
        withAnimation(.easeIn(duration: 0.8).delay(0.2)) {
            titleOpacity = 1.0
        }

        // Subtitle fades in after title
        withAnimation(.easeIn(duration: 0.6).delay(0.6)) {
            subtitleOpacity = 1.0
        }
    }
}

// MARK: - Kayak Shape

struct KayakShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midY = h / 2

        // Kayak hull: pointed bow (right) and stern (left)
        path.move(to: CGPoint(x: 0, y: midY))

        // Top edge: stern to bow
        path.addCurve(
            to: CGPoint(x: w, y: midY),
            control1: CGPoint(x: w * 0.15, y: 0),
            control2: CGPoint(x: w * 0.7, y: h * 0.1)
        )

        // Bottom edge: bow to stern
        path.addCurve(
            to: CGPoint(x: 0, y: midY),
            control1: CGPoint(x: w * 0.7, y: h * 0.9),
            control2: CGPoint(x: w * 0.15, y: h)
        )

        path.closeSubpath()

        // Cockpit opening
        let cockpitX = w * 0.45
        let cockpitW = w * 0.18
        let cockpitH = h * 0.35
        path.addEllipse(in: CGRect(
            x: cockpitX - cockpitW / 2,
            y: midY - cockpitH / 2,
            width: cockpitW,
            height: cockpitH
        ))

        return path
    }
}

// MARK: - Water Waves

struct WaterWavesView: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.midY))

        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = x / rect.width
            let y = rect.midY + sin(relativeX * .pi * 2 * frequency + phase) * amplitude
                + sin(relativeX * .pi * 4 * frequency + phase * 1.3) * (amplitude * 0.3)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Spray Particles

struct SprayParticlesView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: CGFloat.random(in: 2...5))
                    .offset(
                        x: animate ? CGFloat.random(in: -30 ... -10) : 0,
                        y: animate ? CGFloat.random(in: -15...15) : 0
                    )
                    .animation(
                        .easeOut(duration: Double.random(in: 0.5...1.0))
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Wake Trail

struct WakeTrailView: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width, y: rect.midY))

        path.addCurve(
            to: CGPoint(x: 0, y: 0),
            control1: CGPoint(x: rect.width * 0.6, y: rect.midY),
            control2: CGPoint(x: rect.width * 0.3, y: 0)
        )

        path.move(to: CGPoint(x: rect.width, y: rect.midY))

        path.addCurve(
            to: CGPoint(x: 0, y: rect.height),
            control1: CGPoint(x: rect.width * 0.6, y: rect.midY),
            control2: CGPoint(x: rect.width * 0.3, y: rect.height)
        )

        return path
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AuthViewModel())
}
