import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                // 제1조 (목적)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        본 약관은 MyiApp(이하 "회사")이 제공하는 육아 기록 및 관리 서비스(이하 "서비스")를 이용함에 있어 회사와 이용자 간의 권리와 의무, 책임사항 및 기타 필요한 사항을 규정함을 목적으로 합니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제1조 (목적)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제2조 (용어의 정의)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. "서비스"란 이용자가 모바일 기기를 통해 회사가 제공하는 MyiApp을 이용하는 것을 말합니다.
                        2. "이용자"란 본 약관에 동의하고 회사가 제공하는 서비스를 이용하는 자를 말합니다.
                        3. "계정"이란 이용자의 식별과 서비스 이용을 위하여 이용자가 선정하고 회사가 승인하는 이메일, 기타 로그인 수단을 말합니다.
                        4. "콘텐츠"란 회사가 서비스를 통해 이용자에게 제공하는 모든 정보와 이용자가 서비스에 게시 또는 등록하는 모든 정보를 말합니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제2조 (용어의 정의)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제3조 (약관의 효력 및 변경)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 회사는 본 약관의 내용을 이용자가 쉽게 알 수 있도록 서비스 내 또는 연결화면을 통하여 게시합니다.
                        2. 회사는 필요한 경우 관련법령을 위배하지 않는 범위에서 본 약관을 변경할 수 있습니다.
                        3. 회사가 약관을 변경할 경우에는 적용일자 및 변경사유를 명시하여 서비스 내에 공지합니다.
                        4. 이용자는 변경된 약관에 동의하지 않을 경우 서비스 이용을 중단하고 회원 탈퇴를 요청할 수 있으며, 변경된 약관의 효력 발생일 이후에도 서비스를 계속 사용할 경우 약관의 변경사항에 동의한 것으로 간주됩니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제3조 (약관의 효력 및 변경)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제4조 (서비스의 제공 및 변경)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 회사는 다음과 같은 서비스를 제공합니다:
                           - 아기 정보 등록 및 관리 기능
                           - 육아 관련 기록 (수유, 수면, 배변, 체온 등) 관리 기능
                           - 아기 울음소리 분석 기능
                           - 일정 알림 서비스
                           - 기타 회사가 추가 개발하거나 제휴를 통해 이용자에게 제공하는 일체의 서비스
                        2. 회사는 서비스의 품질 향상을 위해 예고 없이 서비스의 내용을 변경할 수 있으며, 이 경우 서비스 내용 및 제공방법이 변경될 수 있습니다.
                        3. 회사는 긴급한 시스템 점검, 증설 및 교체, 천재지변, 국가비상사태 등의 불가항력적인 사유로 인하여 서비스를 일시적으로 중단할 수 있습니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제4조 (서비스의 제공 및 변경)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제5조 (회원가입 및 계정)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 이용자는 회사가 정한 양식에 따라 정보를 기입한 후 본 약관에 동의함으로써 회원가입을 신청합니다.
                        2. 회원가입은 Google 계정 또는 Apple ID를 통한 인증 방식으로 진행됩니다.
                        3. 이용자는 회원가입 시 제공한 개인정보의 진실성에 대한 책임이 있습니다.
                        4. 이용자의 계정은 본인만 이용할 수 있으며, 다른 사람에게 이용을 허락하거나 양도, 대여, 판매할 수 없습니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제5조 (회원가입 및 계정)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제6조 (개인정보 보호)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        회사는 관련 법령이 정하는 바에 따라 이용자의 개인정보를 보호하며, 자세한 내용은 개인정보 처리방침에서 확인할 수 있습니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제6조 (개인정보 보호)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제7조 (이용자의 의무)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 이용자는 다음 행위를 하여서는 안 됩니다:
                           - 타인의 계정 및 개인정보를 도용하는 행위
                           - 서비스를 이용하여 얻은 정보를 회사의 사전 승낙 없이 복제, 유통, 상업적 활용하는 행위
                           - 회사 및 제3자의 지적재산권을 침해하는 행위
                           - 회사의 서비스를 방해하거나 그 정보를 위변조하는 행위
                           - 회사가 정한 정보 이외의 정보를 송신하거나 게시하는 행위
                           - 범죄와 결부된다고 객관적으로 판단되는 행위
                           - 기타 관련 법령에 위배되는 행위
                        2. 이용자는 서비스 이용과 관련하여 관계 법령, 본 약관의 규정, 이용안내 및 주의사항 등을 준수해야 합니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제7조 (이용자의 의무)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제8조 (지적재산권)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 서비스에 포함된 모든 지적재산권은 회사에 귀속됩니다.
                        2. 이용자는 회사가 제공하는 서비스를 이용함으로써 얻은 정보를 회사의 사전 승낙 없이 복제, 전송, 출판, 배포, 방송 등 기타 방법에 의하여 영리목적으로 이용하거나 제3자에게 이용하게 할 수 없습니다.
                        3. 이용자가 서비스 내에 게시한 콘텐츠의 저작권은 해당 이용자에게 귀속됩니다. 단, 회사는 서비스의 운영, 개선 및 홍보 등을 위하여 이용자의 콘텐츠를 사용할 수 있습니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제8조 (지적재산권)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제8조의2 (울음분석 기능)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 본 앱은 아기의 울음소리를 분석하여 감정 상태 또는 추정 원인을 안내하는 기능(이하 "울음분석 기능")을 제공합니다. 해당 기능은 머신러닝 기반 알고리즘 및 사운드 분석 기술을 활용하여 통계적으로 유의미한 패턴을 분석하지만, 의료적 진단 또는 전문가의 판단을 대체하지 않습니다.

                        2. 울음분석 결과는 참고 정보로만 제공되며, 아기의 건강, 안전, 또는 양육 방식에 관한 모든 판단은 보호자의 고유한 책임하에 이루어져야 합니다. 앱에서 제공하는 분석 결과에 따라 발생한 직접적 또는 간접적인 피해, 손실, 오판 등에 대해서 개발자는 일체의 책임을 지지 않습니다.

                        3. 울음소리의 환경적 변수(소음, 녹음 품질 등)에 따라 분석 결과가 다를 수 있으며, 이러한 한계를 사용자 스스로 인지하고 이용해 주시기 바랍니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제8조의2 (울음분석 기능)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제9조 (서비스 이용 제한)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 회사는 다음과 같은 경우 서비스 이용을 제한할 수 있습니다:
                           - 본 약관 제7조의 이용자 의무를 위반한 경우
                           - 서비스 운영을 고의로 방해한 경우
                           - 타인의 명예를 손상시키거나 불이익을 주는 행위를 한 경우
                           - 기타 관련 법령에 위배되는 행위를 한 경우
                        2. 서비스 이용 제한이 이루어지는 경우, 회사는 사전에 이용자에게 통지합니다. 단, 긴급한 사유가 있을 경우에는 사후에 통지할 수 있습니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제9조 (서비스 이용 제한)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제10조 (면책조항)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 회사는 천재지변, 전쟁, 기간통신사업자의 서비스 중지 등 불가항력적인 사유로 서비스를 제공할 수 없는 경우에는 서비스 제공에 관한 책임을 지지 않습니다.
                        2. 회사는 이용자의 귀책사유로 인한 서비스 이용의 장애에 대하여 책임을 지지 않습니다.
                        3. 회사는 이용자가 서비스를 통해 얻은 정보 또는 자료 등으로 인해 발생한 손해에 대하여 책임을 지지 않습니다.
                        4. 회사는 이용자 간 또는 이용자와 제3자 간에 서비스를 매개로 발생한 분쟁에 대해 개입할 의무가 없으며, 이로 인한 손해를 배상할 책임을 지지 않습니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제10조 (면책조항)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 제11조 (준거법 및 재판관할)
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 회사와 이용자 간 발생한 분쟁에 대해서는 대한민국 법을 적용합니다.
                        2. 회사와 이용자 간에 제기된 소송은 민사소송법상의 관할법원에 제기합니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("제11조 (준거법 및 재판관할)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary.opacity(0.8))
                }
                .tint(.primary.opacity(0.8))
                .padding()
                .background(Color(uiColor: .tertiarySystemBackground))
                .cornerRadius(10)
                
                // 부칙
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("""
                        1. 본 약관은 2025년 5월 26일부터 시행됩니다.
                        """)
                    }
                    .foregroundColor(.primary.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("부칙")
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
        .navigationTitle("이용약관")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
