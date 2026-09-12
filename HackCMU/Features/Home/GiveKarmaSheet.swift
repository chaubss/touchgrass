import SwiftUI
import UIKit

/// One scrolling sheet rather than a wizard — you can see the whole shape of
/// what you're about to do, and change your mind about any part of it.
struct GiveKarmaSheet: View {
    @Environment(KarmaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let onGiven: (String) -> Void

    @State private var query = ""
    @State private var recipient: Student?
    @State private var amount = 25
    @State private var category: KarmaCategory = .debugging
    @State private var reason = ""
    @State private var isPublic = true

    @State private var dictation = ElevenLabsDictationService()
    @State private var speech: SpeechService = ElevenLabsSpeechService()
    @State private var isRecording = false
    @State private var isSpeaking = false
    @State private var toast: Toast?

    private var trimmedReason: String {
        reason.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var matches: [Student] {
        let pool = store.students.filter { $0.id != store.currentUserID }
        guard !query.isEmpty else { return Array(pool.prefix(6)) }
        let q = query.lowercased()
        return pool.filter {
            $0.fullName.lowercased().contains(q) || $0.andrewID.lowercased().contains(q)
        }
    }

    private var block: KarmaStore.GiveBlock? {
        recipient.flatMap { store.giveBlock(for: $0.id) }
    }

    private var isValid: Bool {
        recipient != nil
            && block == nil
            && store.canAfford(amount: amount)
            && KarmaRules.reasonRange.contains(trimmedReason.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    recipientSection
                    if recipient != nil {
                        amountSection
                        categorySection
                        reasonSection
                        visibilitySection
                    }
                }
                .padding(.horizontal, Metrics.gutter)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .paperBackground()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Give karma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Palette.ash)
                }
            }
            .safeAreaInset(edge: .bottom) { confirmBar }
            .toast($toast)
        }
    }

    // MARK: - Sections

    private var recipientSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Who")

            if let recipient {
                HStack(spacing: 12) {
                    AvatarView(initials: recipient.initials, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipient.fullName)
                            .font(.uiBodyMedium)
                            .foregroundStyle(Palette.ink)
                        Text("\(recipient.andrewID), \(recipient.program)")
                            .font(.uiCaption)
                            .foregroundStyle(Palette.ash)
                    }
                    Spacer()
                    Button("Change") {
                        withAnimation(.easeOut(duration: 0.2)) { self.recipient = nil }
                    }
                    .font(.uiLabel)
                    .foregroundStyle(Palette.tartan)
                }
                .padding(14)
                .cardSurface()

                if let block {
                    Label(block.message, systemImage: "clock")
                        .font(.uiCaption)
                        .foregroundStyle(Palette.tartan)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Palette.ash)
                    TextField("Name or Andrew ID", text: $query)
                        .font(.uiBody)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 14)
                .frame(height: 46)
                .cardSurface(radius: 12)

                VStack(spacing: 0) {
                    ForEach(matches) { student in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                recipient = student
                                query = ""
                            }
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(initials: student.initials, size: 36)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(student.fullName)
                                        .font(.uiBody)
                                        .foregroundStyle(Palette.ink)
                                    Text("\(student.andrewID), \(student.program)")
                                        .font(.uiCaption)
                                        .foregroundStyle(Palette.ash)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                    if matches.isEmpty {
                        Text("No one matches \"\(query)\". Try an Andrew ID.")
                            .font(.uiLabel)
                            .foregroundStyle(Palette.ash)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 18)
                    }
                }
            }
        }
    }

    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "How much",
                          trailing: "\(store.currentUser.allowanceRemaining) left this month")

            HStack(spacing: 8) {
                ForEach(KarmaRules.quickAmounts, id: \.self) { value in
                    let affordable = store.canAfford(amount: value)
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { amount = value }
                    } label: {
                        Chip(title: value.formatted(), isSelected: amount == value, isEnabled: affordable)
                    }
                    .buttonStyle(.plain)
                    .disabled(!affordable)
                }
                Spacer()
            }

            HStack {
                KarmaAmountText(value: amount, size: 28)
                Stepper("") {
                    amount = min(KarmaRules.maxGrant, amount + 5)
                } onDecrement: {
                    amount = max(KarmaRules.minGrant, amount - 5)
                }
                .labelsHidden()
            }

            if !store.canAfford(amount: amount) {
                Text("That's more than your allowance. You have \(store.currentUser.allowanceRemaining) left.")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.tartan)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What for")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(KarmaCategory.allCases) { option in
                        Button {
                            withAnimation(.easeOut(duration: 0.2)) { category = option }
                        } label: {
                            Chip(title: option.label, isSelected: category == option)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Say why",
                          trailing: "\(trimmedReason.count)/\(KarmaRules.reasonRange.upperBound)")

            TextEditor(text: $reason)
                .font(.uiBody)
                .scrollContentBackground(.hidden)
                .frame(height: 104)
                .padding(10)
                .cardSurface(radius: 12)
                .overlay(alignment: .topLeading) {
                    if reason.isEmpty {
                        Text("Be specific. \"Stayed until the build was green\" beats \"thanks!\"")
                            .font(.uiBody)
                            .foregroundStyle(Palette.ash.opacity(0.8))
                            .padding(.horizontal, 15)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: reason) { _, new in
                    if new.count > KarmaRules.reasonRange.upperBound {
                        reason = String(new.prefix(KarmaRules.reasonRange.upperBound))
                    }
                }

            if !trimmedReason.isEmpty && trimmedReason.count < KarmaRules.reasonRange.lowerBound {
                Text("A few more words — at least \(KarmaRules.reasonRange.lowerBound) characters.")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }

            HStack(spacing: 16) {
                Button(action: toggleDictation) {
                    Label(isRecording ? "Stop" : "Dictate",
                          systemImage: isRecording ? "waveform.circle.fill" : "mic")
                }
                .foregroundStyle(isRecording ? Palette.tartan : Palette.ash)

                Button(action: toggleReadBack) {
                    Label(isSpeaking ? "Stop" : "Read back",
                          systemImage: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                }
                .foregroundStyle(isSpeaking ? Palette.tartan : Palette.ash)
                .disabled(trimmedReason.isEmpty)

                Spacer()

                Text("via ElevenLabs")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash.opacity(0.7))
            }
            .font(.uiCaption.weight(.semibold))
            .buttonStyle(.plain)
        }
    }

    private func toggleDictation() {
        if isRecording {
            isRecording = false
            Task {
                do {
                    let transcript = try await dictation.stopRecordingAndTranscribe()
                    let combined = [trimmedReason, transcript]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    withAnimation(.easeOut(duration: 0.2)) {
                        reason = String(combined.prefix(KarmaRules.reasonRange.upperBound))
                    }
                } catch {
                    toast = Toast(message: error.localizedDescription, symbol: "exclamationmark.triangle")
                }
            }
        } else {
            do {
                try dictation.startRecording()
                isRecording = true
            } catch {
                toast = Toast(message: "Couldn't access the microphone.", symbol: "exclamationmark.triangle")
            }
        }
    }

    private func toggleReadBack() {
        if isSpeaking {
            speech.stop()
            isSpeaking = false
        } else {
            isSpeaking = true
            speech.speak(trimmedReason) { isSpeaking = false }
        }
    }

    private var visibilitySection: some View {
        Toggle(isOn: $isPublic) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Share publicly")
                    .font(.uiBody)
                    .foregroundStyle(Palette.ink)
                Text(isPublic
                     ? "This appears in Explore for everyone to see."
                     : "Only the two of you will see this.")
                    .font(.uiCaption)
                    .foregroundStyle(Palette.ash)
            }
        }
        .tint(Palette.tartan)
    }

    private var confirmBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(Palette.rule)
            Button(recipient == nil ? "Give karma" : "Give \(amount) karma") {
                guard let recipient else { return }
                let ok = store.give(to: recipient.id, amount: amount, category: category,
                                    reason: trimmedReason, isPublic: isPublic)
                if ok {
                    let name = recipient.fullName.split(separator: " ").first.map(String.init) ?? recipient.fullName
                    dismiss()
                    onGiven(name)
                }
            }
            .buttonStyle(FilledButtonStyle())
            .disabled(!isValid)
            .padding(.horizontal, Metrics.gutter)
            .padding(.top, 12)
            .padding(.bottom, 8)
        }
        .background(Palette.paper)
    }
}
