//
//  CryAnalysisResultView.swift
//  MyiApp
//
//  Created by 조영민 on 5/13/25.
//

import SwiftUI

// UI 구성에 사용되는 열거형
private enum Constants {
    static let ringStrokeWidth: CGFloat = 12
    static let ringBackgroundOpacity: Double = 0.3
    static let confidenceAnimationDuration: Double = 0.8
    static let iconSize: CGFloat = 140
    static let ringSize: CGFloat = 230
    static let percentageFontSize: CGFloat = 24
    static let titleFontSize: CGFloat = 25
    static let emotionTypeFontSize: CGFloat = 40
    static let tipsFontSize: CGFloat = 16
    static let cornerRadius: CGFloat = 12
    static let contentSpacing: CGFloat = 24
    static let tipsSpacing: CGFloat = 8
}

// MARK: - ConfidenceRingView
// 분석 결과 정확도를 표현하는 원형 그래프 뷰
struct ConfidenceRingView: View {
    let confidence: Float
    let imageName: String
    
    private var percentageText: String {
        return "\(Int(confidence * 100))%"
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(Constants.ringBackgroundOpacity),
                    lineWidth: Constants.ringStrokeWidth
                )
            
            if imageName.contains("Unknown") {
                Circle()
                    .stroke(
                        Color("buttonColor"),
                        style: StrokeStyle(
                            lineWidth: Constants.ringStrokeWidth,
                            lineCap: .round
                        )
                    )
            } else {
                Circle()
                    .trim(from: 0, to: CGFloat(confidence))
                    .stroke(
                        Color("buttonColor"),
                        style: StrokeStyle(
                            lineWidth: Constants.ringStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .easeOut(duration: Constants.confidenceAnimationDuration),
                        value: confidence
                    )
            }
            
            VStack(spacing: 4) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        width: Constants.iconSize,
                        height: Constants.iconSize
                    )
                    .accessibilityLabel(getAccessibilityLabel(for: imageName))
                
                if !imageName.contains("Unknown") {
                    Text(percentageText)
                        .font(.system(size: Constants.percentageFontSize, weight: .bold))
                        .accessibilityLabel("확률 \(percentageText)")
                }
            }
        }
        .frame(width: Constants.ringSize, height: Constants.ringSize)
    }
    
    // 이미지 이름에서 감정 타입을 추출하여 접근성 레이블을 생성
    // VoiceOver 사용자에게도 설명 제공
    private func getAccessibilityLabel(for imageName: String) -> String {
        let baseType = imageName.replacingOccurrences(of: "shark", with: "")
        return "\(baseType) 상태 이미지"
    }
}

// MARK: - CryAnalysisResultView
struct CryAnalysisResultView: View {
    @ObservedObject var viewModel: VoiceRecordViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    
    let emotionType: EmotionType
    let confidence: Float
    let onDismiss: () -> Void
    
    // MARK: - Computed Properties
    // 감정 타입에 해당하는 이미지 이름을 반환
    private var resultImageName: String {
        return emotionType.rawImageName
    }
    
    // 감정 타입에 따라 표시할 추천 행동 목록을 반환
    private var localizedTips: [String] {
        return tips(for: emotionType)
    }
    
    // MARK: - View Body
    var body: some View {
        VStack(spacing: Constants.contentSpacing) {
            Text(NSLocalizedString("결과", comment: ""))
                .font(.system(size: Constants.titleFontSize, weight: .heavy))
                .padding(.top)
                .accessibilityAddTraits(.isHeader)
            
            ConfidenceRingView(confidence: confidence, imageName: resultImageName)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(emotionType.displayName) 상태, 확률 \(Int(confidence * 100))%")
            
            Text(emotionType.displayName)
                .font(.system(size: Constants.emotionTypeFontSize, weight: .bold))
                .padding()
                .accessibilityAddTraits(.isHeader)
            
            
            VStack(alignment: .leading, spacing: Constants.tipsSpacing) {
                Text(NSLocalizedString("추천 행동", comment: ""))
                    .font(.system(size: Constants.tipsFontSize, weight: .bold))
                
                ForEach(localizedTips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 4) {
                        Text("•")
                            .font(.system(size: Constants.tipsFontSize))
                        Text(tip)
                            .font(.system(size: Constants.tipsFontSize))
                    }
                }
            }
            .padding(.horizontal)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityTipsLabel)
            
