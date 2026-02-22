import SwiftUI

// MARK: - Mascot States

enum MascotState {
    case neutral   // default, watching
    case sideeye   // judging you (extension request, trying to cheat)
    case proud     // you completed a good streak, restrictions active
}

// MARK: - RawDogMascot View

struct RawDogMascot: View {
    let state: MascotState
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            // Glow circle behind mascot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [glowColor.opacity(0.3), glowColor.opacity(0)],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.55
                    )
                )
                .frame(width: size * 1.1, height: size * 1.1)

            // Mascot body
            ShibaShape(state: state)
                .frame(width: size, height: size)
        }
    }

    private var glowColor: Color {
        switch state {
        case .neutral: RawDog.Colors.accent
        case .sideeye: RawDog.Colors.windowClosed
        case .proud: RawDog.Colors.approved
        }
    }
}

// MARK: - Shiba Shape (SwiftUI drawn)

private struct ShibaShape: View {
    let state: MascotState

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let cx = w / 2

            // --- Ears ---
            drawEar(context: context, cx: cx, w: w, h: h, isLeft: true)
            drawEar(context: context, cx: cx, w: w, h: h, isLeft: false)

            // --- Head ---
            let headRect = CGRect(x: w * 0.15, y: h * 0.22, width: w * 0.7, height: h * 0.65)
            let headPath = Path(roundedRect: headRect, cornerRadius: w * 0.25)
            context.fill(headPath, with: .color(Color(hex: "F5C16C")))  // golden shiba

            // --- Inner face (cream) ---
            let faceRect = CGRect(x: w * 0.22, y: h * 0.38, width: w * 0.56, height: h * 0.46)
            let facePath = Path(roundedRect: faceRect, cornerRadius: w * 0.2)
            context.fill(facePath, with: .color(Color(hex: "FFF3D6")))  // cream

            // --- Eyes ---
            drawEyes(context: context, cx: cx, w: w, h: h)

            // --- Nose ---
            let noseSize = w * 0.06
            let noseRect = CGRect(x: cx - noseSize / 2, y: h * 0.62, width: noseSize, height: noseSize * 0.8)
            let nosePath = Path(ellipseIn: noseRect)
            context.fill(nosePath, with: .color(Color(hex: "2C2C2E")))

            // --- Mouth ---
            drawMouth(context: context, cx: cx, w: w, h: h)

