//
//  CustomerServiceChatViewController.swift
//  HYPrinter
//

import UIKit

private struct ChatMessage {
    let isAgent: Bool
    let text: String
}

/// 在线客服对话页：进入后按客服口吻定时自动回复，并支持用户输入发送。
final class CustomerServiceChatViewController: BaseViewController {

    override var shouldHideNavigationBar: Bool {
        get { false }
        set { }
    }

    private var messages: [ChatMessage] = []
    private var scriptCursor = 0
    private var autoReplyTimer: Timer?

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.separatorStyle = .none
        tv.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor
        tv.keyboardDismissMode = .interactive
        tv.estimatedRowHeight = 64
        tv.rowHeight = UITableView.automaticDimension
        tv.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tv.register(CustomerServiceChatCell.self, forCellReuseIdentifier: CustomerServiceChatCell.reuseID)
        return tv
    }()

    private let inputContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        return v
    }()

    private let inputTopLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(hexString: "#E8ECF0")
        return v
    }()

    private let textField: UITextField = {
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 16, weight: .regular)
        tf.textColor = UIColor(hexString: "#1D212C")
        tf.placeholder = "Enter your question and we will reply soon..."
        tf.returnKeyType = .send
        tf.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor
        tf.clearButtonMode = .whileEditing
        tf.layer.cornerRadius = 10
        tf.layer.masksToBounds = true
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        tf.leftView = leftView
        tf.leftViewMode = .always
        
        return tf
    }()

    private let sendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Send", for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        b.setTitleColor(.white, for: .normal)
        b.setTitleColor(.white, for: .disabled)
        b.layer.cornerRadius = 6
        b.layer.masksToBounds = true
        b.backgroundColor = kmainColor.withAlphaComponent(0.3)
        b.isEnabled = false
        return b
    }()

    private var inputBottomConstraint: Constraint?

    private static let agentScripts: [String] = [
        "Hello, this is HYPrinter online support. Glad to help you.",
        "Are you currently having issues with printer connection, document printing, or something else?",
        "Please briefly describe what happened, for example whether it shows offline or gets stuck at a step. I will help you troubleshoot step by step.",
        "If needed, you can also describe screenshots or logs in the input field below, and we will provide suggestions based on your case.",
        "Thanks for your patience. If you have no further questions for now, feel free to leave a message anytime. We are always here to help."
    ]

    override func buildSubviews() {
        super.buildSubviews()
        title = "Online Support"
        allowsInteractivePop = true
        view.backgroundColor = UIColor(hexString: "#EEF1F7") ?? kBgColor

        view.addSubview(tableView)
        view.addSubview(inputContainer)
        inputContainer.addSubview(inputTopLine)
        inputContainer.addSubview(textField)
        inputContainer.addSubview(sendButton)

        tableView.dataSource = self
        tableView.delegate = self
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        sendButton.addTarget(self, action: #selector(onSendTap), for: .touchUpInside)

        tableView.snp.makeConstraints { make in
            make.top.equalTo(topBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(inputContainer.snp.top)
        }

        inputContainer.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            inputBottomConstraint = make.bottom.equalToSuperview().constraint
        }
        inputTopLine.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(inputTopLine.snp.bottom).offset(10)
            make.bottom.equalTo(inputContainer.safeAreaLayoutGuide.snp.bottom).offset(-10)
            make.trailing.equalTo(sendButton.snp.leading).offset(-8)
            make.height.greaterThanOrEqualTo(40)
        }
        sendButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalTo(textField)
            make.width.equalTo(72)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
        beginAutoReplyIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboardNotifications()
        stopAutoReply()
    }

    private func beginAutoReplyIfNeeded() {
        guard autoReplyTimer == nil else { return }
        if messages.isEmpty {
            appendNextAgentMessage()
        }
        let t = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.appendNextAgentMessage()
        }
        RunLoop.main.add(t, forMode: .common)
        autoReplyTimer = t
    }

    private func stopAutoReply() {
        autoReplyTimer?.invalidate()
        autoReplyTimer = nil
    }

    private func appendNextAgentMessage() {
        guard !Self.agentScripts.isEmpty else { return }
        let text = Self.agentScripts[scriptCursor % Self.agentScripts.count]
        scriptCursor += 1
        messages.append(ChatMessage(isAgent: true, text: text))
        tableView.reloadData()
        scrollToBottom(animated: true)
    }

    private func scrollToBottom(animated: Bool) {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.layoutIfNeeded()
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    @objc private func textDidChange() {
        let has = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        sendButton.isEnabled = has
        
        sendButton.backgroundColor = kmainColor.withAlphaComponent(has ? 1 : 0.3)
        
    }

    @objc private func onSendTap() {
        let raw = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty else { return }
        messages.append(ChatMessage(isAgent: false, text: raw))
        textField.text = ""
        textDidChange()
        tableView.reloadData()
        scrollToBottom(animated: true)
        view.endEditing(true)
    }

    private func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    private func unregisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let frameEnd = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let kbFrameInView = view.convert(frameEnd, from: nil)
        let overlap = max(0, view.bounds.maxY - kbFrameInView.minY)
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.inputBottomConstraint?.update(inset: overlap)
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: false)
        }
    }
}

