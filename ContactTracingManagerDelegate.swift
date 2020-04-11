import ContactTracing

@objc protocol ContactTracingManagerDelegate: class {
    @objc optional func contactTacingManager(_ manager: ContactTracingManager,
                                             didChangeState state: CTManagerState)
    @objc optional func contactTacingManager(_ manager: ContactTracingManager,
                                             didChangeAuthorization authorized: Bool)
    @objc optional func contactTacingManager(_ manager: ContactTracingManager,
                                             didFailWithError error: Error)
    @objc optional func contactTacingManager(_ manager: ContactTracingManager,
                                             didReceiveExposureDetectionSummary summary: CTExposureDetectionSummary)
    @objc optional func contactTacingManager(_ manager: ContactTracingManager,
                                             didReceiveContactInformation contactInfo: [CTContactInfo])
}