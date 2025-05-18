;; PropertyRegistry - A digital real estate and property ownership system
;; This contract allows registrars to create digital property records that can be transferred and verified

(define-non-fungible-token property-deed uint)

;; Data storage
(define-map property-details uint {address: (string-ascii 64), description: (string-ascii 256), image-uri: (string-utf8 256)})
(define-map property-attributes uint (list 20 {feature: (string-ascii 32), value: (string-ascii 64)}))
(define-map registrar-registry principal {name: (string-ascii 64), active: bool})
(define-map jurisdiction-property-validation {jurisdiction-id: principal, property-id: uint} {validated: bool, assessment-value: uint})
(define-map property-ownership uint principal)

;; Error codes
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_REGISTRAR_NOT_REGISTERED (err u101))
(define-constant ERR_PROPERTY_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_REGISTERED (err u103))
(define-constant ERR_INVALID_PARAMS (err u104))
(define-constant ERR_NOT_OWNER (err u105))
(define-constant ERR_INVALID_PRINCIPAL (err u106))
(define-constant ERR_EMPTY_STRING (err u107))
(define-constant ERR_INVALID_VALUE (err u108))

;; Constants
(define-constant ZERO_ADDRESS 'SP000000000000000000002Q6VF78)
(define-constant MAX_ASSESSMENT_VALUE u1000000000)

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Admin functions
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    ;; Validate new owner is not zero address
    (asserts! (not (is-eq new-owner ZERO_ADDRESS)) ERR_INVALID_PRINCIPAL)
    (ok (var-set contract-owner new-owner))))

;; Registrar registration
(define-public (register-registrar (registrar-name (string-ascii 64)))
  (begin
    ;; Validate registrar name is not empty
    (asserts! (> (len registrar-name) u0) ERR_EMPTY_STRING)
    (let ((registrar-exists (default-to {name: "", active: false} (map-get? registrar-registry tx-sender))))
      (asserts! (not (get active registrar-exists)) ERR_ALREADY_REGISTERED)
      (ok (map-set registrar-registry tx-sender {name: registrar-name, active: true})))))

(define-public (deactivate-registrar)
  (let ((registrar-exists (default-to {name: "", active: false} (map-get? registrar-registry tx-sender))))
    (asserts! (get active registrar-exists) ERR_REGISTRAR_NOT_REGISTERED)
    (ok (map-set registrar-registry tx-sender 
      {name: (get name registrar-exists), active: false}))))

;; NFT functions
(define-public (register-property 
    (owner principal) 
    (property-id uint) 
    (address (string-ascii 64)) 
    (description (string-ascii 256)) 
    (image-uri (string-utf8 256)))
  (begin
    (asserts! (or (is-eq tx-sender (var-get contract-owner)) 
                 (is-some (map-get? registrar-registry tx-sender))) ERR_NOT_AUTHORIZED)
    (asserts! (is-none (nft-get-owner? property-deed property-id)) ERR_ALREADY_REGISTERED)
    
    ;; Validate owner is not zero address
    (asserts! (not (is-eq owner ZERO_ADDRESS)) ERR_INVALID_PRINCIPAL)
    ;; Validate strings are not empty
    (asserts! (> (len address) u0) ERR_EMPTY_STRING)
    (asserts! (> (len description) u0) ERR_EMPTY_STRING)
    (asserts! (> (len image-uri) u0) ERR_EMPTY_STRING)
    
    (try! (nft-mint? property-deed property-id owner))
    (map-set property-details property-id {address: address, description: description, image-uri: image-uri})
    (map-set property-ownership property-id owner)
    (ok property-id)))

(define-public (transfer-property (property-id uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? property-deed property-id) ERR_PROPERTY_NOT_FOUND)) ERR_NOT_OWNER)
    ;; Validate recipient is not zero address
    (asserts! (not (is-eq recipient ZERO_ADDRESS)) ERR_INVALID_PRINCIPAL)
    (try! (nft-transfer? property-deed property-id tx-sender recipient))
    (map-set property-ownership property-id recipient)
    (ok true)))

;; Jurisdiction validation functions
(define-public (set-property-validation (property-id uint) (assessment-value uint) (validated bool))
  (begin
    (asserts! (is-some (map-get? registrar-registry tx-sender)) ERR_REGISTRAR_NOT_REGISTERED)
    (asserts! (is-some (nft-get-owner? property-deed property-id)) ERR_PROPERTY_NOT_FOUND)
    ;; Validate assessment value is within acceptable range
    (asserts! (<= assessment-value MAX_ASSESSMENT_VALUE) ERR_INVALID_VALUE)
    (ok (map-set jurisdiction-property-validation {jurisdiction-id: tx-sender, property-id: property-id} 
                {validated: validated, assessment-value: assessment-value}))))

;; Helper function to validate attributes
(define-private (validate-attribute (attr {feature: (string-ascii 32), value: (string-ascii 64)}))
  (and (> (len (get feature attr)) u0) (> (len (get value attr)) u0)))

(define-private (validate-attributes (attrs (list 20 {feature: (string-ascii 32), value: (string-ascii 64)})))
  (let ((attrs-len (len attrs)))
    (and 
      (> attrs-len u0)
      (is-eq attrs-len (len (filter validate-attribute attrs))))))

;; Property attribute functions
(define-public (set-property-attributes (property-id uint) (attributes (list 20 {feature: (string-ascii 32), value: (string-ascii 64)})))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (asserts! (is-some (nft-get-owner? property-deed property-id)) ERR_PROPERTY_NOT_FOUND)
    ;; Validate attributes
    (asserts! (validate-attributes attributes) ERR_INVALID_VALUE)
    (ok (map-set property-attributes property-id attributes))))

;; Read-only functions
(define-read-only (get-property-details (property-id uint))
  (map-get? property-details property-id))

(define-read-only (get-property-attributes (property-id uint))
  (map-get? property-attributes property-id))

(define-read-only (get-property-validation (jurisdiction-id principal) (property-id uint))
  (map-get? jurisdiction-property-validation {jurisdiction-id: jurisdiction-id, property-id: property-id}))

(define-read-only (get-registrar-info (registrar-id principal))
  (map-get? registrar-registry registrar-id))

(define-read-only (get-property-owner (property-id uint))
  (nft-get-owner? property-deed property-id))

(define-read-only (is-registrar-active (registrar-id principal))
  (match (map-get? registrar-registry registrar-id)
    registrar-data (get active registrar-data)
    false))