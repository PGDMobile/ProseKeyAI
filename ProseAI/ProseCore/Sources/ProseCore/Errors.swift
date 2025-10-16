import Foundation

public enum ProseAIError: LocalizedError, Equatable {
    case unavailable
    case emptyInput
    case lengthLimit
    case cancelled
    case underlying(String)

    public var errorDescription: String? {
        switch self {
        case .unavailable:
            return NSLocalizedString("Apple Intelligence is not available on this device.", comment: "")
        case .emptyInput:
            return NSLocalizedString("Please provide text to transform.", comment: "")
        case .lengthLimit:
            return NSLocalizedString("The provided text is too long to process at once.", comment: "")
        case .cancelled:
            return NSLocalizedString("The request was cancelled.", comment: "")
        case .underlying(let message):
            return message
        }
    }
}
