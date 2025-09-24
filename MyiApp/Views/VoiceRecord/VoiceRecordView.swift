//
//  VoiceRecordView.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-08.
//

import SwiftUI
import AVFAudio

enum CryRoute {
    case processing(id: UUID = UUID())  // UUID()를 붙이면 뷰의 고유성을 보장하므로 새로운 뷰로 렌더링 함
    case result(emotion: EmotionResult, id: UUID = UUID()) // EmotionResult만 전달되면 이전과 동일한 값이라고 판단돼서 화면 전환이 안 일어나므로 UUID도 넘겨줌
}

extension CryRoute: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .processing:  // 'processing'은 항상 같은 화면으로 인식되도록 고정된 문자열만 해시에 포함시킴
            hasher.combine("processing")
        case .result(let emotion, let id): // 'result' 케이스는 감정 결과 및 UUID를 기준으로 고유하게 구분되도록 해시에 포함
            hasher.combine("result")  // "result": 다른 케이스와 구분하기 위한 마커
            hasher.combine(emotion.type) // emotion.type, confidence: 감정 결과 내용
            hasher.combine(emotion.confidence)
            hasher.combine(id) // 같은 감정 결과라도 화면을 다르게 하기 위해 id 사용
        }
    }
}

// CryRoute 간의 동등성 비교 정의
// NavigationStack에서 동일한 화면인지 판단할 때 사용
extension CryRoute: Equatable {
    static func == (lhs: CryRoute, rhs: CryRoute) -> Bool {
        switch (lhs, rhs) {
        // processing은 UUID는 매번 다르지만, '진행 중 화면'이라는 목적이 같으므로 같은 화면으로 처리함
        case (.processing, .processing):
            return true
            
        // result는 type과 confidence, UUID가 모두 같을 때만 동일한 경로로 간주
        case (.result(let a, let lhsID), .result(let b, let rhsID)):
            return a.type == b.type && a.confidence == b.confidence && lhsID == rhsID
        // 나머지는 서로 다른 경로
        default:
            return false
        }
    }
}

struct VoiceRecordView: View {
    @StateObject private var viewModel: VoiceRecordViewModel = .init() // 분석 관련 상태와 동작을 관리하는 ViewModel
    @State private var navigationPath = NavigationPath() // NavigationStack의 경로를 추적
    @State private var showResultList = false // 결과 목록 화면을 보여줄지 여부를 제어
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                SafeAreaPaddingView()
                    .frame(height: getTopSafeAreaHeight())
                
                HStack(alignment: .center, spacing: 10) {
                    Text("울음 분석")
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    Image(systemName: "list.bullet")
                        .foregroundColor(.primary)
                        .font(.title2)
                        .padding(.leading)
                        .onTapGesture {
                            showResultList.toggle()
                        }
                }
                .padding(.top)
                
                VStack {
                    Spacer()
                    
                    Image("CryAnalysisProcessingShark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 270, height: 270)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    Text("시작 버튼을 누른 후 \n 아이의 울음소리를 들려주세요")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.bottom, 40)
                    
                    
                    Text("녹음은 7초 동안 진행됩니다.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.bottom, 10)
                    
                    Text("가장 뚜렷한 울음소리가 들릴 때 녹음을 시작해 주세요.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.bottom, 10)
                    
                    Text("정확한 분석을 위해 조용한 환경에서 녹음해 주세요.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.bottom, 20)
                    
                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(Color(UIColor.tertiarySystemBackground))
                .cornerRadius(12)
                .padding(.top, 16)
                
                Spacer()
            }
            .padding(.horizontal)
            .background(Color("customBackgroundColor"))
            .safeAreaInset(edge: .bottom) {
                // 분석 시작 버튼 - 분석 상태 초기화 후 분석 처리 화면으로 전환
                Button(action: {
                    viewModel.resetAnalysisState() // 이전 분석 상태 초기화
                    viewModel.startAnalysis() // 녹음 및 분석 시작
                    navigationPath = NavigationPath() // 매번 새로운 시작을 위해 네비게이션 경로 초기화
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        navigationPath.append(CryRoute.processing()) // 분석 중 화면으로 전환
                    }
                }) {
                    Text("분석 시작")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                        .frame(height: 50)
                        .background(Color("buttonColor"))
                        .cornerRadius(12)
                        .padding()
                        .padding(.bottom)
                }
            }
            .navigationDestination(for: CryRoute.self) { route in
                switch route {
                case .processing(let id):
                    CryAnalysisProcessingView(viewModel: viewModel) { result in
                        navigationPath.removeLast()
                        navigationPath.append(CryRoute.result(emotion: result, id: UUID()))
                    }
                    .id(id) // UUID로 뷰의 고유성을 보장하여 새 화면으로 렌더링
                    
                case .result(let emotion, _):
                    // 분석 결과 화면
                    CryAnalysisResultView(
                        viewModel: viewModel,
                        emotionType: emotion.type,
                        confidence: Float(emotion.confidence),
                        onDismiss: {
                            navigationPath = NavigationPath() // 결과 화면 닫기 -> 루트로 이동
                        }
                    )
                }
            }
            // 분석 결과 리스트 화면으로 경로 설정
            .navigationDestination(isPresented: $showResultList) {
                CryAnalysisResultListView()
                    .environmentObject(viewModel) // 결과 리스트 뷰에서도 동일한 뷰모델을 공유하도록 환경 객체로 주입
            }
            .onAppear {
                // 앱 진입 시 마이크 권한 요청
                AVAudioApplication.requestRecordPermission { granted in
                    if !granted {
                        DispatchQueue.main.async {
                            // 마이크 권한이 거부된 경우 오류 상태로 설정하여 사용자에게 알림
                            viewModel.step = .error("마이크 권한이 거부되어 녹음을 시작할 수 없어요.")
                        }
                    }
                }
            }
        }
    }
}
