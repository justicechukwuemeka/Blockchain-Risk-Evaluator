;; Blockchain Risk Evaluation Framework (BREF) Smart Contract
;;
;; A comprehensive decentralized risk assessment platform for blockchain accounts.
;; This framework enables authorized evaluators to assess risk across multiple dimensions,
;; automatically calculates weighted composite risk scores, and provides transparent
;; risk management capabilities for DeFi protocols and financial applications.
;;
;; Features:
;; - Multi-dimensional risk assessment (credit, liquidity, collateral, transaction history)
;; - Weighted scoring system with configurable importance factors
;; - Role-based access control for risk evaluators
;; - Automated composite score calculation
;; - Batch assessment capabilities
;; - Transparent audit trail with timestamps

;; ERROR DEFINITIONS

(define-constant ERR-UNAUTHORIZED-EVALUATOR-ACCESS (err u100))
(define-constant ERR-RISK-SCORE-OUT-OF-BOUNDS (err u101))
(define-constant ERR-ACCOUNT-ADDRESS-NOT-FOUND (err u102))
(define-constant ERR-INVALID-IMPORTANCE-WEIGHT (err u103))
(define-constant ERR-UNKNOWN-RISK-DIMENSION (err u104))
(define-constant ERR-INVALID-PRINCIPAL-ADDRESS (err u105))
(define-constant ERR-ADMIN-AUTHORIZATION-REQUIRED (err u106))

;; SYSTEM CONFIGURATION CONSTANTS

