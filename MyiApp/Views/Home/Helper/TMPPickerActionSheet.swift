//
//  TMPPickerActionSheet.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-13.
//

import SwiftUI

struct TMPPickerActionSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedTemperature: Double
    
    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard isPresented, uiViewController.presentedViewController == nil else { return }
        
        let alert = UIAlertController(title: "", message: String(repeating: "\n", count: 9), preferredStyle: .actionSheet)
        
        let pickerView = UIPickerView()
        pickerView.frame = CGRect(
            origin: .zero,
            size: CGSize(
                width: alert.view.frame.size.width - 16,
                height: 210
            )
        )
        pickerView.delegate = context.coordinator
        pickerView.dataSource = context.coordinator
        
        let currentRow = Int((selectedTemperature - 35.0) * 10)
        pickerView.selectRow(currentRow, inComponent: 0, animated: false)
        
        alert.view.addSubview(pickerView)
        
        alert.addAction(UIAlertAction(title: "완료", style: .default, handler: { _ in
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            selectedTemperature = 35.0 + Double(selectedRow) * 0.1
            isPresented = false
        }))
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in
            isPresented = false
        }))
        
        DispatchQueue.main.async {
            uiViewController.present(alert, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
        private let parent: TMPPickerActionSheet
        
        init(_ parent: TMPPickerActionSheet) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return 41 // 35.0 ~ 39.0
        }
        
        func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            let temperature = 35.0 + Double(row) * 0.1
            let text = String(format: "%.1f", temperature)
            let attributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.alignment = .center
                    return style
                }()
            ]
            return NSAttributedString(string: text, attributes: attributes)
        }
    }
}

#Preview {
    TMPPickerActionSheet(isPresented: .constant(false), selectedTemperature: .constant(36.5))
}
