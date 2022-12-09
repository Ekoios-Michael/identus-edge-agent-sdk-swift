import Core
import Domain
import Foundation

struct MediationKeysUpdateList {
    struct Body: Encodable {
        struct Update: Encodable {
            let recipientDid: String
            let action = "add"
        }
        let updates: [Update]
    }

    let id: String
    let from: DID
    let to: DID
    let type = ProtocolTypes.didcommMediationKeysUpdate.rawValue
    let body: Body

    init(
        id: String = UUID().uuidString,
        from: DID,
        to: DID,
        recipientDid: DID
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.body = .init(
            updates: [.init(
                recipientDid: recipientDid.string
            )]
        )
    }

    func makeMessage() throws -> Message {
        return Message(
            id: id,
            piuri: type,
            from: from,
            to: to,
            body: try JSONEncoder.didComm().encode(body)
        )
    }
}
