import SwiftUI
import UIKit

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // 1. 수집하는 개인정보의 항목
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MyiApp은 다음과 같은 개인정보를 수집하고 있습니다")
                            .fontWeight(.semibold)
                        
                        Text("필수 수집 정보")
                            .fontWeight(.medium)
                        Text("- 계정 정보: 이메일 주소, 이름")
                        Text("- 인증 정보: Google 또는 Apple 로그인을 통한 인증 데이터")
                        
                        Text("선택적 수집 정보")
                            .fontWeight(.medium)
                        Text("- 프로필 정보: 프로필 사진")
                        Text("- 아기 정보: 이름, 생년월일, 성별, 키, 몸무게, 혈액형, 사진")
                        Text("- 육아 기록: 수유, 수면, 배변, 체온 등 육아 관련 기록")
                        Text("- 음성 데이터: 아기 울음소리 분석을 위한 오디오 데이터")
                        
                        Text("이용 목적")
                            .fontWeight(.medium)
                        Text("- 회원 식별 및 서비스 제공")
                        Text("- 아기 성장 기록 및 관리")
                        Text("- 일정 알림 제공")
                        Text("- 울음소리 분석을 통한 아기 상태 파악")
                        Text("- 서비스 개선 및 기록 분석 작성")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("1. 개인정보 수집 항목 및 이용 목적")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 2. 개인정보의 보유 및 이용 기간
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("회원 탈퇴 시 또는 개인정보 수집 및 이용목적이 달성된 후에는 지체 없이 파기합니다. 단, 관계 법령에 의해 보존할 필요가 있는 경우 해당 기간 동안 보관됩니다.")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("2. 개인정보 보유 및 이용 기간")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 3. 개인정보의 제3자 제공
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MyiApp은 원칙적으로 이용자의 개인정보를 외부에 제공하지 않습니다. 다만, 다음의 경우에는 예외로 합니다:")
                        Text("- 이용자가 사전에 동의한 경우")
                        Text("- 법령에 의거하거나 수사 목적으로 법령에 정해진 절차와 방법에 따라 수사기관의 요구가 있는 경우")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("3. 개인정보 제3자 제공")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 4. 개인정보의 처리 위탁
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MyiApp은 서비스 제공을 위해 다음과 같이 개인정보 처리 업무를 위탁하고 있습니다:")
                        Text("- Firebase: 계정 정보 저장 및 인증, 데이터베이스 관리")
                        Text("- Google Cloud Storage: 사용자 및 아기 프로필 이미지 저장")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("4. 개인정보의 처리 위탁")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 5. 이용자 권리
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("이용자는 언제든지 자신의 개인정보를 조회, 수정, 삭제, 처리정지 요구 등의 권리를 행사할 수 있습니다. 이를 위해서는 앱 내 '설정' 메뉴를 통해 직접 처리하거나 개인정보 보호책임자에게 이메일로 연락하시면 됩니다.")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("5. 이용자의 권리와 행사 방법")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 6. 개인정보의 안전성 확보 조치
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MyiApp은 개인정보의 안전성 확보를 위해 다음과 같은 조치를 취하고 있습니다:")
                        Text("- 개인정보 암호화")
                        Text("- 접근 제한 및 권한 관리")
                        Text("- 보안 프로토콜(HTTPS) 사용")
                        Text("- Firebase의 보안 정책 준수")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("6. 개인정보의 안전성 확보 조치")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 7. 알림 서비스 관련 권한 사용
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MyiApp은 일정 알림 제공을 위해 기기의 알림 권한을 사용합니다. 알림 권한은 앱 설정에서 언제든지 변경할 수 있습니다.")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("7. 알림 서비스 관련 권한 사용")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 8. 오디오 분석 관련 권한 사용
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MyiApp은 아기 울음소리 분석을 위해 마이크 권한을 사용합니다. 수집된 오디오 데이터는 분석 목적으로만 사용되며, 사용자의 동의 없이 외부로 전송되지 않습니다. 분석은 기기 내에서 CoreML 모델을 통해 이루어집니다.")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("8. 오디오 분석 관련 권한 사용")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 9. 개인정보 보호책임자
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("MyiApp의 개인정보 보호책임자는 다음과 같습니다:")
                        Text("- 이름: 최범수")
                        Text("- 이메일: qjatn0545123@gmail.com")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("9. 개인정보 보호책임자")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 10. 개인정보 처리방침 변경
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("이 개인정보 처리방침은 법령, 정책 또는 보안 기술의 변경에 따라 내용이 추가, 삭제 및 수정될 수 있으며, 변경사항이 발생할 경우 앱 내 공지사항을 통해 고지합니다.")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("10. 개인정보 처리방침 변경")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 시행일
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("- 본 개인정보 처리방침은 2025년 5월 26일부터 시행됩니다.")
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("시행일")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                Spacer()
                    .frame(height: 20)
            }
            .padding()
        }
        .background(Color("customBackgroundColor"))
        .navigationTitle("개인정보 처리 방침")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
