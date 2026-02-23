import SwiftUI

struct SleepSetupView: View {
    let onSleepSet: (SimpleTime, SimpleTime) -> Void
    let onContinue: () -> Void

    @State private var wakeHour = 6
    @State private var wakeMinute = 0
    @State private var bedHour = 22
    @State private var bedMinute = 30
    @State private var mascotState: MascotState = .neutral
    @State private var confirmed = false

    private var sleepHours: Double {
        let bedMinutes = bedHour * 60 + bedMinute
        let wakeMinutes = wakeHour * 60 + wakeMinute
        var diff = wakeMinutes - bedMinutes
        if diff <= 0 { diff += 1440 }
        return Double(diff) / 60.0
    }

    private var mascotComment: String {
        if sleepHours < 5 {
            return "that's \(String(format: "%.1f", sleepHours)) hours of sleep. you need to fix the bedtime too."
        } else if sleepHours < 6.5 {
            return "barely enough. but i'll work with it."
        } else if sleepHours < 8 {
            return "solid. let's lock this in."
        } else {
            return "good sleep schedule. respect."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            AnimatedMascot(state: mascotState, size: 80)
                .padding(.bottom, 8)

            Text("Sleep schedule")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Text("phone goes dark during these hours.")
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .padding(.top, 4)

            // Wake time picker
            VStack(spacing: 20) {
                timeRow(
                    label: "Wake up",
                    icon: "sunrise.fill",
                    hour: $wakeHour,
                    minute: $wakeMinute
                )

                timeRow(
                    label: "Bedtime",
                    icon: "moon.fill",
                    hour: $bedHour,
                    minute: $bedMinute
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)

            // Sleep hours display
            Text(String(format: "%.1f hours of sleep", sleepHours))
                .font(RawDog.Typography.caption)
                .foregroundStyle(sleepHours < 5 ? RawDog.Colors.destructive : RawDog.Colors.textSecondary)
                .padding(.top, 12)

            // Mascot comment
            Text(mascotComment)
                .font(RawDog.Typography.subheadline)
                .foregroundStyle(RawDog.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 8)
                .animation(.easeInOut(duration: 0.2), value: sleepHours)

            Spacer()

            RawDog.PillButton(title: "Lock it in") {
                let wake = SimpleTime(hour: wakeHour, minute: wakeMinute)
                let bed = SimpleTime(hour: bedHour, minute: bedMinute)
                onSleepSet(wake, bed)
                confirmed = true
                mascotState = .proud
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onContinue()
                }
            }
            .padding(.bottom, 40)
        }
        .onChange(of: wakeHour) { updateMascot() }
        .onChange(of: wakeMinute) { updateMascot() }
        .onChange(of: bedHour) { updateMascot() }
        .onChange(of: bedMinute) { updateMascot() }
    }

    private func updateMascot() {
        withAnimation {
            if sleepHours < 5 {
                mascotState = .concerned
            } else if sleepHours < 6.5 {
                mascotState = .sideeye
            } else {
                mascotState = .amused
            }
        }
    }

    private func timeRow(label: String, icon: String, hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(RawDog.Colors.accent)
                .frame(width: 28)

            Text(label)
                .font(RawDog.Typography.headline)
                .foregroundStyle(RawDog.Colors.textPrimary)

            Spacer()

            // Hour picker
            Picker("", selection: hour) {
                ForEach(0..<24, id: \.self) { h in
                    Text(String(format: "%02d", h)).tag(h)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 50, height: 80)
            .clipped()

            Text(":")
                .font(RawDog.Typography.title2)
                .foregroundStyle(RawDog.Colors.textSecondary)

            // Minute picker
            Picker("", selection: minute) {
                ForEach([0, 15, 30, 45], id: \.self) { m in
                    Text(String(format: "%02d", m)).tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 50, height: 80)
            .clipped()
        }
        .padding(16)
        .background(RawDog.Colors.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}
