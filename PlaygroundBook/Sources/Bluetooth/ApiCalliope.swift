//
//  ClientCalliopeBLEDevice.swift
//  Book_Sources
//
//  Created by Tassilo Karge on 23.02.19.
//

import Foundation

class ApiCalliope: CalliopeBLEDevice {

	static let apiServices: Set<CalliopeService> =
		[.rgbLed, .microphone, .speaker, .brightness,
		 .accelerometer, .button, .led, .temperature, .event]


	override var requiredServices: Set<CalliopeService> {
		return ApiCalliope.apiServices
	}

	//MARK: Convenient way to synchronously access calliope via Bluetooth
	//TODO: Missing: parts of Event Service (we only receive events from calliope, cannot write
	//TODO: Missing: PWMControl (part of Pin Service, which we currently ignore because it is not safe to use)
	//TODO: cannot control motors yet (api not exposed via bluetooth and pins not exposed as well)

	/// action that is done to button A
	public var buttonAAction: BLEDataTypes.ButtonPressAction? {
		return read(.buttonAState)
	}

	/// notification called when Button A value is updated
	public var buttonAActionNotification: ((BLEDataTypes.ButtonPressAction?) -> ())? {
		set { setNotifyListener(for: .buttonAState, newValue) }
		get { return getNotifyListener(for: .buttonAState) }
	}

	/// action that is done to button B
	public var buttonBAction: BLEDataTypes.ButtonPressAction? {
		return read(.buttonBState)
	}

	/// notification called when Button B value is updated
	public var buttonBActionNotification: ((BLEDataTypes.ButtonPressAction?) -> ())? {
		set { setNotifyListener(for: .buttonBState, newValue) }
		get { return getNotifyListener(for: .buttonBState) }
	}

	/// which leds are on and which off.
	/// ledMatrixState[2][3] gives led 3 in row 2
	public var ledMatrixState: [[Bool]]? {
		get { return read(.ledMatrixState) }
		set { write(newValue, .ledMatrixState) }
	}


	/// scrolls a string on the display of the calliope
	/// - Parameter string: the string to display,
	///                     can contain all latin letters and some symbols
	public func displayLedText(_ string: String) {
		write(string, .ledText)
	}


	/// the delay in ms between showing successive characters of the led text
	public var scrollingDelay: UInt16 {
		get { return read(.scrollingDelay)! }
		set { write(newValue, .scrollingDelay) }
	}

	/// (X, Y, Z) value for acceleration
	public var accelerometerValue: (Int16, Int16, Int16)? {
		return read(.accelerometerData)
	}

	/// notification called when accelerometer value is being requested periodically
	public var accelerometerNotification: (((Int16, Int16, Int16)?) -> ())? {
		set { setNotifyListener(for: .accelerometerData, newValue) }
		get { return getNotifyListener(for: .accelerometerData) }
	}

	/// frequency with which the accelerometer data is read
	/// valid values: 1, 2, 5, 10, 20, 80, 160 and 640.
	public var accelerometerUpdateFrequency: UInt16? {
		get { return read(.accelerometerPeriod) }
		set { write(newValue, .accelerometerPeriod) }
	}

	/// (X, Y, Z) value for angle to magnetic pole
	public var magnetometerValue: (Int16, Int16, Int16)? {
		return read(.magnetometerData)
	}

	/// notification called when magnetometer value is being requested periodically
	public var magnetometerNotification: (((Int16, Int16, Int16)?) -> ())? {
		set { setNotifyListener(for: .magnetometerData, newValue) }
		get { return getNotifyListener(for: .magnetometerData) }
	}

	/// frequency with which the magnetometer data is read
	/// valid values: 1, 2, 5, 10, 20, 80, 160 and 640.
	public var magnetometerUpdateFrequency: UInt16? {
		get { return read(.magnetometerPeriod) }
		set { write(newValue, .magnetometerPeriod) }
	}

	/// bearing, i.e. deviation of north of the magnetometer
	public var magnetometerBearing: Int16? {
		return read(.magnetometerBearing)
	}

