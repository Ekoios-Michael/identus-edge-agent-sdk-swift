import Domain
import Foundation

// ALL parameters are DIDCOMMV2 format and naming conventions and follows the protocol
// https://github.com/hyperledger/aries-rfcs/tree/main/features/0453-issue-credential-v2
public struct IssueCredential {
    struct Body: Codable, Equatable {
        let goalCode: String?
        let comment: String?
        let replacementId: String?
        let moreAvailable: String?
        let formats: [CredentialFormat]

        init(
            goalCode: String? = nil,
            comment: String? = nil,
            replacementId: String? = nil,
            moreAvailable: String? = nil,
            formats: [CredentialFormat]
        ) {
            self.goalCode = goalCode
            self.comment = comment
            self.replacementId = replacementId
            self.moreAvailable = moreAvailable
            self.formats = formats
        }
    }

    public let id: String
    public let type = ProtocolTypes.didcommIssueCredential.rawValue
    let body: Body
    let attachments: [AttachmentDescriptor]
    public let thid: String?
    public let from: DID
    // swiftlint:disable identifier_name
    public let to: DID
    // swiftlint:enable identifier_name

    init(
        id: String = UUID().uuidString,
        body: Body,
        attachments: [AttachmentDescriptor],
        thid: String?,
        from: DID,
        // swiftlint:disable identifier_name
        to: DID
        // swiftlint:enable identifier_name
    ) {
        self.id = id
        self.body = body
        self.attachments = attachments
        self.thid = thid
        self.from = from
        self.to = to
    }

    public init(fromMessage: Message) throws {
        guard
            fromMessage.piuri == ProtocolTypes.didcommIssueCredential.rawValue,
            let fromDID = fromMessage.from,
            let toDID = fromMessage.to
        else { throw PrismAgentError.invalidIssueCredentialMessageError }

        let body = try JSONDecoder().decode(Body.self, from: fromMessage.body)
        self.init(
            id: fromMessage.id,
            body: body,
            attachments: fromMessage.attachments,
            thid: fromMessage.thid,
            from: fromDID,
            to: toDID
        )
    }

    public func makeMessage() throws -> Message {
        .init(
            id: id,
            piuri: type,
            from: from,
            to: to,
            body: try JSONEncoder().encode(body),
            attachments: attachments,
            thid: thid
        )
    }

    public static func makeIssueFromRequestCredential(msg: Message) throws -> IssueCredential {
        let request = try RequestCredential(fromMessage: msg)

        return IssueCredential(
            body: Body(
                goalCode: request.body.goalCode,
                comment: request.body.comment,
                formats: request.body.formats
            ),
            attachments: request.attachments,
            thid: msg.id,
            from: request.to,
            to: request.from)
    }

    static func build<T: Encodable>(
        fromDID: DID,
        toDID: DID,
        thid: String?,
        credentialPreview: CredentialPreview,
        credentials: [String: T] = [:]
    ) throws -> IssueCredential {
        let aux = try credentials.map { key, value in
            let attachment = try AttachmentDescriptor.build(payload: value)
            let format = CredentialFormat(attachId: attachment.id, format: key)
            return (format, attachment)
        }
        return IssueCredential(
            body: Body(
                formats: aux.map { $0.0 }
            ),
            attachments: aux.map { $0.1 },
            thid: thid,
            from: fromDID,
            to: toDID
        )
    }
}

extension IssueCredential: Equatable {
    public static func == (lhs: IssueCredential, rhs: IssueCredential) -> Bool {
        lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.body == rhs.body
    }
}