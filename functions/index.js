const admin = require("firebase-admin");

if (admin.apps.length === 0) {
  admin.initializeApp();
}


exports.notifyKitchenReady =
  require("./notifyKitchenReady").notifyKitchenReady;

exports.notifyBarReady =
  require("./notifyBarReady").notifyBarReady;

exports.notifyDepartmentsNewOrder =
  require("./notifyDepartmentsNewOrder").notifyDepartmentsNewOrder;

exports.createEstablishmentAdmin = 
  require("./createEstablishmentAdmin").createEstablishmentAdmin;

exports.createTenantUser =
  require("./createTenantUser").createTenantUser;