	/// notification called when magnetometer bearing value is changed
	public var magnetometerBearingNotification: ((Int16?) -> ())? {
		set { setNotifyListener(for: .magnetometerBearing, newValue) }
		get { return getNotifyListener(for: .magnetometerBearing) }
	}

	/// (event, value) to be received via messagebus.
	public func startNotifying(from source: BLEDataTypes.EventSource = .ANY,
									 for value: BLEDataTypes.EventValue = .ANY) {
		write([(source, value)], .clientRequirements)
	}

	/// notification called when event is raised
	public var eventNotification: (((BLEDataTypes.EventSource, BLEDataTypes.EventValue)?) -> ())? {
		set { setNotifyListener(for: .microBitEvent, newValue) }
		get { return getNotifyListener(for: .microBitEvent) }
	}

	/// temperature reading in celsius
	public var temperature: Int8? {
		return read(.temperature)
	}

	/// notification called when tx value is being requested periodically
	public var temperatureNotification: ((Int8?) -> ())? {
		set { setNotifyListener(for: .temperature, newValue) }
		get { return getNotifyListener(for: .temperature) }
	}

	/// frequency with which the temperature is updated
	var temperatureUpdateFrequency: UInt16? {
		get { return read(.temperaturePeriod) }
		set { write(newValue, .temperaturePeriod) }
	}

	/// data received via UART, 20 bytes max.
	public func readSerialData() -> Data? {
		return read(.txCharacteristic)
	}

	/// data sent via UART, 20 bytes max.
	public func sendSerialData(_ data: Data) {
		write(data, .rxCharacteristic)
	}

	//MARK: calliope specialities

	public func setSound(frequency: UInt16, duration: UInt16 = 30000) {
		write((frequency, duration), .playTone)
	}

	public func setColor(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 0) {
		write((r, g, b, a), .color)
	}

	public var noiseLevel: UInt16? {
		return read(.noise)
	}

	public var brightness: UInt8? {
		return read(.brightness)
	}

	// TODO: the pin api is not safely useable on any pin, since on-board components connected to it need very specific inputs.
	/// data read from input I/O Pins
	private func readPinData() -> [UInt8:UInt8]? {
		return read(.pinData)
	}

	/// writes to pins configured as output pins
	private func writePinData(data: [UInt8:UInt8]) {
		write(data, .pinData)
	}

	/// notification called when pinData value is changed
	private var pinDataNotification: (([UInt8:UInt8]?) -> ())? {
	set { setNotifyListener(for: .pinData, newValue) }
	get { return getNotifyListener(for: .pinData) }
	}

	/// Pins can be analogue or digital
	/// Pins used for internal purposes should not be changed.
	/// Only some pins have the capability to be analogue.
	/// Array holds one entry for each pin.
	private var pinADConfiguration: [BLEDataTypes.PinConfiguration]? {
	get { return read(.pinADConfiguration) }
	set { write(newValue, .pinADConfiguration) }
	}

	/// Pins can be configured as input or output.
	/// Pins used for internal purposes should not be changed.
	/// Input means, the pin delivers read values via bluetooth.
	/// Array holds one entry for each pin.
	private var pinIOConfiguration: [Bool]? {
	get { return read(.pinIOConfiguration) }
	set { write(newValue, .pinIOConfiguration) }
	}


	//MARK: private api


	/// writes a typed input by encoding it to data and sending it to calliope
	///
	/// - Parameters:
	///   - value: some value to be written
	///   - characteristic: some characteristic to write to. Type of value needs to match type taken by characteristic
	private func write<T>(_ value: T, _ characteristic: CalliopeCharacteristic) {
		do {
			guard let data = characteristic.encode(object: value) else { throw "could not convert \(value) for \(characteristic)" }
			try write(data, for: characteristic)
		}
		catch { LogNotify.log("failed writing to \(characteristic), value \(value)") }
	}

