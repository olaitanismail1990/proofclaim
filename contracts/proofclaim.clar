;; ------------------------------------------------------
;; Contract: proof-of-task-plus
;; Purpose: Enhanced bounty contract for submitting and approving task proofs
;; Author: [Your Name]
;; License: MIT
;; ------------------------------------------------------

;; === Constants ===
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_CLAIMED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_INVALID_APPROVAL (err u104))
(define-constant ERR_EXPIRED (err u105))
(define-constant ERR_ALREADY_EXISTS (err u106))

;; === Storage ===
(define-data-var next-bounty-id uint u0)
(define-data-var contract-admin principal tx-sender)

(define-map bounties
  uint
  (tuple
    (creator principal)
    (reward uint)
    (description (buff 100))
    (claimed bool)
    (claimer (optional principal))
    (proof (optional (buff 100)))
    (deadline (optional uint)) ;; block height
    (active bool)
  )
)

;; === Post a new bounty ===
(define-public (post-bounty (description (buff 100)) (reward uint) (deadline (optional uint)))
  (let ((bounty-id (var-get next-bounty-id)))
    (begin
      (map-set bounties bounty-id {
        creator: tx-sender,
        reward: reward,
        description: description,
        claimed: false,
        claimer: none,
        proof: none,
        deadline: deadline,
        active: true
      })
      (var-set next-bounty-id (+ bounty-id u1))
      (ok bounty-id)
    )
  )
)

;; === Fund bounty ===
(define-public (fund-bounty (bounty-id uint))
  (match (map-get? bounties bounty-id)
    bounty
    (if (is-eq tx-sender (get creator bounty))
        (stx-transfer? (get reward bounty) tx-sender (as-contract tx-sender))
        ERR_UNAUTHORIZED
    )
    ERR_NOT_FOUND
  )
)

;; === Submit proof ===
(define-public (submit-proof (bounty-id uint) (proof (buff 100)))
  (match (map-get? bounties bounty-id)
    bounty
    (begin
      (asserts! (not (get claimed bounty)) ERR_ALREADY_CLAIMED)
      (asserts! (get active bounty) ERR_EXPIRED)
      (let ((deadline-check
              (match (get deadline bounty)
                deadline-val (if (<= stacks-block-height deadline-val)
                            (ok true)
                            ERR_EXPIRED)
                (ok true))))
        (try! deadline-check)
        (map-set bounties bounty-id (merge bounty {
          claimer: (some tx-sender),
          proof: (some proof)
        }))
        (ok true))
    )
    ERR_NOT_FOUND
  )
)

;; === Update proof (before approval) ===
(define-public (update-proof (bounty-id uint) (new-proof (buff 100)))
  (match (map-get? bounties bounty-id)
    bounty
    (begin
      (asserts! (is-eq (some tx-sender) (get claimer bounty)) ERR_UNAUTHORIZED)
      (asserts! (not (get claimed bounty)) ERR_ALREADY_CLAIMED)
      (map-set bounties bounty-id (merge bounty { proof: (some new-proof) }))
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; === Approve submission ===
(define-public (approve-submission (bounty-id uint))
  (match (map-get? bounties bounty-id)
    bounty
    (begin
      (asserts! (is-eq tx-sender (get creator bounty)) ERR_UNAUTHORIZED)
      (match (get claimer bounty)
        claimer
        (begin
          (try! (stx-transfer? (get reward bounty) (as-contract tx-sender) claimer))
          (map-set bounties bounty-id (merge bounty {
            claimed: true
          }))
          (ok true)
        )
        ERR_INVALID_APPROVAL
      )
    )
    ERR_NOT_FOUND
  )
)

;; === Cancel bounty (before proof submitted) ===
(define-public (cancel-bounty (bounty-id uint))
  (match (map-get? bounties bounty-id)
    bounty
    (begin
      (asserts! (is-eq tx-sender (get creator bounty)) ERR_UNAUTHORIZED)
      (asserts! (not (get claimed bounty)) ERR_ALREADY_CLAIMED)
      (asserts! (is-none (get claimer bounty)) ERR_INVALID_APPROVAL)
      (map-set bounties bounty-id (merge bounty { active: false }))
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; === Admin or creator withdraw unclaimed expired bounty ===
(define-public (withdraw-unclaimed (bounty-id uint) (to principal))
  (match (map-get? bounties bounty-id)
    bounty
    (begin
      (asserts! (or (is-eq tx-sender (get creator bounty))
                    (is-eq tx-sender (var-get contract-admin)))
                ERR_UNAUTHORIZED)
      (asserts! (not (get claimed bounty)) ERR_ALREADY_CLAIMED)
      (asserts! (not (get active bounty)) ERR_INVALID_APPROVAL)
      (try! (stx-transfer? (get reward bounty) (as-contract tx-sender) to))
      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; === Admin: Transfer ownership ===
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-admin)) ERR_UNAUTHORIZED)
    (var-set contract-admin new-admin)
    (ok true)
  )
)

;; === Read: Get bounty ===
(define-read-only (get-bounty (bounty-id uint))
  (match (map-get? bounties bounty-id)
    bounty (ok bounty)
    ERR_NOT_FOUND
  )
)

;; === Read: Get contract admin ===
(define-read-only (get-admin)
  (ok (var-get contract-admin))
)
