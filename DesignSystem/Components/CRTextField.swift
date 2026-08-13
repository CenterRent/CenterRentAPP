import SwiftUI

// MARK: - CRTextField
struct CRTextField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String
    var icon: String? = nil
    var leadingIcon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var isSecure: Bool = false
    var isRequired: Bool = false
    var errorMessage: String? = nil
    var helperText: String? = nil
    var maxLength: Int? = nil
    var prefix: String? = nil
    @State private var isSecureVisible = false
    @FocusState private var isFocused: Bool

    // Unlabeled first-arg init (used by Features/)
    init(_ label: String,
         text: Binding<String>,
         placeholder: String = "",
         isRequired: Bool = false,
         keyboardType: UIKeyboardType = .default,
         textContentType: UITextContentType? = nil,
         leadingIcon: String? = nil,
         icon: String? = nil,
         isSecure: Bool = false,
         errorMessage: String? = nil,
         helperText: String? = nil,
         maxLength: Int? = nil,
         prefix: String? = nil) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.leadingIcon = leadingIcon
        self.icon = icon ?? leadingIcon
        self.isSecure = isSecure
        self.errorMessage = errorMessage
        self.helperText = helperText
        self.maxLength = maxLength
        self.prefix = prefix
    }

    // Labeled first-arg init (used by old Views/)
    init(label: String,
         placeholder: String = "",
         text: Binding<String>,
         icon: String? = nil,
         keyboardType: UIKeyboardType = .default,
         isSecure: Bool = false,
         errorMessage: String? = nil) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.icon = icon
        self.leadingIcon = icon
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.errorMessage = errorMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CRSpacing.xs) {
            if !label.isEmpty {
                HStack(spacing: 2) {
                    Text(label).font(.crLabelSmall).foregroundColor(.crTextSecondary)
                    if isRequired { Text("*").font(.crLabelSmall).foregroundColor(.crError) }
                }
            }

            HStack(spacing: CRSpacing.sm) {
                if let pfx = prefix {
                    Text(pfx).font(.crBodyLarge).foregroundColor(.crTextSecondary)
                    Divider().frame(height: 20)
                }
                if let ic = leadingIcon ?? icon {
                    Image(systemName: ic)
                        .font(.system(size: 16))
                        .foregroundColor(isFocused ? .crPrimary : .crTextTertiary)
                        .frame(width: 20)
                }
                if isSecure && !isSecureVisible {
                    SecureField(placeholder, text: $text)
                        .font(.crBodyLarge).focused($isFocused)
                        .textContentType(textContentType)
                } else {
                    TextField(placeholder, text: $text)
                        .font(.crBodyLarge)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                        .textContentType(textContentType)
                        .onChange(of: text) { _, new in
                            if let max = maxLength, new.count > max {
                                text = String(new.prefix(max))
                            }
                        }
                }
                if isSecure {
                    Button { isSecureVisible.toggle() } label: {
                        Image(systemName: isSecureVisible ? "eye.slash" : "eye")
                            .font(.system(size: 16)).foregroundColor(.crTextTertiary)
                    }
                }
            }
            .padding(.horizontal, CRSpacing.base)
            .frame(height: 52)
            .background(Color.white)
            .cornerRadius(CRRadius.md)
            .overlay(RoundedRectangle(cornerRadius: CRRadius.md)
                .stroke(borderColor, lineWidth: isFocused ? 2 : 1))

            if let error = errorMessage {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.crCaption).foregroundColor(.crError)
            } else if let helper = helperText {
                Text(helper).font(.crCaption).foregroundColor(.crTextTertiary)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return .crError }
        return isFocused ? .crPrimary : .crDivider
    }
}

// MARK: - CRSecureTextField (convenience wrapper)
struct CRSecureTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isRequired: Bool = false
    var errorMessage: String? = nil

    init(_ label: String,
         text: Binding<String>,
         placeholder: String = "",
         isRequired: Bool = false,
         errorMessage: String? = nil) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.errorMessage = errorMessage
    }

    var body: some View {
        CRTextField(label, text: $text,
                    placeholder: placeholder.isEmpty ? label : placeholder,
                    isRequired: isRequired,
                    isSecure: true,
                    errorMessage: errorMessage)
    }
}

// MARK: - CROTPTextField
struct CROTPTextField: View {
    let length: Int
    @Binding var otpCode: String
    @FocusState private var isFocused: Bool

    init(length: Int = 6, otpCode: Binding<String>) {
        self.length = length
        self._otpCode = otpCode
    }

    var body: some View {
        HStack(spacing: CRSpacing.sm) {
            ForEach(0..<length, id: \.self) { i in
                let char: String = i < otpCode.count
                    ? String(otpCode[otpCode.index(otpCode.startIndex, offsetBy: i)])
                    : ""
                ZStack {
                    RoundedRectangle(cornerRadius: CRRadius.md)
                        .stroke(isFocused && otpCode.count == i ? Color.crPrimary : Color.crDivider, lineWidth: 2)
                        .background(Color.white.cornerRadius(CRRadius.md))
                        .frame(width: 48, height: 56)
                    Text(char).font(.crH2).foregroundColor(.crTextPrimary)
                }
            }
        }
        .overlay(
            TextField("", text: $otpCode)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0.01)
                .onChange(of: otpCode) { _, new in
                    let filtered = new.filter { $0.isNumber }
                    if filtered.count > length { otpCode = String(filtered.prefix(length)) }
                    else if filtered != new { otpCode = filtered }
                }
        )
        .onAppear { isFocused = true }
    }
}

// MARK: - CROTPField (legacy — use CROTPTextField instead)
struct CROTPField: View {
    @Binding var code: [String]
    let count: Int

    init(code: Binding<[String]>, count: Int = 4) {
        self._code = code
        self.count = count
    }

    var body: some View {
        HStack(spacing: CRSpacing.md) {
            ForEach(0..<count, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: CRRadius.md)
                        .stroke(Color.crDivider, lineWidth: 2)
                        .frame(width: 64, height: 64)
                        .background(Color.white.cornerRadius(CRRadius.md))
                    if i < code.count && !code[i].isEmpty {
                        Text(code[i]).font(.crH2).foregroundColor(.crTextPrimary)
                    }
                }
            }
        }
    }
}
