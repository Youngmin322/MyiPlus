//
//  AudioEngineService.swift
//  MyiApp
//
//  Created by 조영민 on 5/20/25.
//

import Foundation
import AVFoundation
import Accelerate

final class AudioEngineService {
    
    // MARK: - Public Properties
    // 외부에 FTT 이퀄라이저 값이나 PCM 샘플 배열을 전달할 때 사용되는 클로저
    var audioLevelsHandler: (([Float]) -> Void)?
    var bufferHandler: (([Float]) -> Void)?
    
    // MARK: - Private Properties
    private let fftBarCount = 8 // FFT 그래프 바 개수
    private let fftNormalizationFactor: Float = 5000.0 // FFT 스케일 조정
    private let sampleRate: Double = 22050 // PCM 버퍼 변환 시 사용할 고정 샘플레이트
    
    // 오디오 캡쳐를 위한 객체
    private var engine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var converter: AVAudioConverter?
    
    // MARK: - Public Methods
    // 마이크 권한 요청 및 권한에 따라 녹음 시작 또는 실패 처리
    func startRecording(onPermissionResult: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission() { granted in
            DispatchQueue.main.async {
                self.handlePermissionResult(granted, onPermissionResult: onPermissionResult) // 권한 허용 여부를 클로저로 전달
            }
        }
    }
    
    // 음성 권한이 허용되면 오디오 세션 설정, AVAudioEngine 설정, 녹음 시작을 하는 함수(실패하거나 거부 시 실패 반환)
    private func handlePermissionResult(_ granted: Bool, onPermissionResult: @escaping (Bool) -> Void) {
        if granted { // granted: 마이크 권한 허용 여부
            do {
                try self.configureAudioSession()
                try self.configureEngine()
                try self.engine?.start()
                onPermissionResult(true)
            } catch {
                print("Failed to start recording: \(error)")
                onPermissionResult(false)
            }
        } else {
            print("Microphone permission denied.")
            onPermissionResult(false)
        }
    }
    
    // 녹음 중단, 리소스 해제(engine, inputNode, tap 제거)
    func stopRecording() {
        inputNode?.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        inputNode = nil
    }
    
    // MARK: - Private Methods
    
