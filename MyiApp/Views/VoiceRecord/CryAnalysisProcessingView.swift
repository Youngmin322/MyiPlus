//
//  CryAnalysisProcessingView.swift
//  MyiApp
//
//  Created by 조영민 on 5/12/25.
//

import SwiftUI
import Combine

struct CryAnalysisProcessingView: View {
    @Environment(\.dismiss) private var dismiss // 네비게이션에서 현재 뷰를 닫을 수 있는 Environment
    @ObservedObject var viewModel: VoiceRecordViewModel // 상태와 로직을 포함한 뷰 모델
    @State private var result: EmotionResult? // 화면에 이미 전달한 결과를 저장해서 중복 전달 방지
    let onComplete: (EmotionResult) -> Void // 분석이 완료되었을 때 결과를 상위 뷰에 전달하는 클로저
    
    var body: some View {
        ZStack {
            switch viewModel.step {
                // .recording, .processing이면 ProccessingStateView 렌더링
            case .recording, .processing:
                ProcessingStateView(viewModel: viewModel, dismiss: dismiss)
                // .result면 onAppear에서 onComplete 호출(결과를 onComplete 클로저를 통해 상위로 전달
            case .result(let res):
                // onAppear 트리거를 위해 사용되는 투명한 배경 뷰
                Color.clear
                    .onAppear {
                        print("[ProcessingView] result onAppear — 새 result 도착: \(res.type) / \(res.confidence)")
                        
                        // 동일한 결과가 중복 호출되지 않도록 이전 결과와 비교하여 변경이 있을 때만 onComplete 호출
                        if result?.type != res.type || result?.confidence != res.confidence {
                            self.result = res
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                onComplete(res)
                            }
                        }
                    }
                // .error면 ErrorStateView 렌더링
            case .error(let message):
                ErrorStateView(message: message, dismiss: dismiss)
                
                // 나머지는 EmptyView 렌더링
            default:
                EmptyView()
            }
        }
        .navigationBarBackButtonHidden(true)
        // 뷰가 사라지면 내부 결과 초기화(결과 상태를 초기화하여 이후에 중복 전송되지 않도록 방지)
        .onDisappear {
            result = nil
        }
    }
}

private struct ProcessingStateView: View {
    @ObservedObject var viewModel: VoiceRecordViewModel // 분석 상태 및 제어 로직을 담은 뷰 모델
    let dismiss: DismissAction // 현재 화면을 종료시키는 액션
    @State private var dotCount: Int = 0 // dot 애니메이션의 현재 점 개수
    @State private var dotTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect() // 0.5초마다 dot 개수를 갱신하는 타이머
    
    @State private var progress: Double = 0.0
    @State private var startTime = Date()
    private let totalDuration: Double = 7.0 // 분석 소요 시간 (7초)
    
    var body: some View {
        VStack(spacing: 24) {
            Text("분석 중")
                .font(.system(size: 20, weight: .semibold))
                .padding(.top, 16)
            
            EqualizerView()
                .padding(.horizontal, 24)
                .frame(height: 123)
            
            Image("CryAnalysisProcessingShark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
            
            Text("아기의 상태를 분석하고 있어요" + String(repeating: ".", count: dotCount))
                .font(.system(size: 20))
                .bold()
                .foregroundColor(.primary)
                .padding(.top, 8)
            
            Text("소음이 심한 경우 정확도가 \n 떨어질 수 있어요.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.horizontal, 24)
                    .tint(Color("buttonColor"))
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gray)
            }
            Button(action: {
                print("[ProcessingView] 취소 버튼 클릭됨")
                viewModel.cancel()
                viewModel.resetAnalysisState()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
            }) {
                Text("취소")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .frame(height: 50)
                    .background(Color("buttonColor"))
                    .cornerRadius(12)
            }
            .contentShape(Rectangle())
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .onReceive(dotTimer) { _ in
            dotCount = (dotCount + 1) % 4
        }
        .onAppear {
            dotCount = 0
            progress = 0.0
            startTime = Date()
            startProgress()
        }
    }
    
    // 부드러운 진행률 계산을 위한 easing 함수 (Cubic Ease-Out)
    private func easeOut(_ t: Double) -> Double {
        return 1 - pow(1 - t, 3)
    }
    
    // CADisplayLink를 사용하여 프레임마다 진행률을 계산하고 갱신
    private func startProgress() {
        let displayLink = CADisplayLink(target: DisplayLinkProxy { link in
            let elapsed = Date().timeIntervalSince(startTime) // 애니메이션 시작 후 경과 시간
            let t = min(elapsed / totalDuration, 1.0)  // 전체 지속 시간 대비 현재 진행 비율 (0.0 ~ 1.0)
            progress = easeOut(t)  // easing 커브를 적용한 진행률 값으로 업데이트
            
            // 애니메이션 완료 시 displayLink 정지
            if t >= 1.0 {
                link.invalidate()
            }
        }, selector: #selector(DisplayLinkProxy.update(_:))) // 프레임마다 실행될 함수 등록
        displayLink.add(to: .main, forMode: .default) // 메인 런루프에 displayLink 등록 → 화면이 그려질 때마다 실행됨
    }
    
    // CADisplayLink는 Objective-C 런타임과의 호환이 필요하므로 래퍼 클래스를 통해 클로저 실행
    private class DisplayLinkProxy {
        let callback: (CADisplayLink) -> Void // 실제 작업을 수행할 클로저
        
        init(_ callback: @escaping (CADisplayLink) -> Void) {
            self.callback = callback // 클로저 저장
        }
        
        @objc func update(_ sender: CADisplayLink) {
            callback(sender)  // CADisplayLink에 의해 호출되면 클로저 실행
        }
    }
}

private struct ErrorStateView: View {
    let message: String
    let dismiss: DismissAction
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Text("분석 중")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
            }
            .padding([.top, .horizontal])
            
            Image("sharkUnknown")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
                .padding()
            
            Text(message)
                .font(.system(size: 20))
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
        }
        .alert("마이크 접근 권한이 필요합니다.", isPresented: $showPermissionAlert) {
            Button("설정으로 이동", action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })
            Button("취소", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("앱에서 울음소리를 분석하려면 마이크 권한이 필요해요.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showPermissionAlert = true
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.primary.opacity(0.8))
                }
            }
        }
        .onAppear {
            showPermissionAlert = true
        }
    }
}
