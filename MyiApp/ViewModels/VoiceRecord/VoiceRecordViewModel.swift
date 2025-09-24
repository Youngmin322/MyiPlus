//
//  VoiceRecordViewModel.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-08.
//

import Foundation
import Combine
import FirebaseFirestore

// 분석 흐름의 상태를 표현하는 enum
enum CryAnalysisStep: Equatable {
    case start
    case recording
    case processing
    case result(EmotionResult)
    case error(String)
    
    // CryAnalysisStep 열거형의 Equatable 프로토콜 구현
    // CryAnalysisStep은 enum인데 연관값이 있는 케이스가 있어서 직접 로직 구현
    static func == (lhs: CryAnalysisStep, rhs: CryAnalysisStep) -> Bool {
        switch (lhs, rhs) {
        // 좌측과 우측 둘 다 .start인 경우
        case (.start, .start):
            return true
            
        // 둘 다 .recording인 경우
        case (.recording, .recording):
            return true
            
        // 둘 다 .processing인 경우
        case (.processing, .processing):
            return true
            
        // 둘 다 .result인 경우, 내부 EmotionResult의 타입과 confidence 값이 같아야 true
        case let (.result(lhsResult), .result(rhsResult)):
            return lhsResult.type == rhsResult.type &&
            lhsResult.confidence == rhsResult.confidence
            
        // 둘 다 .error인 경우, 메세지 문자열이 같아야 true
        case let (.error(lhsMsg), .error(rhsMsg)):
            return lhsMsg == rhsMsg
            
        // 위 모든 조건에 해당되지 않는다면 false
        default:
            return false
        }
    }
}

final class VoiceRecordViewModel: ObservableObject {
    let careGiverManager = CaregiverManager.shared
    
    // MARK: - Published State
    @Published var audioLevels: [Float] = Array(repeating: 0.0, count: 8) // 실시간 FFT 이퀄라이저 값 (0~1의 Float 8개)
    @Published var recordingProgress: Double = 0.0 // 분석 진행률
    @Published var step: CryAnalysisStep = .start { // 현재 상태(녹음 중, 분석 중, 결과)
        didSet {
            print("[ViewModel] step 변경됨 → \(step)")
        }
    }
    @Published var recordResults: [VoiceRecord] = [] // 분석 결과 VoiceRecord 목록
    @Published var analysisCompleted: Bool = false // 분석 완료 여부
    @Published var shouldDismissResultView: Bool = false // 결과 화면 닫힘 여부 트리거
    
    // MARK: - Private
    private let audioService = AudioEngineService()
    private let analyzer = CryAnalyzer()
    private var cancellables = Set<AnyCancellable>()
    
    private var recordingBuffer: [Float] = []
    private var analysisTimer: Timer?
    private var hasStarted = false
    private var isProcessingResult = false
    
