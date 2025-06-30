;; Incentive Management Contract
;; Manages channel partner incentives and rewards

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_NOT_FOUND (err u401))
(define-constant ERR_INSUFFICIENT_FUNDS (err u402))
(define-constant ERR_ALREADY_CLAIMED (err u403))

;; Incentive types
(define-constant INCENTIVE_PERFORMANCE u1)
(define-constant INCENTIVE_MILESTONE u2)
(define-constant INCENTIVE_BONUS u3)
(define-constant INCENTIVE_REFERRAL u4)

;; Data structures
(define-map incentive-pools
  { pool-id: uint }
  {
    total-amount: uint,
    available-amount: uint,
    incentive-type: uint,
    period: uint,
    created-at: uint
  }
)

(define-map partner-incentives
  { partner: principal, incentive-id: uint }
  {
    amount: uint,
    incentive-type: uint,
    earned-at: uint,
    claimed: bool,
    performance-period: uint,
    criteria-met: bool
  }
)

(define-map incentive-criteria
  { incentive-type: uint }
  {
    min-performance-score: uint,
    min-revenue: uint,
    min-deals: uint,
    multiplier: uint
  }
)

(define-data-var next-pool-id uint u1)
(define-data-var next-incentive-id uint u1)
(define-data-var total-distributed uint u0)

;; Public functions
(define-public (create-incentive-pool (amount uint) (incentive-type uint) (period uint))
  (let ((pool-id (var-get next-pool-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set incentive-pools
      { pool-id: pool-id }
      {
        total-amount: amount,
        available-amount: amount,
        incentive-type: incentive-type,
        period: period,
        created-at: block-height
      }
    )

    (var-set next-pool-id (+ pool-id u1))
    (ok pool-id)
  )
)

(define-public (set-incentive-criteria
  (incentive-type uint)
  (min-score uint)
  (min-revenue uint)
  (min-deals uint)
  (multiplier uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set incentive-criteria
      { incentive-type: incentive-type }
      {
        min-performance-score: min-score,
        min-revenue: min-revenue,
        min-deals: min-deals,
        multiplier: multiplier
      }
    )

    (ok true)
  )
)

(define-public (calculate-and-award-incentive
  (partner principal)
  (incentive-type uint)
  (performance-score uint)
  (revenue uint)
  (deals uint)
  (period uint)
)
  (let (
    (incentive-id (var-get next-incentive-id))
    (criteria (unwrap! (map-get? incentive-criteria { incentive-type: incentive-type }) ERR_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (let (
      (criteria-met (and
        (>= performance-score (get min-performance-score criteria))
        (and
          (>= revenue (get min-revenue criteria))
          (>= deals (get min-deals criteria))
        )
      ))
      (base-amount u1000)
      (calculated-amount (* base-amount (get multiplier criteria)))
    )
      (map-set partner-incentives
        { partner: partner, incentive-id: incentive-id }
        {
          amount: calculated-amount,
          incentive-type: incentive-type,
          earned-at: block-height,
          claimed: false,
          performance-period: period,
          criteria-met: criteria-met
        }
      )

      (var-set next-incentive-id (+ incentive-id u1))
      (ok incentive-id)
    )
  )
)

(define-public (claim-incentive (partner principal) (incentive-id uint))
  (let ((incentive-data (unwrap! (map-get? partner-incentives { partner: partner, incentive-id: incentive-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender partner) ERR_UNAUTHORIZED)
    (asserts! (not (get claimed incentive-data)) ERR_ALREADY_CLAIMED)
    (asserts! (get criteria-met incentive-data) ERR_UNAUTHORIZED)

    (map-set partner-incentives
      { partner: partner, incentive-id: incentive-id }
      (merge incentive-data { claimed: true })
    )

    (var-set total-distributed (+ (var-get total-distributed) (get amount incentive-data)))
    (ok (get amount incentive-data))
  )
)

(define-public (approve-incentive (partner principal) (incentive-id uint))
  (let ((incentive-data (unwrap! (map-get? partner-incentives { partner: partner, incentive-id: incentive-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set partner-incentives
      { partner: partner, incentive-id: incentive-id }
      (merge incentive-data { criteria-met: true })
    )

    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-incentive-pool (pool-id uint))
  (map-get? incentive-pools { pool-id: pool-id })
)

(define-read-only (get-partner-incentive (partner principal) (incentive-id uint))
  (map-get? partner-incentives { partner: partner, incentive-id: incentive-id })
)

(define-read-only (get-incentive-criteria (incentive-type uint))
  (map-get? incentive-criteria { incentive-type: incentive-type })
)

(define-read-only (get-total-distributed)
  (var-get total-distributed)
)

(define-read-only (calculate-potential-incentive (performance-score uint) (revenue uint) (deals uint) (incentive-type uint))
  (match (map-get? incentive-criteria { incentive-type: incentive-type })
    criteria
      (if (and
        (>= performance-score (get min-performance-score criteria))
        (and
          (>= revenue (get min-revenue criteria))
          (>= deals (get min-deals criteria))
        )
      )
        (some (* u1000 (get multiplier criteria)))
        (some u0)
      )
    none
  )
)