            // --- Cheeks (blush) ---
            if state == .proud {
                let blushSize = w * 0.08
                let leftBlush = CGRect(x: w * 0.22, y: h * 0.58, width: blushSize, height: blushSize * 0.6)
                let rightBlush = CGRect(x: w * 0.7, y: h * 0.58, width: blushSize, height: blushSize * 0.6)
                context.fill(Path(ellipseIn: leftBlush), with: .color(Color.pink.opacity(0.35)))
                context.fill(Path(ellipseIn: rightBlush), with: .color(Color.pink.opacity(0.35)))
            }
        }
    }

    private func drawEar(context: GraphicsContext, cx: CGFloat, w: CGFloat, h: CGFloat, isLeft: Bool) {
        let earWidth = w * 0.22
        let earHeight = h * 0.3
        let earX = isLeft ? (cx - w * 0.28) : (cx + w * 0.06)
        let earY = h * 0.08

        var earPath = Path()
        earPath.move(to: CGPoint(x: earX, y: earY + earHeight))
        earPath.addLine(to: CGPoint(x: earX + earWidth / 2, y: earY))
        earPath.addLine(to: CGPoint(x: earX + earWidth, y: earY + earHeight))
        earPath.closeSubpath()
        context.fill(earPath, with: .color(Color(hex: "F5C16C")))

        // Inner ear
        let innerScale: CGFloat = 0.6
        let innerW = earWidth * innerScale
        let innerH = earHeight * innerScale
        let innerX = earX + (earWidth - innerW) / 2
        let innerY = earY + earHeight * 0.18

        var innerPath = Path()
        innerPath.move(to: CGPoint(x: innerX, y: innerY + innerH))
        innerPath.addLine(to: CGPoint(x: innerX + innerW / 2, y: innerY))
        innerPath.addLine(to: CGPoint(x: innerX + innerW, y: innerY + innerH))
        innerPath.closeSubpath()
        context.fill(innerPath, with: .color(Color(hex: "FFAD85")))
    }

    private func drawEyes(context: GraphicsContext, cx: CGFloat, w: CGFloat, h: CGFloat) {
        let eyeY = h * 0.48
        let eyeSpacing = w * 0.13
        let eyeSize = w * 0.07

        switch state {
        case .neutral:
            // Round eyes
            let leftEye = CGRect(x: cx - eyeSpacing - eyeSize / 2, y: eyeY, width: eyeSize, height: eyeSize)
            let rightEye = CGRect(x: cx + eyeSpacing - eyeSize / 2, y: eyeY, width: eyeSize, height: eyeSize)
            context.fill(Path(ellipseIn: leftEye), with: .color(Color(hex: "2C2C2E")))
            context.fill(Path(ellipseIn: rightEye), with: .color(Color(hex: "2C2C2E")))

            // Eye shine
            let shineSize = eyeSize * 0.35
            let leftShine = CGRect(x: cx - eyeSpacing - eyeSize / 2 + eyeSize * 0.2, y: eyeY + eyeSize * 0.15, width: shineSize, height: shineSize)
            let rightShine = CGRect(x: cx + eyeSpacing - eyeSize / 2 + eyeSize * 0.2, y: eyeY + eyeSize * 0.15, width: shineSize, height: shineSize)
            context.fill(Path(ellipseIn: leftShine), with: .color(.white.opacity(0.8)))
            context.fill(Path(ellipseIn: rightShine), with: .color(.white.opacity(0.8)))

        case .sideeye:
            // Left eye: half-lid skeptical, pupil shifted right
            let leftEye = CGRect(x: cx - eyeSpacing - eyeSize / 2, y: eyeY + eyeSize * 0.2, width: eyeSize, height: eyeSize * 0.6)
            context.fill(Path(ellipseIn: leftEye), with: .color(Color(hex: "2C2C2E")))

            // Right eye: normal but pupil shifted right (looking sideways)
            let rightEye = CGRect(x: cx + eyeSpacing - eyeSize / 2 + eyeSize * 0.15, y: eyeY, width: eyeSize, height: eyeSize)
            context.fill(Path(ellipseIn: rightEye), with: .color(Color(hex: "2C2C2E")))

            let shineSize = eyeSize * 0.3
            let rightShine = CGRect(x: cx + eyeSpacing + eyeSize * 0.1, y: eyeY + eyeSize * 0.15, width: shineSize, height: shineSize)
            context.fill(Path(ellipseIn: rightShine), with: .color(.white.opacity(0.8)))

        case .proud:
            // Happy closed eyes (upward curves)
            let strokeStyle = StrokeStyle(lineWidth: w * 0.025, lineCap: .round)

            var leftArc = Path()
            leftArc.addArc(
                center: CGPoint(x: cx - eyeSpacing, y: eyeY + eyeSize * 0.5),
                radius: eyeSize * 0.5,
                startAngle: .degrees(200),
                endAngle: .degrees(340),
                clockwise: false
            )
            context.stroke(leftArc, with: .color(Color(hex: "2C2C2E")), style: strokeStyle)

            var rightArc = Path()
            rightArc.addArc(
                center: CGPoint(x: cx + eyeSpacing, y: eyeY + eyeSize * 0.5),
                radius: eyeSize * 0.5,
                startAngle: .degrees(200),
                endAngle: .degrees(340),
                clockwise: false
            )
            context.stroke(rightArc, with: .color(Color(hex: "2C2C2E")), style: strokeStyle)
        }
    }

    private func drawMouth(context: GraphicsContext, cx: CGFloat, w: CGFloat, h: CGFloat) {
        let mouthY = h * 0.67
        let strokeStyle = StrokeStyle(lineWidth: w * 0.018, lineCap: .round)

        switch state {
        case .neutral:
            // Small "w" mouth
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - w * 0.06, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: cx, y: mouthY + h * 0.02),
                control: CGPoint(x: cx - w * 0.03, y: mouthY + h * 0.03)
            )
            mouth.addQuadCurve(
                to: CGPoint(x: cx + w * 0.06, y: mouthY),
                control: CGPoint(x: cx + w * 0.03, y: mouthY + h * 0.03)
            )
            context.stroke(mouth, with: .color(Color(hex: "2C2C2E")), style: strokeStyle)

        case .sideeye:
            // Flat line, slightly disapproving
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - w * 0.06, y: mouthY))
            mouth.addLine(to: CGPoint(x: cx + w * 0.06, y: mouthY - h * 0.005))
            context.stroke(mouth, with: .color(Color(hex: "2C2C2E")), style: strokeStyle)

        case .proud:
            // Big smile
            var mouth = Path()
            mouth.addArc(
                center: CGPoint(x: cx, y: mouthY - h * 0.01),
                radius: w * 0.07,
                startAngle: .degrees(10),
                endAngle: .degrees(170),
                clockwise: false
            )
            context.stroke(mouth, with: .color(Color(hex: "2C2C2E")), style: strokeStyle)
        }
    }
}

// MARK: - Preview

#Preview("Mascot States") {
    HStack(spacing: 32) {
        VStack {
            RawDogMascot(state: .neutral)
            Text("Neutral").font(.caption)
        }
        VStack {
            RawDogMascot(state: .sideeye)
            Text("Side-eye").font(.caption)
        }
        VStack {
            RawDogMascot(state: .proud)
            Text("Proud").font(.caption)
        }
    }
    .padding()
    .background(Color.black)
    .foregroundStyle(.white)
}