            VStack {
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Text("완료")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                        .background(Color("buttonColor"))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
                
            }
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarBackButtonHidden(true)
        .onAppear {
            print("[ResultView] 결과 화면 표시됨: \(emotionType.rawValue)")
        }
    }
    
    // 접근성 팁 레이블 생성
    private var accessibilityTipsLabel: String {
        let tipsJoined = localizedTips.joined(separator: ", ")
        return "\(NSLocalizedString("추천 행동", comment: "")), \(tipsJoined)"
    }
    
    // MARK: - Methods
    // 감정 타입별로 적절한 추천행동(Localized String Key 목록)을 반환
    // 추후 다국어 지원을 위해 NSLocalizedString 사용
    private func tips(for emotion: EmotionType) -> [String] {
        switch emotion {
        case .discomfort:
            return [
                NSLocalizedString("discomfortTip1", comment: ""),
                NSLocalizedString("discomfortTip2", comment: ""),
                NSLocalizedString("discomfortTip3", comment: "")
            ]
        case .hungry:
            return [
                NSLocalizedString("hungryTip1", comment: ""),
                NSLocalizedString("hungryTip2", comment: ""),
                NSLocalizedString("hungryTip3", comment: "")
            ]
        case .tired:
            return [
                NSLocalizedString("tiredTip1", comment: ""),
                NSLocalizedString("tiredTip2", comment: ""),
                NSLocalizedString("tiredTip3", comment: "")
            ]
        case .scared:
            return [
                NSLocalizedString("scaredTip1", comment: ""),
                NSLocalizedString("scaredTip2", comment: ""),
                NSLocalizedString("scaredTip3", comment: "")
            ]
        case .lonely:
            return [
                NSLocalizedString("lonelyTip1", comment: ""),
                NSLocalizedString("lonelyTip2", comment: ""),
                NSLocalizedString("lonelyTip3", comment: "")
            ]
        case .burping:
            return [
                NSLocalizedString("burpingTip1", comment: ""),
                NSLocalizedString("burpingTip2", comment: ""),
                NSLocalizedString("burpingTip3", comment: "")
            ]
        case .bellyPain:
            return [
                NSLocalizedString("bellyPainTip1", comment: ""),
                NSLocalizedString("bellyPainTip2", comment: ""),
                NSLocalizedString("bellyPainTip3", comment: "")
            ]
        case .coldHot:
            return [
                NSLocalizedString("coldHotTip1", comment: ""),
                NSLocalizedString("coldHotTip2", comment: ""),
                NSLocalizedString("coldHotTip3", comment: "")
            ]
        case .unknown:
            return [
                NSLocalizedString("unknownTip1", comment: ""),
                NSLocalizedString("unknownTip2", comment: ""),
                NSLocalizedString("unknownTip3", comment: "")
            ]
        }
    }
}

// 하단 safe area를 고려하여 적절한 버튼 여백 값을 계산
// 디바이스의 화면 크기와 안전 영역에 따라 padding을 동적으로 조정
private func maxSafeAreaBottomPadding() -> CGFloat {
    // 현재 키 윈도우를 가져와서 앱에서 사용 중인 주요 윈도우를 기준으로 계산
    guard let keyWindow = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first?.windows.first(where: { $0.isKeyWindow }) else {
        // 키 윈도우가 없을 경우 기본값 28을 반환
        return 28
    }
    
    // 디바이스 하단의 safe area inset을 가져옴
    let bottomInset = keyWindow.safeAreaInsets.bottom
    
    // 전체 화면 높이를 기준으로 화면이 충분히 크면 적은 여백을 적용하고, 작으면 더 큰 여백을 적용
    let screenHeight = keyWindow.bounds.height
    let basePadding: CGFloat = screenHeight > 700 ? 16 : 28
    
    // inset과 basePadding을 합친 값을 최대 40으로 제한하여 UI가 깨지지 않도록 함
    return min(bottomInset + basePadding, 40)
}

// MARK: - Extension EmotionType
extension EmotionType {
    var rawImageName: String {
        switch self {
        case .hungry:
            return "sharkHungry"
        case .scared:
            return "sharkScared"
        case .tired:
            return "sharkTired"
        case .lonely:
            return "sharkLonely"
        case .burping:
            return "sharkBurping"
        case .bellyPain:
            return "sharkBellyPain"
        case .coldHot:
            return "sharkColdHot"
        case .discomfort:
            return "sharkDiscomfort"
        case .unknown:
            return "sharkUnknown"
        }
    }
}

#Preview {
    let mockViewModel = VoiceRecordViewModel()
    CryAnalysisResultView(viewModel: mockViewModel, emotionType: .unknown, confidence: 0.81, onDismiss: {})
}
