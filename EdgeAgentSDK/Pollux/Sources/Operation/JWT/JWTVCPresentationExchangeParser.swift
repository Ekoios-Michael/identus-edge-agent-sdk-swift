import Domain
import Foundation
import JSONSchema
import JSONWebToken

struct JWTVCPresentationExchangeParser: SubmissionDescriptorFormatParser {
    let format = "jwt_vc"
    let verifier: VerifyJWT

    func parse(path: String, presentationData: Data) async throws -> String {
        guard
            let jwt = presentationData.query(string: path)
        else {
            throw PolluxError.credentialPathInvalid(path: path)
        }

        guard try await verifier.verifyJWT(jwtString: jwt) else {
            throw PolluxError.cannotVerifyCredential(credential: jwt, internalErrors: [])
        }

        return jwt
    }

    func parsePayload(path: String, presentationData: Data) async throws -> Data {
        let jwt = try await parse(path: path, presentationData: presentationData)
        return try JWT.getPayload(jwtString: jwt)
    }

    func parseClaimVerifier(descriptor: PresentationSubmission.Descriptor, presentationData: Data) async throws -> PresentationExchangeClaimVerifier {
        let jwt = try await parse(path: descriptor.path, presentationData: presentationData)
        return JWTVerifierPresentationExchange(
            castor: verifier.castor,
            jwtString: jwt,
            submissionDescriptor: descriptor
        )
    }
}