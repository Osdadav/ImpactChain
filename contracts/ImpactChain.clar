;; ImpactChain - Social impact contribution and reward tracking platform
(define-data-var impact-coordinator principal tx-sender)
(define-data-var total-impact-points uint u0)
(define-data-var impact-multiplier uint u80) ;; multiplier for impact rewards
(define-data-var last-impact-assessment uint u0)

(define-map contributor-impact principal uint)
(define-map impact-initiatives principal (string-utf8 64))
(define-map registered-initiatives (string-utf8 64) bool)

;; Error codes
(define-constant err-unauthorized-coordinator (err u9800))
(define-constant err-coordinator-already-assigned (err u9801))
(define-constant err-invalid-impact-points (err u9802))
(define-constant err-no-impact-rewards (err u9803))
(define-constant err-no-impact-contributions (err u9804))
(define-constant err-invalid-initiative (err u9805))
(define-constant err-initiative-not-registered (err u9806))

;; Verify impact coordinator authorization
(define-private (is-impact-coordinator (caller principal))
  (begin
    (asserts! (is-eq caller (var-get impact-coordinator)) err-unauthorized-coordinator)
    (ok true)))

;; Initialize impact tracking network
(define-public (establish-impact-network (coordinator principal))
  (begin
    (asserts! (is-none (map-get? contributor-impact coordinator)) err-coordinator-already-assigned)
    (var-set impact-coordinator coordinator)
    (ok "ImpactChain social impact network established")))

;; Register social impact initiative
(define-public (register-impact-initiative (initiative (string-utf8 64)))
  (begin
    (try! (is-impact-coordinator tx-sender))
    (asserts! (> (len initiative) u0) err-invalid-initiative)
    (map-set registered-initiatives initiative true)
    (ok "Impact initiative registered for tracking")))

;; Record impact contribution
(define-public (record-impact-contribution (impact-points uint) (initiative (string-utf8 64)))
  (begin
    (asserts! (> impact-points u0) err-invalid-impact-points)
    (asserts! (default-to false (map-get? registered-initiatives initiative)) err-initiative-not-registered)
    
    (let ((current-impact (default-to u0 (map-get? contributor-impact tx-sender))))
      (map-set contributor-impact tx-sender (+ current-impact impact-points))
      (map-set impact-initiatives tx-sender initiative)
      (var-set total-impact-points (+ (var-get total-impact-points) impact-points))
      (ok (+ current-impact impact-points)))))

;; Execute impact assessment round
(define-public (execute-impact-assessment)
  (begin
    (try! (is-impact-coordinator tx-sender))
    (let ((current-assessment (+ (var-get last-impact-assessment) u1))
          (total-points (var-get total-impact-points)))
      (asserts! (> total-points (var-get last-impact-assessment)) err-no-impact-rewards)
      
      (let ((impact-reward-pool (* (var-get impact-multiplier) total-points)))
        (var-set last-impact-assessment current-assessment)
        (ok impact-reward-pool)))))

;; Claim impact contribution rewards
(define-public (claim-impact-rewards)
  (begin
    (let ((impact-contribution (default-to u0 (map-get? contributor-impact tx-sender))))
      (asserts! (> impact-contribution u0) err-no-impact-contributions)
      
      (let ((total-points (var-get total-impact-points))
            (base-impact-rewards (* (var-get impact-multiplier) impact-contribution))
            (contribution-ratio (/ (* impact-contribution u100000) total-points)))
        
        (let ((final-impact-rewards (/ (* contribution-ratio base-impact-rewards) u100000)))
          (map-delete contributor-impact tx-sender)
          (map-delete impact-initiatives tx-sender)
          (var-set total-impact-points (- (var-get total-impact-points) impact-contribution))
          (ok (+ impact-contribution final-impact-rewards)))))))

;; Read-only functions
(define-read-only (get-contributor-impact (contributor principal))
  (default-to u0 (map-get? contributor-impact contributor)))

(define-read-only (get-impact-initiative (contributor principal))
  (map-get? impact-initiatives contributor))

(define-read-only (get-total-impact-points)
  (var-get total-impact-points))

(define-read-only (is-initiative-registered (initiative (string-utf8 64)))
  (default-to false (map-get? registered-initiatives initiative)))