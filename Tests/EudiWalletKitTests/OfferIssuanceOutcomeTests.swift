/*
 * Copyright (c) 2026 European Commission
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Testing
@testable import EudiWalletKit
import Foundation
import MdocDataModel18013
import WalletStorage

/// Each offered credential is a separate request. A failed credential does not remove the stored ones.
@Suite("Offer issuance outcomes")
struct OfferIssuanceOutcomeTests {
	private struct IssueError: Error {}

	private static func document(_ id: String) -> WalletStorage.Document {
		WalletStorage.Document(id: id, docType: "eu.europa.ec.eudi.pid.1", docDataFormat: .cbor, data: Data(), docKeyInfo: nil, createdAt: Date(), metadata: nil, displayName: nil, status: .issued)
	}

	@Test("stored documents are returned with the failed offers")
	func returnsStoredAndFailed() throws {
		let (documents, failures) = try OpenId4VciService.splitOutcomes([
			(0, .success(Self.document("a"))),
			(1, .failure(IssueError())),
			(2, .success(Self.document("c"))),
		])
		#expect(documents.map(\.id) == ["a", "c"])
		#expect(failures.map(\.0) == [1])
	}

	@Test("no failures when all offers are stored")
	func allStored() throws {
		let (documents, failures) = try OpenId4VciService.splitOutcomes([(0, .success(Self.document("a")))])
		#expect(documents.count == 1)
		#expect(failures.isEmpty)
	}

	@Test("the first error is thrown when no offer is stored")
	func throwsWhenNothingStored() {
		#expect(throws: IssueError.self) {
			try OpenId4VciService.splitOutcomes([(0, .failure(IssueError())), (1, .failure(IssueError()))])
		}
	}
}
