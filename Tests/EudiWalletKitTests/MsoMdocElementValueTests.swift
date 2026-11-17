import Foundation
import MdocDataModel18013
import MdocDataTransfer18013
import SwiftCBOR
import Testing
@testable import EudiWalletKit

/// A requested mdoc element shows the value of the issued element, not a redacted description.
@Suite("mdoc element value")
struct MsoMdocElementValueTests {
	@Test("The string value of a requested element is the value of the issued element")
	func stringValueIsTheIssuedValue() throws {
		let issued = try IssuerSignedItem(cbor: .map([
			"digestID": .unsignedInt(1),
			"random": .byteString([1, 2, 3]),
			"elementIdentifier": .utf8String("family_name"),
			"elementValue": .utf8String("Doe"),
		]))
		let element = RequestItem(elementPath: ["family_name"])
			.extractMsoMdocElement(ns: "org.iso.18013.5.1", nsItems: [issued], docClaims: [], isMandatory: true)
		#expect(element.stringValue == "Doe")
		#expect(element.isValid)
	}
}
