// OK
public final class BookProgramProjectRockPaperScissors: ProgramBase, Program {

	public static let assessment: AssessmentBlock = { values in

		let success = "page.success".localized
		let hints = [
			"page.hint1".localized,
			"page.hint2".localized,
			"page.hint3".localized
		]
		let solution = "page.solution".localized

		let time_hint = [ "page.hint.time".localized ]
		let time_solution = "page.solution.time".localized

		guard let speed = UInt16(values[0]) else {
			return (.fail(hints: hints, solution: solution), nil)
		}

		//if speed < 100 {
		//return (.fail(hints: time_hint, solution: time_solution), nil)
		//}

		guard let img1 = miniImage(from: values[1]) else {
			return (.fail(hints: hints, solution: solution), nil)
		}

		guard let img2 = miniImage(from: values[2]) else {
			return (.fail(hints: hints, solution: solution), nil)
		}

		guard let img3 = miniImage(from: values[3]) else {
			return (.fail(hints: hints, solution: solution), nil)
		}

		let p = BookProgramProjectRockPaperScissors()
		p.speed = Int16(speed)
		p.image1 = img1
		p.image2 = img2
		p.image3 = img3

		// return (.pass(message: success), p)
		return (nil, p)
	}

	public var speed: Int16 = 10

    public var image1: miniImage = .arrow_left
    public var image2: miniImage = .arrow_right
    public var image3: miniImage = .arrow_left_right

    func waitOnButton() -> [UInt8] {
        return [
            movi16(speed, .r1),
            sleep(.r1),

            movi16(Button.a.rawValue, .r0),
            button(.r0),
            beq(21 + 3),

            movi16(NotificationAddress.buttonA.rawValue, .r4),
            notify(address: .r4, value: .r4),

            movi16(Button.a.rawValue, .r0),
            button(.r0),
            bne(-8),

            sleep(.r1),
        ].flatMap { $0 }
    }

    public func build() -> ProgramBuildResult {

        let notify_display: [UInt8] = [
            movi16(NotificationAddress.display.rawValue, .r4),
            notify(address: .r4, value: .r4),
        ].flatMap { $0 }

        let rock: [UInt8] = [
            notify_display,
            movi16(image1.rawValue, .r0),
            showImage(.r0),
            waitOnButton(),
        ].flatMap { $0 }

        let paper: [UInt8] = [
            notify_display,
            movi16(image2.rawValue, .r0),
            showImage(.r0),
            waitOnButton(),
        ].flatMap { $0 }

        let scissors: [UInt8] = [
            notify_display,
            movi16(image3.rawValue, .r0),
            showImage(.r0),
            waitOnButton(),
        ].flatMap { $0 }

        let code: [UInt8] = [
            rock +
            paper +
            scissors
        ].flatMap { $0 }

        let methods: [UInt16] = [
            0xffff,
            0x0000,
            0xffff,
            0xffff,
            0xffff,
        ]

        return ProgramBuildResult(code: code, methods: methods)
    }

    public override init() {
    }
}