    //오디오 세션 설정 및 활성화
    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .default)
        try session.setActive(true)
    }
    
    // AVAduioEngine 초기화 및 입력 노드에 Tap 설치
    // 입력 오디오를 지정된 포맷으로 변환하고 FFT 및 PCM 처리 진행
    private func configureEngine() throws {
        engine = AVAudioEngine()
        guard let engine = engine else { throw NSError(domain: "AudioEngineInit", code: -1) }
        
        inputNode = engine.inputNode
        let inputFormat = inputNode!.outputFormat(forBus: 0)
        let outputFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: sampleRate,
                                         channels: 1,
                                         interleaved: false)!
        
        converter = AVAudioConverter(from: inputFormat, to: outputFormat)
        
        inputNode!.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in // 1024 프레임 단위로 input
            let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
            let avg = samples.reduce(0, +) / Float(samples.count)
            print("[AudioService] 버퍼 수신: \(samples.count)개, 평균값: \(avg)")
            self?.processBuffer(buffer, inputFormat: inputFormat, outputFormat: outputFormat)
        }
    }
    
    // 수신된 AVAudioPCMBuffer를 FFT 및 PCM 샘플로 처리하는 ㅎ함수
    private func processBuffer(_ buffer: AVAudioPCMBuffer,
                               inputFormat: AVAudioFormat,
                               outputFormat: AVAudioFormat) {
        // FTT 기반 이퀄라이저 값을 계산 후 전달
        let levels = fftFromBuffer(buffer)
        DispatchQueue.main.async {
            self.audioLevelsHandler?(levels)
        }
        
        // 출력 포맷으로 변환 후, Float 32 PCM 샘플을 클로저로 전달
        guard let converter = converter else { return }
        
        // 출력 포맷에 맞는 새 버퍼 생성
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat,
                                               frameCapacity: buffer.frameCapacity)!
        // 변환 입력 블록 정의(AVAudioConverter가 데이터를 요청할 때마다 호출)
        // convertedBuffer에 변환된 Float32 PCM이 들어감(성공하면 .haveData 반환)
        let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        let status = converter.convert(to: convertedBuffer, error: nil, withInputFrom: inputBlock)
        
        // Float32 샘플 전달
        // UnsafeBufferPointer로 Swift 배열로 복사 후 bufferHandler 클로저를 통해 외부로 전달
        if status == .haveData, let floatData = convertedBuffer.floatChannelData?[0] {
            let samples = Array(UnsafeBufferPointer(start: floatData, count: Int(convertedBuffer.frameLength)))
            DispatchQueue.main.async {
                self.bufferHandler?(samples)
            }
        }
    }
    
    // MARK: - FFT Equalizer
    // 오디오 버퍼를 받아서 FFT 기반 이퀄라이저 바 8개를 계산하는 함수
    private func fftFromBuffer(_ buffer: AVAudioPCMBuffer) -> [Float] {
        // 사전 작업
        // FFT는 2의 제곱수 단위로 계산되므로 log2(frameCount) 필요
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return Array(repeating: 0.0, count: fftBarCount) }
        
        let log2n = vDSP_Length(log2(Float(frameCount)))
        
        // FTT 세팅 준비
        // Accelerate의 FTT 세션 준비 및 defer로 해제 예약(메모리 누수 방지용)
        guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else {
            return Array(repeating: 0.0, count: fftBarCount)
        }
        defer { vDSP_destroy_fftsetup(fftSetup) }
        
        guard let channelData = buffer.floatChannelData?[0] else {
            return Array(repeating: 0.0, count: fftBarCount)
        }
        
        var window = [Float](repeating: 0.0, count: frameCount)
        var windowedSignal = [Float](repeating: 0.0, count: frameCount)
        
        // Hann Window 함수 적용(FFT 스펙트럼 누설 방지
        vDSP_hann_window(&window, vDSP_Length(frameCount), Int32(vDSP_HANN_NORM))
        vDSP_vmul(channelData, 1, window, 1, &windowedSignal, 1, vDSP_Length(frameCount)) // vDSP_vmul: 각 샘플 x 윈도우 값
        
        var real = [Float](repeating: 0, count: frameCount / 2) // FFT 실수부
        var imag = [Float](repeating: 0, count: frameCount / 2) // FFT 허수부
        var magnitudes = [Float](repeating: 0, count: frameCount / 2) // FFT 결과 제곱 크기
        var normalizedMagnitudes = [Float](repeating: 0, count: fftBarCount) // 이퀄라이저 바용 정규화된 값
        
        real.withUnsafeMutableBufferPointer { realPtr in
            imag.withUnsafeMutableBufferPointer { imagPtr in
                var splitComplex = DSPSplitComplex(realp: realPtr.baseAddress!, imagp: imagPtr.baseAddress!)
                windowedSignal.withUnsafeBufferPointer {
                    $0.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: frameCount) {
                        vDSP_ctoz($0, 2, &splitComplex, 1, vDSP_Length(frameCount / 2)) // 실수 -> 복소수 변환, interleaved signal을 DSPSplitComplex로 분리
                    }
                }
                vDSP_fft_zrip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD)) // 실제 FFT 수행, real FFT 수행 (zrip = zipped real input, packed format)
                vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(frameCount / 2)) // 복소수 -> 제곱 크기 (Magnitude^2), 각 주파수 bin의 magnitude^2 계산
            }
        }
        
        // FFT 결과를 fftbarCount 개수로 나누고 각 구간 평균을 RMS 형태로 계산 후 정규화
        let step = magnitudes.count / fftBarCount
        for i in 0..<fftBarCount {
            let slice = magnitudes[i * step ..< min((i + 1) * step, magnitudes.count)]
            let avg = slice.reduce(0, +) / Float(slice.count) // FFT 결과를 fftBarCount(8개)로 나눔
            normalizedMagnitudes[i] = min(1.0, pow(avg, 0.5) / fftNormalizationFactor) // 각 조각에 대해 RMS 형태로 계산
        }
        
        return normalizedMagnitudes
    }
}
