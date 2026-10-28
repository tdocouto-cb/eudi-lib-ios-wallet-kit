/*
 Copyright (c) 2026 European Commission

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
import Foundation
import MdocDataModel18013
import WalletStorage

/// Result of an OpenID4VCI issuance operation.
///
/// Pairs the issued documents with the decoded issuer registration policy and any violations
/// produced by the WRP registration certificate (WRPRC) policy when
/// ``OpenId4VciConfiguration/validateRegistrationCertificate`` is enabled.
public struct IssuerResponse: Sendable {
	/// The issued documents. They are already saved in storage.
	public let documents: [WalletStorage.Document]
	/// Typed violations produced by the WRP registration certificate policy, keyed by credential
	/// configuration identifier; the empty key holds request-wide violations.
	/// `nil` when registration certificate validation is not enabled.
	public let wrpIssuerWarnings: [String: [RegistrationPolicyViolation]]?
	/// The WRP registration policy decoded from the issuer registration certificate (WRPRC),
	/// available when ``OpenId4VciConfiguration/validateRegistrationCertificate`` is enabled.
	/// Preserved even when validation fails (expiry, revocation, trust) so the issuer identity can be inspected.
	public let wrpIssuerPolicy: WrpRegistrationPolicy?
	/// The offered credentials that the wallet did not store. The stored credentials are in ``documents``.
	public let failures: [IssuanceFailure]

	public init(documents: [WalletStorage.Document], wrpIssuerWarnings: [String: [RegistrationPolicyViolation]]?, wrpIssuerPolicy: WrpRegistrationPolicy? = nil, failures: [IssuanceFailure] = []) {
		self.documents = documents
		self.wrpIssuerWarnings = wrpIssuerWarnings
		self.wrpIssuerPolicy = wrpIssuerPolicy
		self.failures = failures
		if let warns = wrpIssuerWarnings, !warns.isEmpty { logger.info("Issuer registration warnings: \(warns)") }
	}

	/// Registration-policy violations matched to each issued document, keyed by document identifier.
	///
	/// A document is matched to the violations of its credential configuration identifier
	/// (taken from the document metadata).
	public var documentWarnings: [WalletStorage.Document.ID: [RegistrationPolicyViolation]] {
		var result = [WalletStorage.Document.ID: [RegistrationPolicyViolation]]()
		for document in documents {
			guard let configurationIdentifier = DocMetadata(from: document.metadata)?.configurationIdentifier,
				let warnings = wrpIssuerWarnings?[configurationIdentifier], !warnings.isEmpty else { continue }
			result[document.id] = warnings
		}
		return result
	}
}

/// An offered credential that the wallet did not store.
public struct IssuanceFailure: Sendable {
	/// The credential configuration identifier of the offer.
	public let credentialConfigurationIdentifier: String
	public let displayName: String
	/// The description of the error.
	public let message: String

	public init(credentialConfigurationIdentifier: String, displayName: String, message: String) {
		self.credentialConfigurationIdentifier = credentialConfigurationIdentifier
		self.displayName = displayName
		self.message = message
	}
}
