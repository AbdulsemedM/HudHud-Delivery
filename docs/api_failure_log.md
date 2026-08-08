# API Failure Log — Manual Testing

Recorded from Flutter debug terminal during manual QA.
Only **failing** requests (non-2xx / Dio errors) are listed.

---

## Failure — 2026-08-06 10:59:34 UTC

**ERROR[422] => PATH: https://api.hudhuddelivery.com/api/payments/initiate**

### Request
```
POST https://api.hudhuddelivery.com/api/payments/initiate
Headers: {Content-Type: application/json, Accept: application/json}
Body: {
  payment_method_code: ebirr,
  type: order,
  amount: 3352.29,
  payment_details: {phone: 251946514836, provider: coop},
  currency: ETB,
  order_id: 29
}
Connect Timeout: 30s
Receive Timeout: 3m
Send Timeout: 3m
```

### Error response
```
Status Code: 422 Unprocessable Entity
Error Type: DioExceptionType.badResponse

Response Data: {
  message: eBirr service unavailable: cURL error 28: Connection timeout after 10001 ms
    for https://payments.ebirr.com/asm,
  errors: {
    payment: [
      eBirr service unavailable: cURL error 28: Connection timeout after 10001 ms
        for https://payments.ebirr.com/asm
    ]
  }
}
```

### Notes
- App → HudHud API succeeded enough to return 422; **backend → eBirr** timed out (~10s).
- Same class of failure as earlier eBirr initiates (orders 22/24).
- Call site: `PaymentDataProvider.initiatePayment` → `PaymentBloc._onProcessPayment`.

---

## Failure â€” 2026-08-06 14:00:39

**ERROR[405] => PATH: https://api.hudhuddelivery.com/api/services/ride/10/cancel**

```
REQUEST[POST] => PATH: https://api.hudhuddelivery.com/api/services/ride/10/cancel
Headers: {Content-Type: application/json, Accept: application/json} 
Query Parameters: {}
Body: {cancellation_reason: Changed my mind, cancelled_by: user}    
Base URL: https://api.hudhuddelivery.com/api/
Full URL: https://api.hudhuddelivery.com/api/services/ride/10/cancel
Connect Timeout: 0:00:30.000000
Receive Timeout: 0:00:30.000000
Send Timeout: 0:00:30.000000
═══════════════════════════════════════════════════════════════     
updateAcquireFence: Did not find frame.
updateAcquireFence: Did not find frame.
updateAcquireFence: Did not find frame.
updateAcquireFence: Did not find frame.
❌ ERROR[405] => PATH: https://api.hudhuddelivery.com/api/services/ride/10/cancel
Error Type: DioExceptionType.badResponse
Error Message: This exception was thrown because the response has astatus code of 405 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 405 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.
Response Headers: connection: keep-alive
cache-control: no-cache, private
access-control-allow-origin: *
transfer-encoding: chunked
date: Thu, 06 Aug 2026 11:00:38 GMT
report-to: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=L%2BKwWMsFh3Cfj6PF7gXvvC6V1R4hDdV%2B8KYPNvTyQAdB3XNtW%2BjfHnt5m6TZtFXatGgQd5gtJUO1nSVvcjVP%2BZrqMHohE7rlM739HCibBGvsq%2BG1KvVrs%2BmY0IKOnEx%2FaJwr0%2Bcy6u%2BY"}]}
cf-cache-status: DYNAMIC
content-type: application/json
x-xss-protection: 1; mode=block
server: cloudflare
alt-svc: h3=":443"; ma=86400
nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800} 
cf-ray: a26d89f9ce7c545c-JIB
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
allow: GET, HEAD
Response Data: {message: The POST method is not supported for routeapi/services/ride/10/cancel. Supported methods: GET, HEAD.}
Status Code: 405
Status Message: Method Not Allowed
Request Data: {cancellation_reason: Changed my mind, cancelled_by: user}
```

---

## Failure â€” 2026-08-06 14:03:04

> **Client note:** pickup/dropoff coords were nearly identical (`estimated_distance: 0.0`) while labels differed (XQRJ+MH vs Urael). Root cause: `LocationSearchScreen` confirmed `_currentPosition` but did not update it when the map pin moved — only the reverse-geocoded address changed. Fixed so pin pan/search keeps coords in sync with the label.

