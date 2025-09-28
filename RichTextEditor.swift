import SwiftUI
import UIKit

// MARK: - Rich Text Editor
struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSMutableAttributedString
    let placeholder: String
    
    @State private var textViewHeight: CGFloat = 100
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        // Configure text view
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isScrollEnabled = true
        textView.backgroundColor = UIColor.secondarySystemBackground
        textView.layer.cornerRadius = 12
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        
        // Setup toolbar
        textView.inputAccessoryView = createToolbar(for: textView, coordinator: context.coordinator)
        
        // Set placeholder if needed
        if attributedText.string.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.placeholderText
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if attributedText.string != uiView.attributedText.string {
            uiView.attributedText = attributedText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func createToolbar(for textView: UITextView, coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        // Formatting buttons
        let boldButton = UIBarButtonItem(
            image: UIImage(systemName: "bold"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.toggleBold)
        )
        
        let italicButton = UIBarButtonItem(
            image: UIImage(systemName: "italic"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.toggleItalic)
        )
        
        let underlineButton = UIBarButtonItem(
            image: UIImage(systemName: "underline"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.toggleUnderline)
        )
        
        let strikethroughButton = UIBarButtonItem(
            image: UIImage(systemName: "strikethrough"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.toggleStrikethrough)
        )
        
        let listButton = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.toggleBulletList)
        )
        
        let checkboxButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark.square"),
            style: .plain,
            target: coordinator,
            action: #selector(Coordinator.addCheckbox)
        )
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let doneButton = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: coordinator,
            action: #selector(Coordinator.dismissKeyboard)
        )
        
        toolbar.setItems([
            boldButton, italicButton, underlineButton, strikethroughButton,
            flexSpace, listButton, checkboxButton, flexSpace, doneButton
        ], animated: false)
        
        return toolbar
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            self.textView = textView
            
            // Clear placeholder
            if textView.textColor == UIColor.placeholderText {
                textView.text = ""
                textView.textColor = UIColor.label
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // Add placeholder if empty
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.placeholderText
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if textView.textColor != UIColor.placeholderText {
                parent.attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            }
        }
        
        // MARK: - Formatting Actions
        @objc func toggleBold() {
            guard let textView = textView else { return }
            applyFormatting(textView, trait: .traitBold)
        }
        
        @objc func toggleItalic() {
            guard let textView = textView else { return }
            applyFormatting(textView, trait: .traitItalic)
        }
        
        @objc func toggleUnderline() {
            guard let textView = textView else { return }
            let range = textView.selectedRange
            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            
            let currentAttributes = mutableText.attributes(at: max(0, range.location - 1), effectiveRange: nil)
            if currentAttributes[.underlineStyle] != nil {
                mutableText.removeAttribute(.underlineStyle, range: range)
            } else {
                mutableText.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
            
            textView.attributedText = mutableText
            textView.selectedRange = range
            parent.attributedText = mutableText
        }
        
        @objc func toggleStrikethrough() {
            guard let textView = textView else { return }
            let range = textView.selectedRange
            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            
            let currentAttributes = mutableText.attributes(at: max(0, range.location - 1), effectiveRange: nil)
            if currentAttributes[.strikethroughStyle] != nil {
                mutableText.removeAttribute(.strikethroughStyle, range: range)
            } else {
                mutableText.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
            }
            
            textView.attributedText = mutableText
            textView.selectedRange = range
            parent.attributedText = mutableText
        }
        
        @objc func toggleBulletList() {
            guard let textView = textView else { return }
            insertBulletPoint(textView)
        }
        
        @objc func addCheckbox() {
            guard let textView = textView else { return }
            insertCheckbox(textView)
        }
        
        @objc func dismissKeyboard() {
            textView?.resignFirstResponder()
        }
        
        // MARK: - Helper Methods
        private func applyFormatting(_ textView: UITextView, trait: UIFontDescriptor.SymbolicTraits) {
            let range = textView.selectedRange
            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            
            if range.length == 0 {
                // Apply to next typed text
                let currentFont = textView.typingAttributes[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
                let newFont = toggleFontTrait(currentFont, trait: trait)
                textView.typingAttributes[.font] = newFont
            } else {
                // Apply to selected text
                mutableText.enumerateAttribute(.font, in: range) { (font, range, _) in
                    let currentFont = font as? UIFont ?? UIFont.systemFont(ofSize: 16)
                    let newFont = toggleFontTrait(currentFont, trait: trait)
                    mutableText.addAttribute(.font, value: newFont, range: range)
                }
                
                textView.attributedText = mutableText
                textView.selectedRange = range
                parent.attributedText = mutableText
            }
        }
        
        private func toggleFontTrait(_ font: UIFont, trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
            let descriptor = font.fontDescriptor
            let existingTraits = descriptor.symbolicTraits
            
            let newTraits: UIFontDescriptor.SymbolicTraits
            if existingTraits.contains(trait) {
                newTraits = existingTraits.subtracting(trait)
            } else {
                newTraits = existingTraits.union(trait)
            }
            
            if let newDescriptor = descriptor.withSymbolicTraits(newTraits) {
                return UIFont(descriptor: newDescriptor, size: font.pointSize)
            }
            
            return font
        }
        
        private func insertBulletPoint(_ textView: UITextView) {
            let currentPosition = textView.selectedRange.location
            let text = textView.text ?? ""
            
            // Find the beginning of the current line
            let currentLineStart = text.prefix(currentPosition).lastIndex(of: "\n")?.utf16Offset(in: text) ?? 0
            let actualLineStart = currentLineStart == 0 ? 0 : currentLineStart + 1
            
            let bulletText = "• "
            let insertionRange = NSRange(location: actualLineStart, length: 0)
            
            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            mutableText.insert(NSAttributedString(string: bulletText), at: insertionRange.location)
            
            textView.attributedText = mutableText
            textView.selectedRange = NSRange(location: insertionRange.location + bulletText.count, length: 0)
            parent.attributedText = mutableText
        }
        
        private func insertCheckbox(_ textView: UITextView) {
            let currentPosition = textView.selectedRange.location
            let text = textView.text ?? ""
            
            // Find the beginning of the current line
            let currentLineStart = text.prefix(currentPosition).lastIndex(of: "\n")?.utf16Offset(in: text) ?? 0
            let actualLineStart = currentLineStart == 0 ? 0 : currentLineStart + 1
            
            let checkboxText = "☐ "
            let insertionRange = NSRange(location: actualLineStart, length: 0)
            
            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            mutableText.insert(NSAttributedString(string: checkboxText), at: insertionRange.location)
            
            textView.attributedText = mutableText
            textView.selectedRange = NSRange(location: insertionRange.location + checkboxText.count, length: 0)
            parent.attributedText = mutableText
        }
    }
}