(define-constant MIN-RISK-SCORE u0)
(define-constant MAX-RISK-SCORE u100)
(define-constant DEFAULT-IMPORTANCE-WEIGHT u1)
(define-constant MAX-IMPORTANCE-WEIGHT u10)
(define-constant ZERO-ADDRESS 'SP000000000000000000002Q6VF78)

;; RISK DIMENSION IDENTIFIERS

(define-constant credit-risk-dimension u0)
(define-constant liquidity-risk-dimension u1)
(define-constant collateral-risk-dimension u2)
(define-constant transaction-history-dimension u3)
(define-constant max-risk-dimension-index u3)

;; DATA STORAGE DEFINITIONS

;; System administrator
(define-data-var system-administrator principal tx-sender)

;; Authorized risk evaluators registry
(define-map authorized-risk-evaluators principal bool)

;; Individual risk dimension scores per account
(define-map account-risk-dimension-scores 
  { 
    evaluated-account: principal, 
    risk-dimension: uint 
  } 
  { 
    assessed-score: uint, 
    evaluation-timestamp: uint,
    evaluator-address: principal
  })

;; Risk dimension importance weightings
(define-map risk-dimension-weights 
  { risk-dimension: uint } 
  { weight-factor: uint })

;; Comprehensive account risk profiles
(define-map comprehensive-account-profiles
  { evaluated-account: principal }
  { 
    overall-risk-score: uint, 
    last-evaluation-timestamp: uint,
    total-evaluations-count: uint
  })

;; AUTHORIZATION AND VALIDATION UTILITIES

;; Check if caller has administrator privileges
(define-private (verify-administrator-access)
  (if (is-eq tx-sender (var-get system-administrator))
    (ok true)
    ERR-ADMIN-AUTHORIZATION-REQUIRED))

;; Verify if principal is an authorized risk evaluator
(define-read-only (check-evaluator-authorization (evaluator-principal principal))
  (default-to false (map-get? authorized-risk-evaluators evaluator-principal)))

;; Validate risk dimension is within acceptable range
(define-private (validate-risk-dimension (dimension-id uint))
  (<= dimension-id max-risk-dimension-index))

;; Validate importance weight is within acceptable bounds
(define-private (validate-importance-weight (weight-value uint))
  (and (> weight-value u0) (<= weight-value MAX-IMPORTANCE-WEIGHT)))

;; Verify principal address is valid (not zero address)
(define-private (validate-principal-address (address-to-check principal))
  (not (is-eq address-to-check ZERO-ADDRESS)))

;; Validate risk score is within acceptable range
(define-private (validate-risk-score (score-value uint))
  (and (>= score-value MIN-RISK-SCORE) (<= score-value MAX-RISK-SCORE)))

;; DATA RETRIEVAL FUNCTIONS

;; Get risk score for specific account and dimension
(define-read-only (fetch-dimension-risk-score (account-address principal) (dimension-id uint))
  (match (map-get? account-risk-dimension-scores 
           { evaluated-account: account-address, risk-dimension: dimension-id })
    score-record score-record
    { assessed-score: u0, evaluation-timestamp: u0, evaluator-address: ZERO-ADDRESS }))

;; Get importance weight for risk dimension
(define-read-only (fetch-dimension-weight (dimension-id uint))
  (default-to { weight-factor: DEFAULT-IMPORTANCE-WEIGHT } 
    (map-get? risk-dimension-weights { risk-dimension: dimension-id })))

;; Get comprehensive account risk profile
(define-read-only (fetch-account-risk-profile (account-address principal))
  (match (map-get? comprehensive-account-profiles { evaluated-account: account-address })
    profile-record profile-record
    { overall-risk-score: u0, last-evaluation-timestamp: u0, total-evaluations-count: u0 }))

;; Get current system administrator
(define-read-only (get-system-administrator)
  (var-get system-administrator))

;; Check if account has been evaluated
(define-read-only (account-has-evaluations (account-address principal))
  (> (get total-evaluations-count (fetch-account-risk-profile account-address)) u0))

;; RISK CALCULATION ENGINE

;; Calculate weighted composite risk score for an account
(define-read-only (compute-composite-risk-score (account-address principal))
  (let
    (
      ;; Fetch individual dimension scores
      (credit-evaluation (get assessed-score 
        (fetch-dimension-risk-score account-address credit-risk-dimension)))
      (liquidity-evaluation (get assessed-score 
        (fetch-dimension-risk-score account-address liquidity-risk-dimension)))
      (collateral-evaluation (get assessed-score 
        (fetch-dimension-risk-score account-address collateral-risk-dimension)))
      (history-evaluation (get assessed-score 
        (fetch-dimension-risk-score account-address transaction-history-dimension)))
      
      ;; Fetch dimension weights
      (credit-weight (get weight-factor (fetch-dimension-weight credit-risk-dimension)))
      (liquidity-weight (get weight-factor (fetch-dimension-weight liquidity-risk-dimension)))
      (collateral-weight (get weight-factor (fetch-dimension-weight collateral-risk-dimension)))
      (history-weight (get weight-factor (fetch-dimension-weight transaction-history-dimension)))
      
      ;; Calculate totals
      (total-weight-sum (+ credit-weight liquidity-weight collateral-weight history-weight))
      (weighted-score-sum (+
        (* credit-evaluation credit-weight)
        (* liquidity-evaluation liquidity-weight)
        (* collateral-evaluation collateral-weight)
        (* history-evaluation history-weight)))
    )
    ;; Return weighted average or zero if no weights
    (if (> total-weight-sum u0)
      (/ weighted-score-sum total-weight-sum)
      u0)))

;; SYSTEM ADMINISTRATION FUNCTIONS

;; Initialize the risk evaluation framework with default settings
(define-public (initialize-risk-framework)
  (begin
    (try! (verify-administrator-access))
    ;; Set default importance weights for each risk dimension
    (map-set risk-dimension-weights 
      { risk-dimension: credit-risk-dimension } 
      { weight-factor: u3 })
    (map-set risk-dimension-weights 
      { risk-dimension: liquidity-risk-dimension } 
      { weight-factor: u2 })
    (map-set risk-dimension-weights 
      { risk-dimension: collateral-risk-dimension } 
      { weight-factor: u3 })
    (map-set risk-dimension-weights 
      { risk-dimension: transaction-history-dimension } 
      { weight-factor: u2 })
    (ok true)))

;; Configure importance weight for a risk dimension
(define-public (configure-dimension-weight (dimension-id uint) (new-weight uint))
  (begin
    (try! (verify-administrator-access))
    (asserts! (validate-risk-dimension dimension-id) ERR-UNKNOWN-RISK-DIMENSION)
    (asserts! (validate-importance-weight new-weight) ERR-INVALID-IMPORTANCE-WEIGHT)
    
    (map-set risk-dimension-weights 
      { risk-dimension: dimension-id } 
      { weight-factor: new-weight })
    (ok true)))

;; Authorize new risk evaluator
(define-public (authorize-risk-evaluator (evaluator-address principal))
  (begin
    (try! (verify-administrator-access))
    (asserts! (validate-principal-address evaluator-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (map-set authorized-risk-evaluators evaluator-address true)
    (ok true)))

;; Revoke risk evaluator authorization
(define-public (revoke-evaluator-authorization (evaluator-address principal))
  (begin
    (try! (verify-administrator-access))
    (asserts! (validate-principal-address evaluator-address) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (map-delete authorized-risk-evaluators evaluator-address)
    (ok true)))

;; Transfer system administration to new principal
(define-public (transfer-system-administration (new-administrator principal))
  (begin
    (try! (verify-administrator-access))
    (asserts! (validate-principal-address new-administrator) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (var-set system-administrator new-administrator)
    (ok true)))

;; RISK EVALUATION FUNCTIONS

;; Submit risk evaluation for specific account and dimension
(define-public (submit-risk-evaluation 
    (target-account principal) 
    (dimension-id uint) 
    (risk-score uint))
  (begin
    ;; Verify evaluator authorization
    (asserts! (check-evaluator-authorization tx-sender) ERR-UNAUTHORIZED-EVALUATOR-ACCESS)
    
    ;; Validate all inputs
    (asserts! (validate-principal-address target-account) ERR-INVALID-PRINCIPAL-ADDRESS)
    (asserts! (validate-risk-score risk-score) ERR-RISK-SCORE-OUT-OF-BOUNDS)
    (asserts! (validate-risk-dimension dimension-id) ERR-UNKNOWN-RISK-DIMENSION)
    
    ;; Store the risk evaluation
    (map-set account-risk-dimension-scores 
      { evaluated-account: target-account, risk-dimension: dimension-id } 
      { 
        assessed-score: risk-score, 
        evaluation-timestamp: block-height,
        evaluator-address: tx-sender
      })
    
    ;; Update comprehensive profile
    (let 
      (
        (current-profile (fetch-account-risk-profile target-account))
        (new-composite-score (compute-composite-risk-score target-account))
        (updated-evaluation-count (+ (get total-evaluations-count current-profile) u1))
      )
      (map-set comprehensive-account-profiles
        { evaluated-account: target-account }
        { 
          overall-risk-score: new-composite-score, 
          last-evaluation-timestamp: block-height,
          total-evaluations-count: updated-evaluation-count
        }))
    
    (ok true)))

;; Manually refresh composite risk score for an account
(define-public (refresh-composite-score (target-account principal))
  (begin
    (asserts! (validate-principal-address target-account) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    (let 
      (
        (current-profile (fetch-account-risk-profile target-account))
        (recalculated-score (compute-composite-risk-score target-account))
      )
      (map-set comprehensive-account-profiles
        { evaluated-account: target-account }
        { 
          overall-risk-score: recalculated-score, 
          last-evaluation-timestamp: block-height,
          total-evaluations-count: (get total-evaluations-count current-profile)
        })
      (ok recalculated-score))))

;; BATCH EVALUATION FUNCTIONS

;; Submit comprehensive risk evaluation across all dimensions
(define-public (submit-comprehensive-evaluation 
    (target-account principal)
    (credit-score uint)
    (liquidity-score uint)
    (collateral-score uint)
    (history-score uint))
  (begin
    ;; Verify evaluator authorization
    (asserts! (check-evaluator-authorization tx-sender) ERR-UNAUTHORIZED-EVALUATOR-ACCESS)
    
    ;; Validate account address
    (asserts! (validate-principal-address target-account) ERR-INVALID-PRINCIPAL-ADDRESS)
    
    ;; Validate each risk score individually to satisfy static analysis
    (asserts! (validate-risk-score credit-score) ERR-RISK-SCORE-OUT-OF-BOUNDS)
    (asserts! (validate-risk-score liquidity-score) ERR-RISK-SCORE-OUT-OF-BOUNDS)
    (asserts! (validate-risk-score collateral-score) ERR-RISK-SCORE-OUT-OF-BOUNDS)
    (asserts! (validate-risk-score history-score) ERR-RISK-SCORE-OUT-OF-BOUNDS)
    
    ;; Store all dimension evaluations
    (map-set account-risk-dimension-scores 
      { evaluated-account: target-account, risk-dimension: credit-risk-dimension } 
      { assessed-score: credit-score, evaluation-timestamp: block-height, evaluator-address: tx-sender })
    
    (map-set account-risk-dimension-scores 
      { evaluated-account: target-account, risk-dimension: liquidity-risk-dimension } 
      { assessed-score: liquidity-score, evaluation-timestamp: block-height, evaluator-address: tx-sender })
    
    (map-set account-risk-dimension-scores 
      { evaluated-account: target-account, risk-dimension: collateral-risk-dimension } 
      { assessed-score: collateral-score, evaluation-timestamp: block-height, evaluator-address: tx-sender })
    
    (map-set account-risk-dimension-scores 
      { evaluated-account: target-account, risk-dimension: transaction-history-dimension } 
      { assessed-score: history-score, evaluation-timestamp: block-height, evaluator-address: tx-sender })
    
    ;; Update comprehensive profile
    (let 
      (
        (current-profile (fetch-account-risk-profile target-account))
        (new-composite-score (compute-composite-risk-score target-account))
        (updated-evaluation-count (+ (get total-evaluations-count current-profile) u4))
      )
      (map-set comprehensive-account-profiles
        { evaluated-account: target-account }
        { 
          overall-risk-score: new-composite-score, 
          last-evaluation-timestamp: block-height,
          total-evaluations-count: updated-evaluation-count
        }))
    
    (ok true)))

;; CONTRACT INITIALIZATION

;; Initialize contract deployer as first authorized evaluator
(map-set authorized-risk-evaluators tx-sender true)