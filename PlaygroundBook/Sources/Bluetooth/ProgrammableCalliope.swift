//
//  ProgrammableCalliopeBLEDevice.swift
//  Book_Sources
//
//  Created by Tassilo Karge on 23.02.19.
//

import Foundation
import CoreBluetooth

class ProgrammableCalliope: CalliopeBLEDevice {

	static let programmingServices: Set<CalliopeService> =
		[.interpreter]

	static let programmingServicesLegacy: Set<CalliopeService> =
		[.notify, .program]


	override var requiredServices: Set<CalliopeService> {
		return hasMasterService
			? ProgrammableCalliope.programmingServices
			: ProgrammableCalliope.programmingServicesLegacy
	}

	// MARK: Uploading programs via program characteristic

	func upload(program: ProgramBuildResult) throws {
		guard state == .playgroundReady else { throw "Not ready to receive programs yet" }

		//code of the program
		let code : [UInt8] = program.code
		//methods of the program
		let methods : [UInt16] = program.methods

		//never crashes because we made sure we are ready for the playground, i.e. we have all required services
		guard let programCharacteristic = getCBCharacteristic(programOrNotify: .program) else { throw "Program characteristic not available" }

		// transfer code in parts

		//offset of current program part
		var address = 0

		//upload porogram in pieces of size 16 bytes
		try partition(data: Data(bytes: code), size: 16)
			.forEach { part in
				//transfer part of program and wait for response
				let len = part.count
				var packet = Data(bytes: [
					len.hi(), len.lo(),
					address.hi(), address.lo(),
					])
				packet.append(part)

				LOG(String(format: "packet address:%.4x len:%.4x", address, len))

				try write(packet, for: programCharacteristic)
				address += len
		}

		// transfer end packet
		//TODO: hash should probably be a hash of the program, but is always 0
		let hash_is = UInt16(0)
		var packet = Data(bytes: [
			0x00, 0x00, // len = 0
			hash_is.hi(), hash_is.lo(),
			])
		for method in methods {
			packet.append(method.hi())
			packet.append(method.lo())
		}
		try write(packet, for: programCharacteristic)
	}

	private func partition(data: Data, size: Int) -> [Data] {
		return stride(from: 0, to: data.count, by: size).map {
			data.subdata(in: $0 ..< Swift.min($0 + size, data.count))
		}
	}

	override func handleStateUpdate() {
		super.handleStateUpdate()
		if state == .playgroundReady {
			do { try readSensors(true) }
			catch { LogNotify.log("\(self)\ncannot start sensor readings") }
		}
	}

	override func handleValueUpdate(_ characteristic: CalliopeCharacteristic, _ value: Data) {
		if characteristic == .notify {
			updateSensorReading(value)
		} else {
			LogNotify.log("programmable calliope received value for characteristic other than notify:\n \(characteristic), \(value)")
			return
		}
	}

	func getCBCharacteristic(programOrNotify calliopeCharacteristic: CalliopeCharacteristic) -> CBCharacteristic? {
		let characteristic: CBCharacteristic?
		if hasMasterService {
			characteristic = getCBCharacteristic(CalliopeService.interpreter.uuid, calliopeCharacteristic.uuid)
		} else {
			characteristic = getCBCharacteristic(calliopeCharacteristic.uuid, calliopeCharacteristic.uuid)
		}
		return characteristic
	}
}

extension ProgrammableCalliope {



	// MARK: Receiving sensor values via notify characteristic

	func readSensors(_ enabled: Bool) throws {
		guard state == .playgroundReady else { throw "Not ready to read sensor values" }
		//never throws because we made sure we are ready for the playground, i.e. we have all required services

		guard let cbCharacteristic = getCBCharacteristic(programOrNotify: .notify) else { throw "Notify characteristic not available" }

		peripheral.setNotifyValue(enabled, for: cbCharacteristic)
	}

	func updateSensorReading(_ value: Data) {

		if let type = DashboardItemType(rawValue:UInt16(value[1])) {
			LogNotify.log("\(self) received value \(String(describing: UInt16(littleEndianData: value.subdata(in: 2..<value.count))))) for \(type)")
			let value = int8(Int(value[3]))

			//TODO: do not use notification center, but let observers subscribe directly to sensorReadings´ value
			//TODO: subscription to swift dictionaries via didSet works.
			if(type == DashboardItemType.ButtonAB) {
				postButtonANotification(value)
				postButtonBNotification(value)
			} else if type == DashboardItemType.Thermometer {
				postThermometerNotification(Int8(ValueLocalizer.current.localizeTemperature(unlocalized: Double(value))))
			} else {
				postSensorUpdateNotification(type, value)
			}
		}
	}
}
