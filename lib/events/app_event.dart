/// Sealed hierarchy of domain events that can trigger notifications.
///
/// Screens and services dispatch an [AppEvent] instead of calling
/// [NotificationService] directly.  All notification logic lives in
/// [NotificationEngine], which is the single consumer of these events.
sealed class AppEvent {
  const AppEvent();
}

// ─── Blood-request lifecycle ──────────────────────────────────────────────────

/// Fired when a recipient submits a new blood request (online or synced from
/// the offline queue).  The engine notifies all hospital admins of [hospitalId].
class BloodRequestCreatedEvent extends AppEvent {
  final String hospitalId;
  final String hospitalName;
  final String patientName;
  final String bloodGroup;
  final String requestId;

  const BloodRequestCreatedEvent({
    required this.hospitalId,
    required this.hospitalName,
    required this.patientName,
    required this.bloodGroup,
    required this.requestId,
  });
}

/// Fired when a hospital admin verifies a blood request (QR scan **or** manual
/// override).  The engine sends a direct notification to the requester and
/// broadcasts an emergency alert to all compatible donors in [city].
class BloodRequestVerifiedEvent extends AppEvent {
  final String requestId;
  final String? requesterId;
  final String city;
  final String bloodGroup;

  const BloodRequestVerifiedEvent({
    required this.requestId,
    required this.requesterId,
    required this.city,
    required this.bloodGroup,
  });
}

/// Fired when a donation is registered by a hospital admin (QR scan **or**
/// manual override).  The engine thanks the donor and informs the requester.
class DonationRegisteredEvent extends AppEvent {
  final String donorId;
  final String requestId;
  final String? requesterId;

  const DonationRegisteredEvent({
    required this.donorId,
    required this.requestId,
    this.requesterId,
  });
}

/// Fired when a recipient manually marks their own request as fulfilled.
/// The engine notifies the matched donor via [sendRequestClosedNotification].
class BloodRequestClosedEvent extends AppEvent {
  final String requestId;

  const BloodRequestClosedEvent({required this.requestId});
}

// ─── Donor lifecycle ──────────────────────────────────────────────────────────

/// Fired when a hospital admin scans a donor's QR and confirms their blood
/// group.  The engine sends a verification confirmation to the donor.
class BloodGroupVerifiedEvent extends AppEvent {
  final String donorId;
  final String bloodGroup;

  const BloodGroupVerifiedEvent({
    required this.donorId,
    required this.bloodGroup,
  });
}

// ─── SuperAdmin broadcast ─────────────────────────────────────────────────────

/// Fired when the SuperAdmin sends a broadcast notification.
/// [city] and [bloodGroup] may be empty strings to indicate "all".
class AdminBroadcastEvent extends AppEvent {
  final String city;
  final String bloodGroup;
  final String broadcastId;

  const AdminBroadcastEvent({
    required this.city,
    required this.bloodGroup,
    required this.broadcastId,
  });
}
