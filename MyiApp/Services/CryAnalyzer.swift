//
//  CryAnalyzer.swift
//  MyiApp
//
//  Created by 조영민 on 5/20/25.
//

import Foundation
import CoreML
import Accelerate
import AVFAudio

final class CryAnalyzer {
    
    // MARK: - Constants
    // CoreML 모델에 필요한 고정 입력 길이. 7초간 22.05kHz로 녹음된 데이터 기준 약 15600 샘플
    private let mfccTargetSampleCount = 15600 // Core ML 모델에 넣을 입력 데이터 샘플 수
    private let model: DeepInfant_V2
    // 무음 상태가 얼마나 지속되고 있는지 판단하기 위한 시간 기록 변수
    private var silenceStartTime: Date?
    
    // MARK: - Init
    // 앱이 시작되면 Core ML 모델을 로딩
    init() {
        do {
            self.model = try DeepInfant_V2(configuration: MLModelConfiguration())
        } catch {
            fatalError("CoreML 모델 로드 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Method
    
    // 녹음된 오디오 샘플을 받아 감정 분석 수행
    // - Parameters:
    //   - samples: 음성 데이터 (Float 배열)
    //   - completion: 분석 결과(EmotionResult?)를 반환하는 비동기 클로저
    func analyze(from samples: [Float], completion: @escaping (EmotionResult?) -> Void) {
        print("[CryAnalyzer] 분석 시작")
        print("[CryAnalyzer] 분석 시작: 입력 샘플 수 = \(samples.count)")
        
        let processedSamples = prepareSamples(samples) // 샘플 보정
        
        // 무음 판별 로직 추가
        if isSilent(samples: processedSamples) {
            if silenceStartTime == nil {
                silenceStartTime = Date()
            }
            
            let silenceDuration = Date().timeIntervalSince(silenceStartTime!)
            print("[CryAnalyzer] 무음 감지됨 (지속시간: \(silenceDuration))")
            let result = EmotionResult(type: .unknown, confidence: 0.0)
            completion(result)
            return
        } else {
            silenceStartTime = nil
        }
        
        guard let inputArray = createMLMultiArray(from: processedSamples) else {
            print("[CryAnalyzer] MLMultiArray 생성 실패")
            completion(nil)
            return
        }
        
        print("[CryAnalyzer] MLMultiArray 구성 완료")
        
        do {
            let input = DeepInfant_V2Input(audioSamples: inputArray)
            let output = try model.prediction(input: input)
            
            print("[CryAnalyzer] 전체 예측 확률:")
            for (label, prob) in output.targetProbability {
                print(" - \(label): \(prob)")
            }
            
            let label = output.target
            let confidence = output.targetProbability[label] ?? 0.0
            
            // confidence가 낮으면 unknown 처리
            if confidence < 0.5 {
                print("[CryAnalyzer] 예측 신뢰도 낮음 (\(confidence)), unknown 반환")
                let result = EmotionResult(type: .unknown, confidence: confidence)
                completion(result)
                return
            }
            
            let result = EmotionResult(
                type: EmotionType(rawValue: label) ?? .unknown,
                confidence: confidence
            )
            print("[CryAnalyzer] 분석 결과: \(label) (\(confidence))")
            completion(result)
            
        } catch {
            print("모델 추론 실패: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // 입력 샘플 수를 모델 입력에 맞게 자르거나 0으로 패딩하는 함수
    private func prepareSamples(_ samples: [Float]) -> [Float] {
        let trimmed = Array(samples.prefix(mfccTargetSampleCount))
        let padding = Array(repeating: Float(0.0), count: max(0, mfccTargetSampleCount - trimmed.count))
        let result = trimmed + padding
        print("[CryAnalyzer] 입력 샘플 보정 완료 (\(result.count)개)")
        return result
    }
    
    // Float 배열을 Core ML에서 사용하는 MLMultiArray로 변환
    private func createMLMultiArray(from samples: [Float]) -> MLMultiArray? {
        guard let array = try? MLMultiArray(shape: [NSNumber(value: samples.count)], dataType: .float32) else {
            return nil
        }
        
        // 배열에 값 할당
        for (i, value) in samples.enumerated() {
            array[i] = NSNumber(value: value)
        }
        return array
    }
    
    // 오디오 샘플의 RMS, Zero 비율, 주파수 특성을 기반으로 무음 여부를 판별
    private func isSilent(samples: [Float], rmsThreshold: Float = 0.0005, zeroRatioThreshold: Float = 0.98) -> Bool {
        var rms: Float = 0.0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
        
        let silenceThreshold: Float = 0.001
        var zeroLikeCount: Int = 0
        for sample in samples {
            if abs(sample) < silenceThreshold {
                zeroLikeCount += 1
            }
        }
        let zeroRatio = Float(zeroLikeCount) / Float(samples.count)
        
        print("[isSilent] RMS: \(rms), ZeroRatio: \(zeroRatio)")
        
        let energyBasedSilent = rms < rmsThreshold && zeroRatio > zeroRatioThreshold && isDominantFrequencyLow(samples: samples, thresholdHz: 200.0)
        let patternBasedSilent = isNonCryLikeSignal(samples: samples) && rms < 0.001
        
        return energyBasedSilent || patternBasedSilent
    }
    
    // AVAudioPCMBuffer 기반의 무음 판별 로직
    private func isSilent(buffer: AVAudioPCMBuffer, rmsThreshold: Float = 0.001, zeroRatioThreshold: Float = 0.95) -> Bool {
        guard let floatChannelData = buffer.floatChannelData else { return true }
        let frameLength = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
        
        var rms: Float = 0.0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(samples.count))
        
        // 0에 가까운 값 비율 계산
        let silenceThreshold: Float = 0.001
        let zeroLikeCount = samples.filter { abs($0) < silenceThreshold }.count
        let zeroRatio = Float(zeroLikeCount) / Float(samples.count)
        
        return rms < rmsThreshold && zeroRatio > zeroRatioThreshold
    }
    
    // 울음소리가 아닌 일반적인 무음/환경음 신호를 판별하기 위한 함수 - 신호의 표준 편차가 매우 낮은 경우, 변동성이 적은 비울음 신호로 간주
    private func isNonCryLikeSignal(samples: [Float], stddevThreshold: Float = 0.005) -> Bool {
        var mean: Float = 0
        var stddev: Float = 0
        // 신호를 정규화하고 평균(mean)과 표준편차(stddev)를 계산함
        vDSP_normalize(samples, 1, nil, 1, &mean, &stddev, vDSP_Length(samples.count))
        print("[isSilent] Signal StdDev: \(stddev)")
        // 표준편차가 임계값보다 작으면 비울음소리로 간주하여 true 반환
        return stddev < stddevThreshold
    }
}

// 주파수 도메인에서 신호의 주요 성분이 저주파인지 확인하는 함수
// 울음소리는 일반적으로 중고주파수 대역에 분포하지만, 환경음이나 무음은 저주파 비중이 높기 때문에
// 지배적인 주파수가 특정 임계값(thresholdHz)보다 낮은 경우 이를 울음이 아닌 신호로 간주할 수 있음
private func isDominantFrequencyLow(samples: [Float], thresholdHz: Float = 300.0, sampleRate: Float = 44100.0) -> Bool {
    var windowedSamples = samples
    var window = [Float](repeating: 0, count: samples.count)
    // FFT 정확도를 높이기 위해 해닝(Hanning) 윈도우를 적용
    // 윈도잉은 신호의 양끝이 급격히 꺾이는 걸 방지하여 스펙트럼 누설(leakage)을 줄이는 역할
    vDSP_hann_window(&window, vDSP_Length(samples.count), Int32(vDSP_HANN_NORM))
    // 원본 샘플과 해닝 윈도 배열을 원소별 곱셈하여 윈도우가 적용된 샘플(windowedSamples)을 생성
    vDSP_vmul(samples, 1, window, 1, &windowedSamples, 1, vDSP_Length(samples.count))
    
    // FFT 입력으로 사용할 실수(real) 성분과 허수(imag) 성분 배열을 준비
    // 초기에는 입력 신호를 real 배열에 복사하고 imag 배열은 0으로 채움
    var real = windowedSamples
    var imag = [Float](repeating: 0.0, count: samples.count)
    var result = true
    real.withUnsafeMutableBufferPointer { realPointer in
        imag.withUnsafeMutableBufferPointer { imagPointer in
            // 실수 배열과 허수 배열을 합쳐 복소수 형태의 splitComplex 구조로 구성하고,
            // 고속 푸리에 변환(FFT)을 수행함 결과는 주파수 도메인의 스펙트럼 정보를 담고 있음
            var splitComplex = DSPSplitComplex(realp: realPointer.baseAddress!, imagp: imagPointer.baseAddress!)
            
            let log2n = vDSP_Length(log2(Float(samples.count)))
            guard let fftSetup = vDSP_create_fftsetup(log2n, FFTRadix(kFFTRadix2)) else { return }
            
            vDSP_fft_zip(fftSetup, &splitComplex, 1, log2n, FFTDirection(FFT_FORWARD))
            vDSP_destroy_fftsetup(fftSetup)
            
            // 변환된 실수 및 허수 값으로부터 각 주파수 성분의 크기(magnitude)를 계산함
            // 주파수 스펙트럼에서 가장 에너지가 큰 성분(지배 주파수)을 찾기 위해 사용함
            let magnitudes = zip(realPointer, imagPointer).map { sqrt($0 * $0 + $1 * $1) }
            if let maxIndex = magnitudes.firstIndex(of: magnitudes.max() ?? 0.0) {
                // magnitude가 최대인 인덱스를 통해 해당하는 주파수를 계산
                // 주파수 단위는 Hz이며, 이 값을 기준으로 저주파인지 판단
                let freq = Float(maxIndex) * sampleRate / Float(samples.count)
                print("[isSilent] Dominant Frequency: \(freq) Hz")
                // 계산된 지배 주파수가 thresholdHz보다 낮으면 true를 반환
                // 해당 신호가 울음이 아닌 저주파 기반의 환경음일 가능성이 높다는 것을 의미
                result = freq < thresholdHz
            }
        }
    }
    return result
}