extension CustomerServiceChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CustomerServiceChatCell.reuseID, for: indexPath) as! CustomerServiceChatCell
        cell.configure(messages[indexPath.row])
        return cell
    }
}

extension CustomerServiceChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSendTap()
        return true
    }
}

// MARK: - Cell

private final class CustomerServiceChatCell: UITableViewCell {
    static let reuseID = "CustomerServiceChatCell"

    private static let avatarLength: CGFloat = 40

    private let avatarView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.layer.masksToBounds = true
        iv.backgroundColor = UIColor(hexString: "#E8ECF0")
        return iv
    }()

    private let bubble = PaddedLabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        contentView.addSubview(avatarView)

        bubble.numberOfLines = 0
        bubble.font = .systemFont(ofSize: 15, weight: .regular)
        bubble.layer.cornerRadius = 16
        bubble.layer.masksToBounds = true
        contentView.addSubview(bubble)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let horizontalInset = bubble.contentInsets.left + bubble.contentInsets.right
        let sideReserve = 12 + Self.avatarLength + 8 + 12
        let maxBubble = contentView.bounds.width - sideReserve - horizontalInset
        bubble.preferredMaxLayoutWidth = max(60, maxBubble)
    }

    func configure(_ message: ChatMessage) {
        bubble.text = message.text
        bubble.textAlignment = .left
        bubble.contentInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)

        if message.isAgent {
            avatarView.contentMode = .center
            avatarView.backgroundColor = kmainColor
            let cfg = UIImage.SymbolConfiguration(pointSize: 19, weight: .semibold)
            avatarView.image = UIImage(systemName: "headphones", withConfiguration: cfg)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            bubble.textColor = UIColor(hexString: "#1D212C")
            bubble.backgroundColor = UIColor(hexString: "#FFFFFF") ?? .white
        } else {
            avatarView.contentMode = .scaleAspectFill
            avatarView.backgroundColor = UIColor(hexString: "#E8ECF0")
            if let img = UIImage(named: "AppIconImage") {
                avatarView.image = img
            } else {
                let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
                avatarView.image = UIImage(systemName: "person.crop.circle.fill", withConfiguration: cfg)?
                    .withTintColor(UIColor(hexString: "#9AA4B2") ?? .gray, renderingMode: .alwaysOriginal)
                avatarView.contentMode = .center
            }
            bubble.textColor = .white
            bubble.backgroundColor = kmainColor
        }

        let av = Self.avatarLength
        avatarView.snp.remakeConstraints { make in
            make.size.equalTo(av)
            make.top.equalToSuperview().offset(6)
            if message.isAgent {
                make.leading.equalToSuperview().offset(12)
            } else {
                make.trailing.equalToSuperview().offset(-12)
            }
        }

        let maxBubbleWidthOffset = -(12 + Self.avatarLength + 8 + 12)
        bubble.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.width.lessThanOrEqualTo(contentView.snp.width).offset(maxBubbleWidthOffset)
            if message.isAgent {
                make.leading.equalTo(avatarView.snp.trailing).offset(8)
            } else {
                make.trailing.equalTo(avatarView.snp.leading).offset(-8)
            }
        }
    }
}

private final class PaddedLabel: UILabel {
    var contentInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + contentInsets.left + contentInsets.right, height: s.height + contentInsets.top + contentInsets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let adj = CGSize(width: size.width - contentInsets.left - contentInsets.right, height: size.height - contentInsets.top - contentInsets.bottom)
        let s = super.sizeThatFits(adj)
        return CGSize(width: s.width + contentInsets.left + contentInsets.right, height: s.height + contentInsets.top + contentInsets.bottom)
    }
}