	/// reads a value from some calliope characteristic and adds type information to the parsed value
	///
	/// - Parameters:
	///   - characteristic: some characteristic to read from. Required type needs to match value read by characteristic
	private func read<T>(_ characteristic: CalliopeCharacteristic) -> T? {
		guard let dataBytes = try? read(characteristic: characteristic) else { return nil }
		return characteristic.interpret(dataBytes: dataBytes)
	}

	private func setNotifyListener(for characteristic: CalliopeCharacteristic, _ listener: Any?) {
		guard let cbCharacteristic = getCBCharacteristic(characteristic) else { return }
		updateListeners[characteristic] = listener
		if listener != nil {
			peripheral.setNotifyValue(true, for: cbCharacteristic)
		} else {
			peripheral.setNotifyValue(false, for: cbCharacteristic)
		}
	}

	private func getNotifyListener<T>(for characteristic: CalliopeCharacteristic) -> T? {
		return updateListeners[characteristic] as? T
	}

	override func handleValueUpdate(_ characteristic: CalliopeCharacteristic, _ value: Data) {
		//TODO: if we have all the sensor characteristics, and one updates, we can as well update the dashboard using it
		updateQueue.async {
			self.notifyListener(for: characteristic, value: value)
		}
	}

	func notifyListener(for characteristic: CalliopeCharacteristic, value: Data) {
		switch characteristic {
		case .accelerometerData:
			accelerometerNotification?(characteristic.interpret(dataBytes: value))
		case .magnetometerData:
			magnetometerNotification?(characteristic.interpret(dataBytes: value))
		case .magnetometerBearing:
			magnetometerBearingNotification?(characteristic.interpret(dataBytes: value))
		/*case .pinData:
			pinDataNotification?(characteristic.interpret(dataBytes: value))
			postSensorUpdateNotification(DashboardItemType.Pin, 0)*/
		case .buttonAState:
			buttonAActionNotification?(characteristic.interpret(dataBytes: value))
			postSensorUpdateNotification(DashboardItemType.ButtonA, 0)
		case .buttonBState:
			buttonBActionNotification?(characteristic.interpret(dataBytes: value))
			postSensorUpdateNotification(DashboardItemType.ButtonB, 0)
		case .microBitEvent:
			eventNotification?(characteristic.interpret(dataBytes: value))
		case .temperature:
			let temperature: Int8? = characteristic.interpret(dataBytes: value)
			temperatureNotification?(temperature)
			postThermometerNotification(temperature ?? 0)
		default:
			return
		}
	}
}

