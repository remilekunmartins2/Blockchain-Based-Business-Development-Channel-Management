;; Channel Manager Verification Contract
;; Validates and manages business development channel managers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Manager verification status
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Data structures
(define-map channel-managers
  { manager: principal }
  {
    status: uint,
    verification-date: uint,
    performance-score: uint,
    territory: (string-ascii 50),
    specialization: (string-ascii 100)
  }
)

(define-map manager-permissions
  { manager: principal }
  {
    can-onboard: bool,
    can-monitor: bool,
    max-partners: uint
  }
)

(define-data-var total-managers uint u0)

;; Public functions
(define-public (register-manager (manager principal) (territory (string-ascii 50)) (specialization (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? channel-managers { manager: manager })) ERR_ALREADY_VERIFIED)

    (map-set channel-managers
      { manager: manager }
      {
        status: STATUS_PENDING,
        verification-date: stacks-block-height,
        performance-score: u0,
        territory: territory,
        specialization: specialization
      }
    )

    (var-set total-managers (+ (var-get total-managers) u1))
    (ok true)
  )
)

(define-public (verify-manager (manager principal))
  (let ((manager-data (unwrap! (map-get? channel-managers { manager: manager }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status manager-data) STATUS_PENDING) ERR_INVALID_STATUS)

    (map-set channel-managers
      { manager: manager }
      (merge manager-data {
        status: STATUS_VERIFIED,
        verification-date: stacks-block-height
      })
    )

    (map-set manager-permissions
      { manager: manager }
      {
        can-onboard: true,
        can-monitor: true,
        max-partners: u10
      }
    )

    (ok true)
  )
)

(define-public (update-performance-score (manager principal) (score uint))
  (let ((manager-data (unwrap! (map-get? channel-managers { manager: manager }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status manager-data) STATUS_VERIFIED) ERR_INVALID_STATUS)

    (map-set channel-managers
      { manager: manager }
      (merge manager-data { performance-score: score })
    )

    (ok true)
  )
)

(define-public (suspend-manager (manager principal))
  (let ((manager-data (unwrap! (map-get? channel-managers { manager: manager }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set channel-managers
      { manager: manager }
      (merge manager-data { status: STATUS_SUSPENDED })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-manager-info (manager principal))
  (map-get? channel-managers { manager: manager })
)

(define-read-only (get-manager-permissions (manager principal))
  (map-get? manager-permissions { manager: manager })
)

(define-read-only (is-verified-manager (manager principal))
  (match (map-get? channel-managers { manager: manager })
    manager-data (is-eq (get status manager-data) STATUS_VERIFIED)
    false
  )
)

(define-read-only (get-total-managers)
  (var-get total-managers)
)
