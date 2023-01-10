import Combine
import Domain
import Foundation
import PrismAgent

final class ProofOfRequestViewModelImpl: ProofOfRequestViewModel {
    @Published var contact: ProofOfRequestState.Contact = .init(text: "")
    @Published var flowStep: ProofOfRequestState.FlowStep = .loading
    @Published var credential = [ProofOfRequestState.Credential]()
    @Published var checks = [Bool]()
    @Published var loading = false
    @Published var dismiss = false

    private let proofOfRequest: RequestPresentation
    private let agent: PrismAgent
    private var selectedCredential: VerifiableCredential?
    private var cancellables = Set<AnyCancellable>()

    init(
        proofOfRequest: RequestPresentation,
        agent: PrismAgent
    ) {
        self.proofOfRequest = proofOfRequest
        self.agent = agent
    }

    func viewDidAppear() {
        contact = .init(text: "Proof request received")
        agent.verifiableCredentials()
            .first { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .map { credentials -> [VerifiableCredential] in
                self.selectedCredential = credentials.first
                return credentials
            }
            .map { credentials -> [ProofOfRequestState.Credential] in
                credentials.map {
                    ProofOfRequestState.Credential(
                        id: $0.id,
                        text: $0.credentialSubject.sorted { $0.key < $1.key }.first?.value ?? ""
                    )
                }
            }
            .replaceError(with: [])
            .map { credentials -> [ProofOfRequestState.Credential] in
                self.flowStep = .shareCredentials
                return credentials
            }
            .assign(to: &$credential)
    }

    func sendPresentation() {
        guard !loading else { return }
        loading = true
    }

    func share() {
        guard let selectedCredential else { return }
        loading = true
        Task {
            do {
                try await agent.presentCredentialProof(
                    request: self.proofOfRequest,
                    credential: selectedCredential
                )
                guard
                    let index = agent.requestedPresentations
                        .value
                        .firstIndex(where: { $0.0.id == proofOfRequest.id })
                else { return }
                agent.requestedPresentations.value[index] = (proofOfRequest, true)
                await MainActor.run {
                    self.loading = false
                    self.dismiss = true
                }
            } catch {
                await MainActor.run {
                    self.loading = false
                }
            }
        }
    }

    func confirmDismiss() {
        guard
            let index = agent.requestedPresentations
                .value
                .firstIndex(where: { $0.0.id == proofOfRequest.id })
        else { return }
        agent.requestedPresentations.value[index] = (proofOfRequest, true)
    }
}