**ERROR[500] => PATH: https://api.hudhuddelivery.com/api/services/delivery/request**

```
REQUEST[POST] => PATH: https://api.hudhuddelivery.com/api/services/delivery/request
Headers: {Content-Type: application/json, Accept: application/json} 
Query Parameters: {}
Body: {package_type: document, package_description: Documents, package_weight: 1.0, pickup_location: XQRJ+MH, Addis Ababa, Addis Ababa, pickup_latitude: 8.99152469, pickup_longitude: 38.78122025, dropoff_location: Urael, Addis Ababa, dropoff_latitude: 8.99152939, dropoff_longitude: 38.78121918, vehicle_type: motorbike, service_type: same_day, scheduled_pickup: null, scheduled_delivery: null, estimated_distance: 0.0, estimated_duration: 0, estimated_cost: 9.61, payment_method: ebirr, requires_signature: false, insurance_required: false, special_instructions: , sender_name: AbdulsemedMussema, sender_phone: , receiver_name: abdusemed , receiver_phone: 251946514836, package_details: {name: Documents, weight: 1.0, description: Documents}, pickup_address: {latitude: 8.99152469, longitude: 38.78122025, address: XQRJ+MH, Addis Ababa, Addis Ababa}, delivery_address: {latitude: 8.99152939, longitude: 38.78121918, address: Urael, Addis Ababa}}
Base URL: https://api.hudhuddelivery.com/api/
Full URL: https://api.hudhuddelivery.com/api/services/delivery/request
Connect Timeout: 0:00:30.000000
Receive Timeout: 0:00:30.000000
Send Timeout: 0:00:30.000000
═══════════════════════════════════════════════════════════════     
updateAcquireFence: Did not find frame.
updateAcquireFence: Did not find frame.
❌ ERROR[500] => PATH: https://api.hudhuddelivery.com/api/services/delivery/request
Error Type: DioExceptionType.badResponse
Error Message: This exception was thrown because the response has astatus code of 500 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 500 has the following meaning: "Server error - the server failed to fulfil an apparently valid request"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.
Response Headers: connection: keep-alive
cache-control: no-cache, private
access-control-allow-origin: *
transfer-encoding: chunked
date: Thu, 06 Aug 2026 11:03:03 GMT
cf-cache-status: DYNAMIC
report-to: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=EmnYOQTO5NzwI1wEEe6IFb1cEepBn8r4SBr%2Bkk21javykR1xI7lT81DDIO4h0bJa1jncwbRGjA8KjfgNp50IY%2FeBbdULH%2FismoHOasMrT1f0RqPlMKIq9JUVzc2xoziOD0vFI3AuIbWl"}]}
content-type: application/json
x-xss-protection: 1; mode=block
server: cloudflare
alt-svc: h3=":443"; ma=86400
nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800} 
cf-ray: a26d8d8489245459-JIB
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
Response Data: {message: Failed to request delivery service.}       
Status Code: 500
Status Message: Internal Server Error
Request Data: {package_type: document, package_description: Documents, package_weight: 1.0, pickup_location: XQRJ+MH, Addis Ababa, Addis Ababa, pickup_latitude: 8.99152469, pickup_longitude: 38.78122025, dropoff_location: Urael, Addis Ababa,dropoff_latitude: 8.99152939, dropoff_longitude: 38.78121918, vehicle_type: motorbike,service_type: same_day, scheduled_pickup: null, scheduled_delivery: null, estimated_distance: 0.0, estimated_duration: 0, estimated_cost: 9.61, payment_method: ebirr, requires_signature: false, insurance_required: false, special_instructions: , sender_name: Abdulsemed Mussema, sender_phone: , receiver_name: abdusemed , receiver_phone: 251946514836, package_details: {name: Documents, weight: 1.0, description: Documents}, pickup_address: {latitude: 8.99152469, longitude: 38.78122025, address: XQRJ+MH, Addis Ababa, Addis Ababa}, delivery_address: {latitude: 8.99152939, longitude: 38.78121918, address: Urael, Addis Ababa}}
```

---

## Failure â€” 2026-08-06 14:06:20

