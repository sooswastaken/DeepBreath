import AVFoundation

@Observable
final class AudioService {
    var isVoiceEnabled: Bool {
        didSet { UserDefaults.standard.set(isVoiceEnabled, forKey: "voiceEnabled") }
    }

    private let synthesizer = AVSpeechSynthesizer()

    // Shared background keep-alive player.
    // Loops a programmatically generated silent WAV so the audio session stays
    // active while the screen is locked, which prevents iOS from suspending the app.
    private static var keepAlivePlayer: AVAudioPlayer?
    private static var keepAliveRefCount = 0

    init() {
        self.isVoiceEnabled = UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool ?? true
        AudioService.configureSession()
    }

    // MARK: - Audio Session

    private static func configureSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {}
        #endif
    }

    // MARK: - Background Keep-Alive

    func startKeepAlive() {
        AudioService.keepAliveRefCount += 1
        guard AudioService.keepAliveRefCount == 1 else { return }

        guard let data = AudioService.makeSilentWAV(),
              let player = try? AVAudioPlayer(data: data, fileTypeHint: AVFileType.wav.rawValue)
        else { return }

        player.numberOfLoops = -1  // loop forever
        player.volume = 0.01       // inaudible but non-zero so iOS counts it as active
        player.prepareToPlay()
        player.play()
        AudioService.keepAlivePlayer = player
    }

    func stopKeepAlive() {
        AudioService.keepAliveRefCount = max(0, AudioService.keepAliveRefCount - 1)
        guard AudioService.keepAliveRefCount == 0 else { return }
        AudioService.keepAlivePlayer?.stop()
        AudioService.keepAlivePlayer = nil
    }

    // Generates a 1-second mono 16-bit 44.1 kHz WAV with silence.
    private static func makeSilentWAV() -> Data? {
        let sampleRate: Int32 = 44100
        let numSamples: Int32 = sampleRate   // 1 second
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate: Int32 = sampleRate * Int32(numChannels) * Int32(bitsPerSample / 8)
        let blockAlign: Int16 = numChannels * (bitsPerSample / 8)
        let dataSize: Int32 = numSamples * Int32(blockAlign)
        let riffSize: Int32 = 36 + dataSize

        var wav = Data()
        func appendLE<T: FixedWidthInteger>(_ v: T) {
            var le = v.littleEndian
            wav.append(contentsOf: withUnsafeBytes(of: &le) { Array($0) })
        }
        wav.append(contentsOf: Array("RIFF".utf8))
        appendLE(riffSize)
        wav.append(contentsOf: Array("WAVE".utf8))
        wav.append(contentsOf: Array("fmt ".utf8))
        appendLE(Int32(16))        // fmt chunk size
        appendLE(Int16(1))         // PCM
        appendLE(numChannels)
        appendLE(sampleRate)
        appendLE(byteRate)
        appendLE(blockAlign)
        appendLE(bitsPerSample)
        wav.append(contentsOf: Array("data".utf8))
        appendLE(dataSize)
        wav.append(Data(count: Int(dataSize)))  // silence
        return wav
    }

    // MARK: - Speech

    func speak(_ text: String) {
        guard isVoiceEnabled else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.45
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.pitchMultiplier = 1.1
        synthesizer.speak(utterance)
    }

    func announceRound(_ round: Int, of total: Int) {
        speak("Round \(round) of \(total)")
    }

    func announceHold() {
        speak("Breathe in deeply. Hold.")
    }

    func announceRest() {
        speak("Breathe out. Rest.")
    }

    func announceCountdown(_ seconds: Int) {
        guard seconds <= 3, seconds > 0 else { return }
        speak("\(seconds)")
    }

    func announceComplete() {
        speak("Session complete. Great work!")
    }
}