// MARK: - String Extensions for Text Processing
extension String {
    func lastIndex(of character: Character) -> String.Index? {
        return self.lastIndex(where: { $0 == character })
    }
}

extension String.Index {
    func utf16Offset(in string: String) -> Int {
        return string.utf16.distance(from: string.startIndex, to: self)
    }
}

// MARK: - Rich Text Display Component
struct AttributedTextView: UIViewRepresentable {
    let attributedText: NSAttributedString
    let isEditable: Bool
    
    init(_ attributedText: NSAttributedString, isEditable: Bool = false) {
        self.attributedText = attributedText
        self.isEditable = isEditable
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = isEditable
        textView.isScrollEnabled = false
        textView.backgroundColor = UIColor.clear
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        
        // Handle checkbox interactions if not editable
        if !isEditable {
            textView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
            textView.addGestureRecognizer(tapGesture)
        }
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText.string != attributedText.string {
            uiView.attributedText = attributedText
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: AttributedTextView
        
        init(_ parent: AttributedTextView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let textView = gesture.view as? UITextView else { return }
            
            let location = gesture.location(in: textView)
            let characterIndex = textView.layoutManager.characterIndex(
                for: location,
                in: textView.textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )
            
            let text = textView.attributedText.string
            
            // Check if tap is on a checkbox
            if characterIndex < text.count {
                let character = text[text.index(text.startIndex, offsetBy: characterIndex)]
                if character == "☐" || character == "☑" {
                    toggleCheckbox(at: characterIndex, in: textView)
                }
            }
        }
        
        private func toggleCheckbox(at index: Int, in textView: UITextView) {
            let mutableText = NSMutableAttributedString(attributedString: textView.attributedText)
            let text = mutableText.string
            
            guard index < text.count else { return }
            
            let character = text[text.index(text.startIndex, offsetBy: index)]
            let newCharacter: String
            
            if character == "☐" {
                newCharacter = "☑"
            } else if character == "☑" {
                newCharacter = "☐"
            } else {
                return
            }
            
            let range = NSRange(location: index, length: 1)
            mutableText.replaceCharacters(in: range, with: newCharacter)
            
            textView.attributedText = mutableText
        }
    }
}