**ERROR[404] => PATH: https://api.hudhuddelivery.com/api/addresses-default**

```
ERROR[404] => PATH: https://api.hudhuddelivery.com/api/addresses-default
Error Type: DioExceptionType.badResponse
Error Message: This exception was thrown because the response has astatus code of 404 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 404 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.
Response Headers: connection: keep-alive
cache-control: no-cache, private
access-control-allow-origin: *
transfer-encoding: chunked
date: Thu, 06 Aug 2026 11:06:12 GMT
content-encoding: gzip
cf-cache-status: DYNAMIC
report-to: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=QG1SUHzvu%2F7dktTFgbxLDkRgILsHJppBSBz6s3DWpKCgvtTiEra0VuaxavAIgaHVhjuh%2FusJ3V0nnEpzHh32ChMEfHbhaKK9ERaViQd%2BXvaURPFzsvtLwN8iXqn6StX6RpKEeAJePHSw"}]}
content-type: application/json
x-xss-protection: 1; mode=block
server: cloudflare
alt-svc: h3=":443"; ma=86400
nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800} 
cf-ray: a26d92213b915456-JIB
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
Response Data: {success: false, message: No default address found}  
Status Code: 404
Status Message: Not Found
Stack Trace: #0      DioMixin.request (package:dio/src/dio_mixin.dart:364:36)
#1      DioMixin.get (package:dio/src/dio_mixin.dart:71:12)
#2      ApiService.get (package:hudhud_delivery/core/api/api_service.dart:31:35)
#3      AddressesDataProvider.getDefaultAddress.<anonymous closure>(package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart:81:35)   
#4      AddressesDataProvider._wrap (package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart:13:34)
#5      AddressesDataProvider.getDefaultAddress (package:hudhud_delivery/features/addresses/data/addresses_data_provider.dart:81:12)
#6      AddressesRepository.getDefaultAddress (package:hudhud_delivery/features/addresses/data/addresses_repository.dart:58:50)
#7      syncDefaultAddressFromApi (package:hudhud_delivery/features/addresses/presentation/screens/addresses_list_screen.dart:501:16)
<asynchronous suspension>
═══════════════════════════════════════════════════════════════     
✅ RESPONSE[201] => PATH: fcm/token
Headers: connection: keep-alive
cache-control: no-cache, private
access-control-allow-origin: *
transfer-encoding: chunked
date: Thu, 06 Aug 2026 11:06:12 GMT
cf-cache-status: DYNAMIC
report-to: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=9f37fYk01YwYpAyPKS0E3tB03dv7NRCG2mR1nerHh3JmfAygsR4HNtrE5SF0cgJ%2FxkmfXbRBrpPiu%2BNrM0GC5Z7yetrukWi%2BH%2BRLLpQpzau6EY%2B%2BweeXCBKNeDoFT4GfRYMOWFhoYn%2F%2F"}]}
content-type: application/json
x-xss-protection: 1; mode=block
server: cloudflare
alt-svc: h3=":443"; ma=86400
nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800} 
cf-ray: a26d922168055452-JIB
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
Response Data: {message: Token stored successfully, token: {token: fE1fYtFTSNCMkagYLJpmsS:APA91bHA6JjRo4zxAS78_RUgGCYHY3UvNs7MEfoausU4SbzGi8_eWWlf70bqaVolmcd1kxZxVv7kpAk-mZ3aF2wVEP31r9_lieyH0TzBGDVcSqPE0fBM4sU, device_type: android, device_id: UP1A.231005.007, is_active: true, user_id: 39, token_hash: b8c54bfc60080ffe61152aefce47e920784e7a91bf8dbd309efefac29d1eea72, updated_at: 2026-08-06T11:06:12.000000Z, created_at: 2026-08-06T11:06:12.000000Z, id: 252}}
```

---

## Failure â€” 2026-08-06 14:13:33

> **Client note:** Coords look correct now (distinct pickup/dropoff, `estimated_distance: 1.31`). Remaining 500 is likely backend. `sender_phone` is still empty in the body.

**ERROR[500] => PATH: https://api.hudhuddelivery.com/api/services/delivery/request**