extension CalliopeCharacteristic {
	fileprivate func interpret<T>(dataBytes: Data?) -> T? {
		guard let dataBytes = dataBytes else { return nil }

		switch self {
		//case .pinData:
		//	var values = [UInt8:UInt8]()
		//	let sequence = stride(from: 0, to: dataBytes.count, by: 2)
		//	for element in sequence {
		//		values[dataBytes[element]] = dataBytes[element + 1]
		//	}
		//	return values as? T
		//case .pinADConfiguration, .pinIOConfiguration:
		//	let config = Array(dataBytes.flatMap { (byte) -> [Bool] in
		//		(0..<8).map { offset in (byte & (1 << offset)) == 0 ? false : true }
		//		}.prefix(19))
		//	if self == .pinADConfiguration {
		//		return config.map { b -> BLEDataTypes.PinConfiguration in b ? .Digital : .Analogue } as? T
		//	}
		//	return config as? T //TODO: hopefully the order is right...
		case .ledMatrixState:
			return dataBytes.map { (byte) -> [Bool] in
				return (1...5).map { offset in (byte & (1 << (5 - offset))) != 0 }
				} as? T
		case .scrollingDelay:
			return UInt16(littleEndianData: dataBytes) as? T
		case .buttonAState, .buttonBState:
			return BLEDataTypes.ButtonPressAction(rawValue: dataBytes[0]) as? T
		case .accelerometerData, .magnetometerData:
			return dataBytes.withUnsafeBytes {
				(int16Ptr: UnsafePointer<Int16>) -> (Int16, Int16, Int16) in
				return (Int16(littleEndian: int16Ptr[0]), //X
					Int16(littleEndian: int16Ptr[1]), //y
					Int16(littleEndian: int16Ptr[2])) //z
				} as? T
		case .accelerometerPeriod, .magnetometerPeriod, .temperaturePeriod:
			return UInt16(littleEndianData: dataBytes) as? T
		case .magnetometerBearing:
			return UInt16(littleEndianData: dataBytes) as? T
		case .microBitEvent:
			return dataBytes.withUnsafeBytes { (uint16ptr:UnsafePointer<UInt16>) -> (BLEDataTypes.EventSource, BLEDataTypes.EventValue)? in
				guard let event = BLEDataTypes.EventSource(rawValue: UInt16(littleEndian:uint16ptr[0]))
					else { return nil }
				let value = BLEDataTypes.EventValue(integerLiteral: UInt16(littleEndian:uint16ptr[1]))
				return (event, value)
				} as? T
		case .txCharacteristic:
			return dataBytes as? T
		case .temperature:
			let localized = Int8(ValueLocalizer.current.localizeTemperature(unlocalized: Double(Int8(littleEndianData: dataBytes) ?? 42)))
			return localized as? T
		case .brightness:
			return UInt8(littleEndianData: dataBytes) as? T
		case .noise:
			return UInt16(littleEndianData: dataBytes) as? T
		default:
			return nil
		}
	}

	fileprivate func encode<T>(object: T) -> Data? {
		switch self {
		case .accelerometerPeriod, .magnetometerPeriod, .temperaturePeriod:
			guard let period = object as? UInt16 else { return nil }
			return period.littleEndianData
		/*case .pinData:
			guard let pinValues = object as? [UInt8: UInt8] else { return nil }
			return Data(bytes: pinValues.flatMap { [$0, $1] })
		case .pinADConfiguration, .pinIOConfiguration:
			let obj: [Int32]?
			if self == .pinADConfiguration {
				obj = (object as? [BLEDataTypes.PinConfiguration])?.enumerated().map { $0.element == .Analogue ? (1 << $0.offset) : 0 }
			} else {
				obj = (object as? [Bool])?.enumerated().map { $0.element ? (1 << $0.offset) : 0 }
			}
			guard var asBitmap = (obj?.reduce(0) { $0 | $1 }) else { return nil }
			return Data(bytes: &asBitmap, count: MemoryLayout.size(ofValue: asBitmap))*/
		case .ledMatrixState:
			guard let ledArray = object as? [[Bool]] else { return nil }
			let bitmapArray = ledArray.map {
				$0.enumerated().reduce(UInt8(0)) {
					$1.element == false ? $0 : ($0 | 1 << (4 - $1.offset))
				}
			}
			return Data(bitmapArray)
		case .ledText:
			return (object as? String)?.data(using: .utf8)
		case .scrollingDelay:
			guard let delay = object as? UInt16 else { return nil }
			return delay.bigEndianData
		case .rxCharacteristic:
			return object as? Data
		case .clientRequirements:
			guard let eventTuples = object as? [(BLEDataTypes.EventSource, BLEDataTypes.EventValue)] else { return nil }
			return eventTuples.flatMap({ (tuple: (BLEDataTypes.EventSource, BLEDataTypes.EventValue)) -> [Data] in
				[tuple.0.rawValue.littleEndianData, tuple.1.value.littleEndianData]
			}).reduce(into: Data()) { $0.append($1) }
		case .color:
			guard let (r, g, b, a) = object as? (UInt8, UInt8, UInt8, UInt8) else { return nil }
			return r.littleEndianData + g.littleEndianData + b.littleEndianData + a.littleEndianData
		case .playTone:
			guard let (tone, duration) = object as? (UInt16, UInt16) else { return nil }
			return tone.littleEndianData + duration.littleEndianData
		default:
			return nil
		}
	}
}