    // MARK: - Init
    init() {
        observeStep() // step 상태가 .result로 바뀌었을 때 후속 처리하기 위한 함수 사용
        // CaregiverManager에서 초기 데이터 로드
        recordResults = careGiverManager.voiceRecords
        
        // voiceRecords 배열의 변경사항 구독
        careGiverManager.$voiceRecords // CaregiverManager.shared.$voiceRecords를 구독하여 자동 반영
            .sink { [weak self] records in
                self?.recordResults = records
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    // 상태 초기화 및 오디오 핸들러 설정, 마이크 권한 요청
    func startAnalysis() {
        print("[ViewModel] startAnalysis() called — step: \(step)")
        hasStarted = true
        step = .start
        recordingProgress = 0.0
        recordingBuffer.removeAll()
        shouldDismissResultView = false
        analysisCompleted = false
        isProcessingResult = false
        
        // FFT 값 실시간 수신
        audioService.audioLevelsHandler = { [weak self] levels in
            self?.audioLevels = levels
        }
        
        // PCM 버퍼 수신
        audioService.bufferHandler = { [weak self] samples in
            self?.recordingBuffer.append(contentsOf: samples)
            let avg = samples.reduce(0, +) / Float(samples.count)
            print("[ViewModel] 새 샘플 수신: \(samples.count)개, 평균값: \(avg)")
        }
        
        audioService.startRecording { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.step = .recording
                self.startRecordingTimer()
            } else {
                self.step = .error("마이크 권한이 필요합니다.")
                self.shouldDismissResultView = true
            }
        }
    }
    
    func cancel() {
        stop()
        resetAnalysisState()
    }
    
    func resetAnalysisState() {
        // 결과 처리 중이면 바로 초기화하지 않음
        if isProcessingResult {
            return
        }
        
        step = .start
        shouldDismissResultView = false
        analysisCompleted = false
        hasStarted = false
        recordingProgress = 0.0
        recordingBuffer.removeAll()
        print("[ViewModel] resetAnalysisState() 완료 — step: \(step)")
    }
    
    func resetAnalysisCompleted() {
        analysisCompleted = false
    }
    
    var analysisCompletedPublisher: some Publisher<Bool, Never> {
        $analysisCompleted.removeDuplicates()
    }
    
    func dismissResultView() {
        shouldDismissResultView = true
    }
    
    // MARK: - Record Management
    // 선택된 레코드들 삭제
    func deleteRecords(with ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        
        // 로컬에서 삭제
        careGiverManager.voiceRecords.removeAll { record in
            ids.contains(record.id)
        }
        
        // Firebase에서 삭제
        Task {
            await deleteRecordsFromFirebase(ids: ids)
        }
    }
    
    // 단일 레코드 삭제
    func deleteRecord(with id: UUID) {
        deleteRecords(with: [id])
    }
    
    // Firebase에 결과 저장 함수
    func saveAnalysisResult(newResult: VoiceRecord) async throws {
        guard let babyID = careGiverManager.selectedBaby?.id.uuidString else {
            return
        }
        
        // baby ID 기준으로 Firebase Firestore에 저장
        let db = Firestore.firestore()
        _ = db.collection("babies")
            .document(babyID)
            .collection("voiceRecords")
            .document(newResult.id.uuidString)
            .setData(from: newResult)
    }
    
    // MARK: - Private Methods
    
    private func observeStep() {
        $step // step 상태가 바뀔 때마다 .sink 클로저가 호출
            .receive(on: DispatchQueue.main)
            .removeDuplicates() // 같은 값으로 연속 변경되는 경우 무시
            .sink { [weak self] newStep in
                self?.handleStepChange(newStep)
            }
            .store(in: &cancellables)
    }
    
    // 분석 결과를 받으면 VoiceRecord 생성 -> CaregiveManager에 추가 -> firebase 저장
    private func handleStepChange(_ newStep: CryAnalysisStep) {
        guard case let .result(emotion) = newStep, !analysisCompleted, !isProcessingResult else {
            return
        }
        
        isProcessingResult = true
        
        let newResult = VoiceRecord(
            id: UUID(),
            createdAt: Date(),
            recordReference: "",
            firstLabel: emotion.type,
            firstLabelConfidence: emotion.confidence,
            secondLabel: .unknown,
            secondLabelConfidence: 0.0
        )
        
        careGiverManager.voiceRecords.insert(newResult, at: 0)
        analysisCompleted = true
        
        Task {
            do {
                try await saveAnalysisResult(newResult: newResult)
            } catch {
                print("Firebase 저장 실패: \(error)")
            }
        }
    }
    
    private func stop() {
        analysisTimer?.invalidate()
        analysisTimer = nil
        audioService.stopRecording()
    }
    
    // 0.1초마다 recordingProgress를 1/70씩 증가(분석을 하는 시간이 7초이기 때문에 1/70씩 증가)
    private func startRecordingTimer() {
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            
            self.recordingProgress += 0.1 / 7.0
            
            if self.recordingProgress >= 1.0 {
                timer.invalidate()
                self.finishRecording()
            }
        }
    }
    
    private func finishRecording() {
        stop()
        step = .processing
        print("[ViewModel] finishRecording() 호출됨, 버퍼 길이: \(recordingBuffer.count)")
        
        analyzer.analyze(from: recordingBuffer) { [weak self] result in
            print("[ViewModel] 분석 결과 수신: \(String(describing: result))")
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.step = result.map { .result($0) } ?? .error("분석 실패")
            }
        }
    }
    
    // Firebase에서 레코드들 삭제
    private func deleteRecordsFromFirebase(ids: Set<UUID>) async {
        guard let babyID = careGiverManager.selectedBaby?.id.uuidString else {
            print("선택된 아기가 없습니다.")
            return
        }
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        for id in ids {
            let docRef = db.collection("babies")
                .document(babyID)
                .collection("voiceRecords")
                .document(id.uuidString)
            batch.deleteDocument(docRef)
        }
        
        do {
            try await batch.commit()
            print("Firebase에서 \(ids.count)개 레코드 삭제 완료")
        } catch {
            print("Firebase 삭제 실패: \(error)")
        }
    }
}