```
REQUEST[POST] => PATH: https://api.hudhuddelivery.com/api/services/delivery/request
Headers: {Content-Type: application/json, Accept: application/json} 
Query Parameters: {}
Body: {package_type: document, package_description: Documents, package_weight: 1.0, pickup_location: XQRJ+MH, Addis Ababa, Addis Ababa, pickup_latitude: 8.99153258, pickup_longitude: 38.78125755, dropoff_location: Urael, Addis Ababa, dropoff_latitude: 9.003318053143381, dropoff_longitude: 38.7803740426898, vehicle_type: motorbike, service_type: same_day, scheduled_pickup: null, scheduled_delivery: null, estimated_distance: 1.31, estimated_duration: 3, estimated_cost: 9.61, payment_method: ebirr, requires_signature: false, insurance_required: false, special_instructions: , sender_name: Abdulsemed Mussema, sender_phone: , receiver_name: adfg, receiver_phone: 251946514836, package_details: {name: Documents, weight: 1.0, description: Documents}, pickup_address: {latitude: 8.99153258, longitude: 38.78125755, address: XQRJ+MH, Addis Ababa, Addis Ababa}, delivery_address: {latitude: 9.003318053143381, longitude: 38.7803740426898, address: Urael, Addis Ababa}}
Base URL: https://api.hudhuddelivery.com/api/
Full URL: https://api.hudhuddelivery.com/api/services/delivery/request
Connect Timeout: 0:00:30.000000
Receive Timeout: 0:00:30.000000
Send Timeout: 0:00:30.000000
═══════════════════════════════════════════════════════════════     
updateAcquireFence: Did not find frame.
updateAcquireFence: Did not find frame.
❌ ERROR[500] => PATH: https://api.hudhuddelivery.com/api/services/delivery/request
Error Type: DioExceptionType.badResponse
Error Message: This exception was thrown because the response has astatus code of 500 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 500 has the following meaning: "Server error - the server failed to fulfil an apparently valid request"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.
Response Headers: connection: keep-alive
cache-control: no-cache, private
access-control-allow-origin: *
transfer-encoding: chunked
date: Thu, 06 Aug 2026 11:13:32 GMT
cf-cache-status: DYNAMIC
report-to: {"group":"cf-nel","max_age":604800,"endpoints":[{"url":"https://a.nel.cloudflare.com/report/v4?s=f72gkC27latjoV2pZGg4HTArBqXuwHMK%2BGdJqc%2BXDzt0dJxS6eajREcpBVau2FVcBEUiNw8yB67z5AK9LAfVODqbsSvMw%2FIBm7lYHYvv95ZaM1gtcDjP1%2FpkLBmmusgObs7mOFbWCAdc"}]}
content-type: application/json
x-xss-protection: 1; mode=block
server: cloudflare
alt-svc: h3=":443"; ma=86400
nel: {"report_to":"cf-nel","success_fraction":0.0,"max_age":604800} 
cf-ray: a26d9cdee8a05452-JIB
x-frame-options: SAMEORIGIN
x-content-type-options: nosniff
Response Data: {message: Failed to request delivery service.}       
Status Code: 500
Status Message: Internal Server Error
Request Data: {package_type: document, package_description: Documents, package_weight: 1.0, pickup_location: XQRJ+MH, Addis Ababa, Addis Ababa, pickup_latitude: 8.99153258, pickup_longitude: 38.78125755, dropoff_location: Urael, Addis Ababa,dropoff_latitude: 9.003318053143381, dropoff_longitude: 38.7803740426898, vehicle_type: motorbike, service_type: same_day, scheduled_pickup: null, scheduled_delivery: null, estimated_distance: 1.31, estimated_duration: 3, estimated_cost: 9.61, payment_method: ebirr, requires_signature: false, insurance_required: false, special_instructions: , sender_name: Abdulsemed Mussema, sender_phone: , receiver_name: adfg, receiver_phone: 251946514836, package_details: {name: Documents, weight: 1.0, description: Documents}, pickup_address: {latitude: 8.99153258, longitude: 38.78125755, address: XQRJ+MH, Addis Ababa, Addis Ababa}, delivery_address: {latitude: 9.003318053143381, longitude: 38.7803740426898, address: Urael, Addis Ababa}}
```

---
