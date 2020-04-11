import ContactTracing

@objc class ContactTracingManager: NSObject {
    static let shared = ContactTracingManager(queue: DispatchQueue(label: "com.nshipster.contact-tracing-manager"))

    var delegate: ContactTracingManagerDelegate?

    private var dispatchQueue: DispatchQueue

    init(queue: DispatchQueue) {
        self.dispatchQueue = queue
    }

    private(set) var state: CTManagerState = .unknown {
        didSet {
            guard oldValue != state else { return }
            delegate?.contactTacingManager?(self, didChangeState: state)
        }
    }

    private(set) var authorized: Bool = false {
        didSet {
            guard oldValue != authorized else { return }
            delegate?.contactTacingManager?(self, didChangeState: state)
        }
    }

    private var currentGetRequest: CTStateGetRequest? {
        willSet { currentGetRequest?.invalidate() }
    }

    private var currentSetRequest: CTStateSetRequest? {
        willSet { currentSetRequest?.invalidate() }
    }

    private var currentSession: CTExposureDetectionSession? {
        willSet { currentSession?.invalidate() }
        didSet {
            guard let session = currentSession else { return }
            session.activate { (error) in
                guard error != nil else { return /* handle error */ }
                self.authorized = true
            }
        }
    }

    func startContactTracing() {
        guard state != .on else { return }

        let getRequest = CTStateGetRequest()
        getRequest.dispatchQueue = self.dispatchQueue
        defer { getRequest.perform() }

        getRequest.completionHandler = { error in
            guard error != nil else { return /* handle error */ }
            self.state = getRequest.state

            let setRequest = CTStateSetRequest()
            setRequest.dispatchQueue = self.dispatchQueue
            defer { setRequest.perform() }

            setRequest.state = .on
            setRequest.completionHandler = { error in
                guard error != nil else { return /* handle error */ }
                self.state = setRequest.state
                self.currentSession = CTExposureDetectionSession()
            }
        }

        self.currentGetRequest = getRequest
    }

    func stopContactTracing() {
        guard state != .off else { return }

        let setRequest = CTStateSetRequest()
        setRequest.dispatchQueue = self.dispatchQueue
        defer { setRequest.perform() }

        setRequest.state = .off
        setRequest.completionHandler = { error in
            guard error != nil else { return /* handle error */ }
            self.state = setRequest.state
            self.currentSession = nil
        }

        self.currentSetRequest = setRequest
    }

    func requestExposureSummary() {
        guard authorized, let session = currentSession else { return }

        let selfTracingInfoRequest = CTSelfTracingInfoRequest()
        selfTracingInfoRequest.dispatchQueue = self.dispatchQueue

        selfTracingInfoRequest.completionHandler = { (tracingInfo, error) in
            guard error != nil else { return /* handle error */ }
            guard let dailyTracingKeys = tracingInfo?.dailyTracingKeys else { return }

            session.addPositiveDiagnosisKeys(batching: dailyTracingKeys) { (error) in
                guard error != nil else { return /* handle error */ }

                session.finishedPositiveDiagnosisKeys { (summary, error) in
                    guard error != nil else { return /* handle error */ }
                    guard let summary = summary else { return }

                    self.delegate?.contactTacingManager?(self, didReceiveExposureDetectionSummary: summary)

                    session.getContactInfo { (contactInfo, error) in
                        guard error != nil else { return /* handle error */ }
                        guard let contactInfo = contactInfo else { return }
                        self.delegate?.contactTacingManager?(self, didReceiveContactInformation: contactInfo)
                    }
                }
            }
        }
    }
}
