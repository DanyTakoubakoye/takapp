# Cloud Functions security follow-up

The Functions source is not present in this workspace. The entries below are
client call-site facts and security assumptions to verify in the Functions
repository; they are not an audit or claim that the callables are secured.

## `createTenantUser`

- Called by `OwnerDashboardPage` and, after this change, `ServeurService`.
- Client sends `name`, `email`, `password`, `phone`, and `role`; the server
  registration screen fixes `role` to `serveur`.
- Client does not send an establishment ID. Verify the callable derives the
  tenant from the authenticated caller's root `users/{uid}` profile, checks
  the caller's role and tenant (including `gerante` for the server-registration
  screen), validates the requested role, and creates the Firebase Auth account
  and root profile without accepting client privilege claims.
- Verify duplicate-email handling and safe behavior if Auth creation succeeds
  but profile creation fails.

## `createEstablishmentAdmin`

- Called by `GlobalAdminDashboardPage` for both a new establishment and an
  existing one.
- Existing-establishment call sends `email`, `password`, `name`, `phone`,
  `establishmentId`, `establishmentName`, and `modules`.
- New-establishment call additionally sends `role: proprietaire`.
- Verify only an authorized platform administrator can call it, that the
  establishment and modules are validated server-side, and that the client
  cannot use the callable to assign arbitrary privileged roles or tenants.

## `notifyKitchenReady` and `notifyBarReady`

- Called by `CuisineService` and `BarService` after the client updates an order.
- Both callables receive `establishmentId` and `orderId`.
- Verify caller role, tenant membership, order ownership/location, allowed
  status transition, and idempotence server-side; do not trust the supplied
  establishment ID or order status from the client.