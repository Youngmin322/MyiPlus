//
//  MinutesPickerActionSheet.swift
//  MyiApp
//
//  Created by 최범수 on 2025-05-13.
//

import SwiftUI


struct MinutesPickerActionSheet: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedAmount: Int?
    
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
        
        let currentRow = selectedAmount
        pickerView.selectRow(currentRow ?? 0, inComponent: 0, animated: false)
        
        alert.view.addSubview(pickerView)
        
        alert.addAction(UIAlertAction(title: "완료", style: .default, handler: { _ in
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            selectedAmount = selectedRow
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
        private let parent: MinutesPickerActionSheet
        
        init(_ parent: MinutesPickerActionSheet) {
            self.parent = parent
        }
        
        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            return 1
        }
        
        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            return 121
        }
        
        func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
            let text = "\(row)